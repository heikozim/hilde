# Syntax von Hilde

Diese Seite beschreibt, wie der Compiler dieses Repositorys Hilde-Quelltext
liest. Maßgeblich sind der Lexer in `lib/Lexer.mll` und der Parser in
`lib/Parser.mly`. Hilde ist aus Austral hervorgegangen. Wo sich die Syntax von
Austral unterscheidet, steht das in einem eigenen Absatz.

Jedes Kapitel außer dem letzten hat Beispiele, und jeder Codeblock ist ein
vollständiges Modul. Ein Block, der mit ```` ```hilde ```` beginnt, ergibt
zusammen mit den übrigen Modulen seines Beispiels ein Programm, das
kompiliert und läuft. Ein Block, der mit ```` ```hilde fails H4012 ````
beginnt, zeigt eine Regel, indem er sie verletzt: Der Compiler lehnt ihn mit
genau diesem Fehlercode ab.

## 1. Kommentare und Literale

**Kommentare.** Ein Kommentar beginnt mit zwei Bindestrichen, `--`, und endet
mit der Zeile. Blockkommentare gibt es nicht.

**Leerraum.** Leerzeichen, Tabulatoren und Zeilenenden trennen die Tokens.
Zeilen enden mit LF oder mit CR LF. Steht außerhalb von Kommentaren und
Strings ein anderes Zeichen, meldet der Compiler einen Fehler.

**Bezeichner.** Ein Bezeichner fängt mit einem Buchstaben an. Danach dürfen
Buchstaben, Ziffern und Unterstriche folgen: `count`, `Max_Size`, `x2`. Groß-
und Kleinschreibung werden unterschieden. Ein einzelnes `_` ist kein
Bezeichner; es ist der Platzhalter in Mustern (Kapitel 11).

**Reservierte Wörter.** Folgende Wörter sind vergeben und taugen nicht als
Bezeichner: `and`, `as`, `body`, `borrow`, `case`, `constant`, `do`, `else`,
`end`, `ensures`, `false`, `for`, `from`, `function`, `generic`, `if`,
`import`, `instance`, `invariant`, `is`, `let`, `method`, `module`, `nil`,
`not`, `of`, `or`, `pragma`, `raise`, `raises`, `record`, `requires`,
`return`, `sizeof`, `skip`, `then`, `to`, `true`, `type`, `typeclass`,
`union`, `var`, `when`, `while`. Hinzu kommen die Typwörter
`Free`, `Linear`, `Region`, `Type` und `Span`.

**Ganze Zahlen.** Dezimal schreibt man `42` oder `-42`, hexadezimal `#xF0`,
binär `#b1010`, oktal `#o755`. Ziffern lassen sich mit einem Apostroph
gliedern: `1'000'000`, `#b0000'1010`. Bei Dezimalzahlen gehört das Vorzeichen
zum Literal; `-1` ist ein einziges Token. Wer subtrahieren will, setzt deshalb
nach dem Minus ein Leerzeichen: `n - 1`, nicht `n -1`. Hexadezimale, binäre
und oktale Literale haben kein Vorzeichen. Welchen Typ ein Zahlen-Literal
bekommt, bestimmt die Stelle, an der es steht: der deklarierte Typ eines
`let`, der Typ der Variablen oder des Pfads, dem es zugewiesen wird, der Typ
des anderen Operanden eines Operators (`55 + i` mit einem `Index` `i` ist ein
`Index`), der Typ, den ein Parameter einer generischen Funktion von den
anderen Argumenten oder vom verlangten Typ des Aufrufs bekommt. Verlangt die
Stelle keinen Typ, wie die Zweige eines `if`-Ausdrucks, ist es ein `Int32`.

**Zeichen.** Zwischen einfachen Anführungszeichen steht ein Buchstabe, eine
Ziffer, ein Leerzeichen oder ein druckbares ASCII-Satzzeichen: `'A'`, `'?'`.
Dazu kommen die Escapes `'\n'`, `'\r'`, `'\t'`, `'\\'` und `'\''`; auch `'''` ist der Apostroph. Ein Zeichen-Literal
ist eine ganze Zahl, nämlich der ASCII-Code des Zeichens. In aller Regel
bekommt es den Typ `Nat8`.

**Gleitkommazahlen.** Auf Ziffern folgt ein Punkt, danach wahlweise weitere
Ziffern und ein Exponent: `3.14`, `-0.5`, `6.25e-2`.

**Strings.** Ein String steht zwischen doppelten Anführungszeichen: `"hello"`.
Er kennt die Escapes `\n`, `\r`, `\t`, `\"`, `\'` und `\\` sowie `\u{X}`, den Codepunkt X
in einer bis sechs Hexadezimalziffern, als UTF-8 geschrieben: `"caf\u{e9}"`
hat fünf Bytes. Folgt auf einen
Backslash Leerraum, fällt alles bis zum nächsten Backslash weg. So lässt sich
ein langer String über zwei Zeilen schreiben. Ein String-Literal hat den Typ
`Span[Nat8, Static]`.

**Strings über mehrere Zeilen.** Zwischen `"""` und `"""` darf Text über
mehrere Zeilen gehen. Ist die erste oder die letzte Zeile leer, entfällt sie,
und die Einrückung, die allen Zeilen gemeinsam ist, wird abgezogen. Drei
Anführungszeichen im Text schreibt man als `\"""`.

**Docstrings.** Steht ein solcher String unmittelbar vor einem Modul, einer
Deklaration, einem Slot eines Records, einem Fall einer Union oder einer
Methode, dokumentiert er sie.

**Weitere Werte.** `Bool` hat die Werte `true` und `false`. `Unit` hat genau
einen Wert, `nil`.

**Auf einen Blick.**

| Form | Beispiel | Typ |
| --- | --- | --- |
| Dezimale ganze Zahl | `42`, `-42`, `1'000'000` | was die Stelle verlangt, sonst `Int32` |
| Hexadezimale ganze Zahl | `#xF0` | wie eine dezimale ganze Zahl; ohne Vorzeichen |
| Binäre ganze Zahl | `#b1010` | wie eine dezimale ganze Zahl; ohne Vorzeichen |
| Oktale ganze Zahl | `#o755` | wie eine dezimale ganze Zahl; ohne Vorzeichen |
| Zeichen | `'A'`, `'\n'` | eine ganze Zahl, meist `Nat8` |
| Gleitkommazahl | `3.14`, `-0.5`, `6.25e-2` | `Float32` oder `Float64`, je nach Stelle |
| String | `"hello"` | `Span[Nat8, Static]` |
| String in dreifachen Anführungszeichen | `"""text"""` | `Span[Nat8, Static]` |
| Wahrheitswert | `true`, `false` | `Bool` |
| Wert von `Unit` | `nil` | `Unit` |

| Escape | steht für | im Zeichen | im String |
| --- | --- | --- | --- |
| `\n` | Zeilenvorschub | ja | ja |
| `\r` | Wagenrücklauf | ja | ja |
| `\t` | Tabulator | ja | ja |
| `\\` | Backslash | ja | ja |
| `\"` | doppeltes Anführungszeichen | nein | ja |
| `\'` | einfaches Anführungszeichen | ja | ja |
| `\u{e9}` | ein Codepunkt als UTF-8 | nein | ja |

```hilde
-- Two hyphens start a comment. It runs to the end of the line.
module body Example.Literals is
    function main(): ExitCode is
        let million: Int32 := 1'000'000;
        let below: Int32 := -42;
        let mask: Nat8 := #xF0;
        let bits: Nat8 := #b0000'1010;
        let mode: Nat16 := #o755;
        let letter: Nat8 := 'A';
        let apostrophe: Nat8 := '\'';
        let accented: Span[Nat8, Static] := "caf\u{e9}";
        let ratio: Float64 := 6.25e-2;
        let yes: Bool := true;
        let nothing: Unit := nil;
        let quoted: Span[Nat8, Static] := "a \"quoted\" word";
        let joined: Span[Nat8, Static] := "one string, \
            \written in two lines";
        let block: Span[Nat8, Static] := """
            Triple quotes span lines.
              Shared indentation is removed.
            """;
        printLn(million);
        printLn(below);
        printLn(mask);
        printLn(bits);
        printLn(mode);
        printLn(letter);
        printLn(apostrophe);
        printLn(accented);
        printLn(ratio);
        printLn(yes);
        printLn(nothing);
        printLn(quoted);
        printLn(joined);
        printLn(block);
        return ExitSuccess();
    end;
end module body.
```

## 2. Module

Zu einem Modul gehören zwei Dateien. Das Interface, eine `.hih`-Datei, legt
fest, was andere Module verwenden dürfen. Der Body, eine `.hiq`-Datei, enthält
die Umsetzung.

Abweichung von Austral: Dort heißen die beiden Dateien `.aui` und `.aum`.

Ein Interface ist so aufgebaut:

- wahlweise ein Docstring,
- beliebig viele Importe,
- `module Name is`, die Deklarationen, `end module.`

