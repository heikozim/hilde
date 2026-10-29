# SPERLI-Wire-Protokoll, Version 1

SPERLI (Simple Parallel Execution over Remote Links Interface) ist die Cluster-Schicht von Hilde: ein Job aus
`size` Rängen, jeder ein Prozess auf einem gelisteten Host, die über TLS miteinander sprechen. SPERLI ist
**nicht MPI-kompatibel**. Es übernimmt nur die Semantik von MPI: Rang, Größe, Senden und Empfangen mit Tag,
Barrier, Broadcast, Reduce, Allreduce, Gather und Scatter. Dieses Dokument und die Vektoren in
`docs/sperli-vectors.txt` sind vollständig genug, um eine zweite Implementierung zu schreiben, etwa in reinem
C. Englische Fassung: `docs/sperli-protocol.md`.

## Umfang und Stand

SPERLI ist der eigene MPI-Ersatz für die Rechenverteilung, in reinem C. Es kommt nach dem Array-Typ und der
Rechenschicht von Hilde; nichts, was vom Array-Typ abhängt, wird vorausgebaut.

- **Aktuell:** Transport und Sicherheit, Jobbeschreibung, Verbindungen, Frame und alle Frame-Typen: HELLO, DATA,
  COLLECTIVE, HEARTBEAT, ABORT, BYE und die Checkpoint-Frames CKPT_BEGIN, CKPT_DATA, CKPT_ACK, CKPT_COMMIT und
  RESUME mit den Checkpoint-Dateien. `Standard.Sperli` setzt sie um. Ein Checkpoint enthält die Bytes eines
  Zustands, die ein Typ mit einer Instanz von `Checkpointable` liefert; auch dafür ist keine Array-Struktur nötig. Die Kollektive arbeiten auf flachen Arrays der
  sieben Elementtypen unten, die auf der Leitung Bytes sind; sie brauchen keine Array-Struktur.
- **Schnittstelle zum Array-Typ.** SPERLI hat keine eigene Array-Struktur und keine eigene Serialisierung. Vom
  Array-Typ braucht es nur eine schmale Schnittstelle mit diesen Platzhalter-Signaturen, die der Array-Typ später
  füllt: `encode(value, buffer)` schreibt einen Wert in einen Bytepuffer und gibt die Länge zurück; `decode(bytes)`
  liest einen Wert zurück und schlägt bei abgeschnittener oder falscher Eingabe fehl; `elementType(value)` gibt den
  Elementtyp-Code der Tabelle unten; `shape(value)` gibt die Ausdehnungen. `combine(a, b, operation)` ist für flache
  Arrays der Elementtypen unten gebaut (`Standard.SperliCollective.combine`); einen Wert mit Form kodiert der
  Array-Typ zu Bytes, die Kollektive senden ihn, und für Formen, die nicht flach sind, reduziert ihn der Array-Typ.
  Nachrichten in DATA-Frames sind schon Bytes und brauchen nichts davon.
- **Kein eigener Konsens, kein eigener Zustandsspeicher.** Einigkeit zwischen Rängen und jeder Zustand, der einen Job
  überdauern muss (Epochen und Commits der Checkpoints, die Mitgliedschaft), gehen an die vorhandene
  Raft-Integration (`Standard.Raft`, `Standard.RaftTcp`, Dienst 1 im Frame-Header) und das replizierte SQLite
  (`Standard.SqliteReplica`). Version 1 des Checkpoints nutzt sie nicht: Welche Epoche zählt, entscheidet die
  COMMIT-Datei, die Rang 0 mit dem Job-Schlüssel signiert und jeder Rang prüft, sodass kein einzelner Rang eine
  Epoche zählen lassen kann, die der Schlüssel nicht signiert hat.
- **Bindings.** C-Bibliotheken (libtls) werden nur über unsafe-Bindings angebunden; alles darüber ist safe.

Alle Ganzzahlen sind Little Endian und ohne Vorzeichen, sofern nichts anderes steht. Eine Bytefolge von n Bytes
heißt `[n]`. "Muss" heißt: Der Empfänger weist den Frame ab, schließt die Verbindung und bricht den Job ab, es
sei denn, eine Regel sagt "verwirft".

## Transport und Sicherheit

- Eine TCP-Verbindung je Paar von Rängen. Der Rang mit der kleineren Nummer verbindet sich zum größeren, so
  gibt es genau eine Verbindung je Paar. Version 1 hat eine feste Mitgliedschaft von `size` Rängen, 1 bis 4096.
