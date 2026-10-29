# Fehlermeldungen des Hilde-Compilers

Diese Seite führt jeden Fehlercode auf, den der Hilde-Compiler dieses
Repositorys melden kann: mit dem Meldungstext, einer kurzen Erklärung
und zwei Beispielen, einem Modul, das genau an diesem Code scheitert, und
der richtigen Form, die kompiliert. Codes und Meldungstexte stammen aus
den Quellen des Compilers unter `lib/`; jedes Beispiel wurde aus dieser
Seite gezogen und kompiliert.

Lehnt der Compiler ein Programm ab, gibt er die Art des Fehlers aus, den
Code, das Modul, die Stelle im Quelltext und eine Beschreibung. Ein Code
bezeichnet genau eine Stelle im Compiler, die den Fehler meldet; er bleibt
derselbe, auch wenn sich der Wortlaut ändert. Die einzige Ausnahme ist
H9999, der Code jedes internen Fehlers.

So liest man einen Eintrag:

- Die Meldung steht so da, wie der Compiler sie beim scheiternden
  Beispiel ausgegeben hat: in der ersten Zeile die Art des Fehlers,
  darunter die Beschreibung.
- Ein Codeblock, der mit ```` ```hilde fails H4012 ```` beginnt, ist ein
  Modul, das der Compiler mit genau diesem Code ablehnt.
- Ein Codeblock, der mit ```` ```hilde ```` beginnt, ist die richtige
  Form. Sie kompiliert.
- Nennt die erste Zeile eines Codeblocks `file` und einen Pfad, ist er eine
  Datei neben dem Modul darüber, etwa ein Template oder eine Migration.
- Ein Codeblock, der mit ```` ```sh command ```` beginnt, ist die
  Kommandozeile, mit der das Modul darüber übersetzt wird. Fehlt er, ist
  es `hilde compile` mit den Dateien des Moduls, den importierten Modulen
  der Standardbibliothek, `--entrypoint=Example:main` und `--output`.
- Manche Codes erreicht kein Programm; ihr Eintrag sagt das, und die
  Übersicht zeigt es in ihrer dritten Spalte.

Der Katalog umfasst 548 Codes: 494 mit Beispielen und 54, die sich nicht
auslösen ließen; jeder der 54 sagt, warum er bleibt.

## Übersicht

Alle Codes in einer Tabelle, in der Reihenfolge der Kapitel unten. Die
letzte Spalte ist der erste Satz des Eintrags.

| Code | Kapitel | Ausgelöst | Bedeutung |
| --- | --- | --- | --- |
| H0001 | 1. Syntax | ja | Im Quelltext steht ein Zeichen, mit dem kein Token beginnt. |
| H0003 | 1. Syntax | ja | Ein String-Literal wird mit einem Anführungszeichen geöffnet und nie geschlossen. |
| H0004 | 1. Syntax | ja | Ein String in dreifachen Anführungszeichen wird geöffnet und nie geschlossen, und die Datei endet mitten darin. |
| H0005 | 1. Syntax | ja | Die Tokens ergeben kein Programm der Grammatik. |
| H0006 | 1. Syntax | ja | Der Funktionszeigertyp Fn steht ohne Typargumente. |
| H0007 | 1. Syntax | nein | Ein Zeichen-Literal enthält mehr als ein Zeichen. |
| H0008 | 1. Syntax | ja | Ein reserviertes Wort steht, wo ein Name hingehört. |
| H0009 | 1. Syntax | ja | Ein Operator folgt auf eine Operation ohne Klammern um sie, etwa a + b * c oder a - b - c. |
| H0010 | 1. Syntax | ja | Ein Index folgt auf die schließende Klammer eines Aufrufs. |
| H0011 | 1. Syntax | ja | Eine Ausleihe nimmt ein Literal. |
| H0012 | 1. Syntax | ja | Ein Feld folgt auf die schließende Klammer eines Aufrufs. |
| H6018 | 1. Syntax | ja | In einem String-Literal verbindet ein Backslash mit folgendem Leerraum zwei Teile des Strings, und der Leerraum muss mit einem zweiten Backslash enden. |
| H6058 | 1. Syntax | ja | Ein Escape \u{...} in einem String-Literal hat keine Ziffern, mehr als sechs, eine Ziffer, die nicht hexadezimal ist, einen Codepunkt über 10FFFF oder ein Surrogat. |
| H2020 | 2. Typen | ja | Eine Instanz nennt etwas, das keine Typklasse ist. |
| H2021 | 2. Typen | ja | Eine Instanz definiert eine Methode, die ihre Typklasse nicht deklariert. |
| H2022 | 2. Typen | ja | Eine Instanz lässt eine Methode ihrer Typklasse aus. |
| H2023 | 2. Typen | ja | Der Parameter einer Typklasse ist im Universum Region deklariert. |
| H2024 | 2. Typen | ja | Ein Record oder eine Union ist im Universum Region deklariert. |
| H2025 | 2. Typen | ja | Eine Instanz nennt eine Typklasse, die im Modul nicht deklariert und nicht importiert ist. |
| H2026 | 2. Typen | ja | Ein Typparameter einer generischen Funktion kommt weder in ihren Parametern noch im Rückgabetyp vor; kein Aufruf könnte also festlegen, wofür er steht. |
| H2031 | 2. Typen | ja | Eine Funktion oder Methode endet ohne return. |
| H2032 | 2. Typen | ja | Das Argument einer generischen Instanz verwendet denselben Typparameter zweimal. |
| H2033 | 2. Typen | ja | Eine generische Instanz deklariert mehr Typparameter, als ihr Argument verwendet. |
| H2034 | 2. Typen | ja | Das Argument einer Instanz ist ein bloßer Typparameter. |
| H2035 | 2. Typen | ja | Das Argument einer generischen Instanz mischt Typparameter mit konkreten Typen. |
| H2037 | 2. Typen | ja | Ein Typparameter einer generischen Instanz heißt wie der Parameter ihrer Typklasse. |
| H3003 | 2. Typen | ja | Ein Typparameter einer generischen Funktion müsste im selben Aufruf für zwei verschiedene Typen stehen. |
| H3004 | 2. Typen | ja | Ein Typargument liegt in einem Universum, das sein Typparameter nicht zulässt, etwa ein Linear-Typ, wo der Parameter Free verlangt. |
| H3007 | 2. Typen | ja | Eine Instanz gilt einem Typ, dessen Universum die Typklasse nicht zulässt, etwa einem Linear-Typ für eine Klasse über Free-Typen. |
| H3008 | 2. Typen | ja | Die beiden Operanden eines Rechenoperators haben verschiedene Typen. |
| H3009 | 2. Typen | ja | Ein Operand eines Rechenoperators ist keine Zahl. |
| H3010 | 2. Typen | ja | Ein Wert eines vorzeichenlosen Typs wird negiert. |
| H3012 | 2. Typen | ja | Ein Wert wird negiert, dessen Typ keine Instanz der Typklasse TrappingNegation hat. |
| H3020 | 2. Typen | ja | Etwas, das weder eine Funktion noch eine Methode noch ein Funktionszeiger ist, wird aufgerufen. |
| H3021 | 2. Typen | ja | Ein Funktionszeiger wird mit mehr oder weniger Argumenten aufgerufen, als sein Typ Parameter hat. |
| H3022 | 2. Typen | ja | Ein case, das nach Namen bindet, lässt einen Fall der Union aus. |
| H3023 | 2. Typen | ja | Ein case schaut in eine Union, die ein anderes Modul nur als opaken Typ exportiert. |
| H3024 | 2. Typen | ja | Ein case, das nach Namen bindet, bekommt einen Wert eines benannten Typs, der keine Union ist, etwa einen Record. |
| H3025 | 2. Typen | ja | Ein when, das nach Namen bindet, nennt Slots, die der Fall der Union nicht hat, oder lässt welche aus. |
| H3027 | 2. Typen | ja | Ein Wert wird in einen Typ umgewandelt, der er nicht werden kann. |
| H3029 | 2. Typen | ja | Die Bedingung eines if, eines while oder eines if-Ausdrucks ist kein Bool. |
| H3030 | 2. Typen | ja | Ein Record oder ein Fall einer Union wird mit Argumenten nach Position gebaut. |
| H3031 | 2. Typen | ja | Ein Konstruktor wird mit Namen aufgerufen, die nicht die Slots des Records oder des Falls sind. |
| H3033 | 2. Typen | ja | Ein let mit geschweiften Klammern zerlegt einen Wert eines eingebauten Typs, der keine Slots hat. |
| H3034 | 2. Typen | ja | Ein let mit geschweiften Klammern zerlegt einen Record, den ein anderes Modul nur als opaken Typ exportiert. |
| H3035 | 2. Typen | ja | Ein let mit geschweiften Klammern nennt andere Slots, als der Record hat. |
| H3037 | 2. Typen | ja | Eine Ausdrucksanweisung wirft ein Option oder ein Either weg. |
| H3038 | 2. Typen | ja | Der Operator ? steht an einem Wert, der weder Option noch Either ist; es gibt also keinen Fehlschlag weiterzureichen. |
| H3039 | 2. Typen | ja | Der Operator ? steht in einer Funktion, die den Fehlschlag nicht weiterreichen kann: Für ein Option muss sie ein Option zurückgeben, für ein Either ein Either mit demselben linken Typ. |
| H3040 | 2. Typen | ja | Der Operator ? steht innerhalb eines größeren Ausdrucks. |
| H3041 | 2. Typen | ja | Der Wert einer Konstanten ist kein konstanter Ausdruck, etwa ein Funktionsaufruf. |
| H3043 | 2. Typen | ja | Ein Funktionszeiger wird mit benannten Argumenten aufgerufen. |
| H3044 | 2. Typen | ja | Die beiden Zweige eines if-Ausdrucks haben verschiedene Typen. |
| H3045 | 2. Typen | ja | Der Operand von not ist kein Bool. |
| H3046 | 2. Typen | ja | Ein Operand von and oder or ist kein Bool. |
| H3049 | 2. Typen | ja | Ein Record hat keinen Slot dieses Namens. |
| H3050 | 2. Typen | ja | Eine Methode einer Typklasse wird mit einem Wert aufgerufen, dessen Typ keine Instanz dieser Klasse hat. |
| H3052 | 2. Typen | ja | Ein Slot wird aus einem Record gelesen, den ein anderes Modul nur als opaken Typ exportiert. |
| H3053 | 2. Typen | ja | Ein Slot wird aus einem Wert eines benannten Typs gelesen, der kein Record ist, etwa einer Union. |
| H3054 | 2. Typen | ja | Eine Bindung in einem case-Zweig deklariert einen anderen Typ, als der Slot hat. |
| H3055 | 2. Typen | ja | Eine generische Funktion, deren Typparameter nur im Rückgabetyp vorkommt, wird an einer Stelle aufgerufen, die keinen Typ erwartet; ihr Typ lässt sich so nicht bestimmen. |
| H3056 | 2. Typen | ja | In einer generischen Funktion wird eine Methode einer Typklasse auf einem Wert eines Typparameters aufgerufen, dem die Anforderung dieser Klasse fehlt. |
| H3057 | 2. Typen | ja | Ein Slot wird aus einem Wert eines eingebauten Typs gelesen, der keine Slots hat. |
| H3058 | 2. Typen | ja | Der Index-Operator s[i] steht an einem Wert, der kein Span ist. |
| H3060 | 2. Typen | ja | Ein Wert hat einen anderen Typ als den, den seine Stelle erwartet, etwa in einer return-Anweisung. |
| H3061 | 2. Typen | ja | Eine generische Funktion verlangt von ihrem Typparameter eine Typklasse, und der dafür eingesetzte Typ hat keine Instanz dieser Klasse. |
| H3062 | 2. Typen | ja | Ein Ganzzahl-Literal passt nicht in seinen Typ. |
| H3063 | 2. Typen | ja | Ein Typargument liegt in einem Universum, das sein Typparameter nicht annimmt, etwa ein Linear-Typ für einen Parameter in Free. |
| H3064 | 2. Typen | ja | Ein Typname ist unbekannt: Er ist im Modul nicht deklariert, nicht importiert und nicht eingebaut. |
| H3065 | 2. Typen | ja | Ein case, das nach Namen bindet, bekommt einen Wert, der weder eine Union noch eine Referenz auf eine Union ist. |
| H3071 | 2. Typen | ja | Ein case verwendet in einem when Muster und bindet in einem anderen Slots nach Name und Typ. |
| H3072 | 2. Typen | ja | Ein case mit Mustern bekommt eine Referenz. |
| H3073 | 2. Typen | ja | Eine Variable steht als ganzes Muster in einem case über einer Union. |
| H3074 | 2. Typen | ja | Ein Muster kann nie gewählt werden, weil die Muster davor schon jeden Wert erfassen, auf den es passt. |
| H3075 | 2. Typen | ja | Ein case mit Mustern lässt Werte aus. |
| H3076 | 2. Typen | ja | Ein Ganzzahl-Muster steht, wo der Wert keine ganze Zahl ist. |
| H3077 | 2. Typen | ja | Ein Bool-Muster, true oder false, steht, wo der Wert kein Bool ist. |
| H3078 | 2. Typen | ja | Ein Literal oder eine Grenze eines Bereichs liegt außerhalb des Typs des Werts. |
| H3079 | 2. Typen | ja | Die untere Grenze eines Bereichs liegt über der oberen; der Bereich ist leer. |
| H3080 | 2. Typen | ja | Ein Gleitkomma-Literal steht als Muster. |
| H3081 | 2. Typen | ja | Ein String-Literal steht als Muster. |
| H3082 | 2. Typen | ja | Das Muster _ steht, wo der Wert nicht Free ist. |
| H3083 | 2. Typen | ja | Ein Variantenmuster gibt mehr oder weniger Untermuster an, als die Variante Slots hat. |
| H3084 | 2. Typen | ja | Die Alternativen eines when binden verschiedene Variablen. |
| H3085 | 2. Typen | ja | Eine Variable hat in einer Alternative eines when einen Typ und in einer anderen einen anderen. |
| H3086 | 2. Typen | ja | Ein Muster bindet dieselbe Variable zweimal. |
| H3087 | 2. Typen | ja | Ein Name mit kleinem Anfangsbuchstaben hat Untermuster. |
| H3088 | 2. Typen | ja | Ein Variantenmuster nennt einen Fall, den die Union nicht hat. |
| H3089 | 2. Typen | ja | Ein Variantenmuster steht, wo der Wert keine Union ist. |
| H3090 | 2. Typen | ja | Ein case mit Mustern bekommt einen Wert eines Typs, über den es nicht entscheiden kann. |
| H3091 | 2. Typen | ja | Das Muster _ steht als ganzes Muster in einem case über einer Union. |
| H3092 | 2. Typen | ja | Ein Bereich steht, wo der Wert keine ganze Zahl ist. |
| H3093 | 2. Typen | ja | Eine Schreib-Referenz auf einen Teil eines Werts wird über eine Lese-Referenz genommen. |
| H3094 | 2. Typen | ja | Eine Funktion gibt eine Referenz auf eine ihrer lokalen Variablen in einer Region zurück, die ihr Aufrufer wählt. |
| H3095 | 2. Typen | ja | Der Rumpf einer generischen Funktion legt einen der Typparameter der Funktion fest. |
| H4001 | 2. Typen | ja | Ein als Free deklarierter Record oder eine solche Union enthält einen Slot eines Linear-Typs oder hat einen Typparameter, der nicht Free ist. |
| H6026 | 2. Typen | ja | Eine Funktion, eine Methode oder ein Konstruktor wird mit mehr oder weniger Argumenten aufgerufen, als sie Parameter hat. |
| H6032 | 2. Typen | ja | Eine Instanz verbindet eine Typklasse und einen Typ, die beide aus anderen Modulen stammen. |
| H6037 | 2. Typen | ja | Eine Instanz einer Typklasse aus einem anderen Modul wird für einen eingebauten Typ angegeben. |
| H6038 | 2. Typen | ja | Ein Typ bekommt eine zweite Instanz derselben Typklasse. |
| H6039 | 2. Typen | ja | Ein aufgerufener Name ist weder eine Funktion noch eine Methode noch eine sichtbare Variable. |
| H6041 | 2. Typen | ja | Links in einer Zuweisung steht ein Parameter der Funktion. |
| H6042 | 2. Typen | ja | Eine Zuweisung ändert eine mit let gebundene Variable. |
| H6045 | 2. Typen | ja | Eine Variable heißt wie eine Deklaration des Moduls, etwa eine Funktion oder eine Konstante. |
| H6048 | 2. Typen | ja | Ein generischer Typ oder ein eingebauter Typ wie Pointer bekommt die falsche Anzahl von Typargumenten. |
| H3105 | 2. Typen | ja | Eine Einschränkung nennt eine Typklasse, die ihr Modul nicht importiert. |
| H3106 | 2. Typen | ja | Der C-Text eines @embed ruft eine Funktion auf, die das Programm mit pragma Foreign_Import importiert. |
| H3107 | 2. Typen | ja | Ein Vergleich hat Operanden eines Typs, den C nicht vergleichen kann: einen Span, einen Record oder eine Union. |
| H3108 | 2. Typen | ja | Eine generische Funktion vergleicht Werte einer Typvariable, und ein Aufruf macht sie zu einem Span, einem Record oder einer Union. |
| H3111 | 2. Typen | ja | Eine Methode einer Typklasse nennt den Parameter ihrer Klasse weder in einem Parameter noch in ihrem Ergebnis. |
| H3036 | 3. Linearität | ja | Eine Ausdrucksanweisung wirft einen Wert eines Linear-Typs weg. |
| H4002 | 3. Linearität | ja | Eine lineare Variable verlässt ihren Gültigkeitsbereich, ohne verbraucht zu sein, etwa eine Variable, die ein when bindet und sein Rumpf nicht verwendet. |
| H4003 | 3. Linearität | ja | Eine lineare Variable von außerhalb einer Schleife wird im Rumpf verbraucht und bekommt vor dessen Ende keinen neuen Wert. |
| H4004 | 3. Linearität | ja | Die Zweige eines if oder eines case behandeln eine lineare Variable verschieden: einer verbraucht sie, ein anderer nicht. |
| H4005 | 3. Linearität | ja | Ein einziger Ausdruck verbraucht dieselbe lineare Variable zweimal, etwa als zwei Argumente eines Aufrufs. |
| H4008 | 3. Linearität | ja | Eine lineare Variable wird in einer späteren Anweisung ein zweites Mal verbraucht. |
| H4010 | 3. Linearität | ja | Einer var mit einem linearen Wert wird ein neuer Wert zugewiesen, bevor der alte verbraucht ist. |
| H4012 | 3. Linearität | ja | Eine lineare Variable ist nicht verbraucht, wenn die Funktion zurückkehrt. |
| H4014 | 3. Linearität | ja | Eine Zuweisung an einen Slot schreibt einen Wert eines Typs, der nicht Free ist. |
| H4015 | 3. Linearität | ja | Ein if-Ausdruck verbraucht eine lineare Variable in einem Zweig und im anderen nicht. |
| H3002 | 4. Borrowing | ja | Eine Referenz oder ein Span wird an einen Task übergeben. |
| H3005 | 4. Borrowing | ja | Der Pfeil -> liest einen Slot über eine Referenz, und der Wert davor ist keine Referenz. |
| H3018 | 4. Borrowing | ja | Eine mit let gebundene Variable wird zum Schreiben ausgeliehen. |
| H3019 | 4. Borrowing | ja | Ein Parameter einer Funktion wird zum Schreiben ausgeliehen. |
| H3026 | 4. Borrowing | ja | Eine Schreib-Referenz wird mit Doppelpunkt in eine Lese-Referenz eines anderen Typs oder einer anderen Region umgewandelt. |
| H3028 | 4. Borrowing | ja | Eine Schreib-Referenz wird mit Doppelpunkt in etwas umgewandelt, das keine Lese-Referenz ist. |
| H3032 | 4. Borrowing | ja | Der Operator ! liest den Wert hinter einer Referenz und steht hier an etwas, das keine Referenz ist. |
| H3066 | 4. Borrowing | ja | Ein Task eines Lending-Scopes bekommt eine Referenz aus einer anderen Ausleihe als der, aus der der Scope verleiht. |
| H3067 | 4. Borrowing | ja | Ein Task eines Lending-Scopes bekommt eine Schreib-Referenz. |
| H3068 | 4. Borrowing | ja | Ein Task eines Lending-Scopes wird mit einem Argument gestartet, dessen Typ eine Typvariable ist. |
| H3069 | 4. Borrowing | ja | Ein Lending-Scope wird an einen Task eines anderen Lending-Scopes übergeben. |
| H3070 | 4. Borrowing | ja | Ein Lending-Scope wird an einen Task eines gewöhnlichen Scopes übergeben. |
| H4006 | 4. Borrowing | ja | Eine Variable wird verbraucht, während sie zum Lesen ausgeliehen ist. |
| H4007 | 4. Borrowing | ja | Eine Variable wird verbraucht, während sie zum Schreiben ausgeliehen ist. |
| H4011 | 4. Borrowing | ja | Eine Variable wird ausgeliehen, die schon verbraucht ist oder deren Zustand diese Art des Ausleihens nicht zulässt. |
| H4013 | 4. Borrowing | ja | Der Operator ! liest den Wert hinter einer Referenz auf einen Typ, der nicht Free ist. |
| H6043 | 4. Borrowing | ja | Eine Referenz-Transformation &( ... ) nimmt einen Pfad, dessen Kopf keine Referenz ist. |
| H6054 | 4. Borrowing | ja | Eine Zuweisung schreibt über eine Lese-Referenz, die in einer var steht. |
| H6055 | 4. Borrowing | ja | Eine borrow-Anweisung leiht mit &~ eine Variable weiter, die keine Schreib-Referenz ist. |
| H6059 | 4. Borrowing | ja | Von einer Konstante des Moduls wird ein Index oder ein Feld genommen. |
| H2001 | 5. Module | ja | Der Body definiert einen Namen des Interfaces als eine andere Art von Deklaration, etwa als Funktion, wo das Interface eine Konstante deklariert. |
| H2002 | 5. Module | ja | Eine Funktion hat im Interface andere Typparameter, Parameter oder einen anderen Rückgabetyp als im Body. |
| H2004 | 5. Module | ja | Das Interface deklariert etwas, das der Body nicht definiert. |
| H2005 | 5. Module | ja | Das Interface deklariert eine Instanz, die der Body nicht definiert. |
| H2006 | 5. Module | ja | Interface und Body, die auf der Kommandozeile als Paar stehen, nennen verschiedene Module. |
| H2008 | 5. Module | ja | Eine Deklaration hat im Interface einen anderen Typ als im Body, etwa eine Konstante. |
| H2009 | 5. Module | ja | Ein opaker Typ ist im Interface in einem Universum deklariert und im Body in einem anderen definiert. |
| H2010 | 5. Module | ja | Die Übersetzung wurde mit --forbid-unsafe-modules gestartet, und eines ihrer Module ist unsicher. |
| H2011 | 5. Module | ja | Ein Pragma bekommt die falschen Argumente. |
| H2012 | 5. Module | ja | Ein Pragma hat einen Namen, den der Compiler nicht kennt. |
| H2013 | 5. Module | ja | Ein sicheres Modul nennt eine C-Bibliothek. |
| H2014 | 5. Module | ja | Der Name in pragma Foreign_Library ist leer. |
| H2015 | 5. Module | ja | Ein Modul deklariert denselben Namen zweimal. |
| H2016 | 5. Module | ja | Zwei Module einer Übersetzung haben denselben Namen. |
| H2017 | 5. Module | ja | Ein Import nennt ein Modul, das nicht zur Übersetzung gehört. |
| H2018 | 5. Module | ja | Eine über einen Typ generische Funktion trägt pragma Foreign_Export. |
| H2027 | 5. Module | ja | Zwei Importe vergeben denselben lokalen Namen. |
| H2028 | 5. Module | ja | Ein sicheres Modul importiert aus Hilde.Memory, dessen rohe Zeiger nur unsichere Module verwenden dürfen. |
| H2029 | 5. Module | ja | Ein Import nennt etwas, das sein Modul nur im Body definiert. |
| H2030 | 5. Module | ja | Ein Import nennt etwas, das sein Modul gar nicht hat. |
| H2038 | 5. Module | ja | Ein sicheres Modul verwendet @embed, das C einfügt, das der Compiler nicht prüft. |
| H2039 | 5. Module | ja | Ein sicheres Modul bindet mit pragma Foreign_Import eine C-Funktion. |
| H2040 | 5. Module | ja | Eine mit Foreign_Import an C gebundene Funktion hat Typparameter. |
| H2041 | 5. Module | ja | Vor einer Funktion steht ein anderes Pragma als Foreign_Import oder Foreign_Export. |
| H2042 | 5. Module | ja | Ein sicheres Modul nennt mit pragma Foreign_Header einen C-Header. |
| H2043 | 5. Module | ja | Der Name in pragma Foreign_Header ist kein Header-Name. |
| H2044 | 5. Module | ja | Ein Programm importiert sowohl Standard.Sqlite als auch Standard.SqlCipher. |
| H2045 | 5. Module | ja | Ein Programm importiert ein Modul, dessen Name mit Bindings. beginnt. |
| H2050 | 5. Module | ja | Der Name, unter dem eine Funktion exportiert wird, ist einer, den C ihr nicht geben kann: kein C-Bezeichner, ein Schlüsselwort von C oder main, ein Name, der mit hilde_ beginnt und den die Laufzeit für sich behält, oder ein Name, unter dem schon eine andere Funktion exportiert wird. |
| H2059 | 5. Module | ja | Eine mit Foreign_Import an C gebundene Funktion gibt Bool zurück. |
| H3001 | 5. Module | ja | Eine mit Foreign_Export an C gegebene Funktion hat einen Parameter- oder Rückgabetyp, der nicht zu C hinüber kann, etwa einen Span aus etwas anderem als Nat8, einen Record mit Typparametern oder eine Referenz auf eine Zahl. |
| H6060 | 5. Module | ja | Ein Aufruf nennt eine Funktion, die ein anderes Modul deklariert und dieses Modul nicht importiert. |
| H1001 | 6. Anderes | ja | Der Wert von --entrypoint hat nicht die Form Modul:Funktion. |
| H1002 | 6. Anderes | ja | Ein Modul auf der Kommandozeile steht weder als einzelne Body-Datei noch als Interface und Body, durch ein Komma verbunden. |
| H1003 | 6. Anderes | ja | Das Kommando compile hat kein --entrypoint. |
| H1004 | 6. Anderes | ja | Das Kommando compile nennt kein Modul. |
| H1005 | 6. Anderes | ja | Das Kommando compile hat kein --output. |
| H1006 | 6. Anderes | ja | Der Compiler soll den Einstiegspunkt weglassen, und sein Ziel ist weder C noch eine Bibliothek. |
| H1007 | 6. Anderes | ja | Der Wert von --target-type ist keiner von exe, c, tc, static und shared. |
| H1008 | 6. Anderes | ja | Der Wert von --error-format ist keiner der Werte plain, json, hilde-json und json-lines. |
| H1009 | 6. Anderes | ja | Ein Flag steht zweimal da. |
| H1010 | 6. Anderes | nein | Die Argumentliste des Compilers ist leer, nicht einmal der Name des Programms steht darin. |
| H1011 | 6. Anderes | ja | Ein Flag ohne Wert bekommt einen, wie in --flag=wert. |
| H1012 | 6. Anderes | ja | Ein Flag, das einen Wert nimmt, steht ohne Wert da. |
| H1013 | 6. Anderes | ja | Ein Flag enthält mehr als ein Gleichheitszeichen und ist damit weder --flag noch --flag=wert. |
| H1014 | 6. Anderes | ja | Der C-Compiler hat den erzeugten C-Code abgelehnt. |
| H1015 | 6. Anderes | ja | Der Compiler konnte seine Ausgabedatei nicht öffnen oder nicht schreiben, etwa weil ihr Verzeichnis fehlt oder das Gerät voll ist. |
| H1016 | 6. Anderes | nein | Das ist die Meldung für ein Scheitern beim Schreiben, das kein Systemfehler ist; ein Systemfehler, etwa ein fehlendes Verzeichnis, ist H1015. |
| H1017 | 6. Anderes | ja | hilde query fragt nach einem Modul, das nicht auf der Kommandozeile steht. |
| H1018 | 6. Anderes | ja | hilde query wird ohne --module aufgerufen und weiß daher nicht, welches Modul es beschreiben soll. |
| H1019 | 6. Anderes | ja | hilde test wird ohne Pfad aufgerufen und weiß daher nicht, wo es Tests suchen soll. |
| H1020 | 6. Anderes | ja | hilde test bekommt zwei Schalter, die einander ausschließen: zwei der Instrumente --race, --memory und --valgrind, oder --emit-c neben einem von ihnen. |
| H1021 | 6. Anderes | nein | hilde test bekommt ein Instrument, --race, --memory oder --valgrind, das dieses System nicht ausführen kann: Sein C-Compiler baut oder startet kein Programm mit den Schaltern des Instruments, valgrind lässt sich nicht starten, oder der C-Compiler findet valgrinds Header valgrind/valgrind.h nicht. |
| H1022 | 6. Anderes | ja | Ein Pfad, den hilde test bekommt, ist weder ein Verzeichnis noch eine .hiq-Datei, zum Beispiel weil es ihn nicht gibt. |
| H1023 | 6. Anderes | ja | hilde test hat die Verzeichnisse durchsucht, die es bekam, und darin keine Testdatei gefunden. |
| H1024 | 6. Anderes | ja | Zwei Dateien unter den Pfaden von hilde test deklarieren dasselbe Modul, und eine Testdatei importiert es. |
| H1025 | 6. Anderes | ja | Ein Verzeichnis, in dem hilde test Module sucht, enthält ein Interface ohne den Rumpf gleichen Namens daneben. |
| H1026 | 6. Anderes | ja | Eine Bibliothek wird gebaut, --target-type=static, shared oder wasm, und die Kommandozeile nennt dazu einen Einstiegspunkt. |
| H1027 | 6. Anderes | ja | Die Ausgabe einer Bibliothek endet nicht auf die Endung ihrer Art, .a für --target-type=static und .so für shared, oder ist nur die Endung. |
| H1028 | 6. Anderes | ja | hilde test --contracts bekommt einen Seed oder eine Zahl von Runden, die keine Dezimalzahl in ihrem Bereich ist. |
| H1029 | 6. Anderes | ja | hilde test bekommt --seed oder --rounds ohne --contracts. |
| H1030 | 6. Anderes | ja | hilde guard bekommt einen Einstiegspunkt, der keine Funktion eines Moduls auf seiner Kommandozeile ist. |
| H1031 | 6. Anderes | ja | hilde guard bekommt eine Schwachstellen-Datenbank, die es nicht lesen kann: einen Pfad, den es nicht gibt, eine Datei, die kein JSON ist, oder einen Eintrag, der nicht im OSV-Format steht. |
| H1032 | 6. Anderes | ja | Ein Eintrag von --library-versions ist nicht der Name einer Bibliothek, wie sie gebunden wird, ein Doppelpunkt und eine Version aus Zahlen mit Punkten dazwischen. |
| H1033 | 6. Anderes | ja | Ein Pfad für hilde fmt ist weder ein Verzeichnis noch eine Datei auf .hih oder .hiq. |
| H1034 | 6. Anderes | ja | Eine Datei, die der Compiler bekam, ließ sich nicht öffnen oder lesen: Es gibt sie nicht, sie ist ein Verzeichnis, oder sie darf nicht gelesen werden. |
| H1035 | 6. Anderes | ja | Ein --build-value hat kein =, einen ungültigen Namen, einen Wert, der nicht druckbares ASCII von höchstens 1024 Bytes ist, oder einen doppelt gegebenen Namen. |
| H1036 | 6. Anderes | ja | SOURCE_DATE_EPOCH ist auf etwas gesetzt, das nicht ein bis achtzehn Dezimalziffern sind. |
| H1037 | 6. Anderes | ja | Das erste Wort ist kein Befehl von hilde. |
| H2046 | 6. Anderes | ja | Eine Funktion einer Testdatei trägt den Namen eines Tests und hat eine andere Form als ein Test. |
| H2047 | 6. Anderes | ja | Eine Testdatei deklariert keine Funktion mit dem Namen eines Tests. |
| H2048 | 6. Anderes | ja | Ein pragma Foreign_Library nennt ein System, das der Compiler nicht kennt. |
| H2049 | 6. Anderes | ja | Ein pragma Foreign_Library hat Argumente, die es nicht kennt, oder seine beiden in der anderen Reihenfolge. |
| H3059 | 6. Anderes | ja | Ein literales Muster für compile aus Standard.Regex ist eines, das das Modul zur Laufzeit ablehnen würde. |
| H5001 | 6. Anderes | ja | Die Einstiegsfunktion hat mehr als einen Parameter. |
| H5002 | 6. Anderes | ja | Das in --entrypoint genannte Modul hat keine Funktion dieses Namens. |
| H5003 | 6. Anderes | ja | Der in --entrypoint genannte Einstiegspunkt ist keine Funktion, etwa eine Konstante. |
| H5004 | 6. Anderes | ja | Die Einstiegsfunktion ist generisch. |
| H5005 | 6. Anderes | ja | Das Modul hat ein Interface, und das Interface deklariert die Einstiegsfunktion nicht. |
| H5006 | 6. Anderes | ja | Der eine Parameter der Einstiegsfunktion hat nicht den Typ RootCapability. |
| H5007 | 6. Anderes | ja | Die Einstiegsfunktion gibt kein ExitCode zurück. |
| H6001 | 6. Anderes | ja | Der Pfad in @bytes ist leer, absolut oder enthält einen Teil ... |
| H6002 | 6. Anderes | ja | Die in @bytes genannte Datei lässt sich nicht lesen, etwa weil sie nicht neben dem Modul liegt. |
| H6005 | 6. Anderes | ja | Die Kommandozeile enthält ein Argument, das compile oder query nicht verwendet, etwa ein unbekanntes Flag. |
| H6013 | 6. Anderes | ja | Ein Ausleihausdruck steht dort, wo keine Anweisung die Ausleihe fassen kann, etwa im Wert einer Konstanten. |
| H6020 | 6. Anderes | ja | Eine Funktion bindet denselben Namen zweimal im selben Gültigkeitsbereich, etwa mit zwei let. |
| H6025 | 6. Anderes | ja | Zwei verschachtelte borrow-Anweisungen geben ihren Regionen denselben Namen. |
| H6047 | 6. Anderes | ja | Eine Liste von Typparametern nennt denselben Parameter zweimal. |
| H9999 | 6. Anderes | nein | Ein interner Fehler: Der Compiler hat einen Zustand erreicht, den seine eigenen Prüfungen hätten ausschließen sollen. |
| H7001 | 7. Templates | ja | Der Name eines Templates ist leer. |
| H7002 | 7. Templates | ja | Der Pfad eines Templates ist absolut. |
| H7003 | 7. Templates | ja | Der Pfad eines Templates enthält einen Teil .. und verlässt damit das Verzeichnis des Moduls. |
| H7004 | 7. Templates | ja | Eine Template-Datei lässt sich nicht lesen, etwa weil sie nicht neben dem Modul liegt. |
| H7005 | 7. Templates | ja | Ein Tag {{ oder {% wird geöffnet und nie geschlossen. |
| H7006 | 7. Templates | ja | Ein Kommentar {# wird geöffnet und nie mit #} geschlossen. |
| H7007 | 7. Templates | ja | Ein {% raw %} wird nie mit {% endraw %} geschlossen. |
| H7008 | 7. Templates | ja | Im Tag {% endraw %} steht nach endraw noch etwas. |
| H7009 | 7. Templates | ja | Eine Zahl im Template ist keine ganze Dezimalzahl, etwa 1.5. |
| H7011 | 7. Templates | ja | Ein String in einem Tag enthält ein anderes Escape als `\n`, `\t`, `\r`, `\\`, `\'` und `\"`. |
| H7013 | 7. Templates | ja | In einem Tag steht ein Zeichen, das nicht zur Template-Sprache gehört. |
| H7014 | 7. Templates | ja | Dem Ausdruck in einem Tag fehlt ein nötiges Symbol, etwa eine schließende Klammer. |
| H7015 | 7. Templates | ja | In einem Tag wird ein Name erwartet, und etwas anderes steht dort, etwa nach einem Punkt. |
| H7016 | 7. Templates | ja | In einem Tag steht der Operator / oder **. |
| H7017 | 7. Templates | ja | Ein if in einer Zeile mischt einen Wert mit |safe und einen ohne, oder steht in einer Bedingung. |
| H7018 | 7. Templates | ja | Der Operator in fragt etwas anderes als einen Namen der Daten, oder nach etwas anderem als einem Text. |
| H7019 | 7. Templates | ja | Die Argumente eines Filters sind nicht durch Kommas getrennt oder nicht geschlossen. |
| H7020 | 7. Templates | ja | Ein Makro wird mit einem Schlüsselwort-Argument name=wert aufgerufen. |
| H7021 | 7. Templates | ja | Die Argumente eines Makroaufrufs sind nicht durch Kommas getrennt oder nicht geschlossen. |
| H7022 | 7. Templates | ja | Ein Aufruf über einen Punkt nennt kein Makro einer importierten Datei. |
| H7023 | 7. Templates | ja | In eckigen Klammern steht etwas anderes als ein Name in Anführungszeichen. |
| H7024 | 7. Templates | ja | Ein Minuszeichen steht vor einem Namen. |
| H7025 | 7. Templates | ja | In einem Tag steht ein Symbol, wo ein Ausdruck beginnen sollte. |
| H7026 | 7. Templates | ja | Ein Tag enthält keinen Ausdruck. |
| H7027 | 7. Templates | ja | Auf einen Ausdruck in einem Tag folgt weiterer Text. |
| H7028 | 7. Templates | ja | Ein {% %}-Tag beginnt nicht mit einem Schlüsselwort. |
| H7029 | 7. Templates | ja | Ein {% %}-Tag verwendet ein Schlüsselwort, das diese Template-Sprache nicht kennt, etwa do. |
| H7030 | 7. Templates | ja | Ein {% include %} oder {% extends %} nimmt den Namen des Templates und nichts danach. |
| H7031 | 7. Templates | ja | Ein {% include %} oder {% extends %} bekommt einen Namen, der kein String-Literal ist. |
| H7032 | 7. Templates | ja | Einem {% import %} fehlen `as` und ein Name, oder es verlangt den Kontext. |
| H7033 | 7. Templates | ja | Ein Template verwendet {% autoescape %}. |
| H7034 | 7. Templates | ja | Ein schließender oder fortsetzender Tag wie {% endif %} oder {% else %} steht ohne seinen öffnenden Tag. |
| H7035 | 7. Templates | ja | Auf ein {% else %} eines {% if %} folgt kein {% endif %}. |
| H7036 | 7. Templates | ja | Ein {% if %} wird nie mit {% endif %} geschlossen. |
| H7037 | 7. Templates | ja | Ein {% for %} nennt mehr als drei Namen. |
| H7038 | 7. Templates | ja | Einem {% for %} fehlt das Wort in. |
| H7039 | 7. Templates | ja | Nach der Folge eines {% for %} steht etwas anderes als `if` und eine Bedingung. |
| H7040 | 7. Templates | ja | Auf ein {% else %} eines {% for %} folgt kein {% endfor %}. |
| H7041 | 7. Templates | ja | Ein {% for %} wird nie mit {% endfor %} geschlossen. |
| H7042 | 7. Templates | ja | Ein Block ist als required markiert. |
| H7043 | 7. Templates | ja | Ein {% block %} hat keinen Namen oder danach etwas anderes als scoped. |
| H7044 | 7. Templates | ja | Ein {% block %} wird nie mit {% endblock %} geschlossen. |
| H7045 | 7. Templates | ja | Ein {% endblock %} nennt einen anderen Block als den, den es schließt. |
| H7046 | 7. Templates | ja | Der Vorgabewert eines Makroparameters ist kein Literal. |
| H7047 | 7. Templates | ja | Die Parameter eines Makros sind nicht durch Kommas getrennt. |
| H7048 | 7. Templates | ja | Auf die Parameterliste eines Makros folgt weiterer Text. |
| H7049 | 7. Templates | ja | Ein {% macro %} wird nie mit {% endmacro %} geschlossen. |
| H7050 | 7. Templates | ja | Ein {% from ... import %} gibt einem importierten Makro mit as einen anderen Namen. |
| H7051 | 7. Templates | ja | Ein {% from ... import %} nennt etwas anderes als Makros. |
| H7052 | 7. Templates | ja | Einem {% from %} fehlt der Dateiname als String oder das Wort import. |
| H7054 | 7. Templates | ja | Ein Makro wird zweimal mit zwei Rümpfen definiert. |
| H7055 | 7. Templates | ja | Ein Template importiert Makros aus sich selbst. |
| H7056 | 7. Templates | ja | Ein {% from ... import %} nennt ein Makro, das die Datei nicht definiert. |
| H7057 | 7. Templates | ja | Ein Template bindet sich selbst ein oder erweitert sich selbst, direkt oder über andere. |
| H7058 | 7. Templates | ja | Ein Template erweitert ein zweites Mal. |
| H7059 | 7. Templates | ja | Nach {% extends %} steht Text außerhalb eines Blocks. |
| H7060 | 7. Templates | ja | Nach {% extends %} steht ein Wert außerhalb eines Blocks. |
| H7061 | 7. Templates | ja | Nach {% extends %} steht ein {% if %} oder {% for %} außerhalb eines Blocks. |
| H7062 | 7. Templates | ja | Nach {% extends %} steht ein {% include %} außerhalb eines Blocks. |
| H7063 | 7. Templates | ja | super() steht in einem Block, den kein Template darüber hat. |
| H7064 | 7. Templates | ja | super() bekommt Argumente. |
| H7065 | 7. Templates | ja | Ein {% extends %} steht in einem anderen Tag, etwa einem {% if %}. |
| H7066 | 7. Templates | ja | Ein Template definiert einen Block, den kein erweitertes Template hat. |
| H7067 | 7. Templates | ja | Ein Wert steht an einer Stelle des HTML, an der ihn kein Maskieren sicher macht, etwa im Namen eines Tags oder in seiner Attributliste. |
| H7069 | 7. Templates | ja | loop wird für etwas anderes als loop.index, loop.index0, loop.length, loop.first oder loop.last verwendet. |
| H7070 | 7. Templates | ja | Ein mit {% from ... import %} geholtes Makro verwendet die Daten des Templates. |
| H7071 | 7. Templates | ja | loop wird außerhalb eines {% for %} verwendet. |
| H7072 | 7. Templates | ja | Eine in einer Bedingung verglichene Zahl ist zu groß. |
| H7073 | 7. Templates | ja | Ein Schleifenattribut wird ausgegeben, das sich nicht ausgeben lässt. |
| H7075 | 7. Templates | ja | `\|length` wird auf etwas angewandt, das kein Name der Daten ist. |
| H7076 | 7. Templates | ja | Es wird ein Filter verwendet, den diese Template-Sprache nicht kennt. |
| H7077 | 7. Templates | ja | none wird ausgegeben. |
| H7079 | 7. Templates | ja | Ein Makroaufruf steht mit einem Filter in {{ }}. |
| H7080 | 7. Templates | ja | Ein Attribut von loop, das keine Zahl ist, steht, wo eine Zahl hingehört. |
| H7082 | 7. Templates | ja | Eine Bedingung fragt is defined. |
| H7083 | 7. Templates | ja | is none wird von etwas gefragt, das kein Name der Daten ist. |
| H7084 | 7. Templates | ja | Eine Bedingung verwendet einen Test, den diese Template-Sprache nicht kennt. |
| H7085 | 7. Templates | ja | Ein String wird mit einem anderen Operator als == und != verglichen. |
| H7086 | 7. Templates | ja | Ein Vergleich vergleicht nicht einen Namen mit einem Literal. |
| H7087 | 7. Templates | ja | Etwas, das keine Bedingung ist, steht als Bedingung, etwa ein String. |
| H7088 | 7. Templates | ja | Ein Makroparameter, der ein Literal bekommt, wird mit einem Feld verwendet, wie in x.name. |
| H7089 | 7. Templates | ja | Ein Makro wird aufgerufen, das nicht definiert ist. |
| H7090 | 7. Templates | ja | Ein Makro ruft sich selbst auf. |
| H7091 | 7. Templates | ja | Ein Makro wird mit mehr Argumenten aufgerufen, als es Parameter hat. |
| H7092 | 7. Templates | ja | Ein Makro wird ohne Wert für einen Parameter ohne Vorgabewert aufgerufen. |
| H7093 | 7. Templates | ja | Ein Makroargument ist weder ein Name noch ein Literal. |
| H7095 | 7. Templates | ja | Die Zweige eines {% if %} enden an verschiedenen Stellen des HTML, etwa einer in einem Script und einer außerhalb. |
| H7096 | 7. Templates | ja | Ein {% for %} läuft über etwas, das kein Name der Daten ist. |
| H7097 | 7. Templates | ja | Der Rumpf eines {% for %} endet an einer anderen Stelle des HTML, als er beginnt. |
| H7098 | 7. Templates | ja | Das {% else %} eines {% for %} endet an einer anderen Stelle des HTML, als es beginnt. |
| H7099 | 7. Templates | ja | Ein Modul, das @template verwendet, importiert Standard.Template nicht. |
| H7100 | 7. Templates | ja | Einem set-Block, einem with, einem filter oder einem call fehlt sein End-Tag. |
| H7101 | 7. Templates | ja | Ein set-, with-, filter- oder call-Tag hat nicht seine Form. |
| H7102 | 7. Templates | ja | Der Name eines Imports wird ausgegeben oder zweimal vergeben. |
| H7103 | 7. Templates | ja | Ein set steht nach extends und außerhalb eines Blocks. |
| H7104 | 7. Templates | ja | Ein berechneter Wert wird nach einem Feld gefragt. |
| H7105 | 7. Templates | ja | // oder % teilt durch einen Namen der Daten oder durch null. |
| H7106 | 7. Templates | ja | Ein Operand einer Rechnung ist keine Zahl. |
| H7107 | 7. Templates | ja | ~ verbindet einen Wert mit |safe mit einem maskierten. |
| H7108 | 7. Templates | ja | Die Argumente eines Filters oder von loop.cycle haben nicht ihre Form. |
| H7109 | 7. Templates | ja | Ein filter-Block nennt einen Filter, der auf einen Wert wirkt. |
| H7110 | 7. Templates | ja | Ein set steht in einem if. |
| H7111 | 7. Templates | ja | Ein filter- oder set-Block steht nicht im HTML-Text oder endet anderswo. |
| H7112 | 7. Templates | ja | caller() steht in einem Makro, das ohne call-Block aufgerufen wird. |
| H7113 | 7. Templates | ja | Der Text eines set-Blocks wird außerhalb von HTML-Text ausgegeben. |
| H7114 | 7. Templates | ja | @template nennt eine unbekannte Option. |
| H7115 | 7. Templates | ja | Der Schlüssel von _( ) ist kein String-Literal. |
| H7116 | 7. Templates | ja | Ein Argument von _( ) wird zweimal benannt. |
| H7117 | 7. Templates | ja | {% catalog %} nennt nicht genau eine Funktion. |
| H7118 | 7. Templates | ja | Der Text eines {% trans %}-Blocks ist nicht genau ein Schlüssel. |
| H7119 | 7. Templates | ja | {% pluralize %} steht in einem {% trans %} ohne count. |
| H7120 | 7. Templates | ja | Zwischen {% pluralize %} und {% endtrans %} steht Text. |
| H7121 | 7. Templates | ja | Ein Template nennt seinen Katalog zweimal. |
| H7122 | 7. Templates | ja | Eine Übersetzung steht vor jedem {% catalog %}. |
| H7123 | 7. Templates | ja | Eine Übersetzung steht in einem Skript oder einem JavaScript-Attribut. |
| H7124 | 7. Templates | ja | Eine Übersetzung steht mit einem Filter oder einem ~. |
| H7125 | 7. Templates | ja | Ein Argument von _( ) hat keinen Namen. |
| H7126 | 7. Templates | ja | Ein Argument von {% trans %} wird zweimal benannt. |
| H7127 | 7. Templates | ja | Ein Modul, dessen Template übersetzt, importiert Standard.I18n nicht. |
| H7128 | 7. Templates | ja | {% catalog %} steht nach {% extends %} außerhalb eines Blocks. |
| H8001 | 8. SQL | ja | Ein String oder ein in Anführungszeichen gesetzter Name im SQL wird nicht geschlossen. |
| H8002 | 8. SQL | ja | Ein Kommentar `/*` im SQL wird nicht mit `*/` geschlossen. |
| H8003 | 8. SQL | ja | Ein Blob-Literal x'...' enthält keine gerade Anzahl hexadezimaler Ziffern. |
| H8004 | 8. SQL | ja | Eine Zahl geht ohne Trennung in einen Namen über, wie in 18years. |
| H8005 | 8. SQL | ja | Ein Name steht in Backticks oder eckigen Klammern. |
| H8006 | 8. SQL | ja | Im SQL steht ein nummerierter Parameter wie ?1. |
| H8007 | 8. SQL | ja | Im SQL steht ein benannter Parameter wie :age. |
| H8008 | 8. SQL | ja | Im SQL steht ein Zeichen, das der Compiler nicht als SQL liest, etwa #. |
| H8009 | 8. SQL | ja | Ein Schlüsselwort fehlt, wo die Grammatik es verlangt, etwa BY nach ORDER. |
| H8010 | 8. SQL | ja | Ein Symbol fehlt, wo die Grammatik es verlangt, etwa die Klammer nach IN. |
| H8011 | 8. SQL | ja | Ein Name fehlt, wo die Grammatik einen verlangt, etwa die Tabelle nach FROM. |
| H8012 | 8. SQL | ja | Das SQL verwendet etwas, das SQLite kennt und dieser Compiler nicht annimmt, weil er ihm keinen Typ geben könnte, etwa eine Unterabfrage. |
| H8013 | 8. SQL | ja | Eine andere Funktion als count bekommt `*`. |
| H8014 | 8. SQL | ja | Eine Spalte des Ergebnisses wird ohne AS benannt. |
| H8015 | 8. SQL | ja | Auf OR in INSERT OR oder UPDATE OR folgt etwas anderes als ABORT, FAIL, IGNORE, REPLACE oder ROLLBACK. |
| H8016 | 8. SQL | ja | Der Vorgabewert einer Spalte in einer Migration ist kein Literal, keine Zahl mit Vorzeichen, kein CURRENT_TIME, CURRENT_DATE oder CURRENT_TIMESTAMP und kein Ausdruck in Klammern. |
| H8017 | 8. SQL | ja | Ein Spaltentyp in einer Migration hat eine Größe, wie in VARCHAR(40). |
| H8018 | 8. SQL | ja | Nach CONSTRAINT und seinem Namen ist eine Tabellen-Constraint weder PRIMARY KEY noch UNIQUE, CHECK oder FOREIGN KEY. |
| H8019 | 8. SQL | ja | Auf WITHOUT nach einer Tabelle folgt nicht ROWID. |
| H8020 | 8. SQL | ja | In der Liste der Tabellenoptionen steht nach einem Komma etwas anderes als STRICT oder WITHOUT ROWID. |
| H8021 | 8. SQL | ja | Bei CREATE INDEX fehlt nach der Tabelle die Klammer mit den Spalten. |
| H8022 | 8. SQL | ja | Auf ALTER TABLE folgt etwas anderes als RENAME, ADD oder DROP. |
| H8023 | 8. SQL | ja | Eine Migration legt etwas anderes als eine Tabelle oder einen Index an, etwa eine View. |
| H8024 | 8. SQL | ja | Eine Migration löscht etwas anderes als eine Tabelle oder einen Index, etwa eine View. |
| H8025 | 8. SQL | ja | Eine Migration enthält eine andere Anweisung als CREATE TABLE, CREATE INDEX, ALTER TABLE, DROP TABLE, DROP INDEX, INSERT, UPDATE und DELETE, etwa PRAGMA. |
| H8026 | 8. SQL | ja | Eine Abfrage ist weder SELECT noch INSERT, UPDATE oder DELETE. |
| H8027 | 8. SQL | ja | Das SQL nennt eine Tabelle, die die Migrationen nicht anlegen. |
| H8028 | 8. SQL | ja | Das SQL nennt eine Spalte, die die Tabelle nicht hat. |
| H8029 | 8. SQL | ja | Ein Parameter steht, wo sich sein Typ nicht bestimmen lässt, etwa in ORDER BY. |
| H8030 | 8. SQL | ja | Eine Spalte wird mit einer Tabelle oder einem Alias qualifiziert, die die Abfrage nicht hat. |
| H8032 | 8. SQL | ja | Eine Abfrage nennt eine Spalte und hat kein FROM, aus dem sie sie nehmen könnte. |
| H8033 | 8. SQL | ja | Keine Tabelle der Abfrage hat eine Spalte dieses Namens. |
| H8034 | 8. SQL | ja | Mehr als eine Tabelle der Abfrage hat eine Spalte dieses Namens. |
| H8035 | 8. SQL | ja | Ein Vorzeichen steht vor etwas, das keine Zahl ist. |
| H8036 | 8. SQL | ja | NOT steht vor etwas, das keine Bedingung ist. |
| H8037 | 8. SQL | ja | % nimmt zwei INTEGER und bekommt ein REAL. |
| H8038 | 8. SQL | ja | Es wird mit etwas gerechnet, das keine Zahl ist. |
| H8039 | 8. SQL | ja | `\|\|` verbindet etwas, das kein TEXT ist. |
| H8040 | 8. SQL | ja | Ein Wert wird mit = oder einem ähnlichen Operator mit NULL verglichen. |
| H8041 | 8. SQL | ja | Zwei Werte verschiedenen Typs werden verglichen, etwa TEXT mit INTEGER. |
| H8042 | 8. SQL | ja | IS vergleicht zwei Werte verschiedenen Typs, die nie gleich sein können. |
| H8043 | 8. SQL | ja | Ein Parameter wird auf NULL geprüft. |
| H8044 | 8. SQL | ja | LIKE oder GLOB bekommt etwas, das kein TEXT ist. |
| H8045 | 8. SQL | ja | Ein Parameter steht links von IN. |
| H8046 | 8. SQL | ja | NULL steht links von IN. |
| H8047 | 8. SQL | ja | NULL steht in der Liste von IN. |
| H8048 | 8. SQL | ja | Ein Wert in der Liste von IN hat einen anderen Typ als der Wert links, die beiden können also nie gleich sein. |
| H8049 | 8. SQL | ja | Ein Parameter steht links von BETWEEN. |
| H8050 | 8. SQL | ja | NULL steht links von BETWEEN. |
| H8051 | 8. SQL | ja | Eine Grenze von BETWEEN hat einen anderen Typ als der Wert, mit dem sie verglichen wird. |
| H8052 | 8. SQL | ja | AND oder OR verbindet etwas, das keine Bedingung ist. |
| H8053 | 8. SQL | ja | `count(*)` steht außerhalb der Spalten, von HAVING und ORDER BY, etwa in WHERE. |
| H8054 | 8. SQL | ja | Eine Aggregatfunktion steht außerhalb der Spalten, von HAVING und ORDER BY, etwa in WHERE. |
| H8055 | 8. SQL | ja | DISTINCT steht in einer Funktion, die keine Aggregatfunktion ist. |
| H8056 | 8. SQL | ja | Eine Funktion, die hier ein Argument nimmt, bekommt eine andere Anzahl. |
| H8057 | 8. SQL | ja | Eine Funktion, die eine Zahl nimmt, etwa abs oder sum, bekommt etwas anderes. |
| H8058 | 8. SQL | ja | count bekommt einen Parameter. |
| H8059 | 8. SQL | ja | min oder max bekommt einen Parameter. |
| H8060 | 8. SQL | ja | min oder max bekommt NULL. |
| H8061 | 8. SQL | ja | coalesce bekommt weniger als zwei Argumente oder ifnull nicht genau zwei. |
| H8062 | 8. SQL | ja | coalesce oder ifnull bekommt nur Parameter; sein Typ lässt sich daher nicht bestimmen. |
| H8063 | 8. SQL | ja | Der erste Wert von coalesce oder ifnull, der kein Parameter ist, ist NULL. |
| H8064 | 8. SQL | ja | coalesce oder ifnull bekommt Werte verschiedenen Typs. |
| H8065 | 8. SQL | ja | length bekommt etwas anderes als TEXT oder BLOB. |
| H8066 | 8. SQL | ja | lower oder upper bekommt etwas anderes als TEXT. |
| H8067 | 8. SQL | ja | Das SQL ruft eine Funktion auf, deren Typ der Compiler nicht kennt. |
| H8068 | 8. SQL | ja | Zwei Parameter treffen an einem Operator aufeinander, und keiner gibt dem anderen einen Typ. |
| H8069 | 8. SQL | ja | Ein WHERE, ON, HAVING oder CHECK bekommt etwas, das keine Bedingung ist. |
| H8070 | 8. SQL | ja | Eine Spalte des Ergebnisses hat einen Namen, der kein Feld des Zeilen-Records benennen kann, etwa einen Namen mit Leerzeichen oder ein Hilde-Schlüsselwort. |
| H8071 | 8. SQL | ja | `*` steht in einer Abfrage ohne Tabelle. |
| H8072 | 8. SQL | ja | `t.*` nennt eine Tabelle oder einen Alias, die die Abfrage nicht hat. |
| H8073 | 8. SQL | ja | Eine Spalte des Ergebnisses ist immer NULL und hat deshalb keinen Typ. |
| H8074 | 8. SQL | ja | Eine Spalte des Ergebnisses, die keine einfache Spalte ist, hat keinen Namen. |
| H8075 | 8. SQL | ja | Zwei Spalten des Ergebnisses haben denselben Namen. |
| H8076 | 8. SQL | ja | NULL wird in eine Spalte geschrieben, die NOT NULL ist. |
| H8077 | 8. SQL | ja | Ein Wert eines anderen Typs wird in eine Spalte geschrieben. |
| H8078 | 8. SQL | ja | Ein Wert, der NULL sein kann, wird in eine Spalte geschrieben, die NOT NULL ist. |
| H8079 | 8. SQL | ja | Eine Tabelle steht zweimal in FROM, ohne einen Alias, der die beiden unterscheidet. |
| H8081 | 8. SQL | ja | LIMIT oder OFFSET bekommt etwas anderes als ein INTEGER, das nicht NULL ist. |
| H8082 | 8. SQL | ja | Die Spaltenliste eines INSERT nennt eine Spalte zweimal. |
| H8083 | 8. SQL | ja | Ein INSERT lässt eine Spalte aus, die NOT NULL ist und keinen Vorgabewert hat. |
| H8084 | 8. SQL | ja | Ein INSERT hat eine Spaltenliste und DEFAULT VALUES. |
| H8085 | 8. SQL | ja | Eine Zeile eines INSERT hat eine andere Anzahl Werte, als es Spalten gibt. |
| H8086 | 8. SQL | ja | Eine Spalte in einer Migration hat den Typ ANY. |
| H8087 | 8. SQL | ja | Eine Spalte in einer Migration hat keinen Typ. |
| H8088 | 8. SQL | ja | Eine Spalte in einer Migration hat einen Typ, den eine STRICT-Tabelle nicht kennt, etwa DATE. |
| H8089 | 8. SQL | ja | Eine Migration legt eine Tabelle an, die es schon gibt. |
| H8090 | 8. SQL | ja | Eine Tabelle wird ohne STRICT angelegt. |
| H8091 | 8. SQL | ja | Eine Tabelle definiert eine Spalte zweimal. |
| H8092 | 8. SQL | ja | Eine Tabelle hat mehr als einen PRIMARY KEY. |
| H8093 | 8. SQL | ja | Der PRIMARY KEY einer Tabelle nennt eine Spalte, die die Tabelle nicht hat. |
| H8094 | 8. SQL | ja | ALTER TABLE ADD COLUMN fügt eine Spalte hinzu, die die Tabelle schon hat. |
| H8095 | 8. SQL | ja | ALTER TABLE ADD COLUMN fügt einen PRIMARY KEY hinzu. |
| H8096 | 8. SQL | ja | ALTER TABLE ADD COLUMN fügt eine NOT-NULL-Spalte ohne Vorgabewert hinzu. |
| H8097 | 8. SQL | ja | ALTER TABLE RENAME TO gibt einer Tabelle den Namen einer Tabelle, die es gibt. |
| H8098 | 8. SQL | ja | ALTER TABLE RENAME COLUMN gibt einer Spalte den Namen einer Spalte, die die Tabelle hat. |
| H8099 | 8. SQL | ja | ALTER TABLE DROP COLUMN löscht die letzte Spalte einer Tabelle. |
| H8100 | 8. SQL | ja | DROP TABLE löscht eine Tabelle, die es nicht gibt. |
| H8101 | 8. SQL | ja | CREATE INDEX legt einen Index an, dessen Name schon vergeben ist. |
| H8102 | 8. SQL | ja | DROP INDEX löscht einen Index, den es nicht gibt. |
| H8103 | 8. SQL | ja | Eine Migrationsdatei lässt sich nicht lesen, etwa weil ein Verzeichnis den Namen einer Migration trägt. |
| H8104 | 8. SQL | ja | Neben dem Modul gibt es kein Verzeichnis migrations. |
| H8105 | 8. SQL | ja | Das Verzeichnis migrations enthält keine Datei, die auf .sql endet. |
| H8106 | 8. SQL | ja | Eine Datei in migrations heißt nicht `<Nummer>-<Name>.sql` mit einer Nummer ab 1. |
| H8107 | 8. SQL | ja | Die Migrationen sind nicht lückenlos mit 1, 2, 3 und so weiter nummeriert, oder eine Nummer kommt zweimal vor. |
| H8108 | 8. SQL | ja | Auf eine Anweisung in einer Migration folgt kein ;, bevor die nächste beginnt. |
| H8109 | 8. SQL | ja | Eine Migration enthält einen Parameter ?. |
| H8110 | 8. SQL | ja | Ein Modul, das @query, @execute oder @migrations verwendet, importiert weder Standard.Sqlite noch Standard.SqlCipher. |
| H8111 | 8. SQL | ja | Das SQL eines @query oder @execute enthält mehr als eine Anweisung. |
| H8112 | 8. SQL | ja | Das SQL hat eine andere Anzahl Parameter ?, als Werte übergeben werden. |
| H8113 | 8. SQL | ja | Der Zeilentyp von @query ist kein Record, geschrieben Name oder Name[R], wobei R die Region ist, unter der der Text der Zeile verliehen wird. |
| H8115 | 8. SQL | ja | @query bekommt eine Anweisung, die keine Zeilen liefert. |
| H8116 | 8. SQL | ja | @execute bekommt eine Anweisung, die Zeilen liefert. |
| H2051 | 9. Verträge | ja | Der Body einer öffentlichen Funktion trägt requires-, ensures- oder raises-Klauseln. |
| H2052 | 9. Verträge | ja | Eine aus C importierte Funktion hat einen Vertrag. |
| H2053 | 9. Verträge | ja | Ein ensures nennt eine Variable, die der Body der Funktion deklariert. |
| H2054 | 9. Verträge | ja | Eine Funktion mit einem ensures hat einen Parameter namens result. |
| H2055 | 9. Verträge | ja | old steht, wo es nichts bedeutet: in einem requires, in einem anderen old oder mit anderem als einem Wert. |
| H2056 | 9. Verträge | ja | Eine Testfunktion hat ein requires. |
| H2057 | 9. Verträge | ja | Ein Record mit einer Invariante lässt sich außerhalb seines Moduls bauen oder beschreiben. |
| H3096 | 9. Verträge | ja | Eine Bedingung verwendet einen linearen Wert selbst statt über eine Referenz. |
| H3097 | 9. Verträge | ja | Eine Bedingung nimmt eine Referenz zum Schreiben. |
| H3098 | 9. Verträge | ja | Eine Bedingung ruft eine Funktion, die ein Binding-Modul, C oder eine Referenz zum Schreiben erreicht. |
| H3099 | 9. Verträge | ja | Eine Bedingung ruft über einen Funktionszeiger oder eine Methode eines Typparameters. |
| H3100 | 9. Verträge | ja | old bekommt einen Wert, der nicht frei ist. |
| H3101 | 9. Verträge | ja | Eine Funktion mit einem requires wird als Funktionszeiger genommen. |
| H5008 | 9. Verträge | ja | Die Einstiegsfunktion hat ein requires. |
| H2058 | 10. Fehlerarten | ja | Die Methode einer Instanz trägt eine raises-Klausel. |
| H3102 | 10. Fehlerarten | ja | Ein raise nennt eine Art, die die raises-Klausel der Funktion nicht nennt. |
| H3103 | 10. Fehlerarten | ja | Ein Aufruf kann mit einer Fehlerart enden, die die raises-Klausel des Aufrufers nicht nennt. |
| H3104 | 10. Fehlerarten | ja | Eine Funktion mit einer raises-Klausel wird als Funktionszeiger genommen. |
| H2060 | 11. Never und Slots | ja | Ein return steht in einer Funktion, die Never zurückgibt. |
| H2061 | 11. Never und Slots | ja | Eine Funktion, die Never zurückgibt, hat einen Pfad, der das Ende ihres Rumpfs erreicht. |
| H2062 | 11. Never und Slots | ja | Eine Funktion, die Never zurückgibt, trägt eine ensures-Klausel. |
| H2063 | 11. Never und Slots | ja | Ein Slot hat weder einen Standardrumpf noch eine Implementierung im Programm. |
| H2064 | 11. Never und Slots | ja | Zwei Funktionen des Programms implementieren denselben Slot. |
| H2065 | 11. Never und Slots | ja | Eine Implementierung eines Slots hat eine andere Signatur als der Slot. |
| H2066 | 11. Never und Slots | ja | Ein pragma Implements nennt etwas, das kein Slot ist. |
| H2067 | 11. Never und Slots | ja | Ein pragma Slot oder pragma Implements steht, wo es nichts bedeutet. |
| H3109 | 11. Never und Slots | ja | Never steht als Typ von etwas, das einen Wert hält. |
| H3110 | 11. Never und Slots | ja | Ein Aufruf einer Funktion, die Never zurückgibt, ist ein Argument oder ein Operand. |
| H1038 | 12. Ziele | ja | Kein Compiler für wasm32-wasi wird gefunden. |
| H1039 | 12. Ziele | ja | HILDE_WASM_CC nennt einen Compiler, den hilde für WebAssembly nicht kennt. |
| H1040 | 12. Ziele | nein | hilde test --target=wasm findet keine Laufzeit für WebAssembly. |
| H1041 | 12. Ziele | ja | --target nennt kein Ziel, für das hilde baut. |
| H1042 | 12. Ziele | nein | --target nennt ein anderes System als das, auf dem hilde läuft. |
| H1043 | 12. Ziele | ja | --target=wasm steht bei einem Archiv oder einem Shared Object. |
| H1044 | 12. Ziele | ja | Die Ausgabe eines Programms für wasm endet nicht auf .wasm. |
| H2068 | 12. Ziele | ja | Ein pragma Targets nennt kein Ziel, eines doppelt, eines, das es nicht gibt, oder ein Instead, das kein Modul ist. |
| H2069 | 12. Ziele | ja | Ein anderes Pragma als ein pragma Targets steht vor einem Modul-Interface. |
| H2070 | 12. Ziele | ja | Ein Modul außerhalb der Standardbibliothek nennt seine Ziele. |
| H2071 | 12. Ziele | ja | Ein Interface der Standardbibliothek nennt keine Ziele. |
| H2072 | 12. Ziele | ja | Ein Modul nennt ein Ziel, für das es einen seiner Importe nicht gibt. |
| H2073 | 12. Ziele | ja | Ein Programm, das für ein Ziel gebaut wird, importiert ein Modul, das es dafür nicht gibt. |
| H1045 | 13. Pakete | nein | Ein Paketkommando wurde gegeben, und hilde-pkg liegt nicht neben dem Compiler. |
| H1046 | 13. Pakete | nein | hilde-pkg liegt neben dem Compiler und ließ sich nicht starten. |
| H1501 | 13. Pakete | nein | Das Kommando braucht ein Paket, und im Verzeichnis liegt keine hilde.toml. |
| H1502 | 13. Pakete | nein | hilde.toml ist kein TOML; die Meldung nennt Zeile und Spalte. |
| H1503 | 13. Pakete | nein | hilde.toml hat einen Schlüssel oder eine Tabelle, die ein Manifest nicht hat, etwa einen vertippten. |
| H1504 | 13. Pakete | nein | Ein Schlüssel, den hilde.toml haben muss, fehlt: Name oder Version des Pakets, git-URL oder Version einer Anforderung. |
| H1505 | 13. Pakete | nein | Ein Wert hat die falsche Form: ein Name, der kein Modulpräfix ist, eine Version, die nicht vX.Y.Z ist, eine Fähigkeit, die es nicht gibt, oder ein Argument falscher Form. |
| H1506 | 13. Pakete | nein | Ein Präfix kommt von zwei git-URLs, oder ein Paket heißt anders als das Präfix, unter dem es verlangt wird. |
| H1507 | 13. Pakete | nein | git ist nicht im PATH, und das Kommando braucht es. |
| H1508 | 13. Pakete | nein | git ist gescheitert: eine falsche URL, ein Repository, das nicht gelesen werden darf, oder ein Programm, das sich nicht starten ließ. |
| H1509 | 13. Pakete | nein | Das Repository hat keinen Tag der verlangten Version; der Vorschlag nennt die nächstliegenden Tags. |
| H1510 | 13. Pakete | nein | Der Baum eines Pakets enthält einen symbolischen Link oder eine Sonderdatei. |
| H1511 | 13. Pakete | nein | Ein Release hat keine Signatur, und die Richtlinie des Pakets verlangt eine. |
| H1512 | 13. Pakete | nein | Eine Signatur hält nicht, der Schlüssel ist nicht der bei der ersten Verwendung übernommene, oder ein Release ist nach einem signierten unsigniert. |
| H1513 | 13. Pakete | nein | Der geheime Schlüssel lässt sich nicht lesen, ist kein signify-Schlüssel oder hat eine Passphrase. |
| H1514 | 13. Pakete | nein | hilde.sum fehlt, hat eine falsche Zeile oder keine Zeile für eine Anforderung. |
| H1515 | 13. Pakete | nein | Ein Baum in vendor/ fehlt, ist geändert oder steht nicht in hilde.sum. |
| H1516 | 13. Pakete | nein | Zwei Hauptversionen eines Pakets werden verlangt; eine neue Hauptversion bekommt ein neues Präfix. |
| H1517 | 13. Pakete | nein | Der Baum eines Pakets ist tiefer als 64 Verzeichnisse. |
| H1518 | 13. Pakete | nein | Ein Verzeichnis oder eine Datei eines Pakets lässt sich nicht lesen. |
| H1519 | 13. Pakete | nein | Eine Datei oder ein Verzeichnis lässt sich nicht schreiben. |
| H1521 | 13. Pakete | nein | hilde new oder ein Schlüssel würde über etwas schreiben, das schon da ist. |
| H1522 | 13. Pakete | nein | hilde doc findet kein Modul und keine Deklaration des Namens. |
| H1523 | 13. Pakete | nein | Ein Ziel aus hilde.toml erlaubt das pragma Targets eines erreichten Moduls nicht. |
| H1530 | 13. Pakete | nein | Die Version eines Releases ist niedriger, als die Änderung der Schnittstelle verlangt, etwa ein Bruch unter einer Nebenversion. |
| H1531 | 13. Pakete | nein | Ein Modul des Pakets hat keine Testdatei. |
| H1532 | 13. Pakete | nein | Die Tests des Pakets laufen nicht durch, oder der Compiler scheiterte daran. |
| H1533 | 13. Pakete | nein | Eine exportierte Funktion wird in keinem Test aufgerufen. |
| H1534 | 13. Pakete | nein | Die Version eines Releases ist nicht neuer als der neueste Tag. |
| H1047 | 14. Sperli | nein | Ein run-Kommando wurde gegeben, und hilde-launcher liegt nicht neben dem Compiler. |
| H1048 | 14. Sperli | nein | hilde-launcher liegt neben dem Compiler und ließ sich nicht starten. |
| H1601 | 14. Sperli | nein | Der Partner zeigte kein Zertifikat, eines, für das die CA des Jobs nicht bürgt, oder bot eine TLS-Version unter 1.3 an. |
| H1602 | 14. Sperli | nein | Der Subject des Zertifikats des Partners ist nicht der Job und der Rang, für den die Verbindung gilt. |
| H1603 | 14. Sperli | nein | Ein Host steht in SPERLI_REFUSED_HOSTS, ist host-a.invalid oder host-b.invalid oder ein Name darunter oder steht auf der Sperrliste des Betreibers; eine Sperrliste hebt die Regel nicht auf. |
| H1604 | 14. Sperli | nein | Das Join-Token eines Partners ist abgelaufen. |
| H1605 | 14. Sperli | nein | Das Join-Token eines Partners wurde für einen anderen Job ausgestellt. |
| H1606 | 14. Sperli | nein | Das Join-Token eines Partners wurde für einen anderen Rang, eine andere Größe, Inkarnation oder einen anderen Host ausgestellt. |
| H1607 | 14. Sperli | nein | Das Join-Token eines Partners ist missgebildet, oder seine Signatur gilt unter dem öffentlichen Schlüssel des Starters nicht. |
| H1608 | 14. Sperli | nein | Ein Frame kündigt mehr Nutzlast an als die Grenze von 16 MiB; er wird abgewiesen, bevor ein Byte der Nutzlast gelesen wird. |
| H1609 | 14. Sperli | nein | Ein Frame gehört zu einer älteren Inkarnation des Jobs; seine Nutzlast wird gelesen und verworfen, und das Warten geht weiter. |
| H1610 | 14. Sperli | nein | Der Kopf eines Frames bricht eine Regel des Protokolls: ein unbekannter Typ, ein Flag, ein Dienst oder eine Mitgliedschaftsepoche ungleich 0, ein anderer Job, andere Ränge oder eine neuere Inkarnation. |
| H1611 | 14. Sperli | nein | Ein Partner ging verloren: Die Verbindung wurde geschlossen, oder innerhalb der Stillegrenze kam kein Frame. |
| H1612 | 14. Sperli | nein | Ein Partner schickte einen Abort-Frame. |
| H1613 | 14. Sperli | nein | Das Hello eines Partners fehlt, kommt zweimal, hat eine andere Version oder bietet keinen Punkt-zu-Punkt-Dienst an. |
| H1614 | 14. Sperli | nein | Die Kommandozeile von hilde run oder seine Hostliste ist falsch: eine fehlende oder unbekannte Option, eine Zahl außerhalb des Bereichs, kein Host oder eine Zeile, die kein Host mit Port ist. |
| H1615 | 14. Sperli | nein | Ein Rang ließ sich nicht starten, oder die Schlüssel, Zertifikate oder Ports des Jobs ließen sich nicht herstellen. |
| H1616 | 14. Sperli | nein | Die Jobbeschreibung, die ein Rang auf der Standardeingabe bekam, ist missgebildet. |
| H1617 | 14. Sperli | nein | Ein Kollektiv-Frame passt nicht zu dem Aufruf, den er beantwortet: andere Operation, anderer Typ, andere Reduktion, Phase, Wurzel oder Folgenummer, oder Beiträge eines gather verschiedener Länge. |
| H1618 | 14. Sperli | nein | Die Argumente eines Kollektiv-Aufrufs sind falsch: eine Wurzel außerhalb des Jobs, ein Elementtyp und eine Reduktion, die nicht zusammenpassen, Daten, die keine ganze Zahl von Elementen oder Blöcken sind, oder Beiträge eines reduce verschiedener Länge. |
| H1619 | 14. Sperli | nein | Eine Checkpoint-Datei hat eine andere Magic oder Version oder einen Job, eine Epoche, einen Rang, eine Größe oder eine Länge, die nicht die erwartete ist, oder sie ist zu kurz. |
| H1620 | 14. Sperli | nein | Das SHA-256 des Zustands in einer Checkpoint-Datei ist nicht das in ihrem Kopf oder nicht das, das die COMMIT-Datei für den Rang aufführt. |
| H1621 | 14. Sperli | nein | Eine COMMIT-Datei ist missgebildet, gehört zu einem anderen Job oder einer anderen Epoche, oder ihre CompositeSig-Signatur gilt für den öffentlichen Schlüssel des Jobs nicht. Eine Epoche ohne gültige COMMIT-Datei zählt nicht. |
| H1622 | 14. Sperli | nein | Ein resume fand keine Epoche mit gültiger COMMIT-Datei und allen Rang-Dateien, oder die Ränge einigten sich nicht auf die Epoche. |
| H1623 | 14. Sperli | nein | Ein resume wurde für einen Job mit anderer Rangzahl verlangt, als der Checkpoint geschrieben wurde. Version 1 des Formats verlangt dieselbe Größe. |
| H1624 | 14. Sperli | nein | Ein Checkpoint wurde verlangt, während auf diesem Rang noch ein send oder receive offen war. |
| H1625 | 14. Sperli | nein | Ein Checkpoint konnte nicht geschrieben oder gesendet werden, oder es wurde kein Checkpoint-Verzeichnis genannt. |

## 1. Syntax

### H0001

Meldung:

```text
Parse Error
Character not allowed in source text: `$`
```

Im Quelltext steht ein Zeichen, mit dem kein Token beginnt. Außerhalb von
Kommentaren und Strings sind nur Buchstaben, Ziffern, Leerraum und die
Symbole der Sprache erlaubt.

Dieses Modul scheitert mit H0001:

```hilde fails H0001
module body Example is
    function main(): ExitCode is
        let total: Int32 := 1 $ 2;
        printLn(total);
        return ExitSuccess();
    end;
end module body.
```

Die richtige Form:

```hilde
module body Example is
    function main(): ExitCode is
        let total: Int32 := 1 + 2;
        printLn(total);
        return ExitSuccess();
    end;
end module body.
```

### H0003

Meldung:

```text
Parse Error
End of file in string literal.
```

Ein String-Literal wird mit einem Anführungszeichen geöffnet und nie
geschlossen. Der Rest der Datei gehört dann zum String, und die Datei endet
mitten darin.

Dieses Modul scheitert mit H0003:

```hilde fails H0003
module body Example is
    function main(): ExitCode is
        printLn("unclosed);
        return ExitSuccess();
    end;
end module body.
```

Die richtige Form:

```hilde
module body Example is
    function main(): ExitCode is
        printLn("closed");
        return ExitSuccess();
    end;
end module body.
```

### H0004

Meldung:

```text
Parse Error
End of file in triple string literal.
```

Ein String in dreifachen Anführungszeichen wird geöffnet und nie
geschlossen, und die Datei endet mitten darin.

Dieses Modul scheitert mit H0004:

```hilde fails H0004
module body Example is
    function main(): ExitCode is
        printLn("""unclosed);
        return ExitSuccess();
    end;
end module body.
```

Die richtige Form:

```hilde
module body Example is
    function main(): ExitCode is
        printLn("""closed""");
        return ExitSuccess();
    end;
end module body.
```

### H0005

Meldung:

```text
Parse Error
Error during parse.
```

Die Tokens ergeben kein Programm der Grammatik. Oft steckt ein Ausdruck mit
zwei Operatoren ohne Klammern dahinter: Hilde kennt keinen Vorrang von
Operatoren.

Dieses Modul scheitert mit H0005:

```hilde fails H0005
module body Example is
    function main(): ExitCode is
        let total: Int32 := 1 +;
        printLn(total);
        return ExitSuccess();
    end;
end module body.
```

Die richtige Form:

```hilde
module body Example is
    function main(): ExitCode is
        let total: Int32 := 1 + (2 * 3);
        printLn(total);
        return ExitSuccess();
    end;
end module body.
```

### H0006

Meldung:

```text
Parse Error
Function pointer type specifier must have at least one argument.
```

Der Funktionszeigertyp Fn steht ohne Typargumente. Er braucht mindestens
eines, den Rückgabetyp, und davor die Typen der Parameter.

Dieses Modul scheitert mit H0006:

```hilde fails H0006
module body Example is
    function keep(callback: Fn): Unit is
        return nil;
    end;

    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Die richtige Form:

```hilde
module body Example is
    function keep(callback: Fn[Int32]): Unit is
        return nil;
    end;

    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

### H0007

Meldung, aus dem Quelltext in `lib/Util.ml`:

```text
Character literal '`lit` is more than one character.
```

Ein Zeichen-Literal enthält mehr als ein Zeichen.  Der Lexer nimmt zwischen
den Apostrophen nur ein Zeichen oder ein Escape, also sieht der Parser nie
ein längeres Literal; der einzige Weg dahin war `'''`, das jetzt der
Apostroph ist, wie `'\''`.

Er bleibt, weil der Parser prüft, was der Lexer liefert: Ließe eine Änderung des Lexers ein längeres
Literal durch, würde es hier abgewiesen und nicht zu einer falschen Zahl.

Nicht ausgelöst: Es fand sich kein Programm, das diesen Fehler erreicht.

### H0008

Meldung:

```text
Parse Error
`method` is a reserved word and cannot be a name. Rename it, for example to `way`; docs/syntax.en.md, section 1, lists the reserved words.

Suggested fix: `way`
```

Ein reserviertes Wort steht, wo ein Name hingehört: der Name einer
Funktion, eines let, eines var, einer Konstante, die Variable eines for,
ein Parameter oder der Name nach as.  Wörter wie method, from und body
klingen nach guten Namen und sind trotzdem reserviert.

Dieses Modul scheitert mit H0008:

```hilde fails H0008
module body Example is
    function method(count: Int32): Int32 is
        return count;
    end;

    function main(): ExitCode is
        printLn(method(1));
        return ExitSuccess();
    end;
end module body.
```

Die richtige Form:

```hilde
module body Example is
    function methodOf(count: Int32): Int32 is
        return count;
    end;

    function main(): ExitCode is
        printLn(methodOf(1));
        return ExitSuccess();
    end;
end module body.
```

### H0009

Meldung:

```text
Parse Error
Hilde has no operator precedence: an operator takes two operands, and only `+`, `*`, `and` and `or` can be chained with themselves. Put the operation before `*` in parentheses, as in `(a + b) * c`.

Suggested fix: `(1 + 2)`
```

Hilde kennt keinen Vorrang: Ein Operator nimmt zwei atomare Operanden.
Nur die assoziativen Operatoren +, *, and und or dürfen eine Kette aus
demselben Operator bilden, a + b + c, gelesen von links.  Folgt ein anderer
Operator auf eine Operation, gehört diese Operation in Klammern.  Die Meldung
schlägt die Klammern um die Operation vor dem Operator vor.

Dieses Modul scheitert mit H0009:

```hilde fails H0009
module body Example is
    function main(): ExitCode is
        let total: Int32 := 1 + 2 * 3;
        printLn(total);
        return ExitSuccess();
    end;
end module body.
```

Die richtige Form:

```hilde
module body Example is
    function main(): ExitCode is
        let total: Int32 := 1 + (2 * 3);
        printLn(total);
        return ExitSuccess();
    end;
end module body.
```

### H0010

Meldung:

```text
Parse Error
An index stands after a name, not after a call. Bind the result of the call to a name first, `let text: Span[Nat8, R] := asSpan(&s);`, and index the name, `text[i]`.
```

Ein Index steht hinter einem Namen.  Das Ergebnis eines Aufrufs wird
zuerst an einen Namen gebunden, und der Name wird indiziert.

Dieses Modul scheitert mit H0010:

```hilde fails H0010
module body Example is
    function digits(): Span[Nat8, Static] is
        return "0123";
    end;

    function main(): ExitCode is
        let first: Nat8 := digits()[0];
        printLn(first);
        return ExitSuccess();
    end;
end module body.
```

Die richtige Form:

```hilde
module body Example is
    function digits(): Span[Nat8, Static] is
        return "0123";
    end;

    function main(): ExitCode is
        let text: Span[Nat8, Static] := digits();
        let first: Nat8 := text[0];
        printLn(first);
        return ExitSuccess();
    end;
end module body.
```

### H0011

Meldung:

```text
Parse Error
Only a variable can be borrowed, not the literal `21`. Bind the value to a name first, `let key: Nat64 := 21;`, and borrow the name, `&key`.
```

Ausleihen lässt sich nur eine Variable.  Ein Literal wird zuerst an einen
Namen gebunden, und der Name wird ausgeliehen.

Dieses Modul scheitert mit H0011:

```hilde fails H0011
module body Example is
    generic [R: Region]
    function twice(value: &[Int32, R]): Int32 is
        return !value * 2;
    end;

    function main(): ExitCode is
        printLn(twice(&21));
        return ExitSuccess();
    end;
end module body.
```

Die richtige Form:

```hilde
module body Example is
    generic [R: Region]
    function twice(value: &[Int32, R]): Int32 is
        return !value * 2;
    end;

    function main(): ExitCode is
        let answer: Int32 := 21;
        printLn(twice(&answer));
        return ExitSuccess();
    end;
end module body.
```

### H0012

Meldung:

```text
Parse Error
A field stands after a name, not after a call. Bind the result of the call to a name first, `let node: Node := nodeAt();`, and take the field of the name, `node.kind`.
```

Ein Feld steht hinter einem Namen.  Das Ergebnis eines Aufrufs wird
zuerst an einen Namen gebunden, und dann wird das Feld des Namens gelesen.

Dieses Modul scheitert mit H0012:

```hilde fails H0012
module body Example is
    record Point: Free is
        x: Int32;
        y: Int32;
    end;

    function origin(): Point is
        return Point(x => 3, y => 4);
    end;

    function main(): ExitCode is
        let x: Int32 := origin().x;
        printLn(x);
        return ExitSuccess();
    end;
end module body.
```

Die richtige Form:

```hilde
module body Example is
    record Point: Free is
        x: Int32;
        y: Int32;
    end;

    function origin(): Point is
        return Point(x => 3, y => 4);
    end;

    function main(): ExitCode is
        let point: Point := origin();
        let x: Int32 := point.x;
        printLn(x);
        return ExitSuccess();
    end;
end module body.
```

### H6018

Meldung:

```text
Generic Error
Bad whitespace escape sequence
```

In einem String-Literal verbindet ein Backslash mit folgendem Leerraum zwei
Teile des Strings, und der Leerraum muss mit einem zweiten Backslash enden.
Hier folgt auf den Leerraum etwas anderes.

Dieses Modul scheitert mit H6018:

```hilde fails H6018
module body Example is
    function main(): ExitCode is
        printLn("one \  two");
        return ExitSuccess();
    end;
end module body.
```

Die richtige Form:

```hilde
module body Example is
    function main(): ExitCode is
        printLn("one \  \two");
        return ExitSuccess();
    end;
end module body.
```

### H6058

Meldung:

```text
Parse Error
A `\u{...}` escape takes one to six hexadecimal digits of a code point up to `10FFFF`, and no surrogate (`D800` to `DFFF`).
```

Das Escape \u{X} schreibt den Codepunkt X als UTF-8.  X sind eine bis
sechs Hexadezimalziffern, höchstens 10FFFF, und kein Surrogat, D800 bis
DFFF.

Dieses Modul scheitert mit H6058:

```hilde fails H6058
module body Example is
    function main(): ExitCode is
        printLn("\u{110000}");
        return ExitSuccess();
    end;
end module body.
```

Die richtige Form:

```hilde
module body Example is
    function main(): ExitCode is
        printLn("caf\u{e9}");
        return ExitSuccess();
    end;
end module body.
```

## 2. Typen

### H2020

Meldung:

```text
Declaration Error
Cannot create an instance for `Point` because it is not a typeclass.
```

Eine Instanz nennt etwas, das keine Typklasse ist.

Dieses Modul scheitert mit H2020:

```hilde fails H2020
module body Example is
    record Point: Free is
        x: Int32;
    end;

    instance Point(Int32) is
    end;

    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Die richtige Form:

```hilde
module body Example is
    typeclass Describe(T: Free) is
        method describe(value: T): Int32;
    end;

    instance Describe(Int32) is
        method describe(value: Int32): Int32 is
            return value;
        end;
    end;

    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

### H2021

Meldung:

```text
Declaration Error
The typeclass `Describe` has no method named `explain`
```

Eine Instanz definiert eine Methode, die ihre Typklasse nicht deklariert.

Dieses Modul scheitert mit H2021:

```hilde fails H2021
module body Example is
    typeclass Describe(T: Free) is
        method describe(value: T): Int32;
    end;

    instance Describe(Int32) is
        method describe(value: Int32): Int32 is
            return value;
        end;

        method explain(value: Int32): Int32 is
            return value;
        end;
    end;

    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Die richtige Form:

```hilde
module body Example is
    typeclass Describe(T: Free) is
        method describe(value: T): Int32;
    end;

    instance Describe(Int32) is
        method describe(value: Int32): Int32 is
            return value;
        end;
    end;

    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

### H2022

Meldung:

```text
Declaration Error
The instance `Describe(Int32)` does not implement every method of the typeclass.

Missing: `explain`.

An instance has to implement every method the typeclass declares, even one whose body does nothing: a method that is simply absent cannot be reported at the call site, only much later and as an internal error.
```

Eine Instanz lässt eine Methode ihrer Typklasse aus. Die Meldung nennt die
fehlenden Methoden.

Dieses Modul scheitert mit H2022:

```hilde fails H2022
module body Example is
    typeclass Describe(T: Free) is
        method describe(value: T): Int32;
        method explain(value: T): Int32;
    end;

    instance Describe(Int32) is
        method describe(value: Int32): Int32 is
            return value;
        end;
    end;

    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Die richtige Form:

```hilde
module body Example is
    typeclass Describe(T: Free) is
        method describe(value: T): Int32;
        method explain(value: T): Int32;
    end;

    instance Describe(Int32) is
        method describe(value: Int32): Int32 is
            return value;
        end;

        method explain(value: Int32): Int32 is
            return value;
        end;
    end;

    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

### H2023

Meldung:

```text
Declaration Error
The parameter for the typeclass `Measure` cannot be declared to be in the `Region` universe, because regions are distinct from types.

Consider using one of `Type`, `Linear`, or `Free` instead.
```

Der Parameter einer Typklasse ist im Universum Region deklariert. Eine
Region ist kein Typ, eine Typklasse kann sich also nicht auf Regionen
beziehen.

Dieses Modul scheitert mit H2023:

```hilde fails H2023
module body Example is
    typeclass Measure(R: Region) is
        method measure(value: Int32): Int32;
    end;

    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Die richtige Form:

```hilde
module body Example is
    typeclass Measure(T: Free) is
        method measure(value: T): Int32;
    end;

    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

### H2024

Meldung:

```text
Declaration Error
The record `Point` was declared to belong to the `Region` universe, but regions are distinct from types.

Consider using one of `Type`, `Linear`, or `Free` instead.
```

Ein Record oder eine Union ist im Universum Region deklariert. Nur
Typparameter können für Regionen stehen; ein deklarierter Typ gehört zu
Free, Linear oder Type.

Dieses Modul scheitert mit H2024:

```hilde fails H2024
module body Example is
    record Point: Region is
        x: Int32;
    end;

    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Die richtige Form:

```hilde
module body Example is
    record Point: Free is
        x: Int32;
    end;

    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

### H2025

Meldung:

```text
Declaration Error
Cannot find typeclass with the name `Describe`
```

Eine Instanz nennt eine Typklasse, die im Modul nicht deklariert und nicht
importiert ist.

Dieses Modul scheitert mit H2025:

```hilde fails H2025
module body Example is
    instance Describe(Int32) is
        method describe(value: Int32): Int32 is
            return value;
        end;
    end;

    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Die richtige Form:

```hilde
module body Example is
    typeclass Describe(T: Free) is
        method describe(value: T): Int32;
    end;

    instance Describe(Int32) is
        method describe(value: Int32): Int32 is
            return value;
        end;
    end;

    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

### H2026

Meldung:

```text
Declaration Error
The type parameter `T` does not appear anywhere in the signature of the function.
```

Ein Typparameter einer generischen Funktion kommt weder in ihren Parametern
noch im Rückgabetyp vor; kein Aufruf könnte also festlegen, wofür er steht.

Dieses Modul scheitert mit H2026:

```hilde fails H2026
module body Example is
    generic [T: Free]
    function answer(): Int32 is
        return 42;
    end;

    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Die richtige Form:

```hilde
module body Example is
    generic [T: Free]
    function answer(value: T): Int32 is
        return 42;
    end;

    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

### H2031

Meldung:

```text
Declaration Error
The function `show` does not end in a return statement.
```

Eine Funktion oder Methode endet ohne return. Auch eine Funktion, die nichts
zurückgibt, endet mit return nil. Jeder Pfad zählt: ein Pfad endet mit
return, raise, dem Aufruf einer Funktion, die Never zurückgibt, wie abort,
oder einem while, dessen Bedingung true ist. Ein if ohne else, das nur im
then-Zweig zurückkehrt, lässt einen Pfad offen.

Dieses Modul scheitert mit H2031:

```hilde fails H2031
module body Example is
    function show(n: Int32): Unit is
        printLn(n);
    end;

    function main(): ExitCode is
        show(1);
        return ExitSuccess();
    end;
end module body.
```

Die richtige Form:

```hilde
module body Example is
    function show(n: Int32): Unit is
        printLn(n);
        return nil;
    end;

    function main(): ExitCode is
        show(1);
        return ExitSuccess();
    end;
end module body.
```

### H2032

Meldung:

```text
Declaration Error
Generic instances can only use each type parameter once in the argument.
```

Das Argument einer generischen Instanz verwendet denselben Typparameter
zweimal. Jeder Typparameter darf darin nur einmal vorkommen.

Dieses Modul scheitert mit H2032:

```hilde fails H2032
module body Example is
    record Pair[A: Free, B: Free]: Free is
        left: A;
        right: B;
    end;

    typeclass Describe(T: Free) is
        method describe(value: T): Int32;
    end;

    generic [U: Free]
    instance Describe(Pair[U, U]) is
        method describe(value: Pair[U, U]): Int32 is
            return 2;
        end;
    end;

    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Die richtige Form:

```hilde
module body Example is
    record Pair[A: Free, B: Free]: Free is
        left: A;
        right: B;
    end;

    typeclass Describe(T: Free) is
        method describe(value: T): Int32;
    end;

    generic [U: Free, V: Free]
    instance Describe(Pair[U, V]) is
        method describe(value: Pair[U, V]): Int32 is
            return 2;
        end;
    end;

    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

### H2033

Meldung:

```text
Declaration Error
The number of type parameters in the instance declaration must be the same as the number of type variables applied to the argument.
```

Eine generische Instanz deklariert mehr Typparameter, als ihr Argument
verwendet. Typparameter und die im Argument verwendeten Variablen müssen
gleich viele sein.

Dieses Modul scheitert mit H2033:

```hilde fails H2033
module body Example is
    record Box[A: Free]: Free is
        content: A;
    end;

    typeclass Describe(T: Free) is
        method describe(value: T): Int32;
    end;

    generic [U: Free, V: Free]
    instance Describe(Box[U]) is
        method describe(value: Box[U]): Int32 is
            return 1;
        end;
    end;

    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Die richtige Form:

```hilde
module body Example is
    record Box[A: Free]: Free is
        content: A;
    end;

    typeclass Describe(T: Free) is
        method describe(value: T): Int32;
    end;

    generic [U: Free]
    instance Describe(Box[U]) is
        method describe(value: Box[U]): Int32 is
            return 1;
        end;
    end;

    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

### H2034

Meldung:

```text
Declaration Error
Typeclass arguments cannot be lone type parameters.
```

Das Argument einer Instanz ist ein bloßer Typparameter. Eine Instanz gilt
einem benannten Typ, dessen Argumente Typparameter sein dürfen.

Dieses Modul scheitert mit H2034:

```hilde fails H2034
module body Example is
    typeclass Describe(T: Free) is
        method describe(value: T): Int32;
    end;

    generic [U: Free]
    instance Describe(U) is
        method describe(value: U): Int32 is
            return 1;
        end;
    end;

    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Die richtige Form:

```hilde
module body Example is
    record Box[A: Free]: Free is
        content: A;
    end;

    typeclass Describe(T: Free) is
        method describe(value: T): Int32;
    end;

    generic [U: Free]
    instance Describe(Box[U]) is
        method describe(value: Box[U]): Int32 is
            return 1;
        end;
    end;

    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

### H2035

Meldung:

```text
Declaration Error
The type `Int32` is not a type parameter, but generic instances must use either all type parameters or none of them in the argument.

Consider adding another generic parameter with universe `Free`
```

Das Argument einer generischen Instanz mischt Typparameter mit konkreten
Typen. Es verwendet entweder nur Typparameter oder gar keine.

Dieses Modul scheitert mit H2035:

```hilde fails H2035
module body Example is
    record Pair[A: Free, B: Free]: Free is
        left: A;
        right: B;
    end;

    typeclass Describe(T: Free) is
        method describe(value: T): Int32;
    end;

    generic [U: Free]
    instance Describe(Pair[U, Int32]) is
        method describe(value: Pair[U, Int32]): Int32 is
            return 2;
        end;
    end;

    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Die richtige Form:

```hilde
module body Example is
    record Pair[A: Free, B: Free]: Free is
        left: A;
        right: B;
    end;

    typeclass Describe(T: Free) is
        method describe(value: T): Int32;
    end;

    generic [U: Free, V: Free]
    instance Describe(Pair[U, V]) is
        method describe(value: Pair[U, V]): Int32 is
            return 2;
        end;
    end;

    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

### H2037

Meldung:

```text
Declaration Error
The type parameters in a generic instance declaration cannot have the same name as the type parameter in the corresponding typeclass. The colliding name is `T`.

Give the type parameter of the instance another name.
```

Ein Typparameter einer generischen Instanz heißt wie der Parameter ihrer
Typklasse. Die beiden müssen verschieden heißen.

Dieses Modul scheitert mit H2037:

```hilde fails H2037
module body Example is
    record Box[A: Free]: Free is
        content: A;
    end;

    typeclass Describe(T: Free) is
        method describe(value: T): Int32;
    end;

    generic [T: Free]
    instance Describe(Box[T]) is
        method describe(value: Box[T]): Int32 is
            return 1;
        end;
    end;

    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Die richtige Form:

```hilde
module body Example is
    record Box[A: Free]: Free is
        content: A;
    end;

    typeclass Describe(T: Free) is
        method describe(value: T): Int32;
    end;

    generic [U: Free]
    instance Describe(Box[U]) is
        method describe(value: Box[U]): Int32 is
            return 1;
        end;
    end;

    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

### H3003

Meldung:

```text
Type Error
The type parameter `T` cannot be bound to both `Int32` and `Bool`
```

Ein Typparameter einer generischen Funktion müsste im selben Aufruf für zwei
verschiedene Typen stehen.

Dieses Modul scheitert mit H3003:

```hilde fails H3003
module body Example is
    generic [T: Free]
    function first(a: T, b: T): T is
        return a;
    end;

    function main(): ExitCode is
        let n: Int32 := 1;
        let flag: Bool := true;
        printLn(first(n, flag));
        return ExitSuccess();
    end;
end module body.
```

Die richtige Form:

```hilde
module body Example is
    generic [T: Free]
    function first(a: T, b: T): T is
        return a;
    end;

    function main(): ExitCode is
        let n: Int32 := 1;
        let m: Int32 := 2;
        printLn(first(n, m));
        return ExitSuccess();
    end;
end module body.
```

### H3004

Meldung:

```text
Type Error
The type parameter `T` must be `Free` but `Ticket` is `Linear`
```

Ein Typargument liegt in einem Universum, das sein Typparameter nicht
zulässt, etwa ein Linear-Typ, wo der Parameter Free verlangt.

Dieses Modul scheitert mit H3004:

```hilde fails H3004
module body Example is
    record Ticket: Linear is
        number: Int32;
    end;

    generic [T: Free]
    function keep(value: T): T is
        return value;
    end;

    function main(): ExitCode is
        let ticket: Ticket := keep(Ticket(number => 1));
        let { number: Int32 } := ticket;
        printLn(number);
        return ExitSuccess();
    end;
end module body.
```

Die richtige Form:

```hilde
module body Example is
    record Ticket: Linear is
        number: Int32;
    end;

    generic [T: Type]
    function keep(value: T): T is
        return value;
    end;

    function main(): ExitCode is
        let ticket: Ticket := keep(Ticket(number => 1));
        let { number: Int32 } := ticket;
        printLn(number);
        return ExitSuccess();
    end;
end module body.
```

### H3007

Meldung:

```text
Type Error
Cannot define an instance with argument `Ticket` because it should belong to the `Free` universe, but it is actually in the `Linear` universe.
```

Eine Instanz gilt einem Typ, dessen Universum die Typklasse nicht zulässt,
etwa einem Linear-Typ für eine Klasse über Free-Typen.

Dieses Modul scheitert mit H3007:

```hilde fails H3007
module body Example is
    record Ticket: Linear is
        number: Int32;
    end;

    typeclass Describe(T: Free) is
        method describe(value: T): Int32;
    end;

    instance Describe(Ticket) is
        method describe(value: Ticket): Int32 is
            let { number: Int32 } := value;
            return number;
        end;
    end;

    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Die richtige Form:

```hilde
module body Example is
    record Ticket: Linear is
        number: Int32;
    end;

    typeclass Describe(T: Type) is
        method describe(value: T): Int32;
    end;

    instance Describe(Ticket) is
        method describe(value: Ticket): Int32 is
            let { number: Int32 } := value;
            return number;
        end;
    end;

    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

### H3008

Meldung:

```text
Type Error
Both operands to an arithmetic expression must be compatible types. The LHS has type `Int32` but the RHS has type `Int64`.
```

Die beiden Operanden eines Rechenoperators haben verschiedene Typen. Hilde
wandelt nichts stillschweigend um; ein Operand wird vorher umgewandelt.

Dieses Modul scheitert mit H3008:

```hilde fails H3008
module body Example is
    function main(): ExitCode is
        let small: Int32 := 1;
        let large: Int64 := 2;
        printLn(small + large);
        return ExitSuccess();
    end;
end module body.
```

Die richtige Form:

```hilde
module body Example is
    function main(): ExitCode is
        let small: Int64 := 1;
        let large: Int64 := 2;
        printLn(small + large);
        return ExitSuccess();
    end;
end module body.
```

### H3009

Meldung:

```text
Type Error
Both operands of an arithmetic operator must be numeric types, but `Bool` is not.
```

Ein Operand eines Rechenoperators ist keine Zahl.

Dieses Modul scheitert mit H3009:

```hilde fails H3009
module body Example is
    function main(): ExitCode is
        let flag: Bool := true;
        printLn(flag + flag);
        return ExitSuccess();
    end;
end module body.
```

Die richtige Form:

```hilde
module body Example is
    function main(): ExitCode is
        let flag: Bool := true;
        printLn(flag and flag);
        return ExitSuccess();
    end;
end module body.
```

### H3010

Meldung:

```text
Type Error
Negation is not defined for the unsigned type `Nat8`. Its values have no opposite inside the type.
```

Ein Wert eines vorzeichenlosen Typs wird negiert. Nat8 bis Nat64, Index und
ByteSize haben keine negativen Werte.

Dieses Modul scheitert mit H3010:

```hilde fails H3010
module body Example is
    function main(): ExitCode is
        let n: Nat8 := 5;
        printLn(-n);
        return ExitSuccess();
    end;
end module body.
```

Die richtige Form:

```hilde
module body Example is
    function main(): ExitCode is
        let n: Int8 := 5;
        printLn(-n);
        return ExitSuccess();
    end;
end module body.
```

### H3012

Meldung:

```text
Type Error
Negation is not defined for the type `Money`: it does not implement the typeclass `TrappingNegation`. Give it an instance if it should have a negation.
```

Ein Wert wird negiert, dessen Typ keine Instanz der Typklasse
TrappingNegation hat. Ein eigener Typ kann eine solche Instanz bekommen.

Dieses Modul scheitert mit H3012:

```hilde fails H3012
module body Example is
    record Money: Free is
        cents: Int64;
    end;

    function main(): ExitCode is
        let debt: Money := Money(cents => 500);
        let credit: Money := -debt;
        printLn(credit.cents);
        return ExitSuccess();
    end;
end module body.
```

Die richtige Form:

```hilde
module body Example is
    record Money: Free is
        cents: Int64;
    end;

    instance TrappingNegation(Money) is
        method trappingNegate(value: Money): Money is
            return Money(cents => -(value.cents));
        end;
    end;

    function main(): ExitCode is
        let debt: Money := Money(cents => 500);
        let credit: Money := -debt;
        printLn(credit.cents);
        return ExitSuccess();
    end;
end module body.
```

### H3020

Meldung:

```text
Type Error
The type `Int32` is neither a function, method or function pointer, and cannot be called.
```

Etwas, das weder eine Funktion noch eine Methode noch ein Funktionszeiger
ist, wird aufgerufen.

Dieses Modul scheitert mit H3020:

```hilde fails H3020
module body Example is
    function main(): ExitCode is
        let n: Int32 := 5;
        printLn(n(1));
        return ExitSuccess();
    end;
end module body.
```

Die richtige Form:

```hilde
module body Example is
    function twice(n: Int32): Int32 is
        return n * 2;
    end;

    function main(): ExitCode is
        printLn(twice(5));
        return ExitSuccess();
    end;
end module body.
```

### H3021

Meldung:

```text
Type Error
The callable `f` expects 2 arguments but 1 was given.
```

Ein Funktionszeiger wird mit mehr oder weniger Argumenten aufgerufen, als
sein Typ Parameter hat. Ein direkter Aufruf einer Funktion mit falscher
Anzahl wird als H6026 gemeldet.

Dieses Modul scheitert mit H3021:

```hilde fails H3021
module body Example is
    function add(a: Int32, b: Int32): Int32 is
        return a + b;
    end;

    function main(): ExitCode is
        let f: Fn[Int32, Int32, Int32] := add;
        let sum: Int32 := f(1);
        printLn(sum);
        return ExitSuccess();
    end;
end module body.
```

Die richtige Form:

```hilde
module body Example is
    function add(a: Int32, b: Int32): Int32 is
        return a + b;
    end;

    function main(): ExitCode is
        let f: Fn[Int32, Int32, Int32] := add;
        let sum: Int32 := f(1, 2);
        printLn(sum);
        return ExitSuccess();
    end;
end module body.
```

### H3022

Meldung:

```text
Type Error
Non-exhaustive case statement.
```

Ein case, das nach Namen bindet, lässt einen Fall der Union aus. Jeder Fall
der Union braucht sein eigenes when.

Dieses Modul scheitert mit H3022:

```hilde fails H3022
module body Example is
    union Shape: Free is
        case Dot;
        case Circle is
            radius: Int32;
    end;

    function main(): ExitCode is
        let s: Shape := Dot();
        case s of
            when Dot do
                printLn(0);
        end case;
        return ExitSuccess();
    end;
end module body.
```

Die richtige Form:

```hilde
module body Example is
    union Shape: Free is
        case Dot;
        case Circle is
            radius: Int32;
    end;

    function main(): ExitCode is
        let s: Shape := Dot();
        case s of
            when Dot do
                printLn(0);
            when Circle(radius: Int32) do
                printLn(radius);
        end case;
        return ExitSuccess();
    end;
end module body.
```

### H3023

Meldung:

```text
Type Error
Union must be public or from the same module to be used in a case statement.
```

Ein case schaut in eine Union, die ein anderes Modul nur als opaken Typ
exportiert. Nur eine öffentliche oder im selben Modul deklarierte Union
lässt sich mit case zerlegen.

Dieses Modul scheitert mit H3023:

```hilde fails H3023
import Library (Shape, make);

module body Example is
    function main(): ExitCode is
        case make() of
            when Dot do
                printLn(0);
            when Circle(radius: Int32) do
                printLn(radius);
        end case;
        return ExitSuccess();
    end;
end module body.
```

Daneben `Library.hih`:

```hilde file Library.hih
module Library is
    type Shape: Free;

    function make(): Shape;
end module.
```

Daneben `Library.hiq`:

```hilde file Library.hiq
module body Library is
    union Shape: Free is
        case Dot;
        case Circle is
            radius: Int32;
    end;

    function make(): Shape is
        return Circle(radius => 2);
    end;
end module body.
```

Die richtige Form:

```hilde
import Library (Shape, make);

module body Example is
    function main(): ExitCode is
        case make() of
            when Dot do
                printLn(0);
            when Circle(radius: Int32) do
                printLn(radius);
        end case;
        return ExitSuccess();
    end;
end module body.
```

Daneben `Library.hih`:

```hilde file Library.hih
module Library is
    union Shape: Free is
        case Dot;
        case Circle is
            radius: Int32;
    end;

    function make(): Shape;
end module.
```

Daneben `Library.hiq`:

```hilde file Library.hiq
module body Library is
    function make(): Shape is
        return Circle(radius => 2);
    end;
end module body.
```

### H3024

Meldung:

```text
Type Error
The case expression has type `Point` which is not a union type.
```

Ein case, das nach Namen bindet, bekommt einen Wert eines benannten Typs,
der keine Union ist, etwa einen Record.

Dieses Modul scheitert mit H3024:

```hilde fails H3024
module body Example is
    record Point: Free is
        x: Int32;
    end;

    function main(): ExitCode is
        let p: Point := Point(x => 1);
        case p of
            when Point(x: Int32) do
                printLn(x);
        end case;
        return ExitSuccess();
    end;
end module body.
```

Die richtige Form:

```hilde
module body Example is
    record Point: Free is
        x: Int32;
    end;

    function main(): ExitCode is
        let p: Point := Point(x => 1);
        let { x: Int32 } := p;
        printLn(x);
        return ExitSuccess();
    end;
end module body.
```

### H3025

Meldung:

```text
Type Error
The set of slots (`diameter`) in the case statement doesn't match the set of slots in the union definition (`radius`).
```

Ein when, das nach Namen bindet, nennt Slots, die der Fall der Union nicht
hat, oder lässt welche aus.

Dieses Modul scheitert mit H3025:

```hilde fails H3025
module body Example is
    union Shape: Free is
        case Dot;
        case Circle is
            radius: Int32;
    end;

    function main(): ExitCode is
        let s: Shape := Circle(radius => 2);
        case s of
            when Dot do
                printLn(0);
            when Circle(diameter: Int32) do
                printLn(diameter);
        end case;
        return ExitSuccess();
    end;
end module body.
```

Die richtige Form:

```hilde
module body Example is
    union Shape: Free is
        case Dot;
        case Circle is
            radius: Int32;
    end;

    function main(): ExitCode is
        let s: Shape := Circle(radius => 2);
        case s of
            when Dot do
                printLn(0);
            when Circle(radius: Int32) do
                printLn(radius);
        end case;
        return ExitSuccess();
    end;
end module body.
```

### H3027

Meldung:

```text
Type Error
Cannot cast to `Int32` from `Bool`
```

Ein Wert wird in einen Typ umgewandelt, der er nicht werden kann. Eine
Typangabe e : T gibt nur einem Literal seinen Typ, macht aus einer Schreib-
eine Lese-Referenz oder nennt einem generischen Aufruf seinen Rückgabetyp.

Dieses Modul scheitert mit H3027:

```hilde fails H3027
module body Example is
    function main(): ExitCode is
        let flag: Bool := true;
        let n: Int32 := flag : Int32;
        printLn(n);
        return ExitSuccess();
    end;
end module body.
```

Die richtige Form:

```hilde
module body Example is
    function main(): ExitCode is
        let n: Int32 := 1 : Int32;
        printLn(n);
        return ExitSuccess();
    end;
end module body.
```

### H3029

Meldung:

```text
Type Error
The condition in `if`-statements should be a boolean type, but is `Int32`
```

Die Bedingung eines if, eines while oder eines if-Ausdrucks ist kein Bool.

Dieses Modul scheitert mit H3029:

```hilde fails H3029
module body Example is
    function main(): ExitCode is
        let n: Int32 := 1;
        if n then
            printLn(n);
        end if;
        return ExitSuccess();
    end;
end module body.
```

Die richtige Form:

```hilde
module body Example is
    function main(): ExitCode is
        let n: Int32 := 1;
        if n /= 0 then
            printLn(n);
        end if;
        return ExitSuccess();
    end;
end module body.
```

### H3030

Meldung:

```text
Type Error
Arguments to record constructor must be named.
```

Ein Record oder ein Fall einer Union wird mit Argumenten nach Position
gebaut. Sein Konstruktor nimmt nur benannte Argumente.

Dieses Modul scheitert mit H3030:

```hilde fails H3030
module body Example is
    record Point: Free is
        x: Int32;
        y: Int32;
    end;

    function main(): ExitCode is
        let p: Point := Point(1, 2);
        printLn(p.x);
        return ExitSuccess();
    end;
end module body.
```

Die richtige Form:

```hilde
module body Example is
    record Point: Free is
        x: Int32;
        y: Int32;
    end;

    function main(): ExitCode is
        let p: Point := Point(x => 1, y => 2);
        printLn(p.x);
        return ExitSuccess();
    end;
end module body.
```

### H3031

Meldung:

```text
Type Error
Arguments to record constructor have the wrong names.
```

Ein Konstruktor wird mit Namen aufgerufen, die nicht die Slots des Records
oder des Falls sind.

Dieses Modul scheitert mit H3031:

```hilde fails H3031
module body Example is
    record Point: Free is
        x: Int32;
        y: Int32;
    end;

    function main(): ExitCode is
        let p: Point := Point(x => 1, z => 2);
        printLn(p.x);
        return ExitSuccess();
    end;
end module body.
```

Die richtige Form:

```hilde
module body Example is
    record Point: Free is
        x: Int32;
        y: Int32;
    end;

    function main(): ExitCode is
        let p: Point := Point(x => 1, y => 2);
        printLn(p.x);
        return ExitSuccess();
    end;
end module body.
```

### H3033

Meldung:

```text
Type Error
The type `Int32` cannot be destructured because it is not a record.
```

Ein let mit geschweiften Klammern zerlegt einen Wert eines eingebauten Typs,
der keine Slots hat. Eine Union wird als H3053 gemeldet.

Dieses Modul scheitert mit H3033:

```hilde fails H3033
module body Example is
    function main(): ExitCode is
        let n: Int32 := 5;
        let { value: Int32 } := n;
        printLn(value);
        return ExitSuccess();
    end;
end module body.
```

Die richtige Form:

```hilde
module body Example is
    record Box: Free is
        value: Int32;
    end;

    function main(): ExitCode is
        let n: Box := Box(value => 5);
        let { value: Int32 } := n;
        printLn(value);
        return ExitSuccess();
    end;
end module body.
```

### H3034

Meldung:

```text
Type Error
The type `Point` is not a public record and so cannot be destructured.
```

Ein let mit geschweiften Klammern zerlegt einen Record, den ein anderes
Modul nur als opaken Typ exportiert. Seine Slots sind außerhalb seines
Moduls nicht sichtbar.

Dieses Modul scheitert mit H3034:

```hilde fails H3034
import Library (Point, make);

module body Example is
    function main(): ExitCode is
        let { x: Int32 } := make();
        printLn(x);
        return ExitSuccess();
    end;
end module body.
```

Daneben `Library.hih`:

```hilde file Library.hih
module Library is
    type Point: Free;

    function make(): Point;
end module.
```

Daneben `Library.hiq`:

```hilde file Library.hiq
module body Library is
    record Point: Free is
        x: Int32;
    end;

    function make(): Point is
        return Point(x => 1);
    end;
end module body.
```

Die richtige Form:

```hilde
import Library (Point, make);

module body Example is
    function main(): ExitCode is
        let { x: Int32 } := make();
        printLn(x);
        return ExitSuccess();
    end;
end module body.
```

Daneben `Library.hih`:

```hilde file Library.hih
module Library is
    record Point: Free is
        x: Int32;
    end;

    function make(): Point;
end module.
```

Daneben `Library.hiq`:

```hilde file Library.hiq
module body Library is
    function make(): Point is
        return Point(x => 1);
    end;
end module body.
```

### H3035

Meldung:

```text
Type Error
The set of slots mentioned differs from the set of slots in `Point`
```

Ein let mit geschweiften Klammern nennt andere Slots, als der Record hat.
Jeder Slot wird genannt, und kein anderer.

Dieses Modul scheitert mit H3035:

```hilde fails H3035
module body Example is
    record Point: Free is
        x: Int32;
        y: Int32;
    end;

    function main(): ExitCode is
        let p: Point := Point(x => 1, y => 2);
        let { x: Int32 } := p;
        printLn(x);
        return ExitSuccess();
    end;
end module body.
```

Die richtige Form:

```hilde
module body Example is
    record Point: Free is
        x: Int32;
        y: Int32;
    end;

    function main(): ExitCode is
        let p: Point := Point(x => 1, y => 2);
        let { x: Int32, y: Int32 } := p;
        printLn(x + y);
        return ExitSuccess();
    end;
end module body.
```

### H3037

Meldung:

```text
Type Error
The value of this expression has type `Option[Int32]`, which carries a failure the caller is meant to look at, so it may not be thrown away. Handle it with a case statement, hand it to your own caller with the ? operator, or, if the failure really is to be ignored here, say so in the program with ignore(...).
```

Eine Ausdrucksanweisung wirft ein Option oder ein Either weg. Ein solcher
Wert trägt einen Fehlschlag, den jemand ansehen muss: mit case behandeln,
mit ? weiterreichen oder mit ignore bewusst verwerfen.

Dieses Modul scheitert mit H3037:

```hilde fails H3037
module body Example is
    function half(n: Int32): Option[Int32] is
        let r: Option[Int32] := Some(value => n / 2);
        return r;
    end;

    function main(): ExitCode is
        half(4);
        return ExitSuccess();
    end;
end module body.
```

Die richtige Form:

```hilde
module body Example is
    function half(n: Int32): Option[Int32] is
        let r: Option[Int32] := Some(value => n / 2);
        return r;
    end;

    function main(): ExitCode is
        ignore(half(4));
        return ExitSuccess();
    end;
end module body.
```

### H3038

Meldung:

```text
Type Error
The `?` operator hands a failure back to the caller, so it needs a value that can carry one: an `Option` or an `Either`. This expression has type `Int32`.
```

Der Operator ? steht an einem Wert, der weder Option noch Either ist; es
gibt also keinen Fehlschlag weiterzureichen.

Dieses Modul scheitert mit H3038:

```hilde fails H3038
module body Example is
    function twice(n: Int32): Option[Int32] is
        let m: Int32 := n?;
        let r: Option[Int32] := Some(value => m * 2);
        return r;
    end;

    function main(): ExitCode is
        ignore(twice(2));
        return ExitSuccess();
    end;
end module body.
```

Die richtige Form:

```hilde
module body Example is
    function twice(n: Option[Int32]): Option[Int32] is
        let m: Int32 := n?;
        let r: Option[Int32] := Some(value => m * 2);
        return r;
    end;

    function main(): ExitCode is
        let two: Option[Int32] := Some(value => 2);
        ignore(twice(two));
        return ExitSuccess();
    end;
end module body.
```

### H3039

Meldung:

```text
Type Error
The `?` operator returns the failure out of the enclosing function, so that function has to be able to carry it. The operand has type `Option[Int32]` but the function returns `Int32`. For an Option the function must return an Option; for an Either it must return an Either whose left type is the same.
```

Der Operator ? steht in einer Funktion, die den Fehlschlag nicht
weiterreichen kann: Für ein Option muss sie ein Option zurückgeben, für ein
Either ein Either mit demselben linken Typ.

Dieses Modul scheitert mit H3039:

```hilde fails H3039
module body Example is
    function half(n: Int32): Option[Int32] is
        let r: Option[Int32] := Some(value => n / 2);
        return r;
    end;

    function quarter(n: Int32): Int32 is
        let h: Int32 := half(n)?;
        return h / 2;
    end;

    function main(): ExitCode is
        printLn(quarter(8));
        return ExitSuccess();
    end;
end module body.
```

Die richtige Form:

```hilde
module body Example is
    function half(n: Int32): Option[Int32] is
        let r: Option[Int32] := Some(value => n / 2);
        return r;
    end;

    function quarter(n: Int32): Option[Int32] is
        let h: Int32 := half(n)?;
        let r: Option[Int32] := Some(value => h / 2);
        return r;
    end;

    function main(): ExitCode is
        ignore(quarter(8));
        return ExitSuccess();
    end;
end module body.
```

### H3040

Meldung:

```text
Type Error
The `?` operator may only stand as the whole right-hand side of a `let` binding or as a whole statement. It is an early return out of the enclosing function, and it is written where that return is visible on its own line rather than buried inside a larger expression.
```

Der Operator ? steht innerhalb eines größeren Ausdrucks. Er darf nur die
ganze rechte Seite eines let oder eine ganze Anweisung sein, damit die
vorzeitige Rückkehr in einer eigenen Zeile sichtbar ist.

Dieses Modul scheitert mit H3040:

```hilde fails H3040
module body Example is
    function half(n: Int32): Option[Int32] is
        let r: Option[Int32] := Some(value => n / 2);
        return r;
    end;

    function quarter(n: Int32): Option[Int32] is
        let q: Int32 := half(n)? / 2;
        let r: Option[Int32] := Some(value => q);
        return r;
    end;

    function main(): ExitCode is
        ignore(quarter(8));
        return ExitSuccess();
    end;
end module body.
```

Die richtige Form:

```hilde
module body Example is
    function half(n: Int32): Option[Int32] is
        let r: Option[Int32] := Some(value => n / 2);
        return r;
    end;

    function quarter(n: Int32): Option[Int32] is
        let h: Int32 := half(n)?;
        let r: Option[Int32] := Some(value => h / 2);
        return r;
    end;

    function main(): ExitCode is
        ignore(quarter(8));
        return ExitSuccess();
    end;
end module body.
```

### H3041

Meldung:

```text
Type Error
The expression is not a valid constant expression.
```

Der Wert einer Konstanten ist kein konstanter Ausdruck, etwa ein
Funktionsaufruf.

Dieses Modul scheitert mit H3041:

```hilde fails H3041
module body Example is
    function five(): Int32 is
        return 5;
    end;

    constant limit: Int32 := five();

    function main(): ExitCode is
        printLn(limit);
        return ExitSuccess();
    end;
end module body.
```

Die richtige Form:

```hilde
module body Example is
    constant limit: Int32 := 5;

    function main(): ExitCode is
        printLn(limit);
        return ExitSuccess();
    end;
end module body.
```

### H3043

Meldung:

```text
Type Error
You can't call a function pointer with a named argument list, because function pointers don't preserve parameter names, so we wouldn't know how to assign arguments to parameters.
```

Ein Funktionszeiger wird mit benannten Argumenten aufgerufen. Ein
Funktionszeiger behält die Namen der Parameter nicht; seine Argumente stehen
deshalb nach Position.

Dieses Modul scheitert mit H3043:

```hilde fails H3043
module body Example is
    function add(a: Int32, b: Int32): Int32 is
        return a + b;
    end;

    function main(): ExitCode is
        let f: Fn[Int32, Int32, Int32] := add;
        let sum: Int32 := f(a => 1, b => 2);
        printLn(sum);
        return ExitSuccess();
    end;
end module body.
```

Die richtige Form:

```hilde
module body Example is
    function add(a: Int32, b: Int32): Int32 is
        return a + b;
    end;

    function main(): ExitCode is
        let f: Fn[Int32, Int32, Int32] := add;
        let sum: Int32 := f(1, 2);
        printLn(sum);
        return ExitSuccess();
    end;
end module body.
```

### H3044

Meldung:

```text
Type Error
The branches of the `if`-expression have different types: `Int32` and `Bool`
```

Die beiden Zweige eines if-Ausdrucks haben verschiedene Typen.

Dieses Modul scheitert mit H3044:

```hilde fails H3044
module body Example is
    function main(): ExitCode is
        let flag: Bool := true;
        printLn(if flag then 1 else false);
        return ExitSuccess();
    end;
end module body.
```

Die richtige Form:

```hilde
module body Example is
    function main(): ExitCode is
        let flag: Bool := true;
        printLn(if flag then 1 else 0);
        return ExitSuccess();
    end;
end module body.
```

### H3045

Meldung:

```text
Type Error
The operand of a negation operator must be a boolean expression, but it has the type `Int32`
```

Der Operand von not ist kein Bool.

Dieses Modul scheitert mit H3045:

```hilde fails H3045
module body Example is
    function main(): ExitCode is
        let n: Int32 := 1;
        printLn(not n);
        return ExitSuccess();
    end;
end module body.
```

Die richtige Form:

```hilde
module body Example is
    function main(): ExitCode is
        let n: Int32 := 1;
        printLn(not (n = 0));
        return ExitSuccess();
    end;
end module body.
```

### H3046

Meldung:

```text
Type Error
Both operands of a conjunction operator must be boolean expressions, but they have types `Int32` and `Bool`
```

Ein Operand von and oder or ist kein Bool.

Dieses Modul scheitert mit H3046:

```hilde fails H3046
module body Example is
    function main(): ExitCode is
        let n: Int32 := 1;
        let flag: Bool := true;
        printLn(n and flag);
        return ExitSuccess();
    end;
end module body.
```

Die richtige Form:

```hilde
module body Example is
    function main(): ExitCode is
        let n: Int32 := 1;
        let flag: Bool := true;
        printLn((n = 1) and flag);
        return ExitSuccess();
    end;
end module body.
```

### H3049

Meldung:

```text
Type Error
The type `Point` has no slot with name `z`
```

Ein Record hat keinen Slot dieses Namens.

Dieses Modul scheitert mit H3049:

```hilde fails H3049
module body Example is
    record Point: Free is
        x: Int32;
        y: Int32;
    end;

    function main(): ExitCode is
        let p: Point := Point(x => 1, y => 2);
        printLn(p.z);
        return ExitSuccess();
    end;
end module body.
```

Die richtige Form:

```hilde
module body Example is
    record Point: Free is
        x: Int32;
        y: Int32;
    end;

    function main(): ExitCode is
        let p: Point := Point(x => 1, y => 2);
        printLn(p.y);
        return ExitSuccess();
    end;
end module body.
```

### H3050

Meldung:

```text
Type Error
The typeclass `Describe` has no instance which matches for `Int32`
```

Eine Methode einer Typklasse wird mit einem Wert aufgerufen, dessen Typ
keine Instanz dieser Klasse hat.

Dieses Modul scheitert mit H3050:

```hilde fails H3050
module body Example is
    typeclass Describe(T: Free) is
        method describe(value: T): Int32;
    end;

    instance Describe(Bool) is
        method describe(value: Bool): Int32 is
            return 1;
        end;
    end;

    function main(): ExitCode is
        let n: Int32 := 5;
        printLn(describe(n));
        return ExitSuccess();
    end;
end module body.
```

Die richtige Form:

```hilde
module body Example is
    typeclass Describe(T: Free) is
        method describe(value: T): Int32;
    end;

    instance Describe(Bool) is
        method describe(value: Bool): Int32 is
            return 1;
        end;
    end;

    function main(): ExitCode is
        let flag: Bool := true;
        printLn(describe(flag));
        return ExitSuccess();
    end;
end module body.
```

### H3052

Meldung:

```text
Type Error
The slot `x` is not publically visible in the type `Point` and so cannot be read.
```

Ein Slot wird aus einem Record gelesen, den ein anderes Modul nur als opaken
Typ exportiert.

Dieses Modul scheitert mit H3052:

```hilde fails H3052
import Library (Point, make);

module body Example is
    function main(): ExitCode is
        let p: Point := make();
        printLn(p.x);
        return ExitSuccess();
    end;
end module body.
```

Daneben `Library.hih`:

```hilde file Library.hih
module Library is
    type Point: Free;

    function make(): Point;
end module.
```

Daneben `Library.hiq`:

```hilde file Library.hiq
module body Library is
    record Point: Free is
        x: Int32;
    end;

    function make(): Point is
        return Point(x => 1);
    end;
end module body.
```

Die richtige Form:

```hilde
import Library (Point, make, pointX);

module body Example is
    function main(): ExitCode is
        let p: Point := make();
        printLn(pointX(p));
        return ExitSuccess();
    end;
end module body.
```

Daneben `Library.hih`:

```hilde file Library.hih
module Library is
    type Point: Free;

    function make(): Point;

    function pointX(p: Point): Int32;
end module.
```

Daneben `Library.hiq`:

```hilde file Library.hiq
module body Library is
    record Point: Free is
        x: Int32;
    end;

    function make(): Point is
        return Point(x => 1);
    end;

    function pointX(p: Point): Int32 is
        return p.x;
    end;
end module body.
```

### H3053

Meldung:

```text
Type Error
Cannot take a path of the type `Shape` because it is not a record.
```

Ein Slot wird aus einem Wert eines benannten Typs gelesen, der kein Record
ist, etwa einer Union. Ein Wert eines eingebauten Typs wird als H3057
gemeldet.

Dieses Modul scheitert mit H3053:

```hilde fails H3053
module body Example is
    union Shape: Free is
        case Dot;
        case Circle is
            radius: Int32;
    end;

    function main(): ExitCode is
        let s: Shape := Circle(radius => 2);
        printLn(s.radius);
        return ExitSuccess();
    end;
end module body.
```

Die richtige Form:

```hilde
module body Example is
    record Circle: Free is
        radius: Int32;
    end;

    function main(): ExitCode is
        let s: Circle := Circle(radius => 2);
        printLn(s.radius);
        return ExitSuccess();
    end;
end module body.
```

### H3054

Meldung:

```text
Type Error
The slot `number` should have type `Int32` but is declared to have type `Int64`
```

Eine Bindung in einem case-Zweig deklariert einen anderen Typ, als der Slot
hat.

Dieses Modul scheitert mit H3054:

```hilde fails H3054
module body Example is
    function main(): ExitCode is
        let count: Option[Int32] := Some(value => 5);
        case count of
            when Some(value as number: Int64) do
                printLn(number);
            when None do
                printLn(0);
        end case;
        return ExitSuccess();
    end;
end module body.
```

Die richtige Form:

```hilde
module body Example is
    function main(): ExitCode is
        let count: Option[Int32] := Some(value => 5);
        case count of
            when Some(value as number: Int32) do
                printLn(number);
            when None do
                printLn(0);
        end case;
        return ExitSuccess();
    end;
end module body.
```

### H3055

Meldung:

```text
Type Error
`None` is generic but unconstrained, so its type is ambiguous: its type is `Option[T]`, and nothing here decides `T`.

Give the value a type: declare the variable it goes into with one, or cast it.
```

Eine generische Funktion, deren Typparameter nur im Rückgabetyp vorkommt,
wird an einer Stelle aufgerufen, die keinen Typ erwartet; ihr Typ lässt sich
so nicht bestimmen. Eine Typangabe mit Doppelpunkt legt ihn fest.

Dieses Modul scheitert mit H3055:

```hilde fails H3055
module body Example is
    function main(): ExitCode is
        ignore(None());
        return ExitSuccess();
    end;
end module body.
```

Die richtige Form:

```hilde
module body Example is
    function main(): ExitCode is
        ignore(None() : Option[Int32]);
        return ExitSuccess();
    end;
end module body.
```

### H3056

Meldung:

```text
Type Error
The type parameter `T` does not implement the type class `Printable`

Consider adding a constraint to the type parameter.
```

In einer generischen Funktion wird eine Methode einer Typklasse auf einem
Wert eines Typparameters aufgerufen, dem die Anforderung dieser Klasse
fehlt.

Dieses Modul scheitert mit H3056:

```hilde fails H3056
module body Example is
    generic [T: Free]
    function show(value: T): Unit is
        print(value);
        return nil;
    end;

    function main(): ExitCode is
        show(5);
        return ExitSuccess();
    end;
end module body.
```

Die richtige Form:

```hilde
module body Example is
    generic [T: Free(Printable)]
    function show(value: T): Unit is
        print(value);
        return nil;
    end;

    function main(): ExitCode is
        show(5);
        return ExitSuccess();
    end;
end module body.
```

### H3057

Meldung:

```text
Type Error
Can't access the slot `value` because the type `Int32` is not a record.
```

Ein Slot wird aus einem Wert eines eingebauten Typs gelesen, der keine Slots
hat.

Dieses Modul scheitert mit H3057:

```hilde fails H3057
module body Example is
    function main(): ExitCode is
        let n: Int32 := 5;
        printLn(n.value);
        return ExitSuccess();
    end;
end module body.
```

Die richtige Form:

```hilde
module body Example is
    record Box: Free is
        value: Int32;
    end;

    function main(): ExitCode is
        let n: Box := Box(value => 5);
        printLn(n.value);
        return ExitSuccess();
    end;
end module body.
```

### H3058

Meldung:

```text
Type Error
I can't use the array indexing operator here, because the type `Box` is not a span.
```

Der Index-Operator s[i] steht an einem Wert, der kein Span ist.

Dieses Modul scheitert mit H3058:

```hilde fails H3058
module body Example is
    record Box: Free is
        value: Int32;
    end;

    function main(): ExitCode is
        let b: Box := Box(value => 5);
        printLn(b[0]);
        return ExitSuccess();
    end;
end module body.
```

Die richtige Form:

```hilde
module body Example is
    function main(): ExitCode is
        let b: Span[Nat8, Static] := "five";
        printLn(b[0]);
        return ExitSuccess();
    end;
end module body.
```

### H3060

Meldung:

```text
Type Error
Expected a value of type `Int32`, but got a value of type `Bool`.
```

Ein Wert hat einen anderen Typ als den, den seine Stelle erwartet, etwa in
einer return-Anweisung.

Dieses Modul scheitert mit H3060:

```hilde fails H3060
module body Example is
    function answer(): Int32 is
        return true;
    end;

    function main(): ExitCode is
        printLn(answer());
        return ExitSuccess();
    end;
end module body.
```

Die richtige Form:

```hilde
module body Example is
    function answer(): Int32 is
        return 42;
    end;

    function main(): ExitCode is
        printLn(answer());
        return ExitSuccess();
    end;
end module body.
```

### H3061

Meldung:

```text
Type Error
Type constraint not satisfied: the type `Point` does not implement the typeclass `Printable`.

This constraint is for the type variable `T`.
```

Eine generische Funktion verlangt von ihrem Typparameter eine Typklasse, und
der dafür eingesetzte Typ hat keine Instanz dieser Klasse.

Dieses Modul scheitert mit H3061:

```hilde fails H3061
module body Example is
    record Point: Free is
        x: Int32;
    end;

    function main(): ExitCode is
        let p: Point := Point(x => 1);
        printLn(p);
        return ExitSuccess();
    end;
end module body.
```

Die richtige Form:

```hilde
module body Example is
    record Point: Free is
        x: Int32;
    end;

    function main(): ExitCode is
        let p: Point := Point(x => 1);
        printLn(p.x);
        return ExitSuccess();
    end;
end module body.
```

### H3062

Meldung:

```text
Type Error
The integer `300` does not fit the type `Nat8`.
```

Ein Ganzzahl-Literal passt nicht in seinen Typ.

Dieses Modul scheitert mit H3062:

```hilde fails H3062
module body Example is
    function main(): ExitCode is
        let n: Nat8 := 300;
        printLn(n);
        return ExitSuccess();
    end;
end module body.
```

Die richtige Form:

```hilde
module body Example is
    function main(): ExitCode is
        let n: Nat16 := 300;
        printLn(n);
        return ExitSuccess();
    end;
end module body.
```

### H3063

Meldung:

```text
Type Error
The type parameter `T` is expected to be `Free` but the supplied argument is `Linear`
```

Ein Typargument liegt in einem Universum, das sein Typparameter nicht
annimmt, etwa ein Linear-Typ für einen Parameter in Free.

Dieses Modul scheitert mit H3063:

```hilde fails H3063
module body Example is
    record Ticket: Linear is
        number: Int32;
    end;

    record Box[T: Free]: Free is
        content: T;
    end;

    function unpack(box: Box[Ticket]): Unit is
        return nil;
    end;

    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Die richtige Form:

```hilde
module body Example is
    record Ticket: Linear is
        number: Int32;
    end;

    record Box[T: Type]: Type is
        content: T;
    end;

    function unpack(box: Box[Ticket]): Unit is
        let { content: Ticket } := box;
        let { number: Int32 } := content;
        return nil;
    end;

    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

### H3064

Meldung:

```text
Type Error
Unable to find a type with the name `Integer`.

Consider importing it, if it is defined in another module.
```

Ein Typname ist unbekannt: Er ist im Modul nicht deklariert, nicht
importiert und nicht eingebaut.

Dieses Modul scheitert mit H3064:

```hilde fails H3064
module body Example is
    function main(): ExitCode is
        let n: Integer := 1;
        printLn(n);
        return ExitSuccess();
    end;
end module body.
```

Die richtige Form:

```hilde
module body Example is
    function main(): ExitCode is
        let n: Int32 := 1;
        printLn(n);
        return ExitSuccess();
    end;
end module body.
```

### H3065

Meldung:

```text
Type Error
The type for the expression in a case statement must be a union or a reference to a union, but I got `Int32`
```

Ein case, das nach Namen bindet, bekommt einen Wert, der weder eine Union
noch eine Referenz auf eine Union ist.

Dieses Modul scheitert mit H3065:

```hilde fails H3065
module body Example is
    function main(): ExitCode is
        let n: Int32 := 1;
        case n of
            when Some(value: Int32) do
                printLn(value);
            when None do
                printLn(0);
        end case;
        return ExitSuccess();
    end;
end module body.
```

Die richtige Form:

```hilde
module body Example is
    function main(): ExitCode is
        let n: Option[Int32] := Some(value => 1);
        case n of
            when Some(value: Int32) do
                printLn(value);
            when None do
                printLn(0);
        end case;
        return ExitSuccess();
    end;
end module body.
```

### H3071

Meldung:

```text
Type Error
The when of `Circle` binds its slots by name and type, but this case uses patterns in another when.

A case either binds by name in every when, or uses patterns in every when: write the slots of `Circle` as patterns, one per slot in the order the union declares them.
```

Ein case verwendet in einem when Muster und bindet in einem anderen Slots
nach Name und Typ. Ein case tut in allen seinen whens das eine oder das
andere.

Dieses Modul scheitert mit H3071:

```hilde fails H3071
module body Example is
    union Shape: Free is
        case Dot;
        case Circle is
            radius: Int32;
    end;

    function main(): ExitCode is
        let s: Shape := Circle(radius => 2);
        case s of
            when Dot | Circle(0) do
                printLn(0);
            when Circle(radius: Int32) do
                printLn(radius);
        end case;
        return ExitSuccess();
    end;
end module body.
```

Die richtige Form:

```hilde
module body Example is
    union Shape: Free is
        case Dot;
        case Circle is
            radius: Int32;
    end;

    function main(): ExitCode is
        let s: Shape := Circle(radius => 2);
        case s of
            when Dot | Circle(0) do
                printLn(0);
            when Circle(radius) do
                printLn(radius);
        end case;
        return ExitSuccess();
    end;
end module body.
```

### H3072

Meldung:

```text
Type Error
A case with patterns takes a value, but this one is given a reference of type `&[Shape, Region<16>]`.

Matching through a reference is not built; pass the value, or use the case that binds by name, which works on references.
```

Ein case mit Mustern bekommt eine Referenz. Muster passen auf einen Wert;
auf Referenzen arbeitet ein case, das nach Namen bindet.

Dieses Modul scheitert mit H3072:

```hilde fails H3072
module body Example is
    union Shape: Free is
        case Dot;
        case Circle is
            radius: Int32;
    end;

    function main(): ExitCode is
        let s: Shape := Circle(radius => 2);
        case &s of
            when Dot do
                printLn(0);
            when Circle(r) do
                printLn(r);
        end case;
        return ExitSuccess();
    end;
end module body.
```

Die richtige Form:

```hilde
module body Example is
    union Shape: Free is
        case Dot;
        case Circle is
            radius: Int32;
    end;

    function main(): ExitCode is
        let s: Shape := Circle(radius => 2);
        case s of
            when Dot do
                printLn(0);
            when Circle(r) do
                printLn(r);
        end case;
        return ExitSuccess();
    end;
end module body.
```

### H3073

Meldung:

```text
Type Error
The variable `other` would match every value of the union `Shape`, and a case over a union has no catch-all.

List the variants; the compiler says which one is missing.
```

Eine Variable steht als ganzes Muster in einem case über einer Union. Sie
würde auf jeden Wert passen, und ein case über einer Union hat keinen
Auffangzweig: Jede Variante wird aufgeführt.

Dieses Modul scheitert mit H3073:

```hilde fails H3073
module body Example is
    union Shape: Free is
        case Dot;
        case Circle is
            radius: Int32;
    end;

    function main(): ExitCode is
        let s: Shape := Circle(radius => 2);
        case s of
            when Dot do
                printLn(0);
            when other do
                printLn(1);
        end case;
        return ExitSuccess();
    end;
end module body.
```

Die richtige Form:

```hilde
module body Example is
    union Shape: Free is
        case Dot;
        case Circle is
            radius: Int32;
    end;

    function main(): ExitCode is
        let s: Shape := Circle(radius => 2);
        case s of
            when Dot do
                printLn(0);
            when Circle(r) do
                printLn(1);
        end case;
        return ExitSuccess();
    end;
end module body.
```

### H3074

Meldung:

```text
Type Error
The pattern `5` can never be chosen: every value it matches is matched by a pattern before it.

Remove it, or move it before the pattern that covers it.
```

Ein Muster kann nie gewählt werden, weil die Muster davor schon jeden Wert
erfassen, auf den es passt.

Dieses Modul scheitert mit H3074:

```hilde fails H3074
module body Example is
    function main(): ExitCode is
        let n: Nat8 := 5;
        case n of
            when 0 .. 9 do
                printLn(1);
            when 5 do
                printLn(2);
            when _ do
                printLn(3);
        end case;
        return ExitSuccess();
    end;
end module body.
```

Die richtige Form:

```hilde
module body Example is
    function main(): ExitCode is
        let n: Nat8 := 5;
        case n of
            when 5 do
                printLn(2);
            when 0 .. 9 do
                printLn(1);
            when _ do
                printLn(3);
        end case;
        return ExitSuccess();
    end;
end module body.
```

### H3075

Meldung:

```text
Type Error
The case does not cover every value of `Nat8`: for example `10` matches no when.

Add a when for it.  A case has no else; over an integer a variable or `_` finishes it.
```

Ein case mit Mustern lässt Werte aus. Die Meldung nennt einen davon; bei
einer ganzen Zahl schließt eine Variable oder _ am Ende das case ab.

Dieses Modul scheitert mit H3075:

```hilde fails H3075
module body Example is
    function main(): ExitCode is
        let n: Nat8 := 5;
        case n of
            when 0 .. 9 do
                printLn(1);
        end case;
        return ExitSuccess();
    end;
end module body.
```

Die richtige Form:

```hilde
module body Example is
    function main(): ExitCode is
        let n: Nat8 := 5;
        case n of
            when 0 .. 9 do
                printLn(1);
            when _ do
                printLn(2);
        end case;
        return ExitSuccess();
    end;
end module body.
```

### H3076

Meldung:

```text
Type Error
The integer pattern `1` stands where the value has the type `Bool`, which is not an integer type.
```

Ein Ganzzahl-Muster steht, wo der Wert keine ganze Zahl ist.

Dieses Modul scheitert mit H3076:

```hilde fails H3076
module body Example is
    function main(): ExitCode is
        let flag: Bool := true;
        case flag of
            when 1 do
                printLn(1);
            when _ do
                printLn(0);
        end case;
        return ExitSuccess();
    end;
end module body.
```

Die richtige Form:

```hilde
module body Example is
    function main(): ExitCode is
        let flag: Bool := true;
        case flag of
            when true do
                printLn(1);
            when false do
                printLn(0);
        end case;
        return ExitSuccess();
    end;
end module body.
```

### H3077

Meldung:

```text
Type Error
`true` is a Bool pattern, but the value here has the type `Int32`.
```

Ein Bool-Muster, true oder false, steht, wo der Wert kein Bool ist.

Dieses Modul scheitert mit H3077:

```hilde fails H3077
module body Example is
    function main(): ExitCode is
        let n: Int32 := 1;
        case n of
            when true do
                printLn(1);
            when _ do
                printLn(0);
        end case;
        return ExitSuccess();
    end;
end module body.
```

Die richtige Form:

```hilde
module body Example is
    function main(): ExitCode is
        let n: Int32 := 1;
        case n of
            when 1 do
                printLn(1);
            when _ do
                printLn(0);
        end case;
        return ExitSuccess();
    end;
end module body.
```

### H3078

Meldung:

```text
Type Error
The literal `256` is outside `Nat8`, whose values are `0 .. 255`.

A pattern never truncates or wraps a literal.
```

Ein Literal oder eine Grenze eines Bereichs liegt außerhalb des Typs des
Werts. Ein Muster schneidet ein Literal nie ab und rechnet es nie um.

Dieses Modul scheitert mit H3078:

```hilde fails H3078
module body Example is
    function main(): ExitCode is
        let n: Nat8 := 5;
        case n of
            when 256 do
                printLn(1);
            when _ do
                printLn(0);
        end case;
        return ExitSuccess();
    end;
end module body.
```

Die richtige Form:

```hilde
module body Example is
    function main(): ExitCode is
        let n: Nat8 := 5;
        case n of
            when 255 do
                printLn(1);
            when _ do
                printLn(0);
        end case;
        return ExitSuccess();
    end;
end module body.
```

### H3079

Meldung:

```text
Type Error
The range `9 .. 0` is empty: its lower bound is above its upper bound.

A range lists its lower bound first, and both bounds belong to it.
```

Die untere Grenze eines Bereichs liegt über der oberen; der Bereich ist
leer.

Dieses Modul scheitert mit H3079:

```hilde fails H3079
module body Example is
    function main(): ExitCode is
        let n: Nat8 := 5;
        case n of
            when 9 .. 0 do
                printLn(1);
            when _ do
                printLn(0);
        end case;
        return ExitSuccess();
    end;
end module body.
```

Die richtige Form:

```hilde
module body Example is
    function main(): ExitCode is
        let n: Nat8 := 5;
        case n of
            when 0 .. 9 do
                printLn(1);
            when _ do
                printLn(0);
        end case;
        return ExitSuccess();
    end;
end module body.
```

### H3080

Meldung:

```text
Type Error
The float literal `1.5` cannot be a pattern.

A pattern compares for equality, and two floats that print alike need not be equal.  Only integer and Bool literals are patterns; bind the value to a variable and compare it in the body.
```

Ein Gleitkomma-Literal steht als Muster. Zwei Gleitkommazahlen, die gleich
aussehen, müssen nicht gleich sein; Gleitkommazahlen sind deshalb keine
Muster. Man bindet den Wert und vergleicht im Rumpf.

Dieses Modul scheitert mit H3080:

```hilde fails H3080
module body Example is
    function main(): ExitCode is
        let x: Int32 := 1;
        case x of
            when 1.5 do
                printLn(1);
            when _ do
                printLn(0);
        end case;
        return ExitSuccess();
    end;
end module body.
```

Die richtige Form:

```hilde
module body Example is
    function main(): ExitCode is
        let x: Int32 := 1;
        case x of
            when 1 do
                printLn(1);
            when _ do
                printLn(0);
        end case;
        return ExitSuccess();
    end;
end module body.
```

### H3081

Meldung:

```text
Type Error
A string literal cannot be a pattern.

Only integer and Bool literals are patterns; bind the value to a variable and compare it in the body.
```

Ein String-Literal steht als Muster. Muster sind nur Ganzzahl- und
Bool-Literale.

Dieses Modul scheitert mit H3081:

```hilde fails H3081
module body Example is
    function main(): ExitCode is
        let x: Int32 := 1;
        case x of
            when "one" do
                printLn(1);
            when _ do
                printLn(0);
        end case;
        return ExitSuccess();
    end;
end module body.
```

Die richtige Form:

```hilde
module body Example is
    function main(): ExitCode is
        let x: Int32 := 1;
        case x of
            when 1 do
                printLn(1);
            when _ do
                printLn(0);
        end case;
        return ExitSuccess();
    end;
end module body.
```

### H3082

Meldung:

```text
Type Error
`_` stands where the value has the type `Ticket`, which is not in the Free universe.

It would drop that value without anyone consuming it.  Bind it to a variable and consume it in the body.
```

Das Muster _ steht, wo der Wert nicht Free ist. Es würde einen linearen Wert
fallen lassen, den niemand verbraucht; man bindet ihn an eine Variable und
verbraucht ihn.

Dieses Modul scheitert mit H3082:

```hilde fails H3082
module body Example is
    record Ticket: Linear is
        number: Int32;
    end;

    union Slot: Linear is
        case Empty;
        case Full is
            ticket: Ticket;
    end;

    function main(): ExitCode is
        let s: Slot := Empty();
        case s of
            when Empty do
                printLn(0);
            when Full(_) do
                printLn(1);
        end case;
        return ExitSuccess();
    end;
end module body.
```

Die richtige Form:

```hilde
module body Example is
    record Ticket: Linear is
        number: Int32;
    end;

    union Slot: Linear is
        case Empty;
        case Full is
            ticket: Ticket;
    end;

    function main(): ExitCode is
        let s: Slot := Empty();
        case s of
            when Empty do
                printLn(0);
            when Full(t) do
                let { number: Int32 } := t;
                printLn(number);
        end case;
        return ExitSuccess();
    end;
end module body.
```

### H3083

Meldung:

```text
Type Error
The variant `Rectangle` has 2 slot(s), and the pattern gives 1 sub-pattern(s).

A variant pattern gives one sub-pattern for every slot, in the order the union declares them, so that no slot is left out unseen.
```

Ein Variantenmuster gibt mehr oder weniger Untermuster an, als die Variante
Slots hat. Jeder Slot bekommt eines, in der Reihenfolge der Deklaration.

Dieses Modul scheitert mit H3083:

```hilde fails H3083
module body Example is
    union Shape: Free is
        case Dot;
        case Rectangle is
            width: Int32;
            height: Int32;
    end;

    function main(): ExitCode is
        let s: Shape := Dot();
        case s of
            when Dot do
                printLn(0);
            when Rectangle(w) do
                printLn(w);
        end case;
        return ExitSuccess();
    end;
end module body.
```

Die richtige Form:

```hilde
module body Example is
    union Shape: Free is
        case Dot;
        case Rectangle is
            width: Int32;
            height: Int32;
    end;

    function main(): ExitCode is
        let s: Shape := Dot();
        case s of
            when Dot do
                printLn(0);
            when Rectangle(w, h) do
                printLn(w * h);
        end case;
        return ExitSuccess();
    end;
end module body.
```

### H3084

Meldung:

```text
Type Error
The alternatives of this when bind different variables: `a` is bound in one alternative and not in another.

The body runs after any of them, so every alternative binds the same variables.
```

Die Alternativen eines when binden verschiedene Variablen. Der Rumpf läuft
nach jeder von ihnen; alle binden deshalb dieselben Variablen.

Dieses Modul scheitert mit H3084:

```hilde fails H3084
module body Example is
    union Shape: Free is
        case Square is
            side: Int32;
        case Rectangle is
            width: Int32;
            height: Int32;
    end;

    function main(): ExitCode is
        let s: Shape := Square(side => 2);
        case s of
            when Square(a) | Rectangle(b, _) do
                printLn(1);
        end case;
        return ExitSuccess();
    end;
end module body.
```

Die richtige Form:

```hilde
module body Example is
    union Shape: Free is
        case Square is
            side: Int32;
        case Rectangle is
            width: Int32;
            height: Int32;
    end;

    function main(): ExitCode is
        let s: Shape := Square(side => 2);
        case s of
            when Square(a) | Rectangle(a, _) do
                printLn(a);
        end case;
        return ExitSuccess();
    end;
end module body.
```

### H3085

Meldung:

```text
Type Error
The variable `x` has the type `Int8` in one alternative and `Int64` in another.

The body runs after any of them, so a variable has one type in every alternative.
```

Eine Variable hat in einer Alternative eines when einen Typ und in einer
anderen einen anderen.

Dieses Modul scheitert mit H3085:

```hilde fails H3085
module body Example is
    union Value: Free is
        case Small is
            n: Int8;
        case Large is
            n: Int64;
    end;

    function main(): ExitCode is
        let v: Value := Small(n => 1);
        case v of
            when Small(x) | Large(x) do
                printLn(1);
        end case;
        return ExitSuccess();
    end;
end module body.
```

Die richtige Form:

```hilde
module body Example is
    union Value: Free is
        case Small is
            n: Int8;
        case Large is
            n: Int64;
    end;

    function main(): ExitCode is
        let v: Value := Small(n => 1);
        case v of
            when Small(x) do
                printLn(x);
            when Large(x) do
                printLn(x);
        end case;
        return ExitSuccess();
    end;
end module body.
```

### H3086

Meldung:

```text
Type Error
The variable `a` is bound twice in one pattern.

A pattern binds each variable once; to compare two parts, bind both and compare them in the body.
```

Ein Muster bindet dieselbe Variable zweimal. Um zwei Teile zu vergleichen,
bindet man beide unter verschiedenen Namen und vergleicht im Rumpf.

Dieses Modul scheitert mit H3086:

```hilde fails H3086
module body Example is
    union Shape: Free is
        case Rectangle is
            width: Int32;
            height: Int32;
    end;

    function main(): ExitCode is
        let s: Shape := Rectangle(width => 2, height => 2);
        case s of
            when Rectangle(a, a) do
                printLn(a);
        end case;
        return ExitSuccess();
    end;
end module body.
```

Die richtige Form:

```hilde
module body Example is
    union Shape: Free is
        case Rectangle is
            width: Int32;
            height: Int32;
    end;

    function main(): ExitCode is
        let s: Shape := Rectangle(width => 2, height => 2);
        case s of
            when Rectangle(a, b) do
                printLn(a = b);
        end case;
        return ExitSuccess();
    end;
end module body.
```

### H3087

Meldung:

```text
Type Error
`circle` takes sub-patterns, but its name begins with a lower-case letter, which makes it a variable.

Only a variant takes sub-patterns, and a variant's name begins with an upper-case letter.
```

Ein Name mit kleinem Anfangsbuchstaben hat Untermuster. Ein solcher Name ist
eine Variable; Untermuster hat nur eine Variante, mit großem
Anfangsbuchstaben.

Dieses Modul scheitert mit H3087:

```hilde fails H3087
module body Example is
    union Shape: Free is
        case Dot;
        case circle is
            radius: Int32;
    end;

    function main(): ExitCode is
        let s: Shape := Dot();
        case s of
            when Dot do
                printLn(0);
            when circle(r) do
                printLn(r);
        end case;
        return ExitSuccess();
    end;
end module body.
```

Die richtige Form:

```hilde
module body Example is
    union Shape: Free is
        case Dot;
        case Circle is
            radius: Int32;
    end;

    function main(): ExitCode is
        let s: Shape := Dot();
        case s of
            when Dot do
                printLn(0);
            when Circle(r) do
                printLn(r);
        end case;
        return ExitSuccess();
    end;
end module body.
```

### H3088

Meldung:

```text
Type Error
`Square` is not a variant of `Shape`.  Its variants are `Dot, Circle`.
```

Ein Variantenmuster nennt einen Fall, den die Union nicht hat. Die Meldung
zählt ihre Varianten auf.

Dieses Modul scheitert mit H3088:

```hilde fails H3088
module body Example is
    union Shape: Free is
        case Dot;
        case Circle is
            radius: Int32;
    end;

    function main(): ExitCode is
        let s: Shape := Dot();
        case s of
            when Dot do
                printLn(0);
            when Square(r) do
                printLn(r);
        end case;
        return ExitSuccess();
    end;
end module body.
```

Die richtige Form:

```hilde
module body Example is
    union Shape: Free is
        case Dot;
        case Circle is
            radius: Int32;
    end;

    function main(): ExitCode is
        let s: Shape := Dot();
        case s of
            when Dot do
                printLn(0);
            when Circle(r) do
                printLn(r);
        end case;
        return ExitSuccess();
    end;
end module body.
```

### H3089

Meldung:

```text
Type Error
`Some` is a variant pattern, but the value here has the type `Int32`, which is not a union.
```

Ein Variantenmuster steht, wo der Wert keine Union ist.

Dieses Modul scheitert mit H3089:

```hilde fails H3089
module body Example is
    function main(): ExitCode is
        let n: Int32 := 1;
        case n of
            when Some(x) do
                printLn(x);
            when _ do
                printLn(0);
        end case;
        return ExitSuccess();
    end;
end module body.
```

Die richtige Form:

```hilde
module body Example is
    function main(): ExitCode is
        let n: Option[Int32] := Some(value => 1);
        case n of
            when Some(x) do
                printLn(x);
            when None do
                printLn(0);
        end case;
        return ExitSuccess();
    end;
end module body.
```

### H3090

Meldung:

```text
Type Error
A case with patterns decides on a union, an integer or a Bool, but this value has the type `Float64`.
```

Ein case mit Mustern bekommt einen Wert eines Typs, über den es nicht
entscheiden kann. Muster entscheiden über eine Union, eine ganze Zahl oder
ein Bool.

Dieses Modul scheitert mit H3090:

```hilde fails H3090
module body Example is
    function main(): ExitCode is
        let x: Float64 := 1.0;
        case x of
            when y do
                printLn(y);
        end case;
        return ExitSuccess();
    end;
end module body.
```

Die richtige Form:

```hilde
module body Example is
    function main(): ExitCode is
        let x: Int32 := 1;
        case x of
            when y do
                printLn(y);
        end case;
        return ExitSuccess();
    end;
end module body.
```

### H3091

Meldung:

```text
Type Error
`_` would match every value of the union `Shape`, and a case over a union has no catch-all.

List the variants; the compiler says which one is missing.
```

Das Muster _ steht als ganzes Muster in einem case über einer Union. Ein
case über einer Union hat keinen Auffangzweig: Jede Variante wird
aufgeführt.

Dieses Modul scheitert mit H3091:

```hilde fails H3091
module body Example is
    union Shape: Free is
        case Dot;
        case Circle is
            radius: Int32;
    end;

    function main(): ExitCode is
        let s: Shape := Dot();
        case s of
            when Dot do
                printLn(0);
            when _ do
                printLn(1);
        end case;
        return ExitSuccess();
    end;
end module body.
```

Die richtige Form:

```hilde
module body Example is
    union Shape: Free is
        case Dot;
        case Circle is
            radius: Int32;
    end;

    function main(): ExitCode is
        let s: Shape := Dot();
        case s of
            when Dot do
                printLn(0);
            when Circle(_) do
                printLn(1);
        end case;
        return ExitSuccess();
    end;
end module body.
```

### H3092

Meldung:

```text
Type Error
The range `0 .. 1` stands where the value has the type `Bool`, which is not an integer type.
```

Ein Bereich steht, wo der Wert keine ganze Zahl ist.

Dieses Modul scheitert mit H3092:

```hilde fails H3092
module body Example is
    function main(): ExitCode is
        let flag: Bool := true;
        case flag of
            when 0 .. 1 do
                printLn(1);
            when _ do
                printLn(0);
        end case;
        return ExitSuccess();
    end;
end module body.
```

Die richtige Form:

```hilde
module body Example is
    function main(): ExitCode is
        let flag: Bool := true;
        case flag of
            when true do
                printLn(1);
            when false do
                printLn(0);
        end case;
        return ExitSuccess();
    end;
end module body.
```

### H3093

Meldung:

```text
Type Error
A write reference to part of a value needs a write reference to the value, but the path gives `&[Inner, R]`.

Start the path from a write reference, or take a read reference with `&(...)`.
```

Eine Schreib-Referenz auf einen Teil eines Werts wird über eine
Lese-Referenz genommen. &!(path) braucht einen Pfad, der bei einer
Schreib-Referenz beginnt; über eine Lese-Referenz liest nur &(path) den
Teil.

Dieses Modul scheitert mit H3093:

```hilde fails H3093
module body Example is
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
        let pair: Pair := Pair(first => Inner(value => 5), second => Inner(value => 0));
        clear(&pair);
        let { first: Inner, second: Inner } := pair;
        let { value as a: Int32 } := first;
        let { value as b: Int32 } := second;
        return ExitSuccess();
    end;
end module body.
```

Die richtige Form:

```hilde
module body Example is
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
    function clear(pair: &![Pair, R]): Unit is
        setValue(&!(pair->first), 0);
        return nil;
    end;

    function main(): ExitCode is
        var pair: Pair := Pair(first => Inner(value => 5), second => Inner(value => 0));
        clear(&!pair);
        let { first: Inner, second: Inner } := pair;
        let { value as a: Int32 } := first;
        let { value as b: Int32 } := second;
        return ExitSuccess();
    end;
end module body.
```

### H3094

Meldung:

```text
Type Error
A reference made inside this function cannot be handed out as `R`.

`R` is a region parameter of the function: the caller chooses it, and it outlives the call.  The reference here has the region `Region<44>`, which ends inside the function.
```

Eine Funktion gibt eine Referenz auf eine ihrer lokalen Variablen in einer
Region zurück, die ihr Aufrufer wählt. Die Region des Aufrufers überdauert
den Aufruf, die lokale Variable nicht.

Dieses Modul scheitert mit H3094:

```hilde fails H3094
module body Example is
    generic [R: Region]
    function local(n: Int32): &[Int32, R] is
        let x: Int32 := n;
        return &x;
    end;

    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Die richtige Form:

```hilde
module body Example is
    generic [R: Region]
    function same(x: &[Int32, R]): &[Int32, R] is
        return x;
    end;

    function main(): ExitCode is
        let n: Int32 := 5;
        let value: Int32 := !same(&n);
        printLn(value);
        return ExitSuccess();
    end;
end module body.
```

### H3095

Meldung:

```text
Type Error
The type parameter `T` would have to be `Int32` here.

The caller chooses the type parameters of a function; its body cannot fix one.
```

Der Rumpf einer generischen Funktion legt einen der Typparameter der
Funktion fest. Was ein Typparameter bedeutet, wählt der Aufrufer; der Rumpf
muss deshalb für jede Wahl funktionieren.

Dieses Modul scheitert mit H3095:

```hilde fails H3095
module body Example is
    generic [T: Type]
    function pretend(n: Int32): T is
        return n;
    end;

    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Die richtige Form:

```hilde
module body Example is
    generic [T: Type]
    function identity(value: T): T is
        return value;
    end;

    function main(): ExitCode is
        let n: Int32 := 7;
        let same: Int32 := identity(n);
        printLn(same);
        return ExitSuccess();
    end;
end module body.
```

### H4001

Meldung:

```text
Linearity Error
`Wallet` was declared to belong to the `Free` universe, but it contains a type that belongs to the `Linear` universe.
```

Ein als Free deklarierter Record oder eine solche Union enthält einen Slot
eines Linear-Typs oder hat einen Typparameter, der nicht Free ist. Ein
Free-Wert ließe sich kopieren, und der lineare Wert darin mit ihm.

Dieses Modul scheitert mit H4001:

```hilde fails H4001
module body Example is
    record Ticket: Linear is
        number: Int32;
    end;

    record Wallet: Free is
        ticket: Ticket;
    end;

    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Die richtige Form:

```hilde
module body Example is
    record Ticket: Linear is
        number: Int32;
    end;

    record Wallet: Linear is
        ticket: Ticket;
    end;

    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

### H6026

Meldung:

```text
Generic Error
Wrong number of arguments. Expected `2` and got `1`.
```

Eine Funktion, eine Methode oder ein Konstruktor wird mit mehr oder weniger
Argumenten aufgerufen, als sie Parameter hat.

Dieses Modul scheitert mit H6026:

```hilde fails H6026
module body Example is
    function add(a: Int32, b: Int32): Int32 is
        return a + b;
    end;

    function main(): ExitCode is
        printLn(add(1));
        return ExitSuccess();
    end;
end module body.
```

Die richtige Form:

```hilde
module body Example is
    function add(a: Int32, b: Int32): Int32 is
        return a + b;
    end;

    function main(): ExitCode is
        printLn(add(1, 2));
        return ExitSuccess();
    end;
end module body.
```

### H6032

Meldung:

```text
Generic Error
Orphan rule broken: typeclass and type are both foreign.
```

Eine Instanz verbindet eine Typklasse und einen Typ, die beide aus anderen
Modulen stammen. Eine Instanz gehört in das Modul ihrer Typklasse oder ihres
Typs.

Dieses Modul scheitert mit H6032:

```hilde fails H6032
module body Example is
    instance Printable(ExitCode) is
        method print(value: ExitCode): Unit is
            return nil;
        end;

        generic [R: Region]
        method printSpan(value: Span[ExitCode, R]): Unit is
            return nil;
        end;
    end;

    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Die richtige Form:

```hilde
module body Example is
    record Status: Free is
        code: Int32;
    end;

    instance Printable(Status) is
        method print(value: Status): Unit is
            print(value.code);
            return nil;
        end;

        generic [R: Region]
        method printSpan(value: Span[Status, R]): Unit is
            return nil;
        end;
    end;

    function main(): ExitCode is
        printLn(Status(code => 0));
        return ExitSuccess();
    end;
end module body.
```

### H6037

Meldung:

```text
Generic Error
Orphan rule broken: `Nat8` is a built-in type. It belongs to the language and not to the module that names it, so it is foreign in every module except Hilde.Pervasive and Hilde.Memory, and the typeclass is foreign here too. Define a type of your own and give that the instance.
```

Eine Instanz einer Typklasse aus einem anderen Modul wird für einen
eingebauten Typ angegeben. Ein eingebauter Typ gehört der Sprache und gilt
deshalb in jedem Modul als fremd; man definiert einen eigenen Typ und gibt
diesem die Instanz.

Dieses Modul scheitert mit H6037:

```hilde fails H6037
module body Example is
    instance TrappingNegation(Nat8) is
        method trappingNegate(value: Nat8): Nat8 is
            return value;
        end;
    end;

    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Die richtige Form:

```hilde
module body Example is
    record Level: Free is
        value: Nat8;
    end;

    instance TrappingNegation(Level) is
        method trappingNegate(value: Level): Level is
            return value;
        end;
    end;

    function main(): ExitCode is
        let l: Level := Level(value => 3);
        let m: Level := -l;
        printLn(m.value);
        return ExitSuccess();
    end;
end module body.
```

### H6038

Meldung:

```text
Generic Error
Instance overlaps: the typeclass already has an instance for `Bool`. The existing instance is in the module `Example`, the new one is in `Example`. In one program a type may have at most one instance of a typeclass, whichever module declares it.
```

Ein Typ bekommt eine zweite Instanz derselben Typklasse. In einem Programm
hat ein Typ höchstens eine Instanz einer Typklasse, gleich welches Modul sie
deklariert.

Dieses Modul scheitert mit H6038:

```hilde fails H6038
module body Example is
    typeclass Describe(T: Free) is
        method describe(value: T): Int32;
    end;

    instance Describe(Bool) is
        method describe(value: Bool): Int32 is
            return 1;
        end;
    end;

    instance Describe(Bool) is
        method describe(value: Bool): Int32 is
            return 2;
        end;
    end;

    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Die richtige Form:

```hilde
module body Example is
    typeclass Describe(T: Free) is
        method describe(value: T): Int32;
    end;

    instance Describe(Bool) is
        method describe(value: Bool): Int32 is
            return 1;
        end;
    end;

    instance Describe(Int32) is
        method describe(value: Int32): Int32 is
            return 2;
        end;
    end;

    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

### H6039

Meldung:

```text
Generic Error
I can't find a callable named `twice`.
```

Ein aufgerufener Name ist weder eine Funktion noch eine Methode noch eine
sichtbare Variable.

Dieses Modul scheitert mit H6039:

```hilde fails H6039
module body Example is
    function main(): ExitCode is
        printLn(twice(2));
        return ExitSuccess();
    end;
end module body.
```

Die richtige Form:

```hilde
module body Example is
    function twice(n: Int32): Int32 is
        return n * 2;
    end;

    function main(): ExitCode is
        printLn(twice(2));
        return ExitSuccess();
    end;
end module body.
```

### H6041

Meldung:

```text
Generic Error
Cannot assign a value to a function parameter.
```

Links in einer Zuweisung steht ein Parameter der Funktion. Parameter lassen
sich nicht ändern; der Wert wird zuerst in ein var kopiert.

Dieses Modul scheitert mit H6041:

```hilde fails H6041
module body Example is
    function next(n: Int32): Int32 is
        n := n + 1;
        return n;
    end;

    function main(): ExitCode is
        printLn(next(1));
        return ExitSuccess();
    end;
end module body.
```

Die richtige Form:

```hilde
module body Example is
    function next(n: Int32): Int32 is
        var m: Int32 := n;
        m := m + 1;
        return m;
    end;

    function main(): ExitCode is
        printLn(next(1));
        return ExitSuccess();
    end;
end module body.
```

### H6042

Meldung:

```text
Generic Error
Cannot assign a value to `n` because it is immutable.
```

Eine Zuweisung ändert eine mit let gebundene Variable. Eine Variable, die
sich ändert, wird mit var gebunden.

Dieses Modul scheitert mit H6042:

```hilde fails H6042
module body Example is
    function main(): ExitCode is
        let n: Int32 := 1;
        n := 2;
        printLn(n);
        return ExitSuccess();
    end;
end module body.
```

Die richtige Form:

```hilde
module body Example is
    function main(): ExitCode is
        var n: Int32 := 1;
        n := 2;
        printLn(n);
        return ExitSuccess();
    end;
end module body.
```

### H6045

Meldung:

```text
Generic Error
The variable `limit` collides with the name of a declaration.
```

Eine Variable heißt wie eine Deklaration des Moduls, etwa eine Funktion oder
eine Konstante.

Dieses Modul scheitert mit H6045:

```hilde fails H6045
module body Example is
    constant limit: Int32 := 5;

    function main(): ExitCode is
        let limit: Int32 := 6;
        printLn(limit);
        return ExitSuccess();
    end;
end module body.
```

Die richtige Form:

```hilde
module body Example is
    constant limit: Int32 := 5;

    function main(): ExitCode is
        let local: Int32 := 6;
        printLn(local + limit);
        return ExitSuccess();
    end;
end module body.
```

### H6048

Meldung:

```text
Generic Error
The type `Option` expects `1` type arguments, but I only found `2` arguments.
```

Ein generischer Typ oder ein eingebauter Typ wie Pointer bekommt die falsche
Anzahl von Typargumenten.

Dieses Modul scheitert mit H6048:

```hilde fails H6048
module body Example is
    function main(): ExitCode is
        let n: Option[Int32, Bool] := None();
        ignore(n);
        return ExitSuccess();
    end;
end module body.
```

Die richtige Form:

```hilde
module body Example is
    function main(): ExitCode is
        let n: Option[Int32] := None();
        ignore(n);
        return ExitSuccess();
    end;
end module body.
```

### H3105

Meldung:

```text
Type Error
The typeclass `Sized` of a constraint is not imported here. A module, its interface too, imports every typeclass its constraints name, as in `import Shape (Sized);`.
```

Eine Einschränkung einer generischen Funktion nennt eine Typklasse, die das
Modul der Funktion weder im Interface noch im Rumpf importiert.  Ein Modul
importiert jede Typklasse, die seine Einschränkungen nennen; ohne diese
Prüfung hielte das den Compiler mit einem internen Fehler an.

Dieses Modul scheitert mit H3105:

```hilde fails H3105
import Shape (Sized);
import Measure (measure);

module body Example is
    function main(): ExitCode is
        printLn(measure(5));
        return ExitSuccess();
    end;
end module body.
```

Daneben `Shape.hih`:

```hilde file Shape.hih
module Shape is
    typeclass Sized(T: Free) is
        method sizeOf(value: T): Int32;
    end;

    instance Sized(Int32);
end module.
```

Daneben `Shape.hiq`:

```hilde file Shape.hiq
module body Shape is
    instance Sized(Int32) is
        method sizeOf(value: Int32): Int32 is
            return 4;
        end;
    end;
end module body.
```

Daneben `Measure.hih`:

```hilde file Measure.hih
module Measure is
    generic [T: Free(Sized)]
    function measure(value: T): Int32;
end module.
```

Daneben `Measure.hiq`:

```hilde file Measure.hiq
module body Measure is
    generic [T: Free(Sized)]
    function measure(value: T): Int32 is
        return 0;
    end;
end module body.
```

Die richtige Form:

```hilde
import Shape (Sized);
import Measure (measure);

module body Example is
    function main(): ExitCode is
        printLn(measure(5));
        return ExitSuccess();
    end;
end module body.
```

Daneben `Shape.hih`:

```hilde file Shape.hih
module Shape is
    typeclass Sized(T: Free) is
        method sizeOf(value: T): Int32;
    end;

    instance Sized(Int32);
end module.
```

Daneben `Shape.hiq`:

```hilde file Shape.hiq
module body Shape is
    instance Sized(Int32) is
        method sizeOf(value: Int32): Int32 is
            return 4;
        end;
    end;
end module body.
```

Daneben `Measure.hih`:

```hilde file Measure.hih
import Shape (Sized);

module Measure is
    generic [T: Free(Sized)]
    function measure(value: T): Int32;
end module.
```

Daneben `Measure.hiq`:

```hilde file Measure.hiq
import Shape (Sized, sizeOf);

module body Measure is
    generic [T: Free(Sized)]
    function measure(value: T): Int32 is
        return sizeOf(value);
    end;
end module body.
```

### H3106

Meldung:

```text
Type Error
The C text of this @embed names `abs`, a function the programme imports through pragma Foreign_Import as `cAbs`. The compiler declares an imported function under a name of its own, so in C the name `abs` is not declared. Call `cAbs` in Hilde instead.
```

Der Compiler deklariert eine aus C importierte Funktion unter einem eigenen
Namen, also ist der C-Name im Text eines @embed nicht deklariert, und cc
wies das Programm mit einer impliziten Deklaration ab.  Aufgerufen wird
stattdessen die Hilde-Funktion, die sie importiert.  Eine Funktion der
Laufzeit, die lib/prelude.h deklariert, ist auch unter ihrem C-Namen
deklariert, und ein @embed darf sie aufrufen, während ein Modul sie
importiert.

Dieses Modul scheitert mit H3106:

```hilde fails H3106
pragma Unsafe_Module;

module body Example is
    pragma Foreign_Import(External_Name => "abs");
    function cAbs(n: Int32): Int32 is
    end;

    function main(): ExitCode is
        let n: Int32 := @embed(Int32, "abs($1)", -3);
        printLn(n);
        return ExitSuccess();
    end;
end module body.
```

Die richtige Form:

```hilde
pragma Unsafe_Module;

module body Example is
    pragma Foreign_Import(External_Name => "abs");
    function cAbs(n: Int32): Int32 is
    end;

    function main(): ExitCode is
        let n: Int32 := cAbs(-3);
        printLn(n);
        return ExitSuccess();
    end;
end module body.
```

### H3107

Meldung:

```text
Type Error
The operator `=` compares numbers, Bool, Unit, references, addresses and pointers, but its operands have the type `Span[Nat8, Static]`.

Compare the bytes of two texts with `Standard.Text.equal`.
```

Ein Vergleich wird zum Operator von C, der nur Skalare und Zeiger
vergleicht.  Zwei Spans, zwei Records oder zwei Unions kämen ohne diese
Prüfung durch die Typprüfung, und cc wiese das erzeugte C mit ungültigen
Operanden ab.
Zwei Texte vergleicht man Byte für Byte mit Standard.Text.equal, einen
Record mit einer Funktion, die seine Felder vergleicht.  Eine Typvariable
kommt hier durch; H3108 ist dieselbe Prüfung dort, wo ein Aufruf ihr
ihren Typ gibt.

Dieses Modul scheitert mit H3107:

```hilde fails H3107
module body Example is
    function main(): ExitCode is
        let text: Span[Nat8, Static] := "export PATH";
        let word: Span[Nat8, Static] := spanPart(text, 0, 7);
        if word = "export " then
            printLn("an export");
        end if;
        return ExitSuccess();
    end;
end module body.
```

Die richtige Form:

```hilde
import Standard.Text (
    equal
);

module body Example is
    function main(): ExitCode is
        let text: Span[Nat8, Static] := "export PATH";
        let word: Span[Nat8, Static] := spanPart(text, 0, 7);
        if equal(word, "export ") then
            printLn("an export");
        end if;
        return ExitSuccess();
    end;
end module body.
```

### H3108

Meldung:

```text
Type Error
The operator `=` compares numbers, Bool, Unit, references, addresses and pointers, but in a use of a generic function its operands have the type `Span[Nat8, Static]`.

Take a function that compares two values as an argument, or a typeclass.
```

Die Typprüfung lässt einen Vergleich von Werten einer Typvariable durch,
denn eine generische Funktion, die Zahlen vergleicht, ist richtig.  Wo ein
Aufruf der Variable einen Span, einen Record oder eine Union gibt, wird der
Vergleich an dieser Instanz abgewiesen, wie H3107 ihn für einen
ausgeschriebenen Typ abweist; ohne sie wiese cc das erzeugte C ab.

Dieses Modul scheitert mit H3108:

```hilde fails H3108
module body Example is
    generic [T: Free]
    function same(a: T, b: T): Bool is
        return a = b;
    end;

    function main(): ExitCode is
        let left: Span[Nat8, Static] := "a";
        let right: Span[Nat8, Static] := "a";
        printLn(same(left, right));
        return ExitSuccess();
    end;
end module body.
```

Die richtige Form:

```hilde
import Standard.Text (
    equal
);

module body Example is
    function main(): ExitCode is
        let left: Span[Nat8, Static] := "a";
        let right: Span[Nat8, Static] := "a";
        printLn(equal(left, right));
        return ExitSuccess();
    end;
end module body.
```

### H3111

Meldung:

```text
Type Error
The method `size` names the parameter `T` of its typeclass neither in a parameter nor in its result, so no call can tell which instance it means.

Give it a parameter of that type, a witness whose value it need not read.
```

Ein Aufruf einer Methode findet die gemeinte Instanz über den Typ, der für
den Parameter der Klasse steht: in einem Argument oder in dem Typ, als den
das Ergebnis genommen wird.  Eine Methode, die den Parameter in keinem von
beiden nennt, lässt jeden Aufruf ohne Instanz; bisher kam die Typprüfung bis
zu einem solchen Aufruf und brach mit einem internen Fehler ab.  Die Methode
wird abgewiesen, wo die Typklasse sie deklariert.

Dieses Modul scheitert mit H3111:

```hilde fails H3111
module body Example is
    typeclass Sized(T: Free) is
        method size(): Index;
    end;

    instance Sized(Int32) is
        method size(): Index is
            return 4;
        end;
    end;

    function main(): ExitCode is
        printLn(size());
        return ExitSuccess();
    end;
end module body.
```

Die richtige Form:

```hilde
module body Example is
    typeclass Sized(T: Free) is
        method size(witness: T): Index;
    end;

    instance Sized(Int32) is
        method size(witness: Int32): Index is
            return 4;
        end;
    end;

    function main(): ExitCode is
        let zero: Int32 := 0;
        printLn(size(zero));
        return ExitSuccess();
    end;
end module body.
```

## 3. Linearität

### H3036

Meldung:

```text
Type Error
Cannot discard a value in the `Linear` universe.
```

Eine Ausdrucksanweisung wirft einen Wert eines Linear-Typs weg. Ein linearer
Wert wird verbraucht: an eine Funktion übergeben, zurückgegeben oder
zerlegt.

Dieses Modul scheitert mit H3036:

```hilde fails H3036
module body Example is
    record Ticket: Linear is
        number: Int32;
    end;

    function main(): ExitCode is
        Ticket(number => 1);
        return ExitSuccess();
    end;
end module body.
```

Die richtige Form:

```hilde
module body Example is
    record Ticket: Linear is
        number: Int32;
    end;

    function main(): ExitCode is
        let ticket: Ticket := Ticket(number => 1);
        let { number: Int32 } := ticket;
        printLn(number);
        return ExitSuccess();
    end;
end module body.
```

### H4002

Meldung:

```text
Linearity Error
Forgot to consume a linear variable: `value`.
```

Eine lineare Variable verlässt ihren Gültigkeitsbereich, ohne verbraucht zu
sein, etwa eine Variable, die ein when bindet und sein Rumpf nicht
verwendet.

Dieses Modul scheitert mit H4002:

```hilde fails H4002
module body Example is
    record Ticket: Linear is
        number: Int32;
    end;

    function main(): ExitCode is
        let ticket: Ticket := Ticket(number => 1);
        let held: Option[Ticket] := Some(value => ticket);
        case held of
            when Some(value: Ticket) do
                skip;
            when None do
                skip;
        end case;
        return ExitSuccess();
    end;
end module body.
```

Die richtige Form:

```hilde
module body Example is
    record Ticket: Linear is
        number: Int32;
    end;

    function main(): ExitCode is
        let ticket: Ticket := Ticket(number => 1);
        let held: Option[Ticket] := Some(value => ticket);
        case held of
            when Some(value: Ticket) do
                let { number: Int32 } := value;
                printLn(number);
            when None do
                skip;
        end case;
        return ExitSuccess();
    end;
end module body.
```

### H4003

Meldung:

```text
Linearity Error
The  variable `ticket` was consumed in the loop, without afterwards being reassigned.
```

Eine lineare Variable von außerhalb einer Schleife wird im Rumpf verbraucht
und bekommt vor dessen Ende keinen neuen Wert. Der nächste Durchlauf würde
sie ein zweites Mal verwenden.

Dieses Modul scheitert mit H4003:

```hilde fails H4003
module body Example is
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

Die richtige Form:

```hilde
module body Example is
    record Ticket: Linear is
        number: Int32;
    end;

    function redeem(ticket: Ticket): Int32 is
        let { number: Int32 } := ticket;
        return number;
    end;

    function main(): ExitCode is
        var ticket: Ticket := Ticket(number => 7);
        for i from 1 to 3 do
            printLn(redeem(ticket));
            ticket := Ticket(number => 8);
        end for;
        printLn(redeem(ticket));
        return ExitSuccess();
    end;
end module body.
```

### H4004

Meldung:

```text
Linearity Error
The variable `ticket` is used inconsistently in the branches of an if statement. In one branch it is consumed while in the other it is not yet consumed.
```

Die Zweige eines if oder eines case behandeln eine lineare Variable
verschieden: einer verbraucht sie, ein anderer nicht.

Dieses Modul scheitert mit H4004:

```hilde fails H4004
module body Example is
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

Die richtige Form:

```hilde
module body Example is
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
            printLn(0 - redeem(ticket));
        end if;
        return ExitSuccess();
    end;
end module body.
```

### H4005

Meldung:

```text
Linearity Error
The variable `ticket` is consumed multiple times within the same expression.
```

Ein einziger Ausdruck verbraucht dieselbe lineare Variable zweimal, etwa als
zwei Argumente eines Aufrufs.

Dieses Modul scheitert mit H4005:

```hilde fails H4005
module body Example is
    record Ticket: Linear is
        number: Int32;
    end;

    function both(a: Ticket, b: Ticket): Int32 is
        let { number as x: Int32 } := a;
        let { number as y: Int32 } := b;
        return x + y;
    end;

    function main(): ExitCode is
        let ticket: Ticket := Ticket(number => 7);
        printLn(both(ticket, ticket));
        return ExitSuccess();
    end;
end module body.
```

Die richtige Form:

```hilde
module body Example is
    record Ticket: Linear is
        number: Int32;
    end;

    function both(a: Ticket, b: Ticket): Int32 is
        let { number as x: Int32 } := a;
        let { number as y: Int32 } := b;
        return x + y;
    end;

    function main(): ExitCode is
        let first: Ticket := Ticket(number => 7);
        let second: Ticket := Ticket(number => 8);
        printLn(both(first, second));
        return ExitSuccess();
    end;
end module body.
```

### H4008

Meldung:

```text
Linearity Error
The variable `ticket` has already been consumed.
```

Eine lineare Variable wird in einer späteren Anweisung ein zweites Mal
verbraucht.

Dieses Modul scheitert mit H4008:

```hilde fails H4008
module body Example is
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

Die richtige Form:

```hilde
module body Example is
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

### H4010

Meldung:

```text
Linearity Error
Cannot assign to the variable `ticket` because it is not yet consumed.

A variable of a linear type takes a new value only after its old one is consumed, and None() of an Option of a linear type is such a value too. Consume the old value first, or give each branch its own value and return it there instead of collecting it in a var.
```

Einer var mit einem linearen Wert wird ein neuer Wert zugewiesen, bevor der
alte verbraucht ist. Der alte Wert ginge verloren.

Dieses Modul scheitert mit H4010:

```hilde fails H4010
module body Example is
    record Ticket: Linear is
        number: Int32;
    end;

    function redeem(ticket: Ticket): Int32 is
        let { number: Int32 } := ticket;
        return number;
    end;

    function main(): ExitCode is
        var ticket: Ticket := Ticket(number => 1);
        ticket := Ticket(number => 2);
        printLn(redeem(ticket));
        return ExitSuccess();
    end;
end module body.
```

Die richtige Form:

```hilde
module body Example is
    record Ticket: Linear is
        number: Int32;
    end;

    function redeem(ticket: Ticket): Int32 is
        let { number: Int32 } := ticket;
        return number;
    end;

    function main(): ExitCode is
        var ticket: Ticket := Ticket(number => 1);
        printLn(redeem(ticket));
        ticket := Ticket(number => 2);
        printLn(redeem(ticket));
        return ExitSuccess();
    end;
end module body.
```

### H4012

Meldung:

```text
Linearity Error
The variable `ticket` is not consumed by the time of the return statement. Did you forget to call a destructor, or destructure the contents?
```

Eine lineare Variable ist nicht verbraucht, wenn die Funktion zurückkehrt.

Dieses Modul scheitert mit H4012:

```hilde fails H4012
module body Example is
    record Ticket: Linear is
        number: Int32;
    end;

    function main(): ExitCode is
        let ticket: Ticket := Ticket(number => 7);
        return ExitSuccess();
    end;
end module body.
```

Die richtige Form:

```hilde
module body Example is
    record Ticket: Linear is
        number: Int32;
    end;

    function main(): ExitCode is
        let ticket: Ticket := Ticket(number => 7);
        let { number: Int32 } := ticket;
        printLn(number);
        return ExitSuccess();
    end;
end module body.
```

### H4014

Meldung:

```text
Linearity Error
Cannot assign to a path that ends in a type, `Ticket`, not in the Free universe.
```

Eine Zuweisung an einen Slot schreibt einen Wert eines Typs, der nicht Free
ist. Der alte Wert im Slot ginge verloren, ohne verbraucht zu sein.

Dieses Modul scheitert mit H4014:

```hilde fails H4014
module body Example is
    record Ticket: Linear is
        number: Int32;
    end;

    record Wallet: Linear is
        ticket: Ticket;
    end;

    function main(): ExitCode is
        var wallet: Wallet := Wallet(ticket => Ticket(number => 1));
        wallet.ticket := Ticket(number => 2);
        let { ticket: Ticket } := wallet;
        let { number: Int32 } := ticket;
        printLn(number);
        return ExitSuccess();
    end;
end module body.
```

Die richtige Form:

```hilde
module body Example is
    record Ticket: Linear is
        number: Int32;
    end;

    record Wallet: Linear is
        ticket: Ticket;
    end;

    function main(): ExitCode is
        let wallet: Wallet := Wallet(ticket => Ticket(number => 1));
        let { ticket: Ticket } := wallet;
        let { number: Int32 } := ticket;
        let replaced: Wallet := Wallet(ticket => Ticket(number => number + 1));
        let { ticket as fresh: Ticket } := replaced;
        let { number as last: Int32 } := fresh;
        printLn(last);
        return ExitSuccess();
    end;
end module body.
```

### H4015

Meldung:

```text
Linearity Error
The variable `box` is consumed in one branch of an if expression and not in the other, so one path leaves it unconsumed.

Consume it in both branches, or write the if as a statement whose branches each consume it.
```

Von einem if-Ausdruck läuft ein Zweig.  Eine lineare Variable, die nur
ein Zweig verbraucht, bleibt auf dem anderen Weg unverbraucht.  Beide
Zweige verbrauchen sie, oder sie wird vor dem if verbraucht.

Dieses Modul scheitert mit H4015:

```hilde fails H4015
module body Example is
    record Box: Linear is
        content: Int32;
    end;

    function open(box: Box): Int32 is
        let { content: Int32 } := box;
        return content;
    end;

    function main(): ExitCode is
        let box: Box := Box(content => 7);
        let full: Bool := true;
        let value: Int32 := if full then open(box) else 0;
        printLn(value);
        return ExitSuccess();
    end;
end module body.
```

Die richtige Form:

```hilde
module body Example is
    record Box: Linear is
        content: Int32;
    end;

    function open(box: Box): Int32 is
        let { content: Int32 } := box;
        return content;
    end;

    function main(): ExitCode is
        let box: Box := Box(content => 7);
        let full: Bool := true;
        let content: Int32 := open(box);
        let value: Int32 := if full then content else 0;
        printLn(value);
        return ExitSuccess();
    end;
end module body.
```

## 4. Borrowing

### H3002

Meldung:

```text
Type Error
The argument of a task holds a reference or a span.

A task can outlive the borrow the reference comes from, so what is handed to `Standard.Task.spawn` must own everything it points at.  Move the value in, or copy what the task needs.
```

Eine Referenz oder ein Span wird an einen Task übergeben. Ein Task kann
länger leben als die Ausleihe, aus der die Referenz stammt; sein Argument
besitzt deshalb alles, worauf es zeigt.

Dieses Modul scheitert mit H3002:

```hilde fails H3002
import Standard.Task (Scope, openScope, closeScope, Task, spawn, join);

module body Example is
    generic [R: Region]
    function read(n: &[Index, R]): Index is
        return !n;
    end;

    function main(): ExitCode is
        let n: Index := 5;
        case openScope() of
            when Some(value as opened: Scope) do
                var scope: Scope := opened;
                borrow r: &[Index, rho] := &n do
                    let work: Fn[&[Index, rho], Index] := read;
                    case spawn(&!scope, work, r) of
                        when Right(right as task: Task[Index]) do
                            printLn(join(task));
                        when Left(left as back: &[Index, rho]) do
                            printLn(0);
                    end case;
                end borrow;
                closeScope(scope);
            when None do
                skip;
        end case;
        return ExitSuccess();
    end;
end module body.
```

Die richtige Form:

```hilde
import Standard.Task (Scope, openScope, closeScope, Task, spawn, join);

module body Example is
    function double(n: Index): Index is
        return n * 2;
    end;

    function main(): ExitCode is
        let n: Index := 5;
        case openScope() of
            when Some(value as opened: Scope) do
                var scope: Scope := opened;
                let work: Fn[Index, Index] := double;
                case spawn(&!scope, work, n) of
                    when Right(right as task: Task[Index]) do
                        printLn(join(task));
                    when Left(left as back: Index) do
                        printLn(back);
                end case;
                closeScope(scope);
            when None do
                skip;
        end case;
        return ExitSuccess();
    end;
end module body.
```

### H3005

Meldung:

```text
Type Error
The type `Point` is not a reference.
```

Der Pfeil -> liest einen Slot über eine Referenz, und der Wert davor ist
keine Referenz. Einen Slot eines Record-Werts liest man mit einem Punkt.

Dieses Modul scheitert mit H3005:

```hilde fails H3005
module body Example is
    record Point: Free is
        x: Int32;
    end;

    function main(): ExitCode is
        let p: Point := Point(x => 1);
        printLn(p->x);
        return ExitSuccess();
    end;
end module body.
```

Die richtige Form:

```hilde
module body Example is
    record Point: Free is
        x: Int32;
    end;

    function main(): ExitCode is
        let p: Point := Point(x => 1);
        printLn(p.x);
        return ExitSuccess();
    end;
end module body.
```

### H3018

Meldung:

```text
Type Error
Cannot borrow the variable `counter` mutably because the variable is immutable.
```

Eine mit let gebundene Variable wird zum Schreiben ausgeliehen. Eine
Variable, die zum Schreiben ausgeliehen wird, wird mit var gebunden.

Dieses Modul scheitert mit H3018:

```hilde fails H3018
module body Example is
    record Counter: Linear is
        count: Int32;
    end;

    generic [R: Region]
    function bump(counter: &![Counter, R]): Unit is
        counter->count := counter->count + 1;
        return nil;
    end;

    function main(): ExitCode is
        let counter: Counter := Counter(count => 0);
        bump(&!counter);
        let { count: Int32 } := counter;
        printLn(count);
        return ExitSuccess();
    end;
end module body.
```

Die richtige Form:

```hilde
module body Example is
    record Counter: Linear is
        count: Int32;
    end;

    generic [R: Region]
    function bump(counter: &![Counter, R]): Unit is
        counter->count := counter->count + 1;
        return nil;
    end;

    function main(): ExitCode is
        var counter: Counter := Counter(count => 0);
        bump(&!counter);
        let { count: Int32 } := counter;
        printLn(count);
        return ExitSuccess();
    end;
end module body.
```

### H3019

Meldung:

```text
Type Error
Cannot borrow the variable `counter` mutably because it is a function parameter, and therefore immutable.
You can move it to a mutable local variable: `var mut_counter: Counter := counter;`
```

Ein Parameter einer Funktion wird zum Schreiben ausgeliehen. Parameter
lassen sich nicht ändern; man übernimmt den Wert zuerst in ein var, wie die
Meldung vorschlägt.

Dieses Modul scheitert mit H3019:

```hilde fails H3019
module body Example is
    record Counter: Linear is
        count: Int32;
    end;

    generic [R: Region]
    function bump(counter: &![Counter, R]): Unit is
        counter->count := counter->count + 1;
        return nil;
    end;

    function bumped(counter: Counter): Counter is
        bump(&!counter);
        return counter;
    end;

    function main(): ExitCode is
        let counter: Counter := bumped(Counter(count => 0));
        let { count: Int32 } := counter;
        printLn(count);
        return ExitSuccess();
    end;
end module body.
```

Die richtige Form:

```hilde
module body Example is
    record Counter: Linear is
        count: Int32;
    end;

    generic [R: Region]
    function bump(counter: &![Counter, R]): Unit is
        counter->count := counter->count + 1;
        return nil;
    end;

    function bumped(counter: Counter): Counter is
        var mut_counter: Counter := counter;
        bump(&!mut_counter);
        return mut_counter;
    end;

    function main(): ExitCode is
        let counter: Counter := bumped(Counter(count => 0));
        let { count: Int32 } := counter;
        printLn(count);
        return ExitSuccess();
    end;
end module body.
```

### H3026

Meldung:

```text
Type Error
Cannot cast a reference to one with a different underlying type.
```

Eine Schreib-Referenz wird mit Doppelpunkt in eine Lese-Referenz eines
anderen Typs oder einer anderen Region umgewandelt. Die Umwandlung behält
beides bei.

Dieses Modul scheitert mit H3026:

```hilde fails H3026
module body Example is
    record Account: Linear is
        balance: Int64;
    end;

    generic [R: Region]
    function peek(account: &![Account, R]): Int64 is
        let r: &[Int64, R] := account : &[Int64, R];
        return !r;
    end;

    function main(): ExitCode is
        var account: Account := Account(balance => 5);
        printLn(peek(&!account));
        let { balance: Int64 } := account;
        printLn(balance);
        return ExitSuccess();
    end;
end module body.
```

Die richtige Form:

```hilde
module body Example is
    record Account: Linear is
        balance: Int64;
    end;

    generic [R: Region]
    function peek(account: &![Account, R]): Int64 is
        let r: &[Account, R] := account : &[Account, R];
        return r->balance;
    end;

    function main(): ExitCode is
        var account: Account := Account(balance => 5);
        printLn(peek(&!account));
        let { balance: Int64 } := account;
        printLn(balance);
        return ExitSuccess();
    end;
end module body.
```

### H3028

Meldung:

```text
Type Error
Write references can only be casted to a read reference.
```

Eine Schreib-Referenz wird mit Doppelpunkt in etwas umgewandelt, das keine
Lese-Referenz ist.

Dieses Modul scheitert mit H3028:

```hilde fails H3028
module body Example is
    record Account: Linear is
        balance: Int64;
    end;

    generic [R: Region]
    function peek(account: &![Account, R]): Int64 is
        let n: Int64 := account : Int64;
        return n;
    end;

    function main(): ExitCode is
        var account: Account := Account(balance => 5);
        printLn(peek(&!account));
        let { balance: Int64 } := account;
        printLn(balance);
        return ExitSuccess();
    end;
end module body.
```

Die richtige Form:

```hilde
module body Example is
    record Account: Linear is
        balance: Int64;
    end;

    generic [R: Region]
    function peek(account: &![Account, R]): Int64 is
        let n: Int64 := account->balance;
        return n;
    end;

    function main(): ExitCode is
        var account: Account := Account(balance => 5);
        printLn(peek(&!account));
        let { balance: Int64 } := account;
        printLn(balance);
        return ExitSuccess();
    end;
end module body.
```

### H3032

Meldung:

```text
Type Error
Only references can be dereferenced, but `Int32` is not.
```

Der Operator ! liest den Wert hinter einer Referenz und steht hier an etwas,
das keine Referenz ist.

Dieses Modul scheitert mit H3032:

```hilde fails H3032
module body Example is
    function main(): ExitCode is
        let n: Int32 := 5;
        printLn(!n);
        return ExitSuccess();
    end;
end module body.
```

Die richtige Form:

```hilde
module body Example is
    function main(): ExitCode is
        let n: Int32 := 5;
        borrow r: &[Int32, R] := &n do
            printLn(!r);
        end borrow;
        return ExitSuccess();
    end;
end module body.
```

### H3066

Meldung:

```text
Type Error
The argument of a task in a lending scope holds a reference of another region.

A task started with `Standard.Task.spawnLending` may be lent only what the scope's own borrow lends -- the region the scope was opened for -- because only that borrow is sure to outlive the task.
```

Ein Task eines Lending-Scopes bekommt eine Referenz aus einer anderen
Ausleihe als der, aus der der Scope verleiht. Diese andere Ausleihe kann
enden, bevor der Scope geschlossen ist.

Dieses Modul scheitert mit H3066:

```hilde fails H3066
import Standard.Task (Lending, openLending, closeLending, Task, spawnLending, join);

module body Example is
    generic [R: Region]
    function read(n: &[Index, R]): Index is
        return !n;
    end;

    function main(): ExitCode is
        let outer: Index := 1;
        let inner: Index := 2;
        borrow o: &[Index, rho] := &outer do
            case openLending(o) of
                when Some(value as opened: Lending[rho]) do
                    var scope: Lending[rho] := opened;
                    borrow i: &[Index, sigma] := &inner do
                        let work: Fn[&[Index, sigma], Index] := read;
                        case spawnLending(&!scope, work, i) of
                            when Right(right as task: Task[Index]) do
                                printLn(join(task));
                            when Left(left as back: &[Index, sigma]) do
                                printLn(0);
                        end case;
                    end borrow;
                    closeLending(scope);
                when None do
                    skip;
            end case;
        end borrow;
        return ExitSuccess();
    end;
end module body.
```

Die richtige Form:

```hilde
import Standard.Task (Lending, openLending, closeLending, Task, spawnLending, join);

module body Example is
    generic [R: Region]
    function read(n: &[Index, R]): Index is
        return !n;
    end;

    function main(): ExitCode is
        let outer: Index := 1;
        borrow o: &[Index, rho] := &outer do
            case openLending(o) of
                when Some(value as opened: Lending[rho]) do
                    var scope: Lending[rho] := opened;
                    let work: Fn[&[Index, rho], Index] := read;
                    case spawnLending(&!scope, work, o) of
                        when Right(right as task: Task[Index]) do
                            printLn(join(task));
                        when Left(left as back: &[Index, rho]) do
                            printLn(0);
                    end case;
                    closeLending(scope);
                when None do
                    skip;
            end case;
        end borrow;
        return ExitSuccess();
    end;
end module body.
```

### H3067

Meldung:

```text
Type Error
The argument of a task in a lending scope holds a write reference or a mutable span.

Tasks of a lending scope may only read what they are lent; two tasks holding the same thing to write would each see the other's half-done change.
```

Ein Task eines Lending-Scopes bekommt eine Schreib-Referenz. Tasks eines
Lending-Scopes dürfen nur lesen, was ihnen geliehen wird.

Dieses Modul scheitert mit H3067:

```hilde fails H3067
import Standard.Task (Lending, openLending, closeLending, Task, spawnLending, join);

module body Example is
    generic [R: Region]
    function read(n: &![Index, R]): Index is
        return !n;
    end;

    function main(): ExitCode is
        let anchor: Index := 1;
        var value: Index := 2;
        borrow a: &[Index, rho] := &anchor do
            case openLending(a) of
                when Some(value as opened: Lending[rho]) do
                    var scope: Lending[rho] := opened;
                    borrow w: &![Index, sigma] := &!value do
                        let work: Fn[&![Index, sigma], Index] := read;
                        case spawnLending(&!scope, work, w) of
                            when Right(right as task: Task[Index]) do
                                printLn(join(task));
                            when Left(left as back: &![Index, sigma]) do
                                printLn(0);
                        end case;
                    end borrow;
                    closeLending(scope);
                when None do
                    skip;
            end case;
        end borrow;
        return ExitSuccess();
    end;
end module body.
```

Die richtige Form:

```hilde
import Standard.Task (Lending, openLending, closeLending, Task, spawnLending, join);

module body Example is
    generic [R: Region]
    function read(n: &[Index, R]): Index is
        return !n;
    end;

    function main(): ExitCode is
        let anchor: Index := 1;
        borrow a: &[Index, rho] := &anchor do
            case openLending(a) of
                when Some(value as opened: Lending[rho]) do
                    var scope: Lending[rho] := opened;
                    let work: Fn[&[Index, rho], Index] := read;
                    case spawnLending(&!scope, work, a) of
                        when Right(right as task: Task[Index]) do
                            printLn(join(task));
                        when Left(left as back: &[Index, rho]) do
                            printLn(0);
                    end case;
                    closeLending(scope);
                when None do
                    skip;
            end case;
        end borrow;
        return ExitSuccess();
    end;
end module body.
```

### H3068

Meldung:

```text
Type Error
The argument of a task in a lending scope is of a type variable's type.

What a type variable stands for is not known where `Standard.Task.spawnLending` is called, so it cannot be checked for references of another region.  Call it where the argument's type is written out.
```

Ein Task eines Lending-Scopes wird mit einem Argument gestartet, dessen Typ
eine Typvariable ist. Wofür sie steht, ist dort, wo der Task startet, nicht
bekannt; die Regionen lassen sich dort nicht prüfen.

Dieses Modul scheitert mit H3068:

```hilde fails H3068
import Standard.Task (Lending, openLending, closeLending, Task, spawnLending, join);

module body Example is
    generic [R: Region]
    function read(n: &[Index, R]): Index is
        return !n;
    end;

    generic [T: Free, R: Region, S: Region]
    function start(scope: &![Lending[R], S], work: Fn[T, Index], argument: T): Index is
        case spawnLending(scope, work, argument) of
            when Right(right as task: Task[Index]) do
                return join(task);
            when Left(left as back: T) do
                return 0;
        end case;
    end;

    function main(): ExitCode is
        let n: Index := 5;
        borrow w: &[Index, rho] := &n do
            case openLending(w) of
                when Some(value as opened: Lending[rho]) do
                    var scope: Lending[rho] := opened;
                    let work: Fn[&[Index, rho], Index] := read;
                    printLn(start(&!scope, work, w));
                    closeLending(scope);
                when None do
                    skip;
            end case;
        end borrow;
        return ExitSuccess();
    end;
end module body.
```

Die richtige Form:

```hilde
import Standard.Task (Lending, openLending, closeLending, Task, spawnLending, join);

module body Example is
    generic [R: Region]
    function read(n: &[Index, R]): Index is
        return !n;
    end;

    generic [R: Region, S: Region]
    function start(scope: &![Lending[R], S], work: Fn[&[Index, R], Index], argument: &[Index, R]): Index is
        case spawnLending(scope, work, argument) of
            when Right(right as task: Task[Index]) do
                return join(task);
            when Left(left as back: &[Index, R]) do
                return 0;
        end case;
    end;

    function main(): ExitCode is
        let n: Index := 5;
        borrow w: &[Index, rho] := &n do
            case openLending(w) of
                when Some(value as opened: Lending[rho]) do
                    var scope: Lending[rho] := opened;
                    let work: Fn[&[Index, rho], Index] := read;
                    printLn(start(&!scope, work, w));
                    closeLending(scope);
                when None do
                    skip;
            end case;
        end borrow;
        return ExitSuccess();
    end;
end module body.
```

### H3069

Meldung:

```text
Type Error
The argument of a task holds a lending scope.

A task that held the scope could keep it open after the borrow it lends from has ended.  Close the scope where it was opened.
```

Ein Lending-Scope wird an einen Task eines anderen Lending-Scopes übergeben.
Ein Task, der einen Scope hält, könnte ihn offen halten, nachdem seine
Ausleihe geendet hat; ein Scope wird dort geschlossen, wo er geöffnet wurde.

Dieses Modul scheitert mit H3069:

```hilde fails H3069
import Standard.Task (Lending, openLending, closeLending, Task, spawnLending, join);

module body Example is
    generic [R: Region]
    function finish(scope: Lending[R]): Unit is
        closeLending(scope);
        return nil;
    end;

    function main(): ExitCode is
        let n: Index := 5;
        borrow w: &[Index, rho] := &n do
            case openLending(w) of
                when Some(value as opened: Lending[rho]) do
                    var scope: Lending[rho] := opened;
                    case openLending(w) of
                        when Some(value as other: Lending[rho]) do
                            let work: Fn[Lending[rho], Unit] := finish;
                            case spawnLending(&!scope, work, other) of
                                when Right(right as task: Task[Unit]) do
                                    let done: Unit := join(task);
                                when Left(left as back: Lending[rho]) do
                                    closeLending(back);
                            end case;
                        when None do
                            skip;
                    end case;
                    closeLending(scope);
                when None do
                    skip;
            end case;
        end borrow;
        return ExitSuccess();
    end;
end module body.
```

Die richtige Form:

```hilde
import Standard.Task (Lending, openLending, closeLending);

module body Example is
    function main(): ExitCode is
        let n: Index := 5;
        borrow w: &[Index, rho] := &n do
            case openLending(w) of
                when Some(value as opened: Lending[rho]) do
                    case openLending(w) of
                        when Some(value as other: Lending[rho]) do
                            closeLending(other);
                        when None do
                            skip;
                    end case;
                    closeLending(opened);
                when None do
                    skip;
            end case;
        end borrow;
        return ExitSuccess();
    end;
end module body.
```

### H3070

Meldung:

```text
Type Error
The argument of a task holds a lending scope.

A task that held the scope could keep it open after the borrow it lends from has ended.  Close the scope where it was opened.
```

Ein Lending-Scope wird an einen Task eines gewöhnlichen Scopes übergeben.
Der Task könnte den Lending-Scope offen halten, nachdem die Ausleihe, aus
der er verleiht, geendet hat.

Dieses Modul scheitert mit H3070:

```hilde fails H3070
import Standard.Task (Scope, openScope, closeScope, Lending, openLending, closeLending, Task, spawn, join);

module body Example is
    generic [R: Region]
    function finish(scope: Lending[R]): Unit is
        closeLending(scope);
        return nil;
    end;

    function main(): ExitCode is
        let n: Index := 5;
        case openScope() of
            when Some(value as opened: Scope) do
                var plain: Scope := opened;
                borrow w: &[Index, rho] := &n do
                    case openLending(w) of
                        when Some(value as lending: Lending[rho]) do
                            let work: Fn[Lending[rho], Unit] := finish;
                            case spawn(&!plain, work, lending) of
                                when Right(right as task: Task[Unit]) do
                                    let done: Unit := join(task);
                                when Left(left as back: Lending[rho]) do
                                    closeLending(back);
                            end case;
                        when None do
                            skip;
                    end case;
                end borrow;
                closeScope(plain);
            when None do
                skip;
        end case;
        return ExitSuccess();
    end;
end module body.
```

Die richtige Form:

```hilde
import Standard.Task (Scope, openScope, closeScope, Lending, openLending, closeLending);

module body Example is
    function main(): ExitCode is
        let n: Index := 5;
        case openScope() of
            when Some(value as opened: Scope) do
                borrow w: &[Index, rho] := &n do
                    case openLending(w) of
                        when Some(value as lending: Lending[rho]) do
                            closeLending(lending);
                        when None do
                            skip;
                    end case;
                end borrow;
                closeScope(opened);
            when None do
                skip;
        end case;
        return ExitSuccess();
    end;
end module body.
```

### H4006

Meldung:

```text
Linearity Error
The variable `ticket` cannot be consumed while it is borrowed (immutably).
```

Eine Variable wird verbraucht, während sie zum Lesen ausgeliehen ist.

Dieses Modul scheitert mit H4006:

```hilde fails H4006
module body Example is
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

Die richtige Form:

```hilde
module body Example is
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

### H4007

Meldung:

```text
Linearity Error
The variable `ticket` cannot be consumed while it is borrowed (mutably).
```

Eine Variable wird verbraucht, während sie zum Schreiben ausgeliehen ist.

Dieses Modul scheitert mit H4007:

```hilde fails H4007
module body Example is
    record Ticket: Linear is
        number: Int32;
    end;

    function redeem(ticket: Ticket): Int32 is
        let { number: Int32 } := ticket;
        return number;
    end;

    function main(): ExitCode is
        var ticket: Ticket := Ticket(number => 7);
        borrow view: &![Ticket, R] := &!ticket do
            printLn(redeem(ticket));
        end borrow;
        return ExitSuccess();
    end;
end module body.
```

Die richtige Form:

```hilde
module body Example is
    record Ticket: Linear is
        number: Int32;
    end;

    function redeem(ticket: Ticket): Int32 is
        let { number: Int32 } := ticket;
        return number;
    end;

    function main(): ExitCode is
        var ticket: Ticket := Ticket(number => 7);
        borrow view: &![Ticket, R] := &!ticket do
            printLn(view->number);
        end borrow;
        printLn(redeem(ticket));
        return ExitSuccess();
    end;
end module body.
```

### H4011

Meldung:

```text
Linearity Error
Cannot borrow (immutably) the variable `ticket` because it is already consumed.
```

Eine Variable wird ausgeliehen, die schon verbraucht ist oder deren Zustand
diese Art des Ausleihens nicht zulässt.

Dieses Modul scheitert mit H4011:

```hilde fails H4011
module body Example is
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
        borrow view: &[Ticket, R] := &ticket do
            printLn(view->number);
        end borrow;
        return ExitSuccess();
    end;
end module body.
```

Die richtige Form:

```hilde
module body Example is
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

### H4013

Meldung:

```text
Linearity Error
Cannot dereference non-free type `Ticket`
```

Der Operator ! liest den Wert hinter einer Referenz auf einen Typ, der nicht
Free ist. Das Lesen würde einen linearen Wert kopieren.

Dieses Modul scheitert mit H4013:

```hilde fails H4013
module body Example is
    record Ticket: Linear is
        number: Int32;
    end;

    function main(): ExitCode is
        let ticket: Ticket := Ticket(number => 7);
        borrow view: &[Ticket, R] := &ticket do
            let copy: Ticket := !view;
            let { number: Int32 } := copy;
            printLn(number);
        end borrow;
        let { number: Int32 } := ticket;
        return ExitSuccess();
    end;
end module body.
```

Die richtige Form:

```hilde
module body Example is
    record Ticket: Linear is
        number: Int32;
    end;

    function main(): ExitCode is
        let ticket: Ticket := Ticket(number => 7);
        borrow view: &[Ticket, R] := &ticket do
            printLn(view->number);
        end borrow;
        let { number: Int32 } := ticket;
        return ExitSuccess();
    end;
end module body.
```

### H6043

Meldung:

```text
Generic Error
The head of a reference transform expression must be of a reference type, but I got `Point`.

A path into a value is borrowed through a reference to the whole value: write a function that takes `r: &[T, R]` and returns `&(r->slot)`, and call it with `&value`.
```

Eine Referenz-Transformation &( ... ) nimmt einen Pfad, dessen Kopf keine
Referenz ist. Der Kopf ist eine Referenz, und der Pfad geht mit einem Pfeil
weiter.

Dieses Modul scheitert mit H6043:

```hilde fails H6043
module body Example is
    record Point: Free is
        x: Int32;
    end;

    function main(): ExitCode is
        let p: Point := Point(x => 1);
        let r: &[Int32, Static] := &(p.x);
        printLn(!r);
        return ExitSuccess();
    end;
end module body.
```

Die richtige Form:

```hilde
module body Example is
    record Point: Free is
        x: Int32;
    end;

    function main(): ExitCode is
        let p: Point := Point(x => 1);
        borrow q: &[Point, R] := &p do
            let r: &[Int32, R] := &(q->x);
            printLn(!r);
        end borrow;
        return ExitSuccess();
    end;
end module body.
```

### H6054

Meldung:

```text
Generic Error
Can't assign: lvalue is not a mutable reference: &[Int32, Region<17>]
```

Eine Zuweisung schreibt über eine Lese-Referenz, die in einer var steht.
Ändern lässt sich nur über eine Schreib-Referenz: zum Schreiben ausleihen
und die Schreib-Referenz in die var legen.

Dieses Modul scheitert mit H6054:

```hilde fails H6054
module body Example is
    record Point: Free is
        x: Int32;
    end;

    function main(): ExitCode is
        let p: Point := Point(x => 1);
        borrow q: &[Point, R] := &p do
            var r: &[Point, R] := q;
            r->x := 0;
        end borrow;
        printLn(p.x);
        return ExitSuccess();
    end;
end module body.
```

Die richtige Form:

```hilde
module body Example is
    record Point: Free is
        x: Int32;
    end;

    function main(): ExitCode is
        var p: Point := Point(x => 1);
        borrow q: &![Point, R] := &!p do
            var r: &![Point, R] := q;
            r->x := 0;
        end borrow;
        printLn(p.x);
        return ExitSuccess();
    end;
end module body.
```

### H6055

Meldung:

```text
Generic Error
Cannot reborrow something that is not a mutable reference: Point
```

Eine borrow-Anweisung leiht mit &~ eine Variable weiter, die keine
Schreib-Referenz ist.

Dieses Modul scheitert mit H6055:

```hilde fails H6055
module body Example is
    record Point: Free is
        x: Int32;
    end;

    function main(): ExitCode is
        var p: Point := Point(x => 1);
        borrow r: &![Point, R] := &~p do
            printLn(r->x);
        end borrow;
        return ExitSuccess();
    end;
end module body.
```

Die richtige Form:

```hilde
module body Example is
    record Point: Free is
        x: Int32;
    end;

    function main(): ExitCode is
        var p: Point := Point(x => 1);
        borrow r: &![Point, R] := &!p do
            printLn(r->x);
        end borrow;
        return ExitSuccess();
    end;
end module body.
```

### H6059

Meldung:

```text
Generic Error
`digits` is a constant of the module, and an index or a slot is taken through a variable, which a constant is not. Bind the constant to a local first, as in `let local: T := digits;`, and index the local.
```

Index und Feld werden über eine Ausleihe einer Variablen gelesen, und
eine Konstante ist keine Variable.  Die Konstante wird zuerst an eine
lokale Variable gebunden, und diese wird indiziert.

Dieses Modul scheitert mit H6059:

```hilde fails H6059
module body Example is
    constant digits: Span[Nat8, Static] := "0123456789";

    function main(): ExitCode is
        printLn(digits[1]);
        return ExitSuccess();
    end;
end module body.
```

Die richtige Form:

```hilde
module body Example is
    constant digits: Span[Nat8, Static] := "0123456789";

    function main(): ExitCode is
        let text: Span[Nat8, Static] := digits;
        printLn(text[1]);
        return ExitSuccess();
    end;
end module body.
```

## 5. Module

### H2001

Meldung:

```text
Declaration Error
The interface requires `limit` to be a constant
```

Der Body definiert einen Namen des Interfaces als eine andere Art von
Deklaration, etwa als Funktion, wo das Interface eine Konstante deklariert.

Dieses Modul scheitert mit H2001:

```hilde fails H2001
module body Example is
    function limit(): Int32 is
        return 5;
    end;

    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Daneben `Example.hih`:

```hilde file Example.hih
module Example is
    constant limit: Int32;

    function main(): ExitCode;
end module.
```

Die richtige Form:

```hilde
module body Example is
    constant limit: Int32 := 5;

    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Daneben `Example.hih`:

```hilde file Example.hih
module Example is
    constant limit: Int32;

    function main(): ExitCode;
end module.
```

### H2002

Meldung:

```text
Declaration Error
The interface declaration for `twice` and its implementation have different parameters.
```

Eine Funktion hat im Interface andere Typparameter, Parameter oder einen
anderen Rückgabetyp als im Body. Die Meldung sagt, was sich unterscheidet.

Dieses Modul scheitert mit H2002:

```hilde fails H2002
module body Example is
    function twice(n: Int64): Int64 is
        return n * 2;
    end;

    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Daneben `Example.hih`:

```hilde file Example.hih
module Example is
    function twice(n: Int32): Int32;

    function main(): ExitCode;
end module.
```

Die richtige Form:

```hilde
module body Example is
    function twice(n: Int32): Int32 is
        return n * 2;
    end;

    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Daneben `Example.hih`:

```hilde file Example.hih
module Example is
    function twice(n: Int32): Int32;

    function main(): ExitCode;
end module.
```

### H2004

Meldung:

```text
Declaration Error
`twice` has no corresponding body implementation.
```

Das Interface deklariert etwas, das der Body nicht definiert.

Dieses Modul scheitert mit H2004:

```hilde fails H2004
module body Example is
    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Daneben `Example.hih`:

```hilde file Example.hih
module Example is
    function twice(n: Int32): Int32;

    function main(): ExitCode;
end module.
```

Die richtige Form:

```hilde
module body Example is
    function twice(n: Int32): Int32 is
        return n * 2;
    end;

    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Daneben `Example.hih`:

```hilde file Example.hih
module Example is
    function twice(n: Int32): Int32;

    function main(): ExitCode;
end module.
```

### H2005

Meldung:

```text
Declaration Error
The instance `Describe` with type `Int32` has no corresponding body implementation.
```

Das Interface deklariert eine Instanz, die der Body nicht definiert.

Dieses Modul scheitert mit H2005:

```hilde fails H2005
module body Example is
    typeclass Describe(T: Free) is
        method describe(value: T): Int32;
    end;

    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Daneben `Example.hih`:

```hilde file Example.hih
module Example is
    typeclass Describe(T: Free) is
        method describe(value: T): Int32;
    end;

    instance Describe(Int32);

    function main(): ExitCode;
end module.
```

Die richtige Form:

```hilde
module body Example is
    instance Describe(Int32) is
        method describe(value: Int32): Int32 is
            return value;
        end;
    end;

    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Daneben `Example.hih`:

```hilde file Example.hih
module Example is
    typeclass Describe(T: Free) is
        method describe(value: T): Int32;
    end;

    instance Describe(Int32);

    function main(): ExitCode;
end module.
```

### H2006

Meldung:

```text
Declaration Error
Module interface and body have different names: `Sample` and `Example`
```

Interface und Body, die auf der Kommandozeile als Paar stehen, nennen
verschiedene Module.

Dieses Modul scheitert mit H2006:

```hilde fails H2006
module body Example is
    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Daneben `Example.hih`:

```hilde file Example.hih
module Sample is
    function main(): ExitCode;
end module.
```

Die richtige Form:

```hilde
module body Example is
    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Daneben `Example.hih`:

```hilde file Example.hih
module Example is
    function main(): ExitCode;
end module.
```

### H2008

Meldung:

```text
Declaration Error
The interface declaration for `limit` and its implementation have different types.
```

Eine Deklaration hat im Interface einen anderen Typ als im Body, etwa eine
Konstante.

Dieses Modul scheitert mit H2008:

```hilde fails H2008
module body Example is
    constant limit: Int64 := 5;

    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Daneben `Example.hih`:

```hilde file Example.hih
module Example is
    constant limit: Int32;

    function main(): ExitCode;
end module.
```

Die richtige Form:

```hilde
module body Example is
    constant limit: Int32 := 5;

    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Daneben `Example.hih`:

```hilde file Example.hih
module Example is
    constant limit: Int32;

    function main(): ExitCode;
end module.
```

### H2009

Meldung:

```text
Declaration Error
The interface declaration for `Ticket` and its implementation have different universes.
```

Ein opaker Typ ist im Interface in einem Universum deklariert und im Body in
einem anderen definiert.

Dieses Modul scheitert mit H2009:

```hilde fails H2009
module body Example is
    record Ticket: Linear is
        number: Int32;
    end;

    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Daneben `Example.hih`:

```hilde file Example.hih
module Example is
    type Ticket: Free;

    function main(): ExitCode;
end module.
```

Die richtige Form:

```hilde
module body Example is
    record Ticket: Linear is
        number: Int32;
    end;

    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Daneben `Example.hih`:

```hilde file Example.hih
module Example is
    type Ticket: Linear;

    function main(): ExitCode;
end module.
```

### H2010

Meldung:

```text
Declaration Error
The module `Example` is unsafe, and this compilation was run with `--forbid-unsafe-modules`.

It is `Example.hiq`, and it carries `pragma Unsafe_Module;`, which is what lets a module hold a foreign function, an `@embed`, or an import from `Hilde.Memory`.

The modules that ship with the compiler are exempt; this applies to the modules named on the command line.
```

Die Übersetzung wurde mit --forbid-unsafe-modules gestartet, und eines ihrer
Module ist unsicher.

Dieses Modul scheitert mit H2010:

```hilde fails H2010
pragma Unsafe_Module;

module body Example is
    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Übersetzt mit:

```sh command
hilde compile Example.hiq --entrypoint=Example:main --output=prog --forbid-unsafe-modules
```

Die richtige Form:

```hilde
module body Example is
    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Übersetzt mit:

```sh command
hilde compile Example.hiq --entrypoint=Example:main --output=prog --forbid-unsafe-modules
```

### H2011

Meldung:

```text
Declaration Error
Invalid Foreign_Import pragma.

This pragma takes exactly one argument, `External_Name`
```

Ein Pragma bekommt die falschen Argumente. Die Meldung sagt, welches
Argument es nimmt oder dass es keines nimmt.

Dieses Modul scheitert mit H2011:

```hilde fails H2011
pragma Unsafe_Module;

module body Example is
    pragma Foreign_Import(Name => "hilde_put_character");
    function putCharacter(character: Nat8): Int32 is
    end;

    function main(): ExitCode is
        putCharacter('a');
        return ExitSuccess();
    end;
end module body.
```

Die richtige Form:

```hilde
pragma Unsafe_Module;

module body Example is
    pragma Foreign_Import(External_Name => "hilde_put_character");
    function putCharacter(character: Nat8): Int32 is
    end;

    function main(): ExitCode is
        putCharacter('a');
        return ExitSuccess();
    end;
end module body.
```

### H2012

Meldung:

```text
Declaration Error
Unknown pragma `Unsafe_Modul`
```

Ein Pragma hat einen Namen, den der Compiler nicht kennt. Die Pragmas heißen
Unsafe_Module, Foreign_Library, Foreign_Header, Foreign_Import und
Foreign_Export.

Dieses Modul scheitert mit H2012:

```hilde fails H2012
pragma Unsafe_Modul;

module body Example is
    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Die richtige Form:

```hilde
pragma Unsafe_Module;

module body Example is
    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

### H2013

Meldung:

```text
Declaration Error
Module `Example` is safe and can't name the C library `m`.

A safe module has no C to link against: it can hold neither a `pragma Foreign_Import` nor an `@embed`. Write `pragma Unsafe_Module;` above `module body`, or take the library declaration out.
```

Ein sicheres Modul nennt eine C-Bibliothek. Nur ein Modul mit pragma
Unsafe_Module hat C, gegen das gelinkt wird.

Dieses Modul scheitert mit H2013:

```hilde fails H2013
pragma Foreign_Library(Name => "m");

module body Example is
    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Die richtige Form:

```hilde
pragma Unsafe_Module;
pragma Foreign_Library(Name => "m");

module body Example is
    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

### H2014

Meldung:

```text
Declaration Error
The name in a `pragma Foreign_Library` must not be empty.

It is a library name, the `z` of `-lz`, not a linker switch.
```

Der Name in pragma Foreign_Library ist leer. Er ist der Name einer
Bibliothek, das z von -lz.

Dieses Modul scheitert mit H2014:

```hilde fails H2014
pragma Unsafe_Module;
pragma Foreign_Library(Name => "");

module body Example is
    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Die richtige Form:

```hilde
pragma Unsafe_Module;
pragma Foreign_Library(Name => "m");

module body Example is
    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

### H2015

Meldung:

```text
Declaration Error
A declaration with the name `twice` already exists in the module `Example`.
```

Ein Modul deklariert denselben Namen zweimal.

Dieses Modul scheitert mit H2015:

```hilde fails H2015
module body Example is
    function twice(n: Int32): Int32 is
        return n * 2;
    end;

    function twice(n: Int64): Int64 is
        return n * 2;
    end;

    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Die richtige Form:

```hilde
module body Example is
    function twice32(n: Int32): Int32 is
        return n * 2;
    end;

    function twice64(n: Int64): Int64 is
        return n * 2;
    end;

    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

### H2016

Meldung:

```text
Declaration Error
A module with the name `Example` already exists.
```

Zwei Module einer Übersetzung haben denselben Namen.

Dieses Modul scheitert mit H2016:

```hilde fails H2016
module body Example is
    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Daneben `Library.hih`:

```hilde file Library.hih
module Example is
    function answer(): Int32;
end module.
```

Daneben `Library.hiq`:

```hilde file Library.hiq
module body Example is
    function answer(): Int32 is
        return 42;
    end;
end module body.
```

Die richtige Form:

```hilde
module body Example is
    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Daneben `Library.hih`:

```hilde file Library.hih
module Library is
    function answer(): Int32;
end module.
```

Daneben `Library.hiq`:

```hilde file Library.hiq
module body Library is
    function answer(): Int32 is
        return 42;
    end;
end module body.
```

### H2017

Meldung:

```text
Declaration Error
Unknown module `Library`.
```

Ein Import nennt ein Modul, das nicht zur Übersetzung gehört.  Trägt ein
Modul der Übersetzung einen Namen, der nur wenige Buchstaben entfernt ist,
fügt die Meldung Did you mean und diesen Namen an.

Dieses Modul scheitert mit H2017:

```hilde fails H2017
import Library (answer);

module body Example is
    function main(): ExitCode is
        printLn(answer());
        return ExitSuccess();
    end;
end module body.
```

Die richtige Form:

```hilde
import Library (answer);

module body Example is
    function main(): ExitCode is
        printLn(answer());
        return ExitSuccess();
    end;
end module body.
```

Daneben `Library.hih`:

```hilde file Library.hih
module Library is
    function answer(): Int32;
end module.
```

Daneben `Library.hiq`:

```hilde file Library.hiq
module body Library is
    function answer(): Int32 is
        return 42;
    end;
end module body.
```

### H2018

Meldung:

```text
Declaration Error
The function `keep` cannot be exported because it is generic over a type.

An exported function may be generic over regions only: a region has nothing to pass at run time.
```

Eine über einen Typ generische Funktion trägt pragma Foreign_Export. C kann
sie nicht aufrufen, weil sie keine einzige feste Form hat. Eine exportierte
Funktion darf nur über Regionen generisch sein: Eine Region übergibt zur
Laufzeit nichts, und die Funktion wird einmal gebaut, für die statische
Region.

Dieses Modul scheitert mit H2018:

```hilde fails H2018
pragma Unsafe_Module;

module body Example is
    pragma Foreign_Export(External_Name => "example_keep");
    generic [T: Free]
    function keep(value: T): T is
        return value;
    end;

    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Die richtige Form:

```hilde
pragma Unsafe_Module;

module body Example is
    pragma Foreign_Export(External_Name => "example_keep");
    function keep(value: Int32): Int32 is
        return value;
    end;

    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

### H2027

Meldung:

```text
Declaration Error
Colliding imports: a declaration with name `question` has already been imported.

Consider giving it a different nickname using `as`, as in `import M (question as otherQuestion);`.
```

Zwei Importe vergeben denselben lokalen Namen. Einer bekommt mit as einen
anderen.

Dieses Modul scheitert mit H2027:

```hilde fails H2027
import Library (answer, question as answer);

module body Example is
    function main(): ExitCode is
        printLn(answer());
        return ExitSuccess();
    end;
end module body.
```

Daneben `Library.hih`:

```hilde file Library.hih
module Library is
    function answer(): Int32;

    function question(): Int32;
end module.
```

Daneben `Library.hiq`:

```hilde file Library.hiq
module body Library is
    function answer(): Int32 is
        return 42;
    end;

    function question(): Int32 is
        return 6;
    end;
end module body.
```

Die richtige Form:

```hilde
import Library (answer, question as ask);

module body Example is
    function main(): ExitCode is
        printLn(answer() * ask());
        return ExitSuccess();
    end;
end module body.
```

Daneben `Library.hih`:

```hilde file Library.hih
module Library is
    function answer(): Int32;

    function question(): Int32;
end module.
```

Daneben `Library.hiq`:

```hilde file Library.hiq
module body Library is
    function answer(): Int32 is
        return 42;
    end;

    function question(): Int32 is
        return 6;
    end;
end module body.
```

### H2028

Meldung:

```text
Declaration Error
Cannot import from the `Hilde.Memory` module in a safe module.

Consider using a safe wrapper or adding `pragma Unsafe_Module;`
```

Ein sicheres Modul importiert aus Hilde.Memory, dessen rohe Zeiger nur
unsichere Module verwenden dürfen.

Dieses Modul scheitert mit H2028:

```hilde fails H2028
import Hilde.Memory (Pointer);

module body Example is
    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Die richtige Form:

```hilde
pragma Unsafe_Module;

import Hilde.Memory (Pointer);

module body Example is
    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

### H2029

Meldung:

```text
Declaration Error
`secret` is private and cannot be imported.
```

Ein Import nennt etwas, das sein Modul nur im Body definiert. Was das
Interface nicht deklariert, ist privat.

Dieses Modul scheitert mit H2029:

```hilde fails H2029
import Library (secret);

module body Example is
    function main(): ExitCode is
        printLn(secret());
        return ExitSuccess();
    end;
end module body.
```

Daneben `Library.hih`:

```hilde file Library.hih
module Library is
    function answer(): Int32;
end module.
```

Daneben `Library.hiq`:

```hilde file Library.hiq
module body Library is
    function answer(): Int32 is
        return secret();
    end;

    function secret(): Int32 is
        return 42;
    end;
end module body.
```

Die richtige Form:

```hilde
import Library (answer);

module body Example is
    function main(): ExitCode is
        printLn(answer());
        return ExitSuccess();
    end;
end module body.
```

Daneben `Library.hih`:

```hilde file Library.hih
module Library is
    function answer(): Int32;
end module.
```

Daneben `Library.hiq`:

```hilde file Library.hiq
module body Library is
    function answer(): Int32 is
        return secret();
    end;

    function secret(): Int32 is
        return 42;
    end;
end module body.
```

### H2030

Meldung:

```text
Declaration Error
No declaration with the name `question` in the module `Library`
```

Ein Import nennt etwas, das sein Modul gar nicht hat.

Dieses Modul scheitert mit H2030:

```hilde fails H2030
import Library (question);

module body Example is
    function main(): ExitCode is
        printLn(question());
        return ExitSuccess();
    end;
end module body.
```

Daneben `Library.hih`:

```hilde file Library.hih
module Library is
    function answer(): Int32;
end module.
```

Daneben `Library.hiq`:

```hilde file Library.hiq
module body Library is
    function answer(): Int32 is
        return 42;
    end;
end module body.
```

Die richtige Form:

```hilde
import Library (answer);

module body Example is
    function main(): ExitCode is
        printLn(answer());
        return ExitSuccess();
    end;
end module body.
```

Daneben `Library.hih`:

```hilde file Library.hih
module Library is
    function answer(): Int32;
end module.
```

Daneben `Library.hiq`:

```hilde file Library.hiq
module body Library is
    function answer(): Int32 is
        return 42;
    end;
end module body.
```

### H2038

Meldung:

```text
Declaration Error
`@embed` pastes C straight into the generated program, and the compiler does not check that C. It is allowed only in a module that says so: write `pragma Unsafe_Module;` above `module body`, or move the `@embed` into a module that already has the pragma.
```

Ein sicheres Modul verwendet @embed, das C einfügt, das der Compiler nicht
prüft. Das darf nur ein Modul mit pragma Unsafe_Module.

Dieses Modul scheitert mit H2038:

```hilde fails H2038
module body Example is
    function main(): ExitCode is
        let n: Int32 := @embed(Int32, "42");
        printLn(n);
        return ExitSuccess();
    end;
end module body.
```

Die richtige Form:

```hilde
pragma Unsafe_Module;

module body Example is
    function main(): ExitCode is
        let n: Int32 := @embed(Int32, "42");
        printLn(n);
        return ExitSuccess();
    end;
end module body.
```

### H2039

Meldung:

```text
Declaration Error
Can't declare a foreign function in a safe module.
```

Ein sicheres Modul bindet mit pragma Foreign_Import eine C-Funktion.

Dieses Modul scheitert mit H2039:

```hilde fails H2039
module body Example is
    pragma Foreign_Import(External_Name => "hilde_put_character");
    function putCharacter(character: Nat8): Int32 is
    end;

    function main(): ExitCode is
        putCharacter('a');
        return ExitSuccess();
    end;
end module body.
```

Die richtige Form:

```hilde
pragma Unsafe_Module;

module body Example is
    pragma Foreign_Import(External_Name => "hilde_put_character");
    function putCharacter(character: Nat8): Int32 is
    end;

    function main(): ExitCode is
        putCharacter('a');
        return ExitSuccess();
    end;
end module body.
```

### H2040

Meldung:

```text
Declaration Error
Foreign functions can't have type parameters.
```

Eine mit Foreign_Import an C gebundene Funktion hat Typparameter. Eine
C-Funktion hat eine einzige feste Signatur.

Dieses Modul scheitert mit H2040:

```hilde fails H2040
pragma Unsafe_Module;

module body Example is
    pragma Foreign_Import(External_Name => "hilde_put_character");
    generic [T: Free]
    function putCharacter(character: T): Int32 is
    end;

    function main(): ExitCode is
        let c: Nat8 := 'a';
        putCharacter(c);
        return ExitSuccess();
    end;
end module body.
```

Die richtige Form:

```hilde
pragma Unsafe_Module;

module body Example is
    pragma Foreign_Import(External_Name => "hilde_put_character");
    function putCharacter(character: Nat8): Int32 is
    end;

    function main(): ExitCode is
        let c: Nat8 := 'a';
        putCharacter(c);
        return ExitSuccess();
    end;
end module body.
```

### H2041

Meldung:

```text
Declaration Error
Only import and export pragmas are allowed inside functions.
```

Vor einer Funktion steht ein anderes Pragma als Foreign_Import oder
Foreign_Export. Modul-Pragmas stehen vor module body.

Dieses Modul scheitert mit H2041:

```hilde fails H2041
module body Example is
    pragma Unsafe_Module;
    function answer(): Int32 is
        return 42;
    end;

    function main(): ExitCode is
        printLn(answer());
        return ExitSuccess();
    end;
end module body.
```

Die richtige Form:

```hilde
pragma Unsafe_Module;

module body Example is
    function answer(): Int32 is
        return 42;
    end;

    function main(): ExitCode is
        printLn(answer());
        return ExitSuccess();
    end;
end module body.
```

### H2042

Meldung:

```text
Declaration Error
Module `Example` is safe and can't name the C header `sys/utsname.h`.

A header gives C's own constants to an `@embed`, and a safe module can hold none. Write `pragma Unsafe_Module;` above `module body`, or take the header declaration out.
```

Ein sicheres Modul nennt mit pragma Foreign_Header einen C-Header.

Dieses Modul scheitert mit H2042:

```hilde fails H2042
pragma Foreign_Header(Name => "sys/utsname.h");

module body Example is
    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Die richtige Form:

```hilde
pragma Unsafe_Module;
pragma Foreign_Header(Name => "sys/utsname.h");

module body Example is
    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

### H2043

Meldung:

```text
Declaration Error
The name in a `pragma Foreign_Header` is not a header name: `../secret.h`

It is what stands between the angle brackets of an `#include`, such as `openssl/evp.h`: letters, digits and `_ . / + -`, not empty, not starting with a slash, and without a `..` part.
```

Der Name in pragma Foreign_Header ist kein Header-Name. Er ist das, was
zwischen den spitzen Klammern eines include steht: Buchstaben, Ziffern und _
. / + -, nicht mit einem Schrägstrich am Anfang und ohne einen Teil ..

Dieses Modul scheitert mit H2043:

```hilde fails H2043
pragma Unsafe_Module;
pragma Foreign_Header(Name => "../secret.h");

module body Example is
    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Die richtige Form:

```hilde
pragma Unsafe_Module;
pragma Foreign_Header(Name => "sys/utsname.h");

module body Example is
    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

### H2044

Meldung:

```text
Declaration Error
This programme links both `sqlite3` and `sqlcipher`, which export the same functions.

Import `Standard.Sqlite` or `Standard.SqlCipher`, not both.  The module that brought the second one is `Bindings.C.SqlCipher`.
```

Ein Programm importiert sowohl Standard.Sqlite als auch Standard.SqlCipher.
Die beiden C-Bibliotheken exportieren dieselben Funktionen; ein Programm
linkt deshalb nur eine davon.

Dieses Modul scheitert mit H2044:

```hilde fails H2044
import Standard.Sqlite (Connection);
import Standard.SqlCipher (Connection as CipherConnection);

module body Example is
    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Die richtige Form:

```hilde
import Standard.Sqlite (Connection);

module body Example is
    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

### H2045

Meldung:

```text
Declaration Error
`Example` imports from `Bindings.Time`, a module that binds C.

Only the standard library imports a module whose name begins with `Bindings.`; a program imports the safe module built on it, whose name begins with `Standard.`.
```

Ein Programm importiert ein Modul, dessen Name mit Bindings. beginnt. Ein
solches Modul bindet C an und ist unsafe; was seinen Aufruf sicher macht,
prüft das Standard-Modul darüber, und das importiert ein Programm. Nur ein
Modul, dessen Name mit Standard. oder Bindings. beginnt, darf es
importieren.

Dieses Modul scheitert mit H2045:

```hilde fails H2045
import Bindings.Time (wallNanos);

module body Example is
    function main(): ExitCode is
        printLn(wallNanos() > 0);
        return ExitSuccess();
    end;
end module body.
```

Die richtige Form:

```hilde
import Standard.Time (wallNanos);

module body Example is
    function main(): ExitCode is
        printLn(wallNanos() > 0);
        return ExitSuccess();
    end;
end module body.
```

### H2050

Meldung:

```text
Declaration Error
The function `keep` cannot be exported under the name `hilde_keep`: names beginning with hilde_ belong to the runtime.
```

Der Name, unter dem eine Funktion exportiert wird, ist einer, den C ihr
nicht geben kann: kein C-Bezeichner, ein Schlüsselwort von C oder main, ein
Name, der mit hilde_ beginnt und den die Laufzeit für sich behält, oder ein
Name, unter dem schon eine andere Funktion exportiert wird.

Dieses Modul scheitert mit H2050:

```hilde fails H2050
module body Example is
    pragma Foreign_Export(External_Name => "hilde_keep");
    function keep(value: Int32): Int32 is
        return value;
    end;

    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Die richtige Form:

```hilde
module body Example is
    pragma Foreign_Export(External_Name => "example_keep");
    function keep(value: Int32): Int32 is
        return value;
    end;

    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

### H2059

Meldung:

```text
Declaration Error
A foreign function can't return `Bool`. C gives a truth value as an int, and a Bool would keep only its lowest byte, so 256 would be false.

Import the C result as `Int32` and compare it with `/= 0`.
```

Eine mit Foreign_Import an C gebundene Funktion gibt Bool zurück.  Eine
C-Funktion gibt einen Wahrheitswert als int, der für wahr jeder Wert außer 0
sein kann, und das erzeugte C liest davon nur das unterste Byte: isalpha der
glibc antwortet für einen Buchstaben 1024, dessen unterstes Byte 0 ist.  Das
Ergebnis von C wird als Int32 importiert und in Hilde mit /= 0 verglichen.

Dieses Modul scheitert mit H2059:

```hilde fails H2059
pragma Unsafe_Module;

module body Example is
    pragma Foreign_Import(External_Name => "isatty");
    function isTerminal(descriptor: Int32): Bool is
    end;

    function main(): ExitCode is
        let terminal: Bool := isTerminal(0);
        return ExitSuccess();
    end;
end module body.
```

Die richtige Form:

```hilde
pragma Unsafe_Module;

module body Example is
    pragma Foreign_Import(External_Name => "isatty");
    function isTerminalAnswer(descriptor: Int32): Int32 is
    end;

    function main(): ExitCode is
        let terminal: Bool := isTerminalAnswer(0) /= 0;
        return ExitSuccess();
    end;
end module body.
```

### H3001

Meldung:

```text
Type Error
The type `Span[Int32, R]` is not allowed in the signature of an exported function.
```

Eine mit Foreign_Export an C gegebene Funktion hat einen Parameter- oder
Rückgabetyp, der nicht zu C hinüber kann, etwa einen Span aus etwas anderem
als Nat8, einen Record mit Typparametern oder eine Referenz auf eine Zahl.
Was hinüber kann und wie, steht in docs/syntax.de.md beim Bau einer Bibliothek.

Dieses Modul scheitert mit H3001:

```hilde fails H3001
module body Example is
    pragma Foreign_Export(External_Name => "example_sum");
    generic [R: Region]
    function sum(words: Span[Int32, R]): Int32 is
        return 0;
    end;

    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Die richtige Form:

```hilde
module body Example is
    pragma Foreign_Export(External_Name => "example_sum");
    generic [R: Region]
    function sum(bytes: Span[Nat8, R]): Int32 is
        return 0;
    end;

    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

### H6060

Meldung:

```text
Generic Error
I can't find a callable named `size` here. The module `Other` declares one; import it, as in `import Other (size);`. A module interface imports what its own contracts call, apart from its body.
```

Die Funktion gibt es in einem anderen Modul, das die Meldung nennt, sie
ist hier aber nicht importiert.  Ein Interface importiert, was seine
eigenen requires und ensures aufrufen: Ein Import des Modulrumpfs reicht
nicht bis ins Interface.

Dieses Modul scheitert mit H6060:

```hilde fails H6060
import Other (size);

module body Example is
    function count(n: Int32): Int32 is
        return size(n);
    end;

    function main(): ExitCode is
        printLn(count(3));
        return ExitSuccess();
    end;
end module body.
```

Daneben `Example.hih`:

```hilde file Example.hih
module Example is
    function count(n: Int32): Int32
        ensures size(result) >= 0;

    function main(): ExitCode;
end module.
```

Daneben `Other.hih`:

```hilde file Other.hih
module Other is
    function size(n: Int32): Int32;
end module.
```

Daneben `Other.hiq`:

```hilde file Other.hiq
module body Other is
    function size(n: Int32): Int32 is
        return n;
    end;
end module body.
```

Die richtige Form:

```hilde
import Other (size);

module body Example is
    function count(n: Int32): Int32 is
        return size(n);
    end;

    function main(): ExitCode is
        printLn(count(3));
        return ExitSuccess();
    end;
end module body.
```

Daneben `Example.hih`:

```hilde file Example.hih
import Other (size);

module Example is
    function count(n: Int32): Int32
        ensures size(result) >= 0;

    function main(): ExitCode;
end module.
```

Daneben `Other.hih`:

```hilde file Other.hih
module Other is
    function size(n: Int32): Int32;
end module.
```

Daneben `Other.hiq`:

```hilde file Other.hiq
module body Other is
    function size(n: Int32): Int32 is
        return n;
    end;
end module body.
```

## 6. Anderes

Dieses Kapitel enthält die Codes der Kommandozeile, des Einstiegspunkts und
der Konsistenzprüfungen im Compiler. Eine Konsistenzprüfung sichert einen
Zustand ab, den eine frühere Stufe des Compilers schon ausschließt; ein
Programm erreicht sie nicht, und ihr Eintrag nennt die frühere Prüfung, die
zuerst greift.

H9999 steht nicht an einer einzelnen Stelle im Compiler: Es ist der Code
seiner Funktion für interne Fehler, die überall dort aufgerufen wird, wo der
Compiler einen Zustand vorfindet, der nicht vorkommen sollte.

### H1001

Meldung:

```text
Command Line Arguments Error
Invalid entrypoint format `Example.main`

The entrypoint must be supplied in the form `Module:name`
```

Der Wert von --entrypoint hat nicht die Form Modul:Funktion.

Dieses Modul scheitert mit H1001:

```hilde fails H1001
module body Example is
    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Übersetzt mit:

```sh command
hilde compile Example.hiq --entrypoint=Example.main --output=prog
```

Die richtige Form:

```hilde
module body Example is
    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Übersetzt mit:

```sh command
hilde compile Example.hiq --entrypoint=Example:main --output=prog
```

### H1002

Meldung:

```text
Command Line Arguments Error
Invalid module source format `Example.hiq,Example.hiq,Example.hiq`

Sources must be supplied as either`interface.hih,body.hiq` or `body.hiq`
```

Ein Modul auf der Kommandozeile steht weder als einzelne Body-Datei noch als
Interface und Body, durch ein Komma verbunden.

Dieses Modul scheitert mit H1002:

```hilde fails H1002
module body Example is
    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Übersetzt mit:

```sh command
hilde compile Example.hiq,Example.hiq,Example.hiq --entrypoint=Example:main --output=prog
```

Die richtige Form:

```hilde
module body Example is
    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Übersetzt mit:

```sh command
hilde compile Example.hiq --entrypoint=Example:main --output=prog
```

### H1003

Meldung:

```text
Command Line Arguments Error
`--entrypoint` argument not provided.
```

Das Kommando compile hat kein --entrypoint. Ein Programm braucht eines; eine
C-Datei ohne Einstiegspunkt entsteht mit --target-type=c und
--no-entrypoint.

Dieses Modul scheitert mit H1003:

```hilde fails H1003
module body Example is
    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Übersetzt mit:

```sh command
hilde compile Example.hiq --output=prog
```

Die richtige Form:

```hilde
module body Example is
    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Übersetzt mit:

```sh command
hilde compile Example.hiq --entrypoint=Example:main --output=prog
```

### H1004

Meldung:

```text
Command Line Arguments Error
The `compile` command must specify at least one module.
```

Das Kommando compile nennt kein Modul.

Dieses Modul scheitert mit H1004:

```hilde fails H1004
module body Example is
    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Übersetzt mit:

```sh command
hilde compile --entrypoint=Example:main --output=prog
```

Die richtige Form:

```hilde
module body Example is
    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Übersetzt mit:

```sh command
hilde compile Example.hiq --entrypoint=Example:main --output=prog
```

### H1005

Meldung:

```text
Command Line Arguments Error
`--output` argument not provided.
```

Das Kommando compile hat kein --output.

Dieses Modul scheitert mit H1005:

```hilde fails H1005
module body Example is
    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Übersetzt mit:

```sh command
hilde compile Example.hiq --entrypoint=Example:main
```

Die richtige Form:

```hilde
module body Example is
    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Übersetzt mit:

```sh command
hilde compile Example.hiq --entrypoint=Example:main --output=prog
```

### H1006

Meldung:

```text
Command Line Arguments Error
`--no-entrypoint` requires `--target-type=c`, `static`, `shared` or `wasm`, because otherwise the compiler will try to build an executable, and will fail because there is no entrypoint function.
```

Der Compiler soll den Einstiegspunkt weglassen, und sein Ziel ist weder C
noch eine Bibliothek. Ein Programm ohne Einstiegspunkt wird als C
geschrieben oder als Bibliothek gebaut, damit ein Programm einer anderen
Sprache es linken kann.

Dieses Modul scheitert mit H1006:

```hilde fails H1006
module body Example is
    function answer(): Int32 is
        return 42;
    end;
end module body.
```

Übersetzt mit:

```sh command
hilde compile Example.hiq --no-entrypoint --output=prog
```

Die richtige Form:

```hilde
module body Example is
    function answer(): Int32 is
        return 42;
    end;
end module body.
```

Übersetzt mit:

```sh command
hilde compile Example.hiq --no-entrypoint --target-type=c --output=example.c
```

### H1007

Meldung:

```text
Command Line Arguments Error
Unknown target type `binary`
```

Der Wert von --target-type ist keiner von exe, c, tc, static und shared.

Dieses Modul scheitert mit H1007:

```hilde fails H1007
module body Example is
    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Übersetzt mit:

```sh command
hilde compile Example.hiq --entrypoint=Example:main --output=prog --target-type=binary
```

Die richtige Form:

```hilde
module body Example is
    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Übersetzt mit:

```sh command
hilde compile Example.hiq --entrypoint=Example:main --output=prog --target-type=exe
```

### H1008

Meldung:

```text
Command Line Arguments Error
Unknown error reporting mode: `xml`. Valid values are `plain`, `json`, `hilde-json` and `json-lines`.
```

Der Wert von --error-format ist keiner der Werte plain, json, hilde-json und json-lines.

Dieses Modul scheitert mit H1008:

```hilde fails H1008
module body Example is
    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Übersetzt mit:

```sh command
hilde compile Example.hiq --entrypoint=Example:main --output=prog --error-format=xml
```

Die richtige Form:

```hilde
module body Example is
    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Übersetzt mit:

```sh command
hilde compile Example.hiq --entrypoint=Example:main --output=prog --error-format=json
```

### H1009

Meldung:

```text
Command Line Arguments Error
The argument `output` was given multiple times
```

Ein Flag steht zweimal da.

Dieses Modul scheitert mit H1009:

```hilde fails H1009
module body Example is
    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Übersetzt mit:

```sh command
hilde compile Example.hiq --entrypoint=Example:main --output=prog --output=other
```

Die richtige Form:

```hilde
module body Example is
    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Übersetzt mit:

```sh command
hilde compile Example.hiq --entrypoint=Example:main --output=prog
```

### H1010

Meldung, aus dem Quelltext in `lib/CliUtil.ml`:

```text
Argument list must have at least one element in it, the path to the binary. Was the compiler invoked through a system call?
```

Die Argumentliste des Compilers ist leer, nicht einmal der Name des
Programms steht darin. Eine Shell übergibt den Namen immer; nur ein
Programm, das den Compiler ohne ihn startet, könnte diese Meldung erreichen.

Er bleibt, weil ein Programm ihn ohne Hilde-Quelltext erreichen kann:
eines, das den Compiler mit execve und einer leeren Argumentliste
startet. Die Prüfung macht daraus eine Meldung statt einer Ausnahme.

Nicht ausgelöst: Es fand sich kein Programm, das diesen Fehler erreicht.

### H1011

Meldung:

```text
Command Line Arguments Error
Expected `forbid-unsafe-modules` to be a boolean flag, but it was given as a value flag.
```

Ein Flag ohne Wert bekommt einen, wie in --flag=wert.

Dieses Modul scheitert mit H1011:

```hilde fails H1011
module body Example is
    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Übersetzt mit:

```sh command
hilde compile Example.hiq --entrypoint=Example:main --output=prog --forbid-unsafe-modules=yes
```

Die richtige Form:

```hilde
module body Example is
    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Übersetzt mit:

```sh command
hilde compile Example.hiq --entrypoint=Example:main --output=prog --forbid-unsafe-modules
```

### H1012

Meldung:

```text
Command Line Arguments Error
Expected `output` to be a value flag, but it was given as a boolean flag.
```

Ein Flag, das einen Wert nimmt, steht ohne Wert da.

Dieses Modul scheitert mit H1012:

```hilde fails H1012
module body Example is
    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Übersetzt mit:

```sh command
hilde compile Example.hiq --entrypoint=Example:main --output
```

Die richtige Form:

```hilde
module body Example is
    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Übersetzt mit:

```sh command
hilde compile Example.hiq --entrypoint=Example:main --output=prog
```

### H1013

Meldung:

```text
Command Line Arguments Error
Invalid flag argument `--output=prog=bin`
```

Ein Flag enthält mehr als ein Gleichheitszeichen und ist damit weder --flag
noch --flag=wert.

Dieses Modul scheitert mit H1013:

```hilde fails H1013
module body Example is
    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Übersetzt mit:

```sh command
hilde compile Example.hiq --entrypoint=Example:main --output=prog=bin
```

Die richtige Form:

```hilde
module body Example is
    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Übersetzt mit:

```sh command
hilde compile Example.hiq --entrypoint=Example:main --output=prog
```

### H1014

Meldung, aus dem Quelltext in `lib/Util.ml`:

```text
Failed to run C compiler. Command: ... Exit code: ... Standard output: ... Standard error: ...
```

Der C-Compiler hat den erzeugten C-Code abgelehnt. Bei einem richtigen
Programm liegt das an C, das mit @embed eingefügt wurde, an einer fehlenden
C-Bibliothek oder an einem Fehler im Compiler. Die Meldung zitiert das
Kommando des C-Compilers und seine Ausgabe. Bei --target-type=static läuft
nach dem C-Compiler der Archivierer ar(1); scheitert er, ist der Code
derselbe, und die Meldung beginnt mit Failed to run the archiver ar.

Dieses Modul scheitert mit H1014:

```hilde fails H1014
pragma Unsafe_Module;

module body Example is
    function main(): ExitCode is
        let n: Int32 := @embed(Int32, "this is not C");
        printLn(n);
        return ExitSuccess();
    end;
end module body.
```

Die richtige Form:

```hilde
pragma Unsafe_Module;

module body Example is
    function main(): ExitCode is
        let n: Int32 := @embed(Int32, "40 + 2");
        printLn(n);
        return ExitSuccess();
    end;
end module body.
```

### H1015

Meldung:

```text
Command Line Arguments Error
Failed to write to file `missing/Example.c`:

missing/Example.c: No such file or directory
```

Der Compiler konnte seine Ausgabedatei nicht öffnen oder nicht schreiben,
etwa weil ihr Verzeichnis fehlt oder das Gerät voll ist.

Dieses Modul scheitert mit H1015:

```hilde fails H1015
module body Example is
    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Übersetzt mit:

```sh command
hilde compile Example.hiq --entrypoint=Example:main --target-type=c --output=missing/Example.c
```

Die richtige Form:

```hilde
module body Example is
    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Übersetzt mit:

```sh command
hilde compile Example.hiq --entrypoint=Example:main --target-type=c --output=example.c
```

### H1016

Meldung, aus dem Quelltext in `lib/Util.ml`:

```text
Failed to write to file ...
```

Das ist die Meldung für ein Scheitern beim Schreiben, das kein Systemfehler
ist; ein Systemfehler, etwa ein fehlendes Verzeichnis, ist H1015. Es fand
sich kein Weg, das Schreiben anders scheitern zu lassen.

Er bleibt, weil er der andere Zweig der Behandlung ist, die die
Ausgabedatei schreibt: ein Fehlschlag dort, der kein Systemfehler ist.
Die Prüfung macht daraus eine Meldung mit dem Dateinamen statt einer
Ausnahme.

Nicht ausgelöst: Es fand sich kein Programm, das diesen Fehler erreicht.

### H1017

Meldung:

```text
Command Line Arguments Error
The module `Sample` is not on the command line, so there is nothing to query.
```

hilde query fragt nach einem Modul, das nicht auf der Kommandozeile steht.

Dieses Modul scheitert mit H1017:

```hilde fails H1017
module body Example is
    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Übersetzt mit:

```sh command
hilde query Example.hiq --module=Sample
```

Die richtige Form:

```hilde
module body Example is
    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Übersetzt mit:

```sh command
hilde query Example.hiq --module=Example
```

### H1018

Meldung:

```text
Command Line Arguments Error
`hilde query` needs `--module=Name`: the module to describe.
```

hilde query wird ohne --module aufgerufen und weiß daher nicht, welches
Modul es beschreiben soll.

Dieses Modul scheitert mit H1018:

```hilde fails H1018
module body Example is
    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Übersetzt mit:

```sh command
hilde query Example.hiq
```

Die richtige Form:

```hilde
module body Example is
    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Übersetzt mit:

```sh command
hilde query Example.hiq --module=Example
```

### H1019

Meldung:

```text
Command Line Arguments Error
`hilde test` names no path: give the directories to search for test files, or test files by name.
```

hilde test wird ohne Pfad aufgerufen und weiß daher nicht, wo es Tests
suchen soll.

Dieses Modul scheitert mit H1019:

```hilde fails H1019
module body Example.Test is
    function testNothing(): Unit is
        return nil;
    end;
end module body.
```

Aufgerufen mit:

```sh command
hilde test
```

Die richtige Form:

```hilde
module body Example.Test is
    function testNothing(): Unit is
        return nil;
    end;
end module body.
```

Aufgerufen mit:

```sh command
hilde test Example.hiq
```

### H1020

Meldung:

```text
Command Line Arguments Error
The flags `--race` and `--memory` of `hilde test` exclude one another.

A run takes at most one of `--race`, `--memory` and `--valgrind`, and `--emit-c` builds and runs nothing, so it takes none of them.
```

hilde test bekommt zwei Schalter, die einander ausschließen: zwei der
Instrumente --race, --memory und --valgrind, oder --emit-c neben einem von
ihnen.

ThreadSanitizer und AddressSanitizer lassen sich nicht in ein Programm
bauen, und valgrind führt ein Programm aus, das ohne beide gebaut ist;
--emit-c schreibt C und baut nichts, ein Instrument daneben bliebe also ohne
Wirkung.

Dieses Modul scheitert mit H1020:

```hilde fails H1020
module body Example.Test is
    function testNothing(): Unit is
        return nil;
    end;
end module body.
```

Aufgerufen mit:

```sh command
hilde test --race --memory Example.hiq
```

Die richtige Form:

```hilde
module body Example.Test is
    function testNothing(): Unit is
        return nil;
    end;
end module body.
```

Aufgerufen mit:

```sh command
hilde test Example.hiq
```

### H1021

Meldung, aus dem Quelltext in `lib/TestRunner.ml`:

```text
`hilde test <flag>` cannot run on this system: <what failed>
The answer was: <the first line the C compiler or valgrind wrote>
```

hilde test bekommt ein Instrument, --race, --memory oder --valgrind, das
dieses System nicht ausführen kann: Sein C-Compiler baut oder startet kein
Programm mit den Schaltern des Instruments, valgrind lässt sich nicht
starten, oder der C-Compiler findet valgrinds Header valgrind/valgrind.h
nicht.

hilde test fragt, bevor es etwas baut: Ein Programm, das nichts tut, wird
mit den Schaltern übersetzt und gestartet, und valgrind wird nach seiner
Version gefragt und ein Programm übersetzt, das seinen Header liest. Die
Laufzeit braucht den Header unter --valgrind: Sie meldet jeden Task-Stack
bei valgrind an.

Er bleibt, weil sich die Systeme, auf denen die Gates laufen, genau darin
unterscheiden: Im Linux-Gate läuft jedes Instrument, OpenBSDs C-Compiler
dagegen lehnt -fsanitize=address und -fsanitize=thread ab, und das System
hat kein valgrind. Ein Beispiel hier sagte auf dem anderen System etwas
anderes;
scripts/check-hilde-test.sh, das das OpenBSD-Gate ausführt, gibt jede
Ablehnung mit ihrem Wortlaut aus. In beiden Gates stellt es außerdem einen
C-Compiler an den Anfang von PATH, der jede -fsanitize-Option ablehnt, und
hält hilde test --race und --memory an diesen Fehler, mit dem Wortlaut
dieses Compilers und ohne dass ein Test läuft.

Nicht ausgelöst: Kein Beispiel erreicht diesen Fehler auf jedem System, auf
dem die Gates laufen.

### H1022

Meldung:

```text
Command Line Arguments Error
`missing` is neither a directory nor a file ending in .hiq.
```

Ein Pfad, den hilde test bekommt, ist weder ein Verzeichnis noch eine
.hiq-Datei, zum Beispiel weil es ihn nicht gibt.

Dieses Modul scheitert mit H1022:

```hilde fails H1022
module body Example.Test is
    function testNothing(): Unit is
        return nil;
    end;
end module body.
```

Aufgerufen mit:

```sh command
hilde test missing
```

Die richtige Form:

```hilde
module body Example.Test is
    function testNothing(): Unit is
        return nil;
    end;
end module body.
```

Aufgerufen mit:

```sh command
hilde test Example.hiq
```

### H1023

Meldung:

```text
Command Line Arguments Error
There is no test file under `.`.

A test file is a module body whose file name ends in .test.hiq, or a .hiq file named on the command line.
```

hilde test hat die Verzeichnisse durchsucht, die es bekam, und darin keine
Testdatei gefunden.

Dieses Modul scheitert mit H1023:

```hilde fails H1023
module body Example is
    function double(n: Nat32): Nat32 is
        return n * 2;
    end;
end module body.
```

Aufgerufen mit:

```sh command
hilde test .
```

Die richtige Form:

```hilde
module body Example is
    function double(n: Nat32): Nat32 is
        return n * 2;
    end;
end module body.
```

```hilde file Example.test.hiq
import Example (double);

module body Example.Test is
    function testDouble(): Unit is
        if double(2) /= 4 then
            abort("double(2) is not 4");
        end if;
        return nil;
    end;
end module body.
```

Aufgerufen mit:

```sh command
hilde test .
```

### H1024

Meldung:

```text
Command Line Arguments Error
The module `Example` is declared by two files, `./Example.hiq` and `./Other.hiq`, and a test programme imports it, so there is no telling which one it means.
```

Zwei Dateien unter den Pfaden von hilde test deklarieren dasselbe Modul, und
eine Testdatei importiert es.

Ein Name, den zwei Dateien deklarieren, wird nur abgelehnt, wenn ein
Testprogramm ihn braucht; sonst in den Verzeichnissen schadet er nicht.

Dieses Modul scheitert mit H1024:

```hilde fails H1024
module body Example is
    function double(n: Nat32): Nat32 is
        return n * 2;
    end;
end module body.
```

```hilde file Other.hiq
module body Example is
    function double(n: Nat32): Nat32 is
        return n + n;
    end;
end module body.
```

```hilde file Example.test.hiq
import Example (double);

module body Example.Test is
    function testDouble(): Unit is
        if double(2) /= 4 then
            abort("double(2) is not 4");
        end if;
        return nil;
    end;
end module body.
```

Aufgerufen mit:

```sh command
hilde test .
```

Die richtige Form:

```hilde
module body Example is
    function double(n: Nat32): Nat32 is
        return n * 2;
    end;
end module body.
```

```hilde file Other.hiq
module body Other is
    function half(n: Nat32): Nat32 is
        return n / 2;
    end;
end module body.
```

```hilde file Example.test.hiq
import Example (double);

module body Example.Test is
    function testDouble(): Unit is
        if double(2) /= 4 then
            abort("double(2) is not 4");
        end if;
        return nil;
    end;
end module body.
```

Aufgerufen mit:

```sh command
hilde test .
```

### H1025

Meldung:

```text
Command Line Arguments Error
The interface `./Other.hih` has no body `./Other.hiq` beside it, so its module cannot be compiled.
```

Ein Verzeichnis, in dem hilde test Module sucht, enthält ein Interface ohne
den Rumpf gleichen Namens daneben.

Dieses Modul scheitert mit H1025:

```hilde fails H1025
module body Example is
    function double(n: Nat32): Nat32 is
        return n * 2;
    end;
end module body.
```

```hilde file Other.hih
module Other is
    function half(n: Nat32): Nat32;
end module.
```

```hilde file Example.test.hiq
import Example (double);

module body Example.Test is
    function testDouble(): Unit is
        if double(2) /= 4 then
            abort("double(2) is not 4");
        end if;
        return nil;
    end;
end module body.
```

Aufgerufen mit:

```sh command
hilde test .
```

Die richtige Form:

```hilde
module body Example is
    function double(n: Nat32): Nat32 is
        return n * 2;
    end;
end module body.
```

```hilde file Other.hih
module Other is
    function half(n: Nat32): Nat32;
end module.
```

```hilde file Other.hiq
module body Other is
    function half(n: Nat32): Nat32 is
        return n / 2;
    end;
end module body.
```

```hilde file Example.test.hiq
import Example (double);

module body Example.Test is
    function testDouble(): Unit is
        if double(2) /= 4 then
            abort("double(2) is not 4");
        end if;
        return nil;
    end;
end module body.
```

Aufgerufen mit:

```sh command
hilde test .
```

### H1026

Meldung:

```text
Command Line Arguments Error
`--target-type=static` builds a library, and a library has no entrypoint: `--entrypoint` cannot be given with it.

The functions a library offers are the ones marked `pragma Foreign_Export`, called from C after `hilde_start`.
```

Eine Bibliothek wird gebaut, --target-type=static, shared oder wasm, und die
Kommandozeile nennt dazu einen Einstiegspunkt. Eine Bibliothek hat keinen
Einstiegspunkt: C ruft die Funktionen auf, die sie exportiert, nach
hilde_start.

Dieses Modul scheitert mit H1026:

```hilde fails H1026
module body Example is
    pragma Foreign_Export(External_Name => "example_twice");
    function twice(x: Int32): Int32 is
        return x * 2;
    end;
end module body.
```

Übersetzt mit:

```sh command
hilde compile Example.hiq --target-type=static --entrypoint=Example:main --output=libexample.a
```

Die richtige Form:

```hilde
module body Example is
    pragma Foreign_Export(External_Name => "example_twice");
    function twice(x: Int32): Int32 is
        return x * 2;
    end;
end module body.
```

Übersetzt mit:

```sh command
hilde compile Example.hiq --target-type=static --output=libexample.a
```

### H1027

Meldung:

```text
Command Line Arguments Error
The output of `--target-type=shared` must end in `.so`, and `libexample.a` does not.

The header is written beside the library under the same name ending in `.h`.
```

Die Ausgabe einer Bibliothek endet nicht auf die Endung ihrer Art, .a für
--target-type=static und .so für shared, oder ist nur die Endung. Der
Header wird neben die Bibliothek geschrieben, unter demselben Namen mit der
Endung .h, also muss der Name sagen, wo seine Endung beginnt.

Dieses Modul scheitert mit H1027:

```hilde fails H1027
module body Example is
    pragma Foreign_Export(External_Name => "example_twice");
    function twice(x: Int32): Int32 is
        return x * 2;
    end;
end module body.
```

Übersetzt mit:

```sh command
hilde compile Example.hiq --target-type=shared --output=libexample.a
```

Die richtige Form:

```hilde
module body Example is
    pragma Foreign_Export(External_Name => "example_twice");
    function twice(x: Int32): Int32 is
        return x * 2;
    end;
end module body.
```

Übersetzt mit:

```sh command
hilde compile Example.hiq --target-type=shared --output=libexample.so
```

### H1028

Meldung:

```text
Command Line Arguments Error
The value of `--seed` is `18446744073709551616`, which is not a decimal number from 0 to 18446744073709551615.
```

hilde test --contracts bekommt einen Seed oder eine Zahl von Runden, die
keine Dezimalzahl in ihrem Bereich ist.

Ein Seed ist ein Nat64, von 0 bis 18446744073709551615, weil er als solcher
in das Programm geschrieben wird, das die Eingaben zieht; die Runden reichen
von 1 bis 100000, weil ein Lauf ohne Runden nichts testen würde.

Dieses Modul scheitert mit H1028:

```hilde fails H1028
module body Example.Test is
    function testNothing(): Unit is
        return nil;
    end;
end module body.
```

Aufgerufen mit:

```sh command
hilde test --contracts --seed=18446744073709551616 Example.hiq
```

Die richtige Form:

```hilde
module body Example.Test is
    function testNothing(): Unit is
        return nil;
    end;
end module body.
```

Aufgerufen mit:

```sh command
hilde test --contracts --seed=18446744073709551615 Example.hiq
```

### H1029

Meldung:

```text
Command Line Arguments Error
`--seed` is read only by `hilde test --contracts`, and this run has no `--contracts`.

Add `--contracts`, or leave the flag out.
```

hilde test bekommt --seed oder --rounds ohne --contracts.

Nur ein Lauf, der Verträge testet, zieht Eingaben; ohne ihn bliebe der
Schalter ohne Wirkung, und ein Schalter ohne Wirkung wird abgewiesen statt
übergangen.

Dieses Modul scheitert mit H1029:

```hilde fails H1029
module body Example.Test is
    function testNothing(): Unit is
        return nil;
    end;
end module body.
```

Aufgerufen mit:

```sh command
hilde test --seed=7 Example.hiq
```

Die richtige Form:

```hilde
module body Example.Test is
    function testNothing(): Unit is
        return nil;
    end;
end module body.
```

Aufgerufen mit:

```sh command
hilde test --contracts --seed=7 Example.hiq
```

### H1030

Meldung:

```text
Command Line Arguments Error
The entrypoint `Example:start` is not a function of a module on the command line.
```

hilde guard bekommt einen Einstiegspunkt, der keine Funktion eines Moduls
auf seiner Kommandozeile ist.

Der Gang über die Aufrufe des Programms beginnt beim Einstiegspunkt; ein
Name, den es nicht gibt, ließe nichts, wovon er ausgehen könnte.  Er wird
abgewiesen, statt als fehlender Einstiegspunkt gelesen zu werden.

Dieses Modul scheitert mit H1030:

```hilde fails H1030
module body Example is
    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Übersetzt mit:

```sh command
hilde guard Example.hiq --entrypoint=Example:start
```

Die richtige Form:

```hilde
module body Example is
    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Übersetzt mit:

```sh command
hilde guard Example.hiq --entrypoint=Example:main
```

### H1031

Meldung:

```text
Command Line Arguments Error
The vulnerability database `missing.json` cannot be read: there is no such file or directory.
```

hilde guard bekommt eine Schwachstellen-Datenbank, die es nicht lesen
kann: einen Pfad, den es nicht gibt, eine Datei, die kein JSON ist, oder
einen Eintrag, der nicht im OSV-Format steht.

Eine Prüfung, die ihre Datenbank nicht lesen konnte, fände nichts, und ein
Bericht ohne Befund sähe aus wie ein Programm ohne Schwachstellen; deshalb
wird die Datenbank vor dem Programm gelesen, und ein Fehler darin beendet
das Kommando.

Dieses Modul scheitert mit H1031:

```hilde fails H1031
module body Example is
    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Übersetzt mit:

```sh command
hilde guard Example.hiq --vulndb=missing.json
```

Die richtige Form:

```hilde
module body Example is
    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Daneben `osv.json`:

```json file osv.json
[]
```

Übersetzt mit:

```sh command
hilde guard Example.hiq --vulndb=osv.json
```

### H1032

Meldung:

```text
Command Line Arguments Error
`sqlite3` in --library-versions is not a library, a colon and a version of numbers separated by dots, such as `--library-versions=sqlite3:3.46.1,tls:4.3.0`.
```

Ein Eintrag von --library-versions ist nicht der Name einer Bibliothek,
wie sie gebunden wird, ein Doppelpunkt und eine Version aus Zahlen mit
Punkten dazwischen.

Die Versionen werden Zahl für Zahl mit den Bereichen der Meldungen
verglichen; eine Version in anderer Form ließe sich nicht vergleichen und
wird abgewiesen, statt als fehlende Version zu gelten.

Dieses Modul scheitert mit H1032:

```hilde fails H1032
module body Example is
    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Übersetzt mit:

```sh command
hilde guard Example.hiq --library-versions=sqlite3
```

Die richtige Form:

```hilde
module body Example is
    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Übersetzt mit:

```sh command
hilde guard Example.hiq --library-versions=sqlite3:3.46.1
```

### H1033

Meldung:

```text
Command Line Arguments Error
hilde fmt: `Example.hiq.txt` is neither a directory nor a .hih or .hiq file.
```

Ein Pfad für hilde fmt ist weder ein Verzeichnis, dessen Hilde-Quellen
formatiert werden, noch eine Datei, deren Name auf .hih oder .hiq endet.
Eine Datei anderer Art gilt nicht als Quelle.

Dieses Modul scheitert mit H1033:

```hilde fails H1033
module body Example is
    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Übersetzt mit:

```sh command
hilde fmt Example.hiq.txt
```

Die richtige Form:

```hilde
module body Example is
    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Übersetzt mit:

```sh command
hilde fmt Example.hiq
```

### H1034

Meldung:

```text
Command Line Arguments Error
Failed to read file `Missing.hiq`:

Missing.hiq: No such file or directory
```

Eine Datei, die der Compiler bekam, ließ sich nicht öffnen oder lesen: Es gibt
sie nicht, sie ist ein Verzeichnis, oder sie darf nicht gelesen werden.  hilde
check, hilde compile, hilde test und hilde fmt melden es so; vorher endete der
Compiler mit einer Ausnahme von OCaml.

Dieses Modul scheitert mit H1034:

```hilde fails H1034
module body Example is
    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Übersetzt mit:

```sh command
hilde compile Missing.hiq --entrypoint=Example:main --target-type=c --output=example.c
```

Die richtige Form:

```hilde
module body Example is
    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Übersetzt mit:

```sh command
hilde compile Example.hiq --entrypoint=Example:main --target-type=c --output=example.c
```

### H1035

Meldung:

```text
Command Line Arguments Error
The build value `1channel=stable` is refused: the name is not valid.

It is written --build-value=name=value, the name a letter and then letters, digits, _, . or -, at most 64 bytes, the value printable ASCII, at most 1024 bytes, each name once.
```

Ein Wert, der mit --build-value kommt und den ein Programm mit value aus
Standard.BuildInfo liest, wird name=wert geschrieben.  Der Name beginnt mit
einem Buchstaben und enthält Buchstaben, Ziffern, _, . und -, höchstens 64
Bytes; der Wert ist druckbares ASCII, höchstens 1024 Bytes; jeder Name kommt
einmal.

Dieses Modul scheitert mit H1035:

```hilde fails H1035
module body Example is
    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Übersetzt mit:

```sh command
hilde compile Example.hiq --entrypoint=Example:main --target-type=c --output=example.c --build-value=1channel=stable
```

Die richtige Form:

```hilde
module body Example is
    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Übersetzt mit:

```sh command
hilde compile Example.hiq --entrypoint=Example:main --target-type=c --output=example.c --build-value=channel=stable
```

### H1036

Meldung:

```text
Command Line Arguments Error
SOURCE_DATE_EPOCH is `17x0`, which is not a number of seconds since 1970: one to eighteen decimal digits.
```

SOURCE_DATE_EPOCH gibt die Zeit des Baus, die builtAt aus Standard.BuildInfo
liefert, damit zwei Bauten dieselben Bytes geben können.  Ein Wert, der keine
Zahl von Sekunden ist, beendet hilde compile, ob das Programm das Modul
importiert oder nicht, wie es die Spezifikation der Variable verlangt.

Dieses Modul scheitert mit H1036:

```hilde fails H1036
module body Example is
    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Übersetzt mit:

```sh command
env SOURCE_DATE_EPOCH=17x0 hilde compile Example.hiq --entrypoint=Example:main --target-type=c --output=example.c
```

Die richtige Form:

```hilde
module body Example is
    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Übersetzt mit:

```sh command
env SOURCE_DATE_EPOCH=1700000000 hilde compile Example.hiq --entrypoint=Example:main --target-type=c --output=example.c
```

### H1037

Meldung:

```text
Command Line Arguments Error
Unknown command `chek`. The commands are build, compile, test, lsp, modules, fmt, check, query, guard, run, get, update, verify, export, new, install, doc, api-diff. Did you mean `check`?
```

Das erste Wort ist kein Befehl von hilde.  Bisher gab hilde seine Hilfe aus
und endete mit 0, so dass ein Werkzeug, das einen Befehl aufrief, den
dieser Compiler nicht hat, etwa check bei einem älteren, das für einen
Erfolg hielt.  Die Meldung nennt die Befehle und, für ein Wort wenige
Buchstaben von einem entfernt, diesen Befehl.

Dieses Modul scheitert mit H1037:

```hilde fails H1037
module body Example is
    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Übersetzt mit:

```sh command
hilde chek Example.hiq
```

Die richtige Form:

```hilde
module body Example is
    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Übersetzt mit:

```sh command
hilde check Example.hiq
```

### H2046

Meldung:

```text
Declaration Error
The function `testLength` has the name of a test, and a test has one of two forms:

`function testName(): Unit`, or, for a test that needs the root capability, `generic [R: Region] function testName(root: &![RootCapability, R]): Unit`.

In a test file every function whose name is test followed by a capital letter or a digit is a test.
```

Eine Funktion einer Testdatei trägt den Namen eines Tests und hat eine
andere Form als ein Test.

Der Name macht sie zum Test: test, gefolgt von einem Großbuchstaben oder
einer Ziffer. Ein Test nimmt nichts und gibt nichts zurück, oder er nimmt
die Root-Fähigkeit; eine Funktion mit dem Namen eines Tests in anderer Form
wird abgelehnt statt übergangen, denn ein Test, der stillschweigend nicht
läuft, sieht genauso aus wie einer, der bestanden hat.

Dieses Modul scheitert mit H2046:

```hilde fails H2046
module body Example.Test is
    function testLength(n: Nat32): Unit is
        return nil;
    end;
end module body.
```

Aufgerufen mit:

```sh command
hilde test Example.hiq
```

Die richtige Form:

```hilde
module body Example.Test is
    function testLength(): Unit is
        return nil;
    end;
end module body.
```

Aufgerufen mit:

```sh command
hilde test Example.hiq
```

### H2047

Meldung:

```text
Declaration Error
The test file `Example.hiq` holds no test.

A test is a function whose name is test followed by a capital letter or a digit, such as `testLength`.
```

Eine Testdatei deklariert keine Funktion mit dem Namen eines Tests.

Dieses Modul scheitert mit H2047:

```hilde fails H2047
module body Example.Test is
    function helper(): Unit is
        return nil;
    end;
end module body.
```

Aufgerufen mit:

```sh command
hilde test Example.hiq
```

Die richtige Form:

```hilde
module body Example.Test is
    function testLength(): Unit is
        return nil;
    end;
end module body.
```

Aufgerufen mit:

```sh command
hilde test Example.hiq
```

### H2048

Meldung:

```text
Declaration Error
The system `linux` in a `pragma Foreign_Library` is not one this compiler knows.

It is compared with what `uname -s` prints on the machine that compiles the programme, and must be one of `Linux, OpenBSD, FreeBSD, NetBSD, Darwin`, written as it prints them.
```

Ein pragma Foreign_Library nennt ein System, das der Compiler nicht kennt.
Das System wird mit der Ausgabe von uname -s verglichen und deshalb so
geschrieben, wie uname es schreibt, mit Großbuchstaben. Ein falsch
geschriebenes System träfe nie zu, und seine Bibliothek würde nie gelinkt;
deshalb wird es abgelehnt.

Dieses Modul scheitert mit H2048:

```hilde fails H2048
pragma Unsafe_Module;
pragma Foreign_Library(Name => "m", System => "linux");

module body Example is
    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Die richtige Form:

```hilde
pragma Unsafe_Module;
pragma Foreign_Library(Name => "m", System => "Linux");

module body Example is
    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

### H2049

Meldung:

```text
Declaration Error
Invalid `pragma Foreign_Library`.

It takes the argument `Name`, and after it, for a library linked on one system only, `System`: `pragma Foreign_Library(Name => "crypt", System => "Linux");`
```

Ein pragma Foreign_Library hat Argumente, die es nicht kennt, oder seine
beiden in der anderen Reihenfolge. Es nimmt Name und danach System, wenn die
Bibliothek nur auf einem System gelinkt wird.

Dieses Modul scheitert mit H2049:

```hilde fails H2049
pragma Unsafe_Module;
pragma Foreign_Library(System => "Linux", Name => "m");

module body Example is
    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Die richtige Form:

```hilde
pragma Unsafe_Module;
pragma Foreign_Library(Name => "m", System => "Linux");

module body Example is
    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

### H3059

Meldung:

```text
Type Error
This pattern can never compile: `Standard.Regex: lookaround is not supported -- it cannot be matched in linear time; Standard.Pcre has it at byte 1`.  Standard.Regex's compile would return that as its Left when the programme runs; a literal pattern is checked now.
```

Ein literales Muster für compile aus Standard.Regex ist eines, das das Modul
zur Laufzeit ablehnen würde. Ein literales Muster wird schon beim
Kompilieren geprüft.

Dieses Modul scheitert mit H3059:

```hilde fails H3059
import Standard.String (String, destroyString);
import Standard.Regex (Regex, compile, destroyRegex);

module body Example is
    function main(): ExitCode is
        let compiled: Either[String, Regex] := compile("a(?=b)");
        case compiled of
            when Right(right as re: Regex) do
                destroyRegex(re);
            when Left(left as message: String) do
                destroyString(message);
        end case;
        return ExitSuccess();
    end;
end module body.
```

Die richtige Form:

```hilde
import Standard.String (String, destroyString);
import Standard.Regex (Regex, compile, destroyRegex);

module body Example is
    function main(): ExitCode is
        let compiled: Either[String, Regex] := compile("a(b)");
        case compiled of
            when Right(right as re: Regex) do
                destroyRegex(re);
            when Left(left as message: String) do
                destroyString(message);
        end case;
        return ExitSuccess();
    end;
end module body.
```

### H5001

Meldung:

```text
Entrypoint Definition Error
The entrypoint function should take a single parameter with type `RootCapability`, or none at all, but it has several.
```

Die Einstiegsfunktion hat mehr als einen Parameter. Sie hat keinen oder
einen vom Typ RootCapability.

Dieses Modul scheitert mit H5001:

```hilde fails H5001
module body Example is
    function main(root: RootCapability, n: Int32): ExitCode is
        surrenderRoot(root);
        return ExitSuccess();
    end;
end module body.
```

Die richtige Form:

```hilde
module body Example is
    function main(root: RootCapability): ExitCode is
        surrenderRoot(root);
        return ExitSuccess();
    end;
end module body.
```

### H5002

Meldung:

```text
Entrypoint Definition Error
No function named `start` in module `Example`
```

Das in --entrypoint genannte Modul hat keine Funktion dieses Namens.

Dieses Modul scheitert mit H5002:

```hilde fails H5002
module body Example is
    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Übersetzt mit:

```sh command
hilde compile Example.hiq --entrypoint=Example:start --output=prog
```

Die richtige Form:

```hilde
module body Example is
    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Übersetzt mit:

```sh command
hilde compile Example.hiq --entrypoint=Example:main --output=prog
```

### H5003

Meldung:

```text
Entrypoint Definition Error
The entrypoint must be a function.
```

Der in --entrypoint genannte Einstiegspunkt ist keine Funktion, etwa eine
Konstante.

Dieses Modul scheitert mit H5003:

```hilde fails H5003
module body Example is
    constant start: Int32 := 1;

    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Übersetzt mit:

```sh command
hilde compile Example.hiq --entrypoint=Example:start --output=prog
```

Die richtige Form:

```hilde
module body Example is
    constant start: Int32 := 1;

    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Übersetzt mit:

```sh command
hilde compile Example.hiq --entrypoint=Example:main --output=prog
```

### H5004

Meldung:

```text
Entrypoint Definition Error
The entrypoint function cannot be generic.
```

Die Einstiegsfunktion ist generisch.

Dieses Modul scheitert mit H5004:

```hilde fails H5004
module body Example is
    generic [T: Free]
    function main(value: T): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Die richtige Form:

```hilde
module body Example is
    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

### H5005

Meldung:

```text
Entrypoint Definition Error
The entrypoint function is not public.

Consider declaring it in the module interface.
```

Das Modul hat ein Interface, und das Interface deklariert die
Einstiegsfunktion nicht. Sie wird dort deklariert.

Dieses Modul scheitert mit H5005:

```hilde fails H5005
module body Example is
    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Daneben `Example.hih`:

```hilde file Example.hih
module Example is
end module.
```

Die richtige Form:

```hilde
module body Example is
    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Daneben `Example.hih`:

```hilde file Example.hih
module Example is
    function main(): ExitCode;
end module.
```

### H5006

Meldung:

```text
Entrypoint Definition Error
The type of the entrypoint argument must be `RootCapability` but it is `Int32`
```

Der eine Parameter der Einstiegsfunktion hat nicht den Typ RootCapability.

Dieses Modul scheitert mit H5006:

```hilde fails H5006
module body Example is
    function main(n: Int32): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Die richtige Form:

```hilde
module body Example is
    function main(root: RootCapability): ExitCode is
        surrenderRoot(root);
        return ExitSuccess();
    end;
end module body.
```

### H5007

Meldung:

```text
Entrypoint Definition Error
The type of the entrypoint function must be `ExitCode` but it is `Int32`
```

Die Einstiegsfunktion gibt kein ExitCode zurück.

Dieses Modul scheitert mit H5007:

```hilde fails H5007
module body Example is
    function main(): Int32 is
        return 0;
    end;
end module body.
```

Die richtige Form:

```hilde
module body Example is
    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

### H6001

Meldung:

```text
Generic Error
@bytes("../data.txt"): the path leaves the module's own directory, which is not allowed
```

Der Pfad in @bytes ist leer, absolut oder enthält einen Teil ... Ein Modul
darf nur eine Datei neben sich oder darunter einbetten.

Dieses Modul scheitert mit H6001:

```hilde fails H6001
module body Example is
    function main(): ExitCode is
        let data: Span[Nat8, Static] := @bytes("../data.txt");
        printLn(spanLength(data));
        return ExitSuccess();
    end;
end module body.
```

Daneben `data.txt`:

```text file data.txt
Hello
```

Die richtige Form:

```hilde
module body Example is
    function main(): ExitCode is
        let data: Span[Nat8, Static] := @bytes("data.txt");
        printLn(spanLength(data));
        return ExitSuccess();
    end;
end module body.
```

Daneben `data.txt`:

```text file data.txt
Hello
```

### H6002

Meldung:

```text
Generic Error
@bytes("missing.txt"): cannot read it: ./missing.txt: No such file or directory
```

Die in @bytes genannte Datei lässt sich nicht lesen, etwa weil sie nicht
neben dem Modul liegt.

Dieses Modul scheitert mit H6002:

```hilde fails H6002
module body Example is
    function main(): ExitCode is
        let data: Span[Nat8, Static] := @bytes("missing.txt");
        printLn(spanLength(data));
        return ExitSuccess();
    end;
end module body.
```

Die richtige Form:

```hilde
module body Example is
    function main(): ExitCode is
        let data: Span[Nat8, Static] := @bytes("data.txt");
        printLn(spanLength(data));
        return ExitSuccess();
    end;
end module body.
```

Daneben `data.txt`:

```text file data.txt
Hello
```

### H6005

Meldung:

```text
Generic Error
There are leftover arguments.
```

Die Kommandozeile enthält ein Argument, das compile oder query nicht
verwendet, etwa ein unbekanntes Flag.

Dieses Modul scheitert mit H6005:

```hilde fails H6005
module body Example is
    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Übersetzt mit:

```sh command
hilde compile Example.hiq --entrypoint=Example:main --output=prog --verbose
```

Die richtige Form:

```hilde
module body Example is
    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Übersetzt mit:

```sh command
hilde compile Example.hiq --entrypoint=Example:main --output=prog
```

### H6013

Meldung:

```text
Generic Error
Borrow expressions not allowed in this context.
```

Ein Ausleihausdruck steht dort, wo keine Anweisung die Ausleihe fassen kann,
etwa im Wert einer Konstanten.

Dieses Modul scheitert mit H6013:

```hilde fails H6013
module body Example is
    constant limit: Int32 := 5;

    constant view: &[Int32, Static] := &limit;

    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Die richtige Form:

```hilde
module body Example is
    constant limit: Int32 := 5;

    function main(): ExitCode is
        printLn(limit);
        return ExitSuccess();
    end;
end module body.
```

### H6020

Meldung:

```text
Generic Error
The name `n` is bound already in this function. A name stays bound until the end of the block it was bound in, also after its value is consumed, so a second binding needs a name of its own, as in `value as otherN`.
```

Eine Funktion bindet denselben Namen zweimal im selben Gültigkeitsbereich,
etwa mit zwei let. Hilde kennt kein Verdecken; die zweite Variable bekommt
einen anderen Namen.

Dieses Modul scheitert mit H6020:

```hilde fails H6020
module body Example is
    function main(): ExitCode is
        let n: Int32 := 1;
        let n: Int32 := 2;
        printLn(n);
        return ExitSuccess();
    end;
end module body.
```

Die richtige Form:

```hilde
module body Example is
    function main(): ExitCode is
        let n: Int32 := 1;
        let m: Int32 := 2;
        printLn(n + m);
        return ExitSuccess();
    end;
end module body.
```

### H6025

Meldung:

```text
Generic Error
Region map already has a region with this name
```

Zwei verschachtelte borrow-Anweisungen geben ihren Regionen denselben Namen.

Dieses Modul scheitert mit H6025:

```hilde fails H6025
module body Example is
    function main(): ExitCode is
        let a: Int32 := 1;
        let b: Int32 := 2;
        borrow ra: &[Int32, R] := &a do
            borrow rb: &[Int32, R] := &b do
                printLn(!ra + !rb);
            end borrow;
        end borrow;
        return ExitSuccess();
    end;
end module body.
```

Die richtige Form:

```hilde
module body Example is
    function main(): ExitCode is
        let a: Int32 := 1;
        let b: Int32 := 2;
        borrow ra: &[Int32, R] := &a do
            borrow rb: &[Int32, S] := &b do
                printLn(!ra + !rb);
            end borrow;
        end borrow;
        return ExitSuccess();
    end;
end module body.
```

### H6047

Meldung:

```text
Generic Error
Duplicate type parameter `T`
```

Eine Liste von Typparametern nennt denselben Parameter zweimal.

Dieses Modul scheitert mit H6047:

```hilde fails H6047
module body Example is
    generic [T: Free, T: Free]
    function first(a: T, b: T): T is
        return a;
    end;

    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Die richtige Form:

```hilde
module body Example is
    generic [T: Free, U: Free]
    function first(a: T, b: U): T is
        return a;
    end;

    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

### H9999

Meldung, aus dem Quelltext in `lib/Error.ml`:

```text
Internal compiler error: ...

This is a bug in the compiler.
```

Ein interner Fehler: Der Compiler hat einen Zustand erreicht, den seine
eigenen Prüfungen hätten ausschließen sollen. Es ist ein Fehler des
Compilers, nicht des Programms.  Der Weg, den dieser Eintrag zeigte, eine
Einschränkung mit einer Typklasse, die nicht importiert ist, ist jetzt
H3105.

Er bleibt, weil jeder interne Fehler des Compilers ihn trägt: Eine Prüfung, die nur ein Fehler des
Compilers erreichen kann, meldet H9999 und keinen eigenen Code.

Nicht ausgelöst: Es fand sich kein Programm, das diesen Fehler erreicht.

## 7. Templates

Jedes Beispiel dieses Kapitels ist dasselbe Modul: ein linearer Record Page
mit den Feldern title, motto, items, admin und count und eine Funktion
render, die die Seite über @template in einen StringBuilder schreibt. Die
Beispiele unterscheiden sich im Template neben dem Modul und bei den ersten
Codes im Namen des Templates.

Die Meldung eines Template-Fehlers nennt die Stelle in der Template-Datei.

### H7001

Meldung:

```text
Generic Error
@template: the template name is empty
```

Der Name eines Templates ist leer.

Dieses Modul scheitert mit H7001:

```hilde fails H7001
import Standard.Buffer (Buffer);
import Standard.String (String);
import Standard.StringBuilder (StringBuilder, makeStringBuilder, finalize);
import Standard.Template (Render);

module body Example is
    record Page: Linear is
        title: String;
        motto: Option[String];
        items: Buffer[Index];
        admin: Bool;
        count: Int32;
    end;

    generic [R: Region]
    function render(page: &[Page, R]): String is
        var out: StringBuilder := makeStringBuilder();
        @template("", page, out);
        return finalize(out);
    end;

    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Daneben `page.jinja`:

```jinja file page.jinja
<p>{{ title }}</p>
```

Die richtige Form:

```hilde
import Standard.Buffer (Buffer);
import Standard.String (String);
import Standard.StringBuilder (StringBuilder, makeStringBuilder, finalize);
import Standard.Template (Render);

module body Example is
    record Page: Linear is
        title: String;
        motto: Option[String];
        items: Buffer[Index];
        admin: Bool;
        count: Int32;
    end;

    generic [R: Region]
    function render(page: &[Page, R]): String is
        var out: StringBuilder := makeStringBuilder();
        @template("page.jinja", page, out);
        return finalize(out);
    end;

    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Daneben `page.jinja`:

```jinja file page.jinja
<p>{{ title }}</p>
```

### H7002

Meldung:

```text
Generic Error
@template: "/page.jinja": the path is absolute, and a template may only be read from beside the module
```

Der Pfad eines Templates ist absolut. Ein Template wird neben dem Modul oder
darunter gelesen.

Dieses Modul scheitert mit H7002:

```hilde fails H7002
import Standard.Buffer (Buffer);
import Standard.String (String);
import Standard.StringBuilder (StringBuilder, makeStringBuilder, finalize);
import Standard.Template (Render);

module body Example is
    record Page: Linear is
        title: String;
        motto: Option[String];
        items: Buffer[Index];
        admin: Bool;
        count: Int32;
    end;

    generic [R: Region]
    function render(page: &[Page, R]): String is
        var out: StringBuilder := makeStringBuilder();
        @template("/page.jinja", page, out);
        return finalize(out);
    end;

    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Daneben `page.jinja`:

```jinja file page.jinja
<p>{{ title }}</p>
```

Die richtige Form:

```hilde
import Standard.Buffer (Buffer);
import Standard.String (String);
import Standard.StringBuilder (StringBuilder, makeStringBuilder, finalize);
import Standard.Template (Render);

module body Example is
    record Page: Linear is
        title: String;
        motto: Option[String];
        items: Buffer[Index];
        admin: Bool;
        count: Int32;
    end;

    generic [R: Region]
    function render(page: &[Page, R]): String is
        var out: StringBuilder := makeStringBuilder();
        @template("page.jinja", page, out);
        return finalize(out);
    end;

    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Daneben `page.jinja`:

```jinja file page.jinja
<p>{{ title }}</p>
```

### H7003

Meldung:

```text
Generic Error
@template: "../page.jinja": the path leaves the module's own directory, which is not allowed
```

Der Pfad eines Templates enthält einen Teil .. und verlässt damit das
Verzeichnis des Moduls.

Dieses Modul scheitert mit H7003:

```hilde fails H7003
import Standard.Buffer (Buffer);
import Standard.String (String);
import Standard.StringBuilder (StringBuilder, makeStringBuilder, finalize);
import Standard.Template (Render);

module body Example is
    record Page: Linear is
        title: String;
        motto: Option[String];
        items: Buffer[Index];
        admin: Bool;
        count: Int32;
    end;

    generic [R: Region]
    function render(page: &[Page, R]): String is
        var out: StringBuilder := makeStringBuilder();
        @template("../page.jinja", page, out);
        return finalize(out);
    end;

    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Daneben `page.jinja`:

```jinja file page.jinja
<p>{{ title }}</p>
```

Die richtige Form:

```hilde
import Standard.Buffer (Buffer);
import Standard.String (String);
import Standard.StringBuilder (StringBuilder, makeStringBuilder, finalize);
import Standard.Template (Render);

module body Example is
    record Page: Linear is
        title: String;
        motto: Option[String];
        items: Buffer[Index];
        admin: Bool;
        count: Int32;
    end;

    generic [R: Region]
    function render(page: &[Page, R]): String is
        var out: StringBuilder := makeStringBuilder();
        @template("page.jinja", page, out);
        return finalize(out);
    end;

    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Daneben `page.jinja`:

```jinja file page.jinja
<p>{{ title }}</p>
```

### H7004

Meldung:

```text
Generic Error
@template: "missing.jinja": cannot read it: ./missing.jinja: No such file or directory
```

Eine Template-Datei lässt sich nicht lesen, etwa weil sie nicht neben dem
Modul liegt.

Dieses Modul scheitert mit H7004:

```hilde fails H7004
import Standard.Buffer (Buffer);
import Standard.String (String);
import Standard.StringBuilder (StringBuilder, makeStringBuilder, finalize);
import Standard.Template (Render);

module body Example is
    record Page: Linear is
        title: String;
        motto: Option[String];
        items: Buffer[Index];
        admin: Bool;
        count: Int32;
    end;

    generic [R: Region]
    function render(page: &[Page, R]): String is
        var out: StringBuilder := makeStringBuilder();
        @template("missing.jinja", page, out);
        return finalize(out);
    end;

    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Daneben `page.jinja`:

```jinja file page.jinja
<p>{{ title }}</p>
```

Die richtige Form:

```hilde
import Standard.Buffer (Buffer);
import Standard.String (String);
import Standard.StringBuilder (StringBuilder, makeStringBuilder, finalize);
import Standard.Template (Render);

module body Example is
    record Page: Linear is
        title: String;
        motto: Option[String];
        items: Buffer[Index];
        admin: Bool;
        count: Int32;
    end;

    generic [R: Region]
    function render(page: &[Page, R]): String is
        var out: StringBuilder := makeStringBuilder();
        @template("page.jinja", page, out);
        return finalize(out);
    end;

    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Daneben `page.jinja`:

```jinja file page.jinja
<p>{{ title }}</p>
```

### H7005

Meldung:

```text
Generic Error
@template: this tag is never closed with }}
```

Ein Tag {{ oder {% wird geöffnet und nie geschlossen.

Dieses Modul scheitert mit H7005:

```hilde fails H7005
import Standard.Buffer (Buffer);
import Standard.String (String);
import Standard.StringBuilder (StringBuilder, makeStringBuilder, finalize);
import Standard.Template (Render);

module body Example is
    record Page: Linear is
        title: String;
        motto: Option[String];
        items: Buffer[Index];
        admin: Bool;
        count: Int32;
    end;

    generic [R: Region]
    function render(page: &[Page, R]): String is
        var out: StringBuilder := makeStringBuilder();
        @template("page.jinja", page, out);
        return finalize(out);
    end;

    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Daneben `page.jinja`:

```jinja file page.jinja
<p>{{ title</p>
```

Die richtige Form:

```hilde
import Standard.Buffer (Buffer);
import Standard.String (String);
import Standard.StringBuilder (StringBuilder, makeStringBuilder, finalize);
import Standard.Template (Render);

module body Example is
    record Page: Linear is
        title: String;
        motto: Option[String];
        items: Buffer[Index];
        admin: Bool;
        count: Int32;
    end;

    generic [R: Region]
    function render(page: &[Page, R]): String is
        var out: StringBuilder := makeStringBuilder();
        @template("page.jinja", page, out);
        return finalize(out);
    end;

    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Daneben `page.jinja`:

```jinja file page.jinja
<p>{{ title }}</p>
```

### H7006

Meldung:

```text
Generic Error
@template: this comment is never closed with #}
```

Ein Kommentar {# wird geöffnet und nie mit #} geschlossen.

Dieses Modul scheitert mit H7006:

```hilde fails H7006
import Standard.Buffer (Buffer);
import Standard.String (String);
import Standard.StringBuilder (StringBuilder, makeStringBuilder, finalize);
import Standard.Template (Render);

module body Example is
    record Page: Linear is
        title: String;
        motto: Option[String];
        items: Buffer[Index];
        admin: Bool;
        count: Int32;
    end;

    generic [R: Region]
    function render(page: &[Page, R]): String is
        var out: StringBuilder := makeStringBuilder();
        @template("page.jinja", page, out);
        return finalize(out);
    end;

    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Daneben `page.jinja`:

```jinja file page.jinja
<p>{# a note</p>
```

Die richtige Form:

```hilde
import Standard.Buffer (Buffer);
import Standard.String (String);
import Standard.StringBuilder (StringBuilder, makeStringBuilder, finalize);
import Standard.Template (Render);

module body Example is
    record Page: Linear is
        title: String;
        motto: Option[String];
        items: Buffer[Index];
        admin: Bool;
        count: Int32;
    end;

    generic [R: Region]
    function render(page: &[Page, R]): String is
        var out: StringBuilder := makeStringBuilder();
        @template("page.jinja", page, out);
        return finalize(out);
    end;

    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Daneben `page.jinja`:

```jinja file page.jinja
<p>{# a note #}</p>
```

### H7007

Meldung:

```text
Generic Error
@template: this {% raw %} is never closed with {% endraw %}
```

Ein {% raw %} wird nie mit {% endraw %} geschlossen.

Dieses Modul scheitert mit H7007:

```hilde fails H7007
import Standard.Buffer (Buffer);
import Standard.String (String);
import Standard.StringBuilder (StringBuilder, makeStringBuilder, finalize);
import Standard.Template (Render);

module body Example is
    record Page: Linear is
        title: String;
        motto: Option[String];
        items: Buffer[Index];
        admin: Bool;
        count: Int32;
    end;

    generic [R: Region]
    function render(page: &[Page, R]): String is
        var out: StringBuilder := makeStringBuilder();
        @template("page.jinja", page, out);
        return finalize(out);
    end;

    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Daneben `page.jinja`:

```jinja file page.jinja
<p>{% raw %}{{ title }}</p>
```

Die richtige Form:

```hilde
import Standard.Buffer (Buffer);
import Standard.String (String);
import Standard.StringBuilder (StringBuilder, makeStringBuilder, finalize);
import Standard.Template (Render);

module body Example is
    record Page: Linear is
        title: String;
        motto: Option[String];
        items: Buffer[Index];
        admin: Bool;
        count: Int32;
    end;

    generic [R: Region]
    function render(page: &[Page, R]): String is
        var out: StringBuilder := makeStringBuilder();
        @template("page.jinja", page, out);
        return finalize(out);
    end;

    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Daneben `page.jinja`:

```jinja file page.jinja
<p>{% raw %}{{ title }}{% endraw %}</p>
```

### H7008

Meldung:

```text
Generic Error
@template: {% endraw %} is not closed with %}
```

Im Tag {% endraw %} steht nach endraw noch etwas.

Dieses Modul scheitert mit H7008:

```hilde fails H7008
import Standard.Buffer (Buffer);
import Standard.String (String);
import Standard.StringBuilder (StringBuilder, makeStringBuilder, finalize);
import Standard.Template (Render);

module body Example is
    record Page: Linear is
        title: String;
        motto: Option[String];
        items: Buffer[Index];
        admin: Bool;
        count: Int32;
    end;

    generic [R: Region]
    function render(page: &[Page, R]): String is
        var out: StringBuilder := makeStringBuilder();
        @template("page.jinja", page, out);
        return finalize(out);
    end;

    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Daneben `page.jinja`:

```jinja file page.jinja
<p>{% raw %}x{% endraw now %}</p>
```

Die richtige Form:

```hilde
import Standard.Buffer (Buffer);
import Standard.String (String);
import Standard.StringBuilder (StringBuilder, makeStringBuilder, finalize);
import Standard.Template (Render);

module body Example is
    record Page: Linear is
        title: String;
        motto: Option[String];
        items: Buffer[Index];
        admin: Bool;
        count: Int32;
    end;

    generic [R: Region]
    function render(page: &[Page, R]): String is
        var out: StringBuilder := makeStringBuilder();
        @template("page.jinja", page, out);
        return finalize(out);
    end;

    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Daneben `page.jinja`:

```jinja file page.jinja
<p>{% raw %}x{% endraw %}</p>
```

### H7009

Meldung:

```text
Generic Error
@template: only whole decimal numbers are supported
```

Eine Zahl im Template ist keine ganze Dezimalzahl, etwa 1.5.

Dieses Modul scheitert mit H7009:

```hilde fails H7009
import Standard.Buffer (Buffer);
import Standard.String (String);
import Standard.StringBuilder (StringBuilder, makeStringBuilder, finalize);
import Standard.Template (Render);

module body Example is
    record Page: Linear is
        title: String;
        motto: Option[String];
        items: Buffer[Index];
        admin: Bool;
        count: Int32;
    end;

    generic [R: Region]
    function render(page: &[Page, R]): String is
        var out: StringBuilder := makeStringBuilder();
        @template("page.jinja", page, out);
        return finalize(out);
    end;

    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Daneben `page.jinja`:

```jinja file page.jinja
<p>{{ 1.5 }}</p>
```

Die richtige Form:

```hilde
import Standard.Buffer (Buffer);
import Standard.String (String);
import Standard.StringBuilder (StringBuilder, makeStringBuilder, finalize);
import Standard.Template (Render);

module body Example is
    record Page: Linear is
        title: String;
        motto: Option[String];
        items: Buffer[Index];
        admin: Bool;
        count: Int32;
    end;

    generic [R: Region]
    function render(page: &[Page, R]): String is
        var out: StringBuilder := makeStringBuilder();
        @template("page.jinja", page, out);
        return finalize(out);
    end;

    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Daneben `page.jinja`:

```jinja file page.jinja
<p>{{ 15 }}</p>
```

### H7011

Meldung:

```text
Generic Error
@template: the escape \x in a string is not supported
```

Ein String in einem Tag enthält ein anderes Escape als `\n`, `\t`, `\r`,
`\\`, `\'` und `\"`.

Dieses Modul scheitert mit H7011:

```hilde fails H7011
import Standard.Buffer (Buffer);
import Standard.String (String);
import Standard.StringBuilder (StringBuilder, makeStringBuilder, finalize);
import Standard.Template (Render);

module body Example is
    record Page: Linear is
        title: String;
        motto: Option[String];
        items: Buffer[Index];
        admin: Bool;
        count: Int32;
    end;

    generic [R: Region]
    function render(page: &[Page, R]): String is
        var out: StringBuilder := makeStringBuilder();
        @template("page.jinja", page, out);
        return finalize(out);
    end;

    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Daneben `page.jinja`:

```jinja file page.jinja
<p>{{ "a\x" }}</p>
```

Die richtige Form:

```hilde
import Standard.Buffer (Buffer);
import Standard.String (String);
import Standard.StringBuilder (StringBuilder, makeStringBuilder, finalize);
import Standard.Template (Render);

module body Example is
    record Page: Linear is
        title: String;
        motto: Option[String];
        items: Buffer[Index];
        admin: Bool;
        count: Int32;
    end;

    generic [R: Region]
    function render(page: &[Page, R]): String is
        var out: StringBuilder := makeStringBuilder();
        @template("page.jinja", page, out);
        return finalize(out);
    end;

    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Daneben `page.jinja`:

```jinja file page.jinja
<p>{{ "a\n" }}</p>
```

### H7013

Meldung:

```text
Generic Error
@template: the character ; cannot stand here
```

In einem Tag steht ein Zeichen, das nicht zur Template-Sprache gehört.

Dieses Modul scheitert mit H7013:

```hilde fails H7013
import Standard.Buffer (Buffer);
import Standard.String (String);
import Standard.StringBuilder (StringBuilder, makeStringBuilder, finalize);
import Standard.Template (Render);

module body Example is
    record Page: Linear is
        title: String;
        motto: Option[String];
        items: Buffer[Index];
        admin: Bool;
        count: Int32;
    end;

    generic [R: Region]
    function render(page: &[Page, R]): String is
        var out: StringBuilder := makeStringBuilder();
        @template("page.jinja", page, out);
        return finalize(out);
    end;

    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Daneben `page.jinja`:

```jinja file page.jinja
<p>{{ title; }}</p>
```

Die richtige Form:

```hilde
import Standard.Buffer (Buffer);
import Standard.String (String);
import Standard.StringBuilder (StringBuilder, makeStringBuilder, finalize);
import Standard.Template (Render);

module body Example is
    record Page: Linear is
        title: String;
        motto: Option[String];
        items: Buffer[Index];
        admin: Bool;
        count: Int32;
    end;

    generic [R: Region]
    function render(page: &[Page, R]): String is
        var out: StringBuilder := makeStringBuilder();
        @template("page.jinja", page, out);
        return finalize(out);
    end;

    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Daneben `page.jinja`:

```jinja file page.jinja
<p>{{ title }}</p>
```

### H7014

Meldung:

```text
Generic Error
@template: expected )
```

Dem Ausdruck in einem Tag fehlt ein nötiges Symbol, etwa eine schließende
Klammer.

Dieses Modul scheitert mit H7014:

```hilde fails H7014
import Standard.Buffer (Buffer);
import Standard.String (String);
import Standard.StringBuilder (StringBuilder, makeStringBuilder, finalize);
import Standard.Template (Render);

module body Example is
    record Page: Linear is
        title: String;
        motto: Option[String];
        items: Buffer[Index];
        admin: Bool;
        count: Int32;
    end;

    generic [R: Region]
    function render(page: &[Page, R]): String is
        var out: StringBuilder := makeStringBuilder();
        @template("page.jinja", page, out);
        return finalize(out);
    end;

    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Daneben `page.jinja`:

```jinja file page.jinja
<p>{{ (title }}</p>
```

Die richtige Form:

```hilde
import Standard.Buffer (Buffer);
import Standard.String (String);
import Standard.StringBuilder (StringBuilder, makeStringBuilder, finalize);
import Standard.Template (Render);

module body Example is
    record Page: Linear is
        title: String;
        motto: Option[String];
        items: Buffer[Index];
        admin: Bool;
        count: Int32;
    end;

    generic [R: Region]
    function render(page: &[Page, R]): String is
        var out: StringBuilder := makeStringBuilder();
        @template("page.jinja", page, out);
        return finalize(out);
    end;

    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Daneben `page.jinja`:

```jinja file page.jinja
<p>{{ (title) }}</p>
```

### H7015

Meldung:

```text
Generic Error
@template: expected a name
```

In einem Tag wird ein Name erwartet, und etwas anderes steht dort, etwa nach
einem Punkt.

Dieses Modul scheitert mit H7015:

```hilde fails H7015
import Standard.Buffer (Buffer);
import Standard.String (String);
import Standard.StringBuilder (StringBuilder, makeStringBuilder, finalize);
import Standard.Template (Render);

module body Example is
    record Page: Linear is
        title: String;
        motto: Option[String];
        items: Buffer[Index];
        admin: Bool;
        count: Int32;
    end;

    generic [R: Region]
    function render(page: &[Page, R]): String is
        var out: StringBuilder := makeStringBuilder();
        @template("page.jinja", page, out);
        return finalize(out);
    end;

    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Daneben `page.jinja`:

```jinja file page.jinja
<p>{{ title. }}</p>
```

Die richtige Form:

```hilde
import Standard.Buffer (Buffer);
import Standard.String (String);
import Standard.StringBuilder (StringBuilder, makeStringBuilder, finalize);
import Standard.Template (Render);

module body Example is
    record Page: Linear is
        title: String;
        motto: Option[String];
        items: Buffer[Index];
        admin: Bool;
        count: Int32;
    end;

    generic [R: Region]
    function render(page: &[Page, R]): String is
        var out: StringBuilder := makeStringBuilder();
        @template("page.jinja", page, out);
        return finalize(out);
    end;

    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Daneben `page.jinja`:

```jinja file page.jinja
<p>{{ title }}</p>
```

### H7016

Meldung:

```text
Generic Error
@template: the operator / divides into a fraction, and @template has no fractions; // divides into a whole number
```

In einem Tag steht ein Operator von Jinja2, der hier keine Bedeutung hat: / teilt in einen Bruch, den ein Template hier nicht hat, und ** potenziert, was nach wenigen Schritten jeden ganzzahligen Typ verlässt. // teilt in eine ganze Zahl.

Dieses Modul scheitert mit H7016:

```hilde fails H7016
import Standard.Buffer (Buffer);
import Standard.String (String);
import Standard.StringBuilder (StringBuilder, makeStringBuilder, finalize);
import Standard.Template (Render);

module body Example is
    record Page: Linear is
        title: String;
        motto: Option[String];
        items: Buffer[Index];
        admin: Bool;
        count: Int32;
    end;

    generic [R: Region]
    function render(page: &[Page, R]): String is
        var out: StringBuilder := makeStringBuilder();
        @template("page.jinja", page, out);
        return finalize(out);
    end;

    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Daneben `page.jinja`:

```jinja file page.jinja
<p>{{ count / 2 }}</p>
```

Die richtige Form:

```hilde
import Standard.Buffer (Buffer);
import Standard.String (String);
import Standard.StringBuilder (StringBuilder, makeStringBuilder, finalize);
import Standard.Template (Render);

module body Example is
    record Page: Linear is
        title: String;
        motto: Option[String];
        items: Buffer[Index];
        admin: Bool;
        count: Int32;
    end;

    generic [R: Region]
    function render(page: &[Page, R]): String is
        var out: StringBuilder := makeStringBuilder();
        @template("page.jinja", page, out);
        return finalize(out);
    end;

    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Daneben `page.jinja`:

```jinja file page.jinja
<p>{{ count // 2 }}</p>
```

### H7017

Meldung:

```text
Generic Error
@template: an inline if prints its two values the same way: both |safe, or neither
```

Die beiden Werte eines if ... else in einer Zeile werden verschieden ausgegeben: einer ist mit |safe markiert, der andere nicht. Oder ein if in einer Zeile steht in einer Bedingung, wo and und or dasselbe sagen.

Dieses Modul scheitert mit H7017:

```hilde fails H7017
import Standard.Buffer (Buffer);
import Standard.String (String);
import Standard.StringBuilder (StringBuilder, makeStringBuilder, finalize);
import Standard.Template (Render);

module body Example is
    record Page: Linear is
        title: String;
        motto: Option[String];
        items: Buffer[Index];
        admin: Bool;
        count: Int32;
    end;

    generic [R: Region]
    function render(page: &[Page, R]): String is
        var out: StringBuilder := makeStringBuilder();
        @template("page.jinja", page, out);
        return finalize(out);
    end;

    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Daneben `page.jinja`:

```jinja file page.jinja
<p>{{ title|safe if admin else "guest" }}</p>
```

Die richtige Form:

```hilde
import Standard.Buffer (Buffer);
import Standard.String (String);
import Standard.StringBuilder (StringBuilder, makeStringBuilder, finalize);
import Standard.Template (Render);

module body Example is
    record Page: Linear is
        title: String;
        motto: Option[String];
        items: Buffer[Index];
        admin: Bool;
        count: Int32;
    end;

    generic [R: Region]
    function render(page: &[Page, R]): String is
        var out: StringBuilder := makeStringBuilder();
        @template("page.jinja", page, out);
        return finalize(out);
    end;

    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Daneben `page.jinja`:

```jinja file page.jinja
<p>{{ title if admin else "guest" }}</p>
```

### H7018

Meldung:

```text
Generic Error
@template: `in' asks for a text in quotes or a name of a string
```

Der Operator in fragt einen Namen der Daten, einen String nach einem Teil oder einen Buffer nach einem Element, und er fragt nach einem Text in Anführungszeichen oder dem Namen eines Strings.

Dieses Modul scheitert mit H7018:

```hilde fails H7018
import Standard.Buffer (Buffer);
import Standard.String (String);
import Standard.StringBuilder (StringBuilder, makeStringBuilder, finalize);
import Standard.Template (Render);

module body Example is
    record Page: Linear is
        title: String;
        motto: Option[String];
        items: Buffer[Index];
        admin: Bool;
        count: Int32;
    end;

    generic [R: Region]
    function render(page: &[Page, R]): String is
        var out: StringBuilder := makeStringBuilder();
        @template("page.jinja", page, out);
        return finalize(out);
    end;

    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Daneben `page.jinja`:

```jinja file page.jinja
<p>{% if 1 in items %}one{% endif %}</p>
```

Die richtige Form:

```hilde
import Standard.Buffer (Buffer);
import Standard.String (String);
import Standard.StringBuilder (StringBuilder, makeStringBuilder, finalize);
import Standard.Template (Render);

module body Example is
    record Page: Linear is
        title: String;
        motto: Option[String];
        items: Buffer[Index];
        admin: Bool;
        count: Int32;
    end;

    generic [R: Region]
    function render(page: &[Page, R]): String is
        var out: StringBuilder := makeStringBuilder();
        @template("page.jinja", page, out);
        return finalize(out);
    end;

    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Daneben `page.jinja`:

```jinja file page.jinja
<p>{% if "a" in title %}one{% endif %}</p>
```

### H7019

Meldung:

```text
Generic Error
@template: expected , or )
```

Die Argumente eines Filters sind nicht durch Kommas getrennt oder nicht
geschlossen.

Dieses Modul scheitert mit H7019:

```hilde fails H7019
import Standard.Buffer (Buffer);
import Standard.String (String);
import Standard.StringBuilder (StringBuilder, makeStringBuilder, finalize);
import Standard.Template (Render);

module body Example is
    record Page: Linear is
        title: String;
        motto: Option[String];
        items: Buffer[Index];
        admin: Bool;
        count: Int32;
    end;

    generic [R: Region]
    function render(page: &[Page, R]): String is
        var out: StringBuilder := makeStringBuilder();
        @template("page.jinja", page, out);
        return finalize(out);
    end;

    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Daneben `page.jinja`:

```jinja file page.jinja
<p>{{ title|trim(1 2) }}</p>
```

Die richtige Form:

```hilde
import Standard.Buffer (Buffer);
import Standard.String (String);
import Standard.StringBuilder (StringBuilder, makeStringBuilder, finalize);
import Standard.Template (Render);

module body Example is
    record Page: Linear is
        title: String;
        motto: Option[String];
        items: Buffer[Index];
        admin: Bool;
        count: Int32;
    end;

    generic [R: Region]
    function render(page: &[Page, R]): String is
        var out: StringBuilder := makeStringBuilder();
        @template("page.jinja", page, out);
        return finalize(out);
    end;

    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Daneben `page.jinja`:

```jinja file page.jinja
<p>{{ title|trim }}</p>
```

### H7020

Meldung:

```text
Generic Error
@template: keyword arguments are not supported
```

Ein Makro wird mit einem Schlüsselwort-Argument name=wert aufgerufen.
Argumente stehen nach Position.

Dieses Modul scheitert mit H7020:

```hilde fails H7020
import Standard.Buffer (Buffer);
import Standard.String (String);
import Standard.StringBuilder (StringBuilder, makeStringBuilder, finalize);
import Standard.Template (Render);

module body Example is
    record Page: Linear is
        title: String;
        motto: Option[String];
        items: Buffer[Index];
        admin: Bool;
        count: Int32;
    end;

    generic [R: Region]
    function render(page: &[Page, R]): String is
        var out: StringBuilder := makeStringBuilder();
        @template("page.jinja", page, out);
        return finalize(out);
    end;

    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Daneben `page.jinja`:

```jinja file page.jinja
{% macro show(x) %}<p>{{ x }}</p>{% endmacro %}{{ show(x=title) }}
```

Die richtige Form:

```hilde
import Standard.Buffer (Buffer);
import Standard.String (String);
import Standard.StringBuilder (StringBuilder, makeStringBuilder, finalize);
import Standard.Template (Render);

module body Example is
    record Page: Linear is
        title: String;
        motto: Option[String];
        items: Buffer[Index];
        admin: Bool;
        count: Int32;
    end;

    generic [R: Region]
    function render(page: &[Page, R]): String is
        var out: StringBuilder := makeStringBuilder();
        @template("page.jinja", page, out);
        return finalize(out);
    end;

    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Daneben `page.jinja`:

```jinja file page.jinja
{% macro show(x) %}<p>{{ x }}</p>{% endmacro %}{{ show(title) }}
```

### H7021

Meldung:

```text
Generic Error
@template: expected , or )
```

Die Argumente eines Makroaufrufs sind nicht durch Kommas getrennt oder nicht
geschlossen.

Dieses Modul scheitert mit H7021:

```hilde fails H7021
import Standard.Buffer (Buffer);
import Standard.String (String);
import Standard.StringBuilder (StringBuilder, makeStringBuilder, finalize);
import Standard.Template (Render);

module body Example is
    record Page: Linear is
        title: String;
        motto: Option[String];
        items: Buffer[Index];
        admin: Bool;
        count: Int32;
    end;

    generic [R: Region]
    function render(page: &[Page, R]): String is
        var out: StringBuilder := makeStringBuilder();
        @template("page.jinja", page, out);
        return finalize(out);
    end;

    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Daneben `page.jinja`:

```jinja file page.jinja
{% macro show(x, y) %}<p>{{ x }}{{ y }}</p>{% endmacro %}{{ show(title title) }}
```

Die richtige Form:

```hilde
import Standard.Buffer (Buffer);
import Standard.String (String);
import Standard.StringBuilder (StringBuilder, makeStringBuilder, finalize);
import Standard.Template (Render);

module body Example is
    record Page: Linear is
        title: String;
        motto: Option[String];
        items: Buffer[Index];
        admin: Bool;
        count: Int32;
    end;

    generic [R: Region]
    function render(page: &[Page, R]): String is
        var out: StringBuilder := makeStringBuilder();
        @template("page.jinja", page, out);
        return finalize(out);
    end;

    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Daneben `page.jinja`:

```jinja file page.jinja
{% macro show(x, y) %}<p>{{ x }}{{ y }}</p>{% endmacro %}{{ show(title, title) }}
```

### H7022

Meldung:

```text
Generic Error
@template: calling title.upper: there is no such macro; the part before the dot is not a name an {% import ... as %} gave, or the file has no macro of that name
```

Ein Makro wird über einen Punkt aufgerufen, und der Teil vor dem Punkt ist kein Name, den ein {% import ... as %} vergeben hat, oder die Datei hat kein solches Makro. Eine Methode eines Werts kann nicht aufgerufen werden.

Dieses Modul scheitert mit H7022:

```hilde fails H7022
import Standard.Buffer (Buffer);
import Standard.String (String);
import Standard.StringBuilder (StringBuilder, makeStringBuilder, finalize);
import Standard.Template (Render);

module body Example is
    record Page: Linear is
        title: String;
        motto: Option[String];
        items: Buffer[Index];
        admin: Bool;
        count: Int32;
    end;

    generic [R: Region]
    function render(page: &[Page, R]): String is
        var out: StringBuilder := makeStringBuilder();
        @template("page.jinja", page, out);
        return finalize(out);
    end;

    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Daneben `page.jinja`:

```jinja file page.jinja
<p>{{ title.upper() }}</p>
```

Die richtige Form:

```hilde
import Standard.Buffer (Buffer);
import Standard.String (String);
import Standard.StringBuilder (StringBuilder, makeStringBuilder, finalize);
import Standard.Template (Render);

module body Example is
    record Page: Linear is
        title: String;
        motto: Option[String];
        items: Buffer[Index];
        admin: Bool;
        count: Int32;
    end;

    generic [R: Region]
    function render(page: &[Page, R]): String is
        var out: StringBuilder := makeStringBuilder();
        @template("page.jinja", page, out);
        return finalize(out);
    end;

    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Daneben `page.jinja`:

```jinja file page.jinja
<p>{{ title|upper }}</p>
```

### H7023

Meldung:

```text
Generic Error
@template: [ ] takes a name in quotes, as in a["b"]: an index into a list fails when the page is rendered if the list is shorter, which a compiled template cannot allow
```

In eckigen Klammern steht etwas anderes als ein Name in Anführungszeichen. Ein Index in eine Liste scheitert, wenn Jinja2 die Seite ausgibt und die Liste kürzer ist; ein kompiliertes Template erlaubt das nicht.

Dieses Modul scheitert mit H7023:

```hilde fails H7023
import Standard.Buffer (Buffer);
import Standard.String (String);
import Standard.StringBuilder (StringBuilder, makeStringBuilder, finalize);
import Standard.Template (Render);

module body Example is
    record Page: Linear is
        title: String;
        motto: Option[String];
        items: Buffer[Index];
        admin: Bool;
        count: Int32;
    end;

    generic [R: Region]
    function render(page: &[Page, R]): String is
        var out: StringBuilder := makeStringBuilder();
        @template("page.jinja", page, out);
        return finalize(out);
    end;

    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Daneben `page.jinja`:

```jinja file page.jinja
<p>{{ items[0] }}</p>
```

Die richtige Form:

```hilde
import Standard.Buffer (Buffer);
import Standard.String (String);
import Standard.StringBuilder (StringBuilder, makeStringBuilder, finalize);
import Standard.Template (Render);

module body Example is
    record Page: Linear is
        title: String;
        motto: Option[String];
        items: Buffer[Index];
        admin: Bool;
        count: Int32;
    end;

    generic [R: Region]
    function render(page: &[Page, R]): String is
        var out: StringBuilder := makeStringBuilder();
        @template("page.jinja", page, out);
        return finalize(out);
    end;

    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Daneben `page.jinja`:

```jinja file page.jinja
<p>{% for item in items %}{% if loop.first %}{{ item }}{% endif %}{% endfor %}</p>
```

### H7024

Meldung:

```text
Generic Error
@template: a minus sign stands before a number only; write 0 - x to subtract from zero
```

Ein Minuszeichen steht vor einem Namen. Eine negative Zahl steht mit dem Minuszeichen vor ihren Ziffern; ein Name wird von null abgezogen.

Dieses Modul scheitert mit H7024:

```hilde fails H7024
import Standard.Buffer (Buffer);
import Standard.String (String);
import Standard.StringBuilder (StringBuilder, makeStringBuilder, finalize);
import Standard.Template (Render);

module body Example is
    record Page: Linear is
        title: String;
        motto: Option[String];
        items: Buffer[Index];
        admin: Bool;
        count: Int32;
    end;

    generic [R: Region]
    function render(page: &[Page, R]): String is
        var out: StringBuilder := makeStringBuilder();
        @template("page.jinja", page, out);
        return finalize(out);
    end;

    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Daneben `page.jinja`:

```jinja file page.jinja
<p>{{ -count }}</p>
```

Die richtige Form:

```hilde
import Standard.Buffer (Buffer);
import Standard.String (String);
import Standard.StringBuilder (StringBuilder, makeStringBuilder, finalize);
import Standard.Template (Render);

module body Example is
    record Page: Linear is
        title: String;
        motto: Option[String];
        items: Buffer[Index];
        admin: Bool;
        count: Int32;
    end;

    generic [R: Region]
    function render(page: &[Page, R]): String is
        var out: StringBuilder := makeStringBuilder();
        @template("page.jinja", page, out);
        return finalize(out);
    end;

    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Daneben `page.jinja`:

```jinja file page.jinja
<p>{{ 0 - count }}</p>
```

### H7025

Meldung:

```text
Generic Error
@template: unexpected )
```

In einem Tag steht ein Symbol, wo ein Ausdruck beginnen sollte.

Dieses Modul scheitert mit H7025:

```hilde fails H7025
import Standard.Buffer (Buffer);
import Standard.String (String);
import Standard.StringBuilder (StringBuilder, makeStringBuilder, finalize);
import Standard.Template (Render);

module body Example is
    record Page: Linear is
        title: String;
        motto: Option[String];
        items: Buffer[Index];
        admin: Bool;
        count: Int32;
    end;

    generic [R: Region]
    function render(page: &[Page, R]): String is
        var out: StringBuilder := makeStringBuilder();
        @template("page.jinja", page, out);
        return finalize(out);
    end;

    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Daneben `page.jinja`:

```jinja file page.jinja
<p>{{ ) }}</p>
```

Die richtige Form:

```hilde
import Standard.Buffer (Buffer);
import Standard.String (String);
import Standard.StringBuilder (StringBuilder, makeStringBuilder, finalize);
import Standard.Template (Render);

module body Example is
    record Page: Linear is
        title: String;
        motto: Option[String];
        items: Buffer[Index];
        admin: Bool;
        count: Int32;
    end;

    generic [R: Region]
    function render(page: &[Page, R]): String is
        var out: StringBuilder := makeStringBuilder();
        @template("page.jinja", page, out);
        return finalize(out);
    end;

    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Daneben `page.jinja`:

```jinja file page.jinja
<p>{{ title }}</p>
```

### H7026

Meldung:

```text
Generic Error
@template: an expression is missing
```

Ein Tag enthält keinen Ausdruck.

Dieses Modul scheitert mit H7026:

```hilde fails H7026
import Standard.Buffer (Buffer);
import Standard.String (String);
import Standard.StringBuilder (StringBuilder, makeStringBuilder, finalize);
import Standard.Template (Render);

module body Example is
    record Page: Linear is
        title: String;
        motto: Option[String];
        items: Buffer[Index];
        admin: Bool;
        count: Int32;
    end;

    generic [R: Region]
    function render(page: &[Page, R]): String is
        var out: StringBuilder := makeStringBuilder();
        @template("page.jinja", page, out);
        return finalize(out);
    end;

    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Daneben `page.jinja`:

```jinja file page.jinja
<p>{{ }}</p>
```

Die richtige Form:

```hilde
import Standard.Buffer (Buffer);
import Standard.String (String);
import Standard.StringBuilder (StringBuilder, makeStringBuilder, finalize);
import Standard.Template (Render);

module body Example is
    record Page: Linear is
        title: String;
        motto: Option[String];
        items: Buffer[Index];
        admin: Bool;
        count: Int32;
    end;

    generic [R: Region]
    function render(page: &[Page, R]): String is
        var out: StringBuilder := makeStringBuilder();
        @template("page.jinja", page, out);
        return finalize(out);
    end;

    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Daneben `page.jinja`:

```jinja file page.jinja
<p>{{ title }}</p>
```

### H7027

Meldung:

```text
Generic Error
@template: unexpected text after the expression
```

Auf einen Ausdruck in einem Tag folgt weiterer Text.

Dieses Modul scheitert mit H7027:

```hilde fails H7027
import Standard.Buffer (Buffer);
import Standard.String (String);
import Standard.StringBuilder (StringBuilder, makeStringBuilder, finalize);
import Standard.Template (Render);

module body Example is
    record Page: Linear is
        title: String;
        motto: Option[String];
        items: Buffer[Index];
        admin: Bool;
        count: Int32;
    end;

    generic [R: Region]
    function render(page: &[Page, R]): String is
        var out: StringBuilder := makeStringBuilder();
        @template("page.jinja", page, out);
        return finalize(out);
    end;

    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Daneben `page.jinja`:

```jinja file page.jinja
<p>{{ title title }}</p>
```

Die richtige Form:

```hilde
import Standard.Buffer (Buffer);
import Standard.String (String);
import Standard.StringBuilder (StringBuilder, makeStringBuilder, finalize);
import Standard.Template (Render);

module body Example is
    record Page: Linear is
        title: String;
        motto: Option[String];
        items: Buffer[Index];
        admin: Bool;
        count: Int32;
    end;

    generic [R: Region]
    function render(page: &[Page, R]): String is
        var out: StringBuilder := makeStringBuilder();
        @template("page.jinja", page, out);
        return finalize(out);
    end;

    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Daneben `page.jinja`:

```jinja file page.jinja
<p>{{ title }}</p>
```

### H7028

Meldung:

```text
Generic Error
@template: a {% %} tag must begin with a keyword
```

Ein {% %}-Tag beginnt nicht mit einem Schlüsselwort.

Dieses Modul scheitert mit H7028:

```hilde fails H7028
import Standard.Buffer (Buffer);
import Standard.String (String);
import Standard.StringBuilder (StringBuilder, makeStringBuilder, finalize);
import Standard.Template (Render);

module body Example is
    record Page: Linear is
        title: String;
        motto: Option[String];
        items: Buffer[Index];
        admin: Bool;
        count: Int32;
    end;

    generic [R: Region]
    function render(page: &[Page, R]): String is
        var out: StringBuilder := makeStringBuilder();
        @template("page.jinja", page, out);
        return finalize(out);
    end;

    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Daneben `page.jinja`:

```jinja file page.jinja
<p>{% = title %}</p>
```

Die richtige Form:

```hilde
import Standard.Buffer (Buffer);
import Standard.String (String);
import Standard.StringBuilder (StringBuilder, makeStringBuilder, finalize);
import Standard.Template (Render);

module body Example is
    record Page: Linear is
        title: String;
        motto: Option[String];
        items: Buffer[Index];
        admin: Bool;
        count: Int32;
    end;

    generic [R: Region]
    function render(page: &[Page, R]): String is
        var out: StringBuilder := makeStringBuilder();
        @template("page.jinja", page, out);
        return finalize(out);
    end;

    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Daneben `page.jinja`:

```jinja file page.jinja
<p>{{ title }}</p>
```

### H7029

Meldung:

```text
Generic Error
@template: {% do %} is not supported
```

Ein {% %}-Tag verwendet ein Schlüsselwort, das diese Template-Sprache nicht
kennt, etwa do.

Dieses Modul scheitert mit H7029:

```hilde fails H7029
import Standard.Buffer (Buffer);
import Standard.String (String);
import Standard.StringBuilder (StringBuilder, makeStringBuilder, finalize);
import Standard.Template (Render);

module body Example is
    record Page: Linear is
        title: String;
        motto: Option[String];
        items: Buffer[Index];
        admin: Bool;
        count: Int32;
    end;

    generic [R: Region]
    function render(page: &[Page, R]): String is
        var out: StringBuilder := makeStringBuilder();
        @template("page.jinja", page, out);
        return finalize(out);
    end;

    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Daneben `page.jinja`:

```jinja file page.jinja
{% do title %}<p>{{ title }}</p>
```

Die richtige Form:

```hilde
import Standard.Buffer (Buffer);
import Standard.String (String);
import Standard.StringBuilder (StringBuilder, makeStringBuilder, finalize);
import Standard.Template (Render);

module body Example is
    record Page: Linear is
        title: String;
        motto: Option[String];
        items: Buffer[Index];
        admin: Bool;
        count: Int32;
    end;

    generic [R: Region]
    function render(page: &[Page, R]): String is
        var out: StringBuilder := makeStringBuilder();
        @template("page.jinja", page, out);
        return finalize(out);
    end;

    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Daneben `page.jinja`:

```jinja file page.jinja
<p>{{ title }}</p>
```

### H7030

Meldung:

```text
Generic Error
@template: {% include %} takes the template's name and nothing after it
```

Ein {% include %} oder {% extends %} nimmt den Namen des Templates und
nichts danach.

Dieses Modul scheitert mit H7030:

```hilde fails H7030
import Standard.Buffer (Buffer);
import Standard.String (String);
import Standard.StringBuilder (StringBuilder, makeStringBuilder, finalize);
import Standard.Template (Render);

module body Example is
    record Page: Linear is
        title: String;
        motto: Option[String];
        items: Buffer[Index];
        admin: Bool;
        count: Int32;
    end;

    generic [R: Region]
    function render(page: &[Page, R]): String is
        var out: StringBuilder := makeStringBuilder();
        @template("page.jinja", page, out);
        return finalize(out);
    end;

    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Daneben `page.jinja`:

```jinja file page.jinja
{% include "part.jinja" "more" %}
```

Daneben `part.jinja`:

```jinja file part.jinja
<p>{{ title }}</p>
```

Die richtige Form:

```hilde
import Standard.Buffer (Buffer);
import Standard.String (String);
import Standard.StringBuilder (StringBuilder, makeStringBuilder, finalize);
import Standard.Template (Render);

module body Example is
    record Page: Linear is
        title: String;
        motto: Option[String];
        items: Buffer[Index];
        admin: Bool;
        count: Int32;
    end;

    generic [R: Region]
    function render(page: &[Page, R]): String is
        var out: StringBuilder := makeStringBuilder();
        @template("page.jinja", page, out);
        return finalize(out);
    end;

    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Daneben `page.jinja`:

```jinja file page.jinja
{% include "part.jinja" %}
```

Daneben `part.jinja`:

```jinja file part.jinja
<p>{{ title }}</p>
```

### H7031

Meldung:

```text
Generic Error
@template: {% include %} takes a string literal: a template chosen when the page is rendered cannot be compiled
```

Ein {% include %} oder {% extends %} bekommt einen Namen, der kein
String-Literal ist. Ein erst beim Rendern gewähltes Template lässt sich
nicht kompilieren.

Dieses Modul scheitert mit H7031:

```hilde fails H7031
import Standard.Buffer (Buffer);
import Standard.String (String);
import Standard.StringBuilder (StringBuilder, makeStringBuilder, finalize);
import Standard.Template (Render);

module body Example is
    record Page: Linear is
        title: String;
        motto: Option[String];
        items: Buffer[Index];
        admin: Bool;
        count: Int32;
    end;

    generic [R: Region]
    function render(page: &[Page, R]): String is
        var out: StringBuilder := makeStringBuilder();
        @template("page.jinja", page, out);
        return finalize(out);
    end;

    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Daneben `page.jinja`:

```jinja file page.jinja
{% include title %}
```

Daneben `part.jinja`:

```jinja file part.jinja
<p>{{ title }}</p>
```

Die richtige Form:

```hilde
import Standard.Buffer (Buffer);
import Standard.String (String);
import Standard.StringBuilder (StringBuilder, makeStringBuilder, finalize);
import Standard.Template (Render);

module body Example is
    record Page: Linear is
        title: String;
        motto: Option[String];
        items: Buffer[Index];
        admin: Bool;
        count: Int32;
    end;

    generic [R: Region]
    function render(page: &[Page, R]): String is
        var out: StringBuilder := makeStringBuilder();
        @template("page.jinja", page, out);
        return finalize(out);
    end;

    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Daneben `page.jinja`:

```jinja file page.jinja
{% include "part.jinja" %}
```

Daneben `part.jinja`:

```jinja file part.jinja
<p>{{ title }}</p>
```

### H7032

Meldung:

```text
Generic Error
@template: {% import %} takes a string literal, `as' and a name: {% import "file" as name %}
```

Einem {% import %} fehlen `as` und ein Name, oder es verlangt mit `with context` den Kontext des Templates. Ein importiertes Makro sieht die Daten des Templates nicht.

Dieses Modul scheitert mit H7032:

```hilde fails H7032
import Standard.Buffer (Buffer);
import Standard.String (String);
import Standard.StringBuilder (StringBuilder, makeStringBuilder, finalize);
import Standard.Template (Render);

module body Example is
    record Page: Linear is
        title: String;
        motto: Option[String];
        items: Buffer[Index];
        admin: Bool;
        count: Int32;
    end;

    generic [R: Region]
    function render(page: &[Page, R]): String is
        var out: StringBuilder := makeStringBuilder();
        @template("page.jinja", page, out);
        return finalize(out);
    end;

    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Daneben `page.jinja`:

```jinja file page.jinja
{% import "macros.jinja" %}<p>{{ title }}</p>
```

Daneben `macros.jinja`:

```jinja file macros.jinja
{% macro show(text) %}<b>{{ text }}</b>{% endmacro %}
```

Die richtige Form:

```hilde
import Standard.Buffer (Buffer);
import Standard.String (String);
import Standard.StringBuilder (StringBuilder, makeStringBuilder, finalize);
import Standard.Template (Render);

module body Example is
    record Page: Linear is
        title: String;
        motto: Option[String];
        items: Buffer[Index];
        admin: Bool;
        count: Int32;
    end;

    generic [R: Region]
    function render(page: &[Page, R]): String is
        var out: StringBuilder := makeStringBuilder();
        @template("page.jinja", page, out);
        return finalize(out);
    end;

    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Daneben `page.jinja`:

```jinja file page.jinja
{% import "macros.jinja" as lib %}<p>{{ lib.show(title) }}</p>
```

Daneben `macros.jinja`:

```jinja file macros.jinja
{% macro show(text) %}<b>{{ text }}</b>{% endmacro %}
```

### H7033

Meldung:

```text
Generic Error
@template: {% autoescape %} is refused: escaping cannot be switched off for a stretch of template -- write |safe on the one value that is meant to go out unescaped, where a grep finds it
```

Ein Template verwendet {% autoescape %}. Das Maskieren lässt sich nicht
abschnittsweise abschalten; der eine Wert, der unmaskiert hinaus soll,
bekommt `|safe`.

Dieses Modul scheitert mit H7033:

```hilde fails H7033
import Standard.Buffer (Buffer);
import Standard.String (String);
import Standard.StringBuilder (StringBuilder, makeStringBuilder, finalize);
import Standard.Template (Render);

module body Example is
    record Page: Linear is
        title: String;
        motto: Option[String];
        items: Buffer[Index];
        admin: Bool;
        count: Int32;
    end;

    generic [R: Region]
    function render(page: &[Page, R]): String is
        var out: StringBuilder := makeStringBuilder();
        @template("page.jinja", page, out);
        return finalize(out);
    end;

    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Daneben `page.jinja`:

```jinja file page.jinja
{% autoescape false %}<p>{{ title }}</p>{% endautoescape %}
```

Die richtige Form:

```hilde
import Standard.Buffer (Buffer);
import Standard.String (String);
import Standard.StringBuilder (StringBuilder, makeStringBuilder, finalize);
import Standard.Template (Render);

module body Example is
    record Page: Linear is
        title: String;
        motto: Option[String];
        items: Buffer[Index];
        admin: Bool;
        count: Int32;
    end;

    generic [R: Region]
    function render(page: &[Page, R]): String is
        var out: StringBuilder := makeStringBuilder();
        @template("page.jinja", page, out);
        return finalize(out);
    end;

    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Daneben `page.jinja`:

```jinja file page.jinja
<p>{{ title|safe }}</p>
```

### H7034

Meldung:

```text
Generic Error
@template: {% endif %} without the tag it belongs to
```

Ein schließender oder fortsetzender Tag wie {% endif %} oder {% else %}
steht ohne seinen öffnenden Tag.

Dieses Modul scheitert mit H7034:

```hilde fails H7034
import Standard.Buffer (Buffer);
import Standard.String (String);
import Standard.StringBuilder (StringBuilder, makeStringBuilder, finalize);
import Standard.Template (Render);

module body Example is
    record Page: Linear is
        title: String;
        motto: Option[String];
        items: Buffer[Index];
        admin: Bool;
        count: Int32;
    end;

    generic [R: Region]
    function render(page: &[Page, R]): String is
        var out: StringBuilder := makeStringBuilder();
        @template("page.jinja", page, out);
        return finalize(out);
    end;

    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Daneben `page.jinja`:

```jinja file page.jinja
<p>{{ title }}</p>{% endif %}
```

Die richtige Form:

```hilde
import Standard.Buffer (Buffer);
import Standard.String (String);
import Standard.StringBuilder (StringBuilder, makeStringBuilder, finalize);
import Standard.Template (Render);

module body Example is
    record Page: Linear is
        title: String;
        motto: Option[String];
        items: Buffer[Index];
        admin: Bool;
        count: Int32;
    end;

    generic [R: Region]
    function render(page: &[Page, R]): String is
        var out: StringBuilder := makeStringBuilder();
        @template("page.jinja", page, out);
        return finalize(out);
    end;

    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Daneben `page.jinja`:

```jinja file page.jinja
<p>{{ title }}</p>
```

### H7035

Meldung:

```text
Generic Error
@template: {% else %} without {% endif %}
```

Auf ein {% else %} eines {% if %} folgt kein {% endif %}.

Dieses Modul scheitert mit H7035:

```hilde fails H7035
import Standard.Buffer (Buffer);
import Standard.String (String);
import Standard.StringBuilder (StringBuilder, makeStringBuilder, finalize);
import Standard.Template (Render);

module body Example is
    record Page: Linear is
        title: String;
        motto: Option[String];
        items: Buffer[Index];
        admin: Bool;
        count: Int32;
    end;

    generic [R: Region]
    function render(page: &[Page, R]): String is
        var out: StringBuilder := makeStringBuilder();
        @template("page.jinja", page, out);
        return finalize(out);
    end;

    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Daneben `page.jinja`:

```jinja file page.jinja
{% if admin %}<p>admin</p>{% else %}<p>guest</p>
```

Die richtige Form:

```hilde
import Standard.Buffer (Buffer);
import Standard.String (String);
import Standard.StringBuilder (StringBuilder, makeStringBuilder, finalize);
import Standard.Template (Render);

module body Example is
    record Page: Linear is
        title: String;
        motto: Option[String];
        items: Buffer[Index];
        admin: Bool;
        count: Int32;
    end;

    generic [R: Region]
    function render(page: &[Page, R]): String is
        var out: StringBuilder := makeStringBuilder();
        @template("page.jinja", page, out);
        return finalize(out);
    end;

    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Daneben `page.jinja`:

```jinja file page.jinja
{% if admin %}<p>admin</p>{% else %}<p>guest</p>{% endif %}
```

### H7036

Meldung:

```text
Generic Error
@template: {% if %} without {% endif %}
```

Ein {% if %} wird nie mit {% endif %} geschlossen.

Dieses Modul scheitert mit H7036:

```hilde fails H7036
import Standard.Buffer (Buffer);
import Standard.String (String);
import Standard.StringBuilder (StringBuilder, makeStringBuilder, finalize);
import Standard.Template (Render);

module body Example is
    record Page: Linear is
        title: String;
        motto: Option[String];
        items: Buffer[Index];
        admin: Bool;
        count: Int32;
    end;

    generic [R: Region]
    function render(page: &[Page, R]): String is
        var out: StringBuilder := makeStringBuilder();
        @template("page.jinja", page, out);
        return finalize(out);
    end;

    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Daneben `page.jinja`:

```jinja file page.jinja
{% if admin %}<p>admin</p>
```

Die richtige Form:

```hilde
import Standard.Buffer (Buffer);
import Standard.String (String);
import Standard.StringBuilder (StringBuilder, makeStringBuilder, finalize);
import Standard.Template (Render);

module body Example is
    record Page: Linear is
        title: String;
        motto: Option[String];
        items: Buffer[Index];
        admin: Bool;
        count: Int32;
    end;

    generic [R: Region]
    function render(page: &[Page, R]): String is
        var out: StringBuilder := makeStringBuilder();
        @template("page.jinja", page, out);
        return finalize(out);
    end;

    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Daneben `page.jinja`:

```jinja file page.jinja
{% if admin %}<p>admin</p>{% endif %}
```

### H7037

Meldung:

```text
Generic Error
@template: {% for %} takes one name, or two or three that unpack a Pair or a Triple of Standard.Tuples
```

Ein {% for %} nennt mehr als drei Namen. Ein Name nimmt das Element; zwei oder drei entpacken ein Pair oder ein Triple aus Standard.Tuples.

Dieses Modul scheitert mit H7037:

```hilde fails H7037
import Standard.Buffer (Buffer);
import Standard.String (String);
import Standard.StringBuilder (StringBuilder, makeStringBuilder, finalize);
import Standard.Template (Render);

module body Example is
    record Page: Linear is
        title: String;
        motto: Option[String];
        items: Buffer[Index];
        admin: Bool;
        count: Int32;
    end;

    generic [R: Region]
    function render(page: &[Page, R]): String is
        var out: StringBuilder := makeStringBuilder();
        @template("page.jinja", page, out);
        return finalize(out);
    end;

    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Daneben `page.jinja`:

```jinja file page.jinja
{% for a, b, c, d in items %}{{ a }}{% endfor %}
```

Die richtige Form:

```hilde
import Standard.Buffer (Buffer);
import Standard.String (String);
import Standard.StringBuilder (StringBuilder, makeStringBuilder, finalize);
import Standard.Template (Render);

module body Example is
    record Page: Linear is
        title: String;
        motto: Option[String];
        items: Buffer[Index];
        admin: Bool;
        count: Int32;
    end;

    generic [R: Region]
    function render(page: &[Page, R]): String is
        var out: StringBuilder := makeStringBuilder();
        @template("page.jinja", page, out);
        return finalize(out);
    end;

    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Daneben `page.jinja`:

```jinja file page.jinja
{% for item in items %}{{ item }}{% endfor %}
```

### H7038

Meldung:

```text
Generic Error
@template: expected `in' in {% for %}
```

Einem {% for %} fehlt das Wort in.

Dieses Modul scheitert mit H7038:

```hilde fails H7038
import Standard.Buffer (Buffer);
import Standard.String (String);
import Standard.StringBuilder (StringBuilder, makeStringBuilder, finalize);
import Standard.Template (Render);

module body Example is
    record Page: Linear is
        title: String;
        motto: Option[String];
        items: Buffer[Index];
        admin: Bool;
        count: Int32;
    end;

    generic [R: Region]
    function render(page: &[Page, R]): String is
        var out: StringBuilder := makeStringBuilder();
        @template("page.jinja", page, out);
        return finalize(out);
    end;

    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Daneben `page.jinja`:

```jinja file page.jinja
{% for item of items %}{{ item }}{% endfor %}
```

Die richtige Form:

```hilde
import Standard.Buffer (Buffer);
import Standard.String (String);
import Standard.StringBuilder (StringBuilder, makeStringBuilder, finalize);
import Standard.Template (Render);

module body Example is
    record Page: Linear is
        title: String;
        motto: Option[String];
        items: Buffer[Index];
        admin: Bool;
        count: Int32;
    end;

    generic [R: Region]
    function render(page: &[Page, R]): String is
        var out: StringBuilder := makeStringBuilder();
        @template("page.jinja", page, out);
        return finalize(out);
    end;

    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Daneben `page.jinja`:

```jinja file page.jinja
{% for item in items %}{{ item }}{% endfor %}
```

### H7039

Meldung:

```text
Generic Error
@template: after {% for ... in ... %} only `if' and a condition may follow
```

Nach der Folge eines {% for %} steht etwas anderes als `if` und eine Bedingung, etwa `recursive`.

Dieses Modul scheitert mit H7039:

```hilde fails H7039
import Standard.Buffer (Buffer);
import Standard.String (String);
import Standard.StringBuilder (StringBuilder, makeStringBuilder, finalize);
import Standard.Template (Render);

module body Example is
    record Page: Linear is
        title: String;
        motto: Option[String];
        items: Buffer[Index];
        admin: Bool;
        count: Int32;
    end;

    generic [R: Region]
    function render(page: &[Page, R]): String is
        var out: StringBuilder := makeStringBuilder();
        @template("page.jinja", page, out);
        return finalize(out);
    end;

    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Daneben `page.jinja`:

```jinja file page.jinja
{% for item in items recursive %}{{ item }}{% endfor %}
```

Die richtige Form:

```hilde
import Standard.Buffer (Buffer);
import Standard.String (String);
import Standard.StringBuilder (StringBuilder, makeStringBuilder, finalize);
import Standard.Template (Render);

module body Example is
    record Page: Linear is
        title: String;
        motto: Option[String];
        items: Buffer[Index];
        admin: Bool;
        count: Int32;
    end;

    generic [R: Region]
    function render(page: &[Page, R]): String is
        var out: StringBuilder := makeStringBuilder();
        @template("page.jinja", page, out);
        return finalize(out);
    end;

    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Daneben `page.jinja`:

```jinja file page.jinja
{% for item in items if item > 1 %}{{ item }}{% endfor %}
```

### H7040

Meldung:

```text
Generic Error
@template: {% else %} without {% endfor %}
```

Auf ein {% else %} eines {% for %} folgt kein {% endfor %}.

Dieses Modul scheitert mit H7040:

```hilde fails H7040
import Standard.Buffer (Buffer);
import Standard.String (String);
import Standard.StringBuilder (StringBuilder, makeStringBuilder, finalize);
import Standard.Template (Render);

module body Example is
    record Page: Linear is
        title: String;
        motto: Option[String];
        items: Buffer[Index];
        admin: Bool;
        count: Int32;
    end;

    generic [R: Region]
    function render(page: &[Page, R]): String is
        var out: StringBuilder := makeStringBuilder();
        @template("page.jinja", page, out);
        return finalize(out);
    end;

    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Daneben `page.jinja`:

```jinja file page.jinja
{% for item in items %}{{ item }}{% else %}<p>none</p>
```

Die richtige Form:

```hilde
import Standard.Buffer (Buffer);
import Standard.String (String);
import Standard.StringBuilder (StringBuilder, makeStringBuilder, finalize);
import Standard.Template (Render);

module body Example is
    record Page: Linear is
        title: String;
        motto: Option[String];
        items: Buffer[Index];
        admin: Bool;
        count: Int32;
    end;

    generic [R: Region]
    function render(page: &[Page, R]): String is
        var out: StringBuilder := makeStringBuilder();
        @template("page.jinja", page, out);
        return finalize(out);
    end;

    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Daneben `page.jinja`:

```jinja file page.jinja
{% for item in items %}{{ item }}{% else %}<p>none</p>{% endfor %}
```

### H7041

Meldung:

```text
Generic Error
@template: {% for %} without {% endfor %}
```

Ein {% for %} wird nie mit {% endfor %} geschlossen.

Dieses Modul scheitert mit H7041:

```hilde fails H7041
import Standard.Buffer (Buffer);
import Standard.String (String);
import Standard.StringBuilder (StringBuilder, makeStringBuilder, finalize);
import Standard.Template (Render);

module body Example is
    record Page: Linear is
        title: String;
        motto: Option[String];
        items: Buffer[Index];
        admin: Bool;
        count: Int32;
    end;

    generic [R: Region]
    function render(page: &[Page, R]): String is
        var out: StringBuilder := makeStringBuilder();
        @template("page.jinja", page, out);
        return finalize(out);
    end;

    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Daneben `page.jinja`:

```jinja file page.jinja
{% for item in items %}{{ item }}
```

Die richtige Form:

```hilde
import Standard.Buffer (Buffer);
import Standard.String (String);
import Standard.StringBuilder (StringBuilder, makeStringBuilder, finalize);
import Standard.Template (Render);

module body Example is
    record Page: Linear is
        title: String;
        motto: Option[String];
        items: Buffer[Index];
        admin: Bool;
        count: Int32;
    end;

    generic [R: Region]
    function render(page: &[Page, R]): String is
        var out: StringBuilder := makeStringBuilder();
        @template("page.jinja", page, out);
        return finalize(out);
    end;

    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Daneben `page.jinja`:

```jinja file page.jinja
{% for item in items %}{{ item }}{% endfor %}
```

### H7042

Meldung:

```text
Generic Error
@template: a `required' block is not supported
```

Ein Block ist als required markiert.

Dieses Modul scheitert mit H7042:

```hilde fails H7042
import Standard.Buffer (Buffer);
import Standard.String (String);
import Standard.StringBuilder (StringBuilder, makeStringBuilder, finalize);
import Standard.Template (Render);

module body Example is
    record Page: Linear is
        title: String;
        motto: Option[String];
        items: Buffer[Index];
        admin: Bool;
        count: Int32;
    end;

    generic [R: Region]
    function render(page: &[Page, R]): String is
        var out: StringBuilder := makeStringBuilder();
        @template("page.jinja", page, out);
        return finalize(out);
    end;

    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Daneben `page.jinja`:

```jinja file page.jinja
{% block main required %}<p>{{ title }}</p>{% endblock %}
```

Die richtige Form:

```hilde
import Standard.Buffer (Buffer);
import Standard.String (String);
import Standard.StringBuilder (StringBuilder, makeStringBuilder, finalize);
import Standard.Template (Render);

module body Example is
    record Page: Linear is
        title: String;
        motto: Option[String];
        items: Buffer[Index];
        admin: Bool;
        count: Int32;
    end;

    generic [R: Region]
    function render(page: &[Page, R]): String is
        var out: StringBuilder := makeStringBuilder();
        @template("page.jinja", page, out);
        return finalize(out);
    end;

    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Daneben `page.jinja`:

```jinja file page.jinja
{% block main %}<p>{{ title }}</p>{% endblock %}
```

### H7043

Meldung:

```text
Generic Error
@template: {% block %} takes a name, and `scoped' after it
```

Ein {% block %} hat keinen Namen oder danach etwas anderes als scoped.

Dieses Modul scheitert mit H7043:

```hilde fails H7043
import Standard.Buffer (Buffer);
import Standard.String (String);
import Standard.StringBuilder (StringBuilder, makeStringBuilder, finalize);
import Standard.Template (Render);

module body Example is
    record Page: Linear is
        title: String;
        motto: Option[String];
        items: Buffer[Index];
        admin: Bool;
        count: Int32;
    end;

    generic [R: Region]
    function render(page: &[Page, R]): String is
        var out: StringBuilder := makeStringBuilder();
        @template("page.jinja", page, out);
        return finalize(out);
    end;

    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Daneben `page.jinja`:

```jinja file page.jinja
{% block %}<p>{{ title }}</p>{% endblock %}
```

Die richtige Form:

```hilde
import Standard.Buffer (Buffer);
import Standard.String (String);
import Standard.StringBuilder (StringBuilder, makeStringBuilder, finalize);
import Standard.Template (Render);

module body Example is
    record Page: Linear is
        title: String;
        motto: Option[String];
        items: Buffer[Index];
        admin: Bool;
        count: Int32;
    end;

    generic [R: Region]
    function render(page: &[Page, R]): String is
        var out: StringBuilder := makeStringBuilder();
        @template("page.jinja", page, out);
        return finalize(out);
    end;

    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Daneben `page.jinja`:

```jinja file page.jinja
{% block main %}<p>{{ title }}</p>{% endblock %}
```

### H7044

Meldung:

```text
Generic Error
@template: {% block main %} without {% endblock %}
```

Ein {% block %} wird nie mit {% endblock %} geschlossen.

Dieses Modul scheitert mit H7044:

```hilde fails H7044
import Standard.Buffer (Buffer);
import Standard.String (String);
import Standard.StringBuilder (StringBuilder, makeStringBuilder, finalize);
import Standard.Template (Render);

module body Example is
    record Page: Linear is
        title: String;
        motto: Option[String];
        items: Buffer[Index];
        admin: Bool;
        count: Int32;
    end;

    generic [R: Region]
    function render(page: &[Page, R]): String is
        var out: StringBuilder := makeStringBuilder();
        @template("page.jinja", page, out);
        return finalize(out);
    end;

    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Daneben `page.jinja`:

```jinja file page.jinja
{% block main %}<p>{{ title }}</p>
```

Die richtige Form:

```hilde
import Standard.Buffer (Buffer);
import Standard.String (String);
import Standard.StringBuilder (StringBuilder, makeStringBuilder, finalize);
import Standard.Template (Render);

module body Example is
    record Page: Linear is
        title: String;
        motto: Option[String];
        items: Buffer[Index];
        admin: Bool;
        count: Int32;
    end;

    generic [R: Region]
    function render(page: &[Page, R]): String is
        var out: StringBuilder := makeStringBuilder();
        @template("page.jinja", page, out);
        return finalize(out);
    end;

    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Daneben `page.jinja`:

```jinja file page.jinja
{% block main %}<p>{{ title }}</p>{% endblock %}
```

### H7045

Meldung:

```text
Generic Error
@template: {% endblock side %} closes {% block main %}
```

Ein {% endblock %} nennt einen anderen Block als den, den es schließt.

Dieses Modul scheitert mit H7045:

```hilde fails H7045
import Standard.Buffer (Buffer);
import Standard.String (String);
import Standard.StringBuilder (StringBuilder, makeStringBuilder, finalize);
import Standard.Template (Render);

module body Example is
    record Page: Linear is
        title: String;
        motto: Option[String];
        items: Buffer[Index];
        admin: Bool;
        count: Int32;
    end;

    generic [R: Region]
    function render(page: &[Page, R]): String is
        var out: StringBuilder := makeStringBuilder();
        @template("page.jinja", page, out);
        return finalize(out);
    end;

    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Daneben `page.jinja`:

```jinja file page.jinja
{% block main %}<p>{{ title }}</p>{% endblock side %}
```

Die richtige Form:

```hilde
import Standard.Buffer (Buffer);
import Standard.String (String);
import Standard.StringBuilder (StringBuilder, makeStringBuilder, finalize);
import Standard.Template (Render);

module body Example is
    record Page: Linear is
        title: String;
        motto: Option[String];
        items: Buffer[Index];
        admin: Bool;
        count: Int32;
    end;

    generic [R: Region]
    function render(page: &[Page, R]): String is
        var out: StringBuilder := makeStringBuilder();
        @template("page.jinja", page, out);
        return finalize(out);
    end;

    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Daneben `page.jinja`:

```jinja file page.jinja
{% block main %}<p>{{ title }}</p>{% endblock main %}
```

### H7046

Meldung:

```text
Generic Error
@template: a macro parameter's default is a literal
```

Der Vorgabewert eines Makroparameters ist kein Literal.

Dieses Modul scheitert mit H7046:

```hilde fails H7046
import Standard.Buffer (Buffer);
import Standard.String (String);
import Standard.StringBuilder (StringBuilder, makeStringBuilder, finalize);
import Standard.Template (Render);

module body Example is
    record Page: Linear is
        title: String;
        motto: Option[String];
        items: Buffer[Index];
        admin: Bool;
        count: Int32;
    end;

    generic [R: Region]
    function render(page: &[Page, R]): String is
        var out: StringBuilder := makeStringBuilder();
        @template("page.jinja", page, out);
        return finalize(out);
    end;

    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Daneben `page.jinja`:

```jinja file page.jinja
{% macro show(x=title) %}{{ x }}{% endmacro %}<p>{{ show() }}</p>
```

Die richtige Form:

```hilde
import Standard.Buffer (Buffer);
import Standard.String (String);
import Standard.StringBuilder (StringBuilder, makeStringBuilder, finalize);
import Standard.Template (Render);

module body Example is
    record Page: Linear is
        title: String;
        motto: Option[String];
        items: Buffer[Index];
        admin: Bool;
        count: Int32;
    end;

    generic [R: Region]
    function render(page: &[Page, R]): String is
        var out: StringBuilder := makeStringBuilder();
        @template("page.jinja", page, out);
        return finalize(out);
    end;

    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Daneben `page.jinja`:

```jinja file page.jinja
{% macro show(x="none") %}{{ x }}{% endmacro %}<p>{{ show() }}</p>
```

### H7047

Meldung:

```text
Generic Error
@template: expected , or ) in the macro's parameters
```

Die Parameter eines Makros sind nicht durch Kommas getrennt.

Dieses Modul scheitert mit H7047:

```hilde fails H7047
import Standard.Buffer (Buffer);
import Standard.String (String);
import Standard.StringBuilder (StringBuilder, makeStringBuilder, finalize);
import Standard.Template (Render);

module body Example is
    record Page: Linear is
        title: String;
        motto: Option[String];
        items: Buffer[Index];
        admin: Bool;
        count: Int32;
    end;

    generic [R: Region]
    function render(page: &[Page, R]): String is
        var out: StringBuilder := makeStringBuilder();
        @template("page.jinja", page, out);
        return finalize(out);
    end;

    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Daneben `page.jinja`:

```jinja file page.jinja
{% macro show(x y) %}{{ x }}{% endmacro %}<p>{{ show(title, title) }}</p>
```

Die richtige Form:

```hilde
import Standard.Buffer (Buffer);
import Standard.String (String);
import Standard.StringBuilder (StringBuilder, makeStringBuilder, finalize);
import Standard.Template (Render);

module body Example is
    record Page: Linear is
        title: String;
        motto: Option[String];
        items: Buffer[Index];
        admin: Bool;
        count: Int32;
    end;

    generic [R: Region]
    function render(page: &[Page, R]): String is
        var out: StringBuilder := makeStringBuilder();
        @template("page.jinja", page, out);
        return finalize(out);
    end;

    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Daneben `page.jinja`:

```jinja file page.jinja
{% macro show(x, y) %}{{ x }}{% endmacro %}<p>{{ show(title, title) }}</p>
```

### H7048

Meldung:

```text
Generic Error
@template: unexpected text after the macro's parameters
```

Auf die Parameterliste eines Makros folgt weiterer Text.

Dieses Modul scheitert mit H7048:

```hilde fails H7048
import Standard.Buffer (Buffer);
import Standard.String (String);
import Standard.StringBuilder (StringBuilder, makeStringBuilder, finalize);
import Standard.Template (Render);

module body Example is
    record Page: Linear is
        title: String;
        motto: Option[String];
        items: Buffer[Index];
        admin: Bool;
        count: Int32;
    end;

    generic [R: Region]
    function render(page: &[Page, R]): String is
        var out: StringBuilder := makeStringBuilder();
        @template("page.jinja", page, out);
        return finalize(out);
    end;

    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Daneben `page.jinja`:

```jinja file page.jinja
{% macro show(x) now %}{{ x }}{% endmacro %}<p>{{ show(title) }}</p>
```

Die richtige Form:

```hilde
import Standard.Buffer (Buffer);
import Standard.String (String);
import Standard.StringBuilder (StringBuilder, makeStringBuilder, finalize);
import Standard.Template (Render);

module body Example is
    record Page: Linear is
        title: String;
        motto: Option[String];
        items: Buffer[Index];
        admin: Bool;
        count: Int32;
    end;

    generic [R: Region]
    function render(page: &[Page, R]): String is
        var out: StringBuilder := makeStringBuilder();
        @template("page.jinja", page, out);
        return finalize(out);
    end;

    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Daneben `page.jinja`:

```jinja file page.jinja
{% macro show(x) %}{{ x }}{% endmacro %}<p>{{ show(title) }}</p>
```

### H7049

Meldung:

```text
Generic Error
@template: {% macro show %} without {% endmacro %}
```

Ein {% macro %} wird nie mit {% endmacro %} geschlossen.

Dieses Modul scheitert mit H7049:

```hilde fails H7049
import Standard.Buffer (Buffer);
import Standard.String (String);
import Standard.StringBuilder (StringBuilder, makeStringBuilder, finalize);
import Standard.Template (Render);

module body Example is
    record Page: Linear is
        title: String;
        motto: Option[String];
        items: Buffer[Index];
        admin: Bool;
        count: Int32;
    end;

    generic [R: Region]
    function render(page: &[Page, R]): String is
        var out: StringBuilder := makeStringBuilder();
        @template("page.jinja", page, out);
        return finalize(out);
    end;

    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Daneben `page.jinja`:

```jinja file page.jinja
{% macro show(x) %}{{ x }}
```

Die richtige Form:

```hilde
import Standard.Buffer (Buffer);
import Standard.String (String);
import Standard.StringBuilder (StringBuilder, makeStringBuilder, finalize);
import Standard.Template (Render);

module body Example is
    record Page: Linear is
        title: String;
        motto: Option[String];
        items: Buffer[Index];
        admin: Bool;
        count: Int32;
    end;

    generic [R: Region]
    function render(page: &[Page, R]): String is
        var out: StringBuilder := makeStringBuilder();
        @template("page.jinja", page, out);
        return finalize(out);
    end;

    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Daneben `page.jinja`:

```jinja file page.jinja
{% macro show(x) %}{{ x }}{% endmacro %}<p>{{ show(title) }}</p>
```

### H7050

Meldung:

```text
Generic Error
@template: `as' in {% from ... import %} is not supported
```

Ein {% from ... import %} gibt einem importierten Makro mit as einen anderen
Namen.

Dieses Modul scheitert mit H7050:

```hilde fails H7050
import Standard.Buffer (Buffer);
import Standard.String (String);
import Standard.StringBuilder (StringBuilder, makeStringBuilder, finalize);
import Standard.Template (Render);

module body Example is
    record Page: Linear is
        title: String;
        motto: Option[String];
        items: Buffer[Index];
        admin: Bool;
        count: Int32;
    end;

    generic [R: Region]
    function render(page: &[Page, R]): String is
        var out: StringBuilder := makeStringBuilder();
        @template("page.jinja", page, out);
        return finalize(out);
    end;

    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Daneben `page.jinja`:

```jinja file page.jinja
{% from "macros.jinja" import show as display %}<p>{{ display(title) }}</p>
```

Daneben `macros.jinja`:

```jinja file macros.jinja
{% macro show(x) %}{{ x }}{% endmacro %}
```

Die richtige Form:

```hilde
import Standard.Buffer (Buffer);
import Standard.String (String);
import Standard.StringBuilder (StringBuilder, makeStringBuilder, finalize);
import Standard.Template (Render);

module body Example is
    record Page: Linear is
        title: String;
        motto: Option[String];
        items: Buffer[Index];
        admin: Bool;
        count: Int32;
    end;

    generic [R: Region]
    function render(page: &[Page, R]): String is
        var out: StringBuilder := makeStringBuilder();
        @template("page.jinja", page, out);
        return finalize(out);
    end;

    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Daneben `page.jinja`:

```jinja file page.jinja
{% from "macros.jinja" import show %}<p>{{ show(title) }}</p>
```

Daneben `macros.jinja`:

```jinja file macros.jinja
{% macro show(x) %}{{ x }}{% endmacro %}
```

### H7051

Meldung:

```text
Generic Error
@template: {% from "file" import a, b %} names the macros to import, and nothing else
```

Ein {% from ... import %} nennt etwas anderes als Makros.

Dieses Modul scheitert mit H7051:

```hilde fails H7051
import Standard.Buffer (Buffer);
import Standard.String (String);
import Standard.StringBuilder (StringBuilder, makeStringBuilder, finalize);
import Standard.Template (Render);

module body Example is
    record Page: Linear is
        title: String;
        motto: Option[String];
        items: Buffer[Index];
        admin: Bool;
        count: Int32;
    end;

    generic [R: Region]
    function render(page: &[Page, R]): String is
        var out: StringBuilder := makeStringBuilder();
        @template("page.jinja", page, out);
        return finalize(out);
    end;

    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Daneben `page.jinja`:

```jinja file page.jinja
{% from "macros.jinja" import 1 %}<p>{{ title }}</p>
```

Daneben `macros.jinja`:

```jinja file macros.jinja
{% macro show(x) %}{{ x }}{% endmacro %}
```

Die richtige Form:

```hilde
import Standard.Buffer (Buffer);
import Standard.String (String);
import Standard.StringBuilder (StringBuilder, makeStringBuilder, finalize);
import Standard.Template (Render);

module body Example is
    record Page: Linear is
        title: String;
        motto: Option[String];
        items: Buffer[Index];
        admin: Bool;
        count: Int32;
    end;

    generic [R: Region]
    function render(page: &[Page, R]): String is
        var out: StringBuilder := makeStringBuilder();
        @template("page.jinja", page, out);
        return finalize(out);
    end;

    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Daneben `page.jinja`:

```jinja file page.jinja
{% from "macros.jinja" import show %}<p>{{ show(title) }}</p>
```

Daneben `macros.jinja`:

```jinja file macros.jinja
{% macro show(x) %}{{ x }}{% endmacro %}
```

### H7052

Meldung:

```text
Generic Error
@template: {% from %} takes a string literal and `import'
```

Einem {% from %} fehlt der Dateiname als String oder das Wort import.

Dieses Modul scheitert mit H7052:

```hilde fails H7052
import Standard.Buffer (Buffer);
import Standard.String (String);
import Standard.StringBuilder (StringBuilder, makeStringBuilder, finalize);
import Standard.Template (Render);

module body Example is
    record Page: Linear is
        title: String;
        motto: Option[String];
        items: Buffer[Index];
        admin: Bool;
        count: Int32;
    end;

    generic [R: Region]
    function render(page: &[Page, R]): String is
        var out: StringBuilder := makeStringBuilder();
        @template("page.jinja", page, out);
        return finalize(out);
    end;

    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Daneben `page.jinja`:

```jinja file page.jinja
{% from macros import show %}<p>{{ show(title) }}</p>
```

Daneben `macros.jinja`:

```jinja file macros.jinja
{% macro show(x) %}{{ x }}{% endmacro %}
```

Die richtige Form:

```hilde
import Standard.Buffer (Buffer);
import Standard.String (String);
import Standard.StringBuilder (StringBuilder, makeStringBuilder, finalize);
import Standard.Template (Render);

module body Example is
    record Page: Linear is
        title: String;
        motto: Option[String];
        items: Buffer[Index];
        admin: Bool;
        count: Int32;
    end;

    generic [R: Region]
    function render(page: &[Page, R]): String is
        var out: StringBuilder := makeStringBuilder();
        @template("page.jinja", page, out);
        return finalize(out);
    end;

    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Daneben `page.jinja`:

```jinja file page.jinja
{% from "macros.jinja" import show %}<p>{{ show(title) }}</p>
```

Daneben `macros.jinja`:

```jinja file macros.jinja
{% macro show(x) %}{{ x }}{% endmacro %}
```

### H7054

Meldung:

```text
Generic Error
@template: the macro show is defined twice
```

Ein Makro wird zweimal mit zwei Rümpfen definiert.

Dieses Modul scheitert mit H7054:

```hilde fails H7054
import Standard.Buffer (Buffer);
import Standard.String (String);
import Standard.StringBuilder (StringBuilder, makeStringBuilder, finalize);
import Standard.Template (Render);

module body Example is
    record Page: Linear is
        title: String;
        motto: Option[String];
        items: Buffer[Index];
        admin: Bool;
        count: Int32;
    end;

    generic [R: Region]
    function render(page: &[Page, R]): String is
        var out: StringBuilder := makeStringBuilder();
        @template("page.jinja", page, out);
        return finalize(out);
    end;

    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Daneben `page.jinja`:

```jinja file page.jinja
{% macro show(x) %}{{ x }}{% endmacro %}{% macro show(x) %}<b>{{ x }}</b>{% endmacro %}<p>{{ show(title) }}</p>
```

Die richtige Form:

```hilde
import Standard.Buffer (Buffer);
import Standard.String (String);
import Standard.StringBuilder (StringBuilder, makeStringBuilder, finalize);
import Standard.Template (Render);

module body Example is
    record Page: Linear is
        title: String;
        motto: Option[String];
        items: Buffer[Index];
        admin: Bool;
        count: Int32;
    end;

    generic [R: Region]
    function render(page: &[Page, R]): String is
        var out: StringBuilder := makeStringBuilder();
        @template("page.jinja", page, out);
        return finalize(out);
    end;

    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Daneben `page.jinja`:

```jinja file page.jinja
{% macro show(x) %}{{ x }}{% endmacro %}{% macro bold(x) %}<b>{{ x }}</b>{% endmacro %}<p>{{ show(title) }}</p>
```

### H7055

Meldung:

```text
Generic Error
@template: "macros.jinja" imports from itself
```

Ein Template importiert Makros aus sich selbst.

Dieses Modul scheitert mit H7055:

```hilde fails H7055
import Standard.Buffer (Buffer);
import Standard.String (String);
import Standard.StringBuilder (StringBuilder, makeStringBuilder, finalize);
import Standard.Template (Render);

module body Example is
    record Page: Linear is
        title: String;
        motto: Option[String];
        items: Buffer[Index];
        admin: Bool;
        count: Int32;
    end;

    generic [R: Region]
    function render(page: &[Page, R]): String is
        var out: StringBuilder := makeStringBuilder();
        @template("page.jinja", page, out);
        return finalize(out);
    end;

    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Daneben `page.jinja`:

```jinja file page.jinja
{% from "macros.jinja" import show %}<p>{{ show(title) }}</p>
```

Daneben `macros.jinja`:

```jinja file macros.jinja
{% from "macros.jinja" import show %}{% macro show(x) %}{{ x }}{% endmacro %}
```

Die richtige Form:

```hilde
import Standard.Buffer (Buffer);
import Standard.String (String);
import Standard.StringBuilder (StringBuilder, makeStringBuilder, finalize);
import Standard.Template (Render);

module body Example is
    record Page: Linear is
        title: String;
        motto: Option[String];
        items: Buffer[Index];
        admin: Bool;
        count: Int32;
    end;

    generic [R: Region]
    function render(page: &[Page, R]): String is
        var out: StringBuilder := makeStringBuilder();
        @template("page.jinja", page, out);
        return finalize(out);
    end;

    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Daneben `page.jinja`:

```jinja file page.jinja
{% from "macros.jinja" import show %}<p>{{ show(title) }}</p>
```

Daneben `macros.jinja`:

```jinja file macros.jinja
{% macro show(x) %}{{ x }}{% endmacro %}
```

### H7056

Meldung:

```text
Generic Error
@template: "macros.jinja" has no macro display
```

Ein {% from ... import %} nennt ein Makro, das die Datei nicht definiert.

Dieses Modul scheitert mit H7056:

```hilde fails H7056
import Standard.Buffer (Buffer);
import Standard.String (String);
import Standard.StringBuilder (StringBuilder, makeStringBuilder, finalize);
import Standard.Template (Render);

module body Example is
    record Page: Linear is
        title: String;
        motto: Option[String];
        items: Buffer[Index];
        admin: Bool;
        count: Int32;
    end;

    generic [R: Region]
    function render(page: &[Page, R]): String is
        var out: StringBuilder := makeStringBuilder();
        @template("page.jinja", page, out);
        return finalize(out);
    end;

    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Daneben `page.jinja`:

```jinja file page.jinja
{% from "macros.jinja" import display %}<p>{{ title }}</p>
```

Daneben `macros.jinja`:

```jinja file macros.jinja
{% macro show(x) %}{{ x }}{% endmacro %}
```

Die richtige Form:

```hilde
import Standard.Buffer (Buffer);
import Standard.String (String);
import Standard.StringBuilder (StringBuilder, makeStringBuilder, finalize);
import Standard.Template (Render);

module body Example is
    record Page: Linear is
        title: String;
        motto: Option[String];
        items: Buffer[Index];
        admin: Bool;
        count: Int32;
    end;

    generic [R: Region]
    function render(page: &[Page, R]): String is
        var out: StringBuilder := makeStringBuilder();
        @template("page.jinja", page, out);
        return finalize(out);
    end;

    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Daneben `page.jinja`:

```jinja file page.jinja
{% from "macros.jinja" import show %}<p>{{ show(title) }}</p>
```

Daneben `macros.jinja`:

```jinja file macros.jinja
{% macro show(x) %}{{ x }}{% endmacro %}
```

### H7057

Meldung:

```text
Generic Error
@template: "page.jinja" includes or extends itself: page.jinja -> part.jinja -> page.jinja
```

Ein Template bindet sich selbst ein oder erweitert sich selbst, direkt oder
über andere.

Dieses Modul scheitert mit H7057:

```hilde fails H7057
import Standard.Buffer (Buffer);
import Standard.String (String);
import Standard.StringBuilder (StringBuilder, makeStringBuilder, finalize);
import Standard.Template (Render);

module body Example is
    record Page: Linear is
        title: String;
        motto: Option[String];
        items: Buffer[Index];
        admin: Bool;
        count: Int32;
    end;

    generic [R: Region]
    function render(page: &[Page, R]): String is
        var out: StringBuilder := makeStringBuilder();
        @template("page.jinja", page, out);
        return finalize(out);
    end;

    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Daneben `page.jinja`:

```jinja file page.jinja
{% include "part.jinja" %}
```

Daneben `part.jinja`:

```jinja file part.jinja
<p>{{ title }}</p>{% include "page.jinja" %}
```

Die richtige Form:

```hilde
import Standard.Buffer (Buffer);
import Standard.String (String);
import Standard.StringBuilder (StringBuilder, makeStringBuilder, finalize);
import Standard.Template (Render);

module body Example is
    record Page: Linear is
        title: String;
        motto: Option[String];
        items: Buffer[Index];
        admin: Bool;
        count: Int32;
    end;

    generic [R: Region]
    function render(page: &[Page, R]): String is
        var out: StringBuilder := makeStringBuilder();
        @template("page.jinja", page, out);
        return finalize(out);
    end;

    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Daneben `page.jinja`:

```jinja file page.jinja
{% include "part.jinja" %}
```

Daneben `part.jinja`:

```jinja file part.jinja
<p>{{ title }}</p>
```

### H7058

Meldung:

```text
Generic Error
@template: a template extends one other template, once
```

Ein Template erweitert ein zweites Mal.

Dieses Modul scheitert mit H7058:

```hilde fails H7058
import Standard.Buffer (Buffer);
import Standard.String (String);
import Standard.StringBuilder (StringBuilder, makeStringBuilder, finalize);
import Standard.Template (Render);

module body Example is
    record Page: Linear is
        title: String;
        motto: Option[String];
        items: Buffer[Index];
        admin: Bool;
        count: Int32;
    end;

    generic [R: Region]
    function render(page: &[Page, R]): String is
        var out: StringBuilder := makeStringBuilder();
        @template("page.jinja", page, out);
        return finalize(out);
    end;

    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Daneben `page.jinja`:

```jinja file page.jinja
{% extends "base.jinja" %}{% extends "base.jinja" %}{% block main %}{{ title }}{% endblock %}
```

Daneben `base.jinja`:

```jinja file base.jinja
<html>{% block main %}{% endblock %}</html>
```

Die richtige Form:

```hilde
import Standard.Buffer (Buffer);
import Standard.String (String);
import Standard.StringBuilder (StringBuilder, makeStringBuilder, finalize);
import Standard.Template (Render);

module body Example is
    record Page: Linear is
        title: String;
        motto: Option[String];
        items: Buffer[Index];
        admin: Bool;
        count: Int32;
    end;

    generic [R: Region]
    function render(page: &[Page, R]): String is
        var out: StringBuilder := makeStringBuilder();
        @template("page.jinja", page, out);
        return finalize(out);
    end;

    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Daneben `page.jinja`:

```jinja file page.jinja
{% extends "base.jinja" %}{% block main %}{{ title }}{% endblock %}
```

Daneben `base.jinja`:

```jinja file base.jinja
<html>{% block main %}{% endblock %}</html>
```

### H7059

Meldung:

```text
Generic Error
@template: text after {% extends %} and outside a block is dropped by Jinja2; here it is refused
```

Nach {% extends %} steht Text außerhalb eines Blocks. Jinja2 würde ihn
verwerfen; hier wird er abgelehnt.

Dieses Modul scheitert mit H7059:

```hilde fails H7059
import Standard.Buffer (Buffer);
import Standard.String (String);
import Standard.StringBuilder (StringBuilder, makeStringBuilder, finalize);
import Standard.Template (Render);

module body Example is
    record Page: Linear is
        title: String;
        motto: Option[String];
        items: Buffer[Index];
        admin: Bool;
        count: Int32;
    end;

    generic [R: Region]
    function render(page: &[Page, R]): String is
        var out: StringBuilder := makeStringBuilder();
        @template("page.jinja", page, out);
        return finalize(out);
    end;

    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Daneben `page.jinja`:

```jinja file page.jinja
{% extends "base.jinja" %}lost text{% block main %}{{ title }}{% endblock %}
```

Daneben `base.jinja`:

```jinja file base.jinja
<html>{% block main %}{% endblock %}</html>
```

Die richtige Form:

```hilde
import Standard.Buffer (Buffer);
import Standard.String (String);
import Standard.StringBuilder (StringBuilder, makeStringBuilder, finalize);
import Standard.Template (Render);

module body Example is
    record Page: Linear is
        title: String;
        motto: Option[String];
        items: Buffer[Index];
        admin: Bool;
        count: Int32;
    end;

    generic [R: Region]
    function render(page: &[Page, R]): String is
        var out: StringBuilder := makeStringBuilder();
        @template("page.jinja", page, out);
        return finalize(out);
    end;

    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Daneben `page.jinja`:

```jinja file page.jinja
{% extends "base.jinja" %}{% block main %}{{ title }}{% endblock %}
```

Daneben `base.jinja`:

```jinja file base.jinja
<html>{% block main %}{% endblock %}</html>
```

### H7060

Meldung:

```text
Generic Error
@template: a value after {% extends %} and outside a block is dropped by Jinja2; here it is refused
```

Nach {% extends %} steht ein Wert außerhalb eines Blocks.

Dieses Modul scheitert mit H7060:

```hilde fails H7060
import Standard.Buffer (Buffer);
import Standard.String (String);
import Standard.StringBuilder (StringBuilder, makeStringBuilder, finalize);
import Standard.Template (Render);

module body Example is
    record Page: Linear is
        title: String;
        motto: Option[String];
        items: Buffer[Index];
        admin: Bool;
        count: Int32;
    end;

    generic [R: Region]
    function render(page: &[Page, R]): String is
        var out: StringBuilder := makeStringBuilder();
        @template("page.jinja", page, out);
        return finalize(out);
    end;

    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Daneben `page.jinja`:

```jinja file page.jinja
{% extends "base.jinja" %}{{ title }}{% block main %}{{ title }}{% endblock %}
```

Daneben `base.jinja`:

```jinja file base.jinja
<html>{% block main %}{% endblock %}</html>
```

Die richtige Form:

```hilde
import Standard.Buffer (Buffer);
import Standard.String (String);
import Standard.StringBuilder (StringBuilder, makeStringBuilder, finalize);
import Standard.Template (Render);

module body Example is
    record Page: Linear is
        title: String;
        motto: Option[String];
        items: Buffer[Index];
        admin: Bool;
        count: Int32;
    end;

    generic [R: Region]
    function render(page: &[Page, R]): String is
        var out: StringBuilder := makeStringBuilder();
        @template("page.jinja", page, out);
        return finalize(out);
    end;

    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Daneben `page.jinja`:

```jinja file page.jinja
{% extends "base.jinja" %}{% block main %}{{ title }}{% endblock %}
```

Daneben `base.jinja`:

```jinja file base.jinja
<html>{% block main %}{% endblock %}</html>
```

### H7061

Meldung:

```text
Generic Error
@template: an if or a for after {% extends %} and outside a block is dropped by Jinja2; here it is refused
```

Nach {% extends %} steht ein {% if %} oder {% for %} außerhalb eines Blocks.

Dieses Modul scheitert mit H7061:

```hilde fails H7061
import Standard.Buffer (Buffer);
import Standard.String (String);
import Standard.StringBuilder (StringBuilder, makeStringBuilder, finalize);
import Standard.Template (Render);

module body Example is
    record Page: Linear is
        title: String;
        motto: Option[String];
        items: Buffer[Index];
        admin: Bool;
        count: Int32;
    end;

    generic [R: Region]
    function render(page: &[Page, R]): String is
        var out: StringBuilder := makeStringBuilder();
        @template("page.jinja", page, out);
        return finalize(out);
    end;

    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Daneben `page.jinja`:

```jinja file page.jinja
{% extends "base.jinja" %}{% if admin %}{% endif %}{% block main %}{{ title }}{% endblock %}
```

Daneben `base.jinja`:

```jinja file base.jinja
<html>{% block main %}{% endblock %}</html>
```

Die richtige Form:

```hilde
import Standard.Buffer (Buffer);
import Standard.String (String);
import Standard.StringBuilder (StringBuilder, makeStringBuilder, finalize);
import Standard.Template (Render);

module body Example is
    record Page: Linear is
        title: String;
        motto: Option[String];
        items: Buffer[Index];
        admin: Bool;
        count: Int32;
    end;

    generic [R: Region]
    function render(page: &[Page, R]): String is
        var out: StringBuilder := makeStringBuilder();
        @template("page.jinja", page, out);
        return finalize(out);
    end;

    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Daneben `page.jinja`:

```jinja file page.jinja
{% extends "base.jinja" %}{% block main %}{% if admin %}{{ title }}{% endif %}{% endblock %}
```

Daneben `base.jinja`:

```jinja file base.jinja
<html>{% block main %}{% endblock %}</html>
```

### H7062

Meldung:

```text
Generic Error
@template: an include after {% extends %} and outside a block is dropped by Jinja2; here it is refused
```

Nach {% extends %} steht ein {% include %} außerhalb eines Blocks.

Dieses Modul scheitert mit H7062:

```hilde fails H7062
import Standard.Buffer (Buffer);
import Standard.String (String);
import Standard.StringBuilder (StringBuilder, makeStringBuilder, finalize);
import Standard.Template (Render);

module body Example is
    record Page: Linear is
        title: String;
        motto: Option[String];
        items: Buffer[Index];
        admin: Bool;
        count: Int32;
    end;

    generic [R: Region]
    function render(page: &[Page, R]): String is
        var out: StringBuilder := makeStringBuilder();
        @template("page.jinja", page, out);
        return finalize(out);
    end;

    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Daneben `page.jinja`:

```jinja file page.jinja
{% extends "base.jinja" %}{% include "part.jinja" %}{% block main %}{{ title }}{% endblock %}
```

Daneben `base.jinja`:

```jinja file base.jinja
<html>{% block main %}{% endblock %}</html>
```

Daneben `part.jinja`:

```jinja file part.jinja
<p>{{ title }}</p>
```

Die richtige Form:

```hilde
import Standard.Buffer (Buffer);
import Standard.String (String);
import Standard.StringBuilder (StringBuilder, makeStringBuilder, finalize);
import Standard.Template (Render);

module body Example is
    record Page: Linear is
        title: String;
        motto: Option[String];
        items: Buffer[Index];
        admin: Bool;
        count: Int32;
    end;

    generic [R: Region]
    function render(page: &[Page, R]): String is
        var out: StringBuilder := makeStringBuilder();
        @template("page.jinja", page, out);
        return finalize(out);
    end;

    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Daneben `page.jinja`:

```jinja file page.jinja
{% extends "base.jinja" %}{% block main %}{% include "part.jinja" %}{% endblock %}
```

Daneben `base.jinja`:

```jinja file base.jinja
<html>{% block main %}{% endblock %}</html>
```

Daneben `part.jinja`:

```jinja file part.jinja
<p>{{ title }}</p>
```

### H7063

Meldung:

```text
Generic Error
@template: super() in a block that no template above this one has
```

super() steht in einem Block, den kein Template darüber hat.

Dieses Modul scheitert mit H7063:

```hilde fails H7063
import Standard.Buffer (Buffer);
import Standard.String (String);
import Standard.StringBuilder (StringBuilder, makeStringBuilder, finalize);
import Standard.Template (Render);

module body Example is
    record Page: Linear is
        title: String;
        motto: Option[String];
        items: Buffer[Index];
        admin: Bool;
        count: Int32;
    end;

    generic [R: Region]
    function render(page: &[Page, R]): String is
        var out: StringBuilder := makeStringBuilder();
        @template("page.jinja", page, out);
        return finalize(out);
    end;

    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Daneben `page.jinja`:

```jinja file page.jinja
{% block main %}{{ super() }}<p>{{ title }}</p>{% endblock %}
```

Die richtige Form:

```hilde
import Standard.Buffer (Buffer);
import Standard.String (String);
import Standard.StringBuilder (StringBuilder, makeStringBuilder, finalize);
import Standard.Template (Render);

module body Example is
    record Page: Linear is
        title: String;
        motto: Option[String];
        items: Buffer[Index];
        admin: Bool;
        count: Int32;
    end;

    generic [R: Region]
    function render(page: &[Page, R]): String is
        var out: StringBuilder := makeStringBuilder();
        @template("page.jinja", page, out);
        return finalize(out);
    end;

    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Daneben `page.jinja`:

```jinja file page.jinja
{% block main %}<p>{{ title }}</p>{% endblock %}
```

### H7064

Meldung:

```text
Generic Error
@template: super() takes no arguments
```

super() bekommt Argumente.

Dieses Modul scheitert mit H7064:

```hilde fails H7064
import Standard.Buffer (Buffer);
import Standard.String (String);
import Standard.StringBuilder (StringBuilder, makeStringBuilder, finalize);
import Standard.Template (Render);

module body Example is
    record Page: Linear is
        title: String;
        motto: Option[String];
        items: Buffer[Index];
        admin: Bool;
        count: Int32;
    end;

    generic [R: Region]
    function render(page: &[Page, R]): String is
        var out: StringBuilder := makeStringBuilder();
        @template("page.jinja", page, out);
        return finalize(out);
    end;

    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Daneben `page.jinja`:

```jinja file page.jinja
{% extends "base.jinja" %}{% block main %}{{ super(1) }}{{ title }}{% endblock %}
```

Daneben `base.jinja`:

```jinja file base.jinja
<html>{% block main %}{% endblock %}</html>
```

Die richtige Form:

```hilde
import Standard.Buffer (Buffer);
import Standard.String (String);
import Standard.StringBuilder (StringBuilder, makeStringBuilder, finalize);
import Standard.Template (Render);

module body Example is
    record Page: Linear is
        title: String;
        motto: Option[String];
        items: Buffer[Index];
        admin: Bool;
        count: Int32;
    end;

    generic [R: Region]
    function render(page: &[Page, R]): String is
        var out: StringBuilder := makeStringBuilder();
        @template("page.jinja", page, out);
        return finalize(out);
    end;

    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Daneben `page.jinja`:

```jinja file page.jinja
{% extends "base.jinja" %}{% block main %}{{ super() }}{{ title }}{% endblock %}
```

Daneben `base.jinja`:

```jinja file base.jinja
<html>{% block main %}{% endblock %}</html>
```

### H7065

Meldung:

```text
Generic Error
@template: {% extends %} stands at the top level of a template, once
```

Ein {% extends %} steht in einem anderen Tag, etwa einem {% if %}. Es steht
auf oberster Ebene, einmal.

Dieses Modul scheitert mit H7065:

```hilde fails H7065
import Standard.Buffer (Buffer);
import Standard.String (String);
import Standard.StringBuilder (StringBuilder, makeStringBuilder, finalize);
import Standard.Template (Render);

module body Example is
    record Page: Linear is
        title: String;
        motto: Option[String];
        items: Buffer[Index];
        admin: Bool;
        count: Int32;
    end;

    generic [R: Region]
    function render(page: &[Page, R]): String is
        var out: StringBuilder := makeStringBuilder();
        @template("page.jinja", page, out);
        return finalize(out);
    end;

    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Daneben `page.jinja`:

```jinja file page.jinja
{% if admin %}{% extends "base.jinja" %}{% endif %}<p>{{ title }}</p>
```

Daneben `base.jinja`:

```jinja file base.jinja
<html>{% block main %}{% endblock %}</html>
```

Die richtige Form:

```hilde
import Standard.Buffer (Buffer);
import Standard.String (String);
import Standard.StringBuilder (StringBuilder, makeStringBuilder, finalize);
import Standard.Template (Render);

module body Example is
    record Page: Linear is
        title: String;
        motto: Option[String];
        items: Buffer[Index];
        admin: Bool;
        count: Int32;
    end;

    generic [R: Region]
    function render(page: &[Page, R]): String is
        var out: StringBuilder := makeStringBuilder();
        @template("page.jinja", page, out);
        return finalize(out);
    end;

    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Daneben `page.jinja`:

```jinja file page.jinja
{% extends "base.jinja" %}{% block main %}{{ title }}{% endblock %}
```

Daneben `base.jinja`:

```jinja file base.jinja
<html>{% block main %}{% endblock %}</html>
```

### H7066

Meldung:

```text
Generic Error
@template: the block side is defined here, and no template this one extends has a block of that name; Jinja2 drops it without a word, and here it is refused
```

Ein Template definiert einen Block, den kein erweitertes Template hat.
Jinja2 würde ihn verwerfen; hier wird er abgelehnt.

Dieses Modul scheitert mit H7066:

```hilde fails H7066
import Standard.Buffer (Buffer);
import Standard.String (String);
import Standard.StringBuilder (StringBuilder, makeStringBuilder, finalize);
import Standard.Template (Render);

module body Example is
    record Page: Linear is
        title: String;
        motto: Option[String];
        items: Buffer[Index];
        admin: Bool;
        count: Int32;
    end;

    generic [R: Region]
    function render(page: &[Page, R]): String is
        var out: StringBuilder := makeStringBuilder();
        @template("page.jinja", page, out);
        return finalize(out);
    end;

    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Daneben `page.jinja`:

```jinja file page.jinja
{% extends "base.jinja" %}{% block side %}{{ title }}{% endblock %}
```

Daneben `base.jinja`:

```jinja file base.jinja
<html>{% block main %}{% endblock %}</html>
```

Die richtige Form:

```hilde
import Standard.Buffer (Buffer);
import Standard.String (String);
import Standard.StringBuilder (StringBuilder, makeStringBuilder, finalize);
import Standard.Template (Render);

module body Example is
    record Page: Linear is
        title: String;
        motto: Option[String];
        items: Buffer[Index];
        admin: Bool;
        count: Int32;
    end;

    generic [R: Region]
    function render(page: &[Page, R]): String is
        var out: StringBuilder := makeStringBuilder();
        @template("page.jinja", page, out);
        return finalize(out);
    end;

    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Daneben `page.jinja`:

```jinja file page.jinja
{% extends "base.jinja" %}{% block main %}{{ title }}{% endblock %}
```

Daneben `base.jinja`:

```jinja file base.jinja
<html>{% block main %}{% endblock %}</html>
```

### H7067

Meldung:

```text
Generic Error
@template: a value cannot stand in a tag, between its attributes: there is no escaping that makes that safe
```

Ein Wert steht an einer Stelle des HTML, an der ihn kein Maskieren sicher
macht, etwa im Namen eines Tags oder in seiner Attributliste.

Dieses Modul scheitert mit H7067:

```hilde fails H7067
import Standard.Buffer (Buffer);
import Standard.String (String);
import Standard.StringBuilder (StringBuilder, makeStringBuilder, finalize);
import Standard.Template (Render);

module body Example is
    record Page: Linear is
        title: String;
        motto: Option[String];
        items: Buffer[Index];
        admin: Bool;
        count: Int32;
    end;

    generic [R: Region]
    function render(page: &[Page, R]): String is
        var out: StringBuilder := makeStringBuilder();
        @template("page.jinja", page, out);
        return finalize(out);
    end;

    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Daneben `page.jinja`:

```jinja file page.jinja
<div {{ title }}>x</div>
```

Die richtige Form:

```hilde
import Standard.Buffer (Buffer);
import Standard.String (String);
import Standard.StringBuilder (StringBuilder, makeStringBuilder, finalize);
import Standard.Template (Render);

module body Example is
    record Page: Linear is
        title: String;
        motto: Option[String];
        items: Buffer[Index];
        admin: Bool;
        count: Int32;
    end;

    generic [R: Region]
    function render(page: &[Page, R]): String is
        var out: StringBuilder := makeStringBuilder();
        @template("page.jinja", page, out);
        return finalize(out);
    end;

    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Daneben `page.jinja`:

```jinja file page.jinja
<div title="{{ title }}">x</div>
```

### H7069

Meldung:

```text
Generic Error
@template: `loop' can only be asked for loop.index, loop.index0, loop.revindex, loop.revindex0, loop.length, loop.first, loop.last and loop.cycle(...), inside a {% for %}
```

loop wird für etwas anderes als loop.index, loop.index0, loop.length,
loop.first oder loop.last verwendet.

Dieses Modul scheitert mit H7069:

```hilde fails H7069
import Standard.Buffer (Buffer);
import Standard.String (String);
import Standard.StringBuilder (StringBuilder, makeStringBuilder, finalize);
import Standard.Template (Render);

module body Example is
    record Page: Linear is
        title: String;
        motto: Option[String];
        items: Buffer[Index];
        admin: Bool;
        count: Int32;
    end;

    generic [R: Region]
    function render(page: &[Page, R]): String is
        var out: StringBuilder := makeStringBuilder();
        @template("page.jinja", page, out);
        return finalize(out);
    end;

    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Daneben `page.jinja`:

```jinja file page.jinja
{% for item in items %}{{ loop }}{% endfor %}
```

Die richtige Form:

```hilde
import Standard.Buffer (Buffer);
import Standard.String (String);
import Standard.StringBuilder (StringBuilder, makeStringBuilder, finalize);
import Standard.Template (Render);

module body Example is
    record Page: Linear is
        title: String;
        motto: Option[String];
        items: Buffer[Index];
        admin: Bool;
        count: Int32;
    end;

    generic [R: Region]
    function render(page: &[Page, R]): String is
        var out: StringBuilder := makeStringBuilder();
        @template("page.jinja", page, out);
        return finalize(out);
    end;

    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Daneben `page.jinja`:

```jinja file page.jinja
{% for item in items %}{{ loop.index }}{% endfor %}
```

### H7070

Meldung:

```text
Generic Error
@template: title: a macro brought in with {% from ... import %} or {% import %} does not see the template's data, as in Jinja2 -- pass it as an argument
```

Ein mit {% from ... import %} geholtes Makro verwendet die Daten des
Templates. Ein solches Makro sieht nur seine Argumente.

Dieses Modul scheitert mit H7070:

```hilde fails H7070
import Standard.Buffer (Buffer);
import Standard.String (String);
import Standard.StringBuilder (StringBuilder, makeStringBuilder, finalize);
import Standard.Template (Render);

module body Example is
    record Page: Linear is
        title: String;
        motto: Option[String];
        items: Buffer[Index];
        admin: Bool;
        count: Int32;
    end;

    generic [R: Region]
    function render(page: &[Page, R]): String is
        var out: StringBuilder := makeStringBuilder();
        @template("page.jinja", page, out);
        return finalize(out);
    end;

    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Daneben `page.jinja`:

```jinja file page.jinja
{% from "macros.jinja" import show %}<p>{{ show() }}</p>
```

Daneben `macros.jinja`:

```jinja file macros.jinja
{% macro show() %}{{ title }}{% endmacro %}
```

Die richtige Form:

```hilde
import Standard.Buffer (Buffer);
import Standard.String (String);
import Standard.StringBuilder (StringBuilder, makeStringBuilder, finalize);
import Standard.Template (Render);

module body Example is
    record Page: Linear is
        title: String;
        motto: Option[String];
        items: Buffer[Index];
        admin: Bool;
        count: Int32;
    end;

    generic [R: Region]
    function render(page: &[Page, R]): String is
        var out: StringBuilder := makeStringBuilder();
        @template("page.jinja", page, out);
        return finalize(out);
    end;

    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Daneben `page.jinja`:

```jinja file page.jinja
{% from "macros.jinja" import show %}<p>{{ show(title) }}</p>
```

Daneben `macros.jinja`:

```jinja file macros.jinja
{% macro show(x) %}{{ x }}{% endmacro %}
```

### H7071

Meldung:

```text
Generic Error
@template: `loop' only exists inside a {% for %}
```

loop wird außerhalb eines {% for %} verwendet.

Dieses Modul scheitert mit H7071:

```hilde fails H7071
import Standard.Buffer (Buffer);
import Standard.String (String);
import Standard.StringBuilder (StringBuilder, makeStringBuilder, finalize);
import Standard.Template (Render);

module body Example is
    record Page: Linear is
        title: String;
        motto: Option[String];
        items: Buffer[Index];
        admin: Bool;
        count: Int32;
    end;

    generic [R: Region]
    function render(page: &[Page, R]): String is
        var out: StringBuilder := makeStringBuilder();
        @template("page.jinja", page, out);
        return finalize(out);
    end;

    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Daneben `page.jinja`:

```jinja file page.jinja
<p>{{ loop.index }}</p>
```

Die richtige Form:

```hilde
import Standard.Buffer (Buffer);
import Standard.String (String);
import Standard.StringBuilder (StringBuilder, makeStringBuilder, finalize);
import Standard.Template (Render);

module body Example is
    record Page: Linear is
        title: String;
        motto: Option[String];
        items: Buffer[Index];
        admin: Bool;
        count: Int32;
    end;

    generic [R: Region]
    function render(page: &[Page, R]): String is
        var out: StringBuilder := makeStringBuilder();
        @template("page.jinja", page, out);
        return finalize(out);
    end;

    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Daneben `page.jinja`:

```jinja file page.jinja
{% for item in items %}{{ loop.index }}{% endfor %}
```

### H7072

Meldung:

```text
Generic Error
@template: this number is too large
```

Eine in einer Bedingung verglichene Zahl ist zu groß.

Dieses Modul scheitert mit H7072:

```hilde fails H7072
import Standard.Buffer (Buffer);
import Standard.String (String);
import Standard.StringBuilder (StringBuilder, makeStringBuilder, finalize);
import Standard.Template (Render);

module body Example is
    record Page: Linear is
        title: String;
        motto: Option[String];
        items: Buffer[Index];
        admin: Bool;
        count: Int32;
    end;

    generic [R: Region]
    function render(page: &[Page, R]): String is
        var out: StringBuilder := makeStringBuilder();
        @template("page.jinja", page, out);
        return finalize(out);
    end;

    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Daneben `page.jinja`:

```jinja file page.jinja
{% if count > 99999999999999999999 %}many{% endif %}
```

Die richtige Form:

```hilde
import Standard.Buffer (Buffer);
import Standard.String (String);
import Standard.StringBuilder (StringBuilder, makeStringBuilder, finalize);
import Standard.Template (Render);

module body Example is
    record Page: Linear is
        title: String;
        motto: Option[String];
        items: Buffer[Index];
        admin: Bool;
        count: Int32;
    end;

    generic [R: Region]
    function render(page: &[Page, R]): String is
        var out: StringBuilder := makeStringBuilder();
        @template("page.jinja", page, out);
        return finalize(out);
    end;

    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Daneben `page.jinja`:

```jinja file page.jinja
{% if count > 99 %}many{% endif %}
```

### H7073

Meldung:

```text
Generic Error
@template: loop.cycle cannot be printed
```

Ein Schleifenattribut wird ausgegeben, das sich nicht ausgeben lässt.

Dieses Modul scheitert mit H7073:

```hilde fails H7073
import Standard.Buffer (Buffer);
import Standard.String (String);
import Standard.StringBuilder (StringBuilder, makeStringBuilder, finalize);
import Standard.Template (Render);

module body Example is
    record Page: Linear is
        title: String;
        motto: Option[String];
        items: Buffer[Index];
        admin: Bool;
        count: Int32;
    end;

    generic [R: Region]
    function render(page: &[Page, R]): String is
        var out: StringBuilder := makeStringBuilder();
        @template("page.jinja", page, out);
        return finalize(out);
    end;

    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Daneben `page.jinja`:

```jinja file page.jinja
{% for item in items %}{{ loop.cycle }}{% endfor %}
```

Die richtige Form:

```hilde
import Standard.Buffer (Buffer);
import Standard.String (String);
import Standard.StringBuilder (StringBuilder, makeStringBuilder, finalize);
import Standard.Template (Render);

module body Example is
    record Page: Linear is
        title: String;
        motto: Option[String];
        items: Buffer[Index];
        admin: Bool;
        count: Int32;
    end;

    generic [R: Region]
    function render(page: &[Page, R]): String is
        var out: StringBuilder := makeStringBuilder();
        @template("page.jinja", page, out);
        return finalize(out);
    end;

    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Daneben `page.jinja`:

```jinja file page.jinja
{% for item in items %}{{ loop.index }}{% endfor %}
```

### H7075

Meldung:

```text
Generic Error
@template: |length is supported on a name of the data only
```

`|length` wird auf etwas angewandt, das kein Name der Daten ist.

Dieses Modul scheitert mit H7075:

```hilde fails H7075
import Standard.Buffer (Buffer);
import Standard.String (String);
import Standard.StringBuilder (StringBuilder, makeStringBuilder, finalize);
import Standard.Template (Render);

module body Example is
    record Page: Linear is
        title: String;
        motto: Option[String];
        items: Buffer[Index];
        admin: Bool;
        count: Int32;
    end;

    generic [R: Region]
    function render(page: &[Page, R]): String is
        var out: StringBuilder := makeStringBuilder();
        @template("page.jinja", page, out);
        return finalize(out);
    end;

    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Daneben `page.jinja`:

```jinja file page.jinja
<p>{{ "abc"|length }}</p>
```

Die richtige Form:

```hilde
import Standard.Buffer (Buffer);
import Standard.String (String);
import Standard.StringBuilder (StringBuilder, makeStringBuilder, finalize);
import Standard.Template (Render);

module body Example is
    record Page: Linear is
        title: String;
        motto: Option[String];
        items: Buffer[Index];
        admin: Bool;
        count: Int32;
    end;

    generic [R: Region]
    function render(page: &[Page, R]): String is
        var out: StringBuilder := makeStringBuilder();
        @template("page.jinja", page, out);
        return finalize(out);
    end;

    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Daneben `page.jinja`:

```jinja file page.jinja
<p>{{ title|length }}</p>
```

### H7076

Meldung:

```text
Generic Error
@template: the filter |wordcount is not supported
```

Es wird ein Filter verwendet, den diese Template-Sprache nicht kennt.

Dieses Modul scheitert mit H7076:

```hilde fails H7076
import Standard.Buffer (Buffer);
import Standard.String (String);
import Standard.StringBuilder (StringBuilder, makeStringBuilder, finalize);
import Standard.Template (Render);

module body Example is
    record Page: Linear is
        title: String;
        motto: Option[String];
        items: Buffer[Index];
        admin: Bool;
        count: Int32;
    end;

    generic [R: Region]
    function render(page: &[Page, R]): String is
        var out: StringBuilder := makeStringBuilder();
        @template("page.jinja", page, out);
        return finalize(out);
    end;

    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Daneben `page.jinja`:

```jinja file page.jinja
<p>{{ title|wordcount }}</p>
```

Die richtige Form:

```hilde
import Standard.Buffer (Buffer);
import Standard.String (String);
import Standard.StringBuilder (StringBuilder, makeStringBuilder, finalize);
import Standard.Template (Render);

module body Example is
    record Page: Linear is
        title: String;
        motto: Option[String];
        items: Buffer[Index];
        admin: Bool;
        count: Int32;
    end;

    generic [R: Region]
    function render(page: &[Page, R]): String is
        var out: StringBuilder := makeStringBuilder();
        @template("page.jinja", page, out);
        return finalize(out);
    end;

    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Daneben `page.jinja`:

```jinja file page.jinja
<p>{{ title|upper }}</p>
```

### H7077

Meldung:

```text
Generic Error
@template: none cannot be printed: an Option is printed by asking `is not none' first
```

none wird ausgegeben. Ein Option wird ausgegeben, nachdem mit is not none
gefragt wurde.

Dieses Modul scheitert mit H7077:

```hilde fails H7077
import Standard.Buffer (Buffer);
import Standard.String (String);
import Standard.StringBuilder (StringBuilder, makeStringBuilder, finalize);
import Standard.Template (Render);

module body Example is
    record Page: Linear is
        title: String;
        motto: Option[String];
        items: Buffer[Index];
        admin: Bool;
        count: Int32;
    end;

    generic [R: Region]
    function render(page: &[Page, R]): String is
        var out: StringBuilder := makeStringBuilder();
        @template("page.jinja", page, out);
        return finalize(out);
    end;

    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Daneben `page.jinja`:

```jinja file page.jinja
<p>{{ none }}</p>
```

Die richtige Form:

```hilde
import Standard.Buffer (Buffer);
import Standard.String (String);
import Standard.StringBuilder (StringBuilder, makeStringBuilder, finalize);
import Standard.Template (Render);

module body Example is
    record Page: Linear is
        title: String;
        motto: Option[String];
        items: Buffer[Index];
        admin: Bool;
        count: Int32;
    end;

    generic [R: Region]
    function render(page: &[Page, R]): String is
        var out: StringBuilder := makeStringBuilder();
        @template("page.jinja", page, out);
        return finalize(out);
    end;

    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Daneben `page.jinja`:

```jinja file page.jinja
{% if motto is not none %}<p>{{ motto }}</p>{% endif %}
```

### H7079

Meldung:

```text
Generic Error
@template: a macro call stands alone in {{ }}, without filters
```

Ein Makroaufruf steht mit einem Filter in {{ }}. Ein Makroaufruf steht
allein.

Dieses Modul scheitert mit H7079:

```hilde fails H7079
import Standard.Buffer (Buffer);
import Standard.String (String);
import Standard.StringBuilder (StringBuilder, makeStringBuilder, finalize);
import Standard.Template (Render);

module body Example is
    record Page: Linear is
        title: String;
        motto: Option[String];
        items: Buffer[Index];
        admin: Bool;
        count: Int32;
    end;

    generic [R: Region]
    function render(page: &[Page, R]): String is
        var out: StringBuilder := makeStringBuilder();
        @template("page.jinja", page, out);
        return finalize(out);
    end;

    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Daneben `page.jinja`:

```jinja file page.jinja
{% macro show(x) %}{{ x }}{% endmacro %}<p>{{ show(title)|upper }}</p>
```

Die richtige Form:

```hilde
import Standard.Buffer (Buffer);
import Standard.String (String);
import Standard.StringBuilder (StringBuilder, makeStringBuilder, finalize);
import Standard.Template (Render);

module body Example is
    record Page: Linear is
        title: String;
        motto: Option[String];
        items: Buffer[Index];
        admin: Bool;
        count: Int32;
    end;

    generic [R: Region]
    function render(page: &[Page, R]): String is
        var out: StringBuilder := makeStringBuilder();
        @template("page.jinja", page, out);
        return finalize(out);
    end;

    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Daneben `page.jinja`:

```jinja file page.jinja
{% macro show(x) %}{{ x|upper }}{% endmacro %}<p>{{ show(title) }}</p>
```

### H7080

Meldung:

```text
Generic Error
@template: loop.first is not a number
```

Ein Attribut von loop, das keine Zahl ist, steht, wo eine Zahl hingehört, in einem Vergleich oder in einer Rechnung. loop.first und loop.last sind Bedingungen.

Dieses Modul scheitert mit H7080:

```hilde fails H7080
import Standard.Buffer (Buffer);
import Standard.String (String);
import Standard.StringBuilder (StringBuilder, makeStringBuilder, finalize);
import Standard.Template (Render);

module body Example is
    record Page: Linear is
        title: String;
        motto: Option[String];
        items: Buffer[Index];
        admin: Bool;
        count: Int32;
    end;

    generic [R: Region]
    function render(page: &[Page, R]): String is
        var out: StringBuilder := makeStringBuilder();
        @template("page.jinja", page, out);
        return finalize(out);
    end;

    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Daneben `page.jinja`:

```jinja file page.jinja
{% for item in items %}{% if loop.first > 0 %}{{ item }}{% endif %}{% endfor %}
```

Die richtige Form:

```hilde
import Standard.Buffer (Buffer);
import Standard.String (String);
import Standard.StringBuilder (StringBuilder, makeStringBuilder, finalize);
import Standard.Template (Render);

module body Example is
    record Page: Linear is
        title: String;
        motto: Option[String];
        items: Buffer[Index];
        admin: Bool;
        count: Int32;
    end;

    generic [R: Region]
    function render(page: &[Page, R]): String is
        var out: StringBuilder := makeStringBuilder();
        @template("page.jinja", page, out);
        return finalize(out);
    end;

    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Daneben `page.jinja`:

```jinja file page.jinja
{% for item in items %}{% if loop.index > 1 %}{{ item }}{% endif %}{% endfor %}
```

### H7082

Meldung:

```text
Generic Error
@template: `is defined' cannot be asked: the template is compiled against one data type, so every name is known when the programme is compiled, and a name that does not exist is a compile error already
```

Eine Bedingung fragt is defined. Das Template wird gegen einen Datentyp
kompiliert; jeder Name ist also beim Kompilieren bekannt.

Dieses Modul scheitert mit H7082:

```hilde fails H7082
import Standard.Buffer (Buffer);
import Standard.String (String);
import Standard.StringBuilder (StringBuilder, makeStringBuilder, finalize);
import Standard.Template (Render);

module body Example is
    record Page: Linear is
        title: String;
        motto: Option[String];
        items: Buffer[Index];
        admin: Bool;
        count: Int32;
    end;

    generic [R: Region]
    function render(page: &[Page, R]): String is
        var out: StringBuilder := makeStringBuilder();
        @template("page.jinja", page, out);
        return finalize(out);
    end;

    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Daneben `page.jinja`:

```jinja file page.jinja
{% if title is defined %}<p>{{ title }}</p>{% endif %}
```

Die richtige Form:

```hilde
import Standard.Buffer (Buffer);
import Standard.String (String);
import Standard.StringBuilder (StringBuilder, makeStringBuilder, finalize);
import Standard.Template (Render);

module body Example is
    record Page: Linear is
        title: String;
        motto: Option[String];
        items: Buffer[Index];
        admin: Bool;
        count: Int32;
    end;

    generic [R: Region]
    function render(page: &[Page, R]): String is
        var out: StringBuilder := makeStringBuilder();
        @template("page.jinja", page, out);
        return finalize(out);
    end;

    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Daneben `page.jinja`:

```jinja file page.jinja
<p>{{ title }}</p>
```

### H7083

Meldung:

```text
Generic Error
@template: `is none' is supported on a name of the data only
```

is none wird von etwas gefragt, das kein Name der Daten ist.

Dieses Modul scheitert mit H7083:

```hilde fails H7083
import Standard.Buffer (Buffer);
import Standard.String (String);
import Standard.StringBuilder (StringBuilder, makeStringBuilder, finalize);
import Standard.Template (Render);

module body Example is
    record Page: Linear is
        title: String;
        motto: Option[String];
        items: Buffer[Index];
        admin: Bool;
        count: Int32;
    end;

    generic [R: Region]
    function render(page: &[Page, R]): String is
        var out: StringBuilder := makeStringBuilder();
        @template("page.jinja", page, out);
        return finalize(out);
    end;

    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Daneben `page.jinja`:

```jinja file page.jinja
{% if "x" is none %}<p>none</p>{% endif %}
```

Die richtige Form:

```hilde
import Standard.Buffer (Buffer);
import Standard.String (String);
import Standard.StringBuilder (StringBuilder, makeStringBuilder, finalize);
import Standard.Template (Render);

module body Example is
    record Page: Linear is
        title: String;
        motto: Option[String];
        items: Buffer[Index];
        admin: Bool;
        count: Int32;
    end;

    generic [R: Region]
    function render(page: &[Page, R]): String is
        var out: StringBuilder := makeStringBuilder();
        @template("page.jinja", page, out);
        return finalize(out);
    end;

    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Daneben `page.jinja`:

```jinja file page.jinja
{% if motto is none %}<p>none</p>{% endif %}
```

### H7084

Meldung:

```text
Generic Error
@template: the test `is even' is not supported
```

Eine Bedingung verwendet einen Test, den diese Template-Sprache nicht kennt.

Dieses Modul scheitert mit H7084:

```hilde fails H7084
import Standard.Buffer (Buffer);
import Standard.String (String);
import Standard.StringBuilder (StringBuilder, makeStringBuilder, finalize);
import Standard.Template (Render);

module body Example is
    record Page: Linear is
        title: String;
        motto: Option[String];
        items: Buffer[Index];
        admin: Bool;
        count: Int32;
    end;

    generic [R: Region]
    function render(page: &[Page, R]): String is
        var out: StringBuilder := makeStringBuilder();
        @template("page.jinja", page, out);
        return finalize(out);
    end;

    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Daneben `page.jinja`:

```jinja file page.jinja
{% if count is even %}<p>even</p>{% endif %}
```

Die richtige Form:

```hilde
import Standard.Buffer (Buffer);
import Standard.String (String);
import Standard.StringBuilder (StringBuilder, makeStringBuilder, finalize);
import Standard.Template (Render);

module body Example is
    record Page: Linear is
        title: String;
        motto: Option[String];
        items: Buffer[Index];
        admin: Bool;
        count: Int32;
    end;

    generic [R: Region]
    function render(page: &[Page, R]): String is
        var out: StringBuilder := makeStringBuilder();
        @template("page.jinja", page, out);
        return finalize(out);
    end;

    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Daneben `page.jinja`:

```jinja file page.jinja
{% if count == 2 %}<p>two</p>{% endif %}
```

### H7085

Meldung:

```text
Generic Error
@template: a string can only be compared with == and !=
```

Ein String wird mit einem anderen Operator als == und != verglichen.

Dieses Modul scheitert mit H7085:

```hilde fails H7085
import Standard.Buffer (Buffer);
import Standard.String (String);
import Standard.StringBuilder (StringBuilder, makeStringBuilder, finalize);
import Standard.Template (Render);

module body Example is
    record Page: Linear is
        title: String;
        motto: Option[String];
        items: Buffer[Index];
        admin: Bool;
        count: Int32;
    end;

    generic [R: Region]
    function render(page: &[Page, R]): String is
        var out: StringBuilder := makeStringBuilder();
        @template("page.jinja", page, out);
        return finalize(out);
    end;

    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Daneben `page.jinja`:

```jinja file page.jinja
{% if title < "m" %}<p>early</p>{% endif %}
```

Die richtige Form:

```hilde
import Standard.Buffer (Buffer);
import Standard.String (String);
import Standard.StringBuilder (StringBuilder, makeStringBuilder, finalize);
import Standard.Template (Render);

module body Example is
    record Page: Linear is
        title: String;
        motto: Option[String];
        items: Buffer[Index];
        admin: Bool;
        count: Int32;
    end;

    generic [R: Region]
    function render(page: &[Page, R]): String is
        var out: StringBuilder := makeStringBuilder();
        @template("page.jinja", page, out);
        return finalize(out);
    end;

    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Daneben `page.jinja`:

```jinja file page.jinja
{% if title == "m" %}<p>m</p>{% endif %}
```

### H7086

Meldung:

```text
Generic Error
@template: only a name compared with a literal, or with a computed number, is supported
```

Ein Vergleich vergleicht nicht einen Namen mit einem Literal.

Dieses Modul scheitert mit H7086:

```hilde fails H7086
import Standard.Buffer (Buffer);
import Standard.String (String);
import Standard.StringBuilder (StringBuilder, makeStringBuilder, finalize);
import Standard.Template (Render);

module body Example is
    record Page: Linear is
        title: String;
        motto: Option[String];
        items: Buffer[Index];
        admin: Bool;
        count: Int32;
    end;

    generic [R: Region]
    function render(page: &[Page, R]): String is
        var out: StringBuilder := makeStringBuilder();
        @template("page.jinja", page, out);
        return finalize(out);
    end;

    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Daneben `page.jinja`:

```jinja file page.jinja
{% if count > count %}<p>more</p>{% endif %}
```

Die richtige Form:

```hilde
import Standard.Buffer (Buffer);
import Standard.String (String);
import Standard.StringBuilder (StringBuilder, makeStringBuilder, finalize);
import Standard.Template (Render);

module body Example is
    record Page: Linear is
        title: String;
        motto: Option[String];
        items: Buffer[Index];
        admin: Bool;
        count: Int32;
    end;

    generic [R: Region]
    function render(page: &[Page, R]): String is
        var out: StringBuilder := makeStringBuilder();
        @template("page.jinja", page, out);
        return finalize(out);
    end;

    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Daneben `page.jinja`:

```jinja file page.jinja
{% if count > 1 %}<p>more</p>{% endif %}
```

### H7087

Meldung:

```text
Generic Error
@template: this cannot be used as a condition
```

Etwas, das keine Bedingung ist, steht als Bedingung, etwa ein String.

Dieses Modul scheitert mit H7087:

```hilde fails H7087
import Standard.Buffer (Buffer);
import Standard.String (String);
import Standard.StringBuilder (StringBuilder, makeStringBuilder, finalize);
import Standard.Template (Render);

module body Example is
    record Page: Linear is
        title: String;
        motto: Option[String];
        items: Buffer[Index];
        admin: Bool;
        count: Int32;
    end;

    generic [R: Region]
    function render(page: &[Page, R]): String is
        var out: StringBuilder := makeStringBuilder();
        @template("page.jinja", page, out);
        return finalize(out);
    end;

    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Daneben `page.jinja`:

```jinja file page.jinja
{% if "yes" %}<p>yes</p>{% endif %}
```

Die richtige Form:

```hilde
import Standard.Buffer (Buffer);
import Standard.String (String);
import Standard.StringBuilder (StringBuilder, makeStringBuilder, finalize);
import Standard.Template (Render);

module body Example is
    record Page: Linear is
        title: String;
        motto: Option[String];
        items: Buffer[Index];
        admin: Bool;
        count: Int32;
    end;

    generic [R: Region]
    function render(page: &[Page, R]): String is
        var out: StringBuilder := makeStringBuilder();
        @template("page.jinja", page, out);
        return finalize(out);
    end;

    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Daneben `page.jinja`:

```jinja file page.jinja
{% if admin %}<p>yes</p>{% endif %}
```

### H7088

Meldung:

```text
Generic Error
@template: the parameter x is a literal here, and a literal has no fields
```

Ein Makroparameter, der ein Literal bekommt, wird mit einem Feld verwendet,
wie in x.name.

Dieses Modul scheitert mit H7088:

```hilde fails H7088
import Standard.Buffer (Buffer);
import Standard.String (String);
import Standard.StringBuilder (StringBuilder, makeStringBuilder, finalize);
import Standard.Template (Render);

module body Example is
    record Page: Linear is
        title: String;
        motto: Option[String];
        items: Buffer[Index];
        admin: Bool;
        count: Int32;
    end;

    generic [R: Region]
    function render(page: &[Page, R]): String is
        var out: StringBuilder := makeStringBuilder();
        @template("page.jinja", page, out);
        return finalize(out);
    end;

    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Daneben `page.jinja`:

```jinja file page.jinja
{% macro show(x) %}{{ x.name }}{% endmacro %}<p>{{ show("a") }}</p>
```

Die richtige Form:

```hilde
import Standard.Buffer (Buffer);
import Standard.String (String);
import Standard.StringBuilder (StringBuilder, makeStringBuilder, finalize);
import Standard.Template (Render);

module body Example is
    record Page: Linear is
        title: String;
        motto: Option[String];
        items: Buffer[Index];
        admin: Bool;
        count: Int32;
    end;

    generic [R: Region]
    function render(page: &[Page, R]): String is
        var out: StringBuilder := makeStringBuilder();
        @template("page.jinja", page, out);
        return finalize(out);
    end;

    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Daneben `page.jinja`:

```jinja file page.jinja
{% macro show(x) %}{{ x }}{% endmacro %}<p>{{ show("a") }}</p>
```

### H7089

Meldung:

```text
Generic Error
@template: there is no macro show
```

Ein Makro wird aufgerufen, das nicht definiert ist.

Dieses Modul scheitert mit H7089:

```hilde fails H7089
import Standard.Buffer (Buffer);
import Standard.String (String);
import Standard.StringBuilder (StringBuilder, makeStringBuilder, finalize);
import Standard.Template (Render);

module body Example is
    record Page: Linear is
        title: String;
        motto: Option[String];
        items: Buffer[Index];
        admin: Bool;
        count: Int32;
    end;

    generic [R: Region]
    function render(page: &[Page, R]): String is
        var out: StringBuilder := makeStringBuilder();
        @template("page.jinja", page, out);
        return finalize(out);
    end;

    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Daneben `page.jinja`:

```jinja file page.jinja
<p>{{ show(title) }}</p>
```

Die richtige Form:

```hilde
import Standard.Buffer (Buffer);
import Standard.String (String);
import Standard.StringBuilder (StringBuilder, makeStringBuilder, finalize);
import Standard.Template (Render);

module body Example is
    record Page: Linear is
        title: String;
        motto: Option[String];
        items: Buffer[Index];
        admin: Bool;
        count: Int32;
    end;

    generic [R: Region]
    function render(page: &[Page, R]): String is
        var out: StringBuilder := makeStringBuilder();
        @template("page.jinja", page, out);
        return finalize(out);
    end;

    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Daneben `page.jinja`:

```jinja file page.jinja
{% macro show(x) %}{{ x }}{% endmacro %}<p>{{ show(title) }}</p>
```

### H7090

Meldung:

```text
Generic Error
@template: the macro show calls itself: show -> show; a template is expanded when the programme is compiled, and a recursion would not end
```

Ein Makro ruft sich selbst auf. Ein Template wird beim Kompilieren
ausgeklappt, und eine Rekursion würde nicht enden.

Dieses Modul scheitert mit H7090:

```hilde fails H7090
import Standard.Buffer (Buffer);
import Standard.String (String);
import Standard.StringBuilder (StringBuilder, makeStringBuilder, finalize);
import Standard.Template (Render);

module body Example is
    record Page: Linear is
        title: String;
        motto: Option[String];
        items: Buffer[Index];
        admin: Bool;
        count: Int32;
    end;

    generic [R: Region]
    function render(page: &[Page, R]): String is
        var out: StringBuilder := makeStringBuilder();
        @template("page.jinja", page, out);
        return finalize(out);
    end;

    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Daneben `page.jinja`:

```jinja file page.jinja
{% macro show(x) %}{{ show(x) }}{% endmacro %}<p>{{ show(title) }}</p>
```

Die richtige Form:

```hilde
import Standard.Buffer (Buffer);
import Standard.String (String);
import Standard.StringBuilder (StringBuilder, makeStringBuilder, finalize);
import Standard.Template (Render);

module body Example is
    record Page: Linear is
        title: String;
        motto: Option[String];
        items: Buffer[Index];
        admin: Bool;
        count: Int32;
    end;

    generic [R: Region]
    function render(page: &[Page, R]): String is
        var out: StringBuilder := makeStringBuilder();
        @template("page.jinja", page, out);
        return finalize(out);
    end;

    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Daneben `page.jinja`:

```jinja file page.jinja
{% macro show(x) %}{{ x }}{% endmacro %}<p>{{ show(title) }}</p>
```

### H7091

Meldung:

```text
Generic Error
@template: the macro show takes 1 arguments
```

Ein Makro wird mit mehr Argumenten aufgerufen, als es Parameter hat.

Dieses Modul scheitert mit H7091:

```hilde fails H7091
import Standard.Buffer (Buffer);
import Standard.String (String);
import Standard.StringBuilder (StringBuilder, makeStringBuilder, finalize);
import Standard.Template (Render);

module body Example is
    record Page: Linear is
        title: String;
        motto: Option[String];
        items: Buffer[Index];
        admin: Bool;
        count: Int32;
    end;

    generic [R: Region]
    function render(page: &[Page, R]): String is
        var out: StringBuilder := makeStringBuilder();
        @template("page.jinja", page, out);
        return finalize(out);
    end;

    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Daneben `page.jinja`:

```jinja file page.jinja
{% macro show(x) %}{{ x }}{% endmacro %}<p>{{ show(title, title) }}</p>
```

Die richtige Form:

```hilde
import Standard.Buffer (Buffer);
import Standard.String (String);
import Standard.StringBuilder (StringBuilder, makeStringBuilder, finalize);
import Standard.Template (Render);

module body Example is
    record Page: Linear is
        title: String;
        motto: Option[String];
        items: Buffer[Index];
        admin: Bool;
        count: Int32;
    end;

    generic [R: Region]
    function render(page: &[Page, R]): String is
        var out: StringBuilder := makeStringBuilder();
        @template("page.jinja", page, out);
        return finalize(out);
    end;

    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Daneben `page.jinja`:

```jinja file page.jinja
{% macro show(x) %}{{ x }}{% endmacro %}<p>{{ show(title) }}</p>
```

### H7092

Meldung:

```text
Generic Error
@template: the macro show needs a value for x
```

Ein Makro wird ohne Wert für einen Parameter ohne Vorgabewert aufgerufen.

Dieses Modul scheitert mit H7092:

```hilde fails H7092
import Standard.Buffer (Buffer);
import Standard.String (String);
import Standard.StringBuilder (StringBuilder, makeStringBuilder, finalize);
import Standard.Template (Render);

module body Example is
    record Page: Linear is
        title: String;
        motto: Option[String];
        items: Buffer[Index];
        admin: Bool;
        count: Int32;
    end;

    generic [R: Region]
    function render(page: &[Page, R]): String is
        var out: StringBuilder := makeStringBuilder();
        @template("page.jinja", page, out);
        return finalize(out);
    end;

    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Daneben `page.jinja`:

```jinja file page.jinja
{% macro show(x) %}{{ x }}{% endmacro %}<p>{{ show() }}</p>
```

Die richtige Form:

```hilde
import Standard.Buffer (Buffer);
import Standard.String (String);
import Standard.StringBuilder (StringBuilder, makeStringBuilder, finalize);
import Standard.Template (Render);

module body Example is
    record Page: Linear is
        title: String;
        motto: Option[String];
        items: Buffer[Index];
        admin: Bool;
        count: Int32;
    end;

    generic [R: Region]
    function render(page: &[Page, R]): String is
        var out: StringBuilder := makeStringBuilder();
        @template("page.jinja", page, out);
        return finalize(out);
    end;

    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Daneben `page.jinja`:

```jinja file page.jinja
{% macro show(x) %}{{ x }}{% endmacro %}<p>{{ show(title) }}</p>
```

### H7093

Meldung:

```text
Generic Error
@template: a macro argument is a name or a literal
```

Ein Makroargument ist weder ein Name noch ein Literal.

Dieses Modul scheitert mit H7093:

```hilde fails H7093
import Standard.Buffer (Buffer);
import Standard.String (String);
import Standard.StringBuilder (StringBuilder, makeStringBuilder, finalize);
import Standard.Template (Render);

module body Example is
    record Page: Linear is
        title: String;
        motto: Option[String];
        items: Buffer[Index];
        admin: Bool;
        count: Int32;
    end;

    generic [R: Region]
    function render(page: &[Page, R]): String is
        var out: StringBuilder := makeStringBuilder();
        @template("page.jinja", page, out);
        return finalize(out);
    end;

    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Daneben `page.jinja`:

```jinja file page.jinja
{% macro show(x) %}{{ x }}{% endmacro %}<p>{{ show(title|upper) }}</p>
```

Die richtige Form:

```hilde
import Standard.Buffer (Buffer);
import Standard.String (String);
import Standard.StringBuilder (StringBuilder, makeStringBuilder, finalize);
import Standard.Template (Render);

module body Example is
    record Page: Linear is
        title: String;
        motto: Option[String];
        items: Buffer[Index];
        admin: Bool;
        count: Int32;
    end;

    generic [R: Region]
    function render(page: &[Page, R]): String is
        var out: StringBuilder := makeStringBuilder();
        @template("page.jinja", page, out);
        return finalize(out);
    end;

    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Daneben `page.jinja`:

```jinja file page.jinja
{% macro show(x) %}{{ x|upper }}{% endmacro %}<p>{{ show(title) }}</p>
```

### H7095

Meldung:

```text
Generic Error
@template: the branches of this {% if %} end in different places in the HTML: a <script> element and HTML text
```

Die Zweige eines {% if %} enden an verschiedenen Stellen des HTML, etwa
einer in einem Script und einer außerhalb.

Dieses Modul scheitert mit H7095:

```hilde fails H7095
import Standard.Buffer (Buffer);
import Standard.String (String);
import Standard.StringBuilder (StringBuilder, makeStringBuilder, finalize);
import Standard.Template (Render);

module body Example is
    record Page: Linear is
        title: String;
        motto: Option[String];
        items: Buffer[Index];
        admin: Bool;
        count: Int32;
    end;

    generic [R: Region]
    function render(page: &[Page, R]): String is
        var out: StringBuilder := makeStringBuilder();
        @template("page.jinja", page, out);
        return finalize(out);
    end;

    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Daneben `page.jinja`:

```jinja file page.jinja
{% if admin %}<script>{% endif %}<p>{{ title }}</p>
```

Die richtige Form:

```hilde
import Standard.Buffer (Buffer);
import Standard.String (String);
import Standard.StringBuilder (StringBuilder, makeStringBuilder, finalize);
import Standard.Template (Render);

module body Example is
    record Page: Linear is
        title: String;
        motto: Option[String];
        items: Buffer[Index];
        admin: Bool;
        count: Int32;
    end;

    generic [R: Region]
    function render(page: &[Page, R]): String is
        var out: StringBuilder := makeStringBuilder();
        @template("page.jinja", page, out);
        return finalize(out);
    end;

    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Daneben `page.jinja`:

```jinja file page.jinja
{% if admin %}<b>admin</b>{% endif %}<p>{{ title }}</p>
```

### H7096

Meldung:

```text
Generic Error
@template: {% for %} walks over a name of the data only
```

Ein {% for %} läuft über etwas, das kein Name der Daten ist.

Dieses Modul scheitert mit H7096:

```hilde fails H7096
import Standard.Buffer (Buffer);
import Standard.String (String);
import Standard.StringBuilder (StringBuilder, makeStringBuilder, finalize);
import Standard.Template (Render);

module body Example is
    record Page: Linear is
        title: String;
        motto: Option[String];
        items: Buffer[Index];
        admin: Bool;
        count: Int32;
    end;

    generic [R: Region]
    function render(page: &[Page, R]): String is
        var out: StringBuilder := makeStringBuilder();
        @template("page.jinja", page, out);
        return finalize(out);
    end;

    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Daneben `page.jinja`:

```jinja file page.jinja
{% for c in "abc" %}{{ c }}{% endfor %}
```

Die richtige Form:

```hilde
import Standard.Buffer (Buffer);
import Standard.String (String);
import Standard.StringBuilder (StringBuilder, makeStringBuilder, finalize);
import Standard.Template (Render);

module body Example is
    record Page: Linear is
        title: String;
        motto: Option[String];
        items: Buffer[Index];
        admin: Bool;
        count: Int32;
    end;

    generic [R: Region]
    function render(page: &[Page, R]): String is
        var out: StringBuilder := makeStringBuilder();
        @template("page.jinja", page, out);
        return finalize(out);
    end;

    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Daneben `page.jinja`:

```jinja file page.jinja
{% for item in items %}{{ item }}{% endfor %}
```

### H7097

Meldung:

```text
Generic Error
@template: the body of this {% for %} ends in a different place in the HTML than it begins: HTML text and a <script> element
```

Der Rumpf eines {% for %} endet an einer anderen Stelle des HTML, als er
beginnt.

Dieses Modul scheitert mit H7097:

```hilde fails H7097
import Standard.Buffer (Buffer);
import Standard.String (String);
import Standard.StringBuilder (StringBuilder, makeStringBuilder, finalize);
import Standard.Template (Render);

module body Example is
    record Page: Linear is
        title: String;
        motto: Option[String];
        items: Buffer[Index];
        admin: Bool;
        count: Int32;
    end;

    generic [R: Region]
    function render(page: &[Page, R]): String is
        var out: StringBuilder := makeStringBuilder();
        @template("page.jinja", page, out);
        return finalize(out);
    end;

    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Daneben `page.jinja`:

```jinja file page.jinja
{% for item in items %}<script>{% endfor %}
```

Die richtige Form:

```hilde
import Standard.Buffer (Buffer);
import Standard.String (String);
import Standard.StringBuilder (StringBuilder, makeStringBuilder, finalize);
import Standard.Template (Render);

module body Example is
    record Page: Linear is
        title: String;
        motto: Option[String];
        items: Buffer[Index];
        admin: Bool;
        count: Int32;
    end;

    generic [R: Region]
    function render(page: &[Page, R]): String is
        var out: StringBuilder := makeStringBuilder();
        @template("page.jinja", page, out);
        return finalize(out);
    end;

    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Daneben `page.jinja`:

```jinja file page.jinja
{% for item in items %}<b>{{ item }}</b>{% endfor %}
```

### H7098

Meldung:

```text
Generic Error
@template: the {% else %} of this {% for %} ends in a different place in the HTML than it begins
```

Das {% else %} eines {% for %} endet an einer anderen Stelle des HTML, als
es beginnt.

Dieses Modul scheitert mit H7098:

```hilde fails H7098
import Standard.Buffer (Buffer);
import Standard.String (String);
import Standard.StringBuilder (StringBuilder, makeStringBuilder, finalize);
import Standard.Template (Render);

module body Example is
    record Page: Linear is
        title: String;
        motto: Option[String];
        items: Buffer[Index];
        admin: Bool;
        count: Int32;
    end;

    generic [R: Region]
    function render(page: &[Page, R]): String is
        var out: StringBuilder := makeStringBuilder();
        @template("page.jinja", page, out);
        return finalize(out);
    end;

    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Daneben `page.jinja`:

```jinja file page.jinja
{% for item in items %}{{ item }}{% else %}<script>{% endfor %}
```

Die richtige Form:

```hilde
import Standard.Buffer (Buffer);
import Standard.String (String);
import Standard.StringBuilder (StringBuilder, makeStringBuilder, finalize);
import Standard.Template (Render);

module body Example is
    record Page: Linear is
        title: String;
        motto: Option[String];
        items: Buffer[Index];
        admin: Bool;
        count: Int32;
    end;

    generic [R: Region]
    function render(page: &[Page, R]): String is
        var out: StringBuilder := makeStringBuilder();
        @template("page.jinja", page, out);
        return finalize(out);
    end;

    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Daneben `page.jinja`:

```jinja file page.jinja
{% for item in items %}{{ item }}{% else %}<b>none</b>{% endfor %}
```

### H7099

Meldung:

```text
Generic Error
@template: a module that uses @template imports Standard.Template -- e.g. `import Standard.Template (Render);' -- because the generated code calls it, and its instances come with the import
```

Ein Modul, das @template verwendet, importiert Standard.Template nicht. Der
erzeugte Code ruft es auf, und seine Instanzen kommen mit dem Import.

Dieses Modul scheitert mit H7099:

```hilde fails H7099
import Standard.Buffer (Buffer);
import Standard.String (String);
import Standard.StringBuilder (StringBuilder, makeStringBuilder, finalize);

module body Example is
    record Page: Linear is
        title: String;
        motto: Option[String];
        items: Buffer[Index];
        admin: Bool;
        count: Int32;
    end;

    generic [R: Region]
    function render(page: &[Page, R]): String is
        var out: StringBuilder := makeStringBuilder();
        @template("page.jinja", page, out);
        return finalize(out);
    end;

    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Daneben `page.jinja`:

```jinja file page.jinja
<p>{{ title }}</p>
```

Die richtige Form:

```hilde
import Standard.Buffer (Buffer);
import Standard.String (String);
import Standard.StringBuilder (StringBuilder, makeStringBuilder, finalize);
import Standard.Template (Render);

module body Example is
    record Page: Linear is
        title: String;
        motto: Option[String];
        items: Buffer[Index];
        admin: Bool;
        count: Int32;
    end;

    generic [R: Region]
    function render(page: &[Page, R]): String is
        var out: StringBuilder := makeStringBuilder();
        @template("page.jinja", page, out);
        return finalize(out);
    end;

    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Daneben `page.jinja`:

```jinja file page.jinja
<p>{{ title }}</p>
```

### H7100

Meldung:

```text
Generic Error
@template: {% with %} without {% endwith %}
```

Ein {% set %}-Block, ein {% with %}, ein {% filter %} oder ein {% call %} wird nicht mit seinem End-Tag geschlossen.

Dieses Modul scheitert mit H7100:

```hilde fails H7100
import Standard.Buffer (Buffer);
import Standard.String (String);
import Standard.StringBuilder (StringBuilder, makeStringBuilder, finalize);
import Standard.Template (Render);

module body Example is
    record Page: Linear is
        title: String;
        motto: Option[String];
        items: Buffer[Index];
        admin: Bool;
        count: Int32;
    end;

    generic [R: Region]
    function render(page: &[Page, R]): String is
        var out: StringBuilder := makeStringBuilder();
        @template("page.jinja", page, out);
        return finalize(out);
    end;

    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Daneben `page.jinja`:

```jinja file page.jinja
{% with name = title %}<p>{{ name }}</p>
```

Die richtige Form:

```hilde
import Standard.Buffer (Buffer);
import Standard.String (String);
import Standard.StringBuilder (StringBuilder, makeStringBuilder, finalize);
import Standard.Template (Render);

module body Example is
    record Page: Linear is
        title: String;
        motto: Option[String];
        items: Buffer[Index];
        admin: Bool;
        count: Int32;
    end;

    generic [R: Region]
    function render(page: &[Page, R]): String is
        var out: StringBuilder := makeStringBuilder();
        @template("page.jinja", page, out);
        return finalize(out);
    end;

    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Daneben `page.jinja`:

```jinja file page.jinja
{% with name = title %}<p>{{ name }}</p>{% endwith %}
```

### H7101

Meldung:

```text
Generic Error
@template: {% set %} takes one name, = and one value
```

Das Tag eines {% set %}, {% with %}, {% filter %} oder {% call %} hat nicht seine Form: set nimmt einen Namen, = und einen Wert; with nimmt Namen mit = und Werten, durch Kommas getrennt; filter nimmt Filter, durch | getrennt; call nimmt einen Makroaufruf, und caller() nimmt keine Parameter.

Dieses Modul scheitert mit H7101:

```hilde fails H7101
import Standard.Buffer (Buffer);
import Standard.String (String);
import Standard.StringBuilder (StringBuilder, makeStringBuilder, finalize);
import Standard.Template (Render);

module body Example is
    record Page: Linear is
        title: String;
        motto: Option[String];
        items: Buffer[Index];
        admin: Bool;
        count: Int32;
    end;

    generic [R: Region]
    function render(page: &[Page, R]): String is
        var out: StringBuilder := makeStringBuilder();
        @template("page.jinja", page, out);
        return finalize(out);
    end;

    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Daneben `page.jinja`:

```jinja file page.jinja
{% set a b = title %}<p>{{ a }}</p>
```

Die richtige Form:

```hilde
import Standard.Buffer (Buffer);
import Standard.String (String);
import Standard.StringBuilder (StringBuilder, makeStringBuilder, finalize);
import Standard.Template (Render);

module body Example is
    record Page: Linear is
        title: String;
        motto: Option[String];
        items: Buffer[Index];
        admin: Bool;
        count: Int32;
    end;

    generic [R: Region]
    function render(page: &[Page, R]): String is
        var out: StringBuilder := makeStringBuilder();
        @template("page.jinja", page, out);
        return finalize(out);
    end;

    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Daneben `page.jinja`:

```jinja file page.jinja
{% set a = title %}<p>{{ a }}</p>
```

### H7102

Meldung:

```text
Generic Error
@template: the name lib is an import's: it stands for the macros of a file, and a macro is called, not printed
```

Der Name, den ein {% import ... as %} vergeben hat, wird ausgegeben oder zwei Imports gegeben. Er steht für die Makros einer Datei und verdeckt ein gleichnamiges Feld der Daten, wie in Jinja2.

Dieses Modul scheitert mit H7102:

```hilde fails H7102
import Standard.Buffer (Buffer);
import Standard.String (String);
import Standard.StringBuilder (StringBuilder, makeStringBuilder, finalize);
import Standard.Template (Render);

module body Example is
    record Page: Linear is
        title: String;
        motto: Option[String];
        items: Buffer[Index];
        admin: Bool;
        count: Int32;
    end;

    generic [R: Region]
    function render(page: &[Page, R]): String is
        var out: StringBuilder := makeStringBuilder();
        @template("page.jinja", page, out);
        return finalize(out);
    end;

    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Daneben `page.jinja`:

```jinja file page.jinja
{% import "macros.jinja" as lib %}<p>{{ lib }}</p>
```

Daneben `macros.jinja`:

```jinja file macros.jinja
{% macro show(text) %}<b>{{ text }}</b>{% endmacro %}
```

Die richtige Form:

```hilde
import Standard.Buffer (Buffer);
import Standard.String (String);
import Standard.StringBuilder (StringBuilder, makeStringBuilder, finalize);
import Standard.Template (Render);

module body Example is
    record Page: Linear is
        title: String;
        motto: Option[String];
        items: Buffer[Index];
        admin: Bool;
        count: Int32;
    end;

    generic [R: Region]
    function render(page: &[Page, R]): String is
        var out: StringBuilder := makeStringBuilder();
        @template("page.jinja", page, out);
        return finalize(out);
    end;

    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Daneben `page.jinja`:

```jinja file page.jinja
{% import "macros.jinja" as lib %}<p>{{ lib.show(title) }}</p>
```

Daneben `macros.jinja`:

```jinja file macros.jinja
{% macro show(text) %}<b>{{ text }}</b>{% endmacro %}
```

### H7103

Meldung:

```text
Generic Error
@template: a {% set %} after {% extends %} and outside a block is refused: whether a block sees it depends on the order in which Jinja2 runs the two templates
```

Ein {% set %} steht nach {% extends %} und außerhalb jedes Blocks. Ob ein Block der Elternvorlage den Namen sieht, hängt von der Reihenfolge ab, in der Jinja2 die beiden Templates ausführt; er gehört in den Block.

Dieses Modul scheitert mit H7103:

```hilde fails H7103
import Standard.Buffer (Buffer);
import Standard.String (String);
import Standard.StringBuilder (StringBuilder, makeStringBuilder, finalize);
import Standard.Template (Render);

module body Example is
    record Page: Linear is
        title: String;
        motto: Option[String];
        items: Buffer[Index];
        admin: Bool;
        count: Int32;
    end;

    generic [R: Region]
    function render(page: &[Page, R]): String is
        var out: StringBuilder := makeStringBuilder();
        @template("page.jinja", page, out);
        return finalize(out);
    end;

    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Daneben `page.jinja`:

```jinja file page.jinja
{% extends "base.jinja" %}{% set name = title %}{% block main %}{{ name }}{% endblock %}
```

Daneben `base.jinja`:

```jinja file base.jinja
<main>{% block main %}{% endblock %}</main>
```

Die richtige Form:

```hilde
import Standard.Buffer (Buffer);
import Standard.String (String);
import Standard.StringBuilder (StringBuilder, makeStringBuilder, finalize);
import Standard.Template (Render);

module body Example is
    record Page: Linear is
        title: String;
        motto: Option[String];
        items: Buffer[Index];
        admin: Bool;
        count: Int32;
    end;

    generic [R: Region]
    function render(page: &[Page, R]): String is
        var out: StringBuilder := makeStringBuilder();
        @template("page.jinja", page, out);
        return finalize(out);
    end;

    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Daneben `page.jinja`:

```jinja file page.jinja
{% extends "base.jinja" %}{% block main %}{% set name = title %}{{ name }}{% endblock %}
```

Daneben `base.jinja`:

```jinja file base.jinja
<main>{% block main %}{% endblock %}</main>
```

### H7104

Meldung:

```text
Generic Error
@template: name is a value that a {% set %} or a {% with %} computed, and a computed value has no fields
```

Ein Name, den ein {% set %} oder ein {% with %} an einen berechneten Wert gebunden hat, etwa einen mit ~ verbundenen Text, wird nach einem Feld gefragt. Nur ein Name der Daten hat Felder.

Dieses Modul scheitert mit H7104:

```hilde fails H7104
import Standard.Buffer (Buffer);
import Standard.String (String);
import Standard.StringBuilder (StringBuilder, makeStringBuilder, finalize);
import Standard.Template (Render);

module body Example is
    record Page: Linear is
        title: String;
        motto: Option[String];
        items: Buffer[Index];
        admin: Bool;
        count: Int32;
    end;

    generic [R: Region]
    function render(page: &[Page, R]): String is
        var out: StringBuilder := makeStringBuilder();
        @template("page.jinja", page, out);
        return finalize(out);
    end;

    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Daneben `page.jinja`:

```jinja file page.jinja
{% set name = title ~ "!" %}<p>{{ name.length }}</p>
```

Die richtige Form:

```hilde
import Standard.Buffer (Buffer);
import Standard.String (String);
import Standard.StringBuilder (StringBuilder, makeStringBuilder, finalize);
import Standard.Template (Render);

module body Example is
    record Page: Linear is
        title: String;
        motto: Option[String];
        items: Buffer[Index];
        admin: Bool;
        count: Int32;
    end;

    generic [R: Region]
    function render(page: &[Page, R]): String is
        var out: StringBuilder := makeStringBuilder();
        @template("page.jinja", page, out);
        return finalize(out);
    end;

    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Daneben `page.jinja`:

```jinja file page.jinja
{% set name = title ~ "!" %}<p>{{ name }}</p>
```

### H7105

Meldung:

```text
Generic Error
@template: // divides by a number written in the template only: a divisor from the data could be zero, and a division by zero stops the programme
```

// oder % teilt durch einen Namen der Daten oder durch null. Ein Teiler aus den Daten könnte null sein, und eine Division durch null hält das Programm an; der Teiler ist eine im Template geschriebene Zahl.

Dieses Modul scheitert mit H7105:

```hilde fails H7105
import Standard.Buffer (Buffer);
import Standard.String (String);
import Standard.StringBuilder (StringBuilder, makeStringBuilder, finalize);
import Standard.Template (Render);

module body Example is
    record Page: Linear is
        title: String;
        motto: Option[String];
        items: Buffer[Index];
        admin: Bool;
        count: Int32;
    end;

    generic [R: Region]
    function render(page: &[Page, R]): String is
        var out: StringBuilder := makeStringBuilder();
        @template("page.jinja", page, out);
        return finalize(out);
    end;

    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Daneben `page.jinja`:

```jinja file page.jinja
<p>{{ count // count }}</p>
```

Die richtige Form:

```hilde
import Standard.Buffer (Buffer);
import Standard.String (String);
import Standard.StringBuilder (StringBuilder, makeStringBuilder, finalize);
import Standard.Template (Render);

module body Example is
    record Page: Linear is
        title: String;
        motto: Option[String];
        items: Buffer[Index];
        admin: Bool;
        count: Int32;
    end;

    generic [R: Region]
    function render(page: &[Page, R]): String is
        var out: StringBuilder := makeStringBuilder();
        @template("page.jinja", page, out);
        return finalize(out);
    end;

    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Daneben `page.jinja`:

```jinja file page.jinja
<p>{{ count // 2 }}</p>
```

### H7106

Meldung:

```text
Generic Error
@template: this is not a number: + - * // % take numbers, names of the data and the numbers of loop
```

Ein Operand von + - * // % ist etwas anderes als eine Zahl: ein Text, ein Filter oder eine Bedingung.

Dieses Modul scheitert mit H7106:

```hilde fails H7106
import Standard.Buffer (Buffer);
import Standard.String (String);
import Standard.StringBuilder (StringBuilder, makeStringBuilder, finalize);
import Standard.Template (Render);

module body Example is
    record Page: Linear is
        title: String;
        motto: Option[String];
        items: Buffer[Index];
        admin: Bool;
        count: Int32;
    end;

    generic [R: Region]
    function render(page: &[Page, R]): String is
        var out: StringBuilder := makeStringBuilder();
        @template("page.jinja", page, out);
        return finalize(out);
    end;

    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Daneben `page.jinja`:

```jinja file page.jinja
<p>{{ count + "1" }}</p>
```

Die richtige Form:

```hilde
import Standard.Buffer (Buffer);
import Standard.String (String);
import Standard.StringBuilder (StringBuilder, makeStringBuilder, finalize);
import Standard.Template (Render);

module body Example is
    record Page: Linear is
        title: String;
        motto: Option[String];
        items: Buffer[Index];
        admin: Bool;
        count: Int32;
    end;

    generic [R: Region]
    function render(page: &[Page, R]): String is
        var out: StringBuilder := makeStringBuilder();
        @template("page.jinja", page, out);
        return finalize(out);
    end;

    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Daneben `page.jinja`:

```jinja file page.jinja
<p>{{ count + 1 }}</p>
```

### H7107

Meldung:

```text
Generic Error
@template: ~ joins texts that are escaped when printed; a |safe value or a {% set %} block's text cannot be joined to them -- print it on its own
```

Der Operator ~ verbindet einen mit |safe markierten Wert oder den Text eines {% set %}-Blocks mit einem Text, der bei der Ausgabe maskiert wird. Das Ergebnis wäre halb maskiert; der Wert mit |safe wird für sich ausgegeben.

Dieses Modul scheitert mit H7107:

```hilde fails H7107
import Standard.Buffer (Buffer);
import Standard.String (String);
import Standard.StringBuilder (StringBuilder, makeStringBuilder, finalize);
import Standard.Template (Render);

module body Example is
    record Page: Linear is
        title: String;
        motto: Option[String];
        items: Buffer[Index];
        admin: Bool;
        count: Int32;
    end;

    generic [R: Region]
    function render(page: &[Page, R]): String is
        var out: StringBuilder := makeStringBuilder();
        @template("page.jinja", page, out);
        return finalize(out);
    end;

    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Daneben `page.jinja`:

```jinja file page.jinja
<p>{{ title|safe ~ "!" }}</p>
```

Die richtige Form:

```hilde
import Standard.Buffer (Buffer);
import Standard.String (String);
import Standard.StringBuilder (StringBuilder, makeStringBuilder, finalize);
import Standard.Template (Render);

module body Example is
    record Page: Linear is
        title: String;
        motto: Option[String];
        items: Buffer[Index];
        admin: Bool;
        count: Int32;
    end;

    generic [R: Region]
    function render(page: &[Page, R]): String is
        var out: StringBuilder := makeStringBuilder();
        @template("page.jinja", page, out);
        return finalize(out);
    end;

    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Daneben `page.jinja`:

```jinja file page.jinja
<p>{{ title|safe }}!</p>
```

### H7108

Meldung:

```text
Generic Error
@template: |truncate takes a length at least as long as its ending, and a leeway of at least 0
```

Die Argumente von |replace, |truncate, |center, |join oder loop.cycle sind keine Literale der Art, die der Filter nimmt, oder nicht in ihrem Bereich: die Länge von |truncate ist mindestens die Länge ihres Endes.

Dieses Modul scheitert mit H7108:

```hilde fails H7108
import Standard.Buffer (Buffer);
import Standard.String (String);
import Standard.StringBuilder (StringBuilder, makeStringBuilder, finalize);
import Standard.Template (Render);

module body Example is
    record Page: Linear is
        title: String;
        motto: Option[String];
        items: Buffer[Index];
        admin: Bool;
        count: Int32;
    end;

    generic [R: Region]
    function render(page: &[Page, R]): String is
        var out: StringBuilder := makeStringBuilder();
        @template("page.jinja", page, out);
        return finalize(out);
    end;

    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Daneben `page.jinja`:

```jinja file page.jinja
<p>{{ title|truncate(2) }}</p>
```

Die richtige Form:

```hilde
import Standard.Buffer (Buffer);
import Standard.String (String);
import Standard.StringBuilder (StringBuilder, makeStringBuilder, finalize);
import Standard.Template (Render);

module body Example is
    record Page: Linear is
        title: String;
        motto: Option[String];
        items: Buffer[Index];
        admin: Bool;
        count: Int32;
    end;

    generic [R: Region]
    function render(page: &[Page, R]): String is
        var out: StringBuilder := makeStringBuilder();
        @template("page.jinja", page, out);
        return finalize(out);
    end;

    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Daneben `page.jinja`:

```jinja file page.jinja
<p>{{ title|truncate(20) }}</p>
```

### H7109

Meldung:

```text
Generic Error
@template: the filter |join cannot stand in {% filter %}: it applies to a value, not to written text
```

Ein {% filter %}-Block nennt einen Filter, der auf einen Wert wirkt, etwa |join oder |length, nicht auf den Text, den der Block schreibt.

Dieses Modul scheitert mit H7109:

```hilde fails H7109
import Standard.Buffer (Buffer);
import Standard.String (String);
import Standard.StringBuilder (StringBuilder, makeStringBuilder, finalize);
import Standard.Template (Render);

module body Example is
    record Page: Linear is
        title: String;
        motto: Option[String];
        items: Buffer[Index];
        admin: Bool;
        count: Int32;
    end;

    generic [R: Region]
    function render(page: &[Page, R]): String is
        var out: StringBuilder := makeStringBuilder();
        @template("page.jinja", page, out);
        return finalize(out);
    end;

    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Daneben `page.jinja`:

```jinja file page.jinja
{% filter join %}<p>{{ title }}</p>{% endfilter %}
```

Die richtige Form:

```hilde
import Standard.Buffer (Buffer);
import Standard.String (String);
import Standard.StringBuilder (StringBuilder, makeStringBuilder, finalize);
import Standard.Template (Render);

module body Example is
    record Page: Linear is
        title: String;
        motto: Option[String];
        items: Buffer[Index];
        admin: Bool;
        count: Int32;
    end;

    generic [R: Region]
    function render(page: &[Page, R]): String is
        var out: StringBuilder := makeStringBuilder();
        @template("page.jinja", page, out);
        return finalize(out);
    end;

    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Daneben `page.jinja`:

```jinja file page.jinja
{% filter upper %}<p>{{ title }}</p>{% endfilter %}
```

### H7110

Meldung:

```text
Generic Error
@template: {% set name %} inside an {% if %} is refused: in Jinja2 the name is still there after the {% endif %} when the branch ran, and missing when it did not, which a compiled template cannot follow; set it before the {% if %}, or use {% with %}
```

Ein {% set %} steht in einem {% if %}. In Jinja2 ist der Name nach dem {% endif %} noch da, wenn der Zweig lief, und fehlt, wenn nicht; ein kompiliertes Template kann dem nicht folgen. Der Name gehört vor das {% if %}, oder es steht ein {% with %}.

Dieses Modul scheitert mit H7110:

```hilde fails H7110
import Standard.Buffer (Buffer);
import Standard.String (String);
import Standard.StringBuilder (StringBuilder, makeStringBuilder, finalize);
import Standard.Template (Render);

module body Example is
    record Page: Linear is
        title: String;
        motto: Option[String];
        items: Buffer[Index];
        admin: Bool;
        count: Int32;
    end;

    generic [R: Region]
    function render(page: &[Page, R]): String is
        var out: StringBuilder := makeStringBuilder();
        @template("page.jinja", page, out);
        return finalize(out);
    end;

    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Daneben `page.jinja`:

```jinja file page.jinja
{% if admin %}{% set name = title %}{% endif %}<p>{{ title }}</p>
```

Die richtige Form:

```hilde
import Standard.Buffer (Buffer);
import Standard.String (String);
import Standard.StringBuilder (StringBuilder, makeStringBuilder, finalize);
import Standard.Template (Render);

module body Example is
    record Page: Linear is
        title: String;
        motto: Option[String];
        items: Buffer[Index];
        admin: Bool;
        count: Int32;
    end;

    generic [R: Region]
    function render(page: &[Page, R]): String is
        var out: StringBuilder := makeStringBuilder();
        @template("page.jinja", page, out);
        return finalize(out);
    end;

    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Daneben `page.jinja`:

```jinja file page.jinja
{% if admin %}{% with name = title %}<p>{{ name }}</p>{% endwith %}{% endif %}
```

### H7111

Meldung:

```text
Generic Error
@template: a {% set %} or {% filter %} block stands in HTML text and ends there; this one stands in the value of the attribute title
```

Ein {% filter %}-Block steht an einer anderen Stelle als im HTML-Text, oder der Text eines {% set %}- oder {% filter %}-Blocks endet an einer anderen Stelle, als er begann. Was ein solcher Block schreibt, wird als HTML-Text maskiert.

Dieses Modul scheitert mit H7111:

```hilde fails H7111
import Standard.Buffer (Buffer);
import Standard.String (String);
import Standard.StringBuilder (StringBuilder, makeStringBuilder, finalize);
import Standard.Template (Render);

module body Example is
    record Page: Linear is
        title: String;
        motto: Option[String];
        items: Buffer[Index];
        admin: Bool;
        count: Int32;
    end;

    generic [R: Region]
    function render(page: &[Page, R]): String is
        var out: StringBuilder := makeStringBuilder();
        @template("page.jinja", page, out);
        return finalize(out);
    end;

    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Daneben `page.jinja`:

```jinja file page.jinja
<a title="{% filter upper %}{{ title }}{% endfilter %}">x</a>
```

Die richtige Form:

```hilde
import Standard.Buffer (Buffer);
import Standard.String (String);
import Standard.StringBuilder (StringBuilder, makeStringBuilder, finalize);
import Standard.Template (Render);

module body Example is
    record Page: Linear is
        title: String;
        motto: Option[String];
        items: Buffer[Index];
        admin: Bool;
        count: Int32;
    end;

    generic [R: Region]
    function render(page: &[Page, R]): String is
        var out: StringBuilder := makeStringBuilder();
        @template("page.jinja", page, out);
        return finalize(out);
    end;

    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Daneben `page.jinja`:

```jinja file page.jinja
<a title="{{ title|upper }}">x</a>
```

### H7112

Meldung:

```text
Generic Error
@template: caller() stands in a macro that a {% call %} block calls
```

caller() steht in einem Makro, das ohne {% call %}-Block aufgerufen wird, oder bekommt Argumente. Jinja2 scheitert, wenn es einen solchen Aufruf ausgibt.

Dieses Modul scheitert mit H7112:

```hilde fails H7112
import Standard.Buffer (Buffer);
import Standard.String (String);
import Standard.StringBuilder (StringBuilder, makeStringBuilder, finalize);
import Standard.Template (Render);

module body Example is
    record Page: Linear is
        title: String;
        motto: Option[String];
        items: Buffer[Index];
        admin: Bool;
        count: Int32;
    end;

    generic [R: Region]
    function render(page: &[Page, R]): String is
        var out: StringBuilder := makeStringBuilder();
        @template("page.jinja", page, out);
        return finalize(out);
    end;

    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Daneben `page.jinja`:

```jinja file page.jinja
{% macro box() %}<div>{{ caller() }}</div>{% endmacro %}<p>{{ box() }}</p>
```

Die richtige Form:

```hilde
import Standard.Buffer (Buffer);
import Standard.String (String);
import Standard.StringBuilder (StringBuilder, makeStringBuilder, finalize);
import Standard.Template (Render);

module body Example is
    record Page: Linear is
        title: String;
        motto: Option[String];
        items: Buffer[Index];
        admin: Bool;
        count: Int32;
    end;

    generic [R: Region]
    function render(page: &[Page, R]): String is
        var out: StringBuilder := makeStringBuilder();
        @template("page.jinja", page, out);
        return finalize(out);
    end;

    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Daneben `page.jinja`:

```jinja file page.jinja
{% macro box() %}<div>{{ caller() }}</div>{% endmacro %}{% call box() %}{{ title }}{% endcall %}
```

### H7113

Meldung:

```text
Generic Error
@template: the text of a {% set %} block is HTML, escaped already, and is printed in HTML text only, not in the value of the attribute title
```

Der Text, den ein {% set %}-Block geschrieben hat, wird an einer anderen Stelle als im HTML-Text ausgegeben, etwa in einem Attribut. Er ist HTML, bereits maskiert, und wird ausgegeben, wie er steht.

Dieses Modul scheitert mit H7113:

```hilde fails H7113
import Standard.Buffer (Buffer);
import Standard.String (String);
import Standard.StringBuilder (StringBuilder, makeStringBuilder, finalize);
import Standard.Template (Render);

module body Example is
    record Page: Linear is
        title: String;
        motto: Option[String];
        items: Buffer[Index];
        admin: Bool;
        count: Int32;
    end;

    generic [R: Region]
    function render(page: &[Page, R]): String is
        var out: StringBuilder := makeStringBuilder();
        @template("page.jinja", page, out);
        return finalize(out);
    end;

    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Daneben `page.jinja`:

```jinja file page.jinja
{% set cell %}<b>{{ title }}</b>{% endset %}<a title="{{ cell }}">x</a>
```

Die richtige Form:

```hilde
import Standard.Buffer (Buffer);
import Standard.String (String);
import Standard.StringBuilder (StringBuilder, makeStringBuilder, finalize);
import Standard.Template (Render);

module body Example is
    record Page: Linear is
        title: String;
        motto: Option[String];
        items: Buffer[Index];
        admin: Bool;
        count: Int32;
    end;

    generic [R: Region]
    function render(page: &[Page, R]): String is
        var out: StringBuilder := makeStringBuilder();
        @template("page.jinja", page, out);
        return finalize(out);
    end;

    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Daneben `page.jinja`:

```jinja file page.jinja
{% set cell %}<b>{{ title }}</b>{% endset %}<p>{{ cell }}</p>
```

### H7114

Meldung:

```text
Generic Error
@template: "strict": @template knows the options trim_blocks and lstrip_blocks
```

Das vierte Argument von @template nennt eine andere Option als trim_blocks und lstrip_blocks.

Dieses Modul scheitert mit H7114:

```hilde fails H7114
import Standard.Buffer (Buffer);
import Standard.String (String);
import Standard.StringBuilder (StringBuilder, makeStringBuilder, finalize);
import Standard.Template (Render);

module body Example is
    record Page: Linear is
        title: String;
        motto: Option[String];
        items: Buffer[Index];
        admin: Bool;
        count: Int32;
    end;

    generic [R: Region]
    function render(page: &[Page, R]): String is
        var out: StringBuilder := makeStringBuilder();
        @template("page.jinja", page, out, "strict");
        return finalize(out);
    end;

    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Daneben `page.jinja`:

```jinja file page.jinja
<p>{{ title }}</p>
```

Die richtige Form:

```hilde
import Standard.Buffer (Buffer);
import Standard.String (String);
import Standard.StringBuilder (StringBuilder, makeStringBuilder, finalize);
import Standard.Template (Render);

module body Example is
    record Page: Linear is
        title: String;
        motto: Option[String];
        items: Buffer[Index];
        admin: Bool;
        count: Int32;
    end;

    generic [R: Region]
    function render(page: &[Page, R]): String is
        var out: StringBuilder := makeStringBuilder();
        @template("page.jinja", page, out, "trim_blocks");
        return finalize(out);
    end;

    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Daneben `page.jinja`:

```jinja file page.jinja
<p>{{ title }}</p>
```

### H7115

Meldung:

```text
Generic Error
@template: _( ) takes the key first, as a string literal, as in _("Greeting")
```

Das erste Argument von _( ) ist der Schlüssel, geschrieben als String-Literal: der Name eines Falls der Schlüssel des Katalogs. Ein Name der Daten oder ein Ausdruck an seiner Stelle wäre ein Schlüssel, der erst beim Rendern feststeht, und den kann der Compiler nicht prüfen.

Dieses Modul scheitert mit H7115:

```hilde fails H7115
import Standard.String (
    String,
    fromLiteral,
    destroyString
);
import Standard.StringBuilder (
    StringBuilder,
    makeStringBuilder,
    finalize
);
import Standard.Template (
    Render
);
import Standard.I18n (
    Message,
    Text,
    Plural,
    Language,
    Catalog,
    englishPlural,
    germanPlural
);

module body Example is
    union Key: Free is
        case Greeting;
        case Items;
    end;

    function english(key: Key): Message is
        case key of
            when Greeting do
                return Text(text => "Hello, {name}!");
            when Items do
                return Plural(one => "{count} item", other => "{count} items");
        end case;
    end;

    function german(key: Key): Message is
        case key of
            when Greeting do
                return Text(text => "Hallo, {name}!");
            when Items do
                return Plural(one => "{count} Teil", other => "{count} Teile");
        end case;
    end;

    function others(i: Index): Option[Language[Key]] is
        if i = 0 then
            return Some(value => Language(code => "de", texts => german, plural => germanPlural));
        end if;
        return None();
    end;

    function messages(): Catalog[Key] is
        return Catalog(default => Language(code => "en", texts => english, plural => englishPlural), others => others);
    end;

    record Page: Linear is
        lang: String;
        user: String;
        count: Int32;
    end;

    generic [R: Region]
    function render(page: &[Page, R]): String is
        var out: StringBuilder := makeStringBuilder();
        @template("page.jinja", page, out);
        return finalize(out);
    end;

    function main(): ExitCode is
        let page: Page := Page(lang => fromLiteral("de"), user => fromLiteral("Ada"), count => 2);
        let text: String := render(&page);
        destroyString(text);
        let { lang: String, user: String, count: Int32 } := page;
        destroyString(lang);
        destroyString(user);
        return ExitSuccess();
    end;
end module body.
```

Daneben, `page.jinja`:

```jinja file page.jinja
{% catalog messages %}<p>{{ _(user) }}</p>
```

Die richtige Form:

```hilde
import Standard.String (
    String,
    fromLiteral,
    destroyString
);
import Standard.StringBuilder (
    StringBuilder,
    makeStringBuilder,
    finalize
);
import Standard.Template (
    Render
);
import Standard.I18n (
    Message,
    Text,
    Plural,
    Language,
    Catalog,
    englishPlural,
    germanPlural
);

module body Example is
    union Key: Free is
        case Greeting;
        case Items;
    end;

    function english(key: Key): Message is
        case key of
            when Greeting do
                return Text(text => "Hello, {name}!");
            when Items do
                return Plural(one => "{count} item", other => "{count} items");
        end case;
    end;

    function german(key: Key): Message is
        case key of
            when Greeting do
                return Text(text => "Hallo, {name}!");
            when Items do
                return Plural(one => "{count} Teil", other => "{count} Teile");
        end case;
    end;

    function others(i: Index): Option[Language[Key]] is
        if i = 0 then
            return Some(value => Language(code => "de", texts => german, plural => germanPlural));
        end if;
        return None();
    end;

    function messages(): Catalog[Key] is
        return Catalog(default => Language(code => "en", texts => english, plural => englishPlural), others => others);
    end;

    record Page: Linear is
        lang: String;
        user: String;
        count: Int32;
    end;

    generic [R: Region]
    function render(page: &[Page, R]): String is
        var out: StringBuilder := makeStringBuilder();
        @template("page.jinja", page, out);
        return finalize(out);
    end;

    function main(): ExitCode is
        let page: Page := Page(lang => fromLiteral("de"), user => fromLiteral("Ada"), count => 2);
        let text: String := render(&page);
        destroyString(text);
        let { lang: String, user: String, count: Int32 } := page;
        destroyString(lang);
        destroyString(user);
        return ExitSuccess();
    end;
end module body.
```

Daneben, `page.jinja`:

```jinja file page.jinja
{% catalog messages %}<p>{{ _("Greeting", name=user) }}</p>
```

### H7116

Meldung:

```text
Generic Error
@template: _( ) is given name twice
```

Jedes Argument von _( ) hat einen eigenen Namen; derselbe Name zweimal ließe offen, welchen Wert der Platzhalter bekommt.

Dieses Modul scheitert mit H7116:

```hilde fails H7116
import Standard.String (
    String,
    fromLiteral,
    destroyString
);
import Standard.StringBuilder (
    StringBuilder,
    makeStringBuilder,
    finalize
);
import Standard.Template (
    Render
);
import Standard.I18n (
    Message,
    Text,
    Plural,
    Language,
    Catalog,
    englishPlural,
    germanPlural
);

module body Example is
    union Key: Free is
        case Greeting;
        case Items;
    end;

    function english(key: Key): Message is
        case key of
            when Greeting do
                return Text(text => "Hello, {name}!");
            when Items do
                return Plural(one => "{count} item", other => "{count} items");
        end case;
    end;

    function german(key: Key): Message is
        case key of
            when Greeting do
                return Text(text => "Hallo, {name}!");
            when Items do
                return Plural(one => "{count} Teil", other => "{count} Teile");
        end case;
    end;

    function others(i: Index): Option[Language[Key]] is
        if i = 0 then
            return Some(value => Language(code => "de", texts => german, plural => germanPlural));
        end if;
        return None();
    end;

    function messages(): Catalog[Key] is
        return Catalog(default => Language(code => "en", texts => english, plural => englishPlural), others => others);
    end;

    record Page: Linear is
        lang: String;
        user: String;
        count: Int32;
    end;

    generic [R: Region]
    function render(page: &[Page, R]): String is
        var out: StringBuilder := makeStringBuilder();
        @template("page.jinja", page, out);
        return finalize(out);
    end;

    function main(): ExitCode is
        let page: Page := Page(lang => fromLiteral("de"), user => fromLiteral("Ada"), count => 2);
        let text: String := render(&page);
        destroyString(text);
        let { lang: String, user: String, count: Int32 } := page;
        destroyString(lang);
        destroyString(user);
        return ExitSuccess();
    end;
end module body.
```

Daneben, `page.jinja`:

```jinja file page.jinja
{% catalog messages %}<p>{{ _("Greeting", name=user, name=user) }}</p>
```

Die richtige Form:

```hilde
import Standard.String (
    String,
    fromLiteral,
    destroyString
);
import Standard.StringBuilder (
    StringBuilder,
    makeStringBuilder,
    finalize
);
import Standard.Template (
    Render
);
import Standard.I18n (
    Message,
    Text,
    Plural,
    Language,
    Catalog,
    englishPlural,
    germanPlural
);

module body Example is
    union Key: Free is
        case Greeting;
        case Items;
    end;

    function english(key: Key): Message is
        case key of
            when Greeting do
                return Text(text => "Hello, {name}!");
            when Items do
                return Plural(one => "{count} item", other => "{count} items");
        end case;
    end;

    function german(key: Key): Message is
        case key of
            when Greeting do
                return Text(text => "Hallo, {name}!");
            when Items do
                return Plural(one => "{count} Teil", other => "{count} Teile");
        end case;
    end;

    function others(i: Index): Option[Language[Key]] is
        if i = 0 then
            return Some(value => Language(code => "de", texts => german, plural => germanPlural));
        end if;
        return None();
    end;

    function messages(): Catalog[Key] is
        return Catalog(default => Language(code => "en", texts => english, plural => englishPlural), others => others);
    end;

    record Page: Linear is
        lang: String;
        user: String;
        count: Int32;
    end;

    generic [R: Region]
    function render(page: &[Page, R]): String is
        var out: StringBuilder := makeStringBuilder();
        @template("page.jinja", page, out);
        return finalize(out);
    end;

    function main(): ExitCode is
        let page: Page := Page(lang => fromLiteral("de"), user => fromLiteral("Ada"), count => 2);
        let text: String := render(&page);
        destroyString(text);
        let { lang: String, user: String, count: Int32 } := page;
        destroyString(lang);
        destroyString(user);
        return ExitSuccess();
    end;
end module body.
```

Daneben, `page.jinja`:

```jinja file page.jinja
{% catalog messages %}<p>{{ _("Greeting", name=user) }}</p>
```

### H7117

Meldung:

```text
Generic Error
@template: {% catalog %} takes the name of a function of no arguments that gives the catalog, as in {% catalog messages %}
```

{% catalog %} nimmt den Namen einer Funktion ohne Argumente, die den Katalog liefert, ohne Anführungszeichen; das Modul mit dem @template hat die Funktion oder importiert sie.

Dieses Modul scheitert mit H7117:

```hilde fails H7117
import Standard.String (
    String,
    fromLiteral,
    destroyString
);
import Standard.StringBuilder (
    StringBuilder,
    makeStringBuilder,
    finalize
);
import Standard.Template (
    Render
);
import Standard.I18n (
    Message,
    Text,
    Plural,
    Language,
    Catalog,
    englishPlural,
    germanPlural
);

module body Example is
    union Key: Free is
        case Greeting;
        case Items;
    end;

    function english(key: Key): Message is
        case key of
            when Greeting do
                return Text(text => "Hello, {name}!");
            when Items do
                return Plural(one => "{count} item", other => "{count} items");
        end case;
    end;

    function german(key: Key): Message is
        case key of
            when Greeting do
                return Text(text => "Hallo, {name}!");
            when Items do
                return Plural(one => "{count} Teil", other => "{count} Teile");
        end case;
    end;

    function others(i: Index): Option[Language[Key]] is
        if i = 0 then
            return Some(value => Language(code => "de", texts => german, plural => germanPlural));
        end if;
        return None();
    end;

    function messages(): Catalog[Key] is
        return Catalog(default => Language(code => "en", texts => english, plural => englishPlural), others => others);
    end;

    record Page: Linear is
        lang: String;
        user: String;
        count: Int32;
    end;

    generic [R: Region]
    function render(page: &[Page, R]): String is
        var out: StringBuilder := makeStringBuilder();
        @template("page.jinja", page, out);
        return finalize(out);
    end;

    function main(): ExitCode is
        let page: Page := Page(lang => fromLiteral("de"), user => fromLiteral("Ada"), count => 2);
        let text: String := render(&page);
        destroyString(text);
        let { lang: String, user: String, count: Int32 } := page;
        destroyString(lang);
        destroyString(user);
        return ExitSuccess();
    end;
end module body.
```

Daneben, `page.jinja`:

```jinja file page.jinja
{% catalog "messages" %}<p>{{ _("Greeting", name=user) }}</p>
```

Die richtige Form:

```hilde
import Standard.String (
    String,
    fromLiteral,
    destroyString
);
import Standard.StringBuilder (
    StringBuilder,
    makeStringBuilder,
    finalize
);
import Standard.Template (
    Render
);
import Standard.I18n (
    Message,
    Text,
    Plural,
    Language,
    Catalog,
    englishPlural,
    germanPlural
);

module body Example is
    union Key: Free is
        case Greeting;
        case Items;
    end;

    function english(key: Key): Message is
        case key of
            when Greeting do
                return Text(text => "Hello, {name}!");
            when Items do
                return Plural(one => "{count} item", other => "{count} items");
        end case;
    end;

    function german(key: Key): Message is
        case key of
            when Greeting do
                return Text(text => "Hallo, {name}!");
            when Items do
                return Plural(one => "{count} Teil", other => "{count} Teile");
        end case;
    end;

    function others(i: Index): Option[Language[Key]] is
        if i = 0 then
            return Some(value => Language(code => "de", texts => german, plural => germanPlural));
        end if;
        return None();
    end;

    function messages(): Catalog[Key] is
        return Catalog(default => Language(code => "en", texts => english, plural => englishPlural), others => others);
    end;

    record Page: Linear is
        lang: String;
        user: String;
        count: Int32;
    end;

    generic [R: Region]
    function render(page: &[Page, R]): String is
        var out: StringBuilder := makeStringBuilder();
        @template("page.jinja", page, out);
        return finalize(out);
    end;

    function main(): ExitCode is
        let page: Page := Page(lang => fromLiteral("de"), user => fromLiteral("Ada"), count => 2);
        let text: String := render(&page);
        destroyString(text);
        let { lang: String, user: String, count: Int32 } := page;
        destroyString(lang);
        destroyString(user);
        return ExitSuccess();
    end;
end module body.
```

Daneben, `page.jinja`:

```jinja file page.jinja
{% catalog messages %}<p>{{ _("Greeting", name=user) }}</p>
```

### H7118

Meldung:

```text
Generic Error
@template: the text of a {% trans %} block is its key, one name such as Greeting; the texts of the languages stand in the catalog
```

Der Text zwischen {% trans %} und {% pluralize %} oder {% endtrans %} ist der Schlüssel, ein Name wie Greeting. Die Texte der Sprachen stehen im Katalog, nicht im Template.

Dieses Modul scheitert mit H7118:

```hilde fails H7118
import Standard.String (
    String,
    fromLiteral,
    destroyString
);
import Standard.StringBuilder (
    StringBuilder,
    makeStringBuilder,
    finalize
);
import Standard.Template (
    Render
);
import Standard.I18n (
    Message,
    Text,
    Plural,
    Language,
    Catalog,
    englishPlural,
    germanPlural
);

module body Example is
    union Key: Free is
        case Greeting;
        case Items;
    end;

    function english(key: Key): Message is
        case key of
            when Greeting do
                return Text(text => "Hello, {name}!");
            when Items do
                return Plural(one => "{count} item", other => "{count} items");
        end case;
    end;

    function german(key: Key): Message is
        case key of
            when Greeting do
                return Text(text => "Hallo, {name}!");
            when Items do
                return Plural(one => "{count} Teil", other => "{count} Teile");
        end case;
    end;

    function others(i: Index): Option[Language[Key]] is
        if i = 0 then
            return Some(value => Language(code => "de", texts => german, plural => germanPlural));
        end if;
        return None();
    end;

    function messages(): Catalog[Key] is
        return Catalog(default => Language(code => "en", texts => english, plural => englishPlural), others => others);
    end;

    record Page: Linear is
        lang: String;
        user: String;
        count: Int32;
    end;

    generic [R: Region]
    function render(page: &[Page, R]): String is
        var out: StringBuilder := makeStringBuilder();
        @template("page.jinja", page, out);
        return finalize(out);
    end;

    function main(): ExitCode is
        let page: Page := Page(lang => fromLiteral("de"), user => fromLiteral("Ada"), count => 2);
        let text: String := render(&page);
        destroyString(text);
        let { lang: String, user: String, count: Int32 } := page;
        destroyString(lang);
        destroyString(user);
        return ExitSuccess();
    end;
end module body.
```

Daneben, `page.jinja`:

```jinja file page.jinja
{% catalog messages %}<p>{% trans name=user %}Hello, {{ name }}!{% endtrans %}</p>
```

Die richtige Form:

```hilde
import Standard.String (
    String,
    fromLiteral,
    destroyString
);
import Standard.StringBuilder (
    StringBuilder,
    makeStringBuilder,
    finalize
);
import Standard.Template (
    Render
);
import Standard.I18n (
    Message,
    Text,
    Plural,
    Language,
    Catalog,
    englishPlural,
    germanPlural
);

module body Example is
    union Key: Free is
        case Greeting;
        case Items;
    end;

    function english(key: Key): Message is
        case key of
            when Greeting do
                return Text(text => "Hello, {name}!");
            when Items do
                return Plural(one => "{count} item", other => "{count} items");
        end case;
    end;

    function german(key: Key): Message is
        case key of
            when Greeting do
                return Text(text => "Hallo, {name}!");
            when Items do
                return Plural(one => "{count} Teil", other => "{count} Teile");
        end case;
    end;

    function others(i: Index): Option[Language[Key]] is
        if i = 0 then
            return Some(value => Language(code => "de", texts => german, plural => germanPlural));
        end if;
        return None();
    end;

    function messages(): Catalog[Key] is
        return Catalog(default => Language(code => "en", texts => english, plural => englishPlural), others => others);
    end;

    record Page: Linear is
        lang: String;
        user: String;
        count: Int32;
    end;

    generic [R: Region]
    function render(page: &[Page, R]): String is
        var out: StringBuilder := makeStringBuilder();
        @template("page.jinja", page, out);
        return finalize(out);
    end;

    function main(): ExitCode is
        let page: Page := Page(lang => fromLiteral("de"), user => fromLiteral("Ada"), count => 2);
        let text: String := render(&page);
        destroyString(text);
        let { lang: String, user: String, count: Int32 } := page;
        destroyString(lang);
        destroyString(user);
        return ExitSuccess();
    end;
end module body.
```

Daneben, `page.jinja`:

```jinja file page.jinja
{% catalog messages %}<p>{% trans name=user %}Greeting{% endtrans %}</p>
```

### H7119

Meldung:

```text
Generic Error
@template: {% pluralize %} needs count=... in its {% trans %}: the count chooses the form
```

Die Anzahl wählt die Pluralform, also nennt ein {% trans %}-Block mit {% pluralize %} sie: count=... in seinem Tag.

Dieses Modul scheitert mit H7119:

```hilde fails H7119
import Standard.String (
    String,
    fromLiteral,
    destroyString
);
import Standard.StringBuilder (
    StringBuilder,
    makeStringBuilder,
    finalize
);
import Standard.Template (
    Render
);
import Standard.I18n (
    Message,
    Text,
    Plural,
    Language,
    Catalog,
    englishPlural,
    germanPlural
);

module body Example is
    union Key: Free is
        case Greeting;
        case Items;
    end;

    function english(key: Key): Message is
        case key of
            when Greeting do
                return Text(text => "Hello, {name}!");
            when Items do
                return Plural(one => "{count} item", other => "{count} items");
        end case;
    end;

    function german(key: Key): Message is
        case key of
            when Greeting do
                return Text(text => "Hallo, {name}!");
            when Items do
                return Plural(one => "{count} Teil", other => "{count} Teile");
        end case;
    end;

    function others(i: Index): Option[Language[Key]] is
        if i = 0 then
            return Some(value => Language(code => "de", texts => german, plural => germanPlural));
        end if;
        return None();
    end;

    function messages(): Catalog[Key] is
        return Catalog(default => Language(code => "en", texts => english, plural => englishPlural), others => others);
    end;

    record Page: Linear is
        lang: String;
        user: String;
        count: Int32;
    end;

    generic [R: Region]
    function render(page: &[Page, R]): String is
        var out: StringBuilder := makeStringBuilder();
        @template("page.jinja", page, out);
        return finalize(out);
    end;

    function main(): ExitCode is
        let page: Page := Page(lang => fromLiteral("de"), user => fromLiteral("Ada"), count => 2);
        let text: String := render(&page);
        destroyString(text);
        let { lang: String, user: String, count: Int32 } := page;
        destroyString(lang);
        destroyString(user);
        return ExitSuccess();
    end;
end module body.
```

Daneben, `page.jinja`:

```jinja file page.jinja
{% catalog messages %}<p>{% trans %}Items{% pluralize %}{% endtrans %}</p>
```

Die richtige Form:

```hilde
import Standard.String (
    String,
    fromLiteral,
    destroyString
);
import Standard.StringBuilder (
    StringBuilder,
    makeStringBuilder,
    finalize
);
import Standard.Template (
    Render
);
import Standard.I18n (
    Message,
    Text,
    Plural,
    Language,
    Catalog,
    englishPlural,
    germanPlural
);

module body Example is
    union Key: Free is
        case Greeting;
        case Items;
    end;

    function english(key: Key): Message is
        case key of
            when Greeting do
                return Text(text => "Hello, {name}!");
            when Items do
                return Plural(one => "{count} item", other => "{count} items");
        end case;
    end;

    function german(key: Key): Message is
        case key of
            when Greeting do
                return Text(text => "Hallo, {name}!");
            when Items do
                return Plural(one => "{count} Teil", other => "{count} Teile");
        end case;
    end;

    function others(i: Index): Option[Language[Key]] is
        if i = 0 then
            return Some(value => Language(code => "de", texts => german, plural => germanPlural));
        end if;
        return None();
    end;

    function messages(): Catalog[Key] is
        return Catalog(default => Language(code => "en", texts => english, plural => englishPlural), others => others);
    end;

    record Page: Linear is
        lang: String;
        user: String;
        count: Int32;
    end;

    generic [R: Region]
    function render(page: &[Page, R]): String is
        var out: StringBuilder := makeStringBuilder();
        @template("page.jinja", page, out);
        return finalize(out);
    end;

    function main(): ExitCode is
        let page: Page := Page(lang => fromLiteral("de"), user => fromLiteral("Ada"), count => 2);
        let text: String := render(&page);
        destroyString(text);
        let { lang: String, user: String, count: Int32 } := page;
        destroyString(lang);
        destroyString(user);
        return ExitSuccess();
    end;
end module body.
```

Daneben, `page.jinja`:

```jinja file page.jinja
{% catalog messages %}<p>{% trans count=count %}Items{% pluralize %}{% endtrans %}</p>
```

### H7120

Meldung:

```text
Generic Error
@template: between {% pluralize %} and {% endtrans %} nothing may stand: the plural forms are in the catalog
```

In Jinja2 ist der Text nach {% pluralize %} die Pluralform. Hier stehen die Formen jeder Sprache im Katalog, deshalb darf dort nichts stehen.

Dieses Modul scheitert mit H7120:

```hilde fails H7120
import Standard.String (
    String,
    fromLiteral,
    destroyString
);
import Standard.StringBuilder (
    StringBuilder,
    makeStringBuilder,
    finalize
);
import Standard.Template (
    Render
);
import Standard.I18n (
    Message,
    Text,
    Plural,
    Language,
    Catalog,
    englishPlural,
    germanPlural
);

module body Example is
    union Key: Free is
        case Greeting;
        case Items;
    end;

    function english(key: Key): Message is
        case key of
            when Greeting do
                return Text(text => "Hello, {name}!");
            when Items do
                return Plural(one => "{count} item", other => "{count} items");
        end case;
    end;

    function german(key: Key): Message is
        case key of
            when Greeting do
                return Text(text => "Hallo, {name}!");
            when Items do
                return Plural(one => "{count} Teil", other => "{count} Teile");
        end case;
    end;

    function others(i: Index): Option[Language[Key]] is
        if i = 0 then
            return Some(value => Language(code => "de", texts => german, plural => germanPlural));
        end if;
        return None();
    end;

    function messages(): Catalog[Key] is
        return Catalog(default => Language(code => "en", texts => english, plural => englishPlural), others => others);
    end;

    record Page: Linear is
        lang: String;
        user: String;
        count: Int32;
    end;

    generic [R: Region]
    function render(page: &[Page, R]): String is
        var out: StringBuilder := makeStringBuilder();
        @template("page.jinja", page, out);
        return finalize(out);
    end;

    function main(): ExitCode is
        let page: Page := Page(lang => fromLiteral("de"), user => fromLiteral("Ada"), count => 2);
        let text: String := render(&page);
        destroyString(text);
        let { lang: String, user: String, count: Int32 } := page;
        destroyString(lang);
        destroyString(user);
        return ExitSuccess();
    end;
end module body.
```

Daneben, `page.jinja`:

```jinja file page.jinja
{% catalog messages %}<p>{% trans count=count %}Items{% pluralize %}{{ count }} items{% endtrans %}</p>
```

Die richtige Form:

```hilde
import Standard.String (
    String,
    fromLiteral,
    destroyString
);
import Standard.StringBuilder (
    StringBuilder,
    makeStringBuilder,
    finalize
);
import Standard.Template (
    Render
);
import Standard.I18n (
    Message,
    Text,
    Plural,
    Language,
    Catalog,
    englishPlural,
    germanPlural
);

module body Example is
    union Key: Free is
        case Greeting;
        case Items;
    end;

    function english(key: Key): Message is
        case key of
            when Greeting do
                return Text(text => "Hello, {name}!");
            when Items do
                return Plural(one => "{count} item", other => "{count} items");
        end case;
    end;

    function german(key: Key): Message is
        case key of
            when Greeting do
                return Text(text => "Hallo, {name}!");
            when Items do
                return Plural(one => "{count} Teil", other => "{count} Teile");
        end case;
    end;

    function others(i: Index): Option[Language[Key]] is
        if i = 0 then
            return Some(value => Language(code => "de", texts => german, plural => germanPlural));
        end if;
        return None();
    end;

    function messages(): Catalog[Key] is
        return Catalog(default => Language(code => "en", texts => english, plural => englishPlural), others => others);
    end;

    record Page: Linear is
        lang: String;
        user: String;
        count: Int32;
    end;

    generic [R: Region]
    function render(page: &[Page, R]): String is
        var out: StringBuilder := makeStringBuilder();
        @template("page.jinja", page, out);
        return finalize(out);
    end;

    function main(): ExitCode is
        let page: Page := Page(lang => fromLiteral("de"), user => fromLiteral("Ada"), count => 2);
        let text: String := render(&page);
        destroyString(text);
        let { lang: String, user: String, count: Int32 } := page;
        destroyString(lang);
        destroyString(user);
        return ExitSuccess();
    end;
end module body.
```

Daneben, `page.jinja`:

```jinja file page.jinja
{% catalog messages %}<p>{% trans count=count %}Items{% pluralize %}{% endtrans %}</p>
```

### H7121

Meldung:

```text
Generic Error
@template: a template names its catalog once, with one {% catalog %}
```

Ein Template nimmt seine Übersetzungen aus einem Katalog, einmal genannt mit {% catalog %}.

Dieses Modul scheitert mit H7121:

```hilde fails H7121
import Standard.String (
    String,
    fromLiteral,
    destroyString
);
import Standard.StringBuilder (
    StringBuilder,
    makeStringBuilder,
    finalize
);
import Standard.Template (
    Render
);
import Standard.I18n (
    Message,
    Text,
    Plural,
    Language,
    Catalog,
    englishPlural,
    germanPlural
);

module body Example is
    union Key: Free is
        case Greeting;
        case Items;
    end;

    function english(key: Key): Message is
        case key of
            when Greeting do
                return Text(text => "Hello, {name}!");
            when Items do
                return Plural(one => "{count} item", other => "{count} items");
        end case;
    end;

    function german(key: Key): Message is
        case key of
            when Greeting do
                return Text(text => "Hallo, {name}!");
            when Items do
                return Plural(one => "{count} Teil", other => "{count} Teile");
        end case;
    end;

    function others(i: Index): Option[Language[Key]] is
        if i = 0 then
            return Some(value => Language(code => "de", texts => german, plural => germanPlural));
        end if;
        return None();
    end;

    function messages(): Catalog[Key] is
        return Catalog(default => Language(code => "en", texts => english, plural => englishPlural), others => others);
    end;

    record Page: Linear is
        lang: String;
        user: String;
        count: Int32;
    end;

    generic [R: Region]
    function render(page: &[Page, R]): String is
        var out: StringBuilder := makeStringBuilder();
        @template("page.jinja", page, out);
        return finalize(out);
    end;

    function main(): ExitCode is
        let page: Page := Page(lang => fromLiteral("de"), user => fromLiteral("Ada"), count => 2);
        let text: String := render(&page);
        destroyString(text);
        let { lang: String, user: String, count: Int32 } := page;
        destroyString(lang);
        destroyString(user);
        return ExitSuccess();
    end;
end module body.
```

Daneben, `page.jinja`:

```jinja file page.jinja
{% catalog messages %}{% catalog messages %}<p>{{ _("Greeting", name=user) }}</p>
```

Die richtige Form:

```hilde
import Standard.String (
    String,
    fromLiteral,
    destroyString
);
import Standard.StringBuilder (
    StringBuilder,
    makeStringBuilder,
    finalize
);
import Standard.Template (
    Render
);
import Standard.I18n (
    Message,
    Text,
    Plural,
    Language,
    Catalog,
    englishPlural,
    germanPlural
);

module body Example is
    union Key: Free is
        case Greeting;
        case Items;
    end;

    function english(key: Key): Message is
        case key of
            when Greeting do
                return Text(text => "Hello, {name}!");
            when Items do
                return Plural(one => "{count} item", other => "{count} items");
        end case;
    end;

    function german(key: Key): Message is
        case key of
            when Greeting do
                return Text(text => "Hallo, {name}!");
            when Items do
                return Plural(one => "{count} Teil", other => "{count} Teile");
        end case;
    end;

    function others(i: Index): Option[Language[Key]] is
        if i = 0 then
            return Some(value => Language(code => "de", texts => german, plural => germanPlural));
        end if;
        return None();
    end;

    function messages(): Catalog[Key] is
        return Catalog(default => Language(code => "en", texts => english, plural => englishPlural), others => others);
    end;

    record Page: Linear is
        lang: String;
        user: String;
        count: Int32;
    end;

    generic [R: Region]
    function render(page: &[Page, R]): String is
        var out: StringBuilder := makeStringBuilder();
        @template("page.jinja", page, out);
        return finalize(out);
    end;

    function main(): ExitCode is
        let page: Page := Page(lang => fromLiteral("de"), user => fromLiteral("Ada"), count => 2);
        let text: String := render(&page);
        destroyString(text);
        let { lang: String, user: String, count: Int32 } := page;
        destroyString(lang);
        destroyString(user);
        return ExitSuccess();
    end;
end module body.
```

Daneben, `page.jinja`:

```jinja file page.jinja
{% catalog messages %}<p>{{ _("Greeting", name=user) }}</p>
```

### H7122

Meldung:

```text
Generic Error
@template: a translation needs the template's catalog: {% catalog name %} before it
```

Eine Übersetzung braucht den Katalog, aus dem sie kommt: {% catalog name %} steht vor dem ersten _( ) oder {% trans %} des Templates.

Dieses Modul scheitert mit H7122:

```hilde fails H7122
import Standard.String (
    String,
    fromLiteral,
    destroyString
);
import Standard.StringBuilder (
    StringBuilder,
    makeStringBuilder,
    finalize
);
import Standard.Template (
    Render
);
import Standard.I18n (
    Message,
    Text,
    Plural,
    Language,
    Catalog,
    englishPlural,
    germanPlural
);

module body Example is
    union Key: Free is
        case Greeting;
        case Items;
    end;

    function english(key: Key): Message is
        case key of
            when Greeting do
                return Text(text => "Hello, {name}!");
            when Items do
                return Plural(one => "{count} item", other => "{count} items");
        end case;
    end;

    function german(key: Key): Message is
        case key of
            when Greeting do
                return Text(text => "Hallo, {name}!");
            when Items do
                return Plural(one => "{count} Teil", other => "{count} Teile");
        end case;
    end;

    function others(i: Index): Option[Language[Key]] is
        if i = 0 then
            return Some(value => Language(code => "de", texts => german, plural => germanPlural));
        end if;
        return None();
    end;

    function messages(): Catalog[Key] is
        return Catalog(default => Language(code => "en", texts => english, plural => englishPlural), others => others);
    end;

    record Page: Linear is
        lang: String;
        user: String;
        count: Int32;
    end;

    generic [R: Region]
    function render(page: &[Page, R]): String is
        var out: StringBuilder := makeStringBuilder();
        @template("page.jinja", page, out);
        return finalize(out);
    end;

    function main(): ExitCode is
        let page: Page := Page(lang => fromLiteral("de"), user => fromLiteral("Ada"), count => 2);
        let text: String := render(&page);
        destroyString(text);
        let { lang: String, user: String, count: Int32 } := page;
        destroyString(lang);
        destroyString(user);
        return ExitSuccess();
    end;
end module body.
```

Daneben, `page.jinja`:

```jinja file page.jinja
<p>{{ _("Greeting", name=user) }}</p>
```

Die richtige Form:

```hilde
import Standard.String (
    String,
    fromLiteral,
    destroyString
);
import Standard.StringBuilder (
    StringBuilder,
    makeStringBuilder,
    finalize
);
import Standard.Template (
    Render
);
import Standard.I18n (
    Message,
    Text,
    Plural,
    Language,
    Catalog,
    englishPlural,
    germanPlural
);

module body Example is
    union Key: Free is
        case Greeting;
        case Items;
    end;

    function english(key: Key): Message is
        case key of
            when Greeting do
                return Text(text => "Hello, {name}!");
            when Items do
                return Plural(one => "{count} item", other => "{count} items");
        end case;
    end;

    function german(key: Key): Message is
        case key of
            when Greeting do
                return Text(text => "Hallo, {name}!");
            when Items do
                return Plural(one => "{count} Teil", other => "{count} Teile");
        end case;
    end;

    function others(i: Index): Option[Language[Key]] is
        if i = 0 then
            return Some(value => Language(code => "de", texts => german, plural => germanPlural));
        end if;
        return None();
    end;

    function messages(): Catalog[Key] is
        return Catalog(default => Language(code => "en", texts => english, plural => englishPlural), others => others);
    end;

    record Page: Linear is
        lang: String;
        user: String;
        count: Int32;
    end;

    generic [R: Region]
    function render(page: &[Page, R]): String is
        var out: StringBuilder := makeStringBuilder();
        @template("page.jinja", page, out);
        return finalize(out);
    end;

    function main(): ExitCode is
        let page: Page := Page(lang => fromLiteral("de"), user => fromLiteral("Ada"), count => 2);
        let text: String := render(&page);
        destroyString(text);
        let { lang: String, user: String, count: Int32 } := page;
        destroyString(lang);
        destroyString(user);
        return ExitSuccess();
    end;
end module body.
```

Daneben, `page.jinja`:

```jinja file page.jinja
{% catalog messages %}<p>{{ _("Greeting", name=user) }}</p>
```

### H7123

Meldung:

```text
Generic Error
@template: a translation is text for HTML and cannot stand in a <script> element
```

Eine Übersetzung ist Text für HTML, maskiert für die Stelle, an der sie landet, und kann nicht dort stehen, wo ein JavaScript-Ausdruck hingehört.

Dieses Modul scheitert mit H7123:

```hilde fails H7123
import Standard.String (
    String,
    fromLiteral,
    destroyString
);
import Standard.StringBuilder (
    StringBuilder,
    makeStringBuilder,
    finalize
);
import Standard.Template (
    Render
);
import Standard.I18n (
    Message,
    Text,
    Plural,
    Language,
    Catalog,
    englishPlural,
    germanPlural
);

module body Example is
    union Key: Free is
        case Greeting;
        case Items;
    end;

    function english(key: Key): Message is
        case key of
            when Greeting do
                return Text(text => "Hello, {name}!");
            when Items do
                return Plural(one => "{count} item", other => "{count} items");
        end case;
    end;

    function german(key: Key): Message is
        case key of
            when Greeting do
                return Text(text => "Hallo, {name}!");
            when Items do
                return Plural(one => "{count} Teil", other => "{count} Teile");
        end case;
    end;

    function others(i: Index): Option[Language[Key]] is
        if i = 0 then
            return Some(value => Language(code => "de", texts => german, plural => germanPlural));
        end if;
        return None();
    end;

    function messages(): Catalog[Key] is
        return Catalog(default => Language(code => "en", texts => english, plural => englishPlural), others => others);
    end;

    record Page: Linear is
        lang: String;
        user: String;
        count: Int32;
    end;

    generic [R: Region]
    function render(page: &[Page, R]): String is
        var out: StringBuilder := makeStringBuilder();
        @template("page.jinja", page, out);
        return finalize(out);
    end;

    function main(): ExitCode is
        let page: Page := Page(lang => fromLiteral("de"), user => fromLiteral("Ada"), count => 2);
        let text: String := render(&page);
        destroyString(text);
        let { lang: String, user: String, count: Int32 } := page;
        destroyString(lang);
        destroyString(user);
        return ExitSuccess();
    end;
end module body.
```

Daneben, `page.jinja`:

```jinja file page.jinja
{% catalog messages %}<script>var t = {{ _("Greeting", name=user) }};</script>
```

Die richtige Form:

```hilde
import Standard.String (
    String,
    fromLiteral,
    destroyString
);
import Standard.StringBuilder (
    StringBuilder,
    makeStringBuilder,
    finalize
);
import Standard.Template (
    Render
);
import Standard.I18n (
    Message,
    Text,
    Plural,
    Language,
    Catalog,
    englishPlural,
    germanPlural
);

module body Example is
    union Key: Free is
        case Greeting;
        case Items;
    end;

    function english(key: Key): Message is
        case key of
            when Greeting do
                return Text(text => "Hello, {name}!");
            when Items do
                return Plural(one => "{count} item", other => "{count} items");
        end case;
    end;

    function german(key: Key): Message is
        case key of
            when Greeting do
                return Text(text => "Hallo, {name}!");
            when Items do
                return Plural(one => "{count} Teil", other => "{count} Teile");
        end case;
    end;

    function others(i: Index): Option[Language[Key]] is
        if i = 0 then
            return Some(value => Language(code => "de", texts => german, plural => germanPlural));
        end if;
        return None();
    end;

    function messages(): Catalog[Key] is
        return Catalog(default => Language(code => "en", texts => english, plural => englishPlural), others => others);
    end;

    record Page: Linear is
        lang: String;
        user: String;
        count: Int32;
    end;

    generic [R: Region]
    function render(page: &[Page, R]): String is
        var out: StringBuilder := makeStringBuilder();
        @template("page.jinja", page, out);
        return finalize(out);
    end;

    function main(): ExitCode is
        let page: Page := Page(lang => fromLiteral("de"), user => fromLiteral("Ada"), count => 2);
        let text: String := render(&page);
        destroyString(text);
        let { lang: String, user: String, count: Int32 } := page;
        destroyString(lang);
        destroyString(user);
        return ExitSuccess();
    end;
end module body.
```

Daneben, `page.jinja`:

```jinja file page.jinja
{% catalog messages %}<p>{{ _("Greeting", name=user) }}</p>
```

### H7124

Meldung:

```text
Generic Error
@template: a translation stands alone in {{ }} or a {% trans %} block, without filters and without ~
```

Eine Übersetzung steht allein in {{ }} oder als {% trans %}-Block; ein Filter oder ein ~ würde einen Text ändern, der nur im Katalog für jede Sprache derselbe ist.

Dieses Modul scheitert mit H7124:

```hilde fails H7124
import Standard.String (
    String,
    fromLiteral,
    destroyString
);
import Standard.StringBuilder (
    StringBuilder,
    makeStringBuilder,
    finalize
);
import Standard.Template (
    Render
);
import Standard.I18n (
    Message,
    Text,
    Plural,
    Language,
    Catalog,
    englishPlural,
    germanPlural
);

module body Example is
    union Key: Free is
        case Greeting;
        case Items;
    end;

    function english(key: Key): Message is
        case key of
            when Greeting do
                return Text(text => "Hello, {name}!");
            when Items do
                return Plural(one => "{count} item", other => "{count} items");
        end case;
    end;

    function german(key: Key): Message is
        case key of
            when Greeting do
                return Text(text => "Hallo, {name}!");
            when Items do
                return Plural(one => "{count} Teil", other => "{count} Teile");
        end case;
    end;

    function others(i: Index): Option[Language[Key]] is
        if i = 0 then
            return Some(value => Language(code => "de", texts => german, plural => germanPlural));
        end if;
        return None();
    end;

    function messages(): Catalog[Key] is
        return Catalog(default => Language(code => "en", texts => english, plural => englishPlural), others => others);
    end;

    record Page: Linear is
        lang: String;
        user: String;
        count: Int32;
    end;

    generic [R: Region]
    function render(page: &[Page, R]): String is
        var out: StringBuilder := makeStringBuilder();
        @template("page.jinja", page, out);
        return finalize(out);
    end;

    function main(): ExitCode is
        let page: Page := Page(lang => fromLiteral("de"), user => fromLiteral("Ada"), count => 2);
        let text: String := render(&page);
        destroyString(text);
        let { lang: String, user: String, count: Int32 } := page;
        destroyString(lang);
        destroyString(user);
        return ExitSuccess();
    end;
end module body.
```

Daneben, `page.jinja`:

```jinja file page.jinja
{% catalog messages %}<p>{{ _("Greeting", name=user)|upper }}</p>
```

Die richtige Form:

```hilde
import Standard.String (
    String,
    fromLiteral,
    destroyString
);
import Standard.StringBuilder (
    StringBuilder,
    makeStringBuilder,
    finalize
);
import Standard.Template (
    Render
);
import Standard.I18n (
    Message,
    Text,
    Plural,
    Language,
    Catalog,
    englishPlural,
    germanPlural
);

module body Example is
    union Key: Free is
        case Greeting;
        case Items;
    end;

    function english(key: Key): Message is
        case key of
            when Greeting do
                return Text(text => "Hello, {name}!");
            when Items do
                return Plural(one => "{count} item", other => "{count} items");
        end case;
    end;

    function german(key: Key): Message is
        case key of
            when Greeting do
                return Text(text => "Hallo, {name}!");
            when Items do
                return Plural(one => "{count} Teil", other => "{count} Teile");
        end case;
    end;

    function others(i: Index): Option[Language[Key]] is
        if i = 0 then
            return Some(value => Language(code => "de", texts => german, plural => germanPlural));
        end if;
        return None();
    end;

    function messages(): Catalog[Key] is
        return Catalog(default => Language(code => "en", texts => english, plural => englishPlural), others => others);
    end;

    record Page: Linear is
        lang: String;
        user: String;
        count: Int32;
    end;

    generic [R: Region]
    function render(page: &[Page, R]): String is
        var out: StringBuilder := makeStringBuilder();
        @template("page.jinja", page, out);
        return finalize(out);
    end;

    function main(): ExitCode is
        let page: Page := Page(lang => fromLiteral("de"), user => fromLiteral("Ada"), count => 2);
        let text: String := render(&page);
        destroyString(text);
        let { lang: String, user: String, count: Int32 } := page;
        destroyString(lang);
        destroyString(user);
        return ExitSuccess();
    end;
end module body.
```

Daneben, `page.jinja`:

```jinja file page.jinja
{% catalog messages %}<p>{{ _("Greeting", name=user) }}</p>
```

### H7125

Meldung:

```text
Generic Error
@template: after the key, _( ) takes its arguments as name=value
```

Nach dem Schlüssel nimmt _( ) seine Argumente als name=Wert: der Name ist der Platzhalter {name} des Textes, den er füllt.

Dieses Modul scheitert mit H7125:

```hilde fails H7125
import Standard.String (
    String,
    fromLiteral,
    destroyString
);
import Standard.StringBuilder (
    StringBuilder,
    makeStringBuilder,
    finalize
);
import Standard.Template (
    Render
);
import Standard.I18n (
    Message,
    Text,
    Plural,
    Language,
    Catalog,
    englishPlural,
    germanPlural
);

module body Example is
    union Key: Free is
        case Greeting;
        case Items;
    end;

    function english(key: Key): Message is
        case key of
            when Greeting do
                return Text(text => "Hello, {name}!");
            when Items do
                return Plural(one => "{count} item", other => "{count} items");
        end case;
    end;

    function german(key: Key): Message is
        case key of
            when Greeting do
                return Text(text => "Hallo, {name}!");
            when Items do
                return Plural(one => "{count} Teil", other => "{count} Teile");
        end case;
    end;

    function others(i: Index): Option[Language[Key]] is
        if i = 0 then
            return Some(value => Language(code => "de", texts => german, plural => germanPlural));
        end if;
        return None();
    end;

    function messages(): Catalog[Key] is
        return Catalog(default => Language(code => "en", texts => english, plural => englishPlural), others => others);
    end;

    record Page: Linear is
        lang: String;
        user: String;
        count: Int32;
    end;

    generic [R: Region]
    function render(page: &[Page, R]): String is
        var out: StringBuilder := makeStringBuilder();
        @template("page.jinja", page, out);
        return finalize(out);
    end;

    function main(): ExitCode is
        let page: Page := Page(lang => fromLiteral("de"), user => fromLiteral("Ada"), count => 2);
        let text: String := render(&page);
        destroyString(text);
        let { lang: String, user: String, count: Int32 } := page;
        destroyString(lang);
        destroyString(user);
        return ExitSuccess();
    end;
end module body.
```

Daneben, `page.jinja`:

```jinja file page.jinja
{% catalog messages %}<p>{{ _("Greeting", user) }}</p>
```

Die richtige Form:

```hilde
import Standard.String (
    String,
    fromLiteral,
    destroyString
);
import Standard.StringBuilder (
    StringBuilder,
    makeStringBuilder,
    finalize
);
import Standard.Template (
    Render
);
import Standard.I18n (
    Message,
    Text,
    Plural,
    Language,
    Catalog,
    englishPlural,
    germanPlural
);

module body Example is
    union Key: Free is
        case Greeting;
        case Items;
    end;

    function english(key: Key): Message is
        case key of
            when Greeting do
                return Text(text => "Hello, {name}!");
            when Items do
                return Plural(one => "{count} item", other => "{count} items");
        end case;
    end;

    function german(key: Key): Message is
        case key of
            when Greeting do
                return Text(text => "Hallo, {name}!");
            when Items do
                return Plural(one => "{count} Teil", other => "{count} Teile");
        end case;
    end;

    function others(i: Index): Option[Language[Key]] is
        if i = 0 then
            return Some(value => Language(code => "de", texts => german, plural => germanPlural));
        end if;
        return None();
    end;

    function messages(): Catalog[Key] is
        return Catalog(default => Language(code => "en", texts => english, plural => englishPlural), others => others);
    end;

    record Page: Linear is
        lang: String;
        user: String;
        count: Int32;
    end;

    generic [R: Region]
    function render(page: &[Page, R]): String is
        var out: StringBuilder := makeStringBuilder();
        @template("page.jinja", page, out);
        return finalize(out);
    end;

    function main(): ExitCode is
        let page: Page := Page(lang => fromLiteral("de"), user => fromLiteral("Ada"), count => 2);
        let text: String := render(&page);
        destroyString(text);
        let { lang: String, user: String, count: Int32 } := page;
        destroyString(lang);
        destroyString(user);
        return ExitSuccess();
    end;
end module body.
```

Daneben, `page.jinja`:

```jinja file page.jinja
{% catalog messages %}<p>{{ _("Greeting", name=user) }}</p>
```

### H7126

Meldung:

```text
Generic Error
@template: {% trans %} is given name twice
```

Jedes Argument im Tag von {% trans %} hat einen eigenen Namen.

Dieses Modul scheitert mit H7126:

```hilde fails H7126
import Standard.String (
    String,
    fromLiteral,
    destroyString
);
import Standard.StringBuilder (
    StringBuilder,
    makeStringBuilder,
    finalize
);
import Standard.Template (
    Render
);
import Standard.I18n (
    Message,
    Text,
    Plural,
    Language,
    Catalog,
    englishPlural,
    germanPlural
);

module body Example is
    union Key: Free is
        case Greeting;
        case Items;
    end;

    function english(key: Key): Message is
        case key of
            when Greeting do
                return Text(text => "Hello, {name}!");
            when Items do
                return Plural(one => "{count} item", other => "{count} items");
        end case;
    end;

    function german(key: Key): Message is
        case key of
            when Greeting do
                return Text(text => "Hallo, {name}!");
            when Items do
                return Plural(one => "{count} Teil", other => "{count} Teile");
        end case;
    end;

    function others(i: Index): Option[Language[Key]] is
        if i = 0 then
            return Some(value => Language(code => "de", texts => german, plural => germanPlural));
        end if;
        return None();
    end;

    function messages(): Catalog[Key] is
        return Catalog(default => Language(code => "en", texts => english, plural => englishPlural), others => others);
    end;

    record Page: Linear is
        lang: String;
        user: String;
        count: Int32;
    end;

    generic [R: Region]
    function render(page: &[Page, R]): String is
        var out: StringBuilder := makeStringBuilder();
        @template("page.jinja", page, out);
        return finalize(out);
    end;

    function main(): ExitCode is
        let page: Page := Page(lang => fromLiteral("de"), user => fromLiteral("Ada"), count => 2);
        let text: String := render(&page);
        destroyString(text);
        let { lang: String, user: String, count: Int32 } := page;
        destroyString(lang);
        destroyString(user);
        return ExitSuccess();
    end;
end module body.
```

Daneben, `page.jinja`:

```jinja file page.jinja
{% catalog messages %}<p>{% trans name=user, name=user %}Greeting{% endtrans %}</p>
```

Die richtige Form:

```hilde
import Standard.String (
    String,
    fromLiteral,
    destroyString
);
import Standard.StringBuilder (
    StringBuilder,
    makeStringBuilder,
    finalize
);
import Standard.Template (
    Render
);
import Standard.I18n (
    Message,
    Text,
    Plural,
    Language,
    Catalog,
    englishPlural,
    germanPlural
);

module body Example is
    union Key: Free is
        case Greeting;
        case Items;
    end;

    function english(key: Key): Message is
        case key of
            when Greeting do
                return Text(text => "Hello, {name}!");
            when Items do
                return Plural(one => "{count} item", other => "{count} items");
        end case;
    end;

    function german(key: Key): Message is
        case key of
            when Greeting do
                return Text(text => "Hallo, {name}!");
            when Items do
                return Plural(one => "{count} Teil", other => "{count} Teile");
        end case;
    end;

    function others(i: Index): Option[Language[Key]] is
        if i = 0 then
            return Some(value => Language(code => "de", texts => german, plural => germanPlural));
        end if;
        return None();
    end;

    function messages(): Catalog[Key] is
        return Catalog(default => Language(code => "en", texts => english, plural => englishPlural), others => others);
    end;

    record Page: Linear is
        lang: String;
        user: String;
        count: Int32;
    end;

    generic [R: Region]
    function render(page: &[Page, R]): String is
        var out: StringBuilder := makeStringBuilder();
        @template("page.jinja", page, out);
        return finalize(out);
    end;

    function main(): ExitCode is
        let page: Page := Page(lang => fromLiteral("de"), user => fromLiteral("Ada"), count => 2);
        let text: String := render(&page);
        destroyString(text);
        let { lang: String, user: String, count: Int32 } := page;
        destroyString(lang);
        destroyString(user);
        return ExitSuccess();
    end;
end module body.
```

Daneben, `page.jinja`:

```jinja file page.jinja
{% catalog messages %}<p>{% trans name=user %}Greeting{% endtrans %}</p>
```

### H7127

Meldung:

```text
Generic Error
@template: a module whose template translates imports Standard.I18n -- e.g. import Standard.I18n (Catalog); -- because the generated code calls it
```

Der Code, zu dem eine Übersetzung wird, ruft Standard.I18n auf, deshalb importiert das Modul mit dem @template es, so wie es Standard.Template importiert.

Dieses Modul scheitert mit H7127:

```hilde fails H7127
import Standard.String (
    String,
    fromLiteral,
    destroyString
);
import Standard.StringBuilder (
    StringBuilder,
    makeStringBuilder,
    finalize
);
import Standard.Template (
    Render
);

module body Example is
    union Key: Free is
        case Greeting;
        case Items;
    end;

    function english(key: Key): Message is
        case key of
            when Greeting do
                return Text(text => "Hello, {name}!");
            when Items do
                return Plural(one => "{count} item", other => "{count} items");
        end case;
    end;

    function german(key: Key): Message is
        case key of
            when Greeting do
                return Text(text => "Hallo, {name}!");
            when Items do
                return Plural(one => "{count} Teil", other => "{count} Teile");
        end case;
    end;

    function others(i: Index): Option[Language[Key]] is
        if i = 0 then
            return Some(value => Language(code => "de", texts => german, plural => germanPlural));
        end if;
        return None();
    end;

    function messages(): Catalog[Key] is
        return Catalog(default => Language(code => "en", texts => english, plural => englishPlural), others => others);
    end;

    record Page: Linear is
        lang: String;
        user: String;
        count: Int32;
    end;

    generic [R: Region]
    function render(page: &[Page, R]): String is
        var out: StringBuilder := makeStringBuilder();
        @template("page.jinja", page, out);
        return finalize(out);
    end;

    function main(): ExitCode is
        let page: Page := Page(lang => fromLiteral("de"), user => fromLiteral("Ada"), count => 2);
        let text: String := render(&page);
        destroyString(text);
        let { lang: String, user: String, count: Int32 } := page;
        destroyString(lang);
        destroyString(user);
        return ExitSuccess();
    end;
end module body.
```

Daneben, `page.jinja`:

```jinja file page.jinja
{% catalog messages %}<p>{{ _("Greeting", name=user) }}</p>
```

Die richtige Form:

```hilde
import Standard.String (
    String,
    fromLiteral,
    destroyString
);
import Standard.StringBuilder (
    StringBuilder,
    makeStringBuilder,
    finalize
);
import Standard.Template (
    Render
);
import Standard.I18n (
    Message,
    Text,
    Plural,
    Language,
    Catalog,
    englishPlural,
    germanPlural
);

module body Example is
    union Key: Free is
        case Greeting;
        case Items;
    end;

    function english(key: Key): Message is
        case key of
            when Greeting do
                return Text(text => "Hello, {name}!");
            when Items do
                return Plural(one => "{count} item", other => "{count} items");
        end case;
    end;

    function german(key: Key): Message is
        case key of
            when Greeting do
                return Text(text => "Hallo, {name}!");
            when Items do
                return Plural(one => "{count} Teil", other => "{count} Teile");
        end case;
    end;

    function others(i: Index): Option[Language[Key]] is
        if i = 0 then
            return Some(value => Language(code => "de", texts => german, plural => germanPlural));
        end if;
        return None();
    end;

    function messages(): Catalog[Key] is
        return Catalog(default => Language(code => "en", texts => english, plural => englishPlural), others => others);
    end;

    record Page: Linear is
        lang: String;
        user: String;
        count: Int32;
    end;

    generic [R: Region]
    function render(page: &[Page, R]): String is
        var out: StringBuilder := makeStringBuilder();
        @template("page.jinja", page, out);
        return finalize(out);
    end;

    function main(): ExitCode is
        let page: Page := Page(lang => fromLiteral("de"), user => fromLiteral("Ada"), count => 2);
        let text: String := render(&page);
        destroyString(text);
        let { lang: String, user: String, count: Int32 } := page;
        destroyString(lang);
        destroyString(user);
        return ExitSuccess();
    end;
end module body.
```

Daneben, `page.jinja`:

```jinja file page.jinja
{% catalog messages %}<p>{{ _("Greeting", name=user) }}</p>
```

### H7128

Meldung:

```text
Generic Error
@template: {% catalog %} after {% extends %} stands in the template that is extended or in a block, where the text it serves is
```

In einem Template, das ein anderes erweitert, bleiben nur die Blöcke. {% catalog %} steht im erweiterten Template, vor den Blöcken, für die es gilt.

Dieses Modul scheitert mit H7128:

```hilde fails H7128
import Standard.String (
    String,
    fromLiteral,
    destroyString
);
import Standard.StringBuilder (
    StringBuilder,
    makeStringBuilder,
    finalize
);
import Standard.Template (
    Render
);
import Standard.I18n (
    Message,
    Text,
    Plural,
    Language,
    Catalog,
    englishPlural,
    germanPlural
);

module body Example is
    union Key: Free is
        case Greeting;
        case Items;
    end;

    function english(key: Key): Message is
        case key of
            when Greeting do
                return Text(text => "Hello, {name}!");
            when Items do
                return Plural(one => "{count} item", other => "{count} items");
        end case;
    end;

    function german(key: Key): Message is
        case key of
            when Greeting do
                return Text(text => "Hallo, {name}!");
            when Items do
                return Plural(one => "{count} Teil", other => "{count} Teile");
        end case;
    end;

    function others(i: Index): Option[Language[Key]] is
        if i = 0 then
            return Some(value => Language(code => "de", texts => german, plural => germanPlural));
        end if;
        return None();
    end;

    function messages(): Catalog[Key] is
        return Catalog(default => Language(code => "en", texts => english, plural => englishPlural), others => others);
    end;

    record Page: Linear is
        lang: String;
        user: String;
        count: Int32;
    end;

    generic [R: Region]
    function render(page: &[Page, R]): String is
        var out: StringBuilder := makeStringBuilder();
        @template("page.jinja", page, out);
        return finalize(out);
    end;

    function main(): ExitCode is
        let page: Page := Page(lang => fromLiteral("de"), user => fromLiteral("Ada"), count => 2);
        let text: String := render(&page);
        destroyString(text);
        let { lang: String, user: String, count: Int32 } := page;
        destroyString(lang);
        destroyString(user);
        return ExitSuccess();
    end;
end module body.
```

Daneben, `base.jinja`:

```jinja file base.jinja
<main>{% block main %}{% endblock %}</main>
```

Daneben, `page.jinja`:

```jinja file page.jinja
{% extends "base.jinja" %}{% catalog messages %}{% block main %}{{ _("Greeting", name=user) }}{% endblock %}
```

Die richtige Form:

```hilde
import Standard.String (
    String,
    fromLiteral,
    destroyString
);
import Standard.StringBuilder (
    StringBuilder,
    makeStringBuilder,
    finalize
);
import Standard.Template (
    Render
);
import Standard.I18n (
    Message,
    Text,
    Plural,
    Language,
    Catalog,
    englishPlural,
    germanPlural
);

module body Example is
    union Key: Free is
        case Greeting;
        case Items;
    end;

    function english(key: Key): Message is
        case key of
            when Greeting do
                return Text(text => "Hello, {name}!");
            when Items do
                return Plural(one => "{count} item", other => "{count} items");
        end case;
    end;

    function german(key: Key): Message is
        case key of
            when Greeting do
                return Text(text => "Hallo, {name}!");
            when Items do
                return Plural(one => "{count} Teil", other => "{count} Teile");
        end case;
    end;

    function others(i: Index): Option[Language[Key]] is
        if i = 0 then
            return Some(value => Language(code => "de", texts => german, plural => germanPlural));
        end if;
        return None();
    end;

    function messages(): Catalog[Key] is
        return Catalog(default => Language(code => "en", texts => english, plural => englishPlural), others => others);
    end;

    record Page: Linear is
        lang: String;
        user: String;
        count: Int32;
    end;

    generic [R: Region]
    function render(page: &[Page, R]): String is
        var out: StringBuilder := makeStringBuilder();
        @template("page.jinja", page, out);
        return finalize(out);
    end;

    function main(): ExitCode is
        let page: Page := Page(lang => fromLiteral("de"), user => fromLiteral("Ada"), count => 2);
        let text: String := render(&page);
        destroyString(text);
        let { lang: String, user: String, count: Int32 } := page;
        destroyString(lang);
        destroyString(user);
        return ExitSuccess();
    end;
end module body.
```

Daneben, `base.jinja`:

```jinja file base.jinja
{% catalog messages %}<main>{% block main %}{% endblock %}</main>
```

Daneben, `page.jinja`:

```jinja file page.jinja
{% extends "base.jinja" %}{% block main %}{{ _("Greeting", name=user) }}{% endblock %}
```

## 8. SQL

Jedes Beispiel dieses Kapitels öffnet eine Datenbank im Speicher, wendet mit
@migrations die Migrationen neben dem Modul an und führt in der Funktion run
eine Anweisung aus, mit @query oder @execute. Das scheiternde Beispiel und
die richtige Form unterscheiden sich in dieser Anweisung oder in den
Migrationsdateien.

Eine Abfrage wird beim Kompilieren geprüft, gegen das Schema, das die
Migrationen aufbauen. Die Meldung eines Fehlers in einer Abfrage nennt Zeile
und Spalte im SQL; die Meldung eines Fehlers in einer Migration beginnt mit
migration und nennt die Stelle in der Datei.

Neben jedem Modul dieses Kapitels liegt die folgende Datei, außer das
Beispiel zeigt eigene Dateien; dann hat es nur diese.

`migrations/1-schema.sql`:

```sql file migrations/1-schema.sql
CREATE TABLE users (
    id INTEGER PRIMARY KEY,
    name TEXT NOT NULL,
    age INTEGER NOT NULL DEFAULT 0,
    email TEXT,
    score REAL
) STRICT;

CREATE TABLE notes (
    id INTEGER PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users (id),
    body BLOB NOT NULL
) STRICT;
```

### H8001

Meldung:

```text
Generic Error
@query: a string is not closed (line 1, column 37 of the SQL)
```

Ein String oder ein in Anführungszeichen gesetzter Name im SQL wird nicht
geschlossen.

Dieses Modul scheitert mit H8001:

```hilde fails H8001
import Standard.Sqlite (Connection, Writing, SqlError, describe, openWriter, closeDatabase, migrate);

module body Example is
    record Person[R: Region]: Free is
        name: Span[Nat8, R];
    end;

    generic [R: Region]
    function run(db: &![Connection[Writing], R]): Unit is
        @query(&~db, "SELECT name FROM users WHERE name = 'ann") for row: Person[Q] do
            printLn(row.name);
        else error do
            printLn(describe(error));
        end for;
        return nil;
    end;

    function main(): ExitCode is
        case openWriter(":memory:") of
            when Left(left as error: SqlError) do
                printLn(describe(error));
                return ExitFailure();
            when Right(right as opened: Connection[Writing]) do
                var db: Connection[Writing] := opened;
                case migrate(&!db, @migrations) of
                    when Left(left as error: SqlError) do
                        printLn(describe(error));
                    when Right(right as applied: Index) do
                        run(&!db);
                end case;
                closeDatabase(db);
                return ExitSuccess();
        end case;
    end;
end module body.
```

Die richtige Form:

```hilde
import Standard.Sqlite (Connection, Writing, SqlError, describe, openWriter, closeDatabase, migrate);

module body Example is
    record Person[R: Region]: Free is
        name: Span[Nat8, R];
    end;

    generic [R: Region]
    function run(db: &![Connection[Writing], R]): Unit is
        @query(&~db, "SELECT name FROM users WHERE name = 'ann'") for row: Person[Q] do
            printLn(row.name);
        else error do
            printLn(describe(error));
        end for;
        return nil;
    end;

    function main(): ExitCode is
        case openWriter(":memory:") of
            when Left(left as error: SqlError) do
                printLn(describe(error));
                return ExitFailure();
            when Right(right as opened: Connection[Writing]) do
                var db: Connection[Writing] := opened;
                case migrate(&!db, @migrations) of
                    when Left(left as error: SqlError) do
                        printLn(describe(error));
                    when Right(right as applied: Index) do
                        run(&!db);
                end case;
                closeDatabase(db);
                return ExitSuccess();
        end case;
    end;
end module body.
```

### H8002

Meldung:

```text
Generic Error
@query: a comment is not closed (line 1, column 24 of the SQL)
```

Ein Kommentar `/*` im SQL wird nicht mit `*/` geschlossen.

Dieses Modul scheitert mit H8002:

```hilde fails H8002
import Standard.Sqlite (Connection, Writing, SqlError, describe, openWriter, closeDatabase, migrate);

module body Example is
    record Person[R: Region]: Free is
        name: Span[Nat8, R];
    end;

    generic [R: Region]
    function run(db: &![Connection[Writing], R]): Unit is
        @query(&~db, "SELECT name FROM users /* everyone") for row: Person[Q] do
            printLn(row.name);
        else error do
            printLn(describe(error));
        end for;
        return nil;
    end;

    function main(): ExitCode is
        case openWriter(":memory:") of
            when Left(left as error: SqlError) do
                printLn(describe(error));
                return ExitFailure();
            when Right(right as opened: Connection[Writing]) do
                var db: Connection[Writing] := opened;
                case migrate(&!db, @migrations) of
                    when Left(left as error: SqlError) do
                        printLn(describe(error));
                    when Right(right as applied: Index) do
                        run(&!db);
                end case;
                closeDatabase(db);
                return ExitSuccess();
        end case;
    end;
end module body.
```

Die richtige Form:

```hilde
import Standard.Sqlite (Connection, Writing, SqlError, describe, openWriter, closeDatabase, migrate);

module body Example is
    record Person[R: Region]: Free is
        name: Span[Nat8, R];
    end;

    generic [R: Region]
    function run(db: &![Connection[Writing], R]): Unit is
        @query(&~db, "SELECT name FROM users /* everyone */") for row: Person[Q] do
            printLn(row.name);
        else error do
            printLn(describe(error));
        end for;
        return nil;
    end;

    function main(): ExitCode is
        case openWriter(":memory:") of
            when Left(left as error: SqlError) do
                printLn(describe(error));
                return ExitFailure();
            when Right(right as opened: Connection[Writing]) do
                var db: Connection[Writing] := opened;
                case migrate(&!db, @migrations) of
                    when Left(left as error: SqlError) do
                        printLn(describe(error));
                    when Right(right as applied: Index) do
                        run(&!db);
                end case;
                closeDatabase(db);
                return ExitSuccess();
        end case;
    end;
end module body.
```

### H8003

Meldung:

```text
Generic Error
@execute: a blob literal is an even number of hexadecimal digits (line 1, column 32 of the SQL)
```

Ein Blob-Literal x'...' enthält keine gerade Anzahl hexadezimaler Ziffern.

Dieses Modul scheitert mit H8003:

```hilde fails H8003
import Standard.Sqlite (Connection, Writing, SqlError, describe, openWriter, closeDatabase, migrate);

module body Example is
    generic [R: Region]
    function run(db: &![Connection[Writing], R]): Unit is
        let result: Either[SqlError, Nat64] := @execute(&~db, "DELETE FROM notes WHERE body = x'ABC'");
        case result of
            when Left(left as error: SqlError) do
                printLn(describe(error));
            when Right(right as changed: Nat64) do
                printLn(changed);
        end case;
        return nil;
    end;

    function main(): ExitCode is
        case openWriter(":memory:") of
            when Left(left as error: SqlError) do
                printLn(describe(error));
                return ExitFailure();
            when Right(right as opened: Connection[Writing]) do
                var db: Connection[Writing] := opened;
                case migrate(&!db, @migrations) of
                    when Left(left as error: SqlError) do
                        printLn(describe(error));
                    when Right(right as applied: Index) do
                        run(&!db);
                end case;
                closeDatabase(db);
                return ExitSuccess();
        end case;
    end;
end module body.
```

Die richtige Form:

```hilde
import Standard.Sqlite (Connection, Writing, SqlError, describe, openWriter, closeDatabase, migrate);

module body Example is
    generic [R: Region]
    function run(db: &![Connection[Writing], R]): Unit is
        let result: Either[SqlError, Nat64] := @execute(&~db, "DELETE FROM notes WHERE body = x'0ABC'");
        case result of
            when Left(left as error: SqlError) do
                printLn(describe(error));
            when Right(right as changed: Nat64) do
                printLn(changed);
        end case;
        return nil;
    end;

    function main(): ExitCode is
        case openWriter(":memory:") of
            when Left(left as error: SqlError) do
                printLn(describe(error));
                return ExitFailure();
            when Right(right as opened: Connection[Writing]) do
                var db: Connection[Writing] := opened;
                case migrate(&!db, @migrations) of
                    when Left(left as error: SqlError) do
                        printLn(describe(error));
                    when Right(right as applied: Index) do
                        run(&!db);
                end case;
                closeDatabase(db);
                return ExitSuccess();
        end case;
    end;
end module body.
```

### H8004

Meldung:

```text
Generic Error
@query: a number runs into a name (line 1, column 36 of the SQL)
```

Eine Zahl geht ohne Trennung in einen Namen über, wie in 18years.

Dieses Modul scheitert mit H8004:

```hilde fails H8004
import Standard.Sqlite (Connection, Writing, SqlError, describe, openWriter, closeDatabase, migrate);

module body Example is
    record Person[R: Region]: Free is
        name: Span[Nat8, R];
    end;

    generic [R: Region]
    function run(db: &![Connection[Writing], R]): Unit is
        @query(&~db, "SELECT name FROM users WHERE age > 18years") for row: Person[Q] do
            printLn(row.name);
        else error do
            printLn(describe(error));
        end for;
        return nil;
    end;

    function main(): ExitCode is
        case openWriter(":memory:") of
            when Left(left as error: SqlError) do
                printLn(describe(error));
                return ExitFailure();
            when Right(right as opened: Connection[Writing]) do
                var db: Connection[Writing] := opened;
                case migrate(&!db, @migrations) of
                    when Left(left as error: SqlError) do
                        printLn(describe(error));
                    when Right(right as applied: Index) do
                        run(&!db);
                end case;
                closeDatabase(db);
                return ExitSuccess();
        end case;
    end;
end module body.
```

Die richtige Form:

```hilde
import Standard.Sqlite (Connection, Writing, SqlError, describe, openWriter, closeDatabase, migrate);

module body Example is
    record Person[R: Region]: Free is
        name: Span[Nat8, R];
    end;

    generic [R: Region]
    function run(db: &![Connection[Writing], R]): Unit is
        @query(&~db, "SELECT name FROM users WHERE age > 18") for row: Person[Q] do
            printLn(row.name);
        else error do
            printLn(describe(error));
        end for;
        return nil;
    end;

    function main(): ExitCode is
        case openWriter(":memory:") of
            when Left(left as error: SqlError) do
                printLn(describe(error));
                return ExitFailure();
            when Right(right as opened: Connection[Writing]) do
                var db: Connection[Writing] := opened;
                case migrate(&!db, @migrations) of
                    when Left(left as error: SqlError) do
                        printLn(describe(error));
                    when Right(right as applied: Index) do
                        run(&!db);
                end case;
                closeDatabase(db);
                return ExitSuccess();
        end case;
    end;
end module body.
```

### H8005

Meldung:

```text
Generic Error
@query: a name is quoted with double quotes here, not with ` or [ ] (line 1, column 8 of the SQL)
```

Ein Name steht in Backticks oder eckigen Klammern. Man setzt ihn in doppelte
Anführungszeichen.

Dieses Modul scheitert mit H8005:

```hilde fails H8005
import Standard.Sqlite (Connection, Writing, SqlError, describe, openWriter, closeDatabase, migrate);

module body Example is
    record Person[R: Region]: Free is
        name: Span[Nat8, R];
    end;

    generic [R: Region]
    function run(db: &![Connection[Writing], R]): Unit is
        @query(&~db, "SELECT [name] FROM users") for row: Person[Q] do
            printLn(row.name);
        else error do
            printLn(describe(error));
        end for;
        return nil;
    end;

    function main(): ExitCode is
        case openWriter(":memory:") of
            when Left(left as error: SqlError) do
                printLn(describe(error));
                return ExitFailure();
            when Right(right as opened: Connection[Writing]) do
                var db: Connection[Writing] := opened;
                case migrate(&!db, @migrations) of
                    when Left(left as error: SqlError) do
                        printLn(describe(error));
                    when Right(right as applied: Index) do
                        run(&!db);
                end case;
                closeDatabase(db);
                return ExitSuccess();
        end case;
    end;
end module body.
```

Die richtige Form:

```hilde
import Standard.Sqlite (Connection, Writing, SqlError, describe, openWriter, closeDatabase, migrate);

module body Example is
    record Person[R: Region]: Free is
        name: Span[Nat8, R];
    end;

    generic [R: Region]
    function run(db: &![Connection[Writing], R]): Unit is
        @query(&~db, "SELECT \"name\" FROM users") for row: Person[Q] do
            printLn(row.name);
        else error do
            printLn(describe(error));
        end for;
        return nil;
    end;

    function main(): ExitCode is
        case openWriter(":memory:") of
            when Left(left as error: SqlError) do
                printLn(describe(error));
                return ExitFailure();
            when Right(right as opened: Connection[Writing]) do
                var db: Connection[Writing] := opened;
                case migrate(&!db, @migrations) of
                    when Left(left as error: SqlError) do
                        printLn(describe(error));
                    when Right(right as applied: Index) do
                        run(&!db);
                end case;
                closeDatabase(db);
                return ExitSuccess();
        end case;
    end;
end module body.
```

### H8006

Meldung:

```text
Generic Error
@query: a numbered parameter (?NNN) is not accepted: write ? and give the values in order (line 1, column 36 of the SQL)
```

Im SQL steht ein nummerierter Parameter wie ?1. Man schreibt ? und gibt die
Werte der Reihe nach an.

Dieses Modul scheitert mit H8006:

```hilde fails H8006
import Standard.Sqlite (Connection, Writing, SqlError, describe, openWriter, closeDatabase, migrate);

module body Example is
    record Person[R: Region]: Free is
        name: Span[Nat8, R];
    end;

    generic [R: Region]
    function run(db: &![Connection[Writing], R]): Unit is
        @query(&~db, "SELECT name FROM users WHERE age > ?1", 18) for row: Person[Q] do
            printLn(row.name);
        else error do
            printLn(describe(error));
        end for;
        return nil;
    end;

    function main(): ExitCode is
        case openWriter(":memory:") of
            when Left(left as error: SqlError) do
                printLn(describe(error));
                return ExitFailure();
            when Right(right as opened: Connection[Writing]) do
                var db: Connection[Writing] := opened;
                case migrate(&!db, @migrations) of
                    when Left(left as error: SqlError) do
                        printLn(describe(error));
                    when Right(right as applied: Index) do
                        run(&!db);
                end case;
                closeDatabase(db);
                return ExitSuccess();
        end case;
    end;
end module body.
```

Die richtige Form:

```hilde
import Standard.Sqlite (Connection, Writing, SqlError, describe, openWriter, closeDatabase, migrate);

module body Example is
    record Person[R: Region]: Free is
        name: Span[Nat8, R];
    end;

    generic [R: Region]
    function run(db: &![Connection[Writing], R]): Unit is
        @query(&~db, "SELECT name FROM users WHERE age > ?", 18) for row: Person[Q] do
            printLn(row.name);
        else error do
            printLn(describe(error));
        end for;
        return nil;
    end;

    function main(): ExitCode is
        case openWriter(":memory:") of
            when Left(left as error: SqlError) do
                printLn(describe(error));
                return ExitFailure();
            when Right(right as opened: Connection[Writing]) do
                var db: Connection[Writing] := opened;
                case migrate(&!db, @migrations) of
                    when Left(left as error: SqlError) do
                        printLn(describe(error));
                    when Right(right as applied: Index) do
                        run(&!db);
                end case;
                closeDatabase(db);
                return ExitSuccess();
        end case;
    end;
end module body.
```

### H8007

Meldung:

```text
Generic Error
@query: a named parameter is not accepted: write ? and give the values in order (line 1, column 36 of the SQL)
```

Im SQL steht ein benannter Parameter wie :age. Man schreibt ? und gibt die
Werte der Reihe nach an.

Dieses Modul scheitert mit H8007:

```hilde fails H8007
import Standard.Sqlite (Connection, Writing, SqlError, describe, openWriter, closeDatabase, migrate);

module body Example is
    record Person[R: Region]: Free is
        name: Span[Nat8, R];
    end;

    generic [R: Region]
    function run(db: &![Connection[Writing], R]): Unit is
        @query(&~db, "SELECT name FROM users WHERE age > :age", 18) for row: Person[Q] do
            printLn(row.name);
        else error do
            printLn(describe(error));
        end for;
        return nil;
    end;

    function main(): ExitCode is
        case openWriter(":memory:") of
            when Left(left as error: SqlError) do
                printLn(describe(error));
                return ExitFailure();
            when Right(right as opened: Connection[Writing]) do
                var db: Connection[Writing] := opened;
                case migrate(&!db, @migrations) of
                    when Left(left as error: SqlError) do
                        printLn(describe(error));
                    when Right(right as applied: Index) do
                        run(&!db);
                end case;
                closeDatabase(db);
                return ExitSuccess();
        end case;
    end;
end module body.
```

Die richtige Form:

```hilde
import Standard.Sqlite (Connection, Writing, SqlError, describe, openWriter, closeDatabase, migrate);

module body Example is
    record Person[R: Region]: Free is
        name: Span[Nat8, R];
    end;

    generic [R: Region]
    function run(db: &![Connection[Writing], R]): Unit is
        @query(&~db, "SELECT name FROM users WHERE age > ?", 18) for row: Person[Q] do
            printLn(row.name);
        else error do
            printLn(describe(error));
        end for;
        return nil;
    end;

    function main(): ExitCode is
        case openWriter(":memory:") of
            when Left(left as error: SqlError) do
                printLn(describe(error));
                return ExitFailure();
            when Right(right as opened: Connection[Writing]) do
                var db: Connection[Writing] := opened;
                case migrate(&!db, @migrations) of
                    when Left(left as error: SqlError) do
                        printLn(describe(error));
                    when Right(right as applied: Index) do
                        run(&!db);
                end case;
                closeDatabase(db);
                return ExitSuccess();
        end case;
    end;
end module body.
```

### H8008

Meldung:

```text
Generic Error
@query: the character '#' is not SQL this compiler reads (line 1, column 40 of the SQL)
```

Im SQL steht ein Zeichen, das der Compiler nicht als SQL liest, etwa #.

Dieses Modul scheitert mit H8008:

```hilde fails H8008
import Standard.Sqlite (Connection, Writing, SqlError, describe, openWriter, closeDatabase, migrate);

module body Example is
    record Person[R: Region]: Free is
        name: Span[Nat8, R];
    end;

    generic [R: Region]
    function run(db: &![Connection[Writing], R]): Unit is
        @query(&~db, "SELECT name FROM users WHERE age >= 18 # adults") for row: Person[Q] do
            printLn(row.name);
        else error do
            printLn(describe(error));
        end for;
        return nil;
    end;

    function main(): ExitCode is
        case openWriter(":memory:") of
            when Left(left as error: SqlError) do
                printLn(describe(error));
                return ExitFailure();
            when Right(right as opened: Connection[Writing]) do
                var db: Connection[Writing] := opened;
                case migrate(&!db, @migrations) of
                    when Left(left as error: SqlError) do
                        printLn(describe(error));
                    when Right(right as applied: Index) do
                        run(&!db);
                end case;
                closeDatabase(db);
                return ExitSuccess();
        end case;
    end;
end module body.
```

Die richtige Form:

```hilde
import Standard.Sqlite (Connection, Writing, SqlError, describe, openWriter, closeDatabase, migrate);

module body Example is
    record Person[R: Region]: Free is
        name: Span[Nat8, R];
    end;

    generic [R: Region]
    function run(db: &![Connection[Writing], R]): Unit is
        @query(&~db, "SELECT name FROM users WHERE age >= 18 -- adults") for row: Person[Q] do
            printLn(row.name);
        else error do
            printLn(describe(error));
        end for;
        return nil;
    end;

    function main(): ExitCode is
        case openWriter(":memory:") of
            when Left(left as error: SqlError) do
                printLn(describe(error));
                return ExitFailure();
            when Right(right as opened: Connection[Writing]) do
                var db: Connection[Writing] := opened;
                case migrate(&!db, @migrations) of
                    when Left(left as error: SqlError) do
                        printLn(describe(error));
                    when Right(right as applied: Index) do
                        run(&!db);
                end case;
                closeDatabase(db);
                return ExitSuccess();
        end case;
    end;
end module body.
```

### H8009

Meldung:

```text
Generic Error
@query: expected BY, found name (line 1, column 30 of the SQL)
```

Ein Schlüsselwort fehlt, wo die Grammatik es verlangt, etwa BY nach ORDER.

Dieses Modul scheitert mit H8009:

```hilde fails H8009
import Standard.Sqlite (Connection, Writing, SqlError, describe, openWriter, closeDatabase, migrate);

module body Example is
    record Person[R: Region]: Free is
        name: Span[Nat8, R];
    end;

    generic [R: Region]
    function run(db: &![Connection[Writing], R]): Unit is
        @query(&~db, "SELECT name FROM users ORDER name") for row: Person[Q] do
            printLn(row.name);
        else error do
            printLn(describe(error));
        end for;
        return nil;
    end;

    function main(): ExitCode is
        case openWriter(":memory:") of
            when Left(left as error: SqlError) do
                printLn(describe(error));
                return ExitFailure();
            when Right(right as opened: Connection[Writing]) do
                var db: Connection[Writing] := opened;
                case migrate(&!db, @migrations) of
                    when Left(left as error: SqlError) do
                        printLn(describe(error));
                    when Right(right as applied: Index) do
                        run(&!db);
                end case;
                closeDatabase(db);
                return ExitSuccess();
        end case;
    end;
end module body.
```

Die richtige Form:

```hilde
import Standard.Sqlite (Connection, Writing, SqlError, describe, openWriter, closeDatabase, migrate);

module body Example is
    record Person[R: Region]: Free is
        name: Span[Nat8, R];
    end;

    generic [R: Region]
    function run(db: &![Connection[Writing], R]): Unit is
        @query(&~db, "SELECT name FROM users ORDER BY name") for row: Person[Q] do
            printLn(row.name);
        else error do
            printLn(describe(error));
        end for;
        return nil;
    end;

    function main(): ExitCode is
        case openWriter(":memory:") of
            when Left(left as error: SqlError) do
                printLn(describe(error));
                return ExitFailure();
            when Right(right as opened: Connection[Writing]) do
                var db: Connection[Writing] := opened;
                case migrate(&!db, @migrations) of
                    when Left(left as error: SqlError) do
                        printLn(describe(error));
                    when Right(right as applied: Index) do
                        run(&!db);
                end case;
                closeDatabase(db);
                return ExitSuccess();
        end case;
    end;
end module body.
```

### H8010

Meldung:

```text
Generic Error
@query: expected (, found 18 (line 1, column 37 of the SQL)
```

Ein Symbol fehlt, wo die Grammatik es verlangt, etwa die Klammer nach IN.

Dieses Modul scheitert mit H8010:

```hilde fails H8010
import Standard.Sqlite (Connection, Writing, SqlError, describe, openWriter, closeDatabase, migrate);

module body Example is
    record Person[R: Region]: Free is
        name: Span[Nat8, R];
    end;

    generic [R: Region]
    function run(db: &![Connection[Writing], R]): Unit is
        @query(&~db, "SELECT name FROM users WHERE age IN 18, 21") for row: Person[Q] do
            printLn(row.name);
        else error do
            printLn(describe(error));
        end for;
        return nil;
    end;

    function main(): ExitCode is
        case openWriter(":memory:") of
            when Left(left as error: SqlError) do
                printLn(describe(error));
                return ExitFailure();
            when Right(right as opened: Connection[Writing]) do
                var db: Connection[Writing] := opened;
                case migrate(&!db, @migrations) of
                    when Left(left as error: SqlError) do
                        printLn(describe(error));
                    when Right(right as applied: Index) do
                        run(&!db);
                end case;
                closeDatabase(db);
                return ExitSuccess();
        end case;
    end;
end module body.
```

Die richtige Form:

```hilde
import Standard.Sqlite (Connection, Writing, SqlError, describe, openWriter, closeDatabase, migrate);

module body Example is
    record Person[R: Region]: Free is
        name: Span[Nat8, R];
    end;

    generic [R: Region]
    function run(db: &![Connection[Writing], R]): Unit is
        @query(&~db, "SELECT name FROM users WHERE age IN (18, 21)") for row: Person[Q] do
            printLn(row.name);
        else error do
            printLn(describe(error));
        end for;
        return nil;
    end;

    function main(): ExitCode is
        case openWriter(":memory:") of
            when Left(left as error: SqlError) do
                printLn(describe(error));
                return ExitFailure();
            when Right(right as opened: Connection[Writing]) do
                var db: Connection[Writing] := opened;
                case migrate(&!db, @migrations) of
                    when Left(left as error: SqlError) do
                        printLn(describe(error));
                    when Right(right as applied: Index) do
                        run(&!db);
                end case;
                closeDatabase(db);
                return ExitSuccess();
        end case;
    end;
end module body.
```

### H8011

Meldung:

```text
Generic Error
@query: expected a table, found WHERE (line 1, column 18 of the SQL)
```

Ein Name fehlt, wo die Grammatik einen verlangt, etwa die Tabelle nach FROM.

Dieses Modul scheitert mit H8011:

```hilde fails H8011
import Standard.Sqlite (Connection, Writing, SqlError, describe, openWriter, closeDatabase, migrate);

module body Example is
    record Person[R: Region]: Free is
        name: Span[Nat8, R];
    end;

    generic [R: Region]
    function run(db: &![Connection[Writing], R]): Unit is
        @query(&~db, "SELECT name FROM WHERE age > 18") for row: Person[Q] do
            printLn(row.name);
        else error do
            printLn(describe(error));
        end for;
        return nil;
    end;

    function main(): ExitCode is
        case openWriter(":memory:") of
            when Left(left as error: SqlError) do
                printLn(describe(error));
                return ExitFailure();
            when Right(right as opened: Connection[Writing]) do
                var db: Connection[Writing] := opened;
                case migrate(&!db, @migrations) of
                    when Left(left as error: SqlError) do
                        printLn(describe(error));
                    when Right(right as applied: Index) do
                        run(&!db);
                end case;
                closeDatabase(db);
                return ExitSuccess();
        end case;
    end;
end module body.
```

Die richtige Form:

```hilde
import Standard.Sqlite (Connection, Writing, SqlError, describe, openWriter, closeDatabase, migrate);

module body Example is
    record Person[R: Region]: Free is
        name: Span[Nat8, R];
    end;

    generic [R: Region]
    function run(db: &![Connection[Writing], R]): Unit is
        @query(&~db, "SELECT name FROM users WHERE age > 18") for row: Person[Q] do
            printLn(row.name);
        else error do
            printLn(describe(error));
        end for;
        return nil;
    end;

    function main(): ExitCode is
        case openWriter(":memory:") of
            when Left(left as error: SqlError) do
                printLn(describe(error));
                return ExitFailure();
            when Right(right as opened: Connection[Writing]) do
                var db: Connection[Writing] := opened;
                case migrate(&!db, @migrations) of
                    when Left(left as error: SqlError) do
                        printLn(describe(error));
                    when Right(right as applied: Index) do
                        run(&!db);
                end case;
                closeDatabase(db);
                return ExitSuccess();
        end case;
    end;
end module body.
```

### H8012

Meldung:

```text
Generic Error
@query: a subquery is not accepted in the SQL the compiler checks (line 1, column 37 of the SQL)
```

Das SQL verwendet etwas, das SQLite kennt und dieser Compiler nicht annimmt,
weil er ihm keinen Typ geben könnte, etwa eine Unterabfrage.

Dieses Modul scheitert mit H8012:

```hilde fails H8012
import Standard.Sqlite (Connection, Writing, SqlError, describe, openWriter, closeDatabase, migrate);

module body Example is
    record Person[R: Region]: Free is
        name: Span[Nat8, R];
    end;

    generic [R: Region]
    function run(db: &![Connection[Writing], R]): Unit is
        @query(&~db, "SELECT name FROM users WHERE age > (SELECT avg(age) FROM users)") for row: Person[Q] do
            printLn(row.name);
        else error do
            printLn(describe(error));
        end for;
        return nil;
    end;

    function main(): ExitCode is
        case openWriter(":memory:") of
            when Left(left as error: SqlError) do
                printLn(describe(error));
                return ExitFailure();
            when Right(right as opened: Connection[Writing]) do
                var db: Connection[Writing] := opened;
                case migrate(&!db, @migrations) of
                    when Left(left as error: SqlError) do
                        printLn(describe(error));
                    when Right(right as applied: Index) do
                        run(&!db);
                end case;
                closeDatabase(db);
                return ExitSuccess();
        end case;
    end;
end module body.
```

Die richtige Form:

```hilde
import Standard.Sqlite (Connection, Writing, SqlError, describe, openWriter, closeDatabase, migrate);

module body Example is
    record Person[R: Region]: Free is
        name: Span[Nat8, R];
    end;

    generic [R: Region]
    function run(db: &![Connection[Writing], R]): Unit is
        @query(&~db, "SELECT name FROM users WHERE age > ?", 40) for row: Person[Q] do
            printLn(row.name);
        else error do
            printLn(describe(error));
        end for;
        return nil;
    end;

    function main(): ExitCode is
        case openWriter(":memory:") of
            when Left(left as error: SqlError) do
                printLn(describe(error));
                return ExitFailure();
            when Right(right as opened: Connection[Writing]) do
                var db: Connection[Writing] := opened;
                case migrate(&!db, @migrations) of
                    when Left(left as error: SqlError) do
                        printLn(describe(error));
                    when Right(right as applied: Index) do
                        run(&!db);
                end case;
                closeDatabase(db);
                return ExitSuccess();
        end case;
    end;
end module body.
```

### H8013

Meldung:

```text
Generic Error
@query: sum(*): only count takes * (line 1, column 8 of the SQL)
```

Eine andere Funktion als count bekommt `*`.

Dieses Modul scheitert mit H8013:

```hilde fails H8013
import Standard.Sqlite (Connection, Writing, SqlError, describe, openWriter, closeDatabase, migrate);

module body Example is
    record Tally: Free is
        total: Int64;
    end;

    generic [R: Region]
    function run(db: &![Connection[Writing], R]): Unit is
        @query(&~db, "SELECT sum(*) AS total FROM users") for row: Tally do
            printLn(row.total);
        else error do
            printLn(describe(error));
        end for;
        return nil;
    end;

    function main(): ExitCode is
        case openWriter(":memory:") of
            when Left(left as error: SqlError) do
                printLn(describe(error));
                return ExitFailure();
            when Right(right as opened: Connection[Writing]) do
                var db: Connection[Writing] := opened;
                case migrate(&!db, @migrations) of
                    when Left(left as error: SqlError) do
                        printLn(describe(error));
                    when Right(right as applied: Index) do
                        run(&!db);
                end case;
                closeDatabase(db);
                return ExitSuccess();
        end case;
    end;
end module body.
```

Die richtige Form:

```hilde
import Standard.Sqlite (Connection, Writing, SqlError, describe, openWriter, closeDatabase, migrate);

module body Example is
    record Tally: Free is
        total: Int64;
    end;

    generic [R: Region]
    function run(db: &![Connection[Writing], R]): Unit is
        @query(&~db, "SELECT count(*) AS total FROM users") for row: Tally do
            printLn(row.total);
        else error do
            printLn(describe(error));
        end for;
        return nil;
    end;

    function main(): ExitCode is
        case openWriter(":memory:") of
            when Left(left as error: SqlError) do
                printLn(describe(error));
                return ExitFailure();
            when Right(right as opened: Connection[Writing]) do
                var db: Connection[Writing] := opened;
                case migrate(&!db, @migrations) of
                    when Left(left as error: SqlError) do
                        printLn(describe(error));
                    when Right(right as applied: Index) do
                        run(&!db);
                end case;
                closeDatabase(db);
                return ExitSuccess();
        end case;
    end;
end module body.
```

### H8014

Meldung:

```text
Generic Error
@query: a column alias is written with AS (line 1, column 20 of the SQL)
```

Eine Spalte des Ergebnisses wird ohne AS benannt.

Dieses Modul scheitert mit H8014:

```hilde fails H8014
import Standard.Sqlite (Connection, Writing, SqlError, describe, openWriter, closeDatabase, migrate);

module body Example is
    record Person[R: Region]: Free is
        name: Span[Nat8, R];
    end;

    generic [R: Region]
    function run(db: &![Connection[Writing], R]): Unit is
        @query(&~db, "SELECT upper(name) name FROM users") for row: Person[Q] do
            printLn(row.name);
        else error do
            printLn(describe(error));
        end for;
        return nil;
    end;

    function main(): ExitCode is
        case openWriter(":memory:") of
            when Left(left as error: SqlError) do
                printLn(describe(error));
                return ExitFailure();
            when Right(right as opened: Connection[Writing]) do
                var db: Connection[Writing] := opened;
                case migrate(&!db, @migrations) of
                    when Left(left as error: SqlError) do
                        printLn(describe(error));
                    when Right(right as applied: Index) do
                        run(&!db);
                end case;
                closeDatabase(db);
                return ExitSuccess();
        end case;
    end;
end module body.
```

Die richtige Form:

```hilde
import Standard.Sqlite (Connection, Writing, SqlError, describe, openWriter, closeDatabase, migrate);

module body Example is
    record Person[R: Region]: Free is
        name: Span[Nat8, R];
    end;

    generic [R: Region]
    function run(db: &![Connection[Writing], R]): Unit is
        @query(&~db, "SELECT upper(name) AS name FROM users") for row: Person[Q] do
            printLn(row.name);
        else error do
            printLn(describe(error));
        end for;
        return nil;
    end;

    function main(): ExitCode is
        case openWriter(":memory:") of
            when Left(left as error: SqlError) do
                printLn(describe(error));
                return ExitFailure();
            when Right(right as opened: Connection[Writing]) do
                var db: Connection[Writing] := opened;
                case migrate(&!db, @migrations) of
                    when Left(left as error: SqlError) do
                        printLn(describe(error));
                    when Right(right as applied: Index) do
                        run(&!db);
                end case;
                closeDatabase(db);
                return ExitSuccess();
        end case;
    end;
end module body.
```

### H8015

Meldung:

```text
Generic Error
@execute: expected ABORT, FAIL, IGNORE, REPLACE or ROLLBACK after OR (line 1, column 11 of the SQL)
```

Auf OR in INSERT OR oder UPDATE OR folgt etwas anderes als ABORT, FAIL,
IGNORE, REPLACE oder ROLLBACK.

Dieses Modul scheitert mit H8015:

```hilde fails H8015
import Standard.Sqlite (Connection, Writing, SqlError, describe, openWriter, closeDatabase, migrate);

module body Example is
    generic [R: Region]
    function run(db: &![Connection[Writing], R]): Unit is
        let result: Either[SqlError, Nat64] := @execute(&~db, "INSERT OR SKIP INTO users (name) VALUES (?)", "ann");
        case result of
            when Left(left as error: SqlError) do
                printLn(describe(error));
            when Right(right as changed: Nat64) do
                printLn(changed);
        end case;
        return nil;
    end;

    function main(): ExitCode is
        case openWriter(":memory:") of
            when Left(left as error: SqlError) do
                printLn(describe(error));
                return ExitFailure();
            when Right(right as opened: Connection[Writing]) do
                var db: Connection[Writing] := opened;
                case migrate(&!db, @migrations) of
                    when Left(left as error: SqlError) do
                        printLn(describe(error));
                    when Right(right as applied: Index) do
                        run(&!db);
                end case;
                closeDatabase(db);
                return ExitSuccess();
        end case;
    end;
end module body.
```

Die richtige Form:

```hilde
import Standard.Sqlite (Connection, Writing, SqlError, describe, openWriter, closeDatabase, migrate);

module body Example is
    generic [R: Region]
    function run(db: &![Connection[Writing], R]): Unit is
        let result: Either[SqlError, Nat64] := @execute(&~db, "INSERT OR IGNORE INTO users (name) VALUES (?)", "ann");
        case result of
            when Left(left as error: SqlError) do
                printLn(describe(error));
            when Right(right as changed: Nat64) do
                printLn(changed);
        end case;
        return nil;
    end;

    function main(): ExitCode is
        case openWriter(":memory:") of
            when Left(left as error: SqlError) do
                printLn(describe(error));
                return ExitFailure();
            when Right(right as opened: Connection[Writing]) do
                var db: Connection[Writing] := opened;
                case migrate(&!db, @migrations) of
                    when Left(left as error: SqlError) do
                        printLn(describe(error));
                    when Right(right as applied: Index) do
                        run(&!db);
                end case;
                closeDatabase(db);
                return ExitSuccess();
        end case;
    end;
end module body.
```

### H8016

Meldung:

```text
Generic Error
migration: expected a default value, found now
```

Der Vorgabewert einer Spalte in einer Migration ist kein Literal, keine Zahl
mit Vorzeichen, kein CURRENT_TIME, CURRENT_DATE oder CURRENT_TIMESTAMP und
kein Ausdruck in Klammern.

Dieses Modul scheitert mit H8016:

```hilde fails H8016
import Standard.Sqlite (Connection, Writing, SqlError, describe, openWriter, closeDatabase, migrate);

module body Example is
    record Person[R: Region]: Free is
        name: Span[Nat8, R];
    end;

    generic [R: Region]
    function run(db: &![Connection[Writing], R]): Unit is
        @query(&~db, "SELECT name FROM users") for row: Person[Q] do
            printLn(row.name);
        else error do
            printLn(describe(error));
        end for;
        return nil;
    end;

    function main(): ExitCode is
        case openWriter(":memory:") of
            when Left(left as error: SqlError) do
                printLn(describe(error));
                return ExitFailure();
            when Right(right as opened: Connection[Writing]) do
                var db: Connection[Writing] := opened;
                case migrate(&!db, @migrations) of
                    when Left(left as error: SqlError) do
                        printLn(describe(error));
                    when Right(right as applied: Index) do
                        run(&!db);
                end case;
                closeDatabase(db);
                return ExitSuccess();
        end case;
    end;
end module body.
```

Daneben `migrations/1-schema.sql`:

```sql file migrations/1-schema.sql
CREATE TABLE users (
    id INTEGER PRIMARY KEY,
    name TEXT NOT NULL,
    created TEXT NOT NULL DEFAULT now
) STRICT;
```

Die richtige Form:

```hilde
import Standard.Sqlite (Connection, Writing, SqlError, describe, openWriter, closeDatabase, migrate);

module body Example is
    record Person[R: Region]: Free is
        name: Span[Nat8, R];
    end;

    generic [R: Region]
    function run(db: &![Connection[Writing], R]): Unit is
        @query(&~db, "SELECT name FROM users") for row: Person[Q] do
            printLn(row.name);
        else error do
            printLn(describe(error));
        end for;
        return nil;
    end;

    function main(): ExitCode is
        case openWriter(":memory:") of
            when Left(left as error: SqlError) do
                printLn(describe(error));
                return ExitFailure();
            when Right(right as opened: Connection[Writing]) do
                var db: Connection[Writing] := opened;
                case migrate(&!db, @migrations) of
                    when Left(left as error: SqlError) do
                        printLn(describe(error));
                    when Right(right as applied: Index) do
                        run(&!db);
                end case;
                closeDatabase(db);
                return ExitSuccess();
        end case;
    end;
end module body.
```

Daneben `migrations/1-schema.sql`:

```sql file migrations/1-schema.sql
CREATE TABLE users (
    id INTEGER PRIMARY KEY,
    name TEXT NOT NULL,
    created TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
) STRICT;
```

### H8017

Meldung:

```text
Generic Error
migration: a size after the type name is not a STRICT type (INT, INTEGER, REAL, TEXT, BLOB)
```

Ein Spaltentyp in einer Migration hat eine Größe, wie in VARCHAR(40). Eine
STRICT-Tabelle kennt INT, INTEGER, REAL, TEXT und BLOB, ohne Größe.

Dieses Modul scheitert mit H8017:

```hilde fails H8017
import Standard.Sqlite (Connection, Writing, SqlError, describe, openWriter, closeDatabase, migrate);

module body Example is
    record Person[R: Region]: Free is
        name: Span[Nat8, R];
    end;

    generic [R: Region]
    function run(db: &![Connection[Writing], R]): Unit is
        @query(&~db, "SELECT name FROM users") for row: Person[Q] do
            printLn(row.name);
        else error do
            printLn(describe(error));
        end for;
        return nil;
    end;

    function main(): ExitCode is
        case openWriter(":memory:") of
            when Left(left as error: SqlError) do
                printLn(describe(error));
                return ExitFailure();
            when Right(right as opened: Connection[Writing]) do
                var db: Connection[Writing] := opened;
                case migrate(&!db, @migrations) of
                    when Left(left as error: SqlError) do
                        printLn(describe(error));
                    when Right(right as applied: Index) do
                        run(&!db);
                end case;
                closeDatabase(db);
                return ExitSuccess();
        end case;
    end;
end module body.
```

Daneben `migrations/1-schema.sql`:

```sql file migrations/1-schema.sql
CREATE TABLE users (
    id INTEGER PRIMARY KEY,
    name VARCHAR(40) NOT NULL
) STRICT;
```

Die richtige Form:

```hilde
import Standard.Sqlite (Connection, Writing, SqlError, describe, openWriter, closeDatabase, migrate);

module body Example is
    record Person[R: Region]: Free is
        name: Span[Nat8, R];
    end;

    generic [R: Region]
    function run(db: &![Connection[Writing], R]): Unit is
        @query(&~db, "SELECT name FROM users") for row: Person[Q] do
            printLn(row.name);
        else error do
            printLn(describe(error));
        end for;
        return nil;
    end;

    function main(): ExitCode is
        case openWriter(":memory:") of
            when Left(left as error: SqlError) do
                printLn(describe(error));
                return ExitFailure();
            when Right(right as opened: Connection[Writing]) do
                var db: Connection[Writing] := opened;
                case migrate(&!db, @migrations) of
                    when Left(left as error: SqlError) do
                        printLn(describe(error));
                    when Right(right as applied: Index) do
                        run(&!db);
                end case;
                closeDatabase(db);
                return ExitSuccess();
        end case;
    end;
end module body.
```

Daneben `migrations/1-schema.sql`:

```sql file migrations/1-schema.sql
CREATE TABLE users (
    id INTEGER PRIMARY KEY,
    name TEXT NOT NULL
) STRICT;
```

### H8018

Meldung:

```text
Generic Error
migration: expected a table constraint, found KEY
```

Nach CONSTRAINT und seinem Namen ist eine Tabellen-Constraint weder PRIMARY
KEY noch UNIQUE, CHECK oder FOREIGN KEY.

Dieses Modul scheitert mit H8018:

```hilde fails H8018
import Standard.Sqlite (Connection, Writing, SqlError, describe, openWriter, closeDatabase, migrate);

module body Example is
    record Person[R: Region]: Free is
        name: Span[Nat8, R];
    end;

    generic [R: Region]
    function run(db: &![Connection[Writing], R]): Unit is
        @query(&~db, "SELECT name FROM users") for row: Person[Q] do
            printLn(row.name);
        else error do
            printLn(describe(error));
        end for;
        return nil;
    end;

    function main(): ExitCode is
        case openWriter(":memory:") of
            when Left(left as error: SqlError) do
                printLn(describe(error));
                return ExitFailure();
            when Right(right as opened: Connection[Writing]) do
                var db: Connection[Writing] := opened;
                case migrate(&!db, @migrations) of
                    when Left(left as error: SqlError) do
                        printLn(describe(error));
                    when Right(right as applied: Index) do
                        run(&!db);
                end case;
                closeDatabase(db);
                return ExitSuccess();
        end case;
    end;
end module body.
```

Daneben `migrations/1-schema.sql`:

```sql file migrations/1-schema.sql
CREATE TABLE users (
    id INTEGER,
    name TEXT NOT NULL,
    CONSTRAINT users_key KEY (id)
) STRICT;
```

Die richtige Form:

```hilde
import Standard.Sqlite (Connection, Writing, SqlError, describe, openWriter, closeDatabase, migrate);

module body Example is
    record Person[R: Region]: Free is
        name: Span[Nat8, R];
    end;

    generic [R: Region]
    function run(db: &![Connection[Writing], R]): Unit is
        @query(&~db, "SELECT name FROM users") for row: Person[Q] do
            printLn(row.name);
        else error do
            printLn(describe(error));
        end for;
        return nil;
    end;

    function main(): ExitCode is
        case openWriter(":memory:") of
            when Left(left as error: SqlError) do
                printLn(describe(error));
                return ExitFailure();
            when Right(right as opened: Connection[Writing]) do
                var db: Connection[Writing] := opened;
                case migrate(&!db, @migrations) of
                    when Left(left as error: SqlError) do
                        printLn(describe(error));
                    when Right(right as applied: Index) do
                        run(&!db);
                end case;
                closeDatabase(db);
                return ExitSuccess();
        end case;
    end;
end module body.
```

Daneben `migrations/1-schema.sql`:

```sql file migrations/1-schema.sql
CREATE TABLE users (
    id INTEGER,
    name TEXT NOT NULL,
    CONSTRAINT users_key PRIMARY KEY (id)
) STRICT;
```

### H8019

Meldung:

```text
Generic Error
migration: expected ROWID after WITHOUT
```

Auf WITHOUT nach einer Tabelle folgt nicht ROWID.

Dieses Modul scheitert mit H8019:

```hilde fails H8019
import Standard.Sqlite (Connection, Writing, SqlError, describe, openWriter, closeDatabase, migrate);

module body Example is
    record Person[R: Region]: Free is
        name: Span[Nat8, R];
    end;

    generic [R: Region]
    function run(db: &![Connection[Writing], R]): Unit is
        @query(&~db, "SELECT name FROM users") for row: Person[Q] do
            printLn(row.name);
        else error do
            printLn(describe(error));
        end for;
        return nil;
    end;

    function main(): ExitCode is
        case openWriter(":memory:") of
            when Left(left as error: SqlError) do
                printLn(describe(error));
                return ExitFailure();
            when Right(right as opened: Connection[Writing]) do
                var db: Connection[Writing] := opened;
                case migrate(&!db, @migrations) of
                    when Left(left as error: SqlError) do
                        printLn(describe(error));
                    when Right(right as applied: Index) do
                        run(&!db);
                end case;
                closeDatabase(db);
                return ExitSuccess();
        end case;
    end;
end module body.
```

Daneben `migrations/1-schema.sql`:

```sql file migrations/1-schema.sql
CREATE TABLE users (
    id INTEGER PRIMARY KEY,
    name TEXT NOT NULL
) STRICT, WITHOUT ROWS;
```

Die richtige Form:

```hilde
import Standard.Sqlite (Connection, Writing, SqlError, describe, openWriter, closeDatabase, migrate);

module body Example is
    record Person[R: Region]: Free is
        name: Span[Nat8, R];
    end;

    generic [R: Region]
    function run(db: &![Connection[Writing], R]): Unit is
        @query(&~db, "SELECT name FROM users") for row: Person[Q] do
            printLn(row.name);
        else error do
            printLn(describe(error));
        end for;
        return nil;
    end;

    function main(): ExitCode is
        case openWriter(":memory:") of
            when Left(left as error: SqlError) do
                printLn(describe(error));
                return ExitFailure();
            when Right(right as opened: Connection[Writing]) do
                var db: Connection[Writing] := opened;
                case migrate(&!db, @migrations) of
                    when Left(left as error: SqlError) do
                        printLn(describe(error));
                    when Right(right as applied: Index) do
                        run(&!db);
                end case;
                closeDatabase(db);
                return ExitSuccess();
        end case;
    end;
end module body.
```

Daneben `migrations/1-schema.sql`:

```sql file migrations/1-schema.sql
CREATE TABLE users (
    id INTEGER PRIMARY KEY,
    name TEXT NOT NULL
) STRICT, WITHOUT ROWID;
```

### H8020

Meldung:

```text
Generic Error
migration: expected STRICT or WITHOUT ROWID, found WITHOUT_ROWID
```

In der Liste der Tabellenoptionen steht nach einem Komma etwas anderes als
STRICT oder WITHOUT ROWID.

Dieses Modul scheitert mit H8020:

```hilde fails H8020
import Standard.Sqlite (Connection, Writing, SqlError, describe, openWriter, closeDatabase, migrate);

module body Example is
    record Person[R: Region]: Free is
        name: Span[Nat8, R];
    end;

    generic [R: Region]
    function run(db: &![Connection[Writing], R]): Unit is
        @query(&~db, "SELECT name FROM users") for row: Person[Q] do
            printLn(row.name);
        else error do
            printLn(describe(error));
        end for;
        return nil;
    end;

    function main(): ExitCode is
        case openWriter(":memory:") of
            when Left(left as error: SqlError) do
                printLn(describe(error));
                return ExitFailure();
            when Right(right as opened: Connection[Writing]) do
                var db: Connection[Writing] := opened;
                case migrate(&!db, @migrations) of
                    when Left(left as error: SqlError) do
                        printLn(describe(error));
                    when Right(right as applied: Index) do
                        run(&!db);
                end case;
                closeDatabase(db);
                return ExitSuccess();
        end case;
    end;
end module body.
```

Daneben `migrations/1-schema.sql`:

```sql file migrations/1-schema.sql
CREATE TABLE users (
    id INTEGER PRIMARY KEY,
    name TEXT NOT NULL
) STRICT, WITHOUT_ROWID;
```

Die richtige Form:

```hilde
import Standard.Sqlite (Connection, Writing, SqlError, describe, openWriter, closeDatabase, migrate);

module body Example is
    record Person[R: Region]: Free is
        name: Span[Nat8, R];
    end;

    generic [R: Region]
    function run(db: &![Connection[Writing], R]): Unit is
        @query(&~db, "SELECT name FROM users") for row: Person[Q] do
            printLn(row.name);
        else error do
            printLn(describe(error));
        end for;
        return nil;
    end;

    function main(): ExitCode is
        case openWriter(":memory:") of
            when Left(left as error: SqlError) do
                printLn(describe(error));
                return ExitFailure();
            when Right(right as opened: Connection[Writing]) do
                var db: Connection[Writing] := opened;
                case migrate(&!db, @migrations) of
                    when Left(left as error: SqlError) do
                        printLn(describe(error));
                    when Right(right as applied: Index) do
                        run(&!db);
                end case;
                closeDatabase(db);
                return ExitSuccess();
        end case;
    end;
end module body.
```

Daneben `migrations/1-schema.sql`:

```sql file migrations/1-schema.sql
CREATE TABLE users (
    id INTEGER PRIMARY KEY,
    name TEXT NOT NULL
) STRICT, WITHOUT ROWID;
```

### H8021

Meldung:

```text
Generic Error
migration: expected ( after the table
```

Bei CREATE INDEX fehlt nach der Tabelle die Klammer mit den Spalten.

Dieses Modul scheitert mit H8021:

```hilde fails H8021
import Standard.Sqlite (Connection, Writing, SqlError, describe, openWriter, closeDatabase, migrate);

module body Example is
    record Person[R: Region]: Free is
        name: Span[Nat8, R];
    end;

    generic [R: Region]
    function run(db: &![Connection[Writing], R]): Unit is
        @query(&~db, "SELECT name FROM users") for row: Person[Q] do
            printLn(row.name);
        else error do
            printLn(describe(error));
        end for;
        return nil;
    end;

    function main(): ExitCode is
        case openWriter(":memory:") of
            when Left(left as error: SqlError) do
                printLn(describe(error));
                return ExitFailure();
            when Right(right as opened: Connection[Writing]) do
                var db: Connection[Writing] := opened;
                case migrate(&!db, @migrations) of
                    when Left(left as error: SqlError) do
                        printLn(describe(error));
                    when Right(right as applied: Index) do
                        run(&!db);
                end case;
                closeDatabase(db);
                return ExitSuccess();
        end case;
    end;
end module body.
```

Daneben `migrations/1-schema.sql`:

```sql file migrations/1-schema.sql
CREATE TABLE users (
    id INTEGER PRIMARY KEY,
    name TEXT NOT NULL
) STRICT;

CREATE INDEX users_name ON users name;
```

Die richtige Form:

```hilde
import Standard.Sqlite (Connection, Writing, SqlError, describe, openWriter, closeDatabase, migrate);

module body Example is
    record Person[R: Region]: Free is
        name: Span[Nat8, R];
    end;

    generic [R: Region]
    function run(db: &![Connection[Writing], R]): Unit is
        @query(&~db, "SELECT name FROM users") for row: Person[Q] do
            printLn(row.name);
        else error do
            printLn(describe(error));
        end for;
        return nil;
    end;

    function main(): ExitCode is
        case openWriter(":memory:") of
            when Left(left as error: SqlError) do
                printLn(describe(error));
                return ExitFailure();
            when Right(right as opened: Connection[Writing]) do
                var db: Connection[Writing] := opened;
                case migrate(&!db, @migrations) of
                    when Left(left as error: SqlError) do
                        printLn(describe(error));
                    when Right(right as applied: Index) do
                        run(&!db);
                end case;
                closeDatabase(db);
                return ExitSuccess();
        end case;
    end;
end module body.
```

Daneben `migrations/1-schema.sql`:

```sql file migrations/1-schema.sql
CREATE TABLE users (
    id INTEGER PRIMARY KEY,
    name TEXT NOT NULL
) STRICT;

CREATE INDEX users_name ON users (name);
```

### H8022

Meldung:

```text
Generic Error
migration: expected RENAME, ADD or DROP after ALTER TABLE
```

Auf ALTER TABLE folgt etwas anderes als RENAME, ADD oder DROP.

Dieses Modul scheitert mit H8022:

```hilde fails H8022
import Standard.Sqlite (Connection, Writing, SqlError, describe, openWriter, closeDatabase, migrate);

module body Example is
    record Person[R: Region]: Free is
        name: Span[Nat8, R];
    end;

    generic [R: Region]
    function run(db: &![Connection[Writing], R]): Unit is
        @query(&~db, "SELECT name FROM users") for row: Person[Q] do
            printLn(row.name);
        else error do
            printLn(describe(error));
        end for;
        return nil;
    end;

    function main(): ExitCode is
        case openWriter(":memory:") of
            when Left(left as error: SqlError) do
                printLn(describe(error));
                return ExitFailure();
            when Right(right as opened: Connection[Writing]) do
                var db: Connection[Writing] := opened;
                case migrate(&!db, @migrations) of
                    when Left(left as error: SqlError) do
                        printLn(describe(error));
                    when Right(right as applied: Index) do
                        run(&!db);
                end case;
                closeDatabase(db);
                return ExitSuccess();
        end case;
    end;
end module body.
```

Daneben `migrations/1-schema.sql`:

```sql file migrations/1-schema.sql
CREATE TABLE users (
    id INTEGER PRIMARY KEY,
    name TEXT NOT NULL
) STRICT;

ALTER TABLE users MODIFY name TEXT;
```

Die richtige Form:

```hilde
import Standard.Sqlite (Connection, Writing, SqlError, describe, openWriter, closeDatabase, migrate);

module body Example is
    record Person[R: Region]: Free is
        name: Span[Nat8, R];
    end;

    generic [R: Region]
    function run(db: &![Connection[Writing], R]): Unit is
        @query(&~db, "SELECT name FROM users") for row: Person[Q] do
            printLn(row.name);
        else error do
            printLn(describe(error));
        end for;
        return nil;
    end;

    function main(): ExitCode is
        case openWriter(":memory:") of
            when Left(left as error: SqlError) do
                printLn(describe(error));
                return ExitFailure();
            when Right(right as opened: Connection[Writing]) do
                var db: Connection[Writing] := opened;
                case migrate(&!db, @migrations) of
                    when Left(left as error: SqlError) do
                        printLn(describe(error));
                    when Right(right as applied: Index) do
                        run(&!db);
                end case;
                closeDatabase(db);
                return ExitSuccess();
        end case;
    end;
end module body.
```

Daneben `migrations/1-schema.sql`:

```sql file migrations/1-schema.sql
CREATE TABLE users (
    id INTEGER PRIMARY KEY,
    name TEXT NOT NULL
) STRICT;

ALTER TABLE users ADD COLUMN nickname TEXT;
```

### H8023

Meldung:

```text
Generic Error
migration: CREATE VIEW is not accepted in a migration, which creates a table (CREATE TABLE) or an index (CREATE INDEX, CREATE UNIQUE INDEX)
```

Eine Migration legt etwas anderes als eine Tabelle oder einen Index an, etwa
eine View.

Dieses Modul scheitert mit H8023:

```hilde fails H8023
import Standard.Sqlite (Connection, Writing, SqlError, describe, openWriter, closeDatabase, migrate);

module body Example is
    record Person[R: Region]: Free is
        name: Span[Nat8, R];
    end;

    generic [R: Region]
    function run(db: &![Connection[Writing], R]): Unit is
        @query(&~db, "SELECT name FROM users") for row: Person[Q] do
            printLn(row.name);
        else error do
            printLn(describe(error));
        end for;
        return nil;
    end;

    function main(): ExitCode is
        case openWriter(":memory:") of
            when Left(left as error: SqlError) do
                printLn(describe(error));
                return ExitFailure();
            when Right(right as opened: Connection[Writing]) do
                var db: Connection[Writing] := opened;
                case migrate(&!db, @migrations) of
                    when Left(left as error: SqlError) do
                        printLn(describe(error));
                    when Right(right as applied: Index) do
                        run(&!db);
                end case;
                closeDatabase(db);
                return ExitSuccess();
        end case;
    end;
end module body.
```

Daneben `migrations/1-schema.sql`:

```sql file migrations/1-schema.sql
CREATE TABLE users (
    id INTEGER PRIMARY KEY,
    name TEXT NOT NULL
) STRICT;

CREATE VIEW names AS SELECT name FROM users;
```

Die richtige Form:

```hilde
import Standard.Sqlite (Connection, Writing, SqlError, describe, openWriter, closeDatabase, migrate);

module body Example is
    record Person[R: Region]: Free is
        name: Span[Nat8, R];
    end;

    generic [R: Region]
    function run(db: &![Connection[Writing], R]): Unit is
        @query(&~db, "SELECT name FROM users") for row: Person[Q] do
            printLn(row.name);
        else error do
            printLn(describe(error));
        end for;
        return nil;
    end;

    function main(): ExitCode is
        case openWriter(":memory:") of
            when Left(left as error: SqlError) do
                printLn(describe(error));
                return ExitFailure();
            when Right(right as opened: Connection[Writing]) do
                var db: Connection[Writing] := opened;
                case migrate(&!db, @migrations) of
                    when Left(left as error: SqlError) do
                        printLn(describe(error));
                    when Right(right as applied: Index) do
                        run(&!db);
                end case;
                closeDatabase(db);
                return ExitSuccess();
        end case;
    end;
end module body.
```

Daneben `migrations/1-schema.sql`:

```sql file migrations/1-schema.sql
CREATE TABLE users (
    id INTEGER PRIMARY KEY,
    name TEXT NOT NULL
) STRICT;

CREATE INDEX users_name ON users (name);
```

### H8024

Meldung:

```text
Generic Error
migration: DROP VIEW is not accepted in a migration
```

Eine Migration löscht etwas anderes als eine Tabelle oder einen Index, etwa
eine View.

Dieses Modul scheitert mit H8024:

```hilde fails H8024
import Standard.Sqlite (Connection, Writing, SqlError, describe, openWriter, closeDatabase, migrate);

module body Example is
    record Person[R: Region]: Free is
        name: Span[Nat8, R];
    end;

    generic [R: Region]
    function run(db: &![Connection[Writing], R]): Unit is
        @query(&~db, "SELECT name FROM users") for row: Person[Q] do
            printLn(row.name);
        else error do
            printLn(describe(error));
        end for;
        return nil;
    end;

    function main(): ExitCode is
        case openWriter(":memory:") of
            when Left(left as error: SqlError) do
                printLn(describe(error));
                return ExitFailure();
            when Right(right as opened: Connection[Writing]) do
                var db: Connection[Writing] := opened;
                case migrate(&!db, @migrations) of
                    when Left(left as error: SqlError) do
                        printLn(describe(error));
                    when Right(right as applied: Index) do
                        run(&!db);
                end case;
                closeDatabase(db);
                return ExitSuccess();
        end case;
    end;
end module body.
```

Daneben `migrations/1-schema.sql`:

```sql file migrations/1-schema.sql
CREATE TABLE users (
    id INTEGER PRIMARY KEY,
    name TEXT NOT NULL
) STRICT;

DROP VIEW names;
```

Die richtige Form:

```hilde
import Standard.Sqlite (Connection, Writing, SqlError, describe, openWriter, closeDatabase, migrate);

module body Example is
    record Person[R: Region]: Free is
        name: Span[Nat8, R];
    end;

    generic [R: Region]
    function run(db: &![Connection[Writing], R]): Unit is
        @query(&~db, "SELECT name FROM users") for row: Person[Q] do
            printLn(row.name);
        else error do
            printLn(describe(error));
        end for;
        return nil;
    end;

    function main(): ExitCode is
        case openWriter(":memory:") of
            when Left(left as error: SqlError) do
                printLn(describe(error));
                return ExitFailure();
            when Right(right as opened: Connection[Writing]) do
                var db: Connection[Writing] := opened;
                case migrate(&!db, @migrations) of
                    when Left(left as error: SqlError) do
                        printLn(describe(error));
                    when Right(right as applied: Index) do
                        run(&!db);
                end case;
                closeDatabase(db);
                return ExitSuccess();
        end case;
    end;
end module body.
```

Daneben `migrations/1-schema.sql`:

```sql file migrations/1-schema.sql
CREATE TABLE users (
    id INTEGER PRIMARY KEY,
    name TEXT NOT NULL
) STRICT;

CREATE INDEX users_name ON users (name);

DROP INDEX users_name;
```

### H8025

Meldung:

```text
Generic Error
migration: a migration may hold CREATE TABLE, CREATE INDEX, ALTER TABLE, DROP TABLE, DROP INDEX, INSERT, UPDATE and DELETE, not PRAGMA
```

Eine Migration enthält eine andere Anweisung als CREATE TABLE, CREATE INDEX,
ALTER TABLE, DROP TABLE, DROP INDEX, INSERT, UPDATE und DELETE, etwa PRAGMA.

Dieses Modul scheitert mit H8025:

```hilde fails H8025
import Standard.Sqlite (Connection, Writing, SqlError, describe, openWriter, closeDatabase, migrate);

module body Example is
    record Person[R: Region]: Free is
        name: Span[Nat8, R];
    end;

    generic [R: Region]
    function run(db: &![Connection[Writing], R]): Unit is
        @query(&~db, "SELECT name FROM users") for row: Person[Q] do
            printLn(row.name);
        else error do
            printLn(describe(error));
        end for;
        return nil;
    end;

    function main(): ExitCode is
        case openWriter(":memory:") of
            when Left(left as error: SqlError) do
                printLn(describe(error));
                return ExitFailure();
            when Right(right as opened: Connection[Writing]) do
                var db: Connection[Writing] := opened;
                case migrate(&!db, @migrations) of
                    when Left(left as error: SqlError) do
                        printLn(describe(error));
                    when Right(right as applied: Index) do
                        run(&!db);
                end case;
                closeDatabase(db);
                return ExitSuccess();
        end case;
    end;
end module body.
```

Daneben `migrations/1-schema.sql`:

```sql file migrations/1-schema.sql
PRAGMA foreign_keys = ON;

CREATE TABLE users (
    id INTEGER PRIMARY KEY,
    name TEXT NOT NULL
) STRICT;
```

Die richtige Form:

```hilde
import Standard.Sqlite (Connection, Writing, SqlError, describe, openWriter, closeDatabase, migrate);

module body Example is
    record Person[R: Region]: Free is
        name: Span[Nat8, R];
    end;

    generic [R: Region]
    function run(db: &![Connection[Writing], R]): Unit is
        @query(&~db, "SELECT name FROM users") for row: Person[Q] do
            printLn(row.name);
        else error do
            printLn(describe(error));
        end for;
        return nil;
    end;

    function main(): ExitCode is
        case openWriter(":memory:") of
            when Left(left as error: SqlError) do
                printLn(describe(error));
                return ExitFailure();
            when Right(right as opened: Connection[Writing]) do
                var db: Connection[Writing] := opened;
                case migrate(&!db, @migrations) of
                    when Left(left as error: SqlError) do
                        printLn(describe(error));
                    when Right(right as applied: Index) do
                        run(&!db);
                end case;
                closeDatabase(db);
                return ExitSuccess();
        end case;
    end;
end module body.
```

Daneben `migrations/1-schema.sql`:

```sql file migrations/1-schema.sql
CREATE TABLE users (
    id INTEGER PRIMARY KEY,
    name TEXT NOT NULL
) STRICT;
```

### H8026

Meldung:

```text
Generic Error
@execute: a query is SELECT, INSERT, UPDATE or DELETE, not CREATE (line 1, column 1 of the SQL)
```

Eine Abfrage ist weder SELECT noch INSERT, UPDATE oder DELETE. Eine Tabelle
wird in einer Migration angelegt.

Dieses Modul scheitert mit H8026:

```hilde fails H8026
import Standard.Sqlite (Connection, Writing, SqlError, describe, openWriter, closeDatabase, migrate);

module body Example is
    generic [R: Region]
    function run(db: &![Connection[Writing], R]): Unit is
        let result: Either[SqlError, Nat64] := @execute(&~db, "CREATE TABLE tags (id INTEGER PRIMARY KEY, label TEXT NOT NULL) STRICT");
        case result of
            when Left(left as error: SqlError) do
                printLn(describe(error));
            when Right(right as changed: Nat64) do
                printLn(changed);
        end case;
        return nil;
    end;

    function main(): ExitCode is
        case openWriter(":memory:") of
            when Left(left as error: SqlError) do
                printLn(describe(error));
                return ExitFailure();
            when Right(right as opened: Connection[Writing]) do
                var db: Connection[Writing] := opened;
                case migrate(&!db, @migrations) of
                    when Left(left as error: SqlError) do
                        printLn(describe(error));
                    when Right(right as applied: Index) do
                        run(&!db);
                end case;
                closeDatabase(db);
                return ExitSuccess();
        end case;
    end;
end module body.
```

Die richtige Form:

```hilde
import Standard.Sqlite (Connection, Writing, SqlError, describe, openWriter, closeDatabase, migrate);

module body Example is
    generic [R: Region]
    function run(db: &![Connection[Writing], R]): Unit is
        let result: Either[SqlError, Nat64] := @execute(&~db, "INSERT INTO tags (label) VALUES (?)", "red");
        case result of
            when Left(left as error: SqlError) do
                printLn(describe(error));
            when Right(right as changed: Nat64) do
                printLn(changed);
        end case;
        return nil;
    end;

    function main(): ExitCode is
        case openWriter(":memory:") of
            when Left(left as error: SqlError) do
                printLn(describe(error));
                return ExitFailure();
            when Right(right as opened: Connection[Writing]) do
                var db: Connection[Writing] := opened;
                case migrate(&!db, @migrations) of
                    when Left(left as error: SqlError) do
                        printLn(describe(error));
                    when Right(right as applied: Index) do
                        run(&!db);
                end case;
                closeDatabase(db);
                return ExitSuccess();
        end case;
    end;
end module body.
```

Daneben `migrations/1-schema.sql`:

```sql file migrations/1-schema.sql
CREATE TABLE tags (
    id INTEGER PRIMARY KEY,
    label TEXT NOT NULL
) STRICT;
```

### H8027

Meldung:

```text
Generic Error
@query: there is no table user in the schema the migrations build (line 1, column 18 of the SQL)
```

Das SQL nennt eine Tabelle, die die Migrationen nicht anlegen.

Dieses Modul scheitert mit H8027:

```hilde fails H8027
import Standard.Sqlite (Connection, Writing, SqlError, describe, openWriter, closeDatabase, migrate);

module body Example is
    record Person[R: Region]: Free is
        name: Span[Nat8, R];
    end;

    generic [R: Region]
    function run(db: &![Connection[Writing], R]): Unit is
        @query(&~db, "SELECT name FROM user") for row: Person[Q] do
            printLn(row.name);
        else error do
            printLn(describe(error));
        end for;
        return nil;
    end;

    function main(): ExitCode is
        case openWriter(":memory:") of
            when Left(left as error: SqlError) do
                printLn(describe(error));
                return ExitFailure();
            when Right(right as opened: Connection[Writing]) do
                var db: Connection[Writing] := opened;
                case migrate(&!db, @migrations) of
                    when Left(left as error: SqlError) do
                        printLn(describe(error));
                    when Right(right as applied: Index) do
                        run(&!db);
                end case;
                closeDatabase(db);
                return ExitSuccess();
        end case;
    end;
end module body.
```

Die richtige Form:

```hilde
import Standard.Sqlite (Connection, Writing, SqlError, describe, openWriter, closeDatabase, migrate);

module body Example is
    record Person[R: Region]: Free is
        name: Span[Nat8, R];
    end;

    generic [R: Region]
    function run(db: &![Connection[Writing], R]): Unit is
        @query(&~db, "SELECT name FROM users") for row: Person[Q] do
            printLn(row.name);
        else error do
            printLn(describe(error));
        end for;
        return nil;
    end;

    function main(): ExitCode is
        case openWriter(":memory:") of
            when Left(left as error: SqlError) do
                printLn(describe(error));
                return ExitFailure();
            when Right(right as opened: Connection[Writing]) do
                var db: Connection[Writing] := opened;
                case migrate(&!db, @migrations) of
                    when Left(left as error: SqlError) do
                        printLn(describe(error));
                    when Right(right as applied: Index) do
                        run(&!db);
                end case;
                closeDatabase(db);
                return ExitSuccess();
        end case;
    end;
end module body.
```

### H8028

Meldung:

```text
Generic Error
@execute: table users has no column years (line 1, column 18 of the SQL)
```

Das SQL nennt eine Spalte, die die Tabelle nicht hat.

Dieses Modul scheitert mit H8028:

```hilde fails H8028
import Standard.Sqlite (Connection, Writing, SqlError, describe, openWriter, closeDatabase, migrate);

module body Example is
    generic [R: Region]
    function run(db: &![Connection[Writing], R]): Unit is
        let result: Either[SqlError, Nat64] := @execute(&~db, "UPDATE users SET years = ? WHERE id = ?", 41, 1);
        case result of
            when Left(left as error: SqlError) do
                printLn(describe(error));
            when Right(right as changed: Nat64) do
                printLn(changed);
        end case;
        return nil;
    end;

    function main(): ExitCode is
        case openWriter(":memory:") of
            when Left(left as error: SqlError) do
                printLn(describe(error));
                return ExitFailure();
            when Right(right as opened: Connection[Writing]) do
                var db: Connection[Writing] := opened;
                case migrate(&!db, @migrations) of
                    when Left(left as error: SqlError) do
                        printLn(describe(error));
                    when Right(right as applied: Index) do
                        run(&!db);
                end case;
                closeDatabase(db);
                return ExitSuccess();
        end case;
    end;
end module body.
```

Die richtige Form:

```hilde
import Standard.Sqlite (Connection, Writing, SqlError, describe, openWriter, closeDatabase, migrate);

module body Example is
    generic [R: Region]
    function run(db: &![Connection[Writing], R]): Unit is
        let result: Either[SqlError, Nat64] := @execute(&~db, "UPDATE users SET age = ? WHERE id = ?", 41, 1);
        case result of
            when Left(left as error: SqlError) do
                printLn(describe(error));
            when Right(right as changed: Nat64) do
                printLn(changed);
        end case;
        return nil;
    end;

    function main(): ExitCode is
        case openWriter(":memory:") of
            when Left(left as error: SqlError) do
                printLn(describe(error));
                return ExitFailure();
            when Right(right as opened: Connection[Writing]) do
                var db: Connection[Writing] := opened;
                case migrate(&!db, @migrations) of
                    when Left(left as error: SqlError) do
                        printLn(describe(error));
                    when Right(right as applied: Index) do
                        run(&!db);
                end case;
                closeDatabase(db);
                return ExitSuccess();
        end case;
    end;
end module body.
```

### H8029

Meldung:

```text
Generic Error
@query: the type of parameter 1 cannot be told from where it stands: compare it with a column, or put it where a column's value goes (line 1, column 33 of the SQL)
```

Ein Parameter steht, wo sich sein Typ nicht bestimmen lässt, etwa in ORDER
BY. Ein Parameter bekommt seinen Typ von einer Spalte, mit der er verglichen
oder in die er geschrieben wird.

Dieses Modul scheitert mit H8029:

```hilde fails H8029
import Standard.Sqlite (Connection, Writing, SqlError, describe, openWriter, closeDatabase, migrate);

module body Example is
    record Person[R: Region]: Free is
        name: Span[Nat8, R];
    end;

    generic [R: Region]
    function run(db: &![Connection[Writing], R]): Unit is
        @query(&~db, "SELECT name FROM users ORDER BY ?", "name") for row: Person[Q] do
            printLn(row.name);
        else error do
            printLn(describe(error));
        end for;
        return nil;
    end;

    function main(): ExitCode is
        case openWriter(":memory:") of
            when Left(left as error: SqlError) do
                printLn(describe(error));
                return ExitFailure();
            when Right(right as opened: Connection[Writing]) do
                var db: Connection[Writing] := opened;
                case migrate(&!db, @migrations) of
                    when Left(left as error: SqlError) do
                        printLn(describe(error));
                    when Right(right as applied: Index) do
                        run(&!db);
                end case;
                closeDatabase(db);
                return ExitSuccess();
        end case;
    end;
end module body.
```

Die richtige Form:

```hilde
import Standard.Sqlite (Connection, Writing, SqlError, describe, openWriter, closeDatabase, migrate);

module body Example is
    record Person[R: Region]: Free is
        name: Span[Nat8, R];
    end;

    generic [R: Region]
    function run(db: &![Connection[Writing], R]): Unit is
        @query(&~db, "SELECT name FROM users ORDER BY name") for row: Person[Q] do
            printLn(row.name);
        else error do
            printLn(describe(error));
        end for;
        return nil;
    end;

    function main(): ExitCode is
        case openWriter(":memory:") of
            when Left(left as error: SqlError) do
                printLn(describe(error));
                return ExitFailure();
            when Right(right as opened: Connection[Writing]) do
                var db: Connection[Writing] := opened;
                case migrate(&!db, @migrations) of
                    when Left(left as error: SqlError) do
                        printLn(describe(error));
                    when Right(right as applied: Index) do
                        run(&!db);
                end case;
                closeDatabase(db);
                return ExitSuccess();
        end case;
    end;
end module body.
```

### H8030

Meldung:

```text
Generic Error
@query: there is no table or alias u in this query (line 1, column 8 of the SQL)
```

Eine Spalte wird mit einer Tabelle oder einem Alias qualifiziert, die die
Abfrage nicht hat.

Dieses Modul scheitert mit H8030:

```hilde fails H8030
import Standard.Sqlite (Connection, Writing, SqlError, describe, openWriter, closeDatabase, migrate);

module body Example is
    record Person[R: Region]: Free is
        name: Span[Nat8, R];
    end;

    generic [R: Region]
    function run(db: &![Connection[Writing], R]): Unit is
        @query(&~db, "SELECT u.name FROM users") for row: Person[Q] do
            printLn(row.name);
        else error do
            printLn(describe(error));
        end for;
        return nil;
    end;

    function main(): ExitCode is
        case openWriter(":memory:") of
            when Left(left as error: SqlError) do
                printLn(describe(error));
                return ExitFailure();
            when Right(right as opened: Connection[Writing]) do
                var db: Connection[Writing] := opened;
                case migrate(&!db, @migrations) of
                    when Left(left as error: SqlError) do
                        printLn(describe(error));
                    when Right(right as applied: Index) do
                        run(&!db);
                end case;
                closeDatabase(db);
                return ExitSuccess();
        end case;
    end;
end module body.
```

Die richtige Form:

```hilde
import Standard.Sqlite (Connection, Writing, SqlError, describe, openWriter, closeDatabase, migrate);

module body Example is
    record Person[R: Region]: Free is
        name: Span[Nat8, R];
    end;

    generic [R: Region]
    function run(db: &![Connection[Writing], R]): Unit is
        @query(&~db, "SELECT u.name FROM users u") for row: Person[Q] do
            printLn(row.name);
        else error do
            printLn(describe(error));
        end for;
        return nil;
    end;

    function main(): ExitCode is
        case openWriter(":memory:") of
            when Left(left as error: SqlError) do
                printLn(describe(error));
                return ExitFailure();
            when Right(right as opened: Connection[Writing]) do
                var db: Connection[Writing] := opened;
                case migrate(&!db, @migrations) of
                    when Left(left as error: SqlError) do
                        printLn(describe(error));
                    when Right(right as applied: Index) do
                        run(&!db);
                end case;
                closeDatabase(db);
                return ExitSuccess();
        end case;
    end;
end module body.
```

### H8032

Meldung:

```text
Generic Error
@query: name: this query has no table to take a column from (line 1, column 8 of the SQL)
```

Eine Abfrage nennt eine Spalte und hat kein FROM, aus dem sie sie nehmen
könnte.

Dieses Modul scheitert mit H8032:

```hilde fails H8032
import Standard.Sqlite (Connection, Writing, SqlError, describe, openWriter, closeDatabase, migrate);

module body Example is
    record Person[R: Region]: Free is
        name: Span[Nat8, R];
    end;

    generic [R: Region]
    function run(db: &![Connection[Writing], R]): Unit is
        @query(&~db, "SELECT name") for row: Person[Q] do
            printLn(row.name);
        else error do
            printLn(describe(error));
        end for;
        return nil;
    end;

    function main(): ExitCode is
        case openWriter(":memory:") of
            when Left(left as error: SqlError) do
                printLn(describe(error));
                return ExitFailure();
            when Right(right as opened: Connection[Writing]) do
                var db: Connection[Writing] := opened;
                case migrate(&!db, @migrations) of
                    when Left(left as error: SqlError) do
                        printLn(describe(error));
                    when Right(right as applied: Index) do
                        run(&!db);
                end case;
                closeDatabase(db);
                return ExitSuccess();
        end case;
    end;
end module body.
```

Die richtige Form:

```hilde
import Standard.Sqlite (Connection, Writing, SqlError, describe, openWriter, closeDatabase, migrate);

module body Example is
    record Person[R: Region]: Free is
        name: Span[Nat8, R];
    end;

    generic [R: Region]
    function run(db: &![Connection[Writing], R]): Unit is
        @query(&~db, "SELECT name FROM users") for row: Person[Q] do
            printLn(row.name);
        else error do
            printLn(describe(error));
        end for;
        return nil;
    end;

    function main(): ExitCode is
        case openWriter(":memory:") of
            when Left(left as error: SqlError) do
                printLn(describe(error));
                return ExitFailure();
            when Right(right as opened: Connection[Writing]) do
                var db: Connection[Writing] := opened;
                case migrate(&!db, @migrations) of
                    when Left(left as error: SqlError) do
                        printLn(describe(error));
                    when Right(right as applied: Index) do
                        run(&!db);
                end case;
                closeDatabase(db);
                return ExitSuccess();
        end case;
    end;
end module body.
```

### H8033

Meldung:

```text
Generic Error
@query: no table of this query has a column mail (users) (line 1, column 30 of the SQL)
```

Keine Tabelle der Abfrage hat eine Spalte dieses Namens.

Dieses Modul scheitert mit H8033:

```hilde fails H8033
import Standard.Sqlite (Connection, Writing, SqlError, describe, openWriter, closeDatabase, migrate);

module body Example is
    record Person[R: Region]: Free is
        name: Span[Nat8, R];
    end;

    generic [R: Region]
    function run(db: &![Connection[Writing], R]): Unit is
        @query(&~db, "SELECT name FROM users WHERE mail IS NULL") for row: Person[Q] do
            printLn(row.name);
        else error do
            printLn(describe(error));
        end for;
        return nil;
    end;

    function main(): ExitCode is
        case openWriter(":memory:") of
            when Left(left as error: SqlError) do
                printLn(describe(error));
                return ExitFailure();
            when Right(right as opened: Connection[Writing]) do
                var db: Connection[Writing] := opened;
                case migrate(&!db, @migrations) of
                    when Left(left as error: SqlError) do
                        printLn(describe(error));
                    when Right(right as applied: Index) do
                        run(&!db);
                end case;
                closeDatabase(db);
                return ExitSuccess();
        end case;
    end;
end module body.
```

Die richtige Form:

```hilde
import Standard.Sqlite (Connection, Writing, SqlError, describe, openWriter, closeDatabase, migrate);

module body Example is
    record Person[R: Region]: Free is
        name: Span[Nat8, R];
    end;

    generic [R: Region]
    function run(db: &![Connection[Writing], R]): Unit is
        @query(&~db, "SELECT name FROM users WHERE email IS NULL") for row: Person[Q] do
            printLn(row.name);
        else error do
            printLn(describe(error));
        end for;
        return nil;
    end;

    function main(): ExitCode is
        case openWriter(":memory:") of
            when Left(left as error: SqlError) do
                printLn(describe(error));
                return ExitFailure();
            when Right(right as opened: Connection[Writing]) do
                var db: Connection[Writing] := opened;
                case migrate(&!db, @migrations) of
                    when Left(left as error: SqlError) do
                        printLn(describe(error));
                    when Right(right as applied: Index) do
                        run(&!db);
                end case;
                closeDatabase(db);
                return ExitSuccess();
        end case;
    end;
end module body.
```

### H8034

Meldung:

```text
Generic Error
@query: more than one table of this query has a column id: name the table, as in t.id (line 1, column 48 of the SQL)
```

Mehr als eine Tabelle der Abfrage hat eine Spalte dieses Namens. Man stellt
den Namen der Tabelle davor.

Dieses Modul scheitert mit H8034:

```hilde fails H8034
import Standard.Sqlite (Connection, Writing, SqlError, describe, openWriter, closeDatabase, migrate);

module body Example is
    record Person[R: Region]: Free is
        name: Span[Nat8, R];
    end;

    generic [R: Region]
    function run(db: &![Connection[Writing], R]): Unit is
        @query(&~db, "SELECT name FROM users JOIN notes ON user_id = id") for row: Person[Q] do
            printLn(row.name);
        else error do
            printLn(describe(error));
        end for;
        return nil;
    end;

    function main(): ExitCode is
        case openWriter(":memory:") of
            when Left(left as error: SqlError) do
                printLn(describe(error));
                return ExitFailure();
            when Right(right as opened: Connection[Writing]) do
                var db: Connection[Writing] := opened;
                case migrate(&!db, @migrations) of
                    when Left(left as error: SqlError) do
                        printLn(describe(error));
                    when Right(right as applied: Index) do
                        run(&!db);
                end case;
                closeDatabase(db);
                return ExitSuccess();
        end case;
    end;
end module body.
```

Die richtige Form:

```hilde
import Standard.Sqlite (Connection, Writing, SqlError, describe, openWriter, closeDatabase, migrate);

module body Example is
    record Person[R: Region]: Free is
        name: Span[Nat8, R];
    end;

    generic [R: Region]
    function run(db: &![Connection[Writing], R]): Unit is
        @query(&~db, "SELECT name FROM users JOIN notes ON notes.user_id = users.id") for row: Person[Q] do
            printLn(row.name);
        else error do
            printLn(describe(error));
        end for;
        return nil;
    end;

    function main(): ExitCode is
        case openWriter(":memory:") of
            when Left(left as error: SqlError) do
                printLn(describe(error));
                return ExitFailure();
            when Right(right as opened: Connection[Writing]) do
                var db: Connection[Writing] := opened;
                case migrate(&!db, @migrations) of
                    when Left(left as error: SqlError) do
                        printLn(describe(error));
                    when Right(right as applied: Index) do
                        run(&!db);
                end case;
                closeDatabase(db);
                return ExitSuccess();
        end case;
    end;
end module body.
```

### H8035

Meldung:

```text
Generic Error
@query: a sign in front of TEXT: only a number has one (line 1, column 33 of the SQL)
```

Ein Vorzeichen steht vor etwas, das keine Zahl ist.

Dieses Modul scheitert mit H8035:

```hilde fails H8035
import Standard.Sqlite (Connection, Writing, SqlError, describe, openWriter, closeDatabase, migrate);

module body Example is
    record Person[R: Region]: Free is
        name: Span[Nat8, R];
    end;

    generic [R: Region]
    function run(db: &![Connection[Writing], R]): Unit is
        @query(&~db, "SELECT name FROM users ORDER BY -name") for row: Person[Q] do
            printLn(row.name);
        else error do
            printLn(describe(error));
        end for;
        return nil;
    end;

    function main(): ExitCode is
        case openWriter(":memory:") of
            when Left(left as error: SqlError) do
                printLn(describe(error));
                return ExitFailure();
            when Right(right as opened: Connection[Writing]) do
                var db: Connection[Writing] := opened;
                case migrate(&!db, @migrations) of
                    when Left(left as error: SqlError) do
                        printLn(describe(error));
                    when Right(right as applied: Index) do
                        run(&!db);
                end case;
                closeDatabase(db);
                return ExitSuccess();
        end case;
    end;
end module body.
```

Die richtige Form:

```hilde
import Standard.Sqlite (Connection, Writing, SqlError, describe, openWriter, closeDatabase, migrate);

module body Example is
    record Person[R: Region]: Free is
        name: Span[Nat8, R];
    end;

    generic [R: Region]
    function run(db: &![Connection[Writing], R]): Unit is
        @query(&~db, "SELECT name FROM users ORDER BY name DESC") for row: Person[Q] do
            printLn(row.name);
        else error do
            printLn(describe(error));
        end for;
        return nil;
    end;

    function main(): ExitCode is
        case openWriter(":memory:") of
            when Left(left as error: SqlError) do
                printLn(describe(error));
                return ExitFailure();
            when Right(right as opened: Connection[Writing]) do
                var db: Connection[Writing] := opened;
                case migrate(&!db, @migrations) of
                    when Left(left as error: SqlError) do
                        printLn(describe(error));
                    when Right(right as applied: Index) do
                        run(&!db);
                end case;
                closeDatabase(db);
                return ExitSuccess();
        end case;
    end;
end module body.
```

### H8036

Meldung:

```text
Generic Error
@query: NOT of TEXT: NOT takes a condition (line 1, column 30 of the SQL)
```

NOT steht vor etwas, das keine Bedingung ist.

Dieses Modul scheitert mit H8036:

```hilde fails H8036
import Standard.Sqlite (Connection, Writing, SqlError, describe, openWriter, closeDatabase, migrate);

module body Example is
    record Person[R: Region]: Free is
        name: Span[Nat8, R];
    end;

    generic [R: Region]
    function run(db: &![Connection[Writing], R]): Unit is
        @query(&~db, "SELECT name FROM users WHERE NOT email") for row: Person[Q] do
            printLn(row.name);
        else error do
            printLn(describe(error));
        end for;
        return nil;
    end;

    function main(): ExitCode is
        case openWriter(":memory:") of
            when Left(left as error: SqlError) do
                printLn(describe(error));
                return ExitFailure();
            when Right(right as opened: Connection[Writing]) do
                var db: Connection[Writing] := opened;
                case migrate(&!db, @migrations) of
                    when Left(left as error: SqlError) do
                        printLn(describe(error));
                    when Right(right as applied: Index) do
                        run(&!db);
                end case;
                closeDatabase(db);
                return ExitSuccess();
        end case;
    end;
end module body.
```

Die richtige Form:

```hilde
import Standard.Sqlite (Connection, Writing, SqlError, describe, openWriter, closeDatabase, migrate);

module body Example is
    record Person[R: Region]: Free is
        name: Span[Nat8, R];
    end;

    generic [R: Region]
    function run(db: &![Connection[Writing], R]): Unit is
        @query(&~db, "SELECT name FROM users WHERE email IS NULL") for row: Person[Q] do
            printLn(row.name);
        else error do
            printLn(describe(error));
        end for;
        return nil;
    end;

    function main(): ExitCode is
        case openWriter(":memory:") of
            when Left(left as error: SqlError) do
                printLn(describe(error));
                return ExitFailure();
            when Right(right as opened: Connection[Writing]) do
                var db: Connection[Writing] := opened;
                case migrate(&!db, @migrations) of
                    when Left(left as error: SqlError) do
                        printLn(describe(error));
                    when Right(right as applied: Index) do
                        run(&!db);
                end case;
                closeDatabase(db);
                return ExitSuccess();
        end case;
    end;
end module body.
```

### H8037

Meldung:

```text
Generic Error
@query: % takes two INTEGERs (line 1, column 36 of the SQL)
```

% nimmt zwei INTEGER und bekommt ein REAL.

Dieses Modul scheitert mit H8037:

```hilde fails H8037
import Standard.Sqlite (Connection, Writing, SqlError, describe, openWriter, closeDatabase, migrate);

module body Example is
    record Person[R: Region]: Free is
        name: Span[Nat8, R];
    end;

    generic [R: Region]
    function run(db: &![Connection[Writing], R]): Unit is
        @query(&~db, "SELECT name FROM users WHERE score % 2 = 0") for row: Person[Q] do
            printLn(row.name);
        else error do
            printLn(describe(error));
        end for;
        return nil;
    end;

    function main(): ExitCode is
        case openWriter(":memory:") of
            when Left(left as error: SqlError) do
                printLn(describe(error));
                return ExitFailure();
            when Right(right as opened: Connection[Writing]) do
                var db: Connection[Writing] := opened;
                case migrate(&!db, @migrations) of
                    when Left(left as error: SqlError) do
                        printLn(describe(error));
                    when Right(right as applied: Index) do
                        run(&!db);
                end case;
                closeDatabase(db);
                return ExitSuccess();
        end case;
    end;
end module body.
```

Die richtige Form:

```hilde
import Standard.Sqlite (Connection, Writing, SqlError, describe, openWriter, closeDatabase, migrate);

module body Example is
    record Person[R: Region]: Free is
        name: Span[Nat8, R];
    end;

    generic [R: Region]
    function run(db: &![Connection[Writing], R]): Unit is
        @query(&~db, "SELECT name FROM users WHERE age % 2 = 0") for row: Person[Q] do
            printLn(row.name);
        else error do
            printLn(describe(error));
        end for;
        return nil;
    end;

    function main(): ExitCode is
        case openWriter(":memory:") of
            when Left(left as error: SqlError) do
                printLn(describe(error));
                return ExitFailure();
            when Right(right as opened: Connection[Writing]) do
                var db: Connection[Writing] := opened;
                case migrate(&!db, @migrations) of
                    when Left(left as error: SqlError) do
                        printLn(describe(error));
                    when Right(right as applied: Index) do
                        run(&!db);
                end case;
                closeDatabase(db);
                return ExitSuccess();
        end case;
    end;
end module body.
```

### H8038

Meldung:

```text
Generic Error
@query: INTEGER + TEXT: arithmetic takes numbers (INTEGER or REAL) (line 1, column 34 of the SQL)
```

Es wird mit etwas gerechnet, das keine Zahl ist.

Dieses Modul scheitert mit H8038:

```hilde fails H8038
import Standard.Sqlite (Connection, Writing, SqlError, describe, openWriter, closeDatabase, migrate);

module body Example is
    record Person[R: Region]: Free is
        name: Span[Nat8, R];
    end;

    generic [R: Region]
    function run(db: &![Connection[Writing], R]): Unit is
        @query(&~db, "SELECT name FROM users WHERE age + '1' > 18") for row: Person[Q] do
            printLn(row.name);
        else error do
            printLn(describe(error));
        end for;
        return nil;
    end;

    function main(): ExitCode is
        case openWriter(":memory:") of
            when Left(left as error: SqlError) do
                printLn(describe(error));
                return ExitFailure();
            when Right(right as opened: Connection[Writing]) do
                var db: Connection[Writing] := opened;
                case migrate(&!db, @migrations) of
                    when Left(left as error: SqlError) do
                        printLn(describe(error));
                    when Right(right as applied: Index) do
                        run(&!db);
                end case;
                closeDatabase(db);
                return ExitSuccess();
        end case;
    end;
end module body.
```

Die richtige Form:

```hilde
import Standard.Sqlite (Connection, Writing, SqlError, describe, openWriter, closeDatabase, migrate);

module body Example is
    record Person[R: Region]: Free is
        name: Span[Nat8, R];
    end;

    generic [R: Region]
    function run(db: &![Connection[Writing], R]): Unit is
        @query(&~db, "SELECT name FROM users WHERE age + 1 > 18") for row: Person[Q] do
            printLn(row.name);
        else error do
            printLn(describe(error));
        end for;
        return nil;
    end;

    function main(): ExitCode is
        case openWriter(":memory:") of
            when Left(left as error: SqlError) do
                printLn(describe(error));
                return ExitFailure();
            when Right(right as opened: Connection[Writing]) do
                var db: Connection[Writing] := opened;
                case migrate(&!db, @migrations) of
                    when Left(left as error: SqlError) do
                        printLn(describe(error));
                    when Right(right as applied: Index) do
                        run(&!db);
                end case;
                closeDatabase(db);
                return ExitSuccess();
        end case;
    end;
end module body.
```

### H8039

Meldung:

```text
Generic Error
@query: TEXT || INTEGER: || joins TEXT to TEXT (line 1, column 13 of the SQL)
```

`||` verbindet etwas, das kein TEXT ist.

Dieses Modul scheitert mit H8039:

```hilde fails H8039
import Standard.Sqlite (Connection, Writing, SqlError, describe, openWriter, closeDatabase, migrate);

module body Example is
    record Person[R: Region]: Free is
        name: Span[Nat8, R];
    end;

    generic [R: Region]
    function run(db: &![Connection[Writing], R]): Unit is
        @query(&~db, "SELECT name || age AS name FROM users") for row: Person[Q] do
            printLn(row.name);
        else error do
            printLn(describe(error));
        end for;
        return nil;
    end;

    function main(): ExitCode is
        case openWriter(":memory:") of
            when Left(left as error: SqlError) do
                printLn(describe(error));
                return ExitFailure();
            when Right(right as opened: Connection[Writing]) do
                var db: Connection[Writing] := opened;
                case migrate(&!db, @migrations) of
                    when Left(left as error: SqlError) do
                        printLn(describe(error));
                    when Right(right as applied: Index) do
                        run(&!db);
                end case;
                closeDatabase(db);
                return ExitSuccess();
        end case;
    end;
end module body.
```

Die richtige Form:

```hilde
import Standard.Sqlite (Connection, Writing, SqlError, describe, openWriter, closeDatabase, migrate);

module body Example is
    record Person[R: Region]: Free is
        name: Span[Nat8, R];
    end;

    generic [R: Region]
    function run(db: &![Connection[Writing], R]): Unit is
        @query(&~db, "SELECT name || '!' AS name FROM users") for row: Person[Q] do
            printLn(row.name);
        else error do
            printLn(describe(error));
        end for;
        return nil;
    end;

    function main(): ExitCode is
        case openWriter(":memory:") of
            when Left(left as error: SqlError) do
                printLn(describe(error));
                return ExitFailure();
            when Right(right as opened: Connection[Writing]) do
                var db: Connection[Writing] := opened;
                case migrate(&!db, @migrations) of
                    when Left(left as error: SqlError) do
                        printLn(describe(error));
                    when Right(right as applied: Index) do
                        run(&!db);
                end case;
                closeDatabase(db);
                return ExitSuccess();
        end case;
    end;
end module body.
```

### H8040

Meldung:

```text
Generic Error
@query: a comparison with NULL is never true: write IS NULL or IS NOT NULL (line 1, column 36 of the SQL)
```

Ein Wert wird mit = oder einem ähnlichen Operator mit NULL verglichen. Ein
solcher Vergleich ist nie wahr; man schreibt IS NULL oder IS NOT NULL.

Dieses Modul scheitert mit H8040:

```hilde fails H8040
import Standard.Sqlite (Connection, Writing, SqlError, describe, openWriter, closeDatabase, migrate);

module body Example is
    record Person[R: Region]: Free is
        name: Span[Nat8, R];
    end;

    generic [R: Region]
    function run(db: &![Connection[Writing], R]): Unit is
        @query(&~db, "SELECT name FROM users WHERE email = NULL") for row: Person[Q] do
            printLn(row.name);
        else error do
            printLn(describe(error));
        end for;
        return nil;
    end;

    function main(): ExitCode is
        case openWriter(":memory:") of
            when Left(left as error: SqlError) do
                printLn(describe(error));
                return ExitFailure();
            when Right(right as opened: Connection[Writing]) do
                var db: Connection[Writing] := opened;
                case migrate(&!db, @migrations) of
                    when Left(left as error: SqlError) do
                        printLn(describe(error));
                    when Right(right as applied: Index) do
                        run(&!db);
                end case;
                closeDatabase(db);
                return ExitSuccess();
        end case;
    end;
end module body.
```

Die richtige Form:

```hilde
import Standard.Sqlite (Connection, Writing, SqlError, describe, openWriter, closeDatabase, migrate);

module body Example is
    record Person[R: Region]: Free is
        name: Span[Nat8, R];
    end;

    generic [R: Region]
    function run(db: &![Connection[Writing], R]): Unit is
        @query(&~db, "SELECT name FROM users WHERE email IS NULL") for row: Person[Q] do
            printLn(row.name);
        else error do
            printLn(describe(error));
        end for;
        return nil;
    end;

    function main(): ExitCode is
        case openWriter(":memory:") of
            when Left(left as error: SqlError) do
                printLn(describe(error));
                return ExitFailure();
            when Right(right as opened: Connection[Writing]) do
                var db: Connection[Writing] := opened;
                case migrate(&!db, @migrations) of
                    when Left(left as error: SqlError) do
                        printLn(describe(error));
                    when Right(right as applied: Index) do
                        run(&!db);
                end case;
                closeDatabase(db);
                return ExitSuccess();
        end case;
    end;
end module body.
```

### H8041

Meldung:

```text
Generic Error
@query: TEXT = INTEGER: SQLite compares these without converting, and the answer is always the same (line 1, column 35 of the SQL)
```

Zwei Werte verschiedenen Typs werden verglichen, etwa TEXT mit INTEGER.
SQLite vergleicht sie, ohne umzuwandeln, und die Antwort hängt nie von den
Werten ab.

Dieses Modul scheitert mit H8041:

```hilde fails H8041
import Standard.Sqlite (Connection, Writing, SqlError, describe, openWriter, closeDatabase, migrate);

module body Example is
    record Person[R: Region]: Free is
        name: Span[Nat8, R];
    end;

    generic [R: Region]
    function run(db: &![Connection[Writing], R]): Unit is
        @query(&~db, "SELECT name FROM users WHERE name = 5") for row: Person[Q] do
            printLn(row.name);
        else error do
            printLn(describe(error));
        end for;
        return nil;
    end;

    function main(): ExitCode is
        case openWriter(":memory:") of
            when Left(left as error: SqlError) do
                printLn(describe(error));
                return ExitFailure();
            when Right(right as opened: Connection[Writing]) do
                var db: Connection[Writing] := opened;
                case migrate(&!db, @migrations) of
                    when Left(left as error: SqlError) do
                        printLn(describe(error));
                    when Right(right as applied: Index) do
                        run(&!db);
                end case;
                closeDatabase(db);
                return ExitSuccess();
        end case;
    end;
end module body.
```

Die richtige Form:

```hilde
import Standard.Sqlite (Connection, Writing, SqlError, describe, openWriter, closeDatabase, migrate);

module body Example is
    record Person[R: Region]: Free is
        name: Span[Nat8, R];
    end;

    generic [R: Region]
    function run(db: &![Connection[Writing], R]): Unit is
        @query(&~db, "SELECT name FROM users WHERE age = 5") for row: Person[Q] do
            printLn(row.name);
        else error do
            printLn(describe(error));
        end for;
        return nil;
    end;

    function main(): ExitCode is
        case openWriter(":memory:") of
            when Left(left as error: SqlError) do
                printLn(describe(error));
                return ExitFailure();
            when Right(right as opened: Connection[Writing]) do
                var db: Connection[Writing] := opened;
                case migrate(&!db, @migrations) of
                    when Left(left as error: SqlError) do
                        printLn(describe(error));
                    when Right(right as applied: Index) do
                        run(&!db);
                end case;
                closeDatabase(db);
                return ExitSuccess();
        end case;
    end;
end module body.
```

### H8042

Meldung:

```text
Generic Error
@query: TEXT IS INTEGER: the two can never be the same (line 1, column 35 of the SQL)
```

IS vergleicht zwei Werte verschiedenen Typs, die nie gleich sein können.

Dieses Modul scheitert mit H8042:

```hilde fails H8042
import Standard.Sqlite (Connection, Writing, SqlError, describe, openWriter, closeDatabase, migrate);

module body Example is
    record Person[R: Region]: Free is
        name: Span[Nat8, R];
    end;

    generic [R: Region]
    function run(db: &![Connection[Writing], R]): Unit is
        @query(&~db, "SELECT name FROM users WHERE name IS 5") for row: Person[Q] do
            printLn(row.name);
        else error do
            printLn(describe(error));
        end for;
        return nil;
    end;

    function main(): ExitCode is
        case openWriter(":memory:") of
            when Left(left as error: SqlError) do
                printLn(describe(error));
                return ExitFailure();
            when Right(right as opened: Connection[Writing]) do
                var db: Connection[Writing] := opened;
                case migrate(&!db, @migrations) of
                    when Left(left as error: SqlError) do
                        printLn(describe(error));
                    when Right(right as applied: Index) do
                        run(&!db);
                end case;
                closeDatabase(db);
                return ExitSuccess();
        end case;
    end;
end module body.
```

Die richtige Form:

```hilde
import Standard.Sqlite (Connection, Writing, SqlError, describe, openWriter, closeDatabase, migrate);

module body Example is
    record Person[R: Region]: Free is
        name: Span[Nat8, R];
    end;

    generic [R: Region]
    function run(db: &![Connection[Writing], R]): Unit is
        @query(&~db, "SELECT name FROM users WHERE age IS 5") for row: Person[Q] do
            printLn(row.name);
        else error do
            printLn(describe(error));
        end for;
        return nil;
    end;

    function main(): ExitCode is
        case openWriter(":memory:") of
            when Left(left as error: SqlError) do
                printLn(describe(error));
                return ExitFailure();
            when Right(right as opened: Connection[Writing]) do
                var db: Connection[Writing] := opened;
                case migrate(&!db, @migrations) of
                    when Left(left as error: SqlError) do
                        printLn(describe(error));
                    when Right(right as applied: Index) do
                        run(&!db);
                end case;
                closeDatabase(db);
                return ExitSuccess();
        end case;
    end;
end module body.
```

### H8043

Meldung:

```text
Generic Error
@query: a parameter tested for NULL: the value is known where it is given (line 1, column 32 of the SQL)
```

Ein Parameter wird auf NULL geprüft. Sein Wert ist dort bekannt, wo er
übergeben wird, im Programm.

Dieses Modul scheitert mit H8043:

```hilde fails H8043
import Standard.Sqlite (Connection, Writing, SqlError, describe, openWriter, closeDatabase, migrate);

module body Example is
    record Person[R: Region]: Free is
        name: Span[Nat8, R];
    end;

    generic [R: Region]
    function run(db: &![Connection[Writing], R]): Unit is
        @query(&~db, "SELECT name FROM users WHERE ? IS NULL", "ann") for row: Person[Q] do
            printLn(row.name);
        else error do
            printLn(describe(error));
        end for;
        return nil;
    end;

    function main(): ExitCode is
        case openWriter(":memory:") of
            when Left(left as error: SqlError) do
                printLn(describe(error));
                return ExitFailure();
            when Right(right as opened: Connection[Writing]) do
                var db: Connection[Writing] := opened;
                case migrate(&!db, @migrations) of
                    when Left(left as error: SqlError) do
                        printLn(describe(error));
                    when Right(right as applied: Index) do
                        run(&!db);
                end case;
                closeDatabase(db);
                return ExitSuccess();
        end case;
    end;
end module body.
```

Die richtige Form:

```hilde
import Standard.Sqlite (Connection, Writing, SqlError, describe, openWriter, closeDatabase, migrate);

module body Example is
    record Person[R: Region]: Free is
        name: Span[Nat8, R];
    end;

    generic [R: Region]
    function run(db: &![Connection[Writing], R]): Unit is
        @query(&~db, "SELECT name FROM users WHERE email IS NULL") for row: Person[Q] do
            printLn(row.name);
        else error do
            printLn(describe(error));
        end for;
        return nil;
    end;

    function main(): ExitCode is
        case openWriter(":memory:") of
            when Left(left as error: SqlError) do
                printLn(describe(error));
                return ExitFailure();
            when Right(right as opened: Connection[Writing]) do
                var db: Connection[Writing] := opened;
                case migrate(&!db, @migrations) of
                    when Left(left as error: SqlError) do
                        printLn(describe(error));
                    when Right(right as applied: Index) do
                        run(&!db);
                end case;
                closeDatabase(db);
                return ExitSuccess();
        end case;
    end;
end module body.
```

### H8044

Meldung:

```text
Generic Error
@query: INTEGER LIKE TEXT: LIKE compares TEXT with TEXT (line 1, column 34 of the SQL)
```

LIKE oder GLOB bekommt etwas, das kein TEXT ist.

Dieses Modul scheitert mit H8044:

```hilde fails H8044
import Standard.Sqlite (Connection, Writing, SqlError, describe, openWriter, closeDatabase, migrate);

module body Example is
    record Person[R: Region]: Free is
        name: Span[Nat8, R];
    end;

    generic [R: Region]
    function run(db: &![Connection[Writing], R]): Unit is
        @query(&~db, "SELECT name FROM users WHERE age LIKE '3%'") for row: Person[Q] do
            printLn(row.name);
        else error do
            printLn(describe(error));
        end for;
        return nil;
    end;

    function main(): ExitCode is
        case openWriter(":memory:") of
            when Left(left as error: SqlError) do
                printLn(describe(error));
                return ExitFailure();
            when Right(right as opened: Connection[Writing]) do
                var db: Connection[Writing] := opened;
                case migrate(&!db, @migrations) of
                    when Left(left as error: SqlError) do
                        printLn(describe(error));
                    when Right(right as applied: Index) do
                        run(&!db);
                end case;
                closeDatabase(db);
                return ExitSuccess();
        end case;
    end;
end module body.
```

Die richtige Form:

```hilde
import Standard.Sqlite (Connection, Writing, SqlError, describe, openWriter, closeDatabase, migrate);

module body Example is
    record Person[R: Region]: Free is
        name: Span[Nat8, R];
    end;

    generic [R: Region]
    function run(db: &![Connection[Writing], R]): Unit is
        @query(&~db, "SELECT name FROM users WHERE name LIKE 'A%'") for row: Person[Q] do
            printLn(row.name);
        else error do
            printLn(describe(error));
        end for;
        return nil;
    end;

    function main(): ExitCode is
        case openWriter(":memory:") of
            when Left(left as error: SqlError) do
                printLn(describe(error));
                return ExitFailure();
            when Right(right as opened: Connection[Writing]) do
                var db: Connection[Writing] := opened;
                case migrate(&!db, @migrations) of
                    when Left(left as error: SqlError) do
                        printLn(describe(error));
                    when Right(right as applied: Index) do
                        run(&!db);
                end case;
                closeDatabase(db);
                return ExitSuccess();
        end case;
    end;
end module body.
```

### H8045

Meldung:

```text
Generic Error
@query: a parameter on the left of IN: put a column there (line 1, column 32 of the SQL)
```

Ein Parameter steht links von IN. Dort steht eine Spalte.

Dieses Modul scheitert mit H8045:

```hilde fails H8045
import Standard.Sqlite (Connection, Writing, SqlError, describe, openWriter, closeDatabase, migrate);

module body Example is
    record Person[R: Region]: Free is
        name: Span[Nat8, R];
    end;

    generic [R: Region]
    function run(db: &![Connection[Writing], R]): Unit is
        @query(&~db, "SELECT name FROM users WHERE ? IN (name, email)", "ann") for row: Person[Q] do
            printLn(row.name);
        else error do
            printLn(describe(error));
        end for;
        return nil;
    end;

    function main(): ExitCode is
        case openWriter(":memory:") of
            when Left(left as error: SqlError) do
                printLn(describe(error));
                return ExitFailure();
            when Right(right as opened: Connection[Writing]) do
                var db: Connection[Writing] := opened;
                case migrate(&!db, @migrations) of
                    when Left(left as error: SqlError) do
                        printLn(describe(error));
                    when Right(right as applied: Index) do
                        run(&!db);
                end case;
                closeDatabase(db);
                return ExitSuccess();
        end case;
    end;
end module body.
```

Die richtige Form:

```hilde
import Standard.Sqlite (Connection, Writing, SqlError, describe, openWriter, closeDatabase, migrate);

module body Example is
    record Person[R: Region]: Free is
        name: Span[Nat8, R];
    end;

    generic [R: Region]
    function run(db: &![Connection[Writing], R]): Unit is
        @query(&~db, "SELECT name FROM users WHERE name = ? OR email = ?", "ann", "ann") for row: Person[Q] do
            printLn(row.name);
        else error do
            printLn(describe(error));
        end for;
        return nil;
    end;

    function main(): ExitCode is
        case openWriter(":memory:") of
            when Left(left as error: SqlError) do
                printLn(describe(error));
                return ExitFailure();
            when Right(right as opened: Connection[Writing]) do
                var db: Connection[Writing] := opened;
                case migrate(&!db, @migrations) of
                    when Left(left as error: SqlError) do
                        printLn(describe(error));
                    when Right(right as applied: Index) do
                        run(&!db);
                end case;
                closeDatabase(db);
                return ExitSuccess();
        end case;
    end;
end module body.
```

### H8046

Meldung:

```text
Generic Error
@query: NULL IN (...) is never true (line 1, column 35 of the SQL)
```

NULL steht links von IN. Das ist nie wahr.

Dieses Modul scheitert mit H8046:

```hilde fails H8046
import Standard.Sqlite (Connection, Writing, SqlError, describe, openWriter, closeDatabase, migrate);

module body Example is
    record Person[R: Region]: Free is
        name: Span[Nat8, R];
    end;

    generic [R: Region]
    function run(db: &![Connection[Writing], R]): Unit is
        @query(&~db, "SELECT name FROM users WHERE NULL IN (email, name)") for row: Person[Q] do
            printLn(row.name);
        else error do
            printLn(describe(error));
        end for;
        return nil;
    end;

    function main(): ExitCode is
        case openWriter(":memory:") of
            when Left(left as error: SqlError) do
                printLn(describe(error));
                return ExitFailure();
            when Right(right as opened: Connection[Writing]) do
                var db: Connection[Writing] := opened;
                case migrate(&!db, @migrations) of
                    when Left(left as error: SqlError) do
                        printLn(describe(error));
                    when Right(right as applied: Index) do
                        run(&!db);
                end case;
                closeDatabase(db);
                return ExitSuccess();
        end case;
    end;
end module body.
```

Die richtige Form:

```hilde
import Standard.Sqlite (Connection, Writing, SqlError, describe, openWriter, closeDatabase, migrate);

module body Example is
    record Person[R: Region]: Free is
        name: Span[Nat8, R];
    end;

    generic [R: Region]
    function run(db: &![Connection[Writing], R]): Unit is
        @query(&~db, "SELECT name FROM users WHERE email IS NULL") for row: Person[Q] do
            printLn(row.name);
        else error do
            printLn(describe(error));
        end for;
        return nil;
    end;

    function main(): ExitCode is
        case openWriter(":memory:") of
            when Left(left as error: SqlError) do
                printLn(describe(error));
                return ExitFailure();
            when Right(right as opened: Connection[Writing]) do
                var db: Connection[Writing] := opened;
                case migrate(&!db, @migrations) of
                    when Left(left as error: SqlError) do
                        printLn(describe(error));
                    when Right(right as applied: Index) do
                        run(&!db);
                end case;
                closeDatabase(db);
                return ExitSuccess();
        end case;
    end;
end module body.
```

### H8047

Meldung:

```text
Generic Error
@query: NULL in an IN list is never matched (line 1, column 59 of the SQL)
```

NULL steht in der Liste von IN. Es trifft nie zu.

Dieses Modul scheitert mit H8047:

```hilde fails H8047
import Standard.Sqlite (Connection, Writing, SqlError, describe, openWriter, closeDatabase, migrate);

module body Example is
    record Person[R: Region]: Free is
        name: Span[Nat8, R];
    end;

    generic [R: Region]
    function run(db: &![Connection[Writing], R]): Unit is
        @query(&~db, "SELECT name FROM users WHERE email IN ('ann@example.org', NULL)") for row: Person[Q] do
            printLn(row.name);
        else error do
            printLn(describe(error));
        end for;
        return nil;
    end;

    function main(): ExitCode is
        case openWriter(":memory:") of
            when Left(left as error: SqlError) do
                printLn(describe(error));
                return ExitFailure();
            when Right(right as opened: Connection[Writing]) do
                var db: Connection[Writing] := opened;
                case migrate(&!db, @migrations) of
                    when Left(left as error: SqlError) do
                        printLn(describe(error));
                    when Right(right as applied: Index) do
                        run(&!db);
                end case;
                closeDatabase(db);
                return ExitSuccess();
        end case;
    end;
end module body.
```

Die richtige Form:

```hilde
import Standard.Sqlite (Connection, Writing, SqlError, describe, openWriter, closeDatabase, migrate);

module body Example is
    record Person[R: Region]: Free is
        name: Span[Nat8, R];
    end;

    generic [R: Region]
    function run(db: &![Connection[Writing], R]): Unit is
        @query(&~db, "SELECT name FROM users WHERE email IN ('ann@example.org') OR email IS NULL") for row: Person[Q] do
            printLn(row.name);
        else error do
            printLn(describe(error));
        end for;
        return nil;
    end;

    function main(): ExitCode is
        case openWriter(":memory:") of
            when Left(left as error: SqlError) do
                printLn(describe(error));
                return ExitFailure();
            when Right(right as opened: Connection[Writing]) do
                var db: Connection[Writing] := opened;
                case migrate(&!db, @migrations) of
                    when Left(left as error: SqlError) do
                        printLn(describe(error));
                    when Right(right as applied: Index) do
                        run(&!db);
                end case;
                closeDatabase(db);
                return ExitSuccess();
        end case;
    end;
end module body.
```

### H8048

Meldung:

```text
Generic Error
@query: INTEGER IN (... TEXT ...): the two can never be equal (line 1, column 38 of the SQL)
```

Ein Wert in der Liste von IN hat einen anderen Typ als der Wert links, die
beiden können also nie gleich sein.

Dieses Modul scheitert mit H8048:

```hilde fails H8048
import Standard.Sqlite (Connection, Writing, SqlError, describe, openWriter, closeDatabase, migrate);

module body Example is
    record Person[R: Region]: Free is
        name: Span[Nat8, R];
    end;

    generic [R: Region]
    function run(db: &![Connection[Writing], R]): Unit is
        @query(&~db, "SELECT name FROM users WHERE age IN ('18', '21')") for row: Person[Q] do
            printLn(row.name);
        else error do
            printLn(describe(error));
        end for;
        return nil;
    end;

    function main(): ExitCode is
        case openWriter(":memory:") of
            when Left(left as error: SqlError) do
                printLn(describe(error));
                return ExitFailure();
            when Right(right as opened: Connection[Writing]) do
                var db: Connection[Writing] := opened;
                case migrate(&!db, @migrations) of
                    when Left(left as error: SqlError) do
                        printLn(describe(error));
                    when Right(right as applied: Index) do
                        run(&!db);
                end case;
                closeDatabase(db);
                return ExitSuccess();
        end case;
    end;
end module body.
```

Die richtige Form:

```hilde
import Standard.Sqlite (Connection, Writing, SqlError, describe, openWriter, closeDatabase, migrate);

module body Example is
    record Person[R: Region]: Free is
        name: Span[Nat8, R];
    end;

    generic [R: Region]
    function run(db: &![Connection[Writing], R]): Unit is
        @query(&~db, "SELECT name FROM users WHERE age IN (18, 21)") for row: Person[Q] do
            printLn(row.name);
        else error do
            printLn(describe(error));
        end for;
        return nil;
    end;

    function main(): ExitCode is
        case openWriter(":memory:") of
            when Left(left as error: SqlError) do
                printLn(describe(error));
                return ExitFailure();
            when Right(right as opened: Connection[Writing]) do
                var db: Connection[Writing] := opened;
                case migrate(&!db, @migrations) of
                    when Left(left as error: SqlError) do
                        printLn(describe(error));
                    when Right(right as applied: Index) do
                        run(&!db);
                end case;
                closeDatabase(db);
                return ExitSuccess();
        end case;
    end;
end module body.
```

### H8049

Meldung:

```text
Generic Error
@query: a parameter on the left of BETWEEN: put a column there (line 1, column 32 of the SQL)
```

Ein Parameter steht links von BETWEEN. Dort steht eine Spalte.

Dieses Modul scheitert mit H8049:

```hilde fails H8049
import Standard.Sqlite (Connection, Writing, SqlError, describe, openWriter, closeDatabase, migrate);

module body Example is
    record Person[R: Region]: Free is
        name: Span[Nat8, R];
    end;

    generic [R: Region]
    function run(db: &![Connection[Writing], R]): Unit is
        @query(&~db, "SELECT name FROM users WHERE ? BETWEEN age AND 99", 18) for row: Person[Q] do
            printLn(row.name);
        else error do
            printLn(describe(error));
        end for;
        return nil;
    end;

    function main(): ExitCode is
        case openWriter(":memory:") of
            when Left(left as error: SqlError) do
                printLn(describe(error));
                return ExitFailure();
            when Right(right as opened: Connection[Writing]) do
                var db: Connection[Writing] := opened;
                case migrate(&!db, @migrations) of
                    when Left(left as error: SqlError) do
                        printLn(describe(error));
                    when Right(right as applied: Index) do
                        run(&!db);
                end case;
                closeDatabase(db);
                return ExitSuccess();
        end case;
    end;
end module body.
```

Die richtige Form:

```hilde
import Standard.Sqlite (Connection, Writing, SqlError, describe, openWriter, closeDatabase, migrate);

module body Example is
    record Person[R: Region]: Free is
        name: Span[Nat8, R];
    end;

    generic [R: Region]
    function run(db: &![Connection[Writing], R]): Unit is
        @query(&~db, "SELECT name FROM users WHERE age BETWEEN ? AND 99", 18) for row: Person[Q] do
            printLn(row.name);
        else error do
            printLn(describe(error));
        end for;
        return nil;
    end;

    function main(): ExitCode is
        case openWriter(":memory:") of
            when Left(left as error: SqlError) do
                printLn(describe(error));
                return ExitFailure();
            when Right(right as opened: Connection[Writing]) do
                var db: Connection[Writing] := opened;
                case migrate(&!db, @migrations) of
                    when Left(left as error: SqlError) do
                        printLn(describe(error));
                    when Right(right as applied: Index) do
                        run(&!db);
                end case;
                closeDatabase(db);
                return ExitSuccess();
        end case;
    end;
end module body.
```

### H8050

Meldung:

```text
Generic Error
@query: NULL BETWEEN ... is never true (line 1, column 35 of the SQL)
```

NULL steht links von BETWEEN. Das ist nie wahr.

Dieses Modul scheitert mit H8050:

```hilde fails H8050
import Standard.Sqlite (Connection, Writing, SqlError, describe, openWriter, closeDatabase, migrate);

module body Example is
    record Person[R: Region]: Free is
        name: Span[Nat8, R];
    end;

    generic [R: Region]
    function run(db: &![Connection[Writing], R]): Unit is
        @query(&~db, "SELECT name FROM users WHERE NULL BETWEEN 1 AND 2") for row: Person[Q] do
            printLn(row.name);
        else error do
            printLn(describe(error));
        end for;
        return nil;
    end;

    function main(): ExitCode is
        case openWriter(":memory:") of
            when Left(left as error: SqlError) do
                printLn(describe(error));
                return ExitFailure();
            when Right(right as opened: Connection[Writing]) do
                var db: Connection[Writing] := opened;
                case migrate(&!db, @migrations) of
                    when Left(left as error: SqlError) do
                        printLn(describe(error));
                    when Right(right as applied: Index) do
                        run(&!db);
                end case;
                closeDatabase(db);
                return ExitSuccess();
        end case;
    end;
end module body.
```

Die richtige Form:

```hilde
import Standard.Sqlite (Connection, Writing, SqlError, describe, openWriter, closeDatabase, migrate);

module body Example is
    record Person[R: Region]: Free is
        name: Span[Nat8, R];
    end;

    generic [R: Region]
    function run(db: &![Connection[Writing], R]): Unit is
        @query(&~db, "SELECT name FROM users WHERE age BETWEEN 1 AND 2") for row: Person[Q] do
            printLn(row.name);
        else error do
            printLn(describe(error));
        end for;
        return nil;
    end;

    function main(): ExitCode is
        case openWriter(":memory:") of
            when Left(left as error: SqlError) do
                printLn(describe(error));
                return ExitFailure();
            when Right(right as opened: Connection[Writing]) do
                var db: Connection[Writing] := opened;
                case migrate(&!db, @migrations) of
                    when Left(left as error: SqlError) do
                        printLn(describe(error));
                    when Right(right as applied: Index) do
                        run(&!db);
                end case;
                closeDatabase(db);
                return ExitSuccess();
        end case;
    end;
end module body.
```

### H8051

Meldung:

```text
Generic Error
@query: BETWEEN compares INTEGER with TEXT (line 1, column 42 of the SQL)
```

Eine Grenze von BETWEEN hat einen anderen Typ als der Wert, mit dem sie
verglichen wird.

Dieses Modul scheitert mit H8051:

```hilde fails H8051
import Standard.Sqlite (Connection, Writing, SqlError, describe, openWriter, closeDatabase, migrate);

module body Example is
    record Person[R: Region]: Free is
        name: Span[Nat8, R];
    end;

    generic [R: Region]
    function run(db: &![Connection[Writing], R]): Unit is
        @query(&~db, "SELECT name FROM users WHERE age BETWEEN '18' AND '65'") for row: Person[Q] do
            printLn(row.name);
        else error do
            printLn(describe(error));
        end for;
        return nil;
    end;

    function main(): ExitCode is
        case openWriter(":memory:") of
            when Left(left as error: SqlError) do
                printLn(describe(error));
                return ExitFailure();
            when Right(right as opened: Connection[Writing]) do
                var db: Connection[Writing] := opened;
                case migrate(&!db, @migrations) of
                    when Left(left as error: SqlError) do
                        printLn(describe(error));
                    when Right(right as applied: Index) do
                        run(&!db);
                end case;
                closeDatabase(db);
                return ExitSuccess();
        end case;
    end;
end module body.
```

Die richtige Form:

```hilde
import Standard.Sqlite (Connection, Writing, SqlError, describe, openWriter, closeDatabase, migrate);

module body Example is
    record Person[R: Region]: Free is
        name: Span[Nat8, R];
    end;

    generic [R: Region]
    function run(db: &![Connection[Writing], R]): Unit is
        @query(&~db, "SELECT name FROM users WHERE age BETWEEN 18 AND 65") for row: Person[Q] do
            printLn(row.name);
        else error do
            printLn(describe(error));
        end for;
        return nil;
    end;

    function main(): ExitCode is
        case openWriter(":memory:") of
            when Left(left as error: SqlError) do
                printLn(describe(error));
                return ExitFailure();
            when Right(right as opened: Connection[Writing]) do
                var db: Connection[Writing] := opened;
                case migrate(&!db, @migrations) of
                    when Left(left as error: SqlError) do
                        printLn(describe(error));
                    when Right(right as applied: Index) do
                        run(&!db);
                end case;
                closeDatabase(db);
                return ExitSuccess();
        end case;
    end;
end module body.
```

### H8052

Meldung:

```text
Generic Error
@query: INTEGER AND TEXT: AND joins conditions (line 1, column 39 of the SQL)
```

AND oder OR verbindet etwas, das keine Bedingung ist.

Dieses Modul scheitert mit H8052:

```hilde fails H8052
import Standard.Sqlite (Connection, Writing, SqlError, describe, openWriter, closeDatabase, migrate);

module body Example is
    record Person[R: Region]: Free is
        name: Span[Nat8, R];
    end;

    generic [R: Region]
    function run(db: &![Connection[Writing], R]): Unit is
        @query(&~db, "SELECT name FROM users WHERE age > 18 AND email") for row: Person[Q] do
            printLn(row.name);
        else error do
            printLn(describe(error));
        end for;
        return nil;
    end;

    function main(): ExitCode is
        case openWriter(":memory:") of
            when Left(left as error: SqlError) do
                printLn(describe(error));
                return ExitFailure();
            when Right(right as opened: Connection[Writing]) do
                var db: Connection[Writing] := opened;
                case migrate(&!db, @migrations) of
                    when Left(left as error: SqlError) do
                        printLn(describe(error));
                    when Right(right as applied: Index) do
                        run(&!db);
                end case;
                closeDatabase(db);
                return ExitSuccess();
        end case;
    end;
end module body.
```

Die richtige Form:

```hilde
import Standard.Sqlite (Connection, Writing, SqlError, describe, openWriter, closeDatabase, migrate);

module body Example is
    record Person[R: Region]: Free is
        name: Span[Nat8, R];
    end;

    generic [R: Region]
    function run(db: &![Connection[Writing], R]): Unit is
        @query(&~db, "SELECT name FROM users WHERE age > 18 AND email IS NOT NULL") for row: Person[Q] do
            printLn(row.name);
        else error do
            printLn(describe(error));
        end for;
        return nil;
    end;

    function main(): ExitCode is
        case openWriter(":memory:") of
            when Left(left as error: SqlError) do
                printLn(describe(error));
                return ExitFailure();
            when Right(right as opened: Connection[Writing]) do
                var db: Connection[Writing] := opened;
                case migrate(&!db, @migrations) of
                    when Left(left as error: SqlError) do
                        printLn(describe(error));
                    when Right(right as applied: Index) do
                        run(&!db);
                end case;
                closeDatabase(db);
                return ExitSuccess();
        end case;
    end;
end module body.
```

### H8053

Meldung:

```text
Generic Error
@query: count(*) here: an aggregate stands in the columns, HAVING or ORDER BY (line 1, column 30 of the SQL)
```

`count(*)` steht außerhalb der Spalten, von HAVING und ORDER BY, etwa in
WHERE.

Dieses Modul scheitert mit H8053:

```hilde fails H8053
import Standard.Sqlite (Connection, Writing, SqlError, describe, openWriter, closeDatabase, migrate);

module body Example is
    record Person[R: Region]: Free is
        name: Span[Nat8, R];
    end;

    generic [R: Region]
    function run(db: &![Connection[Writing], R]): Unit is
        @query(&~db, "SELECT name FROM users WHERE count(*) > 1") for row: Person[Q] do
            printLn(row.name);
        else error do
            printLn(describe(error));
        end for;
        return nil;
    end;

    function main(): ExitCode is
        case openWriter(":memory:") of
            when Left(left as error: SqlError) do
                printLn(describe(error));
                return ExitFailure();
            when Right(right as opened: Connection[Writing]) do
                var db: Connection[Writing] := opened;
                case migrate(&!db, @migrations) of
                    when Left(left as error: SqlError) do
                        printLn(describe(error));
                    when Right(right as applied: Index) do
                        run(&!db);
                end case;
                closeDatabase(db);
                return ExitSuccess();
        end case;
    end;
end module body.
```

Die richtige Form:

```hilde
import Standard.Sqlite (Connection, Writing, SqlError, describe, openWriter, closeDatabase, migrate);

module body Example is
    record Person[R: Region]: Free is
        name: Span[Nat8, R];
    end;

    generic [R: Region]
    function run(db: &![Connection[Writing], R]): Unit is
        @query(&~db, "SELECT name FROM users GROUP BY name HAVING count(*) > 1") for row: Person[Q] do
            printLn(row.name);
        else error do
            printLn(describe(error));
        end for;
        return nil;
    end;

    function main(): ExitCode is
        case openWriter(":memory:") of
            when Left(left as error: SqlError) do
                printLn(describe(error));
                return ExitFailure();
            when Right(right as opened: Connection[Writing]) do
                var db: Connection[Writing] := opened;
                case migrate(&!db, @migrations) of
                    when Left(left as error: SqlError) do
                        printLn(describe(error));
                    when Right(right as applied: Index) do
                        run(&!db);
                end case;
                closeDatabase(db);
                return ExitSuccess();
        end case;
    end;
end module body.
```

### H8054

Meldung:

```text
Generic Error
@query: max() here: an aggregate stands in the columns, HAVING or ORDER BY (line 1, column 30 of the SQL)
```

Eine Aggregatfunktion steht außerhalb der Spalten, von HAVING und ORDER BY,
etwa in WHERE.

Dieses Modul scheitert mit H8054:

```hilde fails H8054
import Standard.Sqlite (Connection, Writing, SqlError, describe, openWriter, closeDatabase, migrate);

module body Example is
    record Person[R: Region]: Free is
        name: Span[Nat8, R];
    end;

    generic [R: Region]
    function run(db: &![Connection[Writing], R]): Unit is
        @query(&~db, "SELECT name FROM users WHERE max(age) > 50") for row: Person[Q] do
            printLn(row.name);
        else error do
            printLn(describe(error));
        end for;
        return nil;
    end;

    function main(): ExitCode is
        case openWriter(":memory:") of
            when Left(left as error: SqlError) do
                printLn(describe(error));
                return ExitFailure();
            when Right(right as opened: Connection[Writing]) do
                var db: Connection[Writing] := opened;
                case migrate(&!db, @migrations) of
                    when Left(left as error: SqlError) do
                        printLn(describe(error));
                    when Right(right as applied: Index) do
                        run(&!db);
                end case;
                closeDatabase(db);
                return ExitSuccess();
        end case;
    end;
end module body.
```

Die richtige Form:

```hilde
import Standard.Sqlite (Connection, Writing, SqlError, describe, openWriter, closeDatabase, migrate);

module body Example is
    record Person[R: Region]: Free is
        name: Span[Nat8, R];
    end;

    generic [R: Region]
    function run(db: &![Connection[Writing], R]): Unit is
        @query(&~db, "SELECT name FROM users GROUP BY name HAVING max(age) > 50") for row: Person[Q] do
            printLn(row.name);
        else error do
            printLn(describe(error));
        end for;
        return nil;
    end;

    function main(): ExitCode is
        case openWriter(":memory:") of
            when Left(left as error: SqlError) do
                printLn(describe(error));
                return ExitFailure();
            when Right(right as opened: Connection[Writing]) do
                var db: Connection[Writing] := opened;
                case migrate(&!db, @migrations) of
                    when Left(left as error: SqlError) do
                        printLn(describe(error));
                    when Right(right as applied: Index) do
                        run(&!db);
                end case;
                closeDatabase(db);
                return ExitSuccess();
        end case;
    end;
end module body.
```

### H8055

Meldung:

```text
Generic Error
@query: DISTINCT inside a function that is not an aggregate (line 1, column 8 of the SQL)
```

DISTINCT steht in einer Funktion, die keine Aggregatfunktion ist.

Dieses Modul scheitert mit H8055:

```hilde fails H8055
import Standard.Sqlite (Connection, Writing, SqlError, describe, openWriter, closeDatabase, migrate);

module body Example is
    record Person[R: Region]: Free is
        name: Span[Nat8, R];
    end;

    generic [R: Region]
    function run(db: &![Connection[Writing], R]): Unit is
        @query(&~db, "SELECT upper(DISTINCT name) AS name FROM users") for row: Person[Q] do
            printLn(row.name);
        else error do
            printLn(describe(error));
        end for;
        return nil;
    end;

    function main(): ExitCode is
        case openWriter(":memory:") of
            when Left(left as error: SqlError) do
                printLn(describe(error));
                return ExitFailure();
            when Right(right as opened: Connection[Writing]) do
                var db: Connection[Writing] := opened;
                case migrate(&!db, @migrations) of
                    when Left(left as error: SqlError) do
                        printLn(describe(error));
                    when Right(right as applied: Index) do
                        run(&!db);
                end case;
                closeDatabase(db);
                return ExitSuccess();
        end case;
    end;
end module body.
```

Die richtige Form:

```hilde
import Standard.Sqlite (Connection, Writing, SqlError, describe, openWriter, closeDatabase, migrate);

module body Example is
    record Person[R: Region]: Free is
        name: Span[Nat8, R];
    end;

    generic [R: Region]
    function run(db: &![Connection[Writing], R]): Unit is
        @query(&~db, "SELECT DISTINCT upper(name) AS name FROM users") for row: Person[Q] do
            printLn(row.name);
        else error do
            printLn(describe(error));
        end for;
        return nil;
    end;

    function main(): ExitCode is
        case openWriter(":memory:") of
            when Left(left as error: SqlError) do
                printLn(describe(error));
                return ExitFailure();
            when Right(right as opened: Connection[Writing]) do
                var db: Connection[Writing] := opened;
                case migrate(&!db, @migrations) of
                    when Left(left as error: SqlError) do
                        printLn(describe(error));
                    when Right(right as applied: Index) do
                        run(&!db);
                end case;
                closeDatabase(db);
                return ExitSuccess();
        end case;
    end;
end module body.
```

### H8056

Meldung:

```text
Generic Error
@query: count() takes one argument here (line 1, column 8 of the SQL)
```

Eine Funktion, die hier ein Argument nimmt, bekommt eine andere Anzahl.

Dieses Modul scheitert mit H8056:

```hilde fails H8056
import Standard.Sqlite (Connection, Writing, SqlError, describe, openWriter, closeDatabase, migrate);

module body Example is
    record Tally: Free is
        total: Int64;
    end;

    generic [R: Region]
    function run(db: &![Connection[Writing], R]): Unit is
        @query(&~db, "SELECT count(name, email) AS total FROM users") for row: Tally do
            printLn(row.total);
        else error do
            printLn(describe(error));
        end for;
        return nil;
    end;

    function main(): ExitCode is
        case openWriter(":memory:") of
            when Left(left as error: SqlError) do
                printLn(describe(error));
                return ExitFailure();
            when Right(right as opened: Connection[Writing]) do
                var db: Connection[Writing] := opened;
                case migrate(&!db, @migrations) of
                    when Left(left as error: SqlError) do
                        printLn(describe(error));
                    when Right(right as applied: Index) do
                        run(&!db);
                end case;
                closeDatabase(db);
                return ExitSuccess();
        end case;
    end;
end module body.
```

Die richtige Form:

```hilde
import Standard.Sqlite (Connection, Writing, SqlError, describe, openWriter, closeDatabase, migrate);

module body Example is
    record Tally: Free is
        total: Int64;
    end;

    generic [R: Region]
    function run(db: &![Connection[Writing], R]): Unit is
        @query(&~db, "SELECT count(email) AS total FROM users") for row: Tally do
            printLn(row.total);
        else error do
            printLn(describe(error));
        end for;
        return nil;
    end;

    function main(): ExitCode is
        case openWriter(":memory:") of
            when Left(left as error: SqlError) do
                printLn(describe(error));
                return ExitFailure();
            when Right(right as opened: Connection[Writing]) do
                var db: Connection[Writing] := opened;
                case migrate(&!db, @migrations) of
                    when Left(left as error: SqlError) do
                        printLn(describe(error));
                    when Right(right as applied: Index) do
                        run(&!db);
                end case;
                closeDatabase(db);
                return ExitSuccess();
        end case;
    end;
end module body.
```

### H8057

Meldung:

```text
Generic Error
@query: abs() of TEXT: it takes a number (line 1, column 30 of the SQL)
```

Eine Funktion, die eine Zahl nimmt, etwa abs oder sum, bekommt etwas
anderes.

Dieses Modul scheitert mit H8057:

```hilde fails H8057
import Standard.Sqlite (Connection, Writing, SqlError, describe, openWriter, closeDatabase, migrate);

module body Example is
    record Person[R: Region]: Free is
        name: Span[Nat8, R];
    end;

    generic [R: Region]
    function run(db: &![Connection[Writing], R]): Unit is
        @query(&~db, "SELECT name FROM users WHERE abs(name) > 1") for row: Person[Q] do
            printLn(row.name);
        else error do
            printLn(describe(error));
        end for;
        return nil;
    end;

    function main(): ExitCode is
        case openWriter(":memory:") of
            when Left(left as error: SqlError) do
                printLn(describe(error));
                return ExitFailure();
            when Right(right as opened: Connection[Writing]) do
                var db: Connection[Writing] := opened;
                case migrate(&!db, @migrations) of
                    when Left(left as error: SqlError) do
                        printLn(describe(error));
                    when Right(right as applied: Index) do
                        run(&!db);
                end case;
                closeDatabase(db);
                return ExitSuccess();
        end case;
    end;
end module body.
```

Die richtige Form:

```hilde
import Standard.Sqlite (Connection, Writing, SqlError, describe, openWriter, closeDatabase, migrate);

module body Example is
    record Person[R: Region]: Free is
        name: Span[Nat8, R];
    end;

    generic [R: Region]
    function run(db: &![Connection[Writing], R]): Unit is
        @query(&~db, "SELECT name FROM users WHERE abs(age - 40) < 10") for row: Person[Q] do
            printLn(row.name);
        else error do
            printLn(describe(error));
        end for;
        return nil;
    end;

    function main(): ExitCode is
        case openWriter(":memory:") of
            when Left(left as error: SqlError) do
                printLn(describe(error));
                return ExitFailure();
            when Right(right as opened: Connection[Writing]) do
                var db: Connection[Writing] := opened;
                case migrate(&!db, @migrations) of
                    when Left(left as error: SqlError) do
                        printLn(describe(error));
                    when Right(right as applied: Index) do
                        run(&!db);
                end case;
                closeDatabase(db);
                return ExitSuccess();
        end case;
    end;
end module body.
```

### H8058

Meldung:

```text
Generic Error
@query: count() of a parameter (line 1, column 8 of the SQL)
```

count bekommt einen Parameter.

Dieses Modul scheitert mit H8058:

```hilde fails H8058
import Standard.Sqlite (Connection, Writing, SqlError, describe, openWriter, closeDatabase, migrate);

module body Example is
    record Tally: Free is
        total: Int64;
    end;

    generic [R: Region]
    function run(db: &![Connection[Writing], R]): Unit is
        @query(&~db, "SELECT count(?) AS total FROM users", "x") for row: Tally do
            printLn(row.total);
        else error do
            printLn(describe(error));
        end for;
        return nil;
    end;

    function main(): ExitCode is
        case openWriter(":memory:") of
            when Left(left as error: SqlError) do
                printLn(describe(error));
                return ExitFailure();
            when Right(right as opened: Connection[Writing]) do
                var db: Connection[Writing] := opened;
                case migrate(&!db, @migrations) of
                    when Left(left as error: SqlError) do
                        printLn(describe(error));
                    when Right(right as applied: Index) do
                        run(&!db);
                end case;
                closeDatabase(db);
                return ExitSuccess();
        end case;
    end;
end module body.
```

Die richtige Form:

```hilde
import Standard.Sqlite (Connection, Writing, SqlError, describe, openWriter, closeDatabase, migrate);

module body Example is
    record Tally: Free is
        total: Int64;
    end;

    generic [R: Region]
    function run(db: &![Connection[Writing], R]): Unit is
        @query(&~db, "SELECT count(*) AS total FROM users") for row: Tally do
            printLn(row.total);
        else error do
            printLn(describe(error));
        end for;
        return nil;
    end;

    function main(): ExitCode is
        case openWriter(":memory:") of
            when Left(left as error: SqlError) do
                printLn(describe(error));
                return ExitFailure();
            when Right(right as opened: Connection[Writing]) do
                var db: Connection[Writing] := opened;
                case migrate(&!db, @migrations) of
                    when Left(left as error: SqlError) do
                        printLn(describe(error));
                    when Right(right as applied: Index) do
                        run(&!db);
                end case;
                closeDatabase(db);
                return ExitSuccess();
        end case;
    end;
end module body.
```

### H8059

Meldung:

```text
Generic Error
@query: max() of a parameter (line 1, column 45 of the SQL)
```

min oder max bekommt einen Parameter.

Dieses Modul scheitert mit H8059:

```hilde fails H8059
import Standard.Sqlite (Connection, Writing, SqlError, describe, openWriter, closeDatabase, migrate);

module body Example is
    record Person[R: Region]: Free is
        name: Span[Nat8, R];
    end;

    generic [R: Region]
    function run(db: &![Connection[Writing], R]): Unit is
        @query(&~db, "SELECT name FROM users GROUP BY name HAVING max(?) > 1", 1) for row: Person[Q] do
            printLn(row.name);
        else error do
            printLn(describe(error));
        end for;
        return nil;
    end;

    function main(): ExitCode is
        case openWriter(":memory:") of
            when Left(left as error: SqlError) do
                printLn(describe(error));
                return ExitFailure();
            when Right(right as opened: Connection[Writing]) do
                var db: Connection[Writing] := opened;
                case migrate(&!db, @migrations) of
                    when Left(left as error: SqlError) do
                        printLn(describe(error));
                    when Right(right as applied: Index) do
                        run(&!db);
                end case;
                closeDatabase(db);
                return ExitSuccess();
        end case;
    end;
end module body.
```

Die richtige Form:

```hilde
import Standard.Sqlite (Connection, Writing, SqlError, describe, openWriter, closeDatabase, migrate);

module body Example is
    record Person[R: Region]: Free is
        name: Span[Nat8, R];
    end;

    generic [R: Region]
    function run(db: &![Connection[Writing], R]): Unit is
        @query(&~db, "SELECT name FROM users GROUP BY name HAVING max(age) > ?", 1) for row: Person[Q] do
            printLn(row.name);
        else error do
            printLn(describe(error));
        end for;
        return nil;
    end;

    function main(): ExitCode is
        case openWriter(":memory:") of
            when Left(left as error: SqlError) do
                printLn(describe(error));
                return ExitFailure();
            when Right(right as opened: Connection[Writing]) do
                var db: Connection[Writing] := opened;
                case migrate(&!db, @migrations) of
                    when Left(left as error: SqlError) do
                        printLn(describe(error));
                    when Right(right as applied: Index) do
                        run(&!db);
                end case;
                closeDatabase(db);
                return ExitSuccess();
        end case;
    end;
end module body.
```

### H8060

Meldung:

```text
Generic Error
@query: max(NULL) (line 1, column 45 of the SQL)
```

min oder max bekommt NULL.

Dieses Modul scheitert mit H8060:

```hilde fails H8060
import Standard.Sqlite (Connection, Writing, SqlError, describe, openWriter, closeDatabase, migrate);

module body Example is
    record Person[R: Region]: Free is
        name: Span[Nat8, R];
    end;

    generic [R: Region]
    function run(db: &![Connection[Writing], R]): Unit is
        @query(&~db, "SELECT name FROM users GROUP BY name HAVING max(NULL) > 1") for row: Person[Q] do
            printLn(row.name);
        else error do
            printLn(describe(error));
        end for;
        return nil;
    end;

    function main(): ExitCode is
        case openWriter(":memory:") of
            when Left(left as error: SqlError) do
                printLn(describe(error));
                return ExitFailure();
            when Right(right as opened: Connection[Writing]) do
                var db: Connection[Writing] := opened;
                case migrate(&!db, @migrations) of
                    when Left(left as error: SqlError) do
                        printLn(describe(error));
                    when Right(right as applied: Index) do
                        run(&!db);
                end case;
                closeDatabase(db);
                return ExitSuccess();
        end case;
    end;
end module body.
```

Die richtige Form:

```hilde
import Standard.Sqlite (Connection, Writing, SqlError, describe, openWriter, closeDatabase, migrate);

module body Example is
    record Person[R: Region]: Free is
        name: Span[Nat8, R];
    end;

    generic [R: Region]
    function run(db: &![Connection[Writing], R]): Unit is
        @query(&~db, "SELECT name FROM users GROUP BY name HAVING max(age) > 1") for row: Person[Q] do
            printLn(row.name);
        else error do
            printLn(describe(error));
        end for;
        return nil;
    end;

    function main(): ExitCode is
        case openWriter(":memory:") of
            when Left(left as error: SqlError) do
                printLn(describe(error));
                return ExitFailure();
            when Right(right as opened: Connection[Writing]) do
                var db: Connection[Writing] := opened;
                case migrate(&!db, @migrations) of
                    when Left(left as error: SqlError) do
                        printLn(describe(error));
                    when Right(right as applied: Index) do
                        run(&!db);
                end case;
                closeDatabase(db);
                return ExitSuccess();
        end case;
    end;
end module body.
```

### H8061

Meldung:

```text
Generic Error
@query: ifnull() takes two arguments (line 1, column 30 of the SQL)
```

coalesce bekommt weniger als zwei Argumente oder ifnull nicht genau zwei.

Dieses Modul scheitert mit H8061:

```hilde fails H8061
import Standard.Sqlite (Connection, Writing, SqlError, describe, openWriter, closeDatabase, migrate);

module body Example is
    record Person[R: Region]: Free is
        name: Span[Nat8, R];
    end;

    generic [R: Region]
    function run(db: &![Connection[Writing], R]): Unit is
        @query(&~db, "SELECT name FROM users WHERE ifnull(email) = 'x'") for row: Person[Q] do
            printLn(row.name);
        else error do
            printLn(describe(error));
        end for;
        return nil;
    end;

    function main(): ExitCode is
        case openWriter(":memory:") of
            when Left(left as error: SqlError) do
                printLn(describe(error));
                return ExitFailure();
            when Right(right as opened: Connection[Writing]) do
                var db: Connection[Writing] := opened;
                case migrate(&!db, @migrations) of
                    when Left(left as error: SqlError) do
                        printLn(describe(error));
                    when Right(right as applied: Index) do
                        run(&!db);
                end case;
                closeDatabase(db);
                return ExitSuccess();
        end case;
    end;
end module body.
```

Die richtige Form:

```hilde
import Standard.Sqlite (Connection, Writing, SqlError, describe, openWriter, closeDatabase, migrate);

module body Example is
    record Person[R: Region]: Free is
        name: Span[Nat8, R];
    end;

    generic [R: Region]
    function run(db: &![Connection[Writing], R]): Unit is
        @query(&~db, "SELECT name FROM users WHERE ifnull(email, '') = 'x'") for row: Person[Q] do
            printLn(row.name);
        else error do
            printLn(describe(error));
        end for;
        return nil;
    end;

    function main(): ExitCode is
        case openWriter(":memory:") of
            when Left(left as error: SqlError) do
                printLn(describe(error));
                return ExitFailure();
            when Right(right as opened: Connection[Writing]) do
                var db: Connection[Writing] := opened;
                case migrate(&!db, @migrations) of
                    when Left(left as error: SqlError) do
                        printLn(describe(error));
                    when Right(right as applied: Index) do
                        run(&!db);
                end case;
                closeDatabase(db);
                return ExitSuccess();
        end case;
    end;
end module body.
```

### H8062

Meldung:

```text
Generic Error
@query: coalesce() of parameters only has no type (line 1, column 38 of the SQL)
```

coalesce oder ifnull bekommt nur Parameter; sein Typ lässt sich daher nicht
bestimmen.

Dieses Modul scheitert mit H8062:

```hilde fails H8062
import Standard.Sqlite (Connection, Writing, SqlError, describe, openWriter, closeDatabase, migrate);

module body Example is
    record Person[R: Region]: Free is
        name: Span[Nat8, R];
    end;

    generic [R: Region]
    function run(db: &![Connection[Writing], R]): Unit is
        @query(&~db, "SELECT name FROM users WHERE email = coalesce(?, ?)", "a", "b") for row: Person[Q] do
            printLn(row.name);
        else error do
            printLn(describe(error));
        end for;
        return nil;
    end;

    function main(): ExitCode is
        case openWriter(":memory:") of
            when Left(left as error: SqlError) do
                printLn(describe(error));
                return ExitFailure();
            when Right(right as opened: Connection[Writing]) do
                var db: Connection[Writing] := opened;
                case migrate(&!db, @migrations) of
                    when Left(left as error: SqlError) do
                        printLn(describe(error));
                    when Right(right as applied: Index) do
                        run(&!db);
                end case;
                closeDatabase(db);
                return ExitSuccess();
        end case;
    end;
end module body.
```

Die richtige Form:

```hilde
import Standard.Sqlite (Connection, Writing, SqlError, describe, openWriter, closeDatabase, migrate);

module body Example is
    record Person[R: Region]: Free is
        name: Span[Nat8, R];
    end;

    generic [R: Region]
    function run(db: &![Connection[Writing], R]): Unit is
        @query(&~db, "SELECT name FROM users WHERE email = coalesce(?, name)", "a") for row: Person[Q] do
            printLn(row.name);
        else error do
            printLn(describe(error));
        end for;
        return nil;
    end;

    function main(): ExitCode is
        case openWriter(":memory:") of
            when Left(left as error: SqlError) do
                printLn(describe(error));
                return ExitFailure();
            when Right(right as opened: Connection[Writing]) do
                var db: Connection[Writing] := opened;
                case migrate(&!db, @migrations) of
                    when Left(left as error: SqlError) do
                        printLn(describe(error));
                    when Right(right as applied: Index) do
                        run(&!db);
                end case;
                closeDatabase(db);
                return ExitSuccess();
        end case;
    end;
end module body.
```

### H8063

Meldung:

```text
Generic Error
@query: coalesce() whose first value is NULL (line 1, column 39 of the SQL)
```

Der erste Wert von coalesce oder ifnull, der kein Parameter ist, ist NULL.

Dieses Modul scheitert mit H8063:

```hilde fails H8063
import Standard.Sqlite (Connection, Writing, SqlError, describe, openWriter, closeDatabase, migrate);

module body Example is
    record Person[R: Region]: Free is
        name: Span[Nat8, R];
    end;

    generic [R: Region]
    function run(db: &![Connection[Writing], R]): Unit is
        @query(&~db, "SELECT name FROM users WHERE coalesce(NULL, email) = 'x'") for row: Person[Q] do
            printLn(row.name);
        else error do
            printLn(describe(error));
        end for;
        return nil;
    end;

    function main(): ExitCode is
        case openWriter(":memory:") of
            when Left(left as error: SqlError) do
                printLn(describe(error));
                return ExitFailure();
            when Right(right as opened: Connection[Writing]) do
                var db: Connection[Writing] := opened;
                case migrate(&!db, @migrations) of
                    when Left(left as error: SqlError) do
                        printLn(describe(error));
                    when Right(right as applied: Index) do
                        run(&!db);
                end case;
                closeDatabase(db);
                return ExitSuccess();
        end case;
    end;
end module body.
```

Die richtige Form:

```hilde
import Standard.Sqlite (Connection, Writing, SqlError, describe, openWriter, closeDatabase, migrate);

module body Example is
    record Person[R: Region]: Free is
        name: Span[Nat8, R];
    end;

    generic [R: Region]
    function run(db: &![Connection[Writing], R]): Unit is
        @query(&~db, "SELECT name FROM users WHERE coalesce(email, 'none') = 'x'") for row: Person[Q] do
            printLn(row.name);
        else error do
            printLn(describe(error));
        end for;
        return nil;
    end;

    function main(): ExitCode is
        case openWriter(":memory:") of
            when Left(left as error: SqlError) do
                printLn(describe(error));
                return ExitFailure();
            when Right(right as opened: Connection[Writing]) do
                var db: Connection[Writing] := opened;
                case migrate(&!db, @migrations) of
                    when Left(left as error: SqlError) do
                        printLn(describe(error));
                    when Right(right as applied: Index) do
                        run(&!db);
                end case;
                closeDatabase(db);
                return ExitSuccess();
        end case;
    end;
end module body.
```

### H8064

Meldung:

```text
Generic Error
@query: coalesce() of TEXT and INTEGER (line 1, column 46 of the SQL)
```

coalesce oder ifnull bekommt Werte verschiedenen Typs.

Dieses Modul scheitert mit H8064:

```hilde fails H8064
import Standard.Sqlite (Connection, Writing, SqlError, describe, openWriter, closeDatabase, migrate);

module body Example is
    record Person[R: Region]: Free is
        name: Span[Nat8, R];
    end;

    generic [R: Region]
    function run(db: &![Connection[Writing], R]): Unit is
        @query(&~db, "SELECT name FROM users WHERE coalesce(email, 0) = 'x'") for row: Person[Q] do
            printLn(row.name);
        else error do
            printLn(describe(error));
        end for;
        return nil;
    end;

    function main(): ExitCode is
        case openWriter(":memory:") of
            when Left(left as error: SqlError) do
                printLn(describe(error));
                return ExitFailure();
            when Right(right as opened: Connection[Writing]) do
                var db: Connection[Writing] := opened;
                case migrate(&!db, @migrations) of
                    when Left(left as error: SqlError) do
                        printLn(describe(error));
                    when Right(right as applied: Index) do
                        run(&!db);
                end case;
                closeDatabase(db);
                return ExitSuccess();
        end case;
    end;
end module body.
```

Die richtige Form:

```hilde
import Standard.Sqlite (Connection, Writing, SqlError, describe, openWriter, closeDatabase, migrate);

module body Example is
    record Person[R: Region]: Free is
        name: Span[Nat8, R];
    end;

    generic [R: Region]
    function run(db: &![Connection[Writing], R]): Unit is
        @query(&~db, "SELECT name FROM users WHERE coalesce(email, '') = 'x'") for row: Person[Q] do
            printLn(row.name);
        else error do
            printLn(describe(error));
        end for;
        return nil;
    end;

    function main(): ExitCode is
        case openWriter(":memory:") of
            when Left(left as error: SqlError) do
                printLn(describe(error));
                return ExitFailure();
            when Right(right as opened: Connection[Writing]) do
                var db: Connection[Writing] := opened;
                case migrate(&!db, @migrations) of
                    when Left(left as error: SqlError) do
                        printLn(describe(error));
                    when Right(right as applied: Index) do
                        run(&!db);
                end case;
                closeDatabase(db);
                return ExitSuccess();
        end case;
    end;
end module body.
```

### H8065

Meldung:

```text
Generic Error
@query: length() of INTEGER: it takes TEXT or BLOB (line 1, column 30 of the SQL)
```

length bekommt etwas anderes als TEXT oder BLOB.

Dieses Modul scheitert mit H8065:

```hilde fails H8065
import Standard.Sqlite (Connection, Writing, SqlError, describe, openWriter, closeDatabase, migrate);

module body Example is
    record Person[R: Region]: Free is
        name: Span[Nat8, R];
    end;

    generic [R: Region]
    function run(db: &![Connection[Writing], R]): Unit is
        @query(&~db, "SELECT name FROM users WHERE length(age) > 1") for row: Person[Q] do
            printLn(row.name);
        else error do
            printLn(describe(error));
        end for;
        return nil;
    end;

    function main(): ExitCode is
        case openWriter(":memory:") of
            when Left(left as error: SqlError) do
                printLn(describe(error));
                return ExitFailure();
            when Right(right as opened: Connection[Writing]) do
                var db: Connection[Writing] := opened;
                case migrate(&!db, @migrations) of
                    when Left(left as error: SqlError) do
                        printLn(describe(error));
                    when Right(right as applied: Index) do
                        run(&!db);
                end case;
                closeDatabase(db);
                return ExitSuccess();
        end case;
    end;
end module body.
```

Die richtige Form:

```hilde
import Standard.Sqlite (Connection, Writing, SqlError, describe, openWriter, closeDatabase, migrate);

module body Example is
    record Person[R: Region]: Free is
        name: Span[Nat8, R];
    end;

    generic [R: Region]
    function run(db: &![Connection[Writing], R]): Unit is
        @query(&~db, "SELECT name FROM users WHERE length(name) > 1") for row: Person[Q] do
            printLn(row.name);
        else error do
            printLn(describe(error));
        end for;
        return nil;
    end;

    function main(): ExitCode is
        case openWriter(":memory:") of
            when Left(left as error: SqlError) do
                printLn(describe(error));
                return ExitFailure();
            when Right(right as opened: Connection[Writing]) do
                var db: Connection[Writing] := opened;
                case migrate(&!db, @migrations) of
                    when Left(left as error: SqlError) do
                        printLn(describe(error));
                    when Right(right as applied: Index) do
                        run(&!db);
                end case;
                closeDatabase(db);
                return ExitSuccess();
        end case;
    end;
end module body.
```

### H8066

Meldung:

```text
Generic Error
@query: upper() of INTEGER: it takes TEXT (line 1, column 30 of the SQL)
```

lower oder upper bekommt etwas anderes als TEXT.

Dieses Modul scheitert mit H8066:

```hilde fails H8066
import Standard.Sqlite (Connection, Writing, SqlError, describe, openWriter, closeDatabase, migrate);

module body Example is
    record Person[R: Region]: Free is
        name: Span[Nat8, R];
    end;

    generic [R: Region]
    function run(db: &![Connection[Writing], R]): Unit is
        @query(&~db, "SELECT name FROM users WHERE upper(age) = 'X'") for row: Person[Q] do
            printLn(row.name);
        else error do
            printLn(describe(error));
        end for;
        return nil;
    end;

    function main(): ExitCode is
        case openWriter(":memory:") of
            when Left(left as error: SqlError) do
                printLn(describe(error));
                return ExitFailure();
            when Right(right as opened: Connection[Writing]) do
                var db: Connection[Writing] := opened;
                case migrate(&!db, @migrations) of
                    when Left(left as error: SqlError) do
                        printLn(describe(error));
                    when Right(right as applied: Index) do
                        run(&!db);
                end case;
                closeDatabase(db);
                return ExitSuccess();
        end case;
    end;
end module body.
```

Die richtige Form:

```hilde
import Standard.Sqlite (Connection, Writing, SqlError, describe, openWriter, closeDatabase, migrate);

module body Example is
    record Person[R: Region]: Free is
        name: Span[Nat8, R];
    end;

    generic [R: Region]
    function run(db: &![Connection[Writing], R]): Unit is
        @query(&~db, "SELECT name FROM users WHERE upper(name) = 'X'") for row: Person[Q] do
            printLn(row.name);
        else error do
            printLn(describe(error));
        end for;
        return nil;
    end;

    function main(): ExitCode is
        case openWriter(":memory:") of
            when Left(left as error: SqlError) do
                printLn(describe(error));
                return ExitFailure();
            when Right(right as opened: Connection[Writing]) do
                var db: Connection[Writing] := opened;
                case migrate(&!db, @migrations) of
                    when Left(left as error: SqlError) do
                        printLn(describe(error));
                    when Right(right as applied: Index) do
                        run(&!db);
                end case;
                closeDatabase(db);
                return ExitSuccess();
        end case;
    end;
end module body.
```

### H8067

Meldung:

```text
Generic Error
@query: trim() is not one of the functions whose type the compiler knows: count, sum, total, avg, min, max, coalesce, ifnull, length, lower, upper, abs (line 1, column 30 of the SQL)
```

Das SQL ruft eine Funktion auf, deren Typ der Compiler nicht kennt. Er kennt
count, sum, total, avg, min, max, coalesce, ifnull, length, lower, upper und
abs.

Dieses Modul scheitert mit H8067:

```hilde fails H8067
import Standard.Sqlite (Connection, Writing, SqlError, describe, openWriter, closeDatabase, migrate);

module body Example is
    record Person[R: Region]: Free is
        name: Span[Nat8, R];
    end;

    generic [R: Region]
    function run(db: &![Connection[Writing], R]): Unit is
        @query(&~db, "SELECT name FROM users WHERE trim(name) = 'x'") for row: Person[Q] do
            printLn(row.name);
        else error do
            printLn(describe(error));
        end for;
        return nil;
    end;

    function main(): ExitCode is
        case openWriter(":memory:") of
            when Left(left as error: SqlError) do
                printLn(describe(error));
                return ExitFailure();
            when Right(right as opened: Connection[Writing]) do
                var db: Connection[Writing] := opened;
                case migrate(&!db, @migrations) of
                    when Left(left as error: SqlError) do
                        printLn(describe(error));
                    when Right(right as applied: Index) do
                        run(&!db);
                end case;
                closeDatabase(db);
                return ExitSuccess();
        end case;
    end;
end module body.
```

Die richtige Form:

```hilde
import Standard.Sqlite (Connection, Writing, SqlError, describe, openWriter, closeDatabase, migrate);

module body Example is
    record Person[R: Region]: Free is
        name: Span[Nat8, R];
    end;

    generic [R: Region]
    function run(db: &![Connection[Writing], R]): Unit is
        @query(&~db, "SELECT name FROM users WHERE lower(name) = 'x'") for row: Person[Q] do
            printLn(row.name);
        else error do
            printLn(describe(error));
        end for;
        return nil;
    end;

    function main(): ExitCode is
        case openWriter(":memory:") of
            when Left(left as error: SqlError) do
                printLn(describe(error));
                return ExitFailure();
            when Right(right as opened: Connection[Writing]) do
                var db: Connection[Writing] := opened;
                case migrate(&!db, @migrations) of
                    when Left(left as error: SqlError) do
                        printLn(describe(error));
                    when Right(right as applied: Index) do
                        run(&!db);
                end case;
                closeDatabase(db);
                return ExitSuccess();
        end case;
    end;
end module body.
```

### H8068

Meldung:

```text
Generic Error
@query: two parameters meet, and neither says what type the other is (line 1, column 30 of the SQL)
```

Zwei Parameter treffen an einem Operator aufeinander, und keiner gibt dem
anderen einen Typ.

Dieses Modul scheitert mit H8068:

```hilde fails H8068
import Standard.Sqlite (Connection, Writing, SqlError, describe, openWriter, closeDatabase, migrate);

module body Example is
    record Person[R: Region]: Free is
        name: Span[Nat8, R];
    end;

    generic [R: Region]
    function run(db: &![Connection[Writing], R]): Unit is
        @query(&~db, "SELECT name FROM users WHERE ? = ?", "a", "b") for row: Person[Q] do
            printLn(row.name);
        else error do
            printLn(describe(error));
        end for;
        return nil;
    end;

    function main(): ExitCode is
        case openWriter(":memory:") of
            when Left(left as error: SqlError) do
                printLn(describe(error));
                return ExitFailure();
            when Right(right as opened: Connection[Writing]) do
                var db: Connection[Writing] := opened;
                case migrate(&!db, @migrations) of
                    when Left(left as error: SqlError) do
                        printLn(describe(error));
                    when Right(right as applied: Index) do
                        run(&!db);
                end case;
                closeDatabase(db);
                return ExitSuccess();
        end case;
    end;
end module body.
```

Die richtige Form:

```hilde
import Standard.Sqlite (Connection, Writing, SqlError, describe, openWriter, closeDatabase, migrate);

module body Example is
    record Person[R: Region]: Free is
        name: Span[Nat8, R];
    end;

    generic [R: Region]
    function run(db: &![Connection[Writing], R]): Unit is
        @query(&~db, "SELECT name FROM users WHERE name = ?", "a") for row: Person[Q] do
            printLn(row.name);
        else error do
            printLn(describe(error));
        end for;
        return nil;
    end;

    function main(): ExitCode is
        case openWriter(":memory:") of
            when Left(left as error: SqlError) do
                printLn(describe(error));
                return ExitFailure();
            when Right(right as opened: Connection[Writing]) do
                var db: Connection[Writing] := opened;
                case migrate(&!db, @migrations) of
                    when Left(left as error: SqlError) do
                        printLn(describe(error));
                    when Right(right as applied: Index) do
                        run(&!db);
                end case;
                closeDatabase(db);
                return ExitSuccess();
        end case;
    end;
end module body.
```

### H8069

Meldung:

```text
Generic Error
@query: the WHERE condition is TEXT, and it has to be a condition (line 1, column 30 of the SQL)
```

Ein WHERE, ON, HAVING oder CHECK bekommt etwas, das keine Bedingung ist.

Dieses Modul scheitert mit H8069:

```hilde fails H8069
import Standard.Sqlite (Connection, Writing, SqlError, describe, openWriter, closeDatabase, migrate);

module body Example is
    record Person[R: Region]: Free is
        name: Span[Nat8, R];
    end;

    generic [R: Region]
    function run(db: &![Connection[Writing], R]): Unit is
        @query(&~db, "SELECT name FROM users WHERE email") for row: Person[Q] do
            printLn(row.name);
        else error do
            printLn(describe(error));
        end for;
        return nil;
    end;

    function main(): ExitCode is
        case openWriter(":memory:") of
            when Left(left as error: SqlError) do
                printLn(describe(error));
                return ExitFailure();
            when Right(right as opened: Connection[Writing]) do
                var db: Connection[Writing] := opened;
                case migrate(&!db, @migrations) of
                    when Left(left as error: SqlError) do
                        printLn(describe(error));
                    when Right(right as applied: Index) do
                        run(&!db);
                end case;
                closeDatabase(db);
                return ExitSuccess();
        end case;
    end;
end module body.
```

Die richtige Form:

```hilde
import Standard.Sqlite (Connection, Writing, SqlError, describe, openWriter, closeDatabase, migrate);

module body Example is
    record Person[R: Region]: Free is
        name: Span[Nat8, R];
    end;

    generic [R: Region]
    function run(db: &![Connection[Writing], R]): Unit is
        @query(&~db, "SELECT name FROM users WHERE email IS NOT NULL") for row: Person[Q] do
            printLn(row.name);
        else error do
            printLn(describe(error));
        end for;
        return nil;
    end;

    function main(): ExitCode is
        case openWriter(":memory:") of
            when Left(left as error: SqlError) do
                printLn(describe(error));
                return ExitFailure();
            when Right(right as opened: Connection[Writing]) do
                var db: Connection[Writing] := opened;
                case migrate(&!db, @migrations) of
                    when Left(left as error: SqlError) do
                        printLn(describe(error));
                    when Right(right as applied: Index) do
                        run(&!db);
                end case;
                closeDatabase(db);
                return ExitSuccess();
        end case;
    end;
end module body.
```

### H8070

Meldung:

```text
Generic Error
@query: the column loud name cannot name a field of the row type: give it a name with AS (line 1, column 8 of the SQL)
```

Eine Spalte des Ergebnisses hat einen Namen, der kein Feld des
Zeilen-Records benennen kann, etwa einen Namen mit Leerzeichen oder ein
Hilde-Schlüsselwort.

Dieses Modul scheitert mit H8070:

```hilde fails H8070
import Standard.Sqlite (Connection, Writing, SqlError, describe, openWriter, closeDatabase, migrate);

module body Example is
    record Shout[R: Region]: Free is
        shout: Span[Nat8, R];
    end;

    generic [R: Region]
    function run(db: &![Connection[Writing], R]): Unit is
        @query(&~db, "SELECT upper(name) AS \"loud name\" FROM users") for row: Shout[Q] do
            printLn(row.shout);
        else error do
            printLn(describe(error));
        end for;
        return nil;
    end;

    function main(): ExitCode is
        case openWriter(":memory:") of
            when Left(left as error: SqlError) do
                printLn(describe(error));
                return ExitFailure();
            when Right(right as opened: Connection[Writing]) do
                var db: Connection[Writing] := opened;
                case migrate(&!db, @migrations) of
                    when Left(left as error: SqlError) do
                        printLn(describe(error));
                    when Right(right as applied: Index) do
                        run(&!db);
                end case;
                closeDatabase(db);
                return ExitSuccess();
        end case;
    end;
end module body.
```

Die richtige Form:

```hilde
import Standard.Sqlite (Connection, Writing, SqlError, describe, openWriter, closeDatabase, migrate);

module body Example is
    record Shout[R: Region]: Free is
        shout: Span[Nat8, R];
    end;

    generic [R: Region]
    function run(db: &![Connection[Writing], R]): Unit is
        @query(&~db, "SELECT upper(name) AS shout FROM users") for row: Shout[Q] do
            printLn(row.shout);
        else error do
            printLn(describe(error));
        end for;
        return nil;
    end;

    function main(): ExitCode is
        case openWriter(":memory:") of
            when Left(left as error: SqlError) do
                printLn(describe(error));
                return ExitFailure();
            when Right(right as opened: Connection[Writing]) do
                var db: Connection[Writing] := opened;
                case migrate(&!db, @migrations) of
                    when Left(left as error: SqlError) do
                        printLn(describe(error));
                    when Right(right as applied: Index) do
                        run(&!db);
                end case;
                closeDatabase(db);
                return ExitSuccess();
        end case;
    end;
end module body.
```

### H8071

Meldung:

```text
Generic Error
@query: * without a table (line 1, column 8 of the SQL)
```

`*` steht in einer Abfrage ohne Tabelle.

Dieses Modul scheitert mit H8071:

```hilde fails H8071
import Standard.Sqlite (Connection, Writing, SqlError, describe, openWriter, closeDatabase, migrate);

module body Example is
    record User[R: Region]: Free is
        id: Int64;
        name: Span[Nat8, R];
        age: Int64;
        email: Option[Span[Nat8, R]];
        score: Option[Float64];
    end;

    generic [R: Region]
    function run(db: &![Connection[Writing], R]): Unit is
        @query(&~db, "SELECT *") for row: User[Q] do
            printLn(row.name);
        else error do
            printLn(describe(error));
        end for;
        return nil;
    end;

    function main(): ExitCode is
        case openWriter(":memory:") of
            when Left(left as error: SqlError) do
                printLn(describe(error));
                return ExitFailure();
            when Right(right as opened: Connection[Writing]) do
                var db: Connection[Writing] := opened;
                case migrate(&!db, @migrations) of
                    when Left(left as error: SqlError) do
                        printLn(describe(error));
                    when Right(right as applied: Index) do
                        run(&!db);
                end case;
                closeDatabase(db);
                return ExitSuccess();
        end case;
    end;
end module body.
```

Die richtige Form:

```hilde
import Standard.Sqlite (Connection, Writing, SqlError, describe, openWriter, closeDatabase, migrate);

module body Example is
    record User[R: Region]: Free is
        id: Int64;
        name: Span[Nat8, R];
        age: Int64;
        email: Option[Span[Nat8, R]];
        score: Option[Float64];
    end;

    generic [R: Region]
    function run(db: &![Connection[Writing], R]): Unit is
        @query(&~db, "SELECT * FROM users") for row: User[Q] do
            printLn(row.name);
        else error do
            printLn(describe(error));
        end for;
        return nil;
    end;

    function main(): ExitCode is
        case openWriter(":memory:") of
            when Left(left as error: SqlError) do
                printLn(describe(error));
                return ExitFailure();
            when Right(right as opened: Connection[Writing]) do
                var db: Connection[Writing] := opened;
                case migrate(&!db, @migrations) of
                    when Left(left as error: SqlError) do
                        printLn(describe(error));
                    when Right(right as applied: Index) do
                        run(&!db);
                end case;
                closeDatabase(db);
                return ExitSuccess();
        end case;
    end;
end module body.
```

### H8072

Meldung:

```text
Generic Error
@query: there is no table or alias u in this query (line 1, column 8 of the SQL)
```

`t.*` nennt eine Tabelle oder einen Alias, die die Abfrage nicht hat.

Dieses Modul scheitert mit H8072:

```hilde fails H8072
import Standard.Sqlite (Connection, Writing, SqlError, describe, openWriter, closeDatabase, migrate);

module body Example is
    record User[R: Region]: Free is
        id: Int64;
        name: Span[Nat8, R];
        age: Int64;
        email: Option[Span[Nat8, R]];
        score: Option[Float64];
    end;

    generic [R: Region]
    function run(db: &![Connection[Writing], R]): Unit is
        @query(&~db, "SELECT u.* FROM users") for row: User[Q] do
            printLn(row.name);
        else error do
            printLn(describe(error));
        end for;
        return nil;
    end;

    function main(): ExitCode is
        case openWriter(":memory:") of
            when Left(left as error: SqlError) do
                printLn(describe(error));
                return ExitFailure();
            when Right(right as opened: Connection[Writing]) do
                var db: Connection[Writing] := opened;
                case migrate(&!db, @migrations) of
                    when Left(left as error: SqlError) do
                        printLn(describe(error));
                    when Right(right as applied: Index) do
                        run(&!db);
                end case;
                closeDatabase(db);
                return ExitSuccess();
        end case;
    end;
end module body.
```

Die richtige Form:

```hilde
import Standard.Sqlite (Connection, Writing, SqlError, describe, openWriter, closeDatabase, migrate);

module body Example is
    record User[R: Region]: Free is
        id: Int64;
        name: Span[Nat8, R];
        age: Int64;
        email: Option[Span[Nat8, R]];
        score: Option[Float64];
    end;

    generic [R: Region]
    function run(db: &![Connection[Writing], R]): Unit is
        @query(&~db, "SELECT u.* FROM users u") for row: User[Q] do
            printLn(row.name);
        else error do
            printLn(describe(error));
        end for;
        return nil;
    end;

    function main(): ExitCode is
        case openWriter(":memory:") of
            when Left(left as error: SqlError) do
                printLn(describe(error));
                return ExitFailure();
            when Right(right as opened: Connection[Writing]) do
                var db: Connection[Writing] := opened;
                case migrate(&!db, @migrations) of
                    when Left(left as error: SqlError) do
                        printLn(describe(error));
                    when Right(right as applied: Index) do
                        run(&!db);
                end case;
                closeDatabase(db);
                return ExitSuccess();
        end case;
    end;
end module body.
```

### H8073

Meldung:

```text
Generic Error
@query: this column is always NULL and has no type (line 1, column 14 of the SQL)
```

Eine Spalte des Ergebnisses ist immer NULL und hat deshalb keinen Typ.

Dieses Modul scheitert mit H8073:

```hilde fails H8073
import Standard.Sqlite (Connection, Writing, SqlError, describe, openWriter, closeDatabase, migrate);

module body Example is
    record Person[R: Region]: Free is
        name: Span[Nat8, R];
    end;

    generic [R: Region]
    function run(db: &![Connection[Writing], R]): Unit is
        @query(&~db, "SELECT name, NULL AS note FROM users") for row: Person[Q] do
            printLn(row.name);
        else error do
            printLn(describe(error));
        end for;
        return nil;
    end;

    function main(): ExitCode is
        case openWriter(":memory:") of
            when Left(left as error: SqlError) do
                printLn(describe(error));
                return ExitFailure();
            when Right(right as opened: Connection[Writing]) do
                var db: Connection[Writing] := opened;
                case migrate(&!db, @migrations) of
                    when Left(left as error: SqlError) do
                        printLn(describe(error));
                    when Right(right as applied: Index) do
                        run(&!db);
                end case;
                closeDatabase(db);
                return ExitSuccess();
        end case;
    end;
end module body.
```

Die richtige Form:

```hilde
import Standard.Sqlite (Connection, Writing, SqlError, describe, openWriter, closeDatabase, migrate);

module body Example is
    record Person[R: Region]: Free is
        name: Span[Nat8, R];
    end;

    generic [R: Region]
    function run(db: &![Connection[Writing], R]): Unit is
        @query(&~db, "SELECT name FROM users") for row: Person[Q] do
            printLn(row.name);
        else error do
            printLn(describe(error));
        end for;
        return nil;
    end;

    function main(): ExitCode is
        case openWriter(":memory:") of
            when Left(left as error: SqlError) do
                printLn(describe(error));
                return ExitFailure();
            when Right(right as opened: Connection[Writing]) do
                var db: Connection[Writing] := opened;
                case migrate(&!db, @migrations) of
                    when Left(left as error: SqlError) do
                        printLn(describe(error));
                    when Right(right as applied: Index) do
                        run(&!db);
                end case;
                closeDatabase(db);
                return ExitSuccess();
        end case;
    end;
end module body.
```

### H8074

Meldung:

```text
Generic Error
@query: a column that is not a plain column needs a name: write AS (line 1, column 8 of the SQL)
```

Eine Spalte des Ergebnisses, die keine einfache Spalte ist, hat keinen
Namen. Man gibt ihr einen mit AS.

Dieses Modul scheitert mit H8074:

```hilde fails H8074
import Standard.Sqlite (Connection, Writing, SqlError, describe, openWriter, closeDatabase, migrate);

module body Example is
    record Person[R: Region]: Free is
        name: Span[Nat8, R];
    end;

    generic [R: Region]
    function run(db: &![Connection[Writing], R]): Unit is
        @query(&~db, "SELECT upper(name) FROM users") for row: Person[Q] do
            printLn(row.name);
        else error do
            printLn(describe(error));
        end for;
        return nil;
    end;

    function main(): ExitCode is
        case openWriter(":memory:") of
            when Left(left as error: SqlError) do
                printLn(describe(error));
                return ExitFailure();
            when Right(right as opened: Connection[Writing]) do
                var db: Connection[Writing] := opened;
                case migrate(&!db, @migrations) of
                    when Left(left as error: SqlError) do
                        printLn(describe(error));
                    when Right(right as applied: Index) do
                        run(&!db);
                end case;
                closeDatabase(db);
                return ExitSuccess();
        end case;
    end;
end module body.
```

Die richtige Form:

```hilde
import Standard.Sqlite (Connection, Writing, SqlError, describe, openWriter, closeDatabase, migrate);

module body Example is
    record Person[R: Region]: Free is
        name: Span[Nat8, R];
    end;

    generic [R: Region]
    function run(db: &![Connection[Writing], R]): Unit is
        @query(&~db, "SELECT upper(name) AS name FROM users") for row: Person[Q] do
            printLn(row.name);
        else error do
            printLn(describe(error));
        end for;
        return nil;
    end;

    function main(): ExitCode is
        case openWriter(":memory:") of
            when Left(left as error: SqlError) do
                printLn(describe(error));
                return ExitFailure();
            when Right(right as opened: Connection[Writing]) do
                var db: Connection[Writing] := opened;
                case migrate(&!db, @migrations) of
                    when Left(left as error: SqlError) do
                        printLn(describe(error));
                    when Right(right as applied: Index) do
                        run(&!db);
                end case;
                closeDatabase(db);
                return ExitSuccess();
        end case;
    end;
end module body.
```

### H8075

Meldung:

```text
Generic Error
@query: two columns of the result are called name: rename one with AS (line 1, column 8 of the SQL)
```

Zwei Spalten des Ergebnisses haben denselben Namen.

Dieses Modul scheitert mit H8075:

```hilde fails H8075
import Standard.Sqlite (Connection, Writing, SqlError, describe, openWriter, closeDatabase, migrate);

module body Example is
    record Person[R: Region]: Free is
        name: Span[Nat8, R];
    end;

    generic [R: Region]
    function run(db: &![Connection[Writing], R]): Unit is
        @query(&~db, "SELECT name, lower(name) AS name FROM users") for row: Person[Q] do
            printLn(row.name);
        else error do
            printLn(describe(error));
        end for;
        return nil;
    end;

    function main(): ExitCode is
        case openWriter(":memory:") of
            when Left(left as error: SqlError) do
                printLn(describe(error));
                return ExitFailure();
            when Right(right as opened: Connection[Writing]) do
                var db: Connection[Writing] := opened;
                case migrate(&!db, @migrations) of
                    when Left(left as error: SqlError) do
                        printLn(describe(error));
                    when Right(right as applied: Index) do
                        run(&!db);
                end case;
                closeDatabase(db);
                return ExitSuccess();
        end case;
    end;
end module body.
```

Die richtige Form:

```hilde
import Standard.Sqlite (Connection, Writing, SqlError, describe, openWriter, closeDatabase, migrate);

module body Example is
    record Person[R: Region]: Free is
        name: Span[Nat8, R];
    end;

    generic [R: Region]
    function run(db: &![Connection[Writing], R]): Unit is
        @query(&~db, "SELECT lower(name) AS name FROM users") for row: Person[Q] do
            printLn(row.name);
        else error do
            printLn(describe(error));
        end for;
        return nil;
    end;

    function main(): ExitCode is
        case openWriter(":memory:") of
            when Left(left as error: SqlError) do
                printLn(describe(error));
                return ExitFailure();
            when Right(right as opened: Connection[Writing]) do
                var db: Connection[Writing] := opened;
                case migrate(&!db, @migrations) of
                    when Left(left as error: SqlError) do
                        printLn(describe(error));
                    when Right(right as applied: Index) do
                        run(&!db);
                end case;
                closeDatabase(db);
                return ExitSuccess();
        end case;
    end;
end module body.
```

### H8076

Meldung:

```text
Generic Error
@execute: NULL into name, which is NOT NULL (line 1, column 34 of the SQL)
```

NULL wird in eine Spalte geschrieben, die NOT NULL ist.

Dieses Modul scheitert mit H8076:

```hilde fails H8076
import Standard.Sqlite (Connection, Writing, SqlError, describe, openWriter, closeDatabase, migrate);

module body Example is
    generic [R: Region]
    function run(db: &![Connection[Writing], R]): Unit is
        let result: Either[SqlError, Nat64] := @execute(&~db, "INSERT INTO users (name) VALUES (NULL)");
        case result of
            when Left(left as error: SqlError) do
                printLn(describe(error));
            when Right(right as changed: Nat64) do
                printLn(changed);
        end case;
        return nil;
    end;

    function main(): ExitCode is
        case openWriter(":memory:") of
            when Left(left as error: SqlError) do
                printLn(describe(error));
                return ExitFailure();
            when Right(right as opened: Connection[Writing]) do
                var db: Connection[Writing] := opened;
                case migrate(&!db, @migrations) of
                    when Left(left as error: SqlError) do
                        printLn(describe(error));
                    when Right(right as applied: Index) do
                        run(&!db);
                end case;
                closeDatabase(db);
                return ExitSuccess();
        end case;
    end;
end module body.
```

Die richtige Form:

```hilde
import Standard.Sqlite (Connection, Writing, SqlError, describe, openWriter, closeDatabase, migrate);

module body Example is
    generic [R: Region]
    function run(db: &![Connection[Writing], R]): Unit is
        let result: Either[SqlError, Nat64] := @execute(&~db, "INSERT INTO users (name) VALUES (?)", "ann");
        case result of
            when Left(left as error: SqlError) do
                printLn(describe(error));
            when Right(right as changed: Nat64) do
                printLn(changed);
        end case;
        return nil;
    end;

    function main(): ExitCode is
        case openWriter(":memory:") of
            when Left(left as error: SqlError) do
                printLn(describe(error));
                return ExitFailure();
            when Right(right as opened: Connection[Writing]) do
                var db: Connection[Writing] := opened;
                case migrate(&!db, @migrations) of
                    when Left(left as error: SqlError) do
                        printLn(describe(error));
                    when Right(right as applied: Index) do
                        run(&!db);
                end case;
                closeDatabase(db);
                return ExitSuccess();
        end case;
    end;
end module body.
```

### H8077

Meldung:

```text
Generic Error
@execute: TEXT into age, a INTEGER column: a STRICT table refuses it (line 1, column 42 of the SQL)
```

Ein Wert eines anderen Typs wird in eine Spalte geschrieben. Eine
STRICT-Tabelle lehnt ihn beim Lauf des Programms ab.

Dieses Modul scheitert mit H8077:

```hilde fails H8077
import Standard.Sqlite (Connection, Writing, SqlError, describe, openWriter, closeDatabase, migrate);

module body Example is
    generic [R: Region]
    function run(db: &![Connection[Writing], R]): Unit is
        let result: Either[SqlError, Nat64] := @execute(&~db, "INSERT INTO users (name, age) VALUES (?, '40')", "ann");
        case result of
            when Left(left as error: SqlError) do
                printLn(describe(error));
            when Right(right as changed: Nat64) do
                printLn(changed);
        end case;
        return nil;
    end;

    function main(): ExitCode is
        case openWriter(":memory:") of
            when Left(left as error: SqlError) do
                printLn(describe(error));
                return ExitFailure();
            when Right(right as opened: Connection[Writing]) do
                var db: Connection[Writing] := opened;
                case migrate(&!db, @migrations) of
                    when Left(left as error: SqlError) do
                        printLn(describe(error));
                    when Right(right as applied: Index) do
                        run(&!db);
                end case;
                closeDatabase(db);
                return ExitSuccess();
        end case;
    end;
end module body.
```

Die richtige Form:

```hilde
import Standard.Sqlite (Connection, Writing, SqlError, describe, openWriter, closeDatabase, migrate);

module body Example is
    generic [R: Region]
    function run(db: &![Connection[Writing], R]): Unit is
        let result: Either[SqlError, Nat64] := @execute(&~db, "INSERT INTO users (name, age) VALUES (?, 40)", "ann");
        case result of
            when Left(left as error: SqlError) do
                printLn(describe(error));
            when Right(right as changed: Nat64) do
                printLn(changed);
        end case;
        return nil;
    end;

    function main(): ExitCode is
        case openWriter(":memory:") of
            when Left(left as error: SqlError) do
                printLn(describe(error));
                return ExitFailure();
            when Right(right as opened: Connection[Writing]) do
                var db: Connection[Writing] := opened;
                case migrate(&!db, @migrations) of
                    when Left(left as error: SqlError) do
                        printLn(describe(error));
                    when Right(right as applied: Index) do
                        run(&!db);
                end case;
                closeDatabase(db);
                return ExitSuccess();
        end case;
    end;
end module body.
```

### H8078

Meldung:

```text
Generic Error
@execute: a value that may be NULL into name, which is NOT NULL (line 1, column 25 of the SQL)
```

Ein Wert, der NULL sein kann, wird in eine Spalte geschrieben, die NOT NULL
ist.

Dieses Modul scheitert mit H8078:

```hilde fails H8078
import Standard.Sqlite (Connection, Writing, SqlError, describe, openWriter, closeDatabase, migrate);

module body Example is
    generic [R: Region]
    function run(db: &![Connection[Writing], R]): Unit is
        let result: Either[SqlError, Nat64] := @execute(&~db, "UPDATE users SET name = email");
        case result of
            when Left(left as error: SqlError) do
                printLn(describe(error));
            when Right(right as changed: Nat64) do
                printLn(changed);
        end case;
        return nil;
    end;

    function main(): ExitCode is
        case openWriter(":memory:") of
            when Left(left as error: SqlError) do
                printLn(describe(error));
                return ExitFailure();
            when Right(right as opened: Connection[Writing]) do
                var db: Connection[Writing] := opened;
                case migrate(&!db, @migrations) of
                    when Left(left as error: SqlError) do
                        printLn(describe(error));
                    when Right(right as applied: Index) do
                        run(&!db);
                end case;
                closeDatabase(db);
                return ExitSuccess();
        end case;
    end;
end module body.
```

Die richtige Form:

```hilde
import Standard.Sqlite (Connection, Writing, SqlError, describe, openWriter, closeDatabase, migrate);

module body Example is
    generic [R: Region]
    function run(db: &![Connection[Writing], R]): Unit is
        let result: Either[SqlError, Nat64] := @execute(&~db, "UPDATE users SET name = ifnull(email, name)");
        case result of
            when Left(left as error: SqlError) do
                printLn(describe(error));
            when Right(right as changed: Nat64) do
                printLn(changed);
        end case;
        return nil;
    end;

    function main(): ExitCode is
        case openWriter(":memory:") of
            when Left(left as error: SqlError) do
                printLn(describe(error));
                return ExitFailure();
            when Right(right as opened: Connection[Writing]) do
                var db: Connection[Writing] := opened;
                case migrate(&!db, @migrations) of
                    when Left(left as error: SqlError) do
                        printLn(describe(error));
                    when Right(right as applied: Index) do
                        run(&!db);
                end case;
                closeDatabase(db);
                return ExitSuccess();
        end case;
    end;
end module body.
```

### H8079

Meldung:

```text
Generic Error
@query: users stands twice in FROM: give one an alias (line 1, column 29 of the SQL)
```

Eine Tabelle steht zweimal in FROM, ohne einen Alias, der die beiden
unterscheidet.

Dieses Modul scheitert mit H8079:

```hilde fails H8079
import Standard.Sqlite (Connection, Writing, SqlError, describe, openWriter, closeDatabase, migrate);

module body Example is
    record Person[R: Region]: Free is
        name: Span[Nat8, R];
    end;

    generic [R: Region]
    function run(db: &![Connection[Writing], R]): Unit is
        @query(&~db, "SELECT name FROM users JOIN users ON age = age") for row: Person[Q] do
            printLn(row.name);
        else error do
            printLn(describe(error));
        end for;
        return nil;
    end;

    function main(): ExitCode is
        case openWriter(":memory:") of
            when Left(left as error: SqlError) do
                printLn(describe(error));
                return ExitFailure();
            when Right(right as opened: Connection[Writing]) do
                var db: Connection[Writing] := opened;
                case migrate(&!db, @migrations) of
                    when Left(left as error: SqlError) do
                        printLn(describe(error));
                    when Right(right as applied: Index) do
                        run(&!db);
                end case;
                closeDatabase(db);
                return ExitSuccess();
        end case;
    end;
end module body.
```

Die richtige Form:

```hilde
import Standard.Sqlite (Connection, Writing, SqlError, describe, openWriter, closeDatabase, migrate);

module body Example is
    record Person[R: Region]: Free is
        name: Span[Nat8, R];
    end;

    generic [R: Region]
    function run(db: &![Connection[Writing], R]): Unit is
        @query(&~db, "SELECT a.name FROM users a JOIN users b ON a.age = b.age AND a.id <> b.id") for row: Person[Q] do
            printLn(row.name);
        else error do
            printLn(describe(error));
        end for;
        return nil;
    end;

    function main(): ExitCode is
        case openWriter(":memory:") of
            when Left(left as error: SqlError) do
                printLn(describe(error));
                return ExitFailure();
            when Right(right as opened: Connection[Writing]) do
                var db: Connection[Writing] := opened;
                case migrate(&!db, @migrations) of
                    when Left(left as error: SqlError) do
                        printLn(describe(error));
                    when Right(right as applied: Index) do
                        run(&!db);
                end case;
                closeDatabase(db);
                return ExitSuccess();
        end case;
    end;
end module body.
```

### H8081

Meldung:

```text
Generic Error
@query: LIMIT and OFFSET take an INTEGER that is not NULL (line 1, column 30 of the SQL)
```

LIMIT oder OFFSET bekommt etwas anderes als ein INTEGER, das nicht NULL ist.

Dieses Modul scheitert mit H8081:

```hilde fails H8081
import Standard.Sqlite (Connection, Writing, SqlError, describe, openWriter, closeDatabase, migrate);

module body Example is
    record Person[R: Region]: Free is
        name: Span[Nat8, R];
    end;

    generic [R: Region]
    function run(db: &![Connection[Writing], R]): Unit is
        @query(&~db, "SELECT name FROM users LIMIT '10'") for row: Person[Q] do
            printLn(row.name);
        else error do
            printLn(describe(error));
        end for;
        return nil;
    end;

    function main(): ExitCode is
        case openWriter(":memory:") of
            when Left(left as error: SqlError) do
                printLn(describe(error));
                return ExitFailure();
            when Right(right as opened: Connection[Writing]) do
                var db: Connection[Writing] := opened;
                case migrate(&!db, @migrations) of
                    when Left(left as error: SqlError) do
                        printLn(describe(error));
                    when Right(right as applied: Index) do
                        run(&!db);
                end case;
                closeDatabase(db);
                return ExitSuccess();
        end case;
    end;
end module body.
```

Die richtige Form:

```hilde
import Standard.Sqlite (Connection, Writing, SqlError, describe, openWriter, closeDatabase, migrate);

module body Example is
    record Person[R: Region]: Free is
        name: Span[Nat8, R];
    end;

    generic [R: Region]
    function run(db: &![Connection[Writing], R]): Unit is
        @query(&~db, "SELECT name FROM users LIMIT 10") for row: Person[Q] do
            printLn(row.name);
        else error do
            printLn(describe(error));
        end for;
        return nil;
    end;

    function main(): ExitCode is
        case openWriter(":memory:") of
            when Left(left as error: SqlError) do
                printLn(describe(error));
                return ExitFailure();
            when Right(right as opened: Connection[Writing]) do
                var db: Connection[Writing] := opened;
                case migrate(&!db, @migrations) of
                    when Left(left as error: SqlError) do
                        printLn(describe(error));
                    when Right(right as applied: Index) do
                        run(&!db);
                end case;
                closeDatabase(db);
                return ExitSuccess();
        end case;
    end;
end module body.
```

### H8082

Meldung:

```text
Generic Error
@execute: name is named twice (line 1, column 26 of the SQL)
```

Die Spaltenliste eines INSERT nennt eine Spalte zweimal.

Dieses Modul scheitert mit H8082:

```hilde fails H8082
import Standard.Sqlite (Connection, Writing, SqlError, describe, openWriter, closeDatabase, migrate);

module body Example is
    generic [R: Region]
    function run(db: &![Connection[Writing], R]): Unit is
        let result: Either[SqlError, Nat64] := @execute(&~db, "INSERT INTO users (name, name) VALUES (?, ?)", "ann", "bob");
        case result of
            when Left(left as error: SqlError) do
                printLn(describe(error));
            when Right(right as changed: Nat64) do
                printLn(changed);
        end case;
        return nil;
    end;

    function main(): ExitCode is
        case openWriter(":memory:") of
            when Left(left as error: SqlError) do
                printLn(describe(error));
                return ExitFailure();
            when Right(right as opened: Connection[Writing]) do
                var db: Connection[Writing] := opened;
                case migrate(&!db, @migrations) of
                    when Left(left as error: SqlError) do
                        printLn(describe(error));
                    when Right(right as applied: Index) do
                        run(&!db);
                end case;
                closeDatabase(db);
                return ExitSuccess();
        end case;
    end;
end module body.
```

Die richtige Form:

```hilde
import Standard.Sqlite (Connection, Writing, SqlError, describe, openWriter, closeDatabase, migrate);

module body Example is
    generic [R: Region]
    function run(db: &![Connection[Writing], R]): Unit is
        let result: Either[SqlError, Nat64] := @execute(&~db, "INSERT INTO users (name, age) VALUES (?, ?)", "ann", 40);
        case result of
            when Left(left as error: SqlError) do
                printLn(describe(error));
            when Right(right as changed: Nat64) do
                printLn(changed);
        end case;
        return nil;
    end;

    function main(): ExitCode is
        case openWriter(":memory:") of
            when Left(left as error: SqlError) do
                printLn(describe(error));
                return ExitFailure();
            when Right(right as opened: Connection[Writing]) do
                var db: Connection[Writing] := opened;
                case migrate(&!db, @migrations) of
                    when Left(left as error: SqlError) do
                        printLn(describe(error));
                    when Right(right as applied: Index) do
                        run(&!db);
                end case;
                closeDatabase(db);
                return ExitSuccess();
        end case;
    end;
end module body.
```

### H8083

Meldung:

```text
Generic Error
@execute: the INSERT leaves out name, which is NOT NULL and has no DEFAULT (line 1, column 13 of the SQL)
```

Ein INSERT lässt eine Spalte aus, die NOT NULL ist und keinen Vorgabewert
hat.

Dieses Modul scheitert mit H8083:

```hilde fails H8083
import Standard.Sqlite (Connection, Writing, SqlError, describe, openWriter, closeDatabase, migrate);

module body Example is
    generic [R: Region]
    function run(db: &![Connection[Writing], R]): Unit is
        let result: Either[SqlError, Nat64] := @execute(&~db, "INSERT INTO users (age) VALUES (?)", 40);
        case result of
            when Left(left as error: SqlError) do
                printLn(describe(error));
            when Right(right as changed: Nat64) do
                printLn(changed);
        end case;
        return nil;
    end;

    function main(): ExitCode is
        case openWriter(":memory:") of
            when Left(left as error: SqlError) do
                printLn(describe(error));
                return ExitFailure();
            when Right(right as opened: Connection[Writing]) do
                var db: Connection[Writing] := opened;
                case migrate(&!db, @migrations) of
                    when Left(left as error: SqlError) do
                        printLn(describe(error));
                    when Right(right as applied: Index) do
                        run(&!db);
                end case;
                closeDatabase(db);
                return ExitSuccess();
        end case;
    end;
end module body.
```

Die richtige Form:

```hilde
import Standard.Sqlite (Connection, Writing, SqlError, describe, openWriter, closeDatabase, migrate);

module body Example is
    generic [R: Region]
    function run(db: &![Connection[Writing], R]): Unit is
        let result: Either[SqlError, Nat64] := @execute(&~db, "INSERT INTO users (name, age) VALUES (?, ?)", "ann", 40);
        case result of
            when Left(left as error: SqlError) do
                printLn(describe(error));
            when Right(right as changed: Nat64) do
                printLn(changed);
        end case;
        return nil;
    end;

    function main(): ExitCode is
        case openWriter(":memory:") of
            when Left(left as error: SqlError) do
                printLn(describe(error));
                return ExitFailure();
            when Right(right as opened: Connection[Writing]) do
                var db: Connection[Writing] := opened;
                case migrate(&!db, @migrations) of
                    when Left(left as error: SqlError) do
                        printLn(describe(error));
                    when Right(right as applied: Index) do
                        run(&!db);
                end case;
                closeDatabase(db);
                return ExitSuccess();
        end case;
    end;
end module body.
```

### H8084

Meldung:

```text
Generic Error
@execute: DEFAULT VALUES with a column list (line 1, column 13 of the SQL)
```

Ein INSERT hat eine Spaltenliste und DEFAULT VALUES.

Dieses Modul scheitert mit H8084:

```hilde fails H8084
import Standard.Sqlite (Connection, Writing, SqlError, describe, openWriter, closeDatabase, migrate);

module body Example is
    generic [R: Region]
    function run(db: &![Connection[Writing], R]): Unit is
        let result: Either[SqlError, Nat64] := @execute(&~db, "INSERT INTO users (name) DEFAULT VALUES");
        case result of
            when Left(left as error: SqlError) do
                printLn(describe(error));
            when Right(right as changed: Nat64) do
                printLn(changed);
        end case;
        return nil;
    end;

    function main(): ExitCode is
        case openWriter(":memory:") of
            when Left(left as error: SqlError) do
                printLn(describe(error));
                return ExitFailure();
            when Right(right as opened: Connection[Writing]) do
                var db: Connection[Writing] := opened;
                case migrate(&!db, @migrations) of
                    when Left(left as error: SqlError) do
                        printLn(describe(error));
                    when Right(right as applied: Index) do
                        run(&!db);
                end case;
                closeDatabase(db);
                return ExitSuccess();
        end case;
    end;
end module body.
```

Die richtige Form:

```hilde
import Standard.Sqlite (Connection, Writing, SqlError, describe, openWriter, closeDatabase, migrate);

module body Example is
    generic [R: Region]
    function run(db: &![Connection[Writing], R]): Unit is
        let result: Either[SqlError, Nat64] := @execute(&~db, "INSERT INTO users (name) VALUES (?)", "ann");
        case result of
            when Left(left as error: SqlError) do
                printLn(describe(error));
            when Right(right as changed: Nat64) do
                printLn(changed);
        end case;
        return nil;
    end;

    function main(): ExitCode is
        case openWriter(":memory:") of
            when Left(left as error: SqlError) do
                printLn(describe(error));
                return ExitFailure();
            when Right(right as opened: Connection[Writing]) do
                var db: Connection[Writing] := opened;
                case migrate(&!db, @migrations) of
                    when Left(left as error: SqlError) do
                        printLn(describe(error));
                    when Right(right as applied: Index) do
                        run(&!db);
                end case;
                closeDatabase(db);
                return ExitSuccess();
        end case;
    end;
end module body.
```

### H8085

Meldung:

```text
Generic Error
@execute: a row of 1 values for 2 columns (line 1, column 13 of the SQL)
```

Eine Zeile eines INSERT hat eine andere Anzahl Werte, als es Spalten gibt.

Dieses Modul scheitert mit H8085:

```hilde fails H8085
import Standard.Sqlite (Connection, Writing, SqlError, describe, openWriter, closeDatabase, migrate);

module body Example is
    generic [R: Region]
    function run(db: &![Connection[Writing], R]): Unit is
        let result: Either[SqlError, Nat64] := @execute(&~db, "INSERT INTO users (name, age) VALUES (?)", "ann");
        case result of
            when Left(left as error: SqlError) do
                printLn(describe(error));
            when Right(right as changed: Nat64) do
                printLn(changed);
        end case;
        return nil;
    end;

    function main(): ExitCode is
        case openWriter(":memory:") of
            when Left(left as error: SqlError) do
                printLn(describe(error));
                return ExitFailure();
            when Right(right as opened: Connection[Writing]) do
                var db: Connection[Writing] := opened;
                case migrate(&!db, @migrations) of
                    when Left(left as error: SqlError) do
                        printLn(describe(error));
                    when Right(right as applied: Index) do
                        run(&!db);
                end case;
                closeDatabase(db);
                return ExitSuccess();
        end case;
    end;
end module body.
```

Die richtige Form:

```hilde
import Standard.Sqlite (Connection, Writing, SqlError, describe, openWriter, closeDatabase, migrate);

module body Example is
    generic [R: Region]
    function run(db: &![Connection[Writing], R]): Unit is
        let result: Either[SqlError, Nat64] := @execute(&~db, "INSERT INTO users (name, age) VALUES (?, ?)", "ann", 40);
        case result of
            when Left(left as error: SqlError) do
                printLn(describe(error));
            when Right(right as changed: Nat64) do
                printLn(changed);
        end case;
        return nil;
    end;

    function main(): ExitCode is
        case openWriter(":memory:") of
            when Left(left as error: SqlError) do
                printLn(describe(error));
                return ExitFailure();
            when Right(right as opened: Connection[Writing]) do
                var db: Connection[Writing] := opened;
                case migrate(&!db, @migrations) of
                    when Left(left as error: SqlError) do
                        printLn(describe(error));
                    when Right(right as applied: Index) do
                        run(&!db);
                end case;
                closeDatabase(db);
                return ExitSuccess();
        end case;
    end;
end module body.
```

### H8086

Meldung:

```text
Generic Error
migration: extra is ANY: a column the compiler checks against has one of INT, INTEGER, REAL, TEXT, BLOB
```

Eine Spalte in einer Migration hat den Typ ANY. Der Compiler prüft eine
Abfrage gegen eine Spalte mit INT, INTEGER, REAL, TEXT oder BLOB.

Dieses Modul scheitert mit H8086:

```hilde fails H8086
import Standard.Sqlite (Connection, Writing, SqlError, describe, openWriter, closeDatabase, migrate);

module body Example is
    record Person[R: Region]: Free is
        name: Span[Nat8, R];
    end;

    generic [R: Region]
    function run(db: &![Connection[Writing], R]): Unit is
        @query(&~db, "SELECT name FROM users") for row: Person[Q] do
            printLn(row.name);
        else error do
            printLn(describe(error));
        end for;
        return nil;
    end;

    function main(): ExitCode is
        case openWriter(":memory:") of
            when Left(left as error: SqlError) do
                printLn(describe(error));
                return ExitFailure();
            when Right(right as opened: Connection[Writing]) do
                var db: Connection[Writing] := opened;
                case migrate(&!db, @migrations) of
                    when Left(left as error: SqlError) do
                        printLn(describe(error));
                    when Right(right as applied: Index) do
                        run(&!db);
                end case;
                closeDatabase(db);
                return ExitSuccess();
        end case;
    end;
end module body.
```

Daneben `migrations/1-schema.sql`:

```sql file migrations/1-schema.sql
CREATE TABLE users (
    id INTEGER PRIMARY KEY,
    name TEXT NOT NULL,
    extra ANY
) STRICT;
```

Die richtige Form:

```hilde
import Standard.Sqlite (Connection, Writing, SqlError, describe, openWriter, closeDatabase, migrate);

module body Example is
    record Person[R: Region]: Free is
        name: Span[Nat8, R];
    end;

    generic [R: Region]
    function run(db: &![Connection[Writing], R]): Unit is
        @query(&~db, "SELECT name FROM users") for row: Person[Q] do
            printLn(row.name);
        else error do
            printLn(describe(error));
        end for;
        return nil;
    end;

    function main(): ExitCode is
        case openWriter(":memory:") of
            when Left(left as error: SqlError) do
                printLn(describe(error));
                return ExitFailure();
            when Right(right as opened: Connection[Writing]) do
                var db: Connection[Writing] := opened;
                case migrate(&!db, @migrations) of
                    when Left(left as error: SqlError) do
                        printLn(describe(error));
                    when Right(right as applied: Index) do
                        run(&!db);
                end case;
                closeDatabase(db);
                return ExitSuccess();
        end case;
    end;
end module body.
```

Daneben `migrations/1-schema.sql`:

```sql file migrations/1-schema.sql
CREATE TABLE users (
    id INTEGER PRIMARY KEY,
    name TEXT NOT NULL,
    extra TEXT
) STRICT;
```

### H8087

Meldung:

```text
Generic Error
migration: nickname has no type: a STRICT table gives every column one
```

Eine Spalte in einer Migration hat keinen Typ. Eine STRICT-Tabelle gibt
jeder Spalte einen.

Dieses Modul scheitert mit H8087:

```hilde fails H8087
import Standard.Sqlite (Connection, Writing, SqlError, describe, openWriter, closeDatabase, migrate);

module body Example is
    record Person[R: Region]: Free is
        name: Span[Nat8, R];
    end;

    generic [R: Region]
    function run(db: &![Connection[Writing], R]): Unit is
        @query(&~db, "SELECT name FROM users") for row: Person[Q] do
            printLn(row.name);
        else error do
            printLn(describe(error));
        end for;
        return nil;
    end;

    function main(): ExitCode is
        case openWriter(":memory:") of
            when Left(left as error: SqlError) do
                printLn(describe(error));
                return ExitFailure();
            when Right(right as opened: Connection[Writing]) do
                var db: Connection[Writing] := opened;
                case migrate(&!db, @migrations) of
                    when Left(left as error: SqlError) do
                        printLn(describe(error));
                    when Right(right as applied: Index) do
                        run(&!db);
                end case;
                closeDatabase(db);
                return ExitSuccess();
        end case;
    end;
end module body.
```

Daneben `migrations/1-schema.sql`:

```sql file migrations/1-schema.sql
CREATE TABLE users (
    id INTEGER PRIMARY KEY,
    name TEXT NOT NULL,
    nickname
) STRICT;
```

Die richtige Form:

```hilde
import Standard.Sqlite (Connection, Writing, SqlError, describe, openWriter, closeDatabase, migrate);

module body Example is
    record Person[R: Region]: Free is
        name: Span[Nat8, R];
    end;

    generic [R: Region]
    function run(db: &![Connection[Writing], R]): Unit is
        @query(&~db, "SELECT name FROM users") for row: Person[Q] do
            printLn(row.name);
        else error do
            printLn(describe(error));
        end for;
        return nil;
    end;

    function main(): ExitCode is
        case openWriter(":memory:") of
            when Left(left as error: SqlError) do
                printLn(describe(error));
                return ExitFailure();
            when Right(right as opened: Connection[Writing]) do
                var db: Connection[Writing] := opened;
                case migrate(&!db, @migrations) of
                    when Left(left as error: SqlError) do
                        printLn(describe(error));
                    when Right(right as applied: Index) do
                        run(&!db);
                end case;
                closeDatabase(db);
                return ExitSuccess();
        end case;
    end;
end module body.
```

Daneben `migrations/1-schema.sql`:

```sql file migrations/1-schema.sql
CREATE TABLE users (
    id INTEGER PRIMARY KEY,
    name TEXT NOT NULL,
    nickname TEXT
) STRICT;
```

### H8088

Meldung:

```text
Generic Error
migration: born is DATE, which is not a STRICT type: INT, INTEGER, REAL, TEXT, BLOB
```

Eine Spalte in einer Migration hat einen Typ, den eine STRICT-Tabelle nicht
kennt, etwa DATE.

Dieses Modul scheitert mit H8088:

```hilde fails H8088
import Standard.Sqlite (Connection, Writing, SqlError, describe, openWriter, closeDatabase, migrate);

module body Example is
    record Person[R: Region]: Free is
        name: Span[Nat8, R];
    end;

    generic [R: Region]
    function run(db: &![Connection[Writing], R]): Unit is
        @query(&~db, "SELECT name FROM users") for row: Person[Q] do
            printLn(row.name);
        else error do
            printLn(describe(error));
        end for;
        return nil;
    end;

    function main(): ExitCode is
        case openWriter(":memory:") of
            when Left(left as error: SqlError) do
                printLn(describe(error));
                return ExitFailure();
            when Right(right as opened: Connection[Writing]) do
                var db: Connection[Writing] := opened;
                case migrate(&!db, @migrations) of
                    when Left(left as error: SqlError) do
                        printLn(describe(error));
                    when Right(right as applied: Index) do
                        run(&!db);
                end case;
                closeDatabase(db);
                return ExitSuccess();
        end case;
    end;
end module body.
```

Daneben `migrations/1-schema.sql`:

```sql file migrations/1-schema.sql
CREATE TABLE users (
    id INTEGER PRIMARY KEY,
    name TEXT NOT NULL,
    born DATE
) STRICT;
```

Die richtige Form:

```hilde
import Standard.Sqlite (Connection, Writing, SqlError, describe, openWriter, closeDatabase, migrate);

module body Example is
    record Person[R: Region]: Free is
        name: Span[Nat8, R];
    end;

    generic [R: Region]
    function run(db: &![Connection[Writing], R]): Unit is
        @query(&~db, "SELECT name FROM users") for row: Person[Q] do
            printLn(row.name);
        else error do
            printLn(describe(error));
        end for;
        return nil;
    end;

    function main(): ExitCode is
        case openWriter(":memory:") of
            when Left(left as error: SqlError) do
                printLn(describe(error));
                return ExitFailure();
            when Right(right as opened: Connection[Writing]) do
                var db: Connection[Writing] := opened;
                case migrate(&!db, @migrations) of
                    when Left(left as error: SqlError) do
                        printLn(describe(error));
                    when Right(right as applied: Index) do
                        run(&!db);
                end case;
                closeDatabase(db);
                return ExitSuccess();
        end case;
    end;
end module body.
```

Daneben `migrations/1-schema.sql`:

```sql file migrations/1-schema.sql
CREATE TABLE users (
    id INTEGER PRIMARY KEY,
    name TEXT NOT NULL,
    born TEXT
) STRICT;
```

### H8089

Meldung:

```text
Generic Error
migration: table users exists already
```

Eine Migration legt eine Tabelle an, die es schon gibt.

Dieses Modul scheitert mit H8089:

```hilde fails H8089
import Standard.Sqlite (Connection, Writing, SqlError, describe, openWriter, closeDatabase, migrate);

module body Example is
    record Person[R: Region]: Free is
        name: Span[Nat8, R];
    end;

    generic [R: Region]
    function run(db: &![Connection[Writing], R]): Unit is
        @query(&~db, "SELECT name FROM users") for row: Person[Q] do
            printLn(row.name);
        else error do
            printLn(describe(error));
        end for;
        return nil;
    end;

    function main(): ExitCode is
        case openWriter(":memory:") of
            when Left(left as error: SqlError) do
                printLn(describe(error));
                return ExitFailure();
            when Right(right as opened: Connection[Writing]) do
                var db: Connection[Writing] := opened;
                case migrate(&!db, @migrations) of
                    when Left(left as error: SqlError) do
                        printLn(describe(error));
                    when Right(right as applied: Index) do
                        run(&!db);
                end case;
                closeDatabase(db);
                return ExitSuccess();
        end case;
    end;
end module body.
```

Daneben `migrations/1-schema.sql`:

```sql file migrations/1-schema.sql
CREATE TABLE users (
    id INTEGER PRIMARY KEY,
    name TEXT NOT NULL
) STRICT;

CREATE TABLE users (
    id INTEGER PRIMARY KEY,
    name TEXT NOT NULL,
    email TEXT
) STRICT;
```

Die richtige Form:

```hilde
import Standard.Sqlite (Connection, Writing, SqlError, describe, openWriter, closeDatabase, migrate);

module body Example is
    record Person[R: Region]: Free is
        name: Span[Nat8, R];
    end;

    generic [R: Region]
    function run(db: &![Connection[Writing], R]): Unit is
        @query(&~db, "SELECT name FROM users") for row: Person[Q] do
            printLn(row.name);
        else error do
            printLn(describe(error));
        end for;
        return nil;
    end;

    function main(): ExitCode is
        case openWriter(":memory:") of
            when Left(left as error: SqlError) do
                printLn(describe(error));
                return ExitFailure();
            when Right(right as opened: Connection[Writing]) do
                var db: Connection[Writing] := opened;
                case migrate(&!db, @migrations) of
                    when Left(left as error: SqlError) do
                        printLn(describe(error));
                    when Right(right as applied: Index) do
                        run(&!db);
                end case;
                closeDatabase(db);
                return ExitSuccess();
        end case;
    end;
end module body.
```

Daneben `migrations/1-schema.sql`:

```sql file migrations/1-schema.sql
CREATE TABLE users (
    id INTEGER PRIMARY KEY,
    name TEXT NOT NULL
) STRICT;

ALTER TABLE users ADD COLUMN email TEXT;
```

### H8090

Meldung:

```text
Generic Error
migration: table users is not STRICT: without STRICT, SQLite stores a value of any type in any column, and the types the compiler checks would not hold
```

Eine Tabelle wird ohne STRICT angelegt. Ohne STRICT speichert SQLite einen
Wert jedes Typs in jeder Spalte, und die Typen, die der Compiler prüft,
würden nicht gelten.

Dieses Modul scheitert mit H8090:

```hilde fails H8090
import Standard.Sqlite (Connection, Writing, SqlError, describe, openWriter, closeDatabase, migrate);

module body Example is
    record Person[R: Region]: Free is
        name: Span[Nat8, R];
    end;

    generic [R: Region]
    function run(db: &![Connection[Writing], R]): Unit is
        @query(&~db, "SELECT name FROM users") for row: Person[Q] do
            printLn(row.name);
        else error do
            printLn(describe(error));
        end for;
        return nil;
    end;

    function main(): ExitCode is
        case openWriter(":memory:") of
            when Left(left as error: SqlError) do
                printLn(describe(error));
                return ExitFailure();
            when Right(right as opened: Connection[Writing]) do
                var db: Connection[Writing] := opened;
                case migrate(&!db, @migrations) of
                    when Left(left as error: SqlError) do
                        printLn(describe(error));
                    when Right(right as applied: Index) do
                        run(&!db);
                end case;
                closeDatabase(db);
                return ExitSuccess();
        end case;
    end;
end module body.
```

Daneben `migrations/1-schema.sql`:

```sql file migrations/1-schema.sql
CREATE TABLE users (
    id INTEGER PRIMARY KEY,
    name TEXT NOT NULL
);
```

Die richtige Form:

```hilde
import Standard.Sqlite (Connection, Writing, SqlError, describe, openWriter, closeDatabase, migrate);

module body Example is
    record Person[R: Region]: Free is
        name: Span[Nat8, R];
    end;

    generic [R: Region]
    function run(db: &![Connection[Writing], R]): Unit is
        @query(&~db, "SELECT name FROM users") for row: Person[Q] do
            printLn(row.name);
        else error do
            printLn(describe(error));
        end for;
        return nil;
    end;

    function main(): ExitCode is
        case openWriter(":memory:") of
            when Left(left as error: SqlError) do
                printLn(describe(error));
                return ExitFailure();
            when Right(right as opened: Connection[Writing]) do
                var db: Connection[Writing] := opened;
                case migrate(&!db, @migrations) of
                    when Left(left as error: SqlError) do
                        printLn(describe(error));
                    when Right(right as applied: Index) do
                        run(&!db);
                end case;
                closeDatabase(db);
                return ExitSuccess();
        end case;
    end;
end module body.
```

Daneben `migrations/1-schema.sql`:

```sql file migrations/1-schema.sql
CREATE TABLE users (
    id INTEGER PRIMARY KEY,
    name TEXT NOT NULL
) STRICT;
```

### H8091

Meldung:

```text
Generic Error
migration: column name is defined twice
```

Eine Tabelle definiert eine Spalte zweimal.

Dieses Modul scheitert mit H8091:

```hilde fails H8091
import Standard.Sqlite (Connection, Writing, SqlError, describe, openWriter, closeDatabase, migrate);

module body Example is
    record Person[R: Region]: Free is
        name: Span[Nat8, R];
    end;

    generic [R: Region]
    function run(db: &![Connection[Writing], R]): Unit is
        @query(&~db, "SELECT name FROM users") for row: Person[Q] do
            printLn(row.name);
        else error do
            printLn(describe(error));
        end for;
        return nil;
    end;

    function main(): ExitCode is
        case openWriter(":memory:") of
            when Left(left as error: SqlError) do
                printLn(describe(error));
                return ExitFailure();
            when Right(right as opened: Connection[Writing]) do
                var db: Connection[Writing] := opened;
                case migrate(&!db, @migrations) of
                    when Left(left as error: SqlError) do
                        printLn(describe(error));
                    when Right(right as applied: Index) do
                        run(&!db);
                end case;
                closeDatabase(db);
                return ExitSuccess();
        end case;
    end;
end module body.
```

Daneben `migrations/1-schema.sql`:

```sql file migrations/1-schema.sql
CREATE TABLE users (
    id INTEGER PRIMARY KEY,
    name TEXT NOT NULL,
    name TEXT
) STRICT;
```

Die richtige Form:

```hilde
import Standard.Sqlite (Connection, Writing, SqlError, describe, openWriter, closeDatabase, migrate);

module body Example is
    record Person[R: Region]: Free is
        name: Span[Nat8, R];
    end;

    generic [R: Region]
    function run(db: &![Connection[Writing], R]): Unit is
        @query(&~db, "SELECT name FROM users") for row: Person[Q] do
            printLn(row.name);
        else error do
            printLn(describe(error));
        end for;
        return nil;
    end;

    function main(): ExitCode is
        case openWriter(":memory:") of
            when Left(left as error: SqlError) do
                printLn(describe(error));
                return ExitFailure();
            when Right(right as opened: Connection[Writing]) do
                var db: Connection[Writing] := opened;
                case migrate(&!db, @migrations) of
                    when Left(left as error: SqlError) do
                        printLn(describe(error));
                    when Right(right as applied: Index) do
                        run(&!db);
                end case;
                closeDatabase(db);
                return ExitSuccess();
        end case;
    end;
end module body.
```

Daneben `migrations/1-schema.sql`:

```sql file migrations/1-schema.sql
CREATE TABLE users (
    id INTEGER PRIMARY KEY,
    name TEXT NOT NULL,
    nickname TEXT
) STRICT;
```

### H8092

Meldung:

```text
Generic Error
migration: table users has more than one PRIMARY KEY
```

Eine Tabelle hat mehr als einen PRIMARY KEY.

Dieses Modul scheitert mit H8092:

```hilde fails H8092
import Standard.Sqlite (Connection, Writing, SqlError, describe, openWriter, closeDatabase, migrate);

module body Example is
    record Person[R: Region]: Free is
        name: Span[Nat8, R];
    end;

    generic [R: Region]
    function run(db: &![Connection[Writing], R]): Unit is
        @query(&~db, "SELECT name FROM users") for row: Person[Q] do
            printLn(row.name);
        else error do
            printLn(describe(error));
        end for;
        return nil;
    end;

    function main(): ExitCode is
        case openWriter(":memory:") of
            when Left(left as error: SqlError) do
                printLn(describe(error));
                return ExitFailure();
            when Right(right as opened: Connection[Writing]) do
                var db: Connection[Writing] := opened;
                case migrate(&!db, @migrations) of
                    when Left(left as error: SqlError) do
                        printLn(describe(error));
                    when Right(right as applied: Index) do
                        run(&!db);
                end case;
                closeDatabase(db);
                return ExitSuccess();
        end case;
    end;
end module body.
```

Daneben `migrations/1-schema.sql`:

```sql file migrations/1-schema.sql
CREATE TABLE users (
    id INTEGER PRIMARY KEY,
    name TEXT NOT NULL PRIMARY KEY
) STRICT;
```

Die richtige Form:

```hilde
import Standard.Sqlite (Connection, Writing, SqlError, describe, openWriter, closeDatabase, migrate);

module body Example is
    record Person[R: Region]: Free is
        name: Span[Nat8, R];
    end;

    generic [R: Region]
    function run(db: &![Connection[Writing], R]): Unit is
        @query(&~db, "SELECT name FROM users") for row: Person[Q] do
            printLn(row.name);
        else error do
            printLn(describe(error));
        end for;
        return nil;
    end;

    function main(): ExitCode is
        case openWriter(":memory:") of
            when Left(left as error: SqlError) do
                printLn(describe(error));
                return ExitFailure();
            when Right(right as opened: Connection[Writing]) do
                var db: Connection[Writing] := opened;
                case migrate(&!db, @migrations) of
                    when Left(left as error: SqlError) do
                        printLn(describe(error));
                    when Right(right as applied: Index) do
                        run(&!db);
                end case;
                closeDatabase(db);
                return ExitSuccess();
        end case;
    end;
end module body.
```

Daneben `migrations/1-schema.sql`:

```sql file migrations/1-schema.sql
CREATE TABLE users (
    id INTEGER PRIMARY KEY,
    name TEXT NOT NULL UNIQUE
) STRICT;
```

### H8093

Meldung:

```text
Generic Error
migration: the PRIMARY KEY names user_id, which is not a column of users
```

Der PRIMARY KEY einer Tabelle nennt eine Spalte, die die Tabelle nicht hat.

Dieses Modul scheitert mit H8093:

```hilde fails H8093
import Standard.Sqlite (Connection, Writing, SqlError, describe, openWriter, closeDatabase, migrate);

module body Example is
    record Person[R: Region]: Free is
        name: Span[Nat8, R];
    end;

    generic [R: Region]
    function run(db: &![Connection[Writing], R]): Unit is
        @query(&~db, "SELECT name FROM users") for row: Person[Q] do
            printLn(row.name);
        else error do
            printLn(describe(error));
        end for;
        return nil;
    end;

    function main(): ExitCode is
        case openWriter(":memory:") of
            when Left(left as error: SqlError) do
                printLn(describe(error));
                return ExitFailure();
            when Right(right as opened: Connection[Writing]) do
                var db: Connection[Writing] := opened;
                case migrate(&!db, @migrations) of
                    when Left(left as error: SqlError) do
                        printLn(describe(error));
                    when Right(right as applied: Index) do
                        run(&!db);
                end case;
                closeDatabase(db);
                return ExitSuccess();
        end case;
    end;
end module body.
```

Daneben `migrations/1-schema.sql`:

```sql file migrations/1-schema.sql
CREATE TABLE users (
    id INTEGER,
    name TEXT NOT NULL,
    PRIMARY KEY (user_id)
) STRICT;
```

Die richtige Form:

```hilde
import Standard.Sqlite (Connection, Writing, SqlError, describe, openWriter, closeDatabase, migrate);

module body Example is
    record Person[R: Region]: Free is
        name: Span[Nat8, R];
    end;

    generic [R: Region]
    function run(db: &![Connection[Writing], R]): Unit is
        @query(&~db, "SELECT name FROM users") for row: Person[Q] do
            printLn(row.name);
        else error do
            printLn(describe(error));
        end for;
        return nil;
    end;

    function main(): ExitCode is
        case openWriter(":memory:") of
            when Left(left as error: SqlError) do
                printLn(describe(error));
                return ExitFailure();
            when Right(right as opened: Connection[Writing]) do
                var db: Connection[Writing] := opened;
                case migrate(&!db, @migrations) of
                    when Left(left as error: SqlError) do
                        printLn(describe(error));
                    when Right(right as applied: Index) do
                        run(&!db);
                end case;
                closeDatabase(db);
                return ExitSuccess();
        end case;
    end;
end module body.
```

Daneben `migrations/1-schema.sql`:

```sql file migrations/1-schema.sql
CREATE TABLE users (
    id INTEGER,
    name TEXT NOT NULL,
    PRIMARY KEY (id)
) STRICT;
```

### H8094

Meldung:

```text
Generic Error
migration: table users has a column name already
```

ALTER TABLE ADD COLUMN fügt eine Spalte hinzu, die die Tabelle schon hat.

Dieses Modul scheitert mit H8094:

```hilde fails H8094
import Standard.Sqlite (Connection, Writing, SqlError, describe, openWriter, closeDatabase, migrate);

module body Example is
    record Person[R: Region]: Free is
        name: Span[Nat8, R];
    end;

    generic [R: Region]
    function run(db: &![Connection[Writing], R]): Unit is
        @query(&~db, "SELECT name FROM users") for row: Person[Q] do
            printLn(row.name);
        else error do
            printLn(describe(error));
        end for;
        return nil;
    end;

    function main(): ExitCode is
        case openWriter(":memory:") of
            when Left(left as error: SqlError) do
                printLn(describe(error));
                return ExitFailure();
            when Right(right as opened: Connection[Writing]) do
                var db: Connection[Writing] := opened;
                case migrate(&!db, @migrations) of
                    when Left(left as error: SqlError) do
                        printLn(describe(error));
                    when Right(right as applied: Index) do
                        run(&!db);
                end case;
                closeDatabase(db);
                return ExitSuccess();
        end case;
    end;
end module body.
```

Daneben `migrations/1-schema.sql`:

```sql file migrations/1-schema.sql
CREATE TABLE users (
    id INTEGER PRIMARY KEY,
    name TEXT NOT NULL
) STRICT;

ALTER TABLE users ADD COLUMN name TEXT;
```

Die richtige Form:

```hilde
import Standard.Sqlite (Connection, Writing, SqlError, describe, openWriter, closeDatabase, migrate);

module body Example is
    record Person[R: Region]: Free is
        name: Span[Nat8, R];
    end;

    generic [R: Region]
    function run(db: &![Connection[Writing], R]): Unit is
        @query(&~db, "SELECT name FROM users") for row: Person[Q] do
            printLn(row.name);
        else error do
            printLn(describe(error));
        end for;
        return nil;
    end;

    function main(): ExitCode is
        case openWriter(":memory:") of
            when Left(left as error: SqlError) do
                printLn(describe(error));
                return ExitFailure();
            when Right(right as opened: Connection[Writing]) do
                var db: Connection[Writing] := opened;
                case migrate(&!db, @migrations) of
                    when Left(left as error: SqlError) do
                        printLn(describe(error));
                    when Right(right as applied: Index) do
                        run(&!db);
                end case;
                closeDatabase(db);
                return ExitSuccess();
        end case;
    end;
end module body.
```

Daneben `migrations/1-schema.sql`:

```sql file migrations/1-schema.sql
CREATE TABLE users (
    id INTEGER PRIMARY KEY,
    name TEXT NOT NULL
) STRICT;

ALTER TABLE users ADD COLUMN nickname TEXT;
```

### H8095

Meldung:

```text
Generic Error
migration: ALTER TABLE ADD COLUMN cannot add a PRIMARY KEY
```

ALTER TABLE ADD COLUMN fügt einen PRIMARY KEY hinzu. SQLite kann einer
bestehenden Tabelle keinen hinzufügen.

Dieses Modul scheitert mit H8095:

```hilde fails H8095
import Standard.Sqlite (Connection, Writing, SqlError, describe, openWriter, closeDatabase, migrate);

module body Example is
    record Person[R: Region]: Free is
        name: Span[Nat8, R];
    end;

    generic [R: Region]
    function run(db: &![Connection[Writing], R]): Unit is
        @query(&~db, "SELECT name FROM users") for row: Person[Q] do
            printLn(row.name);
        else error do
            printLn(describe(error));
        end for;
        return nil;
    end;

    function main(): ExitCode is
        case openWriter(":memory:") of
            when Left(left as error: SqlError) do
                printLn(describe(error));
                return ExitFailure();
            when Right(right as opened: Connection[Writing]) do
                var db: Connection[Writing] := opened;
                case migrate(&!db, @migrations) of
                    when Left(left as error: SqlError) do
                        printLn(describe(error));
                    when Right(right as applied: Index) do
                        run(&!db);
                end case;
                closeDatabase(db);
                return ExitSuccess();
        end case;
    end;
end module body.
```

Daneben `migrations/1-schema.sql`:

```sql file migrations/1-schema.sql
CREATE TABLE users (
    id INTEGER PRIMARY KEY,
    name TEXT NOT NULL
) STRICT;

ALTER TABLE users ADD COLUMN code INTEGER PRIMARY KEY;
```

Die richtige Form:

```hilde
import Standard.Sqlite (Connection, Writing, SqlError, describe, openWriter, closeDatabase, migrate);

module body Example is
    record Person[R: Region]: Free is
        name: Span[Nat8, R];
    end;

    generic [R: Region]
    function run(db: &![Connection[Writing], R]): Unit is
        @query(&~db, "SELECT name FROM users") for row: Person[Q] do
            printLn(row.name);
        else error do
            printLn(describe(error));
        end for;
        return nil;
    end;

    function main(): ExitCode is
        case openWriter(":memory:") of
            when Left(left as error: SqlError) do
                printLn(describe(error));
                return ExitFailure();
            when Right(right as opened: Connection[Writing]) do
                var db: Connection[Writing] := opened;
                case migrate(&!db, @migrations) of
                    when Left(left as error: SqlError) do
                        printLn(describe(error));
                    when Right(right as applied: Index) do
                        run(&!db);
                end case;
                closeDatabase(db);
                return ExitSuccess();
        end case;
    end;
end module body.
```

Daneben `migrations/1-schema.sql`:

```sql file migrations/1-schema.sql
CREATE TABLE users (
    id INTEGER PRIMARY KEY,
    name TEXT NOT NULL
) STRICT;

ALTER TABLE users ADD COLUMN code INTEGER;

CREATE UNIQUE INDEX users_code ON users (code);
```

### H8096

Meldung:

```text
Generic Error
migration: city is NOT NULL without a DEFAULT, and SQLite refuses to add such a column to a table that has rows
```

ALTER TABLE ADD COLUMN fügt eine NOT-NULL-Spalte ohne Vorgabewert hinzu.
SQLite lehnt eine solche Spalte bei einer Tabelle mit Zeilen ab.

Dieses Modul scheitert mit H8096:

```hilde fails H8096
import Standard.Sqlite (Connection, Writing, SqlError, describe, openWriter, closeDatabase, migrate);

module body Example is
    record Person[R: Region]: Free is
        name: Span[Nat8, R];
    end;

    generic [R: Region]
    function run(db: &![Connection[Writing], R]): Unit is
        @query(&~db, "SELECT name FROM users") for row: Person[Q] do
            printLn(row.name);
        else error do
            printLn(describe(error));
        end for;
        return nil;
    end;

    function main(): ExitCode is
        case openWriter(":memory:") of
            when Left(left as error: SqlError) do
                printLn(describe(error));
                return ExitFailure();
            when Right(right as opened: Connection[Writing]) do
                var db: Connection[Writing] := opened;
                case migrate(&!db, @migrations) of
                    when Left(left as error: SqlError) do
                        printLn(describe(error));
                    when Right(right as applied: Index) do
                        run(&!db);
                end case;
                closeDatabase(db);
                return ExitSuccess();
        end case;
    end;
end module body.
```

Daneben `migrations/1-schema.sql`:

```sql file migrations/1-schema.sql
CREATE TABLE users (
    id INTEGER PRIMARY KEY,
    name TEXT NOT NULL
) STRICT;

ALTER TABLE users ADD COLUMN city TEXT NOT NULL;
```

Die richtige Form:

```hilde
import Standard.Sqlite (Connection, Writing, SqlError, describe, openWriter, closeDatabase, migrate);

module body Example is
    record Person[R: Region]: Free is
        name: Span[Nat8, R];
    end;

    generic [R: Region]
    function run(db: &![Connection[Writing], R]): Unit is
        @query(&~db, "SELECT name FROM users") for row: Person[Q] do
            printLn(row.name);
        else error do
            printLn(describe(error));
        end for;
        return nil;
    end;

    function main(): ExitCode is
        case openWriter(":memory:") of
            when Left(left as error: SqlError) do
                printLn(describe(error));
                return ExitFailure();
            when Right(right as opened: Connection[Writing]) do
                var db: Connection[Writing] := opened;
                case migrate(&!db, @migrations) of
                    when Left(left as error: SqlError) do
                        printLn(describe(error));
                    when Right(right as applied: Index) do
                        run(&!db);
                end case;
                closeDatabase(db);
                return ExitSuccess();
        end case;
    end;
end module body.
```

Daneben `migrations/1-schema.sql`:

```sql file migrations/1-schema.sql
CREATE TABLE users (
    id INTEGER PRIMARY KEY,
    name TEXT NOT NULL
) STRICT;

ALTER TABLE users ADD COLUMN city TEXT NOT NULL DEFAULT '';
```

### H8097

Meldung:

```text
Generic Error
migration: table users exists already
```

ALTER TABLE RENAME TO gibt einer Tabelle den Namen einer Tabelle, die es
gibt.

Dieses Modul scheitert mit H8097:

```hilde fails H8097
import Standard.Sqlite (Connection, Writing, SqlError, describe, openWriter, closeDatabase, migrate);

module body Example is
    record Person[R: Region]: Free is
        name: Span[Nat8, R];
    end;

    generic [R: Region]
    function run(db: &![Connection[Writing], R]): Unit is
        @query(&~db, "SELECT name FROM users") for row: Person[Q] do
            printLn(row.name);
        else error do
            printLn(describe(error));
        end for;
        return nil;
    end;

    function main(): ExitCode is
        case openWriter(":memory:") of
            when Left(left as error: SqlError) do
                printLn(describe(error));
                return ExitFailure();
            when Right(right as opened: Connection[Writing]) do
                var db: Connection[Writing] := opened;
                case migrate(&!db, @migrations) of
                    when Left(left as error: SqlError) do
                        printLn(describe(error));
                    when Right(right as applied: Index) do
                        run(&!db);
                end case;
                closeDatabase(db);
                return ExitSuccess();
        end case;
    end;
end module body.
```

Daneben `migrations/1-schema.sql`:

```sql file migrations/1-schema.sql
CREATE TABLE users (
    id INTEGER PRIMARY KEY,
    name TEXT NOT NULL
) STRICT;

CREATE TABLE people (
    id INTEGER PRIMARY KEY,
    name TEXT NOT NULL
) STRICT;

ALTER TABLE people RENAME TO users;
```

Die richtige Form:

```hilde
import Standard.Sqlite (Connection, Writing, SqlError, describe, openWriter, closeDatabase, migrate);

module body Example is
    record Person[R: Region]: Free is
        name: Span[Nat8, R];
    end;

    generic [R: Region]
    function run(db: &![Connection[Writing], R]): Unit is
        @query(&~db, "SELECT name FROM users") for row: Person[Q] do
            printLn(row.name);
        else error do
            printLn(describe(error));
        end for;
        return nil;
    end;

    function main(): ExitCode is
        case openWriter(":memory:") of
            when Left(left as error: SqlError) do
                printLn(describe(error));
                return ExitFailure();
            when Right(right as opened: Connection[Writing]) do
                var db: Connection[Writing] := opened;
                case migrate(&!db, @migrations) of
                    when Left(left as error: SqlError) do
                        printLn(describe(error));
                    when Right(right as applied: Index) do
                        run(&!db);
                end case;
                closeDatabase(db);
                return ExitSuccess();
        end case;
    end;
end module body.
```

Daneben `migrations/1-schema.sql`:

```sql file migrations/1-schema.sql
CREATE TABLE users (
    id INTEGER PRIMARY KEY,
    name TEXT NOT NULL
) STRICT;

CREATE TABLE people (
    id INTEGER PRIMARY KEY,
    name TEXT NOT NULL
) STRICT;

DROP TABLE users;

ALTER TABLE people RENAME TO users;
```

### H8098

Meldung:

```text
Generic Error
migration: table users has a column name already
```

ALTER TABLE RENAME COLUMN gibt einer Spalte den Namen einer Spalte, die die
Tabelle hat.

Dieses Modul scheitert mit H8098:

```hilde fails H8098
import Standard.Sqlite (Connection, Writing, SqlError, describe, openWriter, closeDatabase, migrate);

module body Example is
    record Person[R: Region]: Free is
        name: Span[Nat8, R];
    end;

    generic [R: Region]
    function run(db: &![Connection[Writing], R]): Unit is
        @query(&~db, "SELECT name FROM users") for row: Person[Q] do
            printLn(row.name);
        else error do
            printLn(describe(error));
        end for;
        return nil;
    end;

    function main(): ExitCode is
        case openWriter(":memory:") of
            when Left(left as error: SqlError) do
                printLn(describe(error));
                return ExitFailure();
            when Right(right as opened: Connection[Writing]) do
                var db: Connection[Writing] := opened;
                case migrate(&!db, @migrations) of
                    when Left(left as error: SqlError) do
                        printLn(describe(error));
                    when Right(right as applied: Index) do
                        run(&!db);
                end case;
                closeDatabase(db);
                return ExitSuccess();
        end case;
    end;
end module body.
```

Daneben `migrations/1-schema.sql`:

```sql file migrations/1-schema.sql
CREATE TABLE users (
    id INTEGER PRIMARY KEY,
    name TEXT NOT NULL,
    email TEXT
) STRICT;

ALTER TABLE users RENAME COLUMN email TO name;
```

Die richtige Form:

```hilde
import Standard.Sqlite (Connection, Writing, SqlError, describe, openWriter, closeDatabase, migrate);

module body Example is
    record Person[R: Region]: Free is
        name: Span[Nat8, R];
    end;

    generic [R: Region]
    function run(db: &![Connection[Writing], R]): Unit is
        @query(&~db, "SELECT name FROM users") for row: Person[Q] do
            printLn(row.name);
        else error do
            printLn(describe(error));
        end for;
        return nil;
    end;

    function main(): ExitCode is
        case openWriter(":memory:") of
            when Left(left as error: SqlError) do
                printLn(describe(error));
                return ExitFailure();
            when Right(right as opened: Connection[Writing]) do
                var db: Connection[Writing] := opened;
                case migrate(&!db, @migrations) of
                    when Left(left as error: SqlError) do
                        printLn(describe(error));
                    when Right(right as applied: Index) do
                        run(&!db);
                end case;
                closeDatabase(db);
                return ExitSuccess();
        end case;
    end;
end module body.
```

Daneben `migrations/1-schema.sql`:

```sql file migrations/1-schema.sql
CREATE TABLE users (
    id INTEGER PRIMARY KEY,
    name TEXT NOT NULL,
    email TEXT
) STRICT;

ALTER TABLE users RENAME COLUMN email TO mail;
```

### H8099

Meldung:

```text
Generic Error
migration: a table cannot lose its last column
```

ALTER TABLE DROP COLUMN löscht die letzte Spalte einer Tabelle. Stattdessen
löscht man die Tabelle.

Dieses Modul scheitert mit H8099:

```hilde fails H8099
import Standard.Sqlite (Connection, Writing, SqlError, describe, openWriter, closeDatabase, migrate);

module body Example is
    record Person[R: Region]: Free is
        name: Span[Nat8, R];
    end;

    generic [R: Region]
    function run(db: &![Connection[Writing], R]): Unit is
        @query(&~db, "SELECT name FROM users") for row: Person[Q] do
            printLn(row.name);
        else error do
            printLn(describe(error));
        end for;
        return nil;
    end;

    function main(): ExitCode is
        case openWriter(":memory:") of
            when Left(left as error: SqlError) do
                printLn(describe(error));
                return ExitFailure();
            when Right(right as opened: Connection[Writing]) do
                var db: Connection[Writing] := opened;
                case migrate(&!db, @migrations) of
                    when Left(left as error: SqlError) do
                        printLn(describe(error));
                    when Right(right as applied: Index) do
                        run(&!db);
                end case;
                closeDatabase(db);
                return ExitSuccess();
        end case;
    end;
end module body.
```

Daneben `migrations/1-schema.sql`:

```sql file migrations/1-schema.sql
CREATE TABLE users (
    id INTEGER PRIMARY KEY,
    name TEXT NOT NULL
) STRICT;

CREATE TABLE tags (label TEXT) STRICT;

ALTER TABLE tags DROP COLUMN label;
```

Die richtige Form:

```hilde
import Standard.Sqlite (Connection, Writing, SqlError, describe, openWriter, closeDatabase, migrate);

module body Example is
    record Person[R: Region]: Free is
        name: Span[Nat8, R];
    end;

    generic [R: Region]
    function run(db: &![Connection[Writing], R]): Unit is
        @query(&~db, "SELECT name FROM users") for row: Person[Q] do
            printLn(row.name);
        else error do
            printLn(describe(error));
        end for;
        return nil;
    end;

    function main(): ExitCode is
        case openWriter(":memory:") of
            when Left(left as error: SqlError) do
                printLn(describe(error));
                return ExitFailure();
            when Right(right as opened: Connection[Writing]) do
                var db: Connection[Writing] := opened;
                case migrate(&!db, @migrations) of
                    when Left(left as error: SqlError) do
                        printLn(describe(error));
                    when Right(right as applied: Index) do
                        run(&!db);
                end case;
                closeDatabase(db);
                return ExitSuccess();
        end case;
    end;
end module body.
```

Daneben `migrations/1-schema.sql`:

```sql file migrations/1-schema.sql
CREATE TABLE users (
    id INTEGER PRIMARY KEY,
    name TEXT NOT NULL
) STRICT;

CREATE TABLE tags (label TEXT) STRICT;

DROP TABLE tags;
```

### H8100

Meldung:

```text
Generic Error
migration: there is no table tags to drop
```

DROP TABLE löscht eine Tabelle, die es nicht gibt.

Dieses Modul scheitert mit H8100:

```hilde fails H8100
import Standard.Sqlite (Connection, Writing, SqlError, describe, openWriter, closeDatabase, migrate);

module body Example is
    record Person[R: Region]: Free is
        name: Span[Nat8, R];
    end;

    generic [R: Region]
    function run(db: &![Connection[Writing], R]): Unit is
        @query(&~db, "SELECT name FROM users") for row: Person[Q] do
            printLn(row.name);
        else error do
            printLn(describe(error));
        end for;
        return nil;
    end;

    function main(): ExitCode is
        case openWriter(":memory:") of
            when Left(left as error: SqlError) do
                printLn(describe(error));
                return ExitFailure();
            when Right(right as opened: Connection[Writing]) do
                var db: Connection[Writing] := opened;
                case migrate(&!db, @migrations) of
                    when Left(left as error: SqlError) do
                        printLn(describe(error));
                    when Right(right as applied: Index) do
                        run(&!db);
                end case;
                closeDatabase(db);
                return ExitSuccess();
        end case;
    end;
end module body.
```

Daneben `migrations/1-schema.sql`:

```sql file migrations/1-schema.sql
CREATE TABLE users (
    id INTEGER PRIMARY KEY,
    name TEXT NOT NULL
) STRICT;

DROP TABLE tags;
```

Die richtige Form:

```hilde
import Standard.Sqlite (Connection, Writing, SqlError, describe, openWriter, closeDatabase, migrate);

module body Example is
    record Person[R: Region]: Free is
        name: Span[Nat8, R];
    end;

    generic [R: Region]
    function run(db: &![Connection[Writing], R]): Unit is
        @query(&~db, "SELECT name FROM users") for row: Person[Q] do
            printLn(row.name);
        else error do
            printLn(describe(error));
        end for;
        return nil;
    end;

    function main(): ExitCode is
        case openWriter(":memory:") of
            when Left(left as error: SqlError) do
                printLn(describe(error));
                return ExitFailure();
            when Right(right as opened: Connection[Writing]) do
                var db: Connection[Writing] := opened;
                case migrate(&!db, @migrations) of
                    when Left(left as error: SqlError) do
                        printLn(describe(error));
                    when Right(right as applied: Index) do
                        run(&!db);
                end case;
                closeDatabase(db);
                return ExitSuccess();
        end case;
    end;
end module body.
```

Daneben `migrations/1-schema.sql`:

```sql file migrations/1-schema.sql
CREATE TABLE users (
    id INTEGER PRIMARY KEY,
    name TEXT NOT NULL
) STRICT;

DROP TABLE IF EXISTS tags;
```

### H8101

Meldung:

```text
Generic Error
migration: index users_key exists already
```

CREATE INDEX legt einen Index an, dessen Name schon vergeben ist.

Dieses Modul scheitert mit H8101:

```hilde fails H8101
import Standard.Sqlite (Connection, Writing, SqlError, describe, openWriter, closeDatabase, migrate);

module body Example is
    record Person[R: Region]: Free is
        name: Span[Nat8, R];
    end;

    generic [R: Region]
    function run(db: &![Connection[Writing], R]): Unit is
        @query(&~db, "SELECT name FROM users") for row: Person[Q] do
            printLn(row.name);
        else error do
            printLn(describe(error));
        end for;
        return nil;
    end;

    function main(): ExitCode is
        case openWriter(":memory:") of
            when Left(left as error: SqlError) do
                printLn(describe(error));
                return ExitFailure();
            when Right(right as opened: Connection[Writing]) do
                var db: Connection[Writing] := opened;
                case migrate(&!db, @migrations) of
                    when Left(left as error: SqlError) do
                        printLn(describe(error));
                    when Right(right as applied: Index) do
                        run(&!db);
                end case;
                closeDatabase(db);
                return ExitSuccess();
        end case;
    end;
end module body.
```

Daneben `migrations/1-schema.sql`:

```sql file migrations/1-schema.sql
CREATE TABLE users (
    id INTEGER PRIMARY KEY,
    name TEXT NOT NULL
) STRICT;

CREATE INDEX users_key ON users (name);

CREATE INDEX users_key ON users (id, name);
```

Die richtige Form:

```hilde
import Standard.Sqlite (Connection, Writing, SqlError, describe, openWriter, closeDatabase, migrate);

module body Example is
    record Person[R: Region]: Free is
        name: Span[Nat8, R];
    end;

    generic [R: Region]
    function run(db: &![Connection[Writing], R]): Unit is
        @query(&~db, "SELECT name FROM users") for row: Person[Q] do
            printLn(row.name);
        else error do
            printLn(describe(error));
        end for;
        return nil;
    end;

    function main(): ExitCode is
        case openWriter(":memory:") of
            when Left(left as error: SqlError) do
                printLn(describe(error));
                return ExitFailure();
            when Right(right as opened: Connection[Writing]) do
                var db: Connection[Writing] := opened;
                case migrate(&!db, @migrations) of
                    when Left(left as error: SqlError) do
                        printLn(describe(error));
                    when Right(right as applied: Index) do
                        run(&!db);
                end case;
                closeDatabase(db);
                return ExitSuccess();
        end case;
    end;
end module body.
```

Daneben `migrations/1-schema.sql`:

```sql file migrations/1-schema.sql
CREATE TABLE users (
    id INTEGER PRIMARY KEY,
    name TEXT NOT NULL
) STRICT;

CREATE INDEX users_key ON users (name);

CREATE INDEX users_id_name ON users (id, name);
```

### H8102

Meldung:

```text
Generic Error
migration: there is no index users_name to drop
```

DROP INDEX löscht einen Index, den es nicht gibt.

Dieses Modul scheitert mit H8102:

```hilde fails H8102
import Standard.Sqlite (Connection, Writing, SqlError, describe, openWriter, closeDatabase, migrate);

module body Example is
    record Person[R: Region]: Free is
        name: Span[Nat8, R];
    end;

    generic [R: Region]
    function run(db: &![Connection[Writing], R]): Unit is
        @query(&~db, "SELECT name FROM users") for row: Person[Q] do
            printLn(row.name);
        else error do
            printLn(describe(error));
        end for;
        return nil;
    end;

    function main(): ExitCode is
        case openWriter(":memory:") of
            when Left(left as error: SqlError) do
                printLn(describe(error));
                return ExitFailure();
            when Right(right as opened: Connection[Writing]) do
                var db: Connection[Writing] := opened;
                case migrate(&!db, @migrations) of
                    when Left(left as error: SqlError) do
                        printLn(describe(error));
                    when Right(right as applied: Index) do
                        run(&!db);
                end case;
                closeDatabase(db);
                return ExitSuccess();
        end case;
    end;
end module body.
```

Daneben `migrations/1-schema.sql`:

```sql file migrations/1-schema.sql
CREATE TABLE users (
    id INTEGER PRIMARY KEY,
    name TEXT NOT NULL
) STRICT;

DROP INDEX users_name;
```

Die richtige Form:

```hilde
import Standard.Sqlite (Connection, Writing, SqlError, describe, openWriter, closeDatabase, migrate);

module body Example is
    record Person[R: Region]: Free is
        name: Span[Nat8, R];
    end;

    generic [R: Region]
    function run(db: &![Connection[Writing], R]): Unit is
        @query(&~db, "SELECT name FROM users") for row: Person[Q] do
            printLn(row.name);
        else error do
            printLn(describe(error));
        end for;
        return nil;
    end;

    function main(): ExitCode is
        case openWriter(":memory:") of
            when Left(left as error: SqlError) do
                printLn(describe(error));
                return ExitFailure();
            when Right(right as opened: Connection[Writing]) do
                var db: Connection[Writing] := opened;
                case migrate(&!db, @migrations) of
                    when Left(left as error: SqlError) do
                        printLn(describe(error));
                    when Right(right as applied: Index) do
                        run(&!db);
                end case;
                closeDatabase(db);
                return ExitSuccess();
        end case;
    end;
end module body.
```

Daneben `migrations/1-schema.sql`:

```sql file migrations/1-schema.sql
CREATE TABLE users (
    id INTEGER PRIMARY KEY,
    name TEXT NOT NULL
) STRICT;

DROP INDEX IF EXISTS users_name;
```

### H8103

Meldung:

```text
Generic Error
@query: cannot read ./migrations/2-more.sql: it is a directory, not a file
```

Eine Migrationsdatei lässt sich nicht lesen, etwa weil ein Verzeichnis den
Namen einer Migration trägt.

Dieses Modul scheitert mit H8103:

```hilde fails H8103
import Standard.Sqlite (Connection, Writing, SqlError, describe, openWriter, closeDatabase, migrate);

module body Example is
    record Person[R: Region]: Free is
        name: Span[Nat8, R];
    end;

    generic [R: Region]
    function run(db: &![Connection[Writing], R]): Unit is
        @query(&~db, "SELECT name FROM users") for row: Person[Q] do
            printLn(row.name);
        else error do
            printLn(describe(error));
        end for;
        return nil;
    end;

    function main(): ExitCode is
        case openWriter(":memory:") of
            when Left(left as error: SqlError) do
                printLn(describe(error));
                return ExitFailure();
            when Right(right as opened: Connection[Writing]) do
                var db: Connection[Writing] := opened;
                case migrate(&!db, @migrations) of
                    when Left(left as error: SqlError) do
                        printLn(describe(error));
                    when Right(right as applied: Index) do
                        run(&!db);
                end case;
                closeDatabase(db);
                return ExitSuccess();
        end case;
    end;
end module body.
```

Daneben `migrations/1-schema.sql`:

```sql file migrations/1-schema.sql
CREATE TABLE users (
    id INTEGER PRIMARY KEY,
    name TEXT NOT NULL
) STRICT;
```

Daneben `migrations/2-more.sql/README`:

```text file migrations/2-more.sql/README
This directory is not a migration.
```

Die richtige Form:

```hilde
import Standard.Sqlite (Connection, Writing, SqlError, describe, openWriter, closeDatabase, migrate);

module body Example is
    record Person[R: Region]: Free is
        name: Span[Nat8, R];
    end;

    generic [R: Region]
    function run(db: &![Connection[Writing], R]): Unit is
        @query(&~db, "SELECT name FROM users") for row: Person[Q] do
            printLn(row.name);
        else error do
            printLn(describe(error));
        end for;
        return nil;
    end;

    function main(): ExitCode is
        case openWriter(":memory:") of
            when Left(left as error: SqlError) do
                printLn(describe(error));
                return ExitFailure();
            when Right(right as opened: Connection[Writing]) do
                var db: Connection[Writing] := opened;
                case migrate(&!db, @migrations) of
                    when Left(left as error: SqlError) do
                        printLn(describe(error));
                    when Right(right as applied: Index) do
                        run(&!db);
                end case;
                closeDatabase(db);
                return ExitSuccess();
        end case;
    end;
end module body.
```

Daneben `migrations/1-schema.sql`:

```sql file migrations/1-schema.sql
CREATE TABLE users (
    id INTEGER PRIMARY KEY,
    name TEXT NOT NULL
) STRICT;
```

### H8104

Meldung:

```text
Generic Error
@query: there is no directory ./migrations: the schema a query is checked against is the migrations beside the module
```

Neben dem Modul gibt es kein Verzeichnis migrations. Das Schema, gegen das
eine Abfrage geprüft wird, entsteht aus den Migrationen in diesem
Verzeichnis.

Dieses Modul scheitert mit H8104:

```hilde fails H8104
import Standard.Sqlite (Connection, Writing, SqlError, describe, openWriter, closeDatabase, migrate);

module body Example is
    record Person[R: Region]: Free is
        name: Span[Nat8, R];
    end;

    generic [R: Region]
    function run(db: &![Connection[Writing], R]): Unit is
        @query(&~db, "SELECT name FROM users") for row: Person[Q] do
            printLn(row.name);
        else error do
            printLn(describe(error));
        end for;
        return nil;
    end;

    function main(): ExitCode is
        case openWriter(":memory:") of
            when Left(left as error: SqlError) do
                printLn(describe(error));
                return ExitFailure();
            when Right(right as opened: Connection[Writing]) do
                var db: Connection[Writing] := opened;
                case migrate(&!db, @migrations) of
                    when Left(left as error: SqlError) do
                        printLn(describe(error));
                    when Right(right as applied: Index) do
                        run(&!db);
                end case;
                closeDatabase(db);
                return ExitSuccess();
        end case;
    end;
end module body.
```

Daneben `migration/1-schema.sql`:

```sql file migration/1-schema.sql
CREATE TABLE users (
    id INTEGER PRIMARY KEY,
    name TEXT NOT NULL
) STRICT;
```

Die richtige Form:

```hilde
import Standard.Sqlite (Connection, Writing, SqlError, describe, openWriter, closeDatabase, migrate);

module body Example is
    record Person[R: Region]: Free is
        name: Span[Nat8, R];
    end;

    generic [R: Region]
    function run(db: &![Connection[Writing], R]): Unit is
        @query(&~db, "SELECT name FROM users") for row: Person[Q] do
            printLn(row.name);
        else error do
            printLn(describe(error));
        end for;
        return nil;
    end;

    function main(): ExitCode is
        case openWriter(":memory:") of
            when Left(left as error: SqlError) do
                printLn(describe(error));
                return ExitFailure();
            when Right(right as opened: Connection[Writing]) do
                var db: Connection[Writing] := opened;
                case migrate(&!db, @migrations) of
                    when Left(left as error: SqlError) do
                        printLn(describe(error));
                    when Right(right as applied: Index) do
                        run(&!db);
                end case;
                closeDatabase(db);
                return ExitSuccess();
        end case;
    end;
end module body.
```

Daneben `migrations/1-schema.sql`:

```sql file migrations/1-schema.sql
CREATE TABLE users (
    id INTEGER PRIMARY KEY,
    name TEXT NOT NULL
) STRICT;
```

### H8105

Meldung:

```text
Generic Error
@query: ./migrations holds no .sql file
```

Das Verzeichnis migrations enthält keine Datei, die auf .sql endet.

Dieses Modul scheitert mit H8105:

```hilde fails H8105
import Standard.Sqlite (Connection, Writing, SqlError, describe, openWriter, closeDatabase, migrate);

module body Example is
    record Person[R: Region]: Free is
        name: Span[Nat8, R];
    end;

    generic [R: Region]
    function run(db: &![Connection[Writing], R]): Unit is
        @query(&~db, "SELECT name FROM users") for row: Person[Q] do
            printLn(row.name);
        else error do
            printLn(describe(error));
        end for;
        return nil;
    end;

    function main(): ExitCode is
        case openWriter(":memory:") of
            when Left(left as error: SqlError) do
                printLn(describe(error));
                return ExitFailure();
            when Right(right as opened: Connection[Writing]) do
                var db: Connection[Writing] := opened;
                case migrate(&!db, @migrations) of
                    when Left(left as error: SqlError) do
                        printLn(describe(error));
                    when Right(right as applied: Index) do
                        run(&!db);
                end case;
                closeDatabase(db);
                return ExitSuccess();
        end case;
    end;
end module body.
```

Daneben `migrations/1-schema.txt`:

```sql file migrations/1-schema.txt
CREATE TABLE users (
    id INTEGER PRIMARY KEY,
    name TEXT NOT NULL
) STRICT;
```

Die richtige Form:

```hilde
import Standard.Sqlite (Connection, Writing, SqlError, describe, openWriter, closeDatabase, migrate);

module body Example is
    record Person[R: Region]: Free is
        name: Span[Nat8, R];
    end;

    generic [R: Region]
    function run(db: &![Connection[Writing], R]): Unit is
        @query(&~db, "SELECT name FROM users") for row: Person[Q] do
            printLn(row.name);
        else error do
            printLn(describe(error));
        end for;
        return nil;
    end;

    function main(): ExitCode is
        case openWriter(":memory:") of
            when Left(left as error: SqlError) do
                printLn(describe(error));
                return ExitFailure();
            when Right(right as opened: Connection[Writing]) do
                var db: Connection[Writing] := opened;
                case migrate(&!db, @migrations) of
                    when Left(left as error: SqlError) do
                        printLn(describe(error));
                    when Right(right as applied: Index) do
                        run(&!db);
                end case;
                closeDatabase(db);
                return ExitSuccess();
        end case;
    end;
end module body.
```

Daneben `migrations/1-schema.sql`:

```sql file migrations/1-schema.sql
CREATE TABLE users (
    id INTEGER PRIMARY KEY,
    name TEXT NOT NULL
) STRICT;
```

### H8106

Meldung:

```text
Generic Error
@query: ./migrations/schema.sql: a migration is called <number>-<name>.sql, numbered from 1
```

Eine Datei in migrations heißt nicht `<Nummer>-<Name>.sql` mit einer Nummer
ab 1.

Dieses Modul scheitert mit H8106:

```hilde fails H8106
import Standard.Sqlite (Connection, Writing, SqlError, describe, openWriter, closeDatabase, migrate);

module body Example is
    record Person[R: Region]: Free is
        name: Span[Nat8, R];
    end;

    generic [R: Region]
    function run(db: &![Connection[Writing], R]): Unit is
        @query(&~db, "SELECT name FROM users") for row: Person[Q] do
            printLn(row.name);
        else error do
            printLn(describe(error));
        end for;
        return nil;
    end;

    function main(): ExitCode is
        case openWriter(":memory:") of
            when Left(left as error: SqlError) do
                printLn(describe(error));
                return ExitFailure();
            when Right(right as opened: Connection[Writing]) do
                var db: Connection[Writing] := opened;
                case migrate(&!db, @migrations) of
                    when Left(left as error: SqlError) do
                        printLn(describe(error));
                    when Right(right as applied: Index) do
                        run(&!db);
                end case;
                closeDatabase(db);
                return ExitSuccess();
        end case;
    end;
end module body.
```

Daneben `migrations/schema.sql`:

```sql file migrations/schema.sql
CREATE TABLE users (
    id INTEGER PRIMARY KEY,
    name TEXT NOT NULL
) STRICT;
```

Die richtige Form:

```hilde
import Standard.Sqlite (Connection, Writing, SqlError, describe, openWriter, closeDatabase, migrate);

module body Example is
    record Person[R: Region]: Free is
        name: Span[Nat8, R];
    end;

    generic [R: Region]
    function run(db: &![Connection[Writing], R]): Unit is
        @query(&~db, "SELECT name FROM users") for row: Person[Q] do
            printLn(row.name);
        else error do
            printLn(describe(error));
        end for;
        return nil;
    end;

    function main(): ExitCode is
        case openWriter(":memory:") of
            when Left(left as error: SqlError) do
                printLn(describe(error));
                return ExitFailure();
            when Right(right as opened: Connection[Writing]) do
                var db: Connection[Writing] := opened;
                case migrate(&!db, @migrations) of
                    when Left(left as error: SqlError) do
                        printLn(describe(error));
                    when Right(right as applied: Index) do
                        run(&!db);
                end case;
                closeDatabase(db);
                return ExitSuccess();
        end case;
    end;
end module body.
```

Daneben `migrations/1-schema.sql`:

```sql file migrations/1-schema.sql
CREATE TABLE users (
    id INTEGER PRIMARY KEY,
    name TEXT NOT NULL
) STRICT;
```

### H8107

Meldung:

```text
Generic Error
@query: ./migrations/3-email.sql: migration 2 is missing or doubled; they are numbered 1, 2, 3 ... without a gap
```

Die Migrationen sind nicht lückenlos mit 1, 2, 3 und so weiter nummeriert,
oder eine Nummer kommt zweimal vor.

Dieses Modul scheitert mit H8107:

```hilde fails H8107
import Standard.Sqlite (Connection, Writing, SqlError, describe, openWriter, closeDatabase, migrate);

module body Example is
    record Person[R: Region]: Free is
        name: Span[Nat8, R];
    end;

    generic [R: Region]
    function run(db: &![Connection[Writing], R]): Unit is
        @query(&~db, "SELECT name FROM users") for row: Person[Q] do
            printLn(row.name);
        else error do
            printLn(describe(error));
        end for;
        return nil;
    end;

    function main(): ExitCode is
        case openWriter(":memory:") of
            when Left(left as error: SqlError) do
                printLn(describe(error));
                return ExitFailure();
            when Right(right as opened: Connection[Writing]) do
                var db: Connection[Writing] := opened;
                case migrate(&!db, @migrations) of
                    when Left(left as error: SqlError) do
                        printLn(describe(error));
                    when Right(right as applied: Index) do
                        run(&!db);
                end case;
                closeDatabase(db);
                return ExitSuccess();
        end case;
    end;
end module body.
```

Daneben `migrations/1-schema.sql`:

```sql file migrations/1-schema.sql
CREATE TABLE users (
    id INTEGER PRIMARY KEY,
    name TEXT NOT NULL
) STRICT;
```

Daneben `migrations/3-email.sql`:

```sql file migrations/3-email.sql
ALTER TABLE users ADD COLUMN email TEXT;
```

Die richtige Form:

```hilde
import Standard.Sqlite (Connection, Writing, SqlError, describe, openWriter, closeDatabase, migrate);

module body Example is
    record Person[R: Region]: Free is
        name: Span[Nat8, R];
    end;

    generic [R: Region]
    function run(db: &![Connection[Writing], R]): Unit is
        @query(&~db, "SELECT name FROM users") for row: Person[Q] do
            printLn(row.name);
        else error do
            printLn(describe(error));
        end for;
        return nil;
    end;

    function main(): ExitCode is
        case openWriter(":memory:") of
            when Left(left as error: SqlError) do
                printLn(describe(error));
                return ExitFailure();
            when Right(right as opened: Connection[Writing]) do
                var db: Connection[Writing] := opened;
                case migrate(&!db, @migrations) of
                    when Left(left as error: SqlError) do
                        printLn(describe(error));
                    when Right(right as applied: Index) do
                        run(&!db);
                end case;
                closeDatabase(db);
                return ExitSuccess();
        end case;
    end;
end module body.
```

Daneben `migrations/1-schema.sql`:

```sql file migrations/1-schema.sql
CREATE TABLE users (
    id INTEGER PRIMARY KEY,
    name TEXT NOT NULL
) STRICT;
```

Daneben `migrations/2-email.sql`:

```sql file migrations/2-email.sql
ALTER TABLE users ADD COLUMN email TEXT;
```

### H8108

Meldung:

```text
Generic Error
migration: expected ; after the statement, found CREATE
```

Auf eine Anweisung in einer Migration folgt kein ;, bevor die nächste
beginnt.

Dieses Modul scheitert mit H8108:

```hilde fails H8108
import Standard.Sqlite (Connection, Writing, SqlError, describe, openWriter, closeDatabase, migrate);

module body Example is
    record Person[R: Region]: Free is
        name: Span[Nat8, R];
    end;

    generic [R: Region]
    function run(db: &![Connection[Writing], R]): Unit is
        @query(&~db, "SELECT name FROM users") for row: Person[Q] do
            printLn(row.name);
        else error do
            printLn(describe(error));
        end for;
        return nil;
    end;

    function main(): ExitCode is
        case openWriter(":memory:") of
            when Left(left as error: SqlError) do
                printLn(describe(error));
                return ExitFailure();
            when Right(right as opened: Connection[Writing]) do
                var db: Connection[Writing] := opened;
                case migrate(&!db, @migrations) of
                    when Left(left as error: SqlError) do
                        printLn(describe(error));
                    when Right(right as applied: Index) do
                        run(&!db);
                end case;
                closeDatabase(db);
                return ExitSuccess();
        end case;
    end;
end module body.
```

Daneben `migrations/1-schema.sql`:

```sql file migrations/1-schema.sql
CREATE TABLE users (
    id INTEGER PRIMARY KEY,
    name TEXT NOT NULL
) STRICT

CREATE INDEX users_name ON users (name);
```

Die richtige Form:

```hilde
import Standard.Sqlite (Connection, Writing, SqlError, describe, openWriter, closeDatabase, migrate);

module body Example is
    record Person[R: Region]: Free is
        name: Span[Nat8, R];
    end;

    generic [R: Region]
    function run(db: &![Connection[Writing], R]): Unit is
        @query(&~db, "SELECT name FROM users") for row: Person[Q] do
            printLn(row.name);
        else error do
            printLn(describe(error));
        end for;
        return nil;
    end;

    function main(): ExitCode is
        case openWriter(":memory:") of
            when Left(left as error: SqlError) do
                printLn(describe(error));
                return ExitFailure();
            when Right(right as opened: Connection[Writing]) do
                var db: Connection[Writing] := opened;
                case migrate(&!db, @migrations) of
                    when Left(left as error: SqlError) do
                        printLn(describe(error));
                    when Right(right as applied: Index) do
                        run(&!db);
                end case;
                closeDatabase(db);
                return ExitSuccess();
        end case;
    end;
end module body.
```

Daneben `migrations/1-schema.sql`:

```sql file migrations/1-schema.sql
CREATE TABLE users (
    id INTEGER PRIMARY KEY,
    name TEXT NOT NULL
) STRICT;

CREATE INDEX users_name ON users (name);
```

### H8109

Meldung:

```text
Generic Error
migration: a migration has no parameters
```

Eine Migration enthält einen Parameter ?. Eine Migration läuft so, wie sie
dasteht; ein Parameter darin hat nichts, wofür er stehen könnte.

Dieses Modul scheitert mit H8109:

```hilde fails H8109
import Standard.Sqlite (Connection, Writing, SqlError, describe, openWriter, closeDatabase, migrate);

module body Example is
    record Person[R: Region]: Free is
        name: Span[Nat8, R];
    end;

    generic [R: Region]
    function run(db: &![Connection[Writing], R]): Unit is
        @query(&~db, "SELECT name FROM users") for row: Person[Q] do
            printLn(row.name);
        else error do
            printLn(describe(error));
        end for;
        return nil;
    end;

    function main(): ExitCode is
        case openWriter(":memory:") of
            when Left(left as error: SqlError) do
                printLn(describe(error));
                return ExitFailure();
            when Right(right as opened: Connection[Writing]) do
                var db: Connection[Writing] := opened;
                case migrate(&!db, @migrations) of
                    when Left(left as error: SqlError) do
                        printLn(describe(error));
                    when Right(right as applied: Index) do
                        run(&!db);
                end case;
                closeDatabase(db);
                return ExitSuccess();
        end case;
    end;
end module body.
```

Daneben `migrations/1-schema.sql`:

```sql file migrations/1-schema.sql
CREATE TABLE users (
    id INTEGER PRIMARY KEY,
    name TEXT NOT NULL
) STRICT;

INSERT INTO users (name) VALUES (?);
```

Die richtige Form:

```hilde
import Standard.Sqlite (Connection, Writing, SqlError, describe, openWriter, closeDatabase, migrate);

module body Example is
    record Person[R: Region]: Free is
        name: Span[Nat8, R];
    end;

    generic [R: Region]
    function run(db: &![Connection[Writing], R]): Unit is
        @query(&~db, "SELECT name FROM users") for row: Person[Q] do
            printLn(row.name);
        else error do
            printLn(describe(error));
        end for;
        return nil;
    end;

    function main(): ExitCode is
        case openWriter(":memory:") of
            when Left(left as error: SqlError) do
                printLn(describe(error));
                return ExitFailure();
            when Right(right as opened: Connection[Writing]) do
                var db: Connection[Writing] := opened;
                case migrate(&!db, @migrations) of
                    when Left(left as error: SqlError) do
                        printLn(describe(error));
                    when Right(right as applied: Index) do
                        run(&!db);
                end case;
                closeDatabase(db);
                return ExitSuccess();
        end case;
    end;
end module body.
```

Daneben `migrations/1-schema.sql`:

```sql file migrations/1-schema.sql
CREATE TABLE users (
    id INTEGER PRIMARY KEY,
    name TEXT NOT NULL
) STRICT;

INSERT INTO users (name) VALUES ('ann');
```

### H8110

Meldung:

```text
Generic Error
@migrations: a module that uses @migrations imports Standard.Sqlite or Standard.SqlCipher -- e.g. `import Standard.Sqlite (Connection);' -- because the generated code calls it
```

Ein Modul, das @query, @execute oder @migrations verwendet, importiert weder
Standard.Sqlite noch Standard.SqlCipher. Der erzeugte Code ruft eines von
beiden auf, und der Import wählt, welches.

Dieses Modul scheitert mit H8110:

```hilde fails H8110
module body Example is
    function main(): ExitCode is
        printLn(@migrations);
        return ExitSuccess();
    end;
end module body.
```

Die richtige Form:

```hilde
import Standard.Sqlite (Connection);

module body Example is
    function main(): ExitCode is
        printLn(@migrations);
        return ExitSuccess();
    end;
end module body.
```

### H8111

Meldung:

```text
Generic Error
@execute: one statement per query; found DELETE after it (line 1, column 20 of the SQL)
```

Das SQL eines @query oder @execute enthält mehr als eine Anweisung.

Dieses Modul scheitert mit H8111:

```hilde fails H8111
import Standard.Sqlite (Connection, Writing, SqlError, describe, openWriter, closeDatabase, migrate);

module body Example is
    generic [R: Region]
    function run(db: &![Connection[Writing], R]): Unit is
        let result: Either[SqlError, Nat64] := @execute(&~db, "DELETE FROM notes; DELETE FROM users");
        case result of
            when Left(left as error: SqlError) do
                printLn(describe(error));
            when Right(right as changed: Nat64) do
                printLn(changed);
        end case;
        return nil;
    end;

    function main(): ExitCode is
        case openWriter(":memory:") of
            when Left(left as error: SqlError) do
                printLn(describe(error));
                return ExitFailure();
            when Right(right as opened: Connection[Writing]) do
                var db: Connection[Writing] := opened;
                case migrate(&!db, @migrations) of
                    when Left(left as error: SqlError) do
                        printLn(describe(error));
                    when Right(right as applied: Index) do
                        run(&!db);
                end case;
                closeDatabase(db);
                return ExitSuccess();
        end case;
    end;
end module body.
```

Die richtige Form:

```hilde
import Standard.Sqlite (Connection, Writing, SqlError, describe, openWriter, closeDatabase, migrate);

module body Example is
    generic [R: Region]
    function run(db: &![Connection[Writing], R]): Unit is
        let notesGone: Either[SqlError, Nat64] := @execute(&~db, "DELETE FROM notes");
        case notesGone of
            when Left(left as error: SqlError) do
                printLn(describe(error));
            when Right(right as changed: Nat64) do
                printLn(changed);
        end case;
        let usersGone: Either[SqlError, Nat64] := @execute(&~db, "DELETE FROM users");
        case usersGone of
            when Left(left as error: SqlError) do
                printLn(describe(error));
            when Right(right as changed: Nat64) do
                printLn(changed);
        end case;
        return nil;
    end;

    function main(): ExitCode is
        case openWriter(":memory:") of
            when Left(left as error: SqlError) do
                printLn(describe(error));
                return ExitFailure();
            when Right(right as opened: Connection[Writing]) do
                var db: Connection[Writing] := opened;
                case migrate(&!db, @migrations) of
                    when Left(left as error: SqlError) do
                        printLn(describe(error));
                    when Right(right as applied: Index) do
                        run(&!db);
                end case;
                closeDatabase(db);
                return ExitSuccess();
        end case;
    end;
end module body.
```

### H8112

Meldung:

```text
Generic Error
@query: the SQL has 1 parameter and 0 values are given
```

Das SQL hat eine andere Anzahl Parameter ?, als Werte übergeben werden.

Dieses Modul scheitert mit H8112:

```hilde fails H8112
import Standard.Sqlite (Connection, Writing, SqlError, describe, openWriter, closeDatabase, migrate);

module body Example is
    record Person[R: Region]: Free is
        name: Span[Nat8, R];
    end;

    generic [R: Region]
    function run(db: &![Connection[Writing], R]): Unit is
        @query(&~db, "SELECT name FROM users WHERE age > ?") for row: Person[Q] do
            printLn(row.name);
        else error do
            printLn(describe(error));
        end for;
        return nil;
    end;

    function main(): ExitCode is
        case openWriter(":memory:") of
            when Left(left as error: SqlError) do
                printLn(describe(error));
                return ExitFailure();
            when Right(right as opened: Connection[Writing]) do
                var db: Connection[Writing] := opened;
                case migrate(&!db, @migrations) of
                    when Left(left as error: SqlError) do
                        printLn(describe(error));
                    when Right(right as applied: Index) do
                        run(&!db);
                end case;
                closeDatabase(db);
                return ExitSuccess();
        end case;
    end;
end module body.
```

Die richtige Form:

```hilde
import Standard.Sqlite (Connection, Writing, SqlError, describe, openWriter, closeDatabase, migrate);

module body Example is
    record Person[R: Region]: Free is
        name: Span[Nat8, R];
    end;

    generic [R: Region]
    function run(db: &![Connection[Writing], R]): Unit is
        @query(&~db, "SELECT name FROM users WHERE age > ?", 18) for row: Person[Q] do
            printLn(row.name);
        else error do
            printLn(describe(error));
        end for;
        return nil;
    end;

    function main(): ExitCode is
        case openWriter(":memory:") of
            when Left(left as error: SqlError) do
                printLn(describe(error));
                return ExitFailure();
            when Right(right as opened: Connection[Writing]) do
                var db: Connection[Writing] := opened;
                case migrate(&!db, @migrations) of
                    when Left(left as error: SqlError) do
                        printLn(describe(error));
                    when Right(right as applied: Index) do
                        run(&!db);
                end case;
                closeDatabase(db);
                return ExitSuccess();
        end case;
    end;
end module body.
```

### H8113

Meldung:

```text
Generic Error
@query: the row type is a record, written `Name' or `Name[R]' with R the region the row's text is lent under
```

Der Zeilentyp von @query ist kein Record, geschrieben Name oder Name[R],
wobei R die Region ist, unter der der Text der Zeile verliehen wird.

Dieses Modul scheitert mit H8113:

```hilde fails H8113
import Standard.Sqlite (Connection, Writing, SqlError, describe, openWriter, closeDatabase, migrate);

module body Example is
    generic [R: Region]
    function run(db: &![Connection[Writing], R]): Unit is
        @query(&~db, "SELECT name FROM users") for row: Span[Nat8, Q] do
            printLn(row);
        else error do
            printLn(describe(error));
        end for;
        return nil;
    end;

    function main(): ExitCode is
        case openWriter(":memory:") of
            when Left(left as error: SqlError) do
                printLn(describe(error));
                return ExitFailure();
            when Right(right as opened: Connection[Writing]) do
                var db: Connection[Writing] := opened;
                case migrate(&!db, @migrations) of
                    when Left(left as error: SqlError) do
                        printLn(describe(error));
                    when Right(right as applied: Index) do
                        run(&!db);
                end case;
                closeDatabase(db);
                return ExitSuccess();
        end case;
    end;
end module body.
```

Die richtige Form:

```hilde
import Standard.Sqlite (Connection, Writing, SqlError, describe, openWriter, closeDatabase, migrate);

module body Example is
    record Person[R: Region]: Free is
        name: Span[Nat8, R];
    end;

    generic [R: Region]
    function run(db: &![Connection[Writing], R]): Unit is
        @query(&~db, "SELECT name FROM users") for row: Person[Q] do
            printLn(row.name);
        else error do
            printLn(describe(error));
        end for;
        return nil;
    end;

    function main(): ExitCode is
        case openWriter(":memory:") of
            when Left(left as error: SqlError) do
                printLn(describe(error));
                return ExitFailure();
            when Right(right as opened: Connection[Writing]) do
                var db: Connection[Writing] := opened;
                case migrate(&!db, @migrations) of
                    when Left(left as error: SqlError) do
                        printLn(describe(error));
                    when Right(right as applied: Index) do
                        run(&!db);
                end case;
                closeDatabase(db);
                return ExitSuccess();
        end case;
    end;
end module body.
```

### H8115

Meldung:

```text
Generic Error
@query: this statement returns no rows: write it with @execute, or add RETURNING
```

@query bekommt eine Anweisung, die keine Zeilen liefert. Man schreibt sie
mit @execute oder ergänzt RETURNING.

Dieses Modul scheitert mit H8115:

```hilde fails H8115
import Standard.Sqlite (Connection, Writing, SqlError, describe, openWriter, closeDatabase, migrate);

module body Example is
    record Person[R: Region]: Free is
        name: Span[Nat8, R];
    end;

    generic [R: Region]
    function run(db: &![Connection[Writing], R]): Unit is
        @query(&~db, "DELETE FROM users WHERE age > 99") for row: Person[Q] do
            printLn(row.name);
        else error do
            printLn(describe(error));
        end for;
        return nil;
    end;

    function main(): ExitCode is
        case openWriter(":memory:") of
            when Left(left as error: SqlError) do
                printLn(describe(error));
                return ExitFailure();
            when Right(right as opened: Connection[Writing]) do
                var db: Connection[Writing] := opened;
                case migrate(&!db, @migrations) of
                    when Left(left as error: SqlError) do
                        printLn(describe(error));
                    when Right(right as applied: Index) do
                        run(&!db);
                end case;
                closeDatabase(db);
                return ExitSuccess();
        end case;
    end;
end module body.
```

Die richtige Form:

```hilde
import Standard.Sqlite (Connection, Writing, SqlError, describe, openWriter, closeDatabase, migrate);

module body Example is
    record Person[R: Region]: Free is
        name: Span[Nat8, R];
    end;

    generic [R: Region]
    function run(db: &![Connection[Writing], R]): Unit is
        @query(&~db, "DELETE FROM users WHERE age > 99 RETURNING name") for row: Person[Q] do
            printLn(row.name);
        else error do
            printLn(describe(error));
        end for;
        return nil;
    end;

    function main(): ExitCode is
        case openWriter(":memory:") of
            when Left(left as error: SqlError) do
                printLn(describe(error));
                return ExitFailure();
            when Right(right as opened: Connection[Writing]) do
                var db: Connection[Writing] := opened;
                case migrate(&!db, @migrations) of
                    when Left(left as error: SqlError) do
                        printLn(describe(error));
                    when Right(right as applied: Index) do
                        run(&!db);
                end case;
                closeDatabase(db);
                return ExitSuccess();
        end case;
    end;
end module body.
```

### H8116

Meldung:

```text
Generic Error
@execute: this statement returns rows: write it with @query ... for
```

@execute bekommt eine Anweisung, die Zeilen liefert. Man schreibt sie mit
@query ... for.

Dieses Modul scheitert mit H8116:

```hilde fails H8116
import Standard.Sqlite (Connection, Writing, SqlError, describe, openWriter, closeDatabase, migrate);

module body Example is
    generic [R: Region]
    function run(db: &![Connection[Writing], R]): Unit is
        let result: Either[SqlError, Nat64] := @execute(&~db, "SELECT name FROM users");
        case result of
            when Left(left as error: SqlError) do
                printLn(describe(error));
            when Right(right as changed: Nat64) do
                printLn(changed);
        end case;
        return nil;
    end;

    function main(): ExitCode is
        case openWriter(":memory:") of
            when Left(left as error: SqlError) do
                printLn(describe(error));
                return ExitFailure();
            when Right(right as opened: Connection[Writing]) do
                var db: Connection[Writing] := opened;
                case migrate(&!db, @migrations) of
                    when Left(left as error: SqlError) do
                        printLn(describe(error));
                    when Right(right as applied: Index) do
                        run(&!db);
                end case;
                closeDatabase(db);
                return ExitSuccess();
        end case;
    end;
end module body.
```

Die richtige Form:

```hilde
import Standard.Sqlite (Connection, Writing, SqlError, describe, openWriter, closeDatabase, migrate);

module body Example is
    record Person[R: Region]: Free is
        name: Span[Nat8, R];
    end;

    generic [R: Region]
    function run(db: &![Connection[Writing], R]): Unit is
        @query(&~db, "SELECT name FROM users") for row: Person[Q] do
            printLn(row.name);
        else error do
            printLn(describe(error));
        end for;
        return nil;
    end;

    function main(): ExitCode is
        case openWriter(":memory:") of
            when Left(left as error: SqlError) do
                printLn(describe(error));
                return ExitFailure();
            when Right(right as opened: Connection[Writing]) do
                var db: Connection[Writing] := opened;
                case migrate(&!db, @migrations) of
                    when Left(left as error: SqlError) do
                        printLn(describe(error));
                    when Right(right as applied: Index) do
                        run(&!db);
                end case;
                closeDatabase(db);
                return ExitSuccess();
        end case;
    end;
end module body.
```

## 9. Verträge

Der Vertrag einer Funktion sind ihre requires- und ensures-Klauseln
(docs/syntax.de.md, Abschnitt 3). Die Fehler dieses Kapitels kommen
daher, wo ein Vertrag steht, und von seinen Bedingungen, die nur lesen
dürfen.

### H2051

Meldung:

```text
Declaration Error
The body of the public function `half` holds a contract.

The contract of a public function stands in its interface only: it is written at `Example.hih:3`.  Remove the requires, ensures and raises clauses from the body.
```

Der Body einer öffentlichen Funktion trägt requires-, ensures- oder raises-Klauseln.
Der Vertrag einer öffentlichen Funktion steht einmal, in ihrem
Interface, wo jeder Aufrufer ihn liest. Die Meldung nennt die Stelle des
Vertrags im Interface, oder die der Deklaration, wenn das Interface
keinen hat.

Dieses Modul scheitert mit H2051:

```hilde fails H2051
module body Example is
    function half(n: Nat32): Nat32
        requires n > 0
    is
        return n / 2;
    end;

    function main(): ExitCode is
        printLn(half(8));
        return ExitSuccess();
    end;
end module body.
```

Daneben `Example.hih`:

```hilde file Example.hih
module Example is
    function half(n: Nat32): Nat32
        requires n > 0;

    function main(): ExitCode;
end module.
```

Die richtige Form:

```hilde
module body Example is
    function half(n: Nat32): Nat32 is
        return n / 2;
    end;

    function main(): ExitCode is
        printLn(half(8));
        return ExitSuccess();
    end;
end module body.
```

Daneben `Example.hih`:

```hilde file Example.hih
module Example is
    function half(n: Nat32): Nat32
        requires n > 0;

    function main(): ExitCode;
end module.
```

### H2052

Meldung:

```text
Declaration Error
The function `cAbs` is imported from C and has a contract.

A contract is checked by statements put into the body of its function, and a foreign function has none.  Write the contract on a Hilde function that calls it.
```

Eine aus C importierte Funktion hat einen Vertrag.
Der Compiler prüft einen Vertrag mit Anweisungen, die er in den Body der
Funktion setzt, und eine mit Foreign_Import eingebundene Funktion hat
keinen eigenen Body.

Dieses Modul scheitert mit H2052:

```hilde fails H2052
pragma Unsafe_Module;

module body Example is
    pragma Foreign_Import(External_Name => "abs");
    function cAbs(value: Int32): Int32
        requires value > -100
    is
    end;

    function main(): ExitCode is
        printLn(cAbs(-5));
        return ExitSuccess();
    end;
end module body.
```

Die richtige Form:

```hilde
pragma Unsafe_Module;

module body Example is
    pragma Foreign_Import(External_Name => "abs");
    function cAbs(value: Int32): Int32 is
    end;

    function absolute(value: Int32): Int32
        requires value > -100
    is
        return cAbs(value);
    end;

    function main(): ExitCode is
        printLn(absolute(-5));
        return ExitSuccess();
    end;
end module body.
```

### H2053

Meldung:

```text
Declaration Error
The ensures of `addThree` names `limit`, which the body of the function also declares.

An ensures sees the parameters, result and the names of modules; checked at a return, it would read the body's variable instead.  Rename the variable in the body.
```

Ein ensures nennt eine Variable, die der Body der Funktion deklariert.
Ein ensures wird bei jedem return geprüft, wo die Variablen des Bodys
noch gelten; ein Name, den der Body deklariert, würde dort gelesen statt
des gleich geschriebenen Namens des Moduls. Das ensures liest nur die
Parameter, result und alte Werte.

Dieses Modul scheitert mit H2053:

```hilde fails H2053
module body Example is
    function addThree(n: Nat32): Nat32
        ensures result > limit
    is
        let limit: Nat32 := 3;
        return n + limit;
    end;

    function main(): ExitCode is
        printLn(addThree(4));
        return ExitSuccess();
    end;
end module body.
```

Die richtige Form:

```hilde
module body Example is
    function addThree(n: Nat32): Nat32
        ensures result > n
    is
        let step: Nat32 := 3;
        return n + step;
    end;

    function main(): ExitCode is
        printLn(addThree(4));
        return ExitSuccess();
    end;
end module body.
```

### H2054

Meldung:

```text
Declaration Error
The function `doubled` has an ensures and a parameter named `result`.

In an ensures, result is the value the function returns.  Rename the parameter.
```

Eine Funktion mit einem ensures hat einen Parameter namens result.
In einem ensures steht der Name result für den Wert, den die Funktion
zurückgibt; ein Parameter dieses Namens wäre dort nicht zu lesen.

Dieses Modul scheitert mit H2054:

```hilde fails H2054
module body Example is
    function doubled(result: Nat32): Nat32
        ensures result > 0
    is
        return result * 2;
    end;

    function main(): ExitCode is
        printLn(doubled(4));
        return ExitSuccess();
    end;
end module body.
```

Die richtige Form:

```hilde
module body Example is
    function doubled(n: Nat32): Nat32
        ensures result = (n * 2)
    is
        return n * 2;
    end;

    function main(): ExitCode is
        printLn(doubled(4));
        return ExitSuccess();
    end;
end module body.
```

### H2055

Meldung:

```text
Declaration Error
An old(e) stands in a requires.

old(e) stands only in an ensures, takes one value, and does not nest: it is the value e had when the function was entered.
```

old steht, wo es nichts bedeutet: in einem requires, in einem anderen old oder mit anderem als einem Wert.
old(e) ist der Wert, den e beim Eintritt in die Funktion hatte, bei ihrer
Rückkehr wieder gelesen; in einem requires, das beim Eintritt geprüft
wird, sagte es nichts. Die erste Zeile der Meldung sagt, welcher der
drei Fälle vorliegt.

Dieses Modul scheitert mit H2055:

```hilde fails H2055
module body Example is
    function half(n: Nat32): Nat32
        requires old(n) > 0
    is
        return n / 2;
    end;

    function main(): ExitCode is
        printLn(half(8));
        return ExitSuccess();
    end;
end module body.
```

Die richtige Form:

```hilde
module body Example is
    function half(n: Nat32): Nat32
        requires n > 0
    is
        return n / 2;
    end;

    function main(): ExitCode is
        printLn(half(8));
        return ExitSuccess();
    end;
end module body.
```

### H2056

Meldung:

```text
Declaration Error
The test `testHalf` has a requires.

A violated requires names the call that broke it, and a test is called by hilde test, not by a call in the programme.  Check the condition in the test's body instead.
```

Eine Testfunktion hat ein requires.
Ein verletztes requires nennt den Aufruf, der es gebrochen hat, und kein
Aufruf im Programm ruft einen Test: das tut hilde test. Ein Test prüft,
was er braucht, in seinem Body, mit den Zusicherungen von
Standard.Testing.

Dieses Modul scheitert mit H2056:

```hilde fails H2056
module body Example.Test is
    function testHalf(): Unit
        requires argumentCount() > 0
    is
        return nil;
    end;
end module body.
```

Aufgerufen mit:

```sh command
hilde test Example.hiq
```

Die richtige Form:

```hilde
module body Example.Test is
    function testHalf(): Unit is
        return nil;
    end;
end module body.
```

Aufgerufen mit:

```sh command
hilde test Example.hiq
```

### H2057

Meldung:

```text
Declaration Error
The record `Range` has an invariant, and its slots can be reached outside its module: its slots stand in the interface.

An invariant is checked where a value leaves its module, which holds only when no other module can build the record or write its slots.  Declare the type opaque in the interface, type Name: Universe;, and the record in the body.
```

Ein Record mit einer Invariante lässt sich außerhalb seines Moduls bauen oder beschreiben.
Eine Invariante wird bei der Rückkehr der öffentlichen Funktionen des
Moduls geprüft, wo ein Wert das Modul verlässt. Das hält sie nur, wenn
kein anderes Modul den Record bauen oder seine Slots zuweisen kann, und so
ist es, wenn das Interface den Typ opak oder gar nicht deklariert. Ein
Modul ohne Interface hat keinen privaten Record.

Dieses Modul scheitert mit H2057:

```hilde fails H2057
module body Example is
    function main(): ExitCode is
        let r: Range := Range(low => 1, high => 2);
        printLn(r.high);
        return ExitSuccess();
    end;
end module body.
```

Daneben `Example.hih`:

```hilde file Example.hih
module Example is
    record Range: Free is
        low: Nat32;
        high: Nat32;
        invariant low <= high;
    end;

    function main(): ExitCode;
end module.
```

Die richtige Form:

```hilde
module body Example is
    record Range: Free is
        low: Nat32;
        high: Nat32;
        invariant low <= high;
    end;

    function make(low: Nat32, high: Nat32): Range is
        return Range(low => low, high => high);
    end;

    function main(): ExitCode is
        let r: Range := make(1, 2);
        printLn(r.high);
        return ExitSuccess();
    end;
end module body.
```

Daneben `Example.hih`:

```hilde file Example.hih
module Example is
    type Range: Free;

    function make(low: Nat32, high: Nat32): Range;

    function main(): ExitCode;
end module.
```

### H3096

Meldung:

```text
Type Error
This condition uses the linear value `token` itself, which would consume it.

A condition only reads: read a linear value through a reference, `&token`.
```

Eine Bedingung verwendet einen linearen Wert selbst statt über eine Referenz.
Eine Bedingung liest nur. Ein linearer Wert, selbst verwendet, wird
verbraucht, und die Funktion hätte ihn verloren, bevor ihr Body läuft.

Dieses Modul scheitert mit H3096:

```hilde fails H3096
module body Example is
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

Die richtige Form:

```hilde
module body Example is
    record Token: Linear is
        value: Nat32;
    end;

    function valueOf(token: Token): Nat32 is
        let { value: Nat32 } := token;
        return value;
    end;

    generic [R: Region]
    function peek(token: &[Token, R]): Nat32 is
        return token->value;
    end;

    function spend(token: Token): Nat32
        requires peek(&token) > 0
    is
        return valueOf(token);
    end;

    function main(): ExitCode is
        printLn(spend(Token(value => 3)));
        return ExitSuccess();
    end;
end module body.
```

### H3097

Meldung:

```text
Type Error
This condition makes a reference to write through, with `&!`, `&~` or a writable span.

A condition only reads: take a read reference with & instead.
```

Eine Bedingung nimmt eine Referenz zum Schreiben.
Eine Bedingung liest nur; eine Referenz zum Schreiben hat darin keinen
Platz. Eine Schreibreferenz, die ein Parameter ist, wird mit & gelesen.

Dieses Modul scheitert mit H3097:

```hilde fails H3097
module body Example is
    record Counter: Linear is
        count: Nat32;
    end;

    generic [R: Region]
    function peek(counter: &[Counter, R]): Nat32 is
        return counter->count;
    end;

    generic [R: Region]
    function bump(counter: &![Counter, R]): Nat32 is
        counter->count := counter->count + 1;
        return counter->count;
    end;

    generic [R: Region]
    function current(counter: &![Counter, R]): Nat32
        requires bump(&~counter) > 0
    is
        return counter->count;
    end;

    function main(): ExitCode is
        var c: Counter := Counter(count => 1);
        printLn(current(&!c));
        let { count: Nat32 } := c;
        printLn(count);
        return ExitSuccess();
    end;
end module body.
```

Die richtige Form:

```hilde
module body Example is
    record Counter: Linear is
        count: Nat32;
    end;

    generic [R: Region]
    function peek(counter: &[Counter, R]): Nat32 is
        return counter->count;
    end;

    generic [R: Region]
    function bump(counter: &![Counter, R]): Nat32 is
        counter->count := counter->count + 1;
        return counter->count;
    end;

    generic [R: Region]
    function current(counter: &![Counter, R]): Nat32
        requires peek(&counter) > 0
    is
        return bump(&~counter);
    end;

    function main(): ExitCode is
        var c: Counter := Counter(count => 1);
        printLn(current(&!c));
        let { count: Nat32 } := c;
        printLn(count);
        return ExitSuccess();
    end;
end module body.
```

### H3098

Meldung:

```text
Type Error
This condition calls `Example.countedTwice -> Example.bump`, which asks for a reference to write through.

A condition only reads: every function it calls, and every function those call, stays out of the binding modules and C, and asks for no reference to write through.
```

Eine Bedingung ruft eine Funktion, die ein Binding-Modul, C oder eine Referenz zum Schreiben erreicht.
Der Compiler verfolgt jeden Aufruf einer Bedingung durch die Bodys der
Funktionen, die er erreicht, bis in jede Tiefe. Die Meldung gibt die
Kette der Aufrufe und was ihre letzte Funktion tut: Sie steht in einem
Modul, dessen Name mit Bindings. beginnt, sie ist aus C importiert oder
schreibt C mit @embed, oder sie nimmt eine Referenz zum Schreiben. In
das eigene Modul des Compilers, Hilde.Pervasive, wird nicht
hineingesehen; seine Parameter werden geprüft.

Dieses Modul scheitert mit H3098:

```hilde fails H3098
module body Example is
    record Counter: Linear is
        count: Nat32;
    end;

    generic [R: Region]
    function peek(counter: &[Counter, R]): Nat32 is
        return counter->count;
    end;

    generic [R: Region]
    function bump(counter: &![Counter, R]): Nat32 is
        counter->count := counter->count + 1;
        return counter->count;
    end;

    function countedTwice(n: Nat32): Nat32 is
        var c: Counter := Counter(count => n);
        let first: Nat32 := bump(&!c);
        let { count: Nat32 } := c;
        return first + count;
    end;

    function half(n: Nat32): Nat32
        requires countedTwice(n) > 0
    is
        return n / 2;
    end;

    function main(): ExitCode is
        printLn(half(8));
        return ExitSuccess();
    end;
end module body.
```

Die richtige Form:

```hilde
module body Example is
    function twice(n: Nat32): Nat32 is
        return n * 2;
    end;

    function half(n: Nat32): Nat32
        requires twice(n) > 0
    is
        return n / 2;
    end;

    function main(): ExitCode is
        printLn(half(8));
        return ExitSuccess();
    end;
end module body.
```

### H3099

Meldung:

```text
Type Error
This condition calls through the function pointer f, so the function that runs is not known where the condition is checked.

A condition only reads, and the compiler has to see every function it calls to know that.  Call a function by its name.
```

Eine Bedingung ruft über einen Funktionszeiger oder eine Methode eines Typparameters.
Welche Funktion läuft, entscheidet sich später, am Wert des Zeigers oder
am Typ, für den der Parameter steht, und der Compiler kann dort, wo die
Bedingung geprüft wird, nicht in sie hineinsehen.

Dieses Modul scheitert mit H3099:

```hilde fails H3099
module body Example is
    function double(n: Nat32): Nat32 is
        return n * 2;
    end;

    function apply(f: Fn[Nat32, Nat32], n: Nat32): Nat32
        requires f(n) > 0
    is
        return f(n);
    end;

    function main(): ExitCode is
        printLn(apply(double, 4));
        return ExitSuccess();
    end;
end module body.
```

Die richtige Form:

```hilde
module body Example is
    function double(n: Nat32): Nat32 is
        return n * 2;
    end;

    function apply(f: Fn[Nat32, Nat32], n: Nat32): Nat32
        requires n > 0
    is
        return f(n);
    end;

    function main(): ExitCode is
        printLn(apply(double, 4));
        return ExitSuccess();
    end;
end module body.
```

### H3100

Meldung:

```text
Type Error
old takes a value of the type `Token`, which is not in the Free universe.

old copies a value when the function is entered, and only a free value can be copied.
```

old bekommt einen Wert, der nicht frei ist.
old hebt eine Kopie seines Werts vom Eintritt bis zur Rückkehr auf, und
ein linearer Wert lässt sich nicht kopieren.

Dieses Modul scheitert mit H3100:

```hilde fails H3100
module body Example is
    record Token: Linear is
        value: Nat32;
    end;

    function valueOf(token: Token): Nat32 is
        let { value: Nat32 } := token;
        return value;
    end;

    function fresh(): Token is
        return Token(value => 1);
    end;

    function plusOne(n: Nat32): Nat32
        ensures result = (n + valueOf(old(fresh())))
    is
        return n + 1;
    end;

    function main(): ExitCode is
        printLn(plusOne(4));
        return ExitSuccess();
    end;
end module body.
```

Die richtige Form:

```hilde
module body Example is
    function plusOne(n: Nat32): Nat32
        ensures result = (old(n) + 1)
    is
        return n + 1;
    end;

    function main(): ExitCode is
        printLn(plusOne(4));
        return ExitSuccess();
    end;
end module body.
```

### H3101

Meldung:

```text
Type Error
The function `half` has a requires and cannot be taken as a function pointer.

A violated requires names the call that broke it, and a call through a pointer has no place the compiler can name.  Call the function directly, or write a function without a requires that calls it.
```

Eine Funktion mit einem requires wird als Funktionszeiger genommen.
Der Compiler gibt jedem Aufruf einer Funktion mit einem requires die
Stelle des Aufrufs mit, für die Meldung einer verletzten Bedingung; ein
Aufruf über einen Zeiger hat keine solche Stelle.

Dieses Modul scheitert mit H3101:

```hilde fails H3101
module body Example is
    function half(n: Nat32): Nat32
        requires n > 0
    is
        return n / 2;
    end;

    function main(): ExitCode is
        let f: Fn[Nat32, Nat32] := half;
        printLn(f(8));
        return ExitSuccess();
    end;
end module body.
```

Die richtige Form:

```hilde
module body Example is
    function half(n: Nat32): Nat32
        requires n > 0
    is
        return n / 2;
    end;

    function halved(n: Nat32): Nat32 is
        return half(n);
    end;

    function main(): ExitCode is
        let f: Fn[Nat32, Nat32] := halved;
        let r: Nat32 := f(8);
        printLn(r);
        return ExitSuccess();
    end;
end module body.
```

### H5008

Meldung:

```text
Entrypoint Definition Error
The entrypoint function has a requires.

A violated requires names the call that broke it, and the entrypoint is called by the system, not by a call in the programme.  Check the condition at the start of the function's body instead.
```

Die Einstiegsfunktion hat ein requires.
Ein verletztes requires nennt den Aufruf, der es gebrochen hat, und kein
Aufruf im Programm ruft die Einstiegsfunktion.

Dieses Modul scheitert mit H5008:

```hilde fails H5008
module body Example is
    function main(): ExitCode
        requires argumentCount() > 0
    is
        return ExitSuccess();
    end;
end module body.
```

Die richtige Form:

```hilde
module body Example is
    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

## 10. Fehlerarten

Die raises-Klausel einer Funktion nennt die Fehlerarten, mit denen sie
enden kann (docs/syntax.de.md, Abschnitt 3). Die Fehler dieses Kapitels
kommen daher, wo eine Klausel steht, und von den raise und Aufrufen, die
sie überschreiten.

### H2058

Meldung:

```text
Declaration Error
The method `measure` of an instance has a raises clause.

The raises clause of a method stands in the typeclass, where every instance and every caller reads it.  Remove the clause from the instance, and write it at the method's declaration in the typeclass.
```

Die Methode einer Instanz trägt eine raises-Klausel.
Die raises-Klausel einer Methode steht einmal, an der Deklaration der
Methode in der Typklasse, wo jede Instanz und jeder Aufrufer sie liest;
eine Instanz erbt sie. Eine Klausel an der Methode der Instanz wäre ein
zweites Versprechen, das nichts gegen das erste hält, deshalb wird sie
abgewiesen. Die Meldung nennt die Methode.

Dieses Modul scheitert mit H2058:

```hilde fails H2058
module body Example is
    typeclass Measure(T: Free) is
        method measure(value: T): Int32
            raises Broken;
    end;

    instance Measure(Int32) is
        method measure(value: Int32): Int32
            raises Broken is
            return value * 2;
        end;
    end;

    function main(): ExitCode
        raises Broken is
        printLn(measure(21));
        return ExitSuccess();
    end;
end module body.
```

Die richtige Form:

```hilde
module body Example is
    typeclass Measure(T: Free) is
        method measure(value: T): Int32
            raises Broken;
    end;

    instance Measure(Int32) is
        method measure(value: Int32): Int32 is
            return value * 2;
        end;
    end;

    function main(): ExitCode
        raises Broken is
        printLn(measure(21));
        return ExitSuccess();
    end;
end module body.
```


### H3102

Meldung:

```text
Type Error
The raise of `Denied` is not among the kinds this function's raises clause names: `NotFound`.  Name the kind in the raises clause of this function, or raise a kind it names.
```

Ein raise nennt eine Art, die die raises-Klausel der Funktion nicht nennt.
Eine Funktion darf nur die Arten auslösen, die ihre eigene Klausel nennt.
Die Meldung nennt die ausgelöste Art und die Arten der Klausel, oder sagt,
dass die Funktion keine Klausel hat.

Dieses Modul scheitert mit H3102:

```hilde fails H3102
module body Example is
    function pick(n: Int32): Int32
        raises NotFound is
        if n < 0 then
            raise Denied;
        end if;
        return n;
    end;

    function main(): ExitCode
        raises NotFound is
        printLn(pick(7));
        return ExitSuccess();
    end;
end module body.
```

Die richtige Form:

```hilde
module body Example is
    function pick(n: Int32): Int32
        raises NotFound, Denied is
        if n < 0 then
            raise Denied;
        end if;
        return n;
    end;

    function main(): ExitCode
        raises NotFound, Denied is
        printLn(pick(7));
        return ExitSuccess();
    end;
end module body.
```


### H3103

Meldung:

```text
Type Error
The call of `Example.pick` can end with the error kind(s) `NotFound`, but this function's raises clause names: `no kinds (no raises clause)`.  A function may call only the functions whose error kinds it has named; name the missing kind(s) in the raises clause of this function, or take the call out.
```

Ein Aufruf kann mit einer Fehlerart enden, die die raises-Klausel des
Aufrufers nicht nennt.
Eine Funktion darf nur Funktionen aufrufen, deren Fehlerarten sie selbst
nennt, damit eine Art keinen Aufrufer erreicht, der sie nicht versprochen
hat; die Einstiegsfunktion unterliegt derselben Regel. Die Meldung nennt
das Ziel, die fehlenden Arten und die Arten, die der Aufrufer nennt. Ein
Methodenaufruf wird an der Klausel der Deklaration der Methode in der
Typklasse gemessen.

Dieses Modul scheitert mit H3103:

```hilde fails H3103
module body Example is
    function pick(n: Int32): Int32
        raises NotFound is
        return n;
    end;

    function main(): ExitCode is
        printLn(pick(7));
        return ExitSuccess();
    end;
end module body.
```

Die richtige Form:

```hilde
module body Example is
    function pick(n: Int32): Int32
        raises NotFound is
        return n;
    end;

    function main(): ExitCode
        raises NotFound is
        printLn(pick(7));
        return ExitSuccess();
    end;
end module body.
```


### H3104

Meldung:

```text
Type Error
The function `pick` has a raises clause and cannot be taken as a function pointer.

A call through a pointer has no signature the compiler can hold against the caller's raises clause.  Call the function directly.
```

Eine Funktion mit einer raises-Klausel wird als Funktionszeiger genommen.
Ein Aufruf über einen Zeiger hat keine Signatur, die der Compiler gegen
die Klausel des Aufrufers halten könnte; eine solche Funktion wird nur bei
ihrem Namen aufgerufen.

Dieses Modul scheitert mit H3104:

```hilde fails H3104
module body Example is
    function pick(n: Int32): Int32
        raises NotFound is
        return n;
    end;

    function main(): ExitCode
        raises NotFound is
        let f: Fn[Int32, Int32] := pick;
        printLn(f(7));
        return ExitSuccess();
    end;
end module body.
```

Die richtige Form:

```hilde
module body Example is
    function pick(n: Int32): Int32
        raises NotFound is
        return n;
    end;

    function main(): ExitCode
        raises NotFound is
        printLn(pick(7));
        return ExitSuccess();
    end;
end module body.
```

## 11. Never und Slots

### H2060

Meldung:

```text
Declaration Error
A return stands in a function that returns `Never`.

A function that returns Never does not come back: it ends in a call of a function that returns Never, in a raise or in a loop that never ends.
```

Ein return steht in einer Funktion, die Never zurückgibt. Eine solche
Funktion hat keinen Wert zurückzugeben, also erreicht kein Pfad durch sie
ein return.

Dieses Modul scheitert mit H2060:

```hilde fails H2060
module body Example is
    function stop(): Never is
        return nil;
    end;

    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Die richtige Form:

```hilde
module body Example is
    function stop(): Never is
        abort("stopped");
    end;

    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

### H2061

Meldung:

```text
Declaration Error
The function `stop` returns `Never` but a path through it comes to its end.

Every path ends in a call of a function that returns Never, in a raise or in a while whose condition is true.
```

Eine Funktion, die Never zurückgibt, hat einen Pfad, der das Ende ihres
Rumpfs erreicht. Hier hat das if kein else, also läuft der Pfad mit b
gleich false durch.

Dieses Modul scheitert mit H2061:

```hilde fails H2061
module body Example is
    function stop(b: Bool): Never is
        if b then
            abort("stopped");
        end if;
    end;

    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Die richtige Form:

```hilde
module body Example is
    function stop(b: Bool): Never is
        if b then
            abort("stopped");
        end if;
        abort("stopped anyway");
    end;

    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

### H2062

Meldung:

```text
Declaration Error
The function `stop` returns `Never` and has an ensures.

An ensures speaks of the state at a return, and a function that returns Never does not return: the clause would hold of nothing.  Remove it; a requires stays allowed.
```

Eine Funktion, die Never zurückgibt, trägt eine ensures-Klausel. Die
Klausel würde an einem return geprüft, und es gibt keines.

Dieses Modul scheitert mit H2062:

```hilde fails H2062
module body Example is
    function stop(n: Int32): Never
        ensures n > 0
    is
        abort("stopped");
    end;

    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Die richtige Form:

```hilde
module body Example is
    function stop(n: Int32): Never
        requires n > 0
    is
        abort("stopped");
    end;

    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

### H2063

Meldung:

```text
Declaration Error
The slot `Greeting.greet` has no default body and no function of the programme implements it.

Give the declaration a body in the module, or mark one function with pragma Implements(Name => "Greeting.greet").
```

Ein Slot hat weder einen Standardrumpf noch eine Implementierung im
Programm. Die Prüfung läuft, wenn das letzte Modul des Programms
übersetzt wird.

Dieses Modul scheitert mit H2063:

```hilde fails H2063
import Greeting (
    greet
);

module body Example is
    function main(): ExitCode is
        greet();
        return ExitSuccess();
    end;
end module body.
```

Daneben `Greeting.hih`:

```hilde file Greeting.hih
module Greeting is
    -- Says hello; the programme implements it.
    pragma Slot;
    function greet(): Unit;
end module.
```

Daneben `Greeting.hiq`:

```hilde file Greeting.hiq
module body Greeting is
end module body.
```

Die richtige Form:

```hilde
import Greeting (
    greet
);

module body Example is
    pragma Implements(Name => "Greeting.greet");
    function warmly(): Unit is
        printLn("hello");
        return nil;
    end;

    function main(): ExitCode is
        greet();
        return ExitSuccess();
    end;
end module body.
```

Daneben `Greeting.hih`:

```hilde file Greeting.hih
module Greeting is
    -- Says hello; the programme implements it.
    pragma Slot;
    function greet(): Unit;
end module.
```

Daneben `Greeting.hiq`:

```hilde file Greeting.hiq
module body Greeting is
end module body.
```

### H2064

Meldung:

```text
Declaration Error
The slot `Hilde.Pervasive.onOverflow` is implemented twice: by `Example.first` and by `Example.second`.

A slot has one implementation in a programme; remove the pragma Implements from one of them.
```

Zwei Funktionen des Programms implementieren denselben Slot. Ein Slot hat
eine Implementierung, sonst wüsste der Compiler nicht, welche er aufruft.

Dieses Modul scheitert mit H2064:

```hilde fails H2064
module body Example is
    pragma Implements(Name => "Hilde.Pervasive.onOverflow");
    function first(message: Span[Nat8, Static]): Never is
        abort(message);
    end;

    pragma Implements(Name => "Hilde.Pervasive.onOverflow");
    function second(message: Span[Nat8, Static]): Never is
        abort(message);
    end;

    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Die richtige Form:

```hilde
module body Example is
    pragma Implements(Name => "Hilde.Pervasive.onOverflow");
    function first(message: Span[Nat8, Static]): Never is
        abort(message);
    end;

    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

### H2065

Meldung:

```text
Declaration Error
The function `Example.handled` implements the slot `Hilde.Pervasive.onOverflow` but its signature differs: the parameter message: Span[Nat8, Static] of the slot is text: Span[Nat8, Static] in the implementation.

An implementation has the parameters of the slot, with their names and types, and its result type.
```

Eine Implementierung eines Slots hat eine andere Signatur als der Slot.
Die Parameter stimmen in Zahl, Name und Typ überein, und die
Ergebnistypen sind gleich.

Dieses Modul scheitert mit H2065:

```hilde fails H2065
module body Example is
    pragma Implements(Name => "Hilde.Pervasive.onOverflow");
    function handled(text: Span[Nat8, Static]): Never is
        abort(text);
    end;

    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Die richtige Form:

```hilde
module body Example is
    pragma Implements(Name => "Hilde.Pervasive.onOverflow");
    function handled(message: Span[Nat8, Static]): Never is
        abort(message);
    end;

    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

### H2066

Meldung:

```text
Declaration Error
The function `Example.handled` implements `Hilde.Pervasive.nowhere`, which is not a slot of a module compiled before it.

The name is Module.function of a declaration with pragma Slot, and the implementing module imports that module.
```

Ein pragma Implements nennt etwas, das kein Slot ist. Der Name wird unter
den Slots der Module gesucht, die vor diesem übersetzt wurden.

Dieses Modul scheitert mit H2066:

```hilde fails H2066
module body Example is
    pragma Implements(Name => "Hilde.Pervasive.nowhere");
    function handled(message: Span[Nat8, Static]): Never is
        abort(message);
    end;

    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Die richtige Form:

```hilde
module body Example is
    pragma Implements(Name => "Hilde.Pervasive.onOverflow");
    function handled(message: Span[Nat8, Static]): Never is
        abort(message);
    end;

    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

### H2067

Meldung:

```text
Declaration Error
A function generic over a type cannot be a slot or implement one.

pragma Slot stands at a function declaration in an interface, and pragma Implements at a function definition that is not a slot; neither at a function generic over anything but regions.
```

Ein pragma Slot oder pragma Implements steht, wo es nichts bedeutet: Slot
an einer Funktionsdefinition, Implements an einer Deklaration eines
Interface, eines von beiden an einer Funktion, die über einen Typ generisch ist,
oder beide an derselben Funktion. Ein Slot, der nur über Regionen
generisch ist, ist erlaubt: Eine Region hat zur Laufzeit keine Form, und
jede Instanz ist dieselbe Funktion. Die erste Zeile der Meldung sagt, welcher Fall es ist.

Dieses Modul scheitert mit H2067:

```hilde fails H2067
module body Example is
    pragma Implements(Name => "Hilde.Pervasive.onOverflow");
    generic [T: Free]
    function handled(message: Span[Nat8, Static], other: T): Never is
        abort(message);
    end;

    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Die richtige Form:

```hilde
module body Example is
    pragma Implements(Name => "Hilde.Pervasive.onOverflow");
    function handled(message: Span[Nat8, Static]): Never is
        abort(message);
    end;

    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

### H3109

Meldung:

```text
Type Error
`Never` cannot be the type of a parameter: it has no value.

Only the return type of a function or a method may be Never.
```

Never steht als Typ von etwas, das einen Wert hält: ein Parameter, eine
Variable, ein Feld eines Records oder einer Union, eine Konstante, eine
Konversion, eine Größe, ein Funktionszeiger oder ein Typargument. Never
hat keinen Wert, also kann nur das Ergebnis einer Funktion oder Methode
ihn haben.

Dieses Modul scheitert mit H3109:

```hilde fails H3109
module body Example is
    function take(x: Never): Unit is
        return nil;
    end;

    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Die richtige Form:

```hilde
module body Example is
    function take(x: Int32): Unit is
        return nil;
    end;

    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

### H3110

Meldung:

```text
Type Error
A call that does not come back stands where its value would be passed on.

Its result is Never; call it as a statement of its own.
```

Ein Aufruf einer Funktion, die Never zurückgibt, ist ein Argument oder
ein Operand. Der Aufruf liefert nie einen Wert, also könnte der Ausdruck
um ihn nie fertig werden. Ein let, eine Zuweisung, ein return und ein
Zweig eines if-Ausdrucks dürfen einen solchen Aufruf weiter halten.

Dieses Modul scheitert mit H3110:

```hilde fails H3110
module body Example is
    function show(n: Int32): Unit is
        printLn(n);
        return nil;
    end;

    function main(): ExitCode is
        show(abort("stopped"));
        return ExitSuccess();
    end;
end module body.
```

Die richtige Form:

```hilde
module body Example is
    function show(n: Int32): Unit is
        printLn(n);
        return nil;
    end;

    function main(): ExitCode is
        abort("stopped");
    end;
end module body.
```

## 12. Ziele

Die Ziele, für die ein Programm gebaut wird, `hilde build --target`, der Compiler und die
Laufzeit für WebAssembly, die hilde findet, und pragma Targets, mit dem die Standardbibliothek
sagt, für welche Ziele es jedes Modul gibt.

### H1038

Meldung:

```text
Command Line Arguments Error
No compiler for WebAssembly was found.

hilde looks for zig, given as `HILDE_ZIG` or on the path, and then for clang on the path with `wasm-ld` and the C library of WASI, in `WASI_SYSROOT`, /usr/share/wasi-sysroot, /opt/wasi-sdk/share/wasi-sysroot or where Debian's wasi-libc puts it. Install zig, or clang with lld and wasi-libc.

A compiler for WebAssembly is needed only for --target=wasm and --target-type=wasm; zig is taken at version 0.17.0 only.
```

Kein Compiler für wasm32-wasi wird gefunden.  hilde findet ihn selbst: zig, gegeben als
HILDE_ZIG oder im Pfad, das die C-Bibliothek von WASI mitbringt, sonst clang im Pfad mit
wasm-ld und der C-Bibliothek von WASI.  HILDE_WASM_CC=zig oder clang nimmt diesen und scheitert,
wenn er fehlt; dann nennt ihn die Meldung.  Das Beispiel nimmt den Pfad weg.

Dieses Modul scheitert mit H1038:

```hilde fails H1038
module body Example is
    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Übersetzt mit:


```sh command
env HILDE_ZIG= PATH=/nonexistent hilde build Example.hiq --target=wasm --entrypoint=Example:main --output=prog.wasm
```

Die richtige Form:

```hilde
module body Example is
    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Übersetzt mit:


```sh command
hilde build Example.hiq --entrypoint=Example:main --output=prog
```

### H1039

Meldung:

```text
Command Line Arguments Error
`HILDE_WASM_CC` is `gcc`, which is not a compiler hilde knows for WebAssembly.

It is `zig` or `clang`, or not set, and then zig is taken when it is there.
```

HILDE_WASM_CC nennt einen Compiler, den hilde für WebAssembly nicht kennt.  Es wählt zwischen
den beiden, nach denen hilde sucht, zig und clang; ein falsch geschriebener Name wird abgewiesen,
statt als nicht gesetzt zu gelten.

Dieses Modul scheitert mit H1039:

```hilde fails H1039
module body Example is
    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Übersetzt mit:


```sh command
env HILDE_WASM_CC=gcc hilde build Example.hiq --target=wasm --entrypoint=Example:main --output=prog.wasm
```

Die richtige Form:

```hilde
module body Example is
    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Übersetzt mit:


```sh command
hilde build Example.hiq --entrypoint=Example:main --output=prog
```

### H1040

Meldung, aus dem Quelltext in `lib/Util.ml`:

```text
No runtime for WebAssembly was found to run the tests.

hilde runs a module for wasm32-wasi with wasmtime, given as `HILDE_WASMTIME` or on the path.
```

hilde test --target=wasm findet keine Laufzeit für WebAssembly.  Die Testprogramme sind
Kommandomodule, und wasmtime führt sie aus.

Er bleibt, weil ein Lauf der Tests ohne Laufzeit sagen muss, was fehlt.  Er wird hier nicht
ausgelöst, weil ein Modul gebaut wird, bevor es läuft, und ein Gate, das einen
Compiler für wasm32-wasi hat, auch wasmtime hat.

Nicht ausgelöst: Es fand sich kein Programm, das diesen Fehler erreicht.

### H1041

Meldung:

```text
Command Line Arguments Error
`--target=wsam` names no target hilde builds for.

The targets are `linux, openbsd, freebsd, darwin, wasm`.
```

--target nennt kein Ziel, für das hilde baut.  Die Namen sind die fünf von pragma Targets; für
einen Namen, der wenige Buchstaben von einem entfernt ist, schlägt die Meldung diesen vor.

Dieses Modul scheitert mit H1041:

```hilde fails H1041
module body Example is
    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Übersetzt mit:


```sh command
hilde build Example.hiq --target=wsam --entrypoint=Example:main --output=prog
```

Die richtige Form:

```hilde
module body Example is
    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Übersetzt mit:


```sh command
hilde build Example.hiq --entrypoint=Example:main --output=prog
```

### H1042

Meldung, aus dem Quelltext in `lib/CliParser.ml`:

```text
`--target=<name>` asks for a binary of another system, and hilde builds a binary only for the system it runs on, <host>.

Build on a machine of `<name>`, or build a module for WebAssembly with `--target=wasm`.
```

--target nennt ein anderes System als das, auf dem hilde läuft.  Ein Binary baut der C-Compiler
der Maschine und linkt es gegen ihre C-Bibliothek, also wird es auf einer Maschine des Systems
gebaut, für das es ist; nur WebAssembly, ein Modul, das auf jedem System läuft, wird überall
gebaut.

Er bleibt, weil sich ein Binary für ein anderes System hier nicht bauen lässt.  Er wird hier
nicht ausgelöst, weil es von der Maschine abhängt, auf der der Katalog übersetzt
wird, welches System fremd ist, und die Gates laufen auf vieren.

Nicht ausgelöst: Es fand sich kein Programm, das diesen Fehler erreicht.

### H1043

Meldung:

```text
Command Line Arguments Error
`--target=wasm` cannot build `--target-type=static`: there is no archive and no shared object for WebAssembly.

A programme with an entrypoint becomes a command module, `--target-type=wasm` a library module, a reactor.
```

--target=wasm steht bei einem Archiv oder einem Shared Object.  WebAssembly hat zwei Formen
eines Moduls: ein Kommando, ein Programm mit main, und einen Reaktor, eine Bibliothek, die ihr
Host aufruft.

Dieses Modul scheitert mit H1043:

```hilde fails H1043
module body Example is
    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Übersetzt mit:


```sh command
hilde build Example.hiq --target=wasm --target-type=static --output=libexample.a
```

Die richtige Form:

```hilde
module body Example is
    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Übersetzt mit:


```sh command
hilde build Example.hiq --target=wasm --target-type=c --entrypoint=Example:main --output=prog.c
```

### H1044

Meldung:

```text
Command Line Arguments Error
The output of `--target=wasm` is a module for wasm32-wasi and must end in `.wasm`, and `prog` does not.
```

Die Ausgabe eines Programms für wasm endet nicht auf .wasm.  Ein Modul ist kein Binary des
Systems: Sein Name sagt, was es ist, und wasmtime und ein Host in JavaScript nehmen es unter
diesem Namen.

Dieses Modul scheitert mit H1044:

```hilde fails H1044
module body Example is
    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Übersetzt mit:


```sh command
hilde build Example.hiq --target=wasm --entrypoint=Example:main --output=prog
```

Die richtige Form:

```hilde
module body Example is
    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Übersetzt mit:


```sh command
hilde build Example.hiq --target=wasm --target-type=c --entrypoint=Example:main --output=prog.c
```

### H2068

Meldung:

```text
Declaration Error
Invalid `pragma Targets`: plan9 is no target.

It takes `Names`, the targets separated by one space each, out of `linux, openbsd, freebsd, darwin, wasm`, and after it, where another module does the work on the other targets, `Instead`: `pragma Targets(Names => "linux openbsd freebsd darwin", Instead => "Standard.Regex");`
```

Ein pragma Targets nennt kein Ziel, eines doppelt, eines, das es nicht gibt, oder ein Instead,
das kein Modul ist.  Instead nennt ein Modul mit seinem vollen Namen, und nur, wo ein Ziel fehlt.

Dieses Modul scheitert mit H2068:

```hilde fails H2068
import Standard.Thing (
    size
);

module body Example is
    function main(): ExitCode is
        let n: Index := size();
        return ExitSuccess();
    end;
end module body.
```

Daneben `Thing.hih`:


```hilde file Thing.hih
pragma Targets(Names => "linux plan9");
module Standard.Thing is
    function size(): Index;
end module.
```

Daneben `Thing.hiq`:


```hilde file Thing.hiq
module body Standard.Thing is
    function size(): Index is
        return 1;
    end;
end module body.
```

Die richtige Form:

```hilde
import Standard.Thing (
    size
);

module body Example is
    function main(): ExitCode is
        let n: Index := size();
        return ExitSuccess();
    end;
end module body.
```

Daneben `Thing.hih`:


```hilde file Thing.hih
pragma Targets(Names => "linux openbsd freebsd darwin wasm");
module Standard.Thing is
    function size(): Index;
end module.
```

Daneben `Thing.hiq`:


```hilde file Thing.hiq
module body Standard.Thing is
    function size(): Index is
        return 1;
    end;
end module body.
```

### H2069

Meldung:

```text
Declaration Error
`pragma Unsafe_Module` cannot stand before a module interface.

Only `pragma Targets` stands there, once.
```

Ein anderes Pragma als ein pragma Targets steht vor einem Modul-Interface.  Was ein Modul bindet
und ob es unsicher ist, steht vor seinem Body.

Dieses Modul scheitert mit H2069:

```hilde fails H2069
import Standard.Thing (
    size
);

module body Example is
    function main(): ExitCode is
        let n: Index := size();
        return ExitSuccess();
    end;
end module body.
```

Daneben `Thing.hih`:


```hilde file Thing.hih
pragma Unsafe_Module;
pragma Targets(Names => "linux openbsd freebsd darwin wasm");
module Standard.Thing is
    function size(): Index;
end module.
```

Daneben `Thing.hiq`:


```hilde file Thing.hiq
module body Standard.Thing is
    function size(): Index is
        return 1;
    end;
end module body.
```

Die richtige Form:

```hilde
import Standard.Thing (
    size
);

module body Example is
    function main(): ExitCode is
        let n: Index := size();
        return ExitSuccess();
    end;
end module body.
```

Daneben `Thing.hih`:


```hilde file Thing.hih
pragma Targets(Names => "linux openbsd freebsd darwin wasm");
module Standard.Thing is
    function size(): Index;
end module.
```

Daneben `Thing.hiq`:


```hilde file Thing.hiq
module body Standard.Thing is
    function size(): Index is
        return 1;
    end;
end module body.
```

### H2070

Meldung:

```text
Declaration Error
`Thing` names its targets with `pragma Targets`, and only a module of the standard library does.

A programme is there for the targets of the modules it imports: what differs between the targets is in the standard library, and a programme holds no code for one target only.
```

Ein Modul außerhalb der Standardbibliothek nennt seine Ziele.  Ein Programm wählt die Ziele
nicht, für die es gebaut wird: Es gibt es für die der Module, die es importiert, und der Compiler
hält es daran.  Die Standardbibliothek ist ein Modul, dessen Name mit Standard. oder Bindings.
beginnt.

Dieses Modul scheitert mit H2070:

```hilde fails H2070
import Thing (
    size
);

module body Example is
    function main(): ExitCode is
        let n: Index := size();
        return ExitSuccess();
    end;
end module body.
```

Daneben `Thing.hih`:


```hilde file Thing.hih
pragma Targets(Names => "linux openbsd freebsd darwin wasm");
module Thing is
    function size(): Index;
end module.
```

Daneben `Thing.hiq`:


```hilde file Thing.hiq
module body Thing is
    function size(): Index is
        return 1;
    end;
end module body.
```

Die richtige Form:

```hilde
import Thing (
    size
);

module body Example is
    function main(): ExitCode is
        let n: Index := size();
        return ExitSuccess();
    end;
end module body.
```

Daneben `Thing.hih`:


```hilde file Thing.hih
module Thing is
    function size(): Index;
end module.
```

Daneben `Thing.hiq`:


```hilde file Thing.hiq
module body Thing is
    function size(): Index is
        return 1;
    end;
end module body.
```

### H2071

Meldung:

```text
Declaration Error
The module `Standard.Thing` of the standard library names no targets.

Its interface says before its imports which targets it is there for: `pragma Targets(Names => "linux openbsd freebsd darwin wasm");`
```

Ein Interface der Standardbibliothek nennt keine Ziele.  Jedes Modul, dessen Name mit Standard.
beginnt, sagt, für welche Ziele es es gibt, damit ein Programm, das für eines gebaut wird, es an
seinen Importen merkt und nicht beim Linken.

Dieses Modul scheitert mit H2071:

```hilde fails H2071
import Standard.Thing (
    size
);

module body Example is
    function main(): ExitCode is
        let n: Index := size();
        return ExitSuccess();
    end;
end module body.
```

Daneben `Thing.hih`:


```hilde file Thing.hih
module Standard.Thing is
    function size(): Index;
end module.
```

Daneben `Thing.hiq`:


```hilde file Thing.hiq
module body Standard.Thing is
    function size(): Index is
        return 1;
    end;
end module body.
```

Die richtige Form:

```hilde
import Standard.Thing (
    size
);

module body Example is
    function main(): ExitCode is
        let n: Index := size();
        return ExitSuccess();
    end;
end module body.
```

Daneben `Thing.hih`:


```hilde file Thing.hih
pragma Targets(Names => "linux openbsd freebsd darwin wasm");
module Standard.Thing is
    function size(): Index;
end module.
```

Daneben `Thing.hiq`:


```hilde file Thing.hiq
module body Standard.Thing is
    function size(): Index is
        return 1;
    end;
end module body.
```

### H2072

Meldung:

```text
Declaration Error
`Standard.Thing` names the target `wasm`, but imports `Standard.Other`, which is not there for it.

A module is there only for targets all its imports are there for: take `wasm` out of its pragma Targets, or make the import there for it.
```

Ein Modul nennt ein Ziel, für das es einen seiner Importe nicht gibt.  Das gilt, wofür das
Programm auch gebaut wird, also können die Ziele der Standardbibliothek nicht mehr behaupten, als
sie haben.

Dieses Modul scheitert mit H2072:

```hilde fails H2072
import Standard.Thing (
    size
);

module body Example is
    function main(): ExitCode is
        let n: Index := size();
        return ExitSuccess();
    end;
end module body.
```

Daneben `Thing.hih`:


```hilde file Thing.hih
pragma Targets(Names => "linux openbsd freebsd darwin wasm");
import Standard.Other (
    one
);
module Standard.Thing is
    function size(): Index;
end module.
```

Daneben `Thing.hiq`:


```hilde file Thing.hiq
module body Standard.Thing is
    function size(): Index is
        return 1;
    end;
end module body.
```

Daneben `Other.hih`:


```hilde file Other.hih
pragma Targets(Names => "linux openbsd freebsd darwin");
module Standard.Other is
    function one(): Index;
end module.
```

Daneben `Other.hiq`:


```hilde file Other.hiq
module body Standard.Other is
    function one(): Index is
        return 1;
    end;
end module body.
```

Die richtige Form:

```hilde
import Standard.Thing (
    size
);

module body Example is
    function main(): ExitCode is
        let n: Index := size();
        return ExitSuccess();
    end;
end module body.
```

Daneben `Thing.hih`:


```hilde file Thing.hih
pragma Targets(Names => "linux openbsd freebsd darwin");
import Standard.Other (
    one
);
module Standard.Thing is
    function size(): Index;
end module.
```

Daneben `Thing.hiq`:


```hilde file Thing.hiq
module body Standard.Thing is
    function size(): Index is
        return 1;
    end;
end module body.
```

Daneben `Other.hih`:


```hilde file Other.hih
pragma Targets(Names => "linux openbsd freebsd darwin");
module Standard.Other is
    function one(): Index;
end module.
```

Daneben `Other.hiq`:


```hilde file Other.hiq
module body Standard.Other is
    function one(): Index is
        return 1;
    end;
end module body.
```

### H2073

Meldung:

```text
Declaration Error
`Standard.Thing` is not there for the target `wasm`, and `Example` imports it.

It is there for linux, openbsd, freebsd, darwin. Take `Standard.Other` instead.

Suggested fix: `Standard.Other`
```

Ein Programm, das für ein Ziel gebaut wird, importiert ein Modul, das es dafür nicht gibt.  Die
Meldung nennt die Ziele, für die es das Modul gibt, und, wo sein pragma Targets eines nennt, das
Modul, das stattdessen zu nehmen ist; --error-format=json und hilde-json tragen dieses Modul als
Vorschlag.

Dieses Modul scheitert mit H2073:

```hilde fails H2073
import Standard.Thing (
    size
);

module body Example is
    function main(): ExitCode is
        let n: Index := size();
        return ExitSuccess();
    end;
end module body.
```

Daneben `Thing.hih`:


```hilde file Thing.hih
pragma Targets(Names => "linux openbsd freebsd darwin", Instead => "Standard.Other");
module Standard.Thing is
    function size(): Index;
end module.
```

Daneben `Thing.hiq`:


```hilde file Thing.hiq
module body Standard.Thing is
    function size(): Index is
        return 1;
    end;
end module body.
```

Übersetzt mit:


```sh command
hilde build Thing.hih,Thing.hiq Example.hiq --target=wasm --target-type=c --entrypoint=Example:main --output=prog.c
```

Die richtige Form:

```hilde
import Standard.Thing (
    size
);

module body Example is
    function main(): ExitCode is
        let n: Index := size();
        return ExitSuccess();
    end;
end module body.
```

Daneben `Thing.hih`:


```hilde file Thing.hih
pragma Targets(Names => "linux openbsd freebsd darwin wasm");
module Standard.Thing is
    function size(): Index;
end module.
```

Daneben `Thing.hiq`:


```hilde file Thing.hiq
module body Standard.Thing is
    function size(): Index is
        return 1;
    end;
end module body.
```

Übersetzt mit:


```sh command
hilde build Thing.hih,Thing.hiq Example.hiq --target=wasm --target-type=c --entrypoint=Example:main --output=prog.c
```

## 13. Pakete

Die Paketkommandos, die hilde-pkg neben dem Compiler ausführt: get, update, verify, export,
new, install, doc und api-diff.  docs/package-manager.de.md beschreibt sie.

### H1045

Meldung, aus dem Quelltext in `lib/CliParser.ml`:

```text
The package commands are carried out by `path`, which is not there.
Build it beside the compiler with `make hilde-pkg`, or install both with `make install`.
```

Ein Paketkommando wurde gegeben, und hilde-pkg liegt nicht neben dem Compiler.

Er bleibt, weil kein Beispiel ihn auslöst, da der Compiler der Gates hilde-pkg neben sich hat; scripts/check-pkg.sh fährt die Paketkommandos.

### H1046

Meldung, aus dem Quelltext in `lib/CliParser.ml`:

```text
`path` could not be started: why.
Check that it may be run, or build it again with `make hilde-pkg`.
```

hilde-pkg liegt neben dem Compiler und ließ sich nicht starten.

Er bleibt, weil kein Beispiel ihn auslöst, da der Compiler der Gates hilde-pkg neben sich hat; scripts/check-pkg.sh fährt die Paketkommandos.

### H1501

Meldung, aus dem Quelltext in `pkg/src/Export.hiq`:

```text
no hilde.toml in .
```

Das Kommando braucht ein Paket, und im Verzeichnis liegt keine hilde.toml.

Er bleibt, weil er eine Meldung von hilde-pkg ist, das die Beispiele dieses Katalogs, die der Compiler übersetzt, nicht ausführen; scripts/check-pkg.sh löst ihn in beiden Gates aus.

### H1502

Meldung, aus dem Quelltext in `pkg/src/Manifest.hiq`:

```text
hilde.toml is not TOML: what, at line L, column C
```

hilde.toml ist kein TOML; die Meldung nennt Zeile und Spalte.

Er bleibt, weil er eine Meldung von hilde-pkg ist, das die Beispiele dieses Katalogs, die der Compiler übersetzt, nicht ausführen; scripts/check-pkg.sh löst ihn in beiden Gates aus.

### H1503

Meldung, aus dem Quelltext in `pkg/src/Manifest.hiq`:

```text
hilde.toml has the key k in table, which a manifest does not have
```

hilde.toml hat einen Schlüssel oder eine Tabelle, die ein Manifest nicht hat, etwa einen vertippten.

Er bleibt, weil er eine Meldung von hilde-pkg ist, das die Beispiele dieses Katalogs, die der Compiler übersetzt, nicht ausführen; scripts/check-pkg.sh löst ihn in beiden Gates aus.

### H1504

Meldung, aus dem Quelltext in `pkg/src/Manifest.hiq`:

```text
package.name is missing in hilde.toml
```

Ein Schlüssel, den hilde.toml haben muss, fehlt: Name oder Version des Pakets, git-URL oder Version einer Anforderung.

Er bleibt, weil er eine Meldung von hilde-pkg ist, das die Beispiele dieses Katalogs, die der Compiler übersetzt, nicht ausführen; scripts/check-pkg.sh löst ihn in beiden Gates aus.

### H1505

Meldung, aus dem Quelltext in `pkg/src/Get.hiq`:

```text
hilde get takes Prefix@vX.Y.Z, not text
```

Ein Wert hat die falsche Form: ein Name, der kein Modulpräfix ist, eine Version, die nicht vX.Y.Z ist, eine Fähigkeit, die es nicht gibt, oder ein Argument falscher Form.

Er bleibt, weil er eine Meldung von hilde-pkg ist, das die Beispiele dieses Katalogs, die der Compiler übersetzt, nicht ausführen; scripts/check-pkg.sh löst ihn in beiden Gates aus.

### H1506

Meldung, aus dem Quelltext in `pkg/src/Get.hiq`:

```text
the package at URL is named N, and P requires it as Q
```

Ein Präfix kommt von zwei git-URLs, oder ein Paket heißt anders als das Präfix, unter dem es verlangt wird.

Er bleibt, weil er eine Meldung von hilde-pkg ist, das die Beispiele dieses Katalogs, die der Compiler übersetzt, nicht ausführen; scripts/check-pkg.sh löst ihn in beiden Gates aus.

### H1507

Meldung, aus dem Quelltext in `pkg/src/Export.hiq`:

```text
git is not on PATH, and hilde export reads the tags with git
```

git ist nicht im PATH, und das Kommando braucht es.

Er bleibt, weil er eine Meldung von hilde-pkg ist, das die Beispiele dieses Katalogs, die der Compiler übersetzt, nicht ausführen; scripts/check-pkg.sh löst ihn in beiden Gates aus.

### H1508

Meldung, aus dem Quelltext in `pkg/src/Git.hiq`:

```text
git cannot list the tags of URL: git said: line
```

git ist gescheitert: eine falsche URL, ein Repository, das nicht gelesen werden darf, oder ein Programm, das sich nicht starten ließ.

Er bleibt, weil er eine Meldung von hilde-pkg ist, das die Beispiele dieses Katalogs, die der Compiler übersetzt, nicht ausführen; scripts/check-pkg.sh löst ihn in beiden Gates aus.

### H1509

Meldung, aus dem Quelltext in `pkg/src/Git.hiq`:

```text
the repository URL has no tag vX.Y.Z
```

Das Repository hat keinen Tag der verlangten Version; der Vorschlag nennt die nächstliegenden Tags.

Er bleibt, weil er eine Meldung von hilde-pkg ist, das die Beispiele dieses Katalogs, die der Compiler übersetzt, nicht ausführen; scripts/check-pkg.sh löst ihn in beiden Gates aus.

### H1510

Meldung, aus dem Quelltext in `pkg/src/Tree.hiq`:

```text
a package holds only files and directories, not a link or a special file: path
```

Der Baum eines Pakets enthält einen symbolischen Link oder eine Sonderdatei.

Er bleibt, weil er eine Meldung von hilde-pkg ist, das die Beispiele dieses Katalogs, die der Compiler übersetzt, nicht ausführen; scripts/check-pkg.sh löst ihn in beiden Gates aus.

### H1511

Meldung, aus dem Quelltext in `pkg/src/Get.hiq`:

```text
the release of P has no signature, and policy.require-signatures is true
```

Ein Release hat keine Signatur, und die Richtlinie des Pakets verlangt eine.

Er bleibt, weil er eine Meldung von hilde-pkg ist, das die Beispiele dieses Katalogs, die der Compiler übersetzt, nicht ausführen; scripts/check-pkg.sh löst ihn in beiden Gates aus.

### H1512

Meldung, aus dem Quelltext in `pkg/src/Get.hiq`:

```text
the signature of P does not hold for its tree and its key
```

Eine Signatur hält nicht, der Schlüssel ist nicht der bei der ersten Verwendung übernommene, oder ein Release ist nach einem signierten unsigniert.

Er bleibt, weil er eine Meldung von hilde-pkg ist, das die Beispiele dieses Katalogs, die der Compiler übersetzt, nicht ausführen; scripts/check-pkg.sh löst ihn in beiden Gates aus.

### H1513

Meldung, aus dem Quelltext in `pkg/src/Export.hiq`:

```text
path is not a secret key of signify without a passphrase
```

Der geheime Schlüssel lässt sich nicht lesen, ist kein signify-Schlüssel oder hat eine Passphrase.

Er bleibt, weil er eine Meldung von hilde-pkg ist, das die Beispiele dieses Katalogs, die der Compiler übersetzt, nicht ausführen; scripts/check-pkg.sh löst ihn in beiden Gates aus.

### H1514

Meldung, aus dem Quelltext in `pkg/src/Sum.hiq`:

```text
hilde.sum, line N: what
```

hilde.sum fehlt, hat eine falsche Zeile oder keine Zeile für eine Anforderung.

Er bleibt, weil er eine Meldung von hilde-pkg ist, das die Beispiele dieses Katalogs, die der Compiler übersetzt, nicht ausführen; scripts/check-pkg.sh löst ihn in beiden Gates aus.

### H1515

Meldung, aus dem Quelltext in `pkg/src/Verify.hiq`:

```text
vendor/ has no tree P, which hilde.sum names
```

Ein Baum in vendor/ fehlt, ist geändert oder steht nicht in hilde.sum.

Er bleibt, weil er eine Meldung von hilde-pkg ist, das die Beispiele dieses Katalogs, die der Compiler übersetzt, nicht ausführen; scripts/check-pkg.sh löst ihn in beiden Gates aus.

### H1516

Meldung, aus dem Quelltext in `pkg/src/Get.hiq`:

```text
P is required as vA by X and as vB by Y
```

Zwei Hauptversionen eines Pakets werden verlangt; eine neue Hauptversion bekommt ein neues Präfix.

Er bleibt, weil er eine Meldung von hilde-pkg ist, das die Beispiele dieses Katalogs, die der Compiler übersetzt, nicht ausführen; scripts/check-pkg.sh löst ihn in beiden Gates aus.

### H1517

Meldung, aus dem Quelltext in `pkg/src/Tree.hiq`:

```text
the tree is deeper than 64 directories at: path
```

Der Baum eines Pakets ist tiefer als 64 Verzeichnisse.

Er bleibt, weil er eine Meldung von hilde-pkg ist, das die Beispiele dieses Katalogs, die der Compiler übersetzt, nicht ausführen; scripts/check-pkg.sh löst ihn in beiden Gates aus.

### H1518

Meldung, aus dem Quelltext in `pkg/src/Tree.hiq`:

```text
a directory cannot be read: path
```

Ein Verzeichnis oder eine Datei eines Pakets lässt sich nicht lesen.

Er bleibt, weil er eine Meldung von hilde-pkg ist, das die Beispiele dieses Katalogs, die der Compiler übersetzt, nicht ausführen; scripts/check-pkg.sh löst ihn in beiden Gates aus.

### H1519

Meldung, aus dem Quelltext in `pkg/src/Export.hiq`:

```text
llms.txt or man/man3 cannot be written in root
```

Eine Datei oder ein Verzeichnis lässt sich nicht schreiben.

Er bleibt, weil er eine Meldung von hilde-pkg ist, das die Beispiele dieses Katalogs, die der Compiler übersetzt, nicht ausführen; scripts/check-pkg.sh löst ihn in beiden Gates aus.

### H1521

Meldung, aus dem Quelltext in `pkg/src/Main.hiq`:

```text
the directory is there already: path
```

hilde new oder ein Schlüssel würde über etwas schreiben, das schon da ist.

Er bleibt, weil er eine Meldung von hilde-pkg ist, das die Beispiele dieses Katalogs, die der Compiler übersetzt, nicht ausführen; scripts/check-pkg.sh löst ihn in beiden Gates aus.

### H1522

Meldung, aus dem Quelltext in `pkg/src/Main.hiq`:

```text
no module or declaration X in src, vendor/ or the standard library
```

hilde doc findet kein Modul und keine Deklaration des Namens.

Er bleibt, weil er eine Meldung von hilde-pkg ist, das die Beispiele dieses Katalogs, die der Compiler übersetzt, nicht ausführen; scripts/check-pkg.sh löst ihn in beiden Gates aus.

### H1523

Meldung, aus dem Quelltext in `pkg/src/Targets.hiq`:

```text
hilde.toml names the target T, and a module the package reaches does not allow it: M
```

Ein Ziel aus hilde.toml erlaubt das pragma Targets eines erreichten Moduls nicht.

Er bleibt, weil er eine Meldung von hilde-pkg ist, das die Beispiele dieses Katalogs, die der Compiler übersetzt, nicht ausführen; scripts/check-pkg.sh löst ihn in beiden Gates aus.

### H1530

Meldung, aus dem Quelltext in `pkg/src/Export.hiq`:

```text
the interface changed as a major release does since vA, and hilde.toml says vB
```

Die Version eines Releases ist niedriger, als die Änderung der Schnittstelle verlangt, etwa ein Bruch unter einer Nebenversion.

Er bleibt, weil er eine Meldung von hilde-pkg ist, das die Beispiele dieses Katalogs, die der Compiler übersetzt, nicht ausführen; scripts/check-pkg.sh löst ihn in beiden Gates aus.

### H1531

Meldung, aus dem Quelltext in `pkg/src/Export.hiq`:

```text
a release needs a test file for each module, and these are missing: files
```

Ein Modul des Pakets hat keine Testdatei.

Er bleibt, weil er eine Meldung von hilde-pkg ist, das die Beispiele dieses Katalogs, die der Compiler übersetzt, nicht ausführen; scripts/check-pkg.sh löst ihn in beiden Gates aus.

### H1532

Meldung, aus dem Quelltext in `pkg/src/Export.hiq`:

```text
the tests of the package do not pass: last line
```

Die Tests des Pakets laufen nicht durch, oder der Compiler scheiterte daran.

Er bleibt, weil er eine Meldung von hilde-pkg ist, das die Beispiele dieses Katalogs, die der Compiler übersetzt, nicht ausführen; scripts/check-pkg.sh löst ihn in beiden Gates aus.

### H1533

Meldung, aus dem Quelltext in `pkg/src/Export.hiq`:

```text
every exported function must be called in a test, and these are not: names
```

Eine exportierte Funktion wird in keinem Test aufgerufen.

Er bleibt, weil er eine Meldung von hilde-pkg ist, das die Beispiele dieses Katalogs, die der Compiler übersetzt, nicht ausführen; scripts/check-pkg.sh löst ihn in beiden Gates aus.

### H1534

Meldung, aus dem Quelltext in `pkg/src/Export.hiq`:

```text
hilde.toml says vA, and the newest tag is vB
```

Die Version eines Releases ist nicht neuer als der neueste Tag.

Er bleibt, weil er eine Meldung von hilde-pkg ist, das die Beispiele dieses Katalogs, die der Compiler übersetzt, nicht ausführen; scripts/check-pkg.sh löst ihn in beiden Gates aus.

## 14. Sperli

Das Kommando run und die Cluster-Schicht: hilde run, das hilde-launcher neben dem Compiler ausführt, und die Abweisungen eines Sperli-Jobs, H1601 bis H1625.  docs/sperli.de.md beschreibt sie.

### H1047

Meldung, aus dem Quelltext in `lib/CliParser.ml`:

```text
The command run is carried out by `path`, which is not there.
Build it beside the compiler with `make hilde-launcher`, or install both with `make install`.
```

Ein run-Kommando wurde gegeben, und hilde-launcher liegt nicht neben dem Compiler.

Er bleibt, weil er eine Meldung von hilde run ist, das die Beispiele dieses Katalogs, die der Compiler übersetzt, nicht ausführen; die Tests in standard/src/Sperli.test.hiq und test-programs/suites/100-sperli lösen ihn in den Gates aus.

### H1048

Meldung, aus dem Quelltext in `lib/CliParser.ml`:

```text
`path` could not be started: why.
Check that it may be run, or build it again with `make hilde-launcher`.
```

hilde-launcher liegt neben dem Compiler und ließ sich nicht starten.

Er bleibt, weil er eine Meldung von hilde run ist, das die Beispiele dieses Katalogs, die der Compiler übersetzt, nicht ausführen; die Tests in standard/src/Sperli.test.hiq und test-programs/suites/100-sperli lösen ihn in den Gates aus.

### H1601

Meldung, aus dem Quelltext in `standard/src/SperliError.hiq`:

```text
the peer has no certificate of the job CA
```

Der Partner zeigte kein Zertifikat, eines, für das die CA des Jobs nicht bürgt, oder bot eine TLS-Version unter 1.3 an.

Er bleibt, weil er eine Abweisung eines Sperli-Jobs ist, das die Beispiele dieses Katalogs, die der Compiler übersetzt, nicht ausführen; die Tests in standard/src/Sperli.test.hiq und test-programs/suites/100-sperli lösen ihn in den Gates aus.

### H1602

Meldung, aus dem Quelltext in `standard/src/SperliError.hiq`:

```text
the subject of the certificate is not the job and rank of the peer
```

Der Subject des Zertifikats des Partners ist nicht der Job und der Rang, für den die Verbindung gilt.

Er bleibt, weil er eine Abweisung eines Sperli-Jobs ist, das die Beispiele dieses Katalogs, die der Compiler übersetzt, nicht ausführen; die Tests in standard/src/Sperli.test.hiq und test-programs/suites/100-sperli lösen ihn in den Gates aus.

### H1603

Meldung, aus dem Quelltext in `standard/src/SperliError.hiq`:

```text
the host is refused
```

Ein Host steht in SPERLI_REFUSED_HOSTS, ist host-a.invalid oder host-b.invalid oder ein Name darunter oder steht auf der Sperrliste des Betreibers; eine Sperrliste hebt die Regel nicht auf.

Er bleibt, weil er eine Abweisung eines Sperli-Jobs ist, das die Beispiele dieses Katalogs, die der Compiler übersetzt, nicht ausführen; die Tests in standard/src/Sperli.test.hiq und test-programs/suites/100-sperli lösen ihn in den Gates aus.

### H1604

Meldung, aus dem Quelltext in `standard/src/SperliError.hiq`:

```text
the join token has expired
```

Das Join-Token eines Partners ist abgelaufen.

Er bleibt, weil er eine Abweisung eines Sperli-Jobs ist, das die Beispiele dieses Katalogs, die der Compiler übersetzt, nicht ausführen; die Tests in standard/src/Sperli.test.hiq und test-programs/suites/100-sperli lösen ihn in den Gates aus.

### H1605

Meldung, aus dem Quelltext in `standard/src/SperliError.hiq`:

```text
the join token is for another job
```

Das Join-Token eines Partners wurde für einen anderen Job ausgestellt.

Er bleibt, weil er eine Abweisung eines Sperli-Jobs ist, das die Beispiele dieses Katalogs, die der Compiler übersetzt, nicht ausführen; die Tests in standard/src/Sperli.test.hiq und test-programs/suites/100-sperli lösen ihn in den Gates aus.

### H1606

Meldung, aus dem Quelltext in `standard/src/SperliError.hiq`:

```text
the join token is for another rank, size, incarnation or host
```

Das Join-Token eines Partners wurde für einen anderen Rang, eine andere Größe, Inkarnation oder einen anderen Host ausgestellt.

Er bleibt, weil er eine Abweisung eines Sperli-Jobs ist, das die Beispiele dieses Katalogs, die der Compiler übersetzt, nicht ausführen; die Tests in standard/src/Sperli.test.hiq und test-programs/suites/100-sperli lösen ihn in den Gates aus.

### H1607

Meldung, aus dem Quelltext in `standard/src/SperliError.hiq`:

```text
the join token is malformed or its signature does not hold
```

Das Join-Token eines Partners ist missgebildet, oder seine Signatur gilt unter dem öffentlichen Schlüssel des Starters nicht.

Er bleibt, weil er eine Abweisung eines Sperli-Jobs ist, das die Beispiele dieses Katalogs, die der Compiler übersetzt, nicht ausführen; die Tests in standard/src/Sperli.test.hiq und test-programs/suites/100-sperli lösen ihn in den Gates aus.

### H1608

Meldung, aus dem Quelltext in `standard/src/SperliError.hiq`:

```text
the frame is larger than the limit
```

Ein Frame kündigt mehr Nutzlast an als die Grenze von 16 MiB; er wird abgewiesen, bevor ein Byte der Nutzlast gelesen wird.

Er bleibt, weil er eine Abweisung eines Sperli-Jobs ist, das die Beispiele dieses Katalogs, die der Compiler übersetzt, nicht ausführen; die Tests in standard/src/Sperli.test.hiq und test-programs/suites/100-sperli lösen ihn in den Gates aus.

### H1609

Meldung, aus dem Quelltext in `standard/src/SperliError.hiq`:

```text
the frame is from an older incarnation
```

Ein Frame gehört zu einer älteren Inkarnation des Jobs; seine Nutzlast wird gelesen und verworfen, und das Warten geht weiter.

Er bleibt, weil er eine Abweisung eines Sperli-Jobs ist, das die Beispiele dieses Katalogs, die der Compiler übersetzt, nicht ausführen; die Tests in standard/src/Sperli.test.hiq und test-programs/suites/100-sperli lösen ihn in den Gates aus.

### H1610

Meldung, aus dem Quelltext in `standard/src/SperliError.hiq`:

```text
the header of the frame breaks the protocol
```

Der Kopf eines Frames bricht eine Regel des Protokolls: ein unbekannter Typ, ein Flag, ein Dienst oder eine Mitgliedschaftsepoche ungleich 0, ein anderer Job, andere Ränge oder eine neuere Inkarnation.

Er bleibt, weil er eine Abweisung eines Sperli-Jobs ist, das die Beispiele dieses Katalogs, die der Compiler übersetzt, nicht ausführen; die Tests in standard/src/Sperli.test.hiq und test-programs/suites/100-sperli lösen ihn in den Gates aus.

### H1611

Meldung, aus dem Quelltext in `standard/src/SperliError.hiq`:

```text
the peer was lost
```

Ein Partner ging verloren: Die Verbindung wurde geschlossen, oder innerhalb der Stillegrenze kam kein Frame.

Er bleibt, weil er eine Abweisung eines Sperli-Jobs ist, das die Beispiele dieses Katalogs, die der Compiler übersetzt, nicht ausführen; die Tests in standard/src/Sperli.test.hiq und test-programs/suites/100-sperli lösen ihn in den Gates aus.

### H1612

Meldung, aus dem Quelltext in `standard/src/SperliError.hiq`:

```text
the peer aborted the job
```

Ein Partner schickte einen Abort-Frame.

Er bleibt, weil er eine Abweisung eines Sperli-Jobs ist, das die Beispiele dieses Katalogs, die der Compiler übersetzt, nicht ausführen; die Tests in standard/src/Sperli.test.hiq und test-programs/suites/100-sperli lösen ihn in den Gates aus.

### H1613

Meldung, aus dem Quelltext in `standard/src/SperliError.hiq`:

```text
the hello of the peer is missing, repeated or not acceptable
```

Das Hello eines Partners fehlt, kommt zweimal, hat eine andere Version oder bietet keinen Punkt-zu-Punkt-Dienst an.

Er bleibt, weil er eine Abweisung eines Sperli-Jobs ist, das die Beispiele dieses Katalogs, die der Compiler übersetzt, nicht ausführen; die Tests in standard/src/Sperli.test.hiq und test-programs/suites/100-sperli lösen ihn in den Gates aus.

### H1614

Meldung, aus dem Quelltext in `standard/src/SperliError.hiq`:

```text
the command line or the host list is wrong
```

Die Kommandozeile von hilde run oder seine Hostliste ist falsch: eine fehlende oder unbekannte Option, eine Zahl außerhalb des Bereichs, kein Host oder eine Zeile, die kein Host mit Port ist.

Er bleibt, weil er eine Abweisung eines Sperli-Jobs ist, das die Beispiele dieses Katalogs, die der Compiler übersetzt, nicht ausführen; die Tests in standard/src/Sperli.test.hiq und test-programs/suites/100-sperli lösen ihn in den Gates aus.

### H1615

Meldung, aus dem Quelltext in `standard/src/SperliError.hiq`:

```text
a rank could not be started
```

Ein Rang ließ sich nicht starten, oder die Schlüssel, Zertifikate oder Ports des Jobs ließen sich nicht herstellen.

Er bleibt, weil er eine Abweisung eines Sperli-Jobs ist, das die Beispiele dieses Katalogs, die der Compiler übersetzt, nicht ausführen; die Tests in standard/src/Sperli.test.hiq und test-programs/suites/100-sperli lösen ihn in den Gates aus.

### H1616

Meldung, aus dem Quelltext in `standard/src/SperliError.hiq`:

```text
the job description is malformed
```

Die Jobbeschreibung, die ein Rang auf der Standardeingabe bekam, ist missgebildet.

Er bleibt, weil er eine Abweisung eines Sperli-Jobs ist, das die Beispiele dieses Katalogs, die der Compiler übersetzt, nicht ausführen; die Tests in standard/src/Sperli.test.hiq und test-programs/suites/100-sperli lösen ihn in den Gates aus.

### H1617

Meldung, aus dem Quelltext in `standard/src/SperliError.hiq`:

```text
the collective frame does not match the call
```

Ein Kollektiv-Frame passt nicht zu dem Aufruf, den er beantwortet: andere Operation, anderer Typ, andere Reduktion, Phase, Wurzel oder Folgenummer, oder Beiträge eines gather verschiedener Länge.

Er bleibt, weil er eine Abweisung eines Sperli-Jobs ist, das die Beispiele dieses Katalogs, die der Compiler übersetzt, nicht ausführen; die Tests in standard/src/Sperli.test.hiq und test-programs/suites/100-sperli lösen ihn in den Gates aus.

### H1618

Meldung, aus dem Quelltext in `standard/src/SperliError.hiq`:

```text
the arguments of the collective call are wrong
```

Die Argumente eines Kollektiv-Aufrufs sind falsch: eine Wurzel außerhalb des Jobs, ein Elementtyp und eine Reduktion, die nicht zusammenpassen, Daten, die keine ganze Zahl von Elementen oder Blöcken sind, oder Beiträge eines reduce verschiedener Länge.

Er bleibt, weil er eine Abweisung eines Sperli-Jobs ist, das die Beispiele dieses Katalogs, die der Compiler übersetzt, nicht ausführen; die Tests in standard/src/Sperli.test.hiq und test-programs/suites/100-sperli lösen ihn in den Gates aus.

### H1619

Meldung, aus dem Quelltext in `standard/src/SperliError.hiq`:

```text
the checkpoint file is not the one expected
```

Eine Checkpoint-Datei hat eine andere Magic oder Version oder einen Job, eine Epoche, einen Rang, eine Größe oder eine Länge, die nicht die erwartete ist, oder sie ist zu kurz.

Er bleibt, weil er eine Abweisung eines Sperli-Jobs ist, das die Beispiele dieses Katalogs, die der Compiler übersetzt, nicht ausführen; die Tests in standard/src/SperliCkpt.test.hiq und test-programs/suites/100-sperli lösen ihn in den Gates aus.

### H1620

Meldung, aus dem Quelltext in `standard/src/SperliError.hiq`:

```text
the SHA-256 of the checkpoint file does not match
```

Das SHA-256 des Zustands in einer Checkpoint-Datei ist nicht das in ihrem Kopf oder nicht das, das die COMMIT-Datei für den Rang aufführt.

Er bleibt, weil er eine Abweisung eines Sperli-Jobs ist, das die Beispiele dieses Katalogs, die der Compiler übersetzt, nicht ausführen; die Tests in standard/src/SperliCkpt.test.hiq und test-programs/suites/100-sperli lösen ihn in den Gates aus.

### H1621

Meldung, aus dem Quelltext in `standard/src/SperliError.hiq`:

```text
the COMMIT file is malformed or its signature does not hold
```

Eine COMMIT-Datei ist missgebildet, gehört zu einem anderen Job oder einer anderen Epoche, oder ihre CompositeSig-Signatur gilt für den öffentlichen Schlüssel des Jobs nicht. Eine Epoche ohne gültige COMMIT-Datei zählt nicht.

Er bleibt, weil er eine Abweisung eines Sperli-Jobs ist, das die Beispiele dieses Katalogs, die der Compiler übersetzt, nicht ausführen; die Tests in standard/src/SperliCkpt.test.hiq und test-programs/suites/100-sperli lösen ihn in den Gates aus.

### H1622

Meldung, aus dem Quelltext in `standard/src/SperliError.hiq`:

```text
no epoch can be resumed
```

Ein resume fand keine Epoche mit gültiger COMMIT-Datei und allen Rang-Dateien, oder die Ränge einigten sich nicht auf die Epoche.

Er bleibt, weil er eine Abweisung eines Sperli-Jobs ist, das die Beispiele dieses Katalogs, die der Compiler übersetzt, nicht ausführen; die Tests in standard/src/SperliCkpt.test.hiq und test-programs/suites/100-sperli lösen ihn in den Gates aus.

### H1623

Meldung, aus dem Quelltext in `standard/src/SperliError.hiq`:

```text
the job has another size than the checkpoint
```

Ein resume wurde für einen Job mit anderer Rangzahl verlangt, als der Checkpoint geschrieben wurde. Version 1 des Formats verlangt dieselbe Größe.

Er bleibt, weil er eine Abweisung eines Sperli-Jobs ist, das die Beispiele dieses Katalogs, die der Compiler übersetzt, nicht ausführen; die Tests in standard/src/SperliCkpt.test.hiq und test-programs/suites/100-sperli lösen ihn in den Gates aus.

### H1624

Meldung, aus dem Quelltext in `standard/src/SperliError.hiq`:

```text
a send or receive is still open
```

Ein Checkpoint wurde verlangt, während auf diesem Rang noch ein send oder receive offen war.

Er bleibt, weil er eine Abweisung eines Sperli-Jobs ist, das die Beispiele dieses Katalogs, die der Compiler übersetzt, nicht ausführen; die Tests in standard/src/SperliCkpt.test.hiq und test-programs/suites/100-sperli lösen ihn in den Gates aus.

### H1625

Meldung, aus dem Quelltext in `standard/src/SperliError.hiq`:

```text
the checkpoint could not be written or sent
```

Ein Checkpoint konnte nicht geschrieben oder gesendet werden, oder es wurde kein Checkpoint-Verzeichnis genannt.

Er bleibt, weil er eine Abweisung eines Sperli-Jobs ist, das die Beispiele dieses Katalogs, die der Compiler übersetzt, nicht ausführen; die Tests in standard/src/SperliCkpt.test.hiq und test-programs/suites/100-sperli lösen ihn in den Gates aus.