Ein Body ist so aufgebaut:

- wahlweise ein Docstring,
- beliebig viele Modul-Pragmas (Kapitel 10),
- beliebig viele Importe,
- `module body Name is`, die Definitionen, `end module body.`

Modulnamen bestehen aus einem oder mehreren Bezeichnern mit Punkten
dazwischen, etwa `Example.Counter`.

**Importe.** `import Example.Counter (make, finish as total);` macht die
genannten Namen sichtbar; mit `as` bekommt ein Name hier einen anderen. Ein
Import zählt seine Namen immer auf, ein ganzes Modul auf einmal lässt sich
nicht importieren. Importe stehen vor dem Wort `module`.

**Opake Typen.** Ein Interface darf einen Typ nennen, ohne ihn offenzulegen:
`type Counter: Linear;`. Im Body wird er als Record oder Union definiert.
Andere Module können mit dem Typ arbeiten, seine Slots sehen sie nicht.

**Die Prelude.** Das Modul `Hilde.Pervasive` ist in jedem Modul ohne Import
sichtbar. Es stellt unter anderem `Option`, `Either`, `ExitCode` und `printLn`
bereit.

Abweichung von Austral: Dort heißt die Prelude `Austral.Pervasive`.

**Programme.** Ein Programm startet in einer Funktion `main(): ExitCode`;
welche das ist, gibt man auf der Kommandozeile an. `ExitSuccess()` beendet
den Prozess mit Status 0, `ExitFailure()` mit 1 und
`ExitStatus(status => n)` mit `n`, einem `Nat8` von 0 bis 125. Ein größeres
`n` hält das Programm mit der Meldung `Exit status above 125.` an, denn die
Shell vergibt 126 und 127 an einen Befehl, den sie nicht starten konnte, und
128 und mehr an ein Signal. Das Hauptmodul hat häufig
nur einen Body. Das folgende Beispiel verteilt sich auf drei Dateien und wird
so übersetzt:
`hilde compile Counter.hih,Counter.hiq Main.hiq --entrypoint=Example.Main:main --output=main`

Das Interface, `Counter.hih`:

```hilde
"""
A counter that other modules cannot look inside.
"""
module Example.Counter is
    type Counter: Linear;

    constant start: Nat32;

    function make(): Counter;

    function next(counter: Counter): Counter;

    function finish(counter: Counter): Nat32;
end module.
```

Der Body, `Counter.hiq`:

```hilde
module body Example.Counter is
    record Counter: Linear is
        value: Nat32;
    end;

    constant start: Nat32 := 10;

    function make(): Counter is
        return Counter(value => start);
    end;

    function next(counter: Counter): Counter is
        let { value: Nat32 } := counter;
        return Counter(value => value + 1);
    end;

    function finish(counter: Counter): Nat32 is
        let { value: Nat32 } := counter;
        return value;
    end;
end module body.
```

Das Hauptmodul, `Main.hiq`:

```hilde
import Example.Counter (Counter, make, next, finish as total);

module body Example.Main is
    function main(): ExitCode is
        let first: Counter := make();
        let second: Counter := next(first);
        let third: Counter := next(second);
        printLn(total(third));
        return ExitSuccess();
    end;
end module body.
```

**Tests.** Eine Testdatei ist ein Modul-Body neben dem Modul, das sie
testet, in einer Datei, deren Name auf `.test.hiq` endet. Jede ihrer
Funktionen, deren Name `test` gefolgt von einem Großbuchstaben oder einer
Ziffer ist, ist ein Test, und ein Test hat eine von zwei Formen: `function
testName(): Unit` oder, wenn er die Root-Fähigkeit braucht, `generic [R:
Region] function testName(root: &![RootCapability, R]): Unit`. Ein Test
besteht, wenn er zurückkehrt, und scheitert, wenn er das Programm beendet,
mit `abort` oder mit einer Zusicherung aus `Standard.Testing`.
`hilde test .` führt die Testdateien des Verzeichnisses und der
darunterliegenden aus: ein Programm je Datei, jeder Test in einem eigenen
Prozess. `--race`, `--memory` und `--valgrind` bauen und starten die Tests unter
ThreadSanitizer, AddressSanitizer mit UndefinedBehaviorSanitizer oder
valgrind. `--jobs=N` baut und startet N Testdateien zugleich; der Bericht ist
derselbe wie mit einer. `--test-jobs=M` startet M Tests einer Datei zugleich,
und `--fresh-dirs` startet jeden Test in einem eigenen leeren Verzeichnis, das
Tests brauchen, die dieselbe Datei schreiben.

Abweichung von Austral: Austral hat keinen Testbefehl.

Die Tests des Zählers oben, `Counter.test.hiq`:

```hilde
import Example.Counter (make, next, finish);

module body Example.Counter.Test is
    function testStartsAtTen(): Unit is
        if finish(make()) /= 10 then
            abort("a new counter is not 10");
        end if;
        return nil;
    end;

    function testCountsOne(): Unit is
        if finish(next(make())) /= 11 then
            abort("one step does not give 11");
        end if;
        return nil;
    end;
end module body.
```

Eine Funktion mit dem Namen eines Tests und einer anderen Form wird
abgelehnt, nicht übergangen:

```hilde fails H2046
module body Example.Length.Test is
    function testLength(n: Nat32): Unit is
        return nil;
    end;
end module body.
```

## 3. Deklarationen

Im Interface stehen Deklarationen: `constant`, `type`, `record`, `union`,
`function`, `typeclass` und `instance`. Im Body stehen Definitionen. Das sind
dieselben Arten ohne `type`, nur mit Inhalt.

**Konstanten.** Im Interface steht `constant limit: Int32;`, im Body
`constant limit: Int32 := 100;`.

**Records.** Ein Record besteht aus benannten Slots:

- `record Point: Free is x: Int32; y: Int32; end;`

Hinter dem Doppelpunkt steht das Universum des Records (Kapitel 4). Einen Wert
baut man, indem man den Namen des Records mit benannten Argumenten aufruft:
`Point(x => 1, y => 2)`. Auf einen Slot greift man mit einem Punkt zu:
`origin.x`.

**Unions.** Eine Union besteht aus Fällen. Ein Fall hat entweder keine Slots
oder Slots wie ein Record:

- `union Shape: Free is case Dot; case Circle is radius: Int32; end;`

Einen Wert baut man mit dem Namen eines Falls: `Circle(radius => 5)`,
`Dot()`.

**Funktionen.** Auf `function name(parameter: Type, ...): ReturnType is`
folgen die Anweisungen und `end;`. Im Interface endet die Deklaration schon
nach dem Rückgabetyp mit `;`. Das Ergebnis liefert `return`. Hat eine
Funktion nichts zu liefern, ist ihr Rückgabetyp `Unit` und sie gibt `nil`
zurück.

**Generische Deklarationen** beginnen mit `generic [...]` (Kapitel 9).

Jeder Deklaration darf ein Docstring vorangehen, ebenso den Slots eines
Records und den Fällen einer Union.

```hilde
module body Example.Declarations is
    """
    The largest side a rectangle may have.
    """
    constant limit: Int32 := 100;

    record Point: Free is
        """
        Distance from the left edge.
        """
        x: Int32;
        y: Int32;
    end;

    union Shape: Free is
        case Dot;
        case Circle is
            radius: Int32;
        case Rectangle is
            width: Int32;
            height: Int32;
    end;

    function perimeter(corner: Point): Int32 is
        return 2 * (corner.x + corner.y);
    end;

    function main(): ExitCode is
        let corner: Point := Point(x => 3, y => 4);
        let small: Shape := Circle(radius => 5);
        let large: Shape := Rectangle(width => 3, height => limit);
        let none: Shape := Dot();
        printLn(perimeter(corner));
        return ExitSuccess();
    end;
end module body.
```

**Verträge.** Eine Funktion kann einen Vertrag tragen: nach dem
Rückgabetyp Klauseln `requires Bedingung` und `ensures Bedingung`, in
beliebiger Zahl und Reihenfolge, vor dem `;` im Interface oder dem `is`
im Body. Jede Bedingung ist ein Ausdruck vom Typ `Bool`. Ein requires wird
beim Eintritt in die Funktion geprüft, ein ensures bei ihrer Rückkehr,
und die Prüfungen sind immer an. Eine verletzte Bedingung hält das
Programm an, mit einer Meldung, die die Bedingung, die Funktion und die
Stelle des Vertrags nennt; bei einem requires auch den Aufruf, dessen
Aufrufer schuld ist, bei einem ensures die Stelle der Funktion im Body,
die schuld ist. In einem ensures ist `result` der zurückgegebene Wert
und `old(e)` der Wert, den `e` beim Eintritt in die Funktion hatte;
`old` nimmt einen freien Wert.