- Nur TLS 1.3. Es gibt keinen Klartextmodus, auch nicht für localhost, auch nicht für Tests. Ein Peer, der
  weniger anbietet, wird abgewiesen.
- Gegenseitige Authentifizierung. Der Launcher erzeugt je Job eine **Job-CA**, einen Ed25519-Schlüssel mit
  selbstsigniertem Zertifikat, und je Rang ein Ed25519-Zertifikat, von ihr signiert. Beide Seiten verlangen das
  Zertifikat des Peers und prüfen es allein gegen die Job-CA. Der Vertrauensspeicher des Systems wird nicht
  benutzt.
- Der Subject-Common-Name des Zertifikats von Rang `n` ist `sperli-<Job-Id als 32 kleine Hex-Ziffern>-<n>`, höchstens
  44 Bytes, damit er in die 64 Bytes passt, die ein Common Name haben darf. Der Host `h` des Rangs ist der DNS-Name im
  Subject Alternative Name des Zertifikats, den die verbindende Seite im Handshake gegen den Hostlisten-Eintrag prüft,
  den sie anwählt. Nach dem Handshake vergleicht jede Seite das Subject des Peers mit dem Job und dem erwarteten Rang
  und weist die Verbindung ab, wenn sie abweichen. Der Rang im Subject ist auch der einzige `source rank`, den der Peer
  auf dieser Verbindung benutzen darf. Der Host des Peers wird ein zweites Mal über das Join-Token geprüft, das ihn
  nennt.
- Die Hosts, die der Betreiber in der Umgebungsvariable `SPERLI_REFUSED_HOSTS` nennt (Namen getrennt durch Kommas,
  Leerzeichen oder Zeilenenden; auch jede Domain darunter, in jeder Schreibweise), führen nie einen Rang aus, ebenso
  die reservierten Namen `host-a.invalid` und `host-b.invalid`, die eingebaut sind und keine Maschine bezeichnen.
  Launcher und Rang weisen einen passenden Hostlisten-Eintrag ab, auch wenn er gelistet ist. Der Betreiber kann mit
  `--deny-hosts DATEI` (ein Name je Zeile) weitere Namen sperren; die Namen der Variable bleiben gesperrt, auch wenn
  die Datei leer ist oder fehlt. Die Variable muss überall gesetzt sein, wo ein Launcher oder ein Rang läuft; ohne
  sie sind nur die beiden reservierten Namen gesperrt.
- Keine neue Kryptografie: TLS-Zertifikate sind Ed25519 (`Standard.X509`); Tokens und COMMIT-Signaturen sind
  `Standard.CompositeSig` (ML-DSA-44 und Ed25519 zusammen, öffentlicher Schlüssel 1344 Bytes, Signatur 2484
  Bytes) mit dem Label `COMPSIG-MLDSA44-Ed25519-SHA512` (`CompositeSig.openSshLabel`). Der Kontext ist
  `SPERLI-JOIN-1` für Join-Tokens und `SPERLI-COMMIT-1` für COMMIT-Dateien.
- Der Launcher erzeugt je Job ein CompositeSig-Schlüsselpaar. Der öffentliche Schlüssel (1344 Bytes) geht mit
  Job-Id, `size`, Inkarnation, Hostliste und dem Zertifikat der Job-CA in der Jobbeschreibung an jeden Rang. Der
  geheime Schlüssel bleibt beim Launcher, der die Join-Tokens signiert; Rang 0 bekommt ihn für die Laufzeit des
  Jobs, um die COMMIT-Dateien zu signieren.

## Jobbeschreibung

Der Launcher sagt jedem Rang seinen Job auf der Standardeingabe des Prozesses, als eine Zeile aus kleinen
Hexadezimalziffern und einem Zeilenvorschub. Die Bytes hinter den Ziffern sind:

| Feld | Größe | Bedeutung |
|---|---|---|
| magic | 4 | `SPJD` |
| version | 2 | 1 |
| reserviert | 2 | 0 |
| Job-Id | 16 | die Job-Id |
| size | 4 | die Zahl der Ränge, 1 bis 4096 |
| rank | 4 | der Rang dieses Prozesses, kleiner als `size` |
| incarnation | 4 | 1 oder mehr |
| Hosts | `size` mal | Port (2 Bytes, nicht 0), Länge des Hostnamens (2 Bytes), Hostname |
| öffentlicher Schlüssel | 2 + 1344 | Länge und der öffentliche CompositeSig-Schlüssel des Jobs |
| Token | 2 + t | Länge und das Join-Token dieses Rangs |
| CA | 4 + n | Länge und der PEM-Text des CA-Zertifikats des Jobs |
| Zertifikat | 4 + n | Länge und der PEM-Text des Zertifikats dieses Rangs |
| Schlüssel | 4 + n | Länge und der PEM-Text des Ed25519-Schlüssels dieses Rangs |

