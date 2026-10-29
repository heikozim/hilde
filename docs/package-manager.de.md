# Der Paketmanager

Ein Hilde-Paket ist ein Verzeichnis mit einem Manifest, `hilde.toml`, seinen Modulen unter `src` und den
Paketen, die es braucht, unter `vendor/`, eingecheckt. Die Paketkommandos führt `hilde-pkg` aus, das neben dem
Compiler liegt; der Compiler gibt sie daran weiter, also heißen sie alle `hilde <Kommando>`. Nur `get` und
`update` gehen ins Netz, über git. Jedes Kommando nimmt `--json` und gibt dann ein Objekt aus:

```json
{"command": "verify", "ok": true, "count": 2, "summary": "...", "problems": []}
```

Ein Problem hat einen Code von H1501 bis H1534 (docs/errors.de.md, Abschnitt 13), eine Meldung und einen
Vorschlag. Der Exit-Status ist 0, wenn das Kommando tat, was verlangt war, 1 bei einem Problem, 2 bei einer
Kommandozeile, die es nicht nimmt.

## Ein neues Paket

```sh
hilde new Acme.Json --git --packaging
hilde new module Acme.Json.Parse
```

`hilde new` schreibt `hilde.toml`, eine leere `hilde.sum`, ein Changelog in Debians Form, die ISC-Lizenz mit
dem Autor, den git kennt, `README.md`, `.gitignore` und `src/Json.hih`, `src/Json.hiq` und `src/Json.test.hiq`,
jede Quelle mit einem SPDX-Kopf. `--bin` macht ein Programm mit einer Funktion `main`, `--git` ein
git-Repository, `--packaging` die Skripte `packaging/make_debian_package`, `make_openbsd_package`,
`make_freebsd_package` und `make_source_package`. `hilde new module` legt ein Modul unter `src` nach den Teilen
seines Namens hinter dem des Pakets an, hier `src/Parse.hih`. `SOURCE_DATE_EPOCH` datiert das Changelog.

## hilde.toml

```toml
targets = ["linux", "openbsd"]

[package]
name = "Acme.App"
version = "v0.1.0"
signify-key = "RWS..."
capabilities = ["unsafe", "embed"]

[require]
"Acme.Json" = { git = "https://example.org/json.git", version = "v1.2.0" }

[c-source]
commit = true
dir = "c"

[policy]
require-signatures = true
```

Der Name ist das Modulpräfix des Pakets, seine Module heißen darunter. Eine Version ist `vX.Y.Z`, und die
Version in der `hilde.toml` eines Releases ist sein git-Tag. Eine Anforderung nennt die kleinste Version, die
sie braucht, und wo git das Paket findet, und kann den Schlüssel festlegen, mit dem seine Releases signiert
sind. Schlüssel oder Tabellen, die ein Manifest nicht hat, werden abgewiesen; so fällt ein vertippter
Schlüssel auf.

## Pakete holen

```sh
hilde get Acme.Json@v1.2.0 --git=https://example.org/json.git
hilde get
```

`get` holt jedes verlangte Paket, direkt oder über ein anderes, als git-Tag und wählt die Versionen durch
minimale Versionsauswahl: Jedes Präfix bekommt die größte Version, die ein gewähltes Paket von ihm verlangt,
nie eine neuere. Ein Präfix hat eine Hauptversion; eine neue Hauptversion ist ein neues Präfix, etwa
`Acme.Json2`. Die Bäume kommen nach `vendor/<Präfix>/`, ihre Prüfsummen nach `hilde.sum`:

```text
Acme.Json v1.2.0 h1:0sun7IhfChLljPygSUAzTwodjRy1DIkk5dSyTgM3A1M= key:RWSgBGDjdJGlv/Ssv2UqfdZ9kfEYS1czgn4S5ReDnx9m1cPHwyT0GMWY
```

