# Sperli: Ränge, die einander Nachrichten schicken

Sperli (Simple Parallel Execution over Remote Links Interface) ist die Cluster-Schicht von Hilde: ein Job aus `n`
Rängen, jeder ein Prozess auf einem gelisteten Host, die Nachrichten mit einem Tag senden und empfangen. Sie hat die
Semantik des Nachrichtenaustauschs (Rang, Größe, Senden und Empfangen mit Tag) und nichts von der Schnittstelle von
MPI. Die Bytes auf der Leitung stehen in `docs/sperli-protocol.de.md`; die Abweisungen sind die Codes H1601 bis H1625
aus `docs/errors.de.md`. Diese Seite beschreibt Punkt-zu-Punkt-Nachrichten, die Kollektive, die Checkpoints und den Launcher; die C-Bibliothek folgt auf die Checkpoints.

## Sicherheit

Sicherheit ist keine Option und hat keinen Schalter.

- Jede Verbindung ist TLS 1.3 mit einem Zertifikat auf beiden Seiten. Es gibt keinen Klartextmodus, auch nicht auf
  localhost.
- Der Launcher macht eine CA, für jeden Rang ein Ed25519-Zertifikat und für jeden Job ein Schlüsselpaar von
  `Standard.CompositeSig` (ML-DSA-44 und Ed25519 zusammen). Andere Kryptographie kommt nicht vor.
- Ein Rang zeigt in seinem Hello ein Join-Token: Job, Rang, Größe, Inkarnation, Host und Ablauf, vom Launcher
  signiert. Der Peer prüft zuerst die Signatur, dann den Job, dann Rang, Größe, Inkarnation und Host, dann den Ablauf.
- Die Hosts, die die Umgebungsvariable `SPERLI_REFUSED_HOSTS` nennt (getrennt durch Kommas, Leerzeichen oder
  Zeilenenden), die reservierten Namen `host-a.invalid` und `host-b.invalid` und jeder Name darunter führen nie einen
  Rang aus, auch wenn die Hostliste sie nennt.
  `--deny-hosts DATEI` fügt Namen hinzu; es nimmt diese beiden nie weg.
- Der Kopf eines Frames wird geprüft, bevor ein Byte seiner Nutzlast gelesen wird. Eine Nutzlast hat höchstens 16 MiB.
  Ein Frame einer älteren Inkarnation wird verworfen.

## hilde run

```
hilde run -n 3 --hosts hosts.txt ./app arguments
```

`hilde run` führt `hilde-launcher` aus, das `make` neben `hilde` baut. Das Programm ist der Pfad einer ausführbaren Datei,
die auf jedem Host dieselbe ist. Die Optionen:

| Option | Bedeutung |
|---|---|
| `-n N` | die Zahl der Ränge, 1 bis 4096; erforderlich |
| `--hosts DATEI` | die Hostliste; erforderlich |
| `--deny-hosts DATEI` | Namen, die außer denen von `SPERLI_REFUSED_HOSTS` und den reservierten abgewiesen werden, einer je Zeile |
| `--checkpoint-dir VERZ`, `--checkpoint-every SEKUNDEN`, `--restart-max K`, `--resume JOB` | `--checkpoint-dir` und `--restart-max` lassen den Launcher einen gescheiterten Job neu starten; die anderen beiden werden gelesen und behalten |

Eine Hostliste hat einen Host je Zeile und einen optionalen Port: `node1`, `node2 47001`. Eine Zeile, die mit `#`
beginnt, ist ein Kommentar. Rang `i` läuft auf Zeile `i`; es muss mindestens `N` Zeilen geben. Ein Rang auf
`localhost` oder einer Adresse von `127.` wird direkt gestartet und bekommt einen freien Port; jeder andere Rang wird
über ssh an Port 62222 gestartet (`ssh -p 62222 -o BatchMode=yes host programm argumente`, jedes Wort in Anführung)
und hört am Port seiner Zeile oder an 47000 und seinem Rang. Die Ausgabe der Ränge wird, Rang für Rang, gezeigt, wenn
sie beendet sind: `[rank 1] Text`. Der Exit-Status ist 0, wenn jeder Rang mit 0 endete.

## Ein Rang

Ein Rang liest seinen Job aus der ersten Zeile seiner Standardeingabe und tritt bei:

```
let line: String := readLine(&!input);
case readJobText(asSpan(&line)) of
    when Right(right as job: Job) do
        case init(job) of
            when Right(right as opened: Comm) do
                var comm: Comm := opened;
                let sent: Int32 := send(&!comm, 1, 7, message);
                case recv(&!comm, 1, 7) of
                    when Right(right as text: String) do
                        destroyString(text);
                    when Left(left as code: Int32) do
                        skip;
                end case;
                finish(comm);
            when Left(left as code: Int32) do
                skip;
        end case;
    when Left(left as code: Int32) do
        skip;
end case;
```

- `send` verbraucht den Puffer. Es gibt 0 oder einen Code zurück. Tags sind 0 bis 2147483647.
- `recv` gibt die nächste Nachricht von einem Rang mit einem Tag zurück; eine Nachricht eines anderen Tags vom selben
  Rang wird für ihr eigenes `recv` aufgehoben. Nachrichten eines Rangs und eines Tags kommen in der gesendeten
  Reihenfolge an.
- `startSend` und `startRecv` geben offene Operationen, lineare Werte, die `finishSend` und `finishRecv` beenden.
- Die Kollektive sind auf jedem Rang dieselben Aufrufe in derselben Reihenfolge (siehe unten).
- Ein Rang, der auf eine Nachricht wartet, gilt seinem Peer nach 5000 ms ohne Frame als verloren. `setSilence` hebt
  die Grenze für einen Rang an, der länger rechnet, und `heartbeat` schickt jedem Peer einen Heartbeat.
- `abortJob` sagt jedem Peer, dass der Job vorbei ist; `finish` sagt Bye und schließt.
- Das Signieren und Prüfen eines Tokens braucht einen Stack von mehreren hundert Kilobyte. Ein Rang, der in einem Task
  beitritt, öffnet den Scope mit `openScopeWithStack(8388608)`; der Hauptthread hat genug.

## Kollektive

```
let code: Int32 := barrier(&!comm);
case allreduce(&!comm, int64Type(), sumReduction(), numbers) of
    when Right(right as total: String) do
        destroyString(total);
    when Left(left as code: Int32) do
        skip;
end case;
```

| Aufruf | Ergebnis |
|---|---|
| `barrier(comm)` | 0, wenn jeder Rang ihn aufgerufen hat |
| `bcast(comm, root, data)` | die Daten von `root` auf jedem Rang |
| `reduce(comm, root, type, operation, data)` | die Reduktion über alle Ränge bei `root`; sonst die leere Zeichenkette |
| `allreduce(comm, type, operation, data)` | die Reduktion auf jedem Rang |
| `gather(comm, root, data)` | die Blöcke aller Ränge in Rangfolge bei `root`; sonst die leere Zeichenkette |
| `scatter(comm, root, data)` | Block i der Daten von `root` auf Rang i |

- Daten sind ein `String`, den der Aufruf verbraucht; das Ergebnis ist ein neuer `String`. Die Daten eines Rangs, der
  keine liefert (`bcast`, `scatter` auf einem anderen Rang als der Wurzel), werden ignoriert und dürfen leer sein.
- Ein Array ist eine Zeichenkette von Elementen des Typs `type`: Bytes, int32, int64, uint32, uint64, float32 oder
  float64, niederwertigstes Byte zuerst. `operation` ist sum, min, max, prod, land, lor, lxor, band, bor oder bxor;
  ganze Zahlen laufen über, und die Reduktion läuft in Rangfolge. `docs/sperli-protocol.de.md` hat die Tabelle, was
  wozu passt.
- Ein Aufruf trägt höchstens 16777200 Bytes Daten. Größere Daten teilt der Aufrufer auf.
- Ein falscher Aufruf, den alle Ränge gleich sehen (eine Wurzel außerhalb des Jobs, eine Reduktion, die nicht zum Typ
  passt, Daten, die keine ganze Zahl von Elementen sind), gibt auf jedem Rang H1618 zurück, und der Job läuft weiter.
  Ein Scatter, dessen Daten keine ganze Zahl von Blöcken sind, ein Frame, der nicht zu seinem Aufruf passt, und
  Beiträge verschiedener Länge beenden den Job: der Rang, der es sieht, gibt den Code zurück und sagt es allen
  anderen Rängen, die H1612 zurückgeben.
- Der wartende Rang gilt seinem Peer nach der Stille-Grenze als verloren, wie bei `recv`. Ein Rang, der in einem
  Kollektiv langsam ist, lässt die anderen auf sich warten; ein Job mit langen Rechnungen zwischen Kollektiven hebt die
  Grenze mit `setSilence` an.