Zahlen sind little endian. Eine Beschreibung mit weiteren Bytes hinter dem Schlüssel, ein abgeschnittenes Feld, ein
abgewiesener Host oder eine Größe, ein Rang oder eine Inkarnation außerhalb des Bereichs wird abgewiesen. Der Schlüssel
des Rangs ist ein Geheimnis; der Launcher schreibt die Zeile nie in eine Datei, und ein Rang schreibt die drei
PEM-Texte in Dateien, die nur sein Benutzer lesen darf, in ein eigenes Verzeichnis, solange er Verbindungen aufbaut.

## Verbindungen

Der Rang mit der kleineren Nummer verbindet sich mit dem größeren. Ein Rang hört zuerst an seinem Port, verbindet sich
mit jedem höheren Rang (alle 100 ms ein neuer Versuch, 30 s lang, weil der Peer vielleicht noch nicht hört) und nimmt
dann von jedem niedrigeren Rang eine Verbindung an. Beide Seiten schicken ihr HELLO sofort. Ein Rang darf höchstens
5000 ms schweigen, bevor er als verloren gilt; ein Rang, der auf einen Frame wartet, schickt in Version 1 nichts von
sich aus, und ein Programm, das länger als die Grenze rechnet, hebt sie mit der Stille-Einstellung der Bibliothek an.

## Frame

Jede Nachricht ist ein Frame: ein Kopf von 52 Bytes und `length` Bytes Nutzlast.

| Offset | Größe | Feld | Bedeutung |
|---|---|---|---|
| 0 | 4 | length | Bytes der Nutzlast nach dem Kopf |
| 4 | 1 | type | Frame-Typ, siehe unten |
| 5 | 1 | flags | in Version 1 gleich 0; andere Werte muss man abweisen |
| 6 | 2 | service | 0 = SPERLI; 1 = reserviert für einen gemeinsamen Raft-Transport; andere abweisen |
| 8 | 16 | job id | 128-Bit-Job-Id, für alle Frames eines Jobs gleich |
| 24 | 4 | incarnation | 1 beim Start, bei jedem Neustart plus 1 |
| 28 | 4 | membership epoch | in Version 1 gleich 0; reserviert für dynamische Mitgliedschaft; andere abweisen |
| 32 | 8 | epoch | Checkpoint-Epoche des Frames; 0 für Frames außerhalb eines Checkpoints |
| 40 | 4 | source rank | Rang des Senders |
| 44 | 4 | target rank | Rang des Empfängers |
| 48 | 4 | tag | Nutzer-Tag bei DATA, 0 bei allen anderen Typen |

- Größte Nutzlast: 16777216 Bytes (16 MiB). Der größte Frame hat 52 + 16777216 Bytes. Der Empfänger liest den
  Kopf von 52 Bytes, prüft `length` gegen das Maximum, **bevor er ein Byte der Nutzlast liest oder Speicher dafür
  anlegt**, und weist einen größeren Wert ab. Eine größere Nachricht teilt die Schicht darüber auf.
- Prüfreihenfolge: length, type (1 bis 11), flags, service, membership epoch, job id (gleich dem Job), source rank
  (gleich dem authentifizierten Peer) und target rank (gleich dem eigenen Rang), incarnation.
- Inkarnation: Ein Frame mit **niedrigerer** Inkarnation als der des Empfängers wird verworfen: seine `length`
  Bytes Nutzlast werden gelesen und weggeworfen, sonst geschieht nichts. Eine **höhere** muss abgewiesen werden.
  Alte Frames erreichen den Nutzer nie.
- Nutzer-Tags sind 0 bis 2147483647. Tags ab 2147483648 sind reserviert: ein DATA-Frame mit einem solchen wird
  abgewiesen, und ein COLLECTIVE-Frame hat Tag 0 wie jeder Typ außer DATA. Diese beiden Tag-Prüfungen kommen zuletzt,
  nach der Inkarnation, so dass ein Frame einer älteren Inkarnation weiter verworfen wird, ohne dass sein Tag beurteilt
  wird.