Eine Bedingung liest nur: Einen linearen Wert verwendet sie über eine
Referenz, sie nimmt keine Referenz zum Schreiben, und sie ruft keine
Funktion, die ein Binding-Modul oder C erreicht oder eine Referenz zum
Schreiben verlangt, wie tief der Aufruf auch reicht. Eine
Schreibreferenz, die ein Parameter ist, wird mit `&` gelesen. Der
Vertrag einer öffentlichen Funktion steht nur in ihrem Interface; eine
Funktion, die das Interface nicht deklariert, hat ihn im Body.
Operatoren nehmen atomare Operanden, daher hat eine Bedingung mit mehr
als einem Vergleich Klammern. Eine Funktion mit einem requires lässt sich
nicht als Funktionszeiger nehmen, und die Einstiegsfunktion und ein Test
haben keins.

**Invarianten.** Ein Record kann zwischen seinen Slots Invarianten
angeben, `invariant Bedingung;`, und nennt die Slots bei ihren Namen.
Eine Invariante gilt für jeden Wert, der das Modul verlässt: Sie wird bei
jeder Rückkehr einer öffentlichen Funktion des Moduls geprüft, für jeden
Parameter, der eine Schreibreferenz auf den Record ist, und für ein
Ergebnis vom Typ des Records oder eines, das den Record als Nutzlast
eines `Option` (sein `Some`) oder als Erfolg eines `Either` (sein
`Right`) enthält, und ihre Bedingung liest nur, wie die eines Vertrags.
Ein Record in einem anderen Typ, einem Paar oder einem Puffer von ihnen,
wird nicht untersucht. Eine Funktion, die das Interface nicht deklariert, darf
durch einen verletzten Zustand gehen. Eine Invariante hat nur ein Record,
den sein Modul allein bauen und beschreiben kann: Das Interface
deklariert seinen Typ opak oder gar nicht.

**Verträge testen.** `hilde test --contracts` ruft jede öffentliche
Funktion, die einen Vertrag hat und deren Parameter alle Ganzzahlen,
`Index` oder `Bool` sind, mit Eingaben auf, die aus einem Seed gezogen
werden: zuerst Randwerte, dann gezogene. Es behält die Eingaben, die ihr
requires annimmt, und lässt ihr ensures prüfen; eine Funktion, von der
keine Eingabe angenommen wird, scheitert. `--seed=N` wiederholt einen
Lauf, und ein Fehlschlag zeigt den Seed, die Runde und die Eingaben;
`--rounds=N` setzt die Eingaben je Funktion, 100 ohne Angabe.

Unterschied zu Austral: Verträge und Invarianten sind neu in Hilde.

```hilde
module Example.Gauge is
    record Counter: Linear is
        count: Nat32;
    end;

    generic [R: Region]
    function peek(counter: &[Counter, R]): Nat32;

    generic [R: Region]
    function bump(counter: &![Counter, R], limit: Nat32): Unit
        requires peek(&counter) < limit
        ensures peek(&counter) = (old(peek(&counter)) + 1);
end module.
```

```hilde
module body Example.Gauge is
    generic [R: Region]
    function peek(counter: &[Counter, R]): Nat32 is
        return counter->count;
    end;

    generic [R: Region]
    function bump(counter: &![Counter, R], limit: Nat32): Unit is
        counter->count := counter->count + 1;
        return nil;
    end;
end module body.
```

```hilde
import Example.Gauge (
    Counter,
    peek,
    bump
);

module body Example.Contracts is
    function half(n: Nat32): Nat32
        requires n > 0
        ensures (result * 2) <= n
    is
        return n / 2;
    end;

    function main(): ExitCode is
        var c: Counter := Counter(count => 0);
        bump(&!c, 3);
        bump(&!c, 3);
        printLn(peek(&c));
        printLn(half(9));
        let { count: Nat32 } := c;
        printLn(count);
        return ExitSuccess();
    end;
end module body.
```

```hilde
module Example.Interval is
    type Interval: Free;

    function make(low: Nat32, high: Nat32): Interval;

    function width(interval: Interval): Nat32;
end module.
```

```hilde
module body Example.Interval is
    record Interval: Free is
        low: Nat32;
        high: Nat32;
        invariant low <= high;
    end;

    function make(low: Nat32, high: Nat32): Interval is
        return Interval(low => low, high => high);
    end;

    function width(interval: Interval): Nat32 is
        return interval.high - interval.low;
    end;
end module body.
```

```hilde
import Example.Interval (
    Interval,
    make,
    width
);

module body Example.Intervals is
    function main(): ExitCode is
        let i: Interval := make(3, 10);
        printLn(width(i));
        return ExitSuccess();
    end;
end module body.
```

```hilde fails H3096
module body Example.ContractConsumes is
    record Token: Linear is
        value: Nat32;
    end;

    function valueOf(token: Token): Nat32 is
        let { value: Nat32 } := token;
        return value;
    end;

    function spend(token: Token): Nat32
        requires valueOf(token) > 0
    is
        return valueOf(token);
    end;

    function main(): ExitCode is
        printLn(spend(Token(value => 3)));
        return ExitSuccess();
    end;
end module body.
```

**Fehlerarten.** Eine Funktion kann die Fehlerarten nennen, mit denen sie
enden kann: nach dem Rückgabetyp eine Klausel `raises NotFound, Denied`,
unter den Vertragsklauseln und vor `;` in einem Interface oder `is` in
einem Body. Eine Art ist ein Name, geschrieben wie ein Bezeichner; sie
wird nirgends deklariert und hat keinen Wert. `raise NotFound;` ist eine
Anweisung, die das Programm mit dieser Art als Meldung beendet, so wie
`abort` es mit einem Text beendet, und nichts fängt sie ab. Eine Funktion
darf nur die Arten auslösen, die ihre eigene Klausel nennt, und nur
Funktionen aufrufen, deren Arten sie nennt: Ein Aufruf, dessen Ziel eine
Art trägt, die die Klausel des Aufrufers nicht hat, wird abgewiesen, und
ebenso eine Funktion ohne Klausel, die eine auslöst oder aufruft.
`abort`, ein verletzter Vertrag und eine Rechenfalle sind Panics: Sie
tragen keine Art, und keine Klausel nennt sie. Die Klausel einer
öffentlichen Funktion steht nur in ihrem Interface, wie ihr Vertrag. Eine
Typklasse schreibt die Klausel an eine Methode, `method measure(value: T):
Int32 raises Broken;`, und jede Instanz erbt sie; eine Klausel an der
Methode einer Instanz wird abgewiesen. Eine Funktion mit einer
raises-Klausel lässt sich nicht als Funktionszeiger nehmen. `hilde query`
nennt die Arten einer Funktion unter `raises`.

Unterschied zu Austral: Fehlerarten sind neu in Hilde.

```hilde
module Example.Store is
    function fetch(key: Nat32): Nat32
        raises NotFound;
end module.
```

```hilde
module body Example.Store is
    function fetch(key: Nat32): Nat32 is
        if key > 100 then
            raise NotFound;
        end if;
        return key * 2;
    end;
end module body.
```

```hilde
import Example.Store (
    fetch
);

module body Example.Stores is
    function lookup(key: Nat32): Nat32
        raises NotFound is
        return fetch(key);
    end;

    function main(): ExitCode
        raises NotFound is
        printLn(lookup(21));
        return ExitSuccess();
    end;
end module body.
```

```hilde fails H3103
module body Example.StoreUnnamed is
    function fetch(key: Nat32): Nat32
        raises NotFound is
        return key;
    end;

    function main(): ExitCode is
        printLn(fetch(21));
        return ExitSuccess();
    end;
end module body.
```

## 4. Typen und Universen

**Wie man Typen schreibt.**

- Mit dem Namen: `Int32`.
- Mit dem Namen und Typargumenten in eckigen Klammern: `Option[Int32]`,
  `Pair[Int32, Bool]`.
- Als Referenz: `&[T, R]` zum Lesen, `&![T, R]` zum Schreiben (Kapitel 7).
- Als Span, also als Blick auf hintereinander liegende Werte: `Span[T, R]`
  zum Lesen, `Span![T, R]` zum Schreiben.

`R` ist bei Referenzen und Spans jeweils eine Region.

**Eingebaute Typen.** `Unit` und `Bool`; die vorzeichenlosen Ganzzahltypen
`Nat8`, `Nat16`, `Nat32` und `Nat64`; die vorzeichenbehafteten `Int8`,
`Int16`, `Int32` und `Int64`; `Index` für Positionen und Anzahlen; `ByteSize`
für Größen in Bytes; die Gleitkommatypen `Float32` und `Float64`.

`Nat` kommt von den natürlichen Zahlen 0, 1, 2 und so weiter; ein `Nat` ist
also nie negativ: `Nat8` ist eine natürliche Zahl in 8 Bit, 0 bis 255.