- Die Kollektive sind ein Stern um die Wurzel, so dass ein Ergebnis nicht vom Zeitablauf abhängt.

## Checkpoints

```
useCheckpoints(&!comm, "ckpt");
let code: Int32 := checkpoint(&!comm, &state);
case resume(&!comm) of
    when Right(right as back: String) do
        destroyString(back);
    when Left(left as code: Int32) do
        skip;
end case;
```

- `useCheckpoints` nennt das Verzeichnis. Jeder Rang ruft `checkpoint` in derselben Reihenfolge auf wie die
  Kollektive. Ein Zustand ist ein Wert eines Typs mit einer Instanz von `Checkpointable` (`encodeState`,
  `decodeState`; `String` hat eine); `checkpointBytes` nimmt die Bytes unmittelbar. Ein Typ, der eine Verbindung,
  eine Datei oder ein offenes Send oder Receive hält, hat keine Instanz, sodass der Compiler den Aufruf abweist; ein
  noch offenes Send oder Receive lässt den Aufruf mit H1624 scheitern.
- Ein Rang schreibt `<dir>/<job>/<epoch>/rank-<n>.ckpt` (Kopf `SPCK`, Version, Job, Epoche, Rang, size, Länge und
  SHA-256, dann der Zustand) unter einem temporären Namen, synchronisiert sie, benennt sie um und sendet ihr SHA-256
  an Rang 0. Er sendet die Datei auch an Rang `(n + 1) mod size`, der sie als `rank-<n>.ckpt.buddy` behält.
- Hat Rang 0 jedes SHA-256, schreibt er `COMMIT`, das sie aufführt und eine CompositeSig-Signatur des Job-Schlüssels
  trägt, und sendet es den anderen. Eine Epoche ohne gültiges signiertes COMMIT zählt nicht. Nur die eben
  geschriebene Epoche und die davor bleiben.
- Fällt ein Rang aus, enden die anderen mit H1611 oder H1612 und dem Exit-Status 75. Mit `--checkpoint-dir` startet
  der Launcher den Job neu, höchstens `--restart-max` Mal; ein ausgefallener Rang geht auf den nächsten unbenutzten
  Host der Liste. Der Rang ruft `resume` auf: Die neueste Epoche, deren COMMIT stimmt, wird genommen, die Signatur und
  jedes SHA-256 werden gegen die Dateiköpfe und das COMMIT geprüft, und eine fehlende oder beschädigte Datei wird vom
  Buddy geholt. Version 1 nimmt nur einen Job mit der size wieder auf, mit der er geschrieben wurde (H1623). Eine
  Abweisung ist ein Code: H1619 bis H1622.

## Die C-Bibliothek

`libsperli` ist die C-Schnittstelle von Sperli, für ein Programm, das nicht in Hilde geschrieben ist, etwa das
Go-Paket. Sie ist eine statische Bibliothek und ein Header je Ziel:

```
sh scripts/libsperli/build.sh
```

schreibt `libsperli/c/<ziel>/libsperli.a` und `libsperli/c/<ziel>/sperli.h`, mit `<ziel>` einem von `linux`,
`openbsd`, `freebsd` und `darwin`, dem System, auf dem das Skript läuft. Ein Programm bindet die Bibliothek mit
`-lpthread -ltls -lcrypto` und nimmt `sperli.h` ein, der den vollen Text jeder Funktion enthält.

| Funktion | Aufruf |
|---|---|
| `sperli_init` | tritt dem Job bei, den eine Beschreibung nennt; gibt das Handle |
| `sperli_rank`, `sperli_size` | der eigene Rang, die Zahl der Ränge |
| `sperli_send`, `sperli_recv` | eine Nachricht an einen Rang oder von ihm mit einem Tag |
| `sperli_barrier`, `sperli_bcast`, `sperli_reduce`, `sperli_allreduce`, `sperli_gather`, `sperli_scatter` | die Kollektive |
| `sperli_result` | kopiert die Daten heraus, die ein Aufruf behalten hat |
| `sperli_checkpoint_directory`, `sperli_checkpoint`, `sperli_resume` | die Checkpoints |
| `sperli_finish` | verlässt den Job |
| `sperli_describe` | ein Satz zu einem Code |