- Frames einer Verbindung kommen in der gesendeten Reihenfolge an. DATA-Frames werden nach (source rank, tag) in
  dieser Reihenfolge zugeordnet.

## Frame-Typen

| Code | Name | Richtung | Nutzlast |
|---|---|---|---|
| 1 | HELLO | beide, erster Frame | Fähigkeiten und Join-Token |
| 2 | DATA | beliebig | Nachrichtenbytes |
| 3 | COLLECTIVE | beliebig | Kollektiv-Kopf und Daten |
| 4 | HEARTBEAT | beide | Zähler des Senders |
| 5 | ABORT | beliebig | Grundcode und Text |
| 6 | CKPT_BEGIN | Rang 0 an alle | Checkpoint-Beginn |
| 7 | CKPT_DATA | Rang an Buddy, oder Abruf | Stück einer Rang-Datei |
| 8 | CKPT_ACK | Rang an Rang 0 | Digest der geschriebenen Datei |
| 9 | CKPT_COMMIT | Rang 0 an alle | die COMMIT-Datei |
| 10 | RESUME | Rang 0 an alle, und Antworten | Wiederaufnahme-Epoche und Status |
| 11 | BYE | beide | leer |

Code 0 und Codes über 11 sind ungültig.

### HELLO (1)

Beide Seiten senden es unmittelbar nach dem TLS-Handshake; davor darf nichts kommen. Ein zweites HELLO wird
abgewiesen.

| Offset | Größe | Feld |
|---|---|---|
| 0 | 2 | Protokollversion, 1 |
| 2 | 1 | Sprache: 0 Hilde, 1 Go, 2 C |
| 3 | 1 | reserviert, 0 |
| 4 | 4 | Dienste als Bitmenge: Bit 0 Punkt-zu-Punkt und Kollektive, Bit 1 Checkpoint, Bit 2 reserviert für Raft |
| 8 | 4 | reserviert, 0 |
| 12 | 4 | Länge `t` des Tokens |
| 16 | t | Join-Token |

Der Kopf eines HELLO trägt Rang und Inkarnation des Senders. Der Peer braucht Bit 0 gemeinsam; eine andere
Protokollversion als 1 wird abgewiesen.

**Join-Token.** Die signierte Nachricht ist

| Offset | Größe | Feld |
|---|---|---|
| 0 | 4 | Magic `SPJT` |
| 4 | 2 | Token-Version, 1 |
| 6 | 2 | reserviert, 0 |
| 8 | 16 | Job-Id |
| 24 | 4 | Rang |
| 28 | 4 | Größe (size) |
| 32 | 4 | Inkarnation |
| 36 | 8 | Ablauf, Sekunden seit 1970-01-01 UTC |
| 44 | 2 | Länge `h` des Hosts, 1 bis 255 |
| 46 | h | Hostname, ASCII |

und das Token ist diese Nachricht, dann eine Signaturlänge von 2 Bytes (2484) und die Signatur. Der Empfänger
prüft die Signatur mit dem öffentlichen Job-Schlüssel und weist das Token ab, wenn die Signatur nicht stimmt, die
Job-Id nicht die seines Jobs ist, der Rang nicht der Rang im Frame-Kopf und im Zertifikat ist, `size` oder
Inkarnation vom Job abweichen, der Host vom Hostlisten-Eintrag dieses Rangs abweicht oder der Ablauf nicht nach
der Uhr des Empfängers liegt.

### DATA (2)

Die Nutzlast ist die Nachricht. Der Tag steht im Kopf. Eine leere Nachricht ist gültig.

### COLLECTIVE (3)

Nutzlast: ein Kollektiv-Kopf von 16 Bytes, dann Daten. Der `tag` im Frame-Kopf ist 0, und eine Nutzlast, die kürzer
als der Kollektiv-Kopf ist, wird mit dem Frame-Kopf abgewiesen (bevor die Nutzlast gelesen wird). Die Daten haben
höchstens 16777200 Bytes, damit Kopf und Daten in die größte Nutzlast passen.