| Typ | Kleinster Wert | Größter Wert | Wofür |
| --- | --- | --- | --- |
| `Unit` | `nil` | `nil` | ein Ergebnis, das nichts trägt; `nil` ist sein einziger Wert |
| `Bool` | `false` | `true` | Bedingungen |
| `Nat8` | 0 | 255 | Bytes und Zeichen; Text ist ein `Span[Nat8, R]` |
| `Nat16` | 0 | 65535 | vorzeichenlose ganze Zahlen in 16 Bit |
| `Nat32` | 0 | 4294967295 | vorzeichenlose ganze Zahlen in 32 Bit |
| `Nat64` | 0 | 18446744073709551615 | vorzeichenlose ganze Zahlen in 64 Bit |
| `Int8` | -128 | 127 | ganze Zahlen mit Vorzeichen in 8 Bit |
| `Int16` | -32768 | 32767 | ganze Zahlen mit Vorzeichen in 16 Bit |
| `Int32` | -2147483648 | 2147483647 | ganze Zahlen mit Vorzeichen in 32 Bit; ein Zahlen-Literal, wo kein Typ verlangt ist |
| `Int64` | -9223372036854775808 | 9223372036854775807 | ganze Zahlen mit Vorzeichen in 64 Bit |
| `Index` | 0 | 18446744073709551615 | Positionen und Anzahlen |
| `ByteSize` | 0 | 18446744073709551615 | Größen in Bytes; der Typ von `sizeof` |
| `Float32` | etwa -3.4028235e38 | etwa 3.4028235e38 | Gleitkommazahlen in 32 Bit, das `float` von C |
| `Float64` | etwa -1.7976931348623157e308 | etwa 1.7976931348623157e308 | Gleitkommazahlen in 64 Bit, das `double` von C |

Die Grenzen der ganzen Zahlen sind die, gegen die der Compiler ein Literal
prüft: Ein `Nat8`, geschrieben als `-1` oder `256`, lehnt er ab. `Index` und
`ByteSize` sind das `size_t` von C; ihr größter Wert hängt also von der
Maschine ab, die Tabelle zeigt ihn für eine 64-Bit-Maschine. Die Grenzen der
Gleitkommatypen sind die größten endlichen Werte, gerundet auf die gezeigten
Stellen.

**Never.** `Never` ist der Ergebnistyp einer Funktion, die nicht
zurückkommt: Sie beendet das Programm oder endet nie. `abort` gibt ihn
zurück. Eine Funktion mit Ergebnis `Never` hat kein `return`; jeder Pfad
durch sie endet in einem Aufruf einer Funktion, die `Never` zurückgibt, in
einem `raise` oder in einer Schleife `while true` (H2060, H2061), und sie
hat kein `ensures` (H2062). Auch der Pfad jeder anderen Funktion endet
dort, also folgt einem Aufruf von `abort` kein Schein-`return`. `Never` ist
kein Wert: Kein Parameter, keine Variable, kein Feld, keine Konstante und
kein Typargument hat ihn (H3109), und ein Aufruf, der ihn zurückgibt, wird
nicht als Argument oder Operand weitergereicht (H3110). Er steht, wo ein
Wert erwartet wird: in einem `let`, einer Zuweisung, einem `return` oder
einem Zweig eines `if`-Ausdrucks. In C ist die Funktion `_Noreturn`.
Unterschied zu Austral: neu in Hilde, nach Adas `No_Return` und C17s
`_Noreturn`.

```hilde
module body Example.Never is
    function stop(message: Span[Nat8, Static]): Never is
        abort(message);
    end;

    function positive(n: Int32): Int32 is
        if n > 0 then
            return n;
        end if;
        stop("not positive");
    end;

    function main(): ExitCode is
        printLn(positive(3));
        return ExitSuccess();
    end;
end module body.
```

**Universen.** Jeder Typ liegt in einem Universum. Die Deklaration nennt es
hinter dem Doppelpunkt:

- `Free`: Werte dürfen beliebig kopiert und verworfen werden.
- `Linear`: Jeder Wert wird genau einmal verwendet, und zwar indem man ihn an
  eine Funktion übergibt, ihn zurückgibt oder ihn zerlegt. Die Regeln dazu
  stehen in Kapitel 8.
- `Type`: nur für Typparameter und generische Typen. Ein Parameter aus `Type`
  nimmt Free- wie Linear-Typen. Ein generischer Record aus `Type` ist Free,
  sobald seine Typargumente Free sind.
- `Region`: nur für Typparameter, die eine Region bezeichnen.

Die Region `Static` gilt für Werte, die so lange leben wie das Programm, zum
Beispiel String-Literale.

```hilde
module body Example.Types is
    record Pair[A: Type, B: Type]: Type is
        first: A;
        second: B;
    end;

    record Ticket: Linear is
        number: Nat32;
    end;

    function main(): ExitCode is
        let empty: Unit := nil;
        let flag: Bool := false;
        let a: Nat8 := 200;
        let b: Nat16 := 60'000;
        let c: Nat32 := 4'000'000'000;
        let d: Nat64 := 18'000'000'000'000'000'000;
        let e: Int8 := -100;
        let f: Int16 := -30'000;
        let g: Int32 := -2'000'000'000;
        let h: Int64 := -9'000'000'000'000'000'000;
        let position: Index := 3;
        let size: ByteSize := 64;
        let half: Float32 := 0.5;
        let third: Float64 := 0.333;
        let pair: Pair[Int32, Bool] := Pair(first => 7, second => true);
        let ticket: Ticket := Ticket(number => 1);
        let { number: Nat32 } := ticket;
        let text: Span[Nat8, Static] := "span";
        printLn(d);
        printLn(h);
        printLn(half);
        printLn(pair.first);
        printLn(number);
        printLn(spanLength(text));
        return ExitSuccess();
    end;
end module body.
```

## 5. Anweisungen

**Bindungen.** `let name: Type := value;` führt einen Namen ein, dessen Wert
fest bleibt; bei `var name: Type := value;` darf er sich ändern. Den Typ
schreibt man immer aus.

**Zerlegen.** `let { x: Int32, y as height: Int32 } := point;` nimmt einen
Record auseinander. Jeder Slot landet in einem Namen, mit `as` in einem
anderen als seinem eigenen. `var` ist hier ebenfalls erlaubt.

**Zuweisung.** `place := value;` Die Stelle ist eine Variable, der beliebig
oft `.slot`, `->slot` oder `[index]` folgen darf.

**Bedingungen.**

- `if condition then ... end if;`
- `if condition then ... else ... end if;`
- `if condition then ... else if condition then ... else ... end if;`

Als Einheit gilt `else if` nur, wenn beide Wörter in derselben Zeile stehen,
nur durch Leerzeichen oder Tabulatoren getrennt. Steht `else` am Zeilenende
und `if` am Anfang der nächsten Zeile, beginnt im `else`-Block ein neues
`if`, das sein eigenes `end if;` braucht.

**Schleifen.**

- `while condition do ... end while;`
- `for i from first to last do ... end for;`

Die Laufvariable von `for` ist ein `Index`. Beide Grenzen werden
durchlaufen.

**Weitere Anweisungen.**

- `return value;` verlässt die Funktion.
- `skip;` bewirkt nichts.
- `raise Kind;` beendet das Programm mit einer Fehlerart (Abschnitt 3).
- Ein Ausdruck mit `;` dahinter ist ebenfalls eine Anweisung, meistens ein
  Aufruf: `printLn(total);`.

Jeder Block, etwa der zwischen `then` und `else`, braucht mindestens eine
Anweisung. Gibt es nichts zu tun, steht dort `skip;`.

Zu `case` siehe Kapitel 11, zu `borrow` Kapitel 7.

Abweichung von Austral: Wirft eine Anweisung ein `Option` oder ein `Either`
einfach weg, lehnt der Compiler sie ab. Wer das absichtlich tut, schreibt
`ignore(value);`.

```hilde
module body Example.Statements is
    record Point: Free is
        x: Int32;
        y: Int32;
    end;

    function main(): ExitCode is
        let limit: Int32 := 5;
        var total: Int32 := 0;
        var count: Int32 := 0;
        while count < limit do
            count := count + 1;
            if count = 2 then
                skip;
            else if count = 4 then
                total := total + 100;
            else
                total := total + count;
            end if;
        end while;
        printLn(total);
        for i from 1 to 3 do
            printLn(i);
        end for;
        var point: Point := Point(x => 1, y => 2);
        point.x := 10;
        let { x: Int32, y as height: Int32 } := point;
        printLn(x + height);
        return ExitSuccess();
    end;
end module body.
```

## 6. Ausdrücke

**Kein Vorrang.** Operanden eines Operators sind stets atomare Ausdrücke:
Literale, Namen, Aufrufe, Pfade, geklammerte Ausdrücke sowie die Formen `&x`,
`&!x`, `&~x`, `&(path)`, `&!(path)`, `!e`, `sizeof(T)` und `e?`. `a + b * c`
lässt sich deshalb nicht parsen, es heißt `a + (b * c)`, und genauso
`(a < b) and (b < c)`. Die vier assoziativen Operatoren `+`, `*`, `and` und
`or` dürfen eine Kette aus demselben Operator bilden, gelesen von links:
`a + b + c` ist `(a + b) + c`, `a and b and c` ist `(a and b) and c`. Eine
Kette aus `-` oder `/` oder aus zwei verschiedenen Operatoren lässt sich nicht
parsen: `(a - b) - c`.