- TLS 1.3 mit Zertifikat auf beiden Seiten ist immer an; die Bibliothek hat keine Option für etwas anderes.
- Jede Funktion prüft zuerst alle ihre Argumente und antwortet mit einem Code: einen Nullzeiger, eine Länge, einen
  Rang, einen Tag, einen Elementtyp, eine Reduktion, eine Anzahl, ein Handle, einen Pfad, einen Aufruf, während ein
  anderer läuft. Ein falsches Argument beendet nie den Prozess und ändert nichts am Job. Nur ein gebrochenes Versprechen
  der Bibliothek selbst, ein `ensures`, beendet ihn mit `abort(3)`.
- Ein Code ist 0, eine negative Zahl für einen Fehler des Aufrufers oder 1601 bis 1625 für eine Abweisung im Job, die
  Nummer des H-Codes. Die Nummern sind stabil. Die negativen Codes:

| Code | Name | Bedeutung |
|---|---|---|
| -1 | `SPERLI_E_NULL_POINTER` | ein Zeiger ist NULL, wo Bytes oder ein Ergebnis gebraucht werden |
| -2 | `SPERLI_E_BAD_LENGTH` | eine Länge ist null, wo Daten gebraucht werden, oder über ihrer Grenze |
| -3 | `SPERLI_E_BAD_RANK` | ein Rang liegt nicht im Job oder ist der eigene, wo ein Gegenüber gebraucht wird |
| -4 | `SPERLI_E_BAD_TAG` | ein Tag ist größer als 2147483647 |
| -5 | `SPERLI_E_BAD_HANDLE` | das Handle ist nicht die lebende Sitzung |
| -6 | `SPERLI_E_NOT_READY` | die Sitzung hält keine Comm |
| -7 | `SPERLI_E_BAD_TYPE` | ein Elementtyp ist größer als 6 |
| -8 | `SPERLI_E_BAD_OPERATION` | eine Reduktion ist 0 oder größer als 10 |
| -9 | `SPERLI_E_BUFFER_TOO_SMALL` | der Puffer ist kürzer als das Ergebnis; das Ergebnis bleibt erhalten |
| -10 | `SPERLI_E_NO_RESULT` | es gibt kein Ergebnis zu holen |
| -11 | `SPERLI_E_RESULT_PENDING` | ein früheres Ergebnis wurde nicht geholt |
| -12 | `SPERLI_E_BUSY` | ein anderer Aufruf läuft |
| -13 | `SPERLI_E_ALREADY_INITIALISED` | der Prozess hält schon eine Sitzung |
| -14 | `SPERLI_E_BAD_PATH` | ein Pfad enthält ein Nullbyte |
| -15 | `SPERLI_E_BAD_COUNT` | die Daten sind keine ganze Zahl von Elementen oder Blöcken |
| -16 | `SPERLI_E_INTERNAL` | der Kern antwortete mit einem Code, der keiner dieser ist |

- Die Sitzung ist eine Zahl, kein Zeiger; ein freigegebenes oder erfundenes Handle ist also ein Code und kein Absturz.
  Ein Prozess hält eine Sitzung. Es läuft ein Aufruf zur Zeit; ein Aufruf, während ein anderer läuft, antwortet
  `SPERLI_E_BUSY`.
- Ein Aufruf, der Daten macht (`recv`, `bcast`, `reduce`, `allreduce`, `gather`, `scatter`, `resume`), behält sie und
  nennt ihre Länge; `sperli_result` kopiert sie heraus. `sperli_result` mit zu kurzem Puffer nennt die nötige Länge und
  behält das Ergebnis.
- Die Bibliothek ist das Modul `Standard.SperliExport`, das die Aufrufe mit `pragma Foreign_Export` ausführt, und
  `libsperli/src/sperli.c`, das die Argumente prüft, bevor es sie aufruft. Die Laufzeit startet beim ersten
  `sperli_init` und bleibt bis zum Ende des Prozesses.
- `sh scripts/libsperli/check-libsperli.sh` baut die Bibliothek und führt `libsperli/test/test_sperli.c` aus, das jeder
  Funktion falsche Eingaben gibt und den Code gegen die Tabelle hält.

## Gemischte Jobs, das Summenbeispiel und der Benchmark

Ein Job kann Hilde-Ränge und Ränge des Go-Pakets (`sperli`, das `libsperli` benutzt) mischen; Leitung, Zertifikate
und Token sind dieselben. Die Programme und Skripte:

| Pfad | Was es ist |
|---|---|
| `examples/sperli-sum` | die Summe einer Tabelle mit 3.000.000 Zeilen über die Ränge eines Jobs; Zeile i enthaelt i + 1, die Summe ist also 4500001500000 |
| `examples/sperli-bench` | Latenz und Bandbreite zwischen zwei Rängen: `ping`, `echo`, `stream` und `sink` |
| `libsperli/test/mixed` | die Hilfen der Tests: die Beschreibungen eines Jobs und ein Rang 0, der auf eine gewählte Art falsch ist |
| `scripts/sperli/mixed-test.sh` | die gemischten Tests |
| `scripts/sperli/bench.sh` | der Benchmark |

- Jeder Rang liest seine Beschreibung aus der ersten Zeile seiner Standardeingabe. Die Ränge eines Jobs duerfen von
  Hand nacheinander gestartet werden; der höchste Rang zuerst und Rang 0 zuletzt, je eine Sekunde dazwischen, denn die
  C-Bibliothek wartet nicht auf einen Rang, der noch nicht lauscht.
- `sperli-sum` teilt die Zeilen nach einer Regel: die ersten `rows mod size` Ränge bekommen eine Zeile mehr, die
  Teile folgen ab Zeile 0 aufeinander. Jeder Rang summiert seine Zeilen und nimmt an einer Reduktion auf Rang 0 teil
  (`Int64`, Summe); Rang 0 schreibt `rows=3000000 total=4500001500000 expected=4500001500000 ok`. Das Go-Beispiel
  schreibt dieselbe Zeile.
- `bash scripts/sperli/mixed-test.sh` baut alles in ein privates Verzeichnis, kopiert das Go-Repository dorthin (es
  wird nicht verändert; `SPERLI_REPO` nennt es, Vorgabe `/repos/sperli`) und braucht `hilde`, `go` und einen
  C-Compiler. Er führt die Summe mit Rang 0 in Hilde und den Rängen 1 und 2 in Go aus, und mit drei Hilde-Rängen.
  Danach trifft ein Hilde-Rang 0 auf einen Go-Rang 1 und ist jedes Mal auf eine Art falsch: ein Zertifikat einer
  anderen CA, kein Zertifikat, ein abgelaufenes Token, ein Token eines anderen Jobs, ein Token eines anderen Rangs,
  ein überlanger Frame. Der Go-Rang muss mit dem Code der Abweisung enden (H1601, H1601, H1604, H1605, H1606,
  H1608); ein richtiger Client wird eingelassen. Eine Hostliste mit einem Host, den das Go-Rangprogramm sperrt, weist es ab; `SPERLI_GO_REFUSED_TEST`
  nennt diesen Go-Test. Der Test
  endet mit 0, wenn jede Prüfung hielt. Er dauert etwa zwei Minuten.
- `bash scripts/sperli/bench.sh [pings [messages]]` misst die Umlaufzeit einer Nachricht von 64 Bytes und die Rate
  von Nachrichten zu 1 MiB in eine Richtung, für zwei Hilde-Ränge, einen Hilde-Rang 0 mit einem Go-Rang 1 und zwei
  Go-Ränge.
- Gemessen auf einem Rechner (Linux, Loopback, TLS 1.3 mit Zertifikaten auf beiden Seiten, 1000 Umläufe, 32
  Nachrichten zu 1 MiB; MB sind 10^6 Bytes):

| Paar | Umlauf, Mittel | Bandbreite |
|---|---|---|
| Hilde und Hilde | 68 us | 90,1 MB/s |
| Hilde (Rang 0) und Go | 381 us | 4,3 MB/s |
| Go und Go | 547 us | 4,3 MB/s |

- Ein Paar mit einem Go-Rang ist um den Faktor 5 bis 20 langsamer als zwei Hilde-Ränge, auf jeder Seite des Paares
  gleich. Die Ursache liegt im Weg durch die C-Bibliothek; sie ist nicht untersucht.

## Dateien

Ein Rang schreibt seine CA, sein Zertifikat und seinen Schlüssel in ein Verzeichnis `sperli-<job>-<rang>` des
Arbeitsverzeichnisses, nur für seinen Benutzer lesbar, und entfernt sie, wenn er dem Job beigetreten oder daran
gescheitert ist. Er braucht ein Arbeitsverzeichnis, in das er schreiben darf.