| Offset | Größe | Feld |
|---|---|---|
| 0 | 1 | Operation: 1 barrier, 2 bcast, 3 reduce, 4 allreduce, 5 gather, 6 scatter |
| 1 | 1 | Elementtyp: 0 Bytes, 1 int32, 2 int64, 3 uint32, 4 uint64, 5 float32, 6 float64 |
| 2 | 1 | Reduktion: 0 keine, 1 sum, 2 min, 3 max, 4 prod, 5 land, 6 lor, 7 lxor, 8 band, 9 bor, 10 bxor |
| 3 | 1 | Phase: 0 Beitrag zur Wurzel, 1 Ergebnis von der Wurzel |
| 4 | 4 | Wurzelrang |
| 8 | 8 | Folgenummer des Kollektiv-Aufrufs, ab 1; für denselben Aufruf auf allen Rängen gleich |
| 16 | n | Daten |

Bytes, barrier, bcast, gather und scatter tragen Elementtyp 0 und Reduktion 0. Reduce und allreduce tragen Typ und
Operation des Aufrufs. Jeder Rang macht dieselben Kollektiv-Aufrufe in derselben Reihenfolge; die Folgenummer zählt
die Aufrufe eines Rangs ab 1, und ein Aufruf, der scheitert, zählt trotzdem.

**Form.** Version 1 benutzt einen Stern, keinen Baum und keinen Ring, damit das Ergebnis nicht vom Zeitablauf
abhängt und jeder Rang schon mit jedem anderen verbunden ist. Bei allreduce ist die Wurzel Rang 0. Reduziert wird
über die Beiträge in aufsteigender Rangfolge, und der eigene Wert der Wurzel ist der Beitrag ihres Rangs. Ein Rang
sendet nur an die Wurzel und empfängt nur von der Wurzel; die Wurzel spricht mit jedem Rang.

| Operation | Beiträge (Phase 0) | Ergebnisse (Phase 1) |
|---|---|---|
| barrier | leer, jeder Rang an Rang 0 | leer, Rang 0 an jeden Rang |
| bcast | keine | die Daten der Wurzel an jeden anderen Rang |
| reduce | Daten jedes anderen Rangs an die Wurzel | keine; jeder Rang außer der Wurzel bekommt die leere Zeichenkette |
| allreduce | Daten jedes Rangs an Rang 0 | die reduzierten Daten, Rang 0 an jeden anderen Rang |
| gather | der Block jedes anderen Rangs an die Wurzel | keine; die Wurzel fügt die Blöcke in Rangfolge zusammen, die anderen bekommen die leere Zeichenkette |
| scatter | keine | Block i der Daten der Wurzel an Rang i; die Wurzel behält ihren eigenen Block |

**Reduktionen.** Die Elemente eines Arrays haben je `width` Bytes (1, 4 oder 8, nach Typ), niederwertigstes Byte
zuerst. Zwei Arrays werden Element für Element reduziert, das erste als linker Operand.

| Operation | Elementtypen | Ergebnis |
|---|---|---|
| sum, prod | int32, int64, uint32, uint64 | das Ergebnis modulo 2 hoch Breite in Bits; nichts bricht ab |
| sum, prod | float32, float64 | das IEEE-Ergebnis in der Breite des Typs |
| min, max | ganze Zahlen | nach der Ordnung des Typs: mit Vorzeichen für int32 und int64, sonst ohne |
| min, max | Fließkommazahlen | min nimmt den zweiten Operanden nur, wenn er kleiner als der erste ist, max nur, wenn er größer ist |
| land, lor, lxor | ganze Zahlen | jedes Element ist wahr, wenn es nicht 0 ist; das Ergebnis ist 0 oder 1 |
| band, bor, bxor | ganze Zahlen und Bytes | die Bits |

Nicht erlaubt und von jedem Rang abgewiesen, bevor etwas gesendet wird (H1618): sum, min, max, prod und die
logischen Operationen auf Bytes; die logischen und bitweisen Operationen auf Fließkommazahlen; Reduktion 0; ein Typ
über 6; eine Operation über 10.

**Prüfung der Argumente.** Jede Prüfung, die jeder Rang allein machen kann, geschieht, bevor etwas gesendet wird,
damit alle Ränge denselben Aufruf abweisen und der Job weiterläuft: eine Wurzel ab `size`, ein Typ oder eine
Operation, die nicht zusammenpassen, und Daten, die keine ganze Zahl von Elementen sind (H1618). Prüfungen, die nur
ein Rang machen kann, beenden den Job:

- Ein Scatter, dessen Daten an der Wurzel keine ganze Zahl von Blöcken zu höchstens 16777200 Bytes sind: die Wurzel
  sendet ABORT mit Grund 4 an alle Ränge und gibt H1618 zurück; die anderen geben H1612 zurück.