**Operatoren.**

| Operator | Bedeutung | Beispiel |
| --- | --- | --- |
| `+` | Addition | `a + b` |
| `-` | Subtraktion | `a - b` |
| `*` | Multiplikation | `a * b` |
| `/` | Division | `a / b` |
| `-` vor einem Operanden | Negation | `-a` |
| `=` | gleich | `a = b` |
| `/=` | ungleich | `a /= b` |
| `<` | kleiner | `a < b` |
| `<=` | kleiner oder gleich | `a <= b` |
| `>` | größer | `a > b` |
| `>=` | größer oder gleich | `a >= b` |
| `and` | wahr, wenn beide wahr sind | `a and b` |
| `or` | wahr, wenn mindestens einer wahr ist | `a or b` |
| `not` | das Gegenteil einer Bedingung | `not a` |
| `?` | der Wert aus einem `Option` oder `Either`, sonst Rücksprung | `half(n)?` |
| `:` | Typangabe | `5 : Int64` |
| `&` | zum Lesen ausleihen | `&x` |
| `&!` | zum Schreiben ausleihen | `&!x` |
| `&~` | eine Schreib-Referenz weiterleihen | `&~r` |
| `&( )` | eine Lese-Referenz auf einen Teil | `&(r->slot)` |
| `&!( )` | eine Schreib-Referenz auf einen Teil | `&!(r->slot)` |
| `!` | der Wert hinter einer Referenz | `!r` |
| `.` | ein Slot eines Records | `p.slot` |
| `->` | ein Slot über eine Referenz | `r->slot` |
| `[ ]` | ein Element eines Spans | `s[i]` |

Negation und `not` beziehen sich auf einen atomaren Ausdruck: `not (a = b)`.

Abweichung von Austral: Austral versteht `-a` als `0 - a`. In Hilde ist `-a`
eine Operation für sich, nämlich die Methode `trappingNegate` der Typklasse
`TrappingNegation`.

**Bedingter Ausdruck.** `if condition then a else b` liefert einen Wert.

**Typangabe.** `e : T` hat drei Aufgaben. Es gibt einem Zahlen-Literal einen
Typ (`5 : Int64`), es wandelt eine Schreib- in eine Lese-Referenz, und es
teilt einem generischen Aufruf mit, welchen Typ er liefern soll.

**Größe.** `sizeof(T)` gibt an, wie viele Bytes ein Wert vom Typ `T` belegt,
als `ByteSize`.

**Aufrufe.** Argumente übergibt man entweder alle nach Position, `f(1, 2)`,
oder alle mit Namen, `f(first => 1, second => 2)`. In einem Aufruf mischen
lassen sich beide Arten nicht.

**Pfade.** `p.slot` liest einen Slot eines Records, `r->slot` einen Slot
hinter einer Referenz, `s[i]` ein Element eines Spans.

**Weiterreichen mit `?`.** `e?` packt den Wert aus einem `Option` oder einem
`Either` aus. Aus `Some(value => v)` wird `v`; bei `None()` kehrt die
umgebende Funktion sofort mit `None()` zurück. Aus `Right(right => v)` wird
`v`; bei einem `Left` kehrt die Funktion mit genau diesem `Left` zurück. `e?`
darf nur als ganze rechte Seite eines `let` oder als ganze Anweisung stehen.
`!e?` bedeutet `!(e?)`; wer die andere Reihenfolge will, schreibt `(!e)?`.

Abweichung von Austral: `?` gibt es erst in Hilde.

```hilde
module body Example.Expressions is
    function half(n: Int32): Option[Int32] is
        if rem(n, 2) = 0 then
            let result: Option[Int32] := Some(value => n / 2);
            return result;
        else
            let result: Option[Int32] := None();
            return result;
        end if;
    end;

    function quarter(n: Int32): Option[Int32] is
        let h: Int32 := half(n)?;
        let q: Int32 := half(h)?;
        let result: Option[Int32] := Some(value => q);
        return result;
    end;

    function mark(small: Bool, even: Bool): Int32 is
        return if small and even then 1 else 0;
    end;

    function main(): ExitCode is
        let a: Int32 := 7;
        let b: Int32 := 3;
        printLn((a + b) * 2);
        printLn(-a);
        printLn((a > b) and (not (a = b)));
        printLn(if a /= b then a else b);
        printLn(5 : Int64);
        let bytes: ByteSize := sizeof(Int64);
        printLn(bytes);
        printLn(mark(small => true, even => false));
        case quarter(20) of
            when Some(value: Int32) do
                printLn(value);
            when None do
                printLn("not a multiple of four");
        end case;
        return ExitSuccess();
    end;
end module body.
```

## 7. Referenzen und Borrowing

Eine Referenz verweist auf einen Wert, der einem anderen gehört. Sie ist an
eine Region gebunden, also an ein benanntes Stück Code, in dem sie gültig ist.

**Referenztypen.** Über `&[T, R]` liest man ein `T` in der Region `R`, über
`&![T, R]` darf man es auch ändern.

**Variablen ausleihen.** `&x` leiht die Variable `x` zum Lesen aus, `&!x` zum
Schreiben. Ausleihen kann man nur Variablen. Soll eine Variable zum Schreiben
ausgeliehen werden, muss sie mit `var` deklariert sein.

Ist `w` eine Schreib-Referenz, dann ist `&w` eine Lese-Referenz auf den Wert,
auf den `w` verweist, mit einer eigenen Region. Solange sie lebt, lässt sich
`w` nicht benutzen.

Abweichung von Austral: Dort ist `&w` eine Referenz auf die Variable `w`
selbst, also eine Referenz auf eine Referenz.

**Weiterleihen.** Wer eine Schreib-Referenz weitergibt, hat sie damit
verbraucht. `&~r` gibt stattdessen eine neue Schreib-Referenz weiter, und `r`
bleibt danach benutzbar. Eine Schreib-Referenz kann einen eigenen Namen
bekommen, `let w: &![T, R] := r;`; damit wird sie verschoben, wie beim
Weitergeben.

**Mit Referenzen arbeiten.**

- `!r` liefert den Wert hinter `r`.
- `r->slot` liest einen Slot des Records hinter `r`. Nimmt eine Funktion eine
  Schreib-Referenz `r` entgegen, ändert sie den Slot mit `r->slot := value;`.
- `&(r->slot)` ergibt eine Lese-Referenz auf genau diesen Slot, in der
  Region von `r`, gleich ob `r` liest oder schreibt. `&!(r->slot)` ergibt
  eine Schreib-Referenz darauf und braucht eine Schreib-Referenz `r`. Der
  Pfad darf weitergehen, etwa `&(r->a->b)`. Beide Formen verbrauchen eine
  Schreib-Referenz `r`.

Abweichung von Austral: Dort hat `&(path)` die Art der Referenz, die der
Anfang des Pfads hat, und `&!(path)` gibt es nicht.

**Die borrow-Anweisung** gibt der Region einen Namen:

- `borrow name: &[T, R] := &x do ... end borrow;`

Innerhalb des Blocks ist `name` eine Referenz mit der Region `R`. Hinter `:=`
steht `&x` für Lesen, `&!x` für Schreiben und `&~x` für Weiterleihen. Allein
dieses Zeichen legt fest, wie ausgeliehen wird; der Referenztyp davor sollte
dazu passen. Leiht die Anweisung zum Schreiben aus, ist `name` eine
Schreib-Referenz, und `name->slot := value;` ändert den Slot.

Abweichung von Austral: Dort weist der Compiler eine Zuweisung über den Namen
einer borrow-Anweisung zurück; ändern ließ sich der Wert nur, indem man
`name` an eine Funktion gab, die eine Schreib-Referenz nimmt.

Funktionen, die Referenzen nehmen, sind in der Regel generisch über die
Region (Kapitel 9).

```hilde
module body Example.Borrowing is
    record Account: Linear is
        balance: Int64;
    end;

    generic [R: Region]
    function balanceOf(account: &[Account, R]): Int64 is
        return account->balance;
    end;

    generic [R: Region]
    function deposit(account: &![Account, R], amount: Int64): Unit is
        account->balance := account->balance + amount;
        return nil;
    end;

    generic [R: Region]
    function depositTwice(account: &![Account, R], amount: Int64): Unit is
        deposit(&~account, amount);
        deposit(account, amount);
        return nil;
    end;

    function main(): ExitCode is
        var account: Account := Account(balance => 10);
        deposit(&!account, 5);
        depositTwice(&!account, 1);
        borrow slot: &![Account, W] := &!account do
            slot->balance := slot->balance + 100;
            let moved: &![Account, W] := slot;
            deposit(moved, 1);
        end borrow;
        printLn(balanceOf(&account));
        borrow view: &[Account, V] := &account do
            let field: &[Int64, V] := &(view->balance);
            printLn(!field);
        end borrow;
        let { balance: Int64 } := account;
        printLn(balance);
        return ExitSuccess();
    end;
end module body.
```