Die Prüfsumme ist Gos dirhash über die Dateien des Baums; ein Baum hat also eine Prüfsumme, ob er aus git,
aus einem Archiv oder aus `vendor/` kommt. Ein Release ist signiert, wenn sein Baum `signatures/vX.Y.Z.sig`
hat; der Schlüssel wird beim ersten Mal übernommen und in `hilde.sum` geschrieben, und jedes spätere Release
des Präfixes muss mit ihm signiert sein. In `vendor/` und `hilde.sum` ändert sich nichts, solange nicht jedes
Paket geholt und geprüft ist.

In einem Paket findet der Compiler die Module von `src`, jedes Baums in `vendor/` und der Standardbibliothek
selbst: `hilde check`, `hilde test`, `hilde compile`, `hilde lsp` und `hilde guard` brauchen kein `--modules`.

## Prüfen und aktualisieren

```sh
hilde verify
hilde update --check
hilde update
```

`verify` hält `vendor/` ohne Netz gegen `hilde.sum`: Jede Anforderung hat ihre Zeile, jeder Baum ist mit
seiner Prüfsumme da, kein Baum ist übrig, und jedes Ziel aus `hilde.toml` erlaubt das `pragma Targets` jedes
Moduls, das das Paket erreicht. `update` hebt jede Anforderung auf den neuesten Tag ihrer Hauptversion, eine
nach der anderen: Es holt, fährt `hilde test src` und `hilde guard` und nimmt die Anhebung zurück, wenn eins
davon scheitert oder das Paket eine Fähigkeit mehr erklärt. Es gibt die Zeilen der Changelogs zwischen alter
und neuer Version und den Text eines Commits aus. Eine Hauptversion hebt es nie an.

## Fähigkeiten

`hilde guard` sagt in einem Paket für jedes Paket, was seine eigenen Module tun, das es erklären muss:
`unsafe` für ein Modul mit `pragma Unsafe_Module`, `foreign` für eine Fremdfunktion, die das Programm
erreicht, `embed` für ein Embed, das es erreicht. Eine Fähigkeit, die benutzt und nicht in
`[package] capabilities` genannt ist, beendet guard mit dem Exit-Status 4.

## Doc-Tests

Das Beispiel im Docstring einer exportierten Funktion, seine um vier Leerzeichen eingerückten Zeilen, läuft
als eigener Test, wann immer `hilde test` in einem Paket läuft, und sonst mit `--doc`.

## Ein Release

```sh
hilde export --make-key=release
hilde export --secret-key=release.sec
git add -A
git commit -m "release v1.3.0"
git tag v1.3.0
```

`export` verlangt eine Testdatei für jedes Modul, grüne Tests und einen Test, der jede exportierte Funktion
aufruft. Es vergleicht die Schnittstellen mit denen des neuesten Tags und weist eine Version ab, die kleiner
ist, als die Änderung verlangt: Eine entfernte oder geänderte Deklaration, ein strengeres requires oder ein
schwächeres ensures ist eine Hauptversion, eine neue Deklaration eine Nebenversion. Es schreibt `llms.txt`,
eine Handbuchseite je Modul nach `man/man3`, die Signatur des Baums nach `signatures/` und das Archiv mit
seiner Signatur nach `dist/`. `--with-c` schreibt das erzeugte C des Systems, auf dem es läuft, nach `c/`.
`hilde api-diff alt neu` zeigt denselben Vergleich zwischen zwei Verzeichnissen, mit den Aufrufen in `src`
dessen, was brach.

## Doku und Installation

```sh
hilde doc Standard.Text.trim
hilde doc --man Acme.Json > Acme.Json.3
hilde install --prefix=/usr/local --destdir=stage
```

`doc` gibt ein Modul oder eine Deklaration mit Verträgen und Docstring aus, aus `src`, `vendor/` und der
Standardbibliothek, ohne Netz. `install` schreibt nur unter den Staging-Baum: ein Programm nach `bin`, die
Quellen einer Bibliothek nach `share/hilde`, die Handbuchseiten nach `share/man` (auf OpenBSD nach
`man`, außer bei dem Präfix `/usr`), Lizenz und Changelog nach `share/doc`. Die Skripte von `--packaging` packen diesen Baum in ein
Paket des Systems.