- Ein Frame, dessen Kollektiv-Kopf in Operation, Typ, Reduktion, Phase, Wurzel oder Folgenummer vom Aufruf abweicht,
  den er beantwortet, oder der abgeschnitten ist (H1617): der Rang sendet ABORT mit Grund 3 an alle Ränge und gibt
  H1617 zurück.
- Beiträge verschiedener Länge bei reduce oder Blöcke verschiedener Länge bei gather: ebenso, bei reduce mit H1618
  (die Längen sind die Daten eines Aufrufs) und bei gather mit H1617.

**Reihenfolge mit DATA.** Kollektiv-Frames und DATA-Frames einer Verbindung kommen in der gesendeten Reihenfolge an.
Ein Rang, der auf einen Kollektiv-Frame wartet, hebt die DATA-Frames davor für sein eigenes `recv` auf, und ein Rang,
der auf DATA wartet, hebt die Kollektiv-Frames davor auf. Die Tags ab 2147483648 sind dafür reserviert: ein DATA-Frame
mit so einem Tag wird mit dem Frame-Kopf abgewiesen (H1610), ein Peer kann also keinen Daten-Frame als Kollektiv-Frame
ausgeben.

### HEARTBEAT (4)

Nutzlast: 8 Bytes, ein Zähler des Senders, der bei 1 beginnt und je Heartbeat um eins wächst. Jede Seite sendet
auf jeder Verbindung alle 1000 ms einen, wenn sie sonst nichts gesendet hat. Eine Verbindung, die 5000 ms keinen
Frame geliefert hat, gilt als verloren: Der Rang sendet ABORT mit Grund 1 an alle Peers und hält an.

### ABORT (5)

| Offset | Größe | Feld |
|---|---|---|
| 0 | 4 | Grund: 1 Heartbeat verloren, 2 Rang ausgefallen, 3 Protokollfehler, 4 Abbruch durch den Nutzer, 5 Checkpoint fehlgeschlagen |
| 4 | n | Text, UTF-8, höchstens 1024 Bytes |

Ein Rang, der ABORT empfängt, leitet nichts weiter, schließt alle Verbindungen und beendet den Jobschritt. Mit
Checkpoint startet der Launcher den Job vom letzten COMMIT neu (siehe Checkpoints).

### BYE (11)

Leere Nutzlast. Ein Rang sendet BYE an jeden Peer, wenn er normal geht, und schließt dann die Verbindung. Ein
Schließen ohne BYE ist ein verlorener Peer.

### CKPT_BEGIN (6)

Rang 0 an jeden Rang, `epoch` im Kopf ist die neue Epoche. Ein Rang weist eine andere Version als 1 und eine
andere size als seine eigene ab.

| Offset | Größe | Feld |
|---|---|---|
| 0 | 4 | Checkpoint-Formatversion, 1 |
| 4 | 4 | size |

### CKPT_DATA (7)

| Offset | Größe | Feld |
|---|---|---|
| 0 | 1 | Art: 0 Buddy-Kopie, 1 Abrufanfrage, 2 Abrufantwort, 3 Abruf abgelehnt, 4 nichts zu holen |
| 1 | 3 | reserviert, 0 |
| 4 | 4 | Eigentümer-Rang, der Rang, dem die Datei gehört |
| 8 | 8 | Offset des Stücks in der Datei |
| 16 | 8 | Gesamtlänge der Datei |
| 24 | n | Stück |

Art 0: Rang `r` sendet seine fertige Rang-Datei in Stücken der Reihe nach an Rang `(r + 1) mod size`, der sie als
`rank-<r>.ckpt.buddy` in seinem eigenen Epochenverzeichnis ablegt. Art 1: Ein Rang fragt den Buddy nach einer
Datei, die ihm fehlt; Offset und Gesamtlänge sind 0, es gibt kein Stück. Art 2 antwortet mit den Stücken. Art 3
heißt: Der Buddy hat keine gültige Kopie. Art 4 sagt, dass ein Rang nichts braucht, damit der Buddy nicht auf eine
Anfrage wartet. Ein Stück hat höchstens 1 MiB; die Stücke kommen der Reihe nach, der Offset jedes Stücks ist die
Zahl der bisher empfangenen Bytes, und die Gesamtlänge ändert sich nie.

### CKPT_ACK (8)

Nutzlast: 32 Bytes, das SHA-256 der ganzen Rang-Datei, die eben an ihren Platz umbenannt wurde. `epoch` im Kopf
ist die Epoche.

### CKPT_COMMIT (9)