Referenzen auf Teile eines Werts, gelesen über eine Schreib-Referenz und
geschrieben über einen Teil:

```hilde
module body Example.Parts is
    record Inner: Linear is
        value: Int32;
    end;

    record Pair: Linear is
        first: Inner;
        second: Inner;
    end;

    generic [R: Region]
    function valueOf(inner: &[Inner, R]): Int32 is
        return inner->value;
    end;

    generic [R: Region]
    function setValue(inner: &![Inner, R], value: Int32): Unit is
        inner->value := value;
        return nil;
    end;

    generic [R: Region]
    function total(pair: &[Pair, R]): Int32 is
        return valueOf(&(pair->first)) + valueOf(&(pair->second));
    end;

    generic [R: Region]
    function storeTotal(pair: &![Pair, R]): Unit is
        let sum: Int32 := total(&pair);
        setValue(&!(pair->second), sum);
        return nil;
    end;

    function main(): ExitCode is
        var pair: Pair := Pair(first => Inner(value => 2), second => Inner(value => 3));
        storeTotal(&!pair);
        printLn(total(&pair));
        let { first: Inner, second: Inner } := pair;
        let { value as a: Int32 } := first;
        let { value as b: Int32 } := second;
        printLn(a + b);
        return ExitSuccess();
    end;
end module body.
```

Eine Schreib-Referenz auf einen Teil braucht eine Schreib-Referenz auf das
Ganze:

```hilde fails H3093
module body Example.ReadOnlyPart is
    record Inner: Linear is
        value: Int32;
    end;

    record Pair: Linear is
        first: Inner;
        second: Inner;
    end;

    generic [R: Region]
    function setValue(inner: &![Inner, R], value: Int32): Unit is
        inner->value := value;
        return nil;
    end;

    generic [R: Region]
    function clear(pair: &[Pair, R]): Unit is
        setValue(&!(pair->first), 0);
        return nil;
    end;

    function main(): ExitCode is
        let pair: Pair := Pair(first => Inner(value => 2), second => Inner(value => 3));
        clear(&pair);
        let { first: Inner, second: Inner } := pair;
        let { value as a: Int32 } := first;
        let { value as b: Int32 } := second;
        return ExitSuccess();
    end;
end module body.
```

## 8. Lineare Werte

Ein Wert eines `Linear`-Typs wird genau einmal verwendet. Man sagt, er wird
verbraucht: indem man ihn an eine Funktion übergibt, ihn zurückgibt oder ihn
mit `let { ... } :=` zerlegt. Der Compiler prüft das nach den folgenden
Regeln. Zu jeder Regel gibt es ein Beispiel, das kompiliert, und eines, das
scheitert. Bei einem scheiternden Beispiel nennt die erste Zeile des
Codeblocks den Fehlercode, den der Compiler meldet, etwa
so: ```` ```hilde fails H4012 ````.

**Genau einmal.** Eine lineare Variable muss verbraucht sein, bevor die
Funktion zurückkehrt, und sie darf nur einmal verbraucht werden.

```hilde
module body Example.Once is
    record Ticket: Linear is
        number: Int32;
    end;

    function redeem(ticket: Ticket): Int32 is
        let { number: Int32 } := ticket;
        return number;
    end;

    function main(): ExitCode is
        let ticket: Ticket := Ticket(number => 7);
        printLn(redeem(ticket));
        return ExitSuccess();
    end;
end module body.
```

Hier wird das Ticket nie verbraucht:

```hilde fails H4012
module body Example.Forgotten is
    record Ticket: Linear is
        number: Int32;
    end;

    function main(): ExitCode is
        let ticket: Ticket := Ticket(number => 7);
        return ExitSuccess();
    end;
end module body.
```

Hier wird es zweimal verbraucht:

```hilde fails H4008
module body Example.Twice is
    record Ticket: Linear is
        number: Int32;
    end;

    function redeem(ticket: Ticket): Int32 is
        let { number: Int32 } := ticket;
        return number;
    end;

    function main(): ExitCode is
        let ticket: Ticket := Ticket(number => 7);
        printLn(redeem(ticket));
        printLn(redeem(ticket));
        return ExitSuccess();
    end;
end module body.
```

**Verzweigungen.** Alle Zweige eines `if` oder eines `case` verbrauchen
dieselben linearen Variablen.

```hilde
module body Example.Branch is
    record Ticket: Linear is
        number: Int32;
    end;

    function redeem(ticket: Ticket): Int32 is
        let { number: Int32 } := ticket;
        return number;
    end;

    function tear(ticket: Ticket): Unit is
        let { number: Int32 } := ticket;
        return nil;
    end;

    function main(): ExitCode is
        let ticket: Ticket := Ticket(number => 7);
        let lucky: Bool := true;
        if lucky then
            printLn(redeem(ticket));
        else
            tear(ticket);
        end if;
        return ExitSuccess();
    end;
end module body.
```

Hier verbraucht nur ein Zweig das Ticket:

```hilde fails H4004
module body Example.OneBranch is
    record Ticket: Linear is
        number: Int32;
    end;

    function redeem(ticket: Ticket): Int32 is
        let { number: Int32 } := ticket;
        return number;
    end;

    function main(): ExitCode is
        let ticket: Ticket := Ticket(number => 7);
        let lucky: Bool := true;
        if lucky then
            printLn(redeem(ticket));
        else
            skip;
        end if;
        return ExitSuccess();
    end;
end module body.
```

**Schleifen.** Ein Schleifenrumpf kann mehrmals laufen. Eine lineare Variable
von außerhalb darf er deshalb nur verbrauchen, wenn er ihr vor seinem Ende
einen neuen Wert gibt. Was der Rumpf selbst an linearen Werten erzeugt,
verbraucht er auch selbst.

```hilde
module body Example.Loop is
    record Ticket: Linear is
        number: Int32;
    end;

    function redeem(ticket: Ticket): Int32 is
        let { number: Int32 } := ticket;
        return number;
    end;

    function main(): ExitCode is
        for i from 1 to 3 do
            let ticket: Ticket := Ticket(number => 7);
            printLn(redeem(ticket));
        end for;
        return ExitSuccess();
    end;
end module body.
```

Hier entsteht das Ticket vor der Schleife und wird in ihr verbraucht:

```hilde fails H4003
module body Example.LoopOutside is
    record Ticket: Linear is
        number: Int32;
    end;

    function redeem(ticket: Ticket): Int32 is
        let { number: Int32 } := ticket;
        return number;
    end;

    function main(): ExitCode is
        let ticket: Ticket := Ticket(number => 7);
        for i from 1 to 3 do
            printLn(redeem(ticket));
        end for;
        return ExitSuccess();
    end;
end module body.
```

**Ausleihen.** Solange eine Variable ausgeliehen ist, wird sie nicht
verbraucht. Ist die Ausleihe vorbei, darf sie verbraucht werden.

```hilde
module body Example.Borrow is
    record Ticket: Linear is
        number: Int32;
    end;

    function redeem(ticket: Ticket): Int32 is
        let { number: Int32 } := ticket;
        return number;
    end;

    function main(): ExitCode is
        let ticket: Ticket := Ticket(number => 7);
        borrow view: &[Ticket, R] := &ticket do
            printLn(view->number);
        end borrow;
        printLn(redeem(ticket));
        return ExitSuccess();
    end;
end module body.
```

Hier wird das Ticket verbraucht, während es ausgeliehen ist:

```hilde fails H4006
module body Example.BorrowConsumed is
    record Ticket: Linear is
        number: Int32;
    end;

    function redeem(ticket: Ticket): Int32 is
        let { number: Int32 } := ticket;
        return number;
    end;

    function main(): ExitCode is
        let ticket: Ticket := Ticket(number => 7);
        borrow view: &[Ticket, R] := &ticket do
            printLn(redeem(ticket));
        end borrow;
        return ExitSuccess();
    end;
end module body.
```

**Schreib-Referenzen weitergeben.** Eine Schreib-Referenz ist verbraucht,
sobald sie weitergegeben wird. `&~` gibt eine neue weiter, und die alte bleibt
benutzbar.

```hilde
module body Example.Reborrow is
    record Counter: Linear is
        count: Int32;
    end;

    generic [R: Region]
    function bump(counter: &![Counter, R]): Unit is
        counter->count := counter->count + 1;
        return nil;
    end;

    generic [R: Region]
    function bumpTwice(counter: &![Counter, R]): Unit is
        bump(&~counter);
        bump(counter);
        return nil;
    end;

    function main(): ExitCode is
        var counter: Counter := Counter(count => 0);
        bumpTwice(&!counter);
        let { count: Int32 } := counter;
        printLn(count);
        return ExitSuccess();
    end;