Nutzlast: die Bytes der COMMIT-Datei der Epoche. Empfänger prüfen die Signatur und legen eine Kopie ab.

### RESUME (10)

| Offset | Größe | Feld |
|---|---|---|
| 0 | 4 | size |
| 4 | 4 | Status: 0 Anfrage oder bereit, 1 Datei vom Buddy geholt, 2 fehlgeschlagen |
| 8 | 32 | SHA-256 der COMMIT-Datei, 32 Nullbytes für keine |
| 40 | n | die COMMIT-Datei, bei Status 0 von Rang 0 und bei Status 3 |

Status 3 ist ein Angebot: Jeder Rang außer 0 sendet Rang 0 die beste COMMIT-Datei, die er hat (`epoch` im Kopf =
ihre Epoche, leer, wenn er keine hat). Rang 0 nimmt unter den Angeboten und seinen eigenen Dateien die höchste
Epoche, deren Signatur stimmt, und sendet Status 0 mit dieser Epoche (`epoch` im Kopf) und der COMMIT-Datei. Jeder
Rang antwortet Rang 0 mit 0 oder 1, sobald sein Zustand geladen ist, oder mit 2, wenn er ihn nicht laden kann;
Rang 0 sendet dann allen Status 0 zum Weitermachen; Status 2 bricht den Job ab.

## Checkpoints

Aufbau auf der Platte: `<dir>/<job>/<epoch>/rank-<n>.ckpt` und `<dir>/<job>/<epoch>/COMMIT`. `<job>` ist die
Job-Id als 32 kleine Hex-Ziffern; `<epoch>` ist eine Dezimalzahl, die bei 1 beginnt.

**Rang-Datei.** Ein Kopf von 80 Bytes, dann der Zustand.

| Offset | Größe | Feld |
|---|---|---|
| 0 | 4 | Magic `SPCK` |
| 4 | 2 | Formatversion, 1 |
| 6 | 2 | reserviert, 0 |
| 8 | 16 | Job-Id |
| 24 | 8 | Epoche |
| 32 | 4 | Rang |
| 36 | 4 | size |
| 40 | 8 | Länge der Nutzlast |
| 48 | 32 | SHA-256 der Nutzlast |
| 80 | n | Nutzlast (der serialisierte Zustand) |

Ein Leser weist eine Datei ab mit anderem Magic oder anderer Version, mit Job-Id, Epoche, Rang oder size, die
nicht zu dem passen, was er erwartet, mit einer Dateilänge, die nicht 80 plus Nutzlastlänge ist, oder deren
Nutzlast nicht zum gespeicherten SHA-256 passt.

**COMMIT-Datei.**

| Offset | Größe | Feld |
|---|---|---|
| 0 | 4 | Magic `SPCM` |
| 4 | 2 | Formatversion, 1 |
| 6 | 2 | reserviert, 0 |
| 8 | 16 | Job-Id |
| 24 | 8 | Epoche |
| 32 | 4 | size |
| 36 | 32 * size | SHA-256 der ganzen Rang-Datei von Rang 0, 1, ... |
| 36 + 32 * size | 2 | Signaturlänge (2484) |
| 38 + 32 * size | 2484 | CompositeSig-Signatur über die Bytes 0 bis 36 + 32 * size |

Eine Epoche ohne COMMIT, dessen Signatur gegen den öffentlichen Job-Schlüssel stimmt, dessen Job-Id, Epoche und
size passen und dessen Hashes zu den Rang-Dateien passen, **zählt nicht**.

**Ablauf.** Für das Kollektiv `checkpoint(state)`, ohne offenes Send- oder Receive-Handle auf irgendeinem Rang:

1. Rang 0 sendet CKPT_BEGIN mit der neuen Epoche `e` an alle Ränge.
2. Jeder Rang serialisiert seinen Zustand und schreibt die Rang-Datei unter einem temporären Namen in das
   Epochenverzeichnis, ruft fsync auf, benennt sie in `rank-<n>.ckpt` um und sendet CKPT_ACK mit ihrem SHA-256 an
   Rang 0.