end module body.
```

Hier wird dieselbe Schreib-Referenz zweimal weitergegeben:

```hilde fails H4008
module body Example.PassedTwice is
    record Counter: Linear is
        count: Int32;
    end;

    generic [R: Region]
    function bump(counter: &![Counter, R]): Unit is
        counter->count := counter->count + 1;
        return nil;
    end;

    generic [R: Region]
    function bumpTwice(counter: &![Counter, R]): Unit is
        bump(counter);
        bump(counter);
        return nil;
    end;

    function main(): ExitCode is
        var counter: Counter := Counter(count => 0);
        bumpTwice(&!counter);
        let { count: Int32 } := counter;
        printLn(count);
        return ExitSuccess();
    end;
end module body.
```

## 9. Generics und Typklassen

**Typparameter.** Eine generische Funktion beginnt mit `generic` und der Liste
ihrer Typparameter: `generic [T: Free, R: Region]`. Zu jedem Parameter gehört
sein Universum. Bei Records und Unions stehen die Typparameter in eckigen
Klammern hinter dem Namen: `record Pair[T: Free]: Free is`.

**Anforderungen.** Ein Typparameter kann Typklassen verlangen; sie stehen in
Klammern hinter dem Universum: `T: Free(Describe)`, oder mehrere:
`T: Type(First, Second)`.

**Typklassen.** Eine Typklasse benennt einen Typparameter und zählt Methoden
auf:

- `typeclass Describe(T: Free) is method describe(value: T): Span[Nat8, Static]; end;`

**Instanzen.** Eine Instanz stellt die Methoden für einen bestimmten Typ
bereit. Im Body enthält sie die Definitionen der Methoden, im Interface steht
nur ihr Kopf: `instance Describe(Bool);`. Generische Instanzen und generische
Methoden beginnen mit `generic [...]`.

**Aufrufe.** Methoden ruft man auf wie Funktionen: `describe(true)`.
Typargumente stehen nie beim Aufruf; der Compiler leitet sie aus den
Argumenten und aus dem erwarteten Typ ab.

```hilde
module body Example.Generics is
    record Pair[T: Free]: Free is
        left: T;
        right: T;
    end;

    generic [T: Free]
    function swap(pair: Pair[T]): Pair[T] is
        return Pair(left => pair.right, right => pair.left);
    end;

    typeclass Describe(T: Free) is
        method describe(value: T): Span[Nat8, Static];
    end;

    instance Describe(Bool) is
        method describe(value: Bool): Span[Nat8, Static] is
            if value then
                return "yes";
            else
                return "no";
            end if;
        end;
    end;

    generic [T: Free(Describe)]
    function show(value: T): Unit is
        printLn(describe(value));
        return nil;
    end;

    function main(): ExitCode is
        let pair: Pair[Int32] := Pair(left => 1, right => 2);
        let swapped: Pair[Int32] := swap(pair);
        printLn(swapped.left);
        show(true);
        show(false);
        return ExitSuccess();
    end;
end module body.
```

## 10. Pragmas

Mit einem Pragma gibt man dem Compiler eine Anweisung: `pragma Name;` oder
`pragma Name(Argument => "value");`. Pragmas haben zwei Plätze.

**Vor `module body`**, gültig für das ganze Modul:

- `pragma Unsafe_Module;` erklärt das Modul für unsicher. Nur unsichere
  Module dürfen C-Funktionen binden, `@embed` verwenden oder C-Bibliotheken
  und C-Header angeben.
- `pragma Foreign_Library(Name => "z");` linkt die C-Bibliothek `z` dazu.
- `pragma Foreign_Library(Name => "crypt", System => "Linux");` linkt sie
  nur, wenn das Programm auf diesem System übersetzt wird, so wie
  `uname -s` es nennt: `Linux`, `OpenBSD`, `FreeBSD`, `NetBSD` oder
  `Darwin`.
- `pragma Foreign_Header(Name => "zlib.h");` bindet einen C-Header ein.

**Vor einer Definition im Body:**

- `pragma Foreign_Import(External_Name => "c_name");` verbindet die folgende
  Funktion mit einer C-Funktion. Ihr Rumpf bleibt leer: `is end;`.
- `pragma Foreign_Export(External_Name => "c_name");` stellt die folgende
  Funktion unter diesem Namen für C bereit. Der Name ist ein C-Bezeichner,
  kein Schlüsselwort von C, nicht `main`, beginnt nicht mit `hilde_`, und
  keine andere Funktion wird unter ihm exportiert (H2050). Die Funktion
  darf über Regionen generisch sein, nicht über Typen (H2018). Ihre
  Parameter und ihr Ergebnis gehen als C-Typen hinüber: `Bool` als `bool`,
  die ganzen Zahlen als `int8_t` bis `uint64_t` und `size_t`, die
  Gleitkommazahlen, `Span[Nat8, R]` und `Span![Nat8, R]` als Zeiger und
  Länge, ein Record oder eine Union ohne Typparameter als Handle und eine
  Referenz darauf als Zeiger auf sein Handle; jeder andere Typ wird
  abgelehnt (H3001).

`hilde compile --target-type=static --output=libname.a` und
`--target-type=shared --output=libname.so` bauen eine Bibliothek der
exportierten Funktionen, ohne `main`, und schreiben ihren Header
`libname.h` daneben. Ein Aufrufer in C ruft `hilde_start()` vor der ersten
von ihnen auf und `hilde_end()` nach der letzten.

`hilde build` ist `hilde compile` unter einem zweiten Namen.
`--target=wasm` baut für wasm32-wasi: Ein Programm mit `--entrypoint` wird
ein Kommandomodul, dessen Ausgabe auf `.wasm` endet (H1044) und das
wasmtime ausführt wie ein Binary; `--target-type=wasm` baut ein
Bibliotheksmodul, einen Reaktor, dessen Host die exportierten Funktionen
nach `hilde_start()` aufruft.  hilde findet den Compiler selbst: zig
(`HILDE_ZIG`, dann im Pfad), sonst clang im Pfad mit `wasm-ld` und der
C-Bibliothek von WASI; `HILDE_WASM_CC=zig` oder `clang` wählt (H1038,
H1039).  `--target` nennt eines von `linux`, `openbsd`, `freebsd`,
`darwin` und `wasm`; ein anderes System als das, auf dem hilde läuft, wird
abgewiesen (H1041, H1042), ebenso ein Archiv oder ein Shared Object für
wasm (H1043).  `hilde test --target=wasm` baut jedes Testprogramm als
Kommandomodul und führt es in wasmtime aus (`HILDE_WASMTIME`, dann im
Pfad, H1040), mit dem Arbeitsverzeichnis, `/tmp` und der Umgebung.  Eine
Funktion mit `pragma Foreign_Export` wird in beiden Formen an den Host des
Moduls exportiert.

**Vor den Importen eines Interface**, für das Modul:

- `pragma Targets(Names => "linux openbsd freebsd darwin wasm");` nennt
  die Ziele, für die es das Modul gibt, getrennt durch je ein Leerzeichen.
  `Instead => "Standard.Regex"` danach nennt das Modul, das auf einem Ziel
  außerhalb davon zu nehmen ist (H2068).  Es ist dort das einzige Pragma
  und steht einmal (H2069).  Jedes Interface der Standardbibliothek nennt
  seine Ziele (H2071), und nur die Standardbibliothek tut es (H2070): Was
  zwischen den Zielen verschieden ist, steht in der Standardbibliothek, und
  ein Programm hält keinen Code für nur ein Ziel.  Ein Modul nennt nur
  Ziele, für die es jedes Modul gibt, das es importiert (H2072), und ein
  Programm, das für ein Ziel gebaut wird, importiert nur Module, die es
  dafür gibt (H2073, mit dem Modul von `Instead` als Vorschlag).

**Vor einer Deklaration in einem Interface:**

- `pragma Slot;` macht die folgende Funktion zu einem Slot: Eine Funktion
  des Programms darf ihn implementieren, gewählt, wenn das ganze Programm
  übersetzt wird. Ihre Definition im Body, falls es eine gibt, ist der
  Default. Ein Slot ist höchstens über Regionen generisch (H2067).

**Vor einer Definition in einem Body, für einen Slot:**

- `pragma Implements(Name => "Modul.funktion");` macht die folgende
  Funktion zur Implementierung dieses Slots. Sie hat die Parameter des
  Slots mit Namen und Typen und sein Ergebnis (H2065); ein Slot hat eine
  Implementierung (H2064), der Name ist ein Slot eines vorher übersetzten
  Moduls (H2066), und ein Slot ohne Default hat eine (H2063). Ohne eigenen
  Vertrag übernimmt sie den des Slots. Der Aufruf ist direkt, ohne
  Funktionszeiger. `Hilde.Pervasive` hat zwei Slots: `onOverflow`, den
  jede trapping-Operation ruft, und `onAbort`, den `abort` ruft; beide
  geben `Never` zurück. Unterschied zu Austral: neu in Hilde, nach Rusts
  externally implementable items.

```hilde
module body Example.Slots is
    pragma Implements(Name => "Hilde.Pervasive.onOverflow");
    function overflowed(message: Span[Nat8, Static]): Never is
        printLn("an operation overflowed");
        abort(message);
    end;

    function main(): ExitCode is
        printLn("ok");
        return ExitSuccess();
    end;
end module body.
```

Interfaces haben keine Modul-Pragmas.

Abweichung von Austral: `Foreign_Library` und `Foreign_Header` sind in Hilde
hinzugekommen, und `@embed` setzt `pragma Unsafe_Module;` voraus. Neu sind
auch der Export über Regionen, Spans aus Bytes und Handles sowie die beiden
Bibliotheksziele.

```hilde
pragma Unsafe_Module;

module body Example.Pragmas is
    pragma Foreign_Import(External_Name => "hilde_put_character");
    function putCharacter(character: Nat8): Int32 is
    end;

    pragma Foreign_Export(External_Name => "example_byte_count");
    generic [R: Region]
    function byteCount(bytes: Span[Nat8, R]): Index is
        return spanLength(bytes);
    end;

    function main(): ExitCode is
        putCharacter('o');
        putCharacter('k');
        putCharacter('\n');
        let two: Int32 := 2;
        let answer: Int32 := @embed(Int32, "40 + $1", two);
        printLn(answer);
        return ExitSuccess();
    end;
end module body.
```

## 11. case

`case` entscheidet anhand eines Werts, welcher Zweig ausgeführt wird:

- `case value of when ... do ... when ... do ... end case;`

Für `when` gibt es zwei Schreibweisen.

**Nach Namen.** Das `when` nennt einen Fall der Union und bindet seine Slots
mit Name und Typ: `when Circle(radius: Int32) do`. Mit
`when Circle(radius as r: Int32) do` bekommt der Slot einen anderen Namen.
Fälle ohne Slots stehen allein: `when Dot do`. Jeder Fall der Union taucht
genau einmal auf. Diese Schreibweise funktioniert auch mit einer Referenz auf
eine Union; die Slots sind dann Referenzen derselben Region, etwa
`when Circle(radius: &[Int32, R]) do`.

**Nach Muster.** Das `when` gibt ein Muster an oder mehrere, getrennt durch
`|`. Als Muster kommen in Frage:

- eine Variable, also ein Name mit kleinem Anfangsbuchstaben; sie bindet den
  Wert,
- `_`, das auf jeden Wert passt und nichts bindet,
- eine ganze Zahl, auch als Zeichen geschrieben: `0`, `-1`, `#x41`, `'a'`,
- ein Bereich zwischen zwei ganzen Zahlen: `'a' .. 'z'`, ohne Leerzeichen
  auch `0..9`,
- `true` oder `false`,
- eine Variante, also ein Name mit großem Anfangsbuchstaben, dahinter in
  Klammern ein Untermuster für jeden Slot, in der Reihenfolge der Slots:
  `Rectangle(1, _)`.

Es gilt das erste `when`, das passt. Lässt ein `case` einen möglichen Wert
aus oder enthält es ein Muster, das nie zum Zug kommen kann, lehnt der
Compiler es ab. Über einer Union gibt es keinen Auffangzweig: `_` oder eine
Variable darf dort nicht das ganze Muster sein. Bei einer ganzen Zahl oder
einem `Bool` dagegen schließt `_` oder eine Variable das `case` ab. Die
Alternativen eines `when` binden alle dieselben Variablen.
Ein `case` mit Mustern braucht einen Wert, keine Referenz. Gleitkomma- und
String-Literale lässt der Parser als Muster zu, der Compiler weist sie
zurück.

**Über einer ganzen Zahl.** Ein `case` über einer ganzen Zahl ist die Form
für eine Verteilung nach Codes: `when 0 do`, `when 1 | 2 do`, `when 3 .. 9 do`,
am Ende `when _ do` oder `when n do`. Kein Wert steht in zwei Zweigen, ein
Zweig läuft nie in den nächsten weiter, und ohne `_` oder Variable am Ende
muss das `case` jeden Wert des Typs abdecken. Haben alle `when` vor dem
letzten nur Zahlen und Bereiche und nennen sie zusammen höchstens 1024 Werte,
wird das `case` in C zu einem `switch`; sonst zu einer Kette von `if`. Die
Wahl des Zweigs ist in beiden Formen dieselbe.

Beide Schreibweisen lassen sich nicht mischen: Verwendet ein `when` eines
`case` Muster, weist der Compiler jedes `when` zurück, das nach Name und Typ
bindet. Ein `when`, das nur aus einem Namen besteht wie `when Dot do`, passt
in beide.

Abweichung von Austral: Muster gibt es erst in Hilde. In Austral bezeichnet
`when x do` einen Fall der Union; in Hilde ist ein Name mit kleinem
Anfangsbuchstaben eine Variable.

```hilde
module body Example.Case is
    union Shape: Free is
        case Dot;
        case Circle is
            radius: Int32;
        case Rectangle is
            width: Int32;
            height: Int32;
    end;

    function area(shape: Shape): Int32 is
        case shape of
            when Dot do
                return 0;
            when Circle(radius as r: Int32) do
                return (3 * r) * r;
            when Rectangle(width: Int32, height: Int32) do
                return width * height;
        end case;
    end;

    function kind(shape: Shape): Span[Nat8, Static] is
        case shape of
            when Dot | Circle(0) do
                return "a point";
            when Circle(r) do
                return "a circle";
            when Rectangle(1, _) | Rectangle(_, 1) do
                return "a line";
            when Rectangle(w, h) do
                return "a rectangle";
        end case;
    end;

    function digit(c: Nat8): Bool is
        case c of
            when '0' .. '9' do
                return true;
            when 65..90 | #x61 .. #x7A do
                return false;
            when _ do
                return false;
        end case;
    end;

    function main(): ExitCode is
        printLn(area(Rectangle(width => 2, height => 3)));
        printLn(kind(Circle(radius => 0)));
        printLn(kind(Rectangle(width => 1, height => 7)));
        printLn(kind(Rectangle(width => 2, height => 7)));
        printLn(digit('7'));
        printLn(digit('x'));
        return ExitSuccess();
    end;
end module body.
```

## 12. Formen mit @

Sechs Formen fangen mit `@` an. `@embed` kommt im Beispiel von Kapitel 10
vor. Die übrigen fünf brauchen eine Datei oder eine Datenbank neben dem
Programm, deshalb hat dieses Kapitel kein eigenes Beispiel.

- `@embed(Type, "C expression", arguments)` ist ein Ausdruck und setzt C in
  das Programm ein. `$1`, `$2` und so fort stehen für die Argumente. Nur
  unsichere Module dürfen `@embed` verwenden (Kapitel 10).
- `@bytes("path")` ist ein Ausdruck: der Inhalt einer Datei, beim Kompilieren
  gelesen, als `Span[Nat8, Static]`. Der Pfad gilt relativ zur Datei des
  Moduls. Absolute Pfade und `..` werden zurückgewiesen.
- `@template("path", data, out);` ist eine Anweisung. Beim Kompilieren liest
  sie die Template-Datei neben dem Modul und erzeugt daraus Anweisungen, die in
  `out` schreiben, eine Variable vom Typ `StringBuilder`. Die Namen im
  Template stammen aus `data`, einer Referenz auf einen Record. Ein viertes
  Argument, ein String, nennt die Whitespace-Optionen von Jinja2, durch
  Leerzeichen getrennt:
  `@template("path", data, out, "trim_blocks lstrip_blocks");`.
  Ein Template übersetzt mit `{% catalog messages %}`, das eine Funktion nennt,
  die einen Katalog von `Standard.I18n` liefert, und dann mit
  `{{ _("Greeting", name=user) }}` oder
  `{% trans count=n %}Items{% pluralize %}{% endtrans %}`. Ein Schlüssel ist ein
  Fall der Union der Schlüssel des Katalogs, ein unbekannter Schlüssel
  kompiliert also nicht; die Sprache ist der Slot `lang` von `data`. Das Modul
  importiert `Standard.I18n`.
- `@query(&!db, "SQL", arguments) for row: Row do ... else error do ... end for;`
  ist eine Anweisung für SQL, das Zeilen liefert. Der erste Block läuft für
  jede Zeile einmal, der Block nach `else`, wenn die Abfrage fehlschlägt. Ohne
  `else` geht es nicht.
- `@execute(&!db, "SQL", arguments)` ist ein Ausdruck für SQL, das keine
  Zeilen liefert.
- `@migrations` ist ein Ausdruck: Er übernimmt die Migrationsdateien neben dem
  Modul, `migrations/1-name.sql` und die folgenden, in das Programm.

Die Datenbank steht in `@query` und `@execute` als `&!db` oder `&~db`. Der
Compiler prüft das SQL beim Kompilieren gegen die Tabellen, die die
Migrationsdateien anlegen.

Abweichung von Austral: Bis auf `@embed` sind alle diese Formen in Hilde neu.