3. Jeder Rang sendet die Datei als CKPT_DATA Art 0 an seinen Buddy `(n + 1) mod size`.
4. Hat Rang 0 alle ACKs, schreibt er COMMIT auf dieselbe Weise (temporärer Name, fsync, Umbenennen), mit dem
   Job-Schlüssel signiert, und sendet CKPT_COMMIT an alle Ränge. Jeder Rang prüft die Signatur, prüft, dass das
   COMMIT das SHA-256 seiner eigenen Datei und der Buddy-Kopie, die er hält, aufführt, und legt eine Kopie ab. Ein
   Rang verlässt `checkpoint`, wenn er das COMMIT hat. Rang 0 entfernt ein altes COMMIT derselben Epoche, bevor er
   CKPT_BEGIN sendet, sodass eine halbfertige Epoche nie ein COMMIT eines früheren Versuchs zeigt.
5. Nur die Epochen `e` und `e - 1` bleiben. Nach dem COMMIT von `e` wird jedes ältere Verzeichnis gelöscht, ob
   committet oder nicht. Verzeichnisse einer späteren Epoche bleiben unberührt, weil ein Rang, der weiter ist, sie
schreiben kann.

Ein Checkpoint mit noch offenem Send oder Receive scheitert auf jedem Rang mit H1624; das wird zur Laufzeit
geprüft. Der Zustand geht durch die Typklasse `Checkpointable`; ein Typ, der ein Handle, eine Verbindung oder eine
Datei hält, hat keine Instanz, sodass der Compiler den Aufruf abweist. Ein gescheiterter Checkpoint sendet ABORT
mit Grund 5 an die anderen.

**Ausfall und Wiederaufnahme.** Bei Heartbeat-Verlust brechen alle Ränge ab. Der Launcher startet den Job mit
Inkarnation plus 1 neu, höchstens `--restart-max` Mal; ein ausgefallener Rang darf auf einen anderen Host der
Liste gehen, nie auf einen gesperrten Host (oder einen Host der Sperrdatei). Die Wiederaufnahme-Epoche ist die höchste Epoche mit gültigem COMMIT.
Bei der Wiederaufnahme wird die Signatur der COMMIT-Datei gegen den öffentlichen Job-Schlüssel geprüft, und das
SHA-256 jeder Rang-Datei wird zweimal geprüft: gegen den Kopf der Datei und gegen den Eintrag der COMMIT-Datei. Ein
Rang, dessen Datei fehlt oder ungültig ist, holt sie mit CKPT_DATA Art 1 von seinem Buddy; die geholte Datei wird
ebenso geprüft. Ein Fehler wird mit einem Code abgewiesen: H1619 für eine Datei, die nicht die erwartete ist, H1620
für ein SHA-256, das nicht passt, H1621 für ein COMMIT, das missgebildet ist oder dessen Signatur nicht stimmt,
H1622, wenn keine Epoche wieder aufgenommen werden kann. Version 1 verlangt bei der Wiederaufnahme dasselbe `size`;
ein signiertes COMMIT mit anderer size wird mit H1623 abgewiesen. Hat die neueste Epoche kein gültiges COMMIT, eine
ältere aber schon, wird die ältere wieder aufgenommen; scheitert ein COMMIT und gilt kein anderes, wird der Code
dieses Fehlers gegeben.

## Grenzen und reservierte Felder in Version 1

Fest: Mitgliedschaft von `size` Rängen; `service` 0; `membership epoch` 0; `flags` 0. Sie sind für einen
gemeinsamen Raft-und-SPERLI-Transport und für dynamische Mitgliedschaft reserviert und werden noch nicht
gedeutet. Ein Empfänger der Version 1 weist Werte ungleich 0 ab; eine spätere Version muss sich daher zuerst im
HELLO ankündigen.

## Testvektoren

`docs/sperli-vectors.txt` enthält genaue Bytes für einen Frame jedes Typs, für den Kopf der Rang-Datei, für eine
COMMIT-Datei und die Negativfälle (zu große Länge, alte und künftige Inkarnation, unbekannter Typ, flags,
service, membership epoch, ein reservierter Tag, ein Kollektiv-Frame mit Tag oder ohne Kopf, falsches SHA-256, falsches
Magic). Einträge der Art `reduce` geben zwei Arrays, einen Elementtyp und eine Reduktion und das Ergebnis; sie
decken Überlauf, Ordnung mit Vorzeichen, Ordnung der Fließkommazahlen, die logischen und bitweisen Operationen und die
abgewiesenen Kombinationen ab. Signaturen lassen sich nicht festlegen (ML-DSA
signiert mit Zufall); Vektoren mit Signatur tragen daher einen Platzhalter aus 0xaa-Bytes und nennen auch den
signierten Teil. Die Datei wird von `scripts/sperli-vectors.py` geschrieben und geprüft. Ihr Format steht in
ihrem Kopf.
