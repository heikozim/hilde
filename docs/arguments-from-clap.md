# Standard.Arguments for those who know clap

This is a map from clap's builder API to `Standard.Arguments`, for an agent or a
person who has written command lines in Rust with clap and now writes them in Hilde.
It says what to call, where Hilde differs and why, what is not there and how to do
without, and it ends with three complete programmes, each one written twice.

"clap" here is clap 4 and its builder form (`Command`, `Arg`, `ArgAction`), the
form that `Standard.Arguments` follows; clap's derive form has no counterpart
(section 2).  The interface is `standard/src/Arguments.hih`.

What is checked and what is not.  The Hilde programmes of section 4 are the test
programmes `test-programs/suites/055-arguments/007-clap-simple`, `008-clap-subcommands`
and `009-clap-env-and-conflict`: the checks compile them, run them and compare what
they print with the output shown here, and `scripts/check-arguments-doc.py` holds this
file to those tests byte for byte.  The same script holds every function the tables
name to the interface.  The clap programmes are the files of `scripts/clap-compare/`,
which `cargo` builds with the versions of its `Cargo.lock`; the same script holds each
Rust fence to its file byte for byte, and this text to the version of clap that is
locked, clap 4.6.7.  The checks of the project have no Rust, so they do not
build them.  They were built and run by hand with rustc 1.85.1 and cargo
1.85.1, and section 4.4 says what came of it.

## 1. The calls

A command is declared by calls on a write reference, `&!c`, and every declaration of
an option gives back a key; the programme asks the matches with the key.  The names
and the help texts of a declaration are literals, `Span[Nat8, Static]`.  Declare,
parse, ask, destroy:

| Step | clap | Standard.Arguments |
|---|---|---|
| declare | `Command::new("tool")` and `.arg(...)` | `var c: Command := makeCommand("tool", "about")` and `addFlag(&!c, ...)` |
| parse | `get_matches()` | `parse(&c, &words)`, with the process's words from `processArguments()` |
| ask | `matches.get_one::<T>("id")` | `textOf(&m, key)` and the other getters below |
| destroy | dropped by Rust | `destroyMatches(m)`, `destroyCommand(c)`, `destroyArguments(words)` |

The declarations, one clap call to one Hilde call.  A short letter of 0 and a long
name of "" mean none.  The words of a choice are written joined by a bar, as in
"fast|safe|small".

| clap builder | Standard.Arguments | Note |
|---|---|---|
| `Command::new("tool")` with `.about("...")` | `makeCommand("tool", "...")` | name and one line of help in one call; the command is linear |
| `.version("1.0")` | `setVersion(&!c, "1.0")` | `-V` and `--version` come with it |
| `Arg::new("verbose").short('v').long("verbose").help("...")` | `addVerbose(&!c, "...")`, since -v and --verbose are reserved; `option("name", 'n', "...")` for others | a `Spec`, which the `add...` calls take |
| `.action(ArgAction::SetTrue)` | `addFlag(&!c, spec)` | ask with `flagCount(&m, key) > 0` |
| `.action(ArgAction::Count)` | `addFlag(&!c, repeatable(spec))` | `flagCount(&m, key)` is the count |
| `.action(ArgAction::Set)`, a text | `addText(&!c, spec, "")` | the last argument is the default, empty for none |
| `.action(ArgAction::Append)` | `addText(&!c, repeatable(spec), "")` | all values: `textCount(&m, key)`, `textAt(&m, key, i)` |
| `.value_parser(value_parser!(i64).range(1..=9))` | `addWhole(&!c, spec, 1, 9, "")` | an Int64 in a range; `wholeOf(&m, key)` |
| `.value_parser(BoolishValueParser::new())` | `addBool(&!c, spec, "")` | true, yes, on, 1, false, no, off, 0; `boolOf(&m, key)`; clap's `value_parser!(bool)` takes true and false only |
| `.value_parser(["fast", "safe"])` | `addChoice(&!c, spec, words, "")` | `choiceOf(&m, key)` gives the index of the word |
| `.value_parser(value_parser!(PathBuf))` | `addPath(&!c, spec)` | any bytes, not empty; `pathOf(&m, key)` |
| `.required(true)` | `required(spec)` | met by the environment too, when the option has one |
| `.default_value("6")` | the last argument of `addText`, `addWhole`, `addBool`, `addChoice` | the default as the user would type it |
| `.conflicts_with("b")` | `addConflict(&!c, anyFlag(a), anyFlag(b))` | `anyText`, `anyWhole`, `anyBool`, `anyChoice`, `anyPath` for the other kinds |
| `.requires("b")` | `addDependency(&!c, anyPath(a), anyChoice(b))` | `a` may only be given with `b` |
| `.env("TOOL_NAME")` | `fromEnvironment(spec, "TOOL_NAME")` | checked as if typed; a flag takes a Bool word |
| `.value_name("FILE")` | `valueName(spec, "file")` | shown in capitals in the help |
| a positional `Arg::new("file")` | `addPositional(&!c, "file", "help", isRequired, isRepeatable)` | `positionalOf`, or `positionalCount` and `positionalAt` |
| `.num_args(1..)` on a positional | `isRepeatable` true | only the last positional may be repeatable |
| a positional that is a path | `addPositionalPath(&!c, "file", "help", isRequired, isRepeatable)` | asked with `pathOf` |
| `.subcommand(sub)` | `addSubcommand(&!c, sub)` | `sub` is built apart, then moved in; the key is asked with `chosen(&m, key)` |
| `.subcommand_required(true)` | `requireSubcommand(&!c)` | |
| `.alias("a")` on a subcommand | `addAlias(&!sub, "a")` | before the subcommand is attached |
| `.global(true)` | `global(spec)` | accepted by every subcommand below |
| `get_one::<String>("id")` | `textOf(&m, key)` | an `Option` of a reference |
| `get_one::<i64>("id")` | `wholeOf(&m, key)` | `Option[Int64]` |
| `get_many::<String>("id")` | `textCount(&m, key)` and `textAt(&m, key, i)` | for paths `pathCount` and `pathAt` |
| `get_count("id")` | `flagCount(&m, key)` | |
| `get_flag("id")` | `flagCount(&m, key) > 0` | |
| `--help` printed and exit | `Help(text)` of the outcome, or `helpText(&c)` | the programme prints it and exits |
| the error printed and exit | `describeError(&c, &error)` | `errorKind(&error)`, `errorPosition(&error)`, then `destroyError(error)` |
| `clap_complete` | `completionScript(&c, Bash())` | `Zsh()` and `Fish()` too |
| `clap_mangen` | `manPage(&c, "October 7, 2026")` | a page in mdoc; the date is a parameter |
| the `argfile` crate | `expandArgumentFiles(&words)` | words that begin with `@` name files; call it before `parse` |

What `parse` gives back is `Either[ArgumentError, Outcome]`.  An `Outcome` is `Run`
with the matches, `Help` or `Version` with the text the user asked for.  The library
prints nothing and never ends the process.

## 2. Where Hilde differs, and why

- **A key, not a string id.**  `addFlag` gives a `FlagKey`, `addText` a `TextKey`,
  and so on; the programme asks with the key.  A name misspelt in the programme is a
  variable the compiler does not know (H6039), and a key asked as the wrong kind is
  refused (H3060): the mistake that clap can only find when the programme runs is
  found when it is compiled.  The price is that the keys have to be kept
  where the programme asks: a `record` of them, as in the examples.
- **A value, not an exit.**  `get_matches()` prints and ends the process on a
  mistake; `parse` gives back an `ArgumentError`, and the programme prints it and
  returns its own exit code.  `try_get_matches()` is the nearest in clap.  Nothing
  a user types stops the programme.
- **No derive.**  clap's derive form needs code generated from a type, which Hilde
  does not have.  The builder is the whole interface.
- **No prefix abbreviation.**  `--verb` does not mean `--verbose`; a prefix that is
  unique today is ambiguous when the next option is added.  A word nearly right gets
  a suggestion instead: `unknown option --nmae, did you mean --name?`  clap has the
  abbreviation only when asked (`infer_long_args`).
- **Defaults are text.**  `addWhole(..., 1, 5, "1")`, `addBool(..., "false")`,
  `addChoice(..., "json|text", "text")`: every kind takes its default as the user
  would type it, and it is checked by the code that checks a typed value.  There is
  no typed `default_value_t`.
- **Given twice is an error unless the declaration says it may be.**  A flag or an
  option given a second time is `Repeated`, as `Set` and `SetTrue` are in clap 4;
  `repeatable(spec)` is the one marker that makes a flag a counter and a text option
  a list, where clap has the actions `Count` and `Append`.
- **An option takes the next word, always.**  `--output -v` gives `-v` as the value,
  as getopt does; clap reads a word with a leading dash as an option unless
  `allow_hyphen_values` is set.
- **A Bool takes the longer list.**  `addBool` takes true, yes, on, 1 and false, no,
  off, 0, which is clap's `BoolishValueParser` less its single letters; clap's
  `value_parser!(bool)` takes `true` and `false` only.  A default for a Bool is
  one of those words as text.
- **Linear values.**  A `Command`, the `Matches`, the words and an `ArgumentError`
  are given back with the `destroy...` calls; Rust drops them.  The compiler
  refuses a programme that forgets one.
- **Names are ASCII, text is UTF-8.**  Option names, subcommand names and the words
  of a choice are ASCII; a text value that is not UTF-8 is an error (`InvalidUtf8`),
  and a path is taken as the bytes it is.
- **The words are an argument, not the process.**  `parse` reads nothing but the
  buffer it is given: `processArguments()` is the process's words without the
  programme's name, a test builds its own.
- **One integer type.**  `addWhole` is an `Int64` with a range; there is no `u8`, no
  float.  A range such as `0..=255` is the way to say it.

## 3. What is not there, and the way round

| clap | In Hilde | Way round |
|---|---|---|
| `#[derive(Parser)]` | not offered | declare the command by hand, as in section 4 |
| `ArgGroup`, one of several required | not offered | `addConflict` for each pair, and a check of `flagCount` or `textOf` after the parse |
| `num_args(2)` on an option, several values after one option | an option has one value | repeat the option (`repeatable`), or take one text and split it with `Standard.Text.split` |
| `value_delimiter(',')` | not offered | one text option, split with `Standard.Text.split` |
| a custom `value_parser` | five kinds of value | take the text and parse it after `parse`, with the functions of `Standard.Text` |
| floats and unsigned numbers | `Int64` only | take a text and parse it, or use `addWhole` with a range |
| `trailing_var_arg`, `last(true)` | a word `--` ends the options | the positional arguments after `--` are kept in order; the last positional may be repeatable |
| `--no-flag` negation, `overrides_with` | not offered | declare the second flag and `addConflict` between the two |
| `infer_subcommands`, `infer_long_args` | never | a suggestion for a word nearly right |
| `help_template`, `before_help`, `after_help`, colours | the help is written from the declarations | print the extra text before or after `helpText(&c)` |
| `value_hint`, dynamic completion | the scripts name options, subcommands and the words of a choice | none |
| `ArgMatches::value_source` | not offered | declare the option without a default and apply the default in the programme, then the case is known |
| `Command::print_help` and `render_usage` | `helpText(&c)` and `usageLine(&c)` give strings | print them |
| a value that is not UTF-8 as a `String` | an error for text | declare it with `addPath`, which takes the bytes |

## 4. Three programmes, each written twice

Each clap programme is the model; the Hilde programme under it is a test of the
suite `055-arguments`, run with the command lines it builds itself instead of the
process's, so that a run shows what every call does.  A programme of your own takes
`processArguments()` in place of the buffers of the example, and after `parse` and
`describeError` it returns `ExitSuccess()` or an exit code of its own.  What the
Hilde programme prints is shown under it: the words of the errors and of the help
are Hilde's, clap words them differently.

### 4.1 A command with a default, a range and a flag

The clap programme (`Cargo.toml` needs `clap` 4):

```rust greet
use clap::builder::BoolishValueParser;
use clap::{value_parser, Arg, ArgAction, Command};

fn main() {
    let matches = Command::new("greet")
        .about("Prints a greeting.")
        .version("1.0")
        .arg(
            Arg::new("name")
                .short('n')
                .long("name")
                .value_name("NAME")
                .help("Who to greet")
                .default_value("world"),
        )
        .arg(
            Arg::new("times")
                .short('t')
                .long("times")
                .help("How often")
                .value_parser(value_parser!(i64).range(1..=5))
                .default_value("1"),
        )
        .arg(
            Arg::new("polite")
                .long("polite")
                .help("Say please")
                .value_parser(BoolishValueParser::new())
                .default_value("false"),
        )
        .arg(
            Arg::new("loud")
                .short('l')
                .long("loud")
                .help("Shout")
                .action(ArgAction::SetTrue),
        )
        .get_matches();

    let name = matches.get_one::<String>("name").unwrap();
    let times = matches.get_one::<i64>("times").unwrap();
    let end = if matches.get_flag("loud") { "!" } else { "." };
    println!("Hello, {name}{end}");
    println!("times: {times}");
    println!("polite: {}", matches.get_one::<bool>("polite").unwrap());
}
```

The Hilde programme, `test-programs/suites/055-arguments/007-clap-simple/Test.hiq`:

```hilde 055-arguments/007-clap-simple
import Standard.Buffer (
    Buffer,
    allocateEmpty,
    insertBack
);
import Standard.String (
    String,
    fromLiteral,
    destroyString,
    asSpan
);
import Standard.Arguments (
    Command,
    FlagKey,
    TextKey,
    WholeKey,
    BoolKey,
    ArgumentError,
    Outcome,
    Run,
    Help,
    Version,
    Matches,
    makeCommand,
    destroyCommand,
    setVersion,
    option,
    valueName,
    addFlag,
    addText,
    addWhole,
    addBool,
    destroyArguments,
    parse,
    destroyMatches,
    describeError,
    destroyError,
    flagCount,
    textOf,
    wholeOf,
    boolOf
);

module body Test is
    -- The keys are what clap's string ids are: what the programme asks the
    -- matches with.
    record Keys: Free is
        name: TextKey;
        times: WholeKey;
        polite: BoolKey;
        loud: FlagKey;
    end;

    -- What the programme does with the matches: the greeting, times over.
    generic [R: Region]
    function greet(m: &[Matches, R], keys: Keys): Unit is
        case textOf(m, keys.name) of
            when Some(value as given: &[String, R]) do
                print("Hello, ");
                print(asSpan(given));
                if flagCount(m, keys.loud) > 0 then
                    print("!");
                else
                    print(".");
                end if;
                print("\n");
            when None do
                printLn("Hello, nobody.");
        end case;
        case wholeOf(m, keys.times) of
            when Some(value as times: Int64) do
                print("times: ");
                printLn(times);
            when None do
                printLn("times: none");
        end case;
        case boolOf(m, keys.polite) of
            when Some(value as polite: Bool) do
                print("polite: ");
                printLn(polite);
            when None do
                printLn("polite: none");
        end case;
        return nil;
    end;

    -- One command line: parsed, then the greeting, or the help, the version
    -- or the error as the user is to read it.
    generic [R: Region]
    function run(c: &[Command, R], keys: Keys, words: Buffer[String]): Unit is
        case parse(c, &words) of
            when Right(right as outcome: Outcome) do
                case outcome of
                    when Run(matches as m: Matches) do
                        greet(&m, keys);
                        destroyMatches(m);
                    when Help(text as t: String) do
                        print(asSpan(&t));
                        destroyString(t);
                    when Version(text as t: String) do
                        print(asSpan(&t));
                        destroyString(t);
                end case;
            when Left(left as e: ArgumentError) do
                let message: String := describeError(c, &e);
                print(asSpan(&message));
                destroyString(message);
                destroyError(e);
        end case;
        destroyArguments(words);
        return nil;
    end;

    -- A command line is a buffer of words, built a word at a time.
    function noWords(): Buffer[String] is
        return allocateEmpty();
    end;

    function plus(line: Buffer[String], word: Span[Nat8, Static]): Buffer[String] is
        var out: Buffer[String] := line;
        insertBack(&!out, fromLiteral(word));
        return out;
    end;

    function main(): ExitCode is
        -- Command::new("greet").about(..).version(..)
        var c: Command := makeCommand("greet", "Prints a greeting.");
        setVersion(&!c, "1.0");
        -- Arg::new with the name name, short n, a value_name and a default_value
        let name: TextKey := addText(&!c, valueName(option("name", 'n', "Who to greet"), "NAME"), "world");
        -- Arg::new("times").value_parser(value_parser!(i64).range(1..=5)).default_value("1")
        let times: WholeKey := addWhole(&!c, option("times", 't', "How often"), 1, 5, "1");
        -- Arg::new("polite").value_parser(BoolishValueParser::new()).default_value("false")
        let polite: BoolKey := addBool(&!c, option("polite", 0, "Say please"), "false");
        -- Arg::new("loud").action(ArgAction::SetTrue)
        let loud: FlagKey := addFlag(&!c, option("loud", 'l', "Shout"));
        let keys: Keys := Keys(name => name, times => times, polite => polite, loud => loud);
        printLn("the defaults:");
        run(&c, keys, noWords());
        printLn("a name, a count and a flag:");
        run(&c, keys, plus(plus(plus(plus(plus(noWords(), "-n"), "Ann"), "--times=2"), "--polite=yes"), "--loud"));
        printLn("a count out of its range:");
        run(&c, keys, plus(plus(noWords(), "--times"), "9"));
        printLn("a Bool that is not one:");
        run(&c, keys, plus(noWords(), "--polite=maybe"));
        printLn("a name nearly right:");
        run(&c, keys, plus(plus(noWords(), "--nmae"), "Ann"));
        printLn("the version:");
        run(&c, keys, plus(noWords(), "--version"));
        printLn("the help:");
        run(&c, keys, plus(noWords(), "-h"));
        destroyCommand(c);
        return ExitSuccess();
    end;
end module body.
```

What it prints:

```text 055-arguments/007-clap-simple
the defaults:
Hello, world.
times: 1
polite: false
a name, a count and a flag:
Hello, Ann!
times: 2
polite: true
a count out of its range:
greet: 9 is out of range for --times, which takes 1 to 5
Usage: greet [OPTIONS]
Try greet --help for more information.
a Bool that is not one:
greet: maybe is not allowed for --polite, which takes true, false, yes, no, on, off, 1 or 0
Usage: greet [OPTIONS]
Try greet --help for more information.
a name nearly right:
greet: unknown option --nmae, did you mean --name?
Usage: greet [OPTIONS]
Try greet --help for more information.
the version:
greet 1.0
the help:
Prints a greeting.

Usage: greet [OPTIONS]

Options:
  -n, --name <NAME>      Who to greet [default: world]
  -t, --times <TIMES>    How often [range: 1 to 5] [default: 1]
      --polite <POLITE>  Say please [default: false]
  -l, --loud             Shout
  -h, --help             Print help
  -V, --version          Print version
```

### 4.2 Subcommands, an alias, a global counter

The clap programme:

```rust pack
use clap::{Arg, ArgAction, Command};

fn main() {
    let matches = Command::new("pack")
        .about("A small archive tool.")
        .version("0.2")
        .subcommand_required(true)
        .arg(
            Arg::new("verbose")
                .short('v')
                .long("verbose")
                .help("More output")
                .action(ArgAction::Count)
                .global(true),
        )
        .subcommand(
            Command::new("add")
                .about("Add files.")
                .alias("a")
                .arg(
                    Arg::new("force")
                        .short('f')
                        .long("force")
                        .help("Overwrite what is there")
                        .action(ArgAction::SetTrue),
                )
                .arg(
                    Arg::new("file")
                        .help("Files to add")
                        .required(true)
                        .num_args(1..),
                ),
        )
        .subcommand(
            Command::new("list").about("List the archive.").arg(
                Arg::new("long")
                    .short('l')
                    .long("long")
                    .help("One line each")
                    .action(ArgAction::SetTrue),
            ),
        )
        .get_matches();

    match matches.subcommand() {
        Some(("add", sub)) => {
            println!("verbose: {}", sub.get_count("verbose"));
            println!("add, force: {}", sub.get_flag("force") as u8);
            for file in sub.get_many::<String>("file").unwrap() {
                println!("  file: {file}");
            }
        }
        Some(("list", sub)) => {
            println!("verbose: {}", sub.get_count("verbose"));
            println!("list, long: {}", sub.get_flag("long") as u8);
        }
        _ => unreachable!(),
    }
}
```

The Hilde programme, `test-programs/suites/055-arguments/008-clap-subcommands/Test.hiq`.
The counter is declared on the command and asked there: it counts wherever on the
line it was given.

```hilde 055-arguments/008-clap-subcommands
import Standard.Buffer (
    Buffer,
    allocateEmpty,
    insertBack
);
import Standard.String (
    String,
    fromLiteral,
    destroyString,
    asSpan
);
import Standard.Arguments (
    Command,
    FlagKey,
    PositionalKey,
    SubcommandKey,
    ArgumentError,
    Outcome,
    Run,
    Help,
    Version,
    Matches,
    makeCommand,
    destroyCommand,
    setVersion,
    addAlias,
    option,
    repeatable,
    global,
    addFlag,
    addPositional,
    addSubcommand,
    requireSubcommand,
    destroyArguments,
    parse,
    destroyMatches,
    describeError,
    destroyError,
    flagCount,
    positionalCount,
    positionalAt,
    chosen,
    addVerbose
);

module body Test is
    record Keys: Free is
        verbose: FlagKey;
        add: SubcommandKey;
        force: FlagKey;
        files: PositionalKey;
        list: SubcommandKey;
        oneLine: FlagKey;
    end;

    -- What the programme does with the matches: match on the subcommand, as
    -- clap's matches.subcommand() is matched.
    generic [R: Region]
    function act(m: &[Matches, R], keys: Keys): Unit is
        print("verbose: ");
        printLn(flagCount(m, keys.verbose));
        if chosen(m, keys.add) then
            print("add, force: ");
            printLn(flagCount(m, keys.force));
            let count: Index := positionalCount(m, keys.files);
            var i: Index := 0;
            while i < count do
                case positionalAt(m, keys.files, i) of
                    when Some(value as file: &[String, R]) do
                        print("  file: ");
                        printLn(asSpan(file));
                    when None do
                        skip;
                end case;
                i := i + 1;
            end while;
        else if chosen(m, keys.list) then
            print("list, long: ");
            printLn(flagCount(m, keys.oneLine));
        end if;
        return nil;
    end;

    generic [R: Region]
    function run(c: &[Command, R], keys: Keys, words: Buffer[String]): Unit is
        case parse(c, &words) of
            when Right(right as outcome: Outcome) do
                case outcome of
                    when Run(matches as m: Matches) do
                        act(&m, keys);
                        destroyMatches(m);
                    when Help(text as t: String) do
                        print(asSpan(&t));
                        destroyString(t);
                    when Version(text as t: String) do
                        print(asSpan(&t));
                        destroyString(t);
                end case;
            when Left(left as e: ArgumentError) do
                let message: String := describeError(c, &e);
                print(asSpan(&message));
                destroyString(message);
                destroyError(e);
        end case;
        destroyArguments(words);
        return nil;
    end;

    -- A command line is a buffer of words, built a word at a time.
    function noWords(): Buffer[String] is
        return allocateEmpty();
    end;

    function plus(line: Buffer[String], word: Span[Nat8, Static]): Buffer[String] is
        var out: Buffer[String] := line;
        insertBack(&!out, fromLiteral(word));
        return out;
    end;

    function main(): ExitCode is
        -- Command::new("pack").subcommand_required(true)
        var c: Command := makeCommand("pack", "A small archive tool.");
        setVersion(&!c, "0.2");
        requireSubcommand(&!c);
        -- Arg::new with the name verbose, short v, the action Count and global
        let verbose: FlagKey := addVerbose(&!c, "More output");
        -- Command::new("add").alias("a"), built apart and attached
        var add: Command := makeCommand("add", "Add files.");
        addAlias(&!add, "a");
        let force: FlagKey := addFlag(&!add, option("force", 'f', "Overwrite what is there"));
        -- Arg::new("files").required(true).num_args(1..)
        let files: PositionalKey := addPositional(&!add, "file", "Files to add", true, true);
        let addKey: SubcommandKey := addSubcommand(&!c, add);
        var list: Command := makeCommand("list", "List the archive.");
        let oneLine: FlagKey := addFlag(&!list, option("long", 'l', "One line each"));
        let listKey: SubcommandKey := addSubcommand(&!c, list);
        let keys: Keys := Keys(verbose => verbose, add => addKey, force => force, files => files, list => listKey, oneLine => oneLine);
        printLn("add, with a flag and two files:");
        run(&c, keys, plus(plus(plus(plus(noWords(), "add"), "-f"), "a.txt"), "b.txt"));
        printLn("the alias, and a global flag before the subcommand:");
        run(&c, keys, plus(plus(plus(noWords(), "-vv"), "a"), "x.txt"));
        printLn("a global flag after the subcommand:");
        run(&c, keys, plus(plus(plus(noWords(), "list"), "-v"), "--long"));
        printLn("no subcommand:");
        run(&c, keys, noWords());
        printLn("add without a file:");
        run(&c, keys, plus(plus(noWords(), "add"), "-f"));
        printLn("a subcommand nearly right:");
        run(&c, keys, plus(noWords(), "lst"));
        printLn("the help of a subcommand:");
        run(&c, keys, plus(plus(noWords(), "help"), "add"));
        destroyCommand(c);
        return ExitSuccess();
    end;
end module body.
```

What it prints:

```text 055-arguments/008-clap-subcommands
add, with a flag and two files:
verbose: 0
add, force: 1
  file: a.txt
  file: b.txt
the alias, and a global flag before the subcommand:
verbose: 2
add, force: 0
  file: x.txt
a global flag after the subcommand:
verbose: 1
list, long: 1
no subcommand:
pack: a subcommand is required
Usage: pack [OPTIONS] <COMMAND>
Try pack --help for more information.
add without a file:
pack: <FILE> is required
Usage: pack add [OPTIONS] <FILE>...
Try pack add --help for more information.
a subcommand nearly right:
pack: unknown subcommand lst, did you mean list?
Usage: pack [OPTIONS] <COMMAND>
Try pack --help for more information.
the help of a subcommand:
Add files.

Usage: pack add [OPTIONS] <FILE>...

Arguments:
  <FILE>...  Files to add

Options:
  -v, --verbose  More output [repeatable]
  -f, --force    Overwrite what is there
  -h, --help     Print help
  -V, --version  Print version
```

### 4.3 The environment, a conflict, a dependency

The clap programme (the `env` feature of clap is needed for `.env`):

```rust convert
use clap::{value_parser, Arg, ArgAction, Command};
use std::path::PathBuf;

fn main() {
    let matches = Command::new("convert")
        .about("Converts a file.")
        .arg(
            Arg::new("format")
                .short('f')
                .long("format")
                .help("Output format")
                .value_parser(["json", "text"])
                .env("CONVERT_FORMAT"),
        )
        .arg(
            Arg::new("jobs")
                .short('j')
                .long("jobs")
                .help("Parallel jobs")
                .value_parser(value_parser!(i64).range(1..=64))
                .env("CONVERT_JOBS")
                .default_value("1"),
        )
        .arg(
            Arg::new("quiet")
                .short('q')
                .long("quiet")
                .help("Print nothing")
                .action(ArgAction::SetTrue)
                .conflicts_with("verbose"),
        )
        .arg(
            Arg::new("verbose")
                .short('v')
                .long("verbose")
                .help("Print more")
                .action(ArgAction::SetTrue),
        )
        .arg(
            Arg::new("output")
                .short('o')
                .long("output")
                .help("Where to write")
                .value_parser(value_parser!(PathBuf))
                .requires("format"),
        )
        .arg(
            Arg::new("exclude")
                .short('x')
                .long("exclude")
                .help("Skip a name")
                .action(ArgAction::Append),
        )
        .arg(
            Arg::new("input")
                .help("The file to convert")
                .required(true)
                .value_parser(value_parser!(PathBuf)),
        )
        .get_matches();

    println!("input: {}", matches.get_one::<PathBuf>("input").unwrap().display());
    match matches.get_one::<String>("format") {
        Some(format) => println!("format: {format}"),
        None => println!("format: none"),
    }
    println!("jobs: {}", matches.get_one::<i64>("jobs").unwrap());
    match matches.get_one::<PathBuf>("output") {
        Some(output) => println!("output: {}", output.display()),
        None => println!("output: none"),
    }
    let skipped: Vec<&String> = matches
        .get_many::<String>("exclude")
        .map(|names| names.collect())
        .unwrap_or_default();
    println!("exclude: {}", skipped.len());
    for name in skipped {
        println!("  skip: {name}");
    }
    println!(
        "quiet: {}, verbose: {}",
        matches.get_flag("quiet") as u8,
        matches.get_flag("verbose") as u8
    );
}
```

The Hilde programme, `test-programs/suites/055-arguments/009-clap-env-and-conflict/Test.hiq`,
run with `CONVERT_JOBS=4` in its environment (the file `env.txt` of the test).  The
dependency is the second line the declaration needs after the options: a conflict and
a dependency are declared on the command, between keys.

```hilde 055-arguments/009-clap-env-and-conflict
import Standard.Buffer (
    Buffer,
    allocateEmpty,
    insertBack
);
import Standard.String (
    String,
    fromLiteral,
    destroyString,
    asSpan
);
import Standard.Arguments (
    Command,
    FlagKey,
    TextKey,
    WholeKey,
    ChoiceKey,
    PathKey,
    ArgumentError,
    Outcome,
    Run,
    Help,
    Version,
    Matches,
    makeCommand,
    destroyCommand,
    option,
    repeatable,
    fromEnvironment,
    addFlag,
    addText,
    addWhole,
    addChoice,
    addPath,
    addPositionalPath,
    anyFlag,
    anyPath,
    anyChoice,
    addConflict,
    addDependency,
    destroyArguments,
    parse,
    destroyMatches,
    describeError,
    destroyError,
    flagCount,
    textCount,
    textAt,
    wholeOf,
    choiceOf,
    pathOf,
    addVerbose
);

module body Test is
    record Keys: Free is
        format: ChoiceKey;
        jobs: WholeKey;
        quiet: FlagKey;
        verbose: FlagKey;
        output: PathKey;
        exclude: TextKey;
        input: PathKey;
    end;

    -- What the programme does with the matches.
    generic [R: Region]
    function convert(m: &[Matches, R], keys: Keys): Unit is
        case pathOf(m, keys.input) of
            when Some(value as file: &[String, R]) do
                print("input: ");
                printLn(asSpan(file));
            when None do
                printLn("input: none");
        end case;
        case choiceOf(m, keys.format) of
            when Some(value as which: Index) do
                if which = 0 then
                    printLn("format: json");
                else
                    printLn("format: text");
                end if;
            when None do
                printLn("format: none");
        end case;
        case wholeOf(m, keys.jobs) of
            when Some(value as jobs: Int64) do
                print("jobs: ");
                printLn(jobs);
            when None do
                printLn("jobs: none");
        end case;
        case pathOf(m, keys.output) of
            when Some(value as file: &[String, R]) do
                print("output: ");
                printLn(asSpan(file));
            when None do
                printLn("output: none");
        end case;
        let skipped: Index := textCount(m, keys.exclude);
        print("exclude: ");
        printLn(skipped);
        var i: Index := 0;
        while i < skipped do
            case textAt(m, keys.exclude, i) of
                when Some(value as name: &[String, R]) do
                    print("  skip: ");
                    printLn(asSpan(name));
                when None do
                    skip;
            end case;
            i := i + 1;
        end while;
        print("quiet: ");
        print(flagCount(m, keys.quiet));
        print(", verbose: ");
        printLn(flagCount(m, keys.verbose));
        return nil;
    end;

    generic [R: Region]
    function run(c: &[Command, R], keys: Keys, words: Buffer[String]): Unit is
        case parse(c, &words) of
            when Right(right as outcome: Outcome) do
                case outcome of
                    when Run(matches as m: Matches) do
                        convert(&m, keys);
                        destroyMatches(m);
                    when Help(text as t: String) do
                        print(asSpan(&t));
                        destroyString(t);
                    when Version(text as t: String) do
                        print(asSpan(&t));
                        destroyString(t);
                end case;
            when Left(left as e: ArgumentError) do
                let message: String := describeError(c, &e);
                print(asSpan(&message));
                destroyString(message);
                destroyError(e);
        end case;
        destroyArguments(words);
        return nil;
    end;

    -- A command line is a buffer of words, built a word at a time.
    function noWords(): Buffer[String] is
        return allocateEmpty();
    end;

    function plus(line: Buffer[String], word: Span[Nat8, Static]): Buffer[String] is
        var out: Buffer[String] := line;
        insertBack(&!out, fromLiteral(word));
        return out;
    end;

    function main(): ExitCode is
        var c: Command := makeCommand("convert", "Converts a file.");
        -- Arg::new("format").value_parser(["json", "text"]).env("CONVERT_FORMAT")
        let format: ChoiceKey := addChoice(&!c, fromEnvironment(option("format", 'f', "Output format"), "CONVERT_FORMAT"), "json|text", "");
        -- Arg::new("jobs").value_parser(value_parser!(i64).range(1..=64)).env("CONVERT_JOBS").default_value("1")
        let jobs: WholeKey := addWhole(&!c, fromEnvironment(option("jobs", 'j', "Parallel jobs"), "CONVERT_JOBS"), 1, 64, "1");
        let quiet: FlagKey := addFlag(&!c, option("quiet", 'q', "Print nothing"));
        let verbose: FlagKey := addVerbose(&!c, "Print more");
        -- Arg::new("output").value_parser(value_parser!(PathBuf)).requires("format")
        let output: PathKey := addPath(&!c, option("output", 'o', "Where to write"));
        -- Arg::new("exclude").action(ArgAction::Append)
        let exclude: TextKey := addText(&!c, repeatable(option("exclude", 'x', "Skip a name")), "");
        -- Arg::new("input").required(true), a positional argument that is a path
        let input: PathKey := addPositionalPath(&!c, "input", "The file to convert", true, false);
        -- Arg::new("quiet").conflicts_with("verbose")
        addConflict(&!c, anyFlag(quiet), anyFlag(verbose));
        addDependency(&!c, anyPath(output), anyChoice(format));
        let keys: Keys := Keys(format => format, jobs => jobs, quiet => quiet, verbose => verbose, output => output, exclude => exclude, input => input);
        printLn("the file alone, the jobs from the environment:");
        run(&c, keys, plus(noWords(), "in.txt"));
        printLn("everything on the line, which wins over the environment:");
        run(&c, keys, plus(plus(plus(plus(plus(plus(plus(plus(plus(noWords(), "-f"), "json"), "-j8"), "-o"), "out.json"), "-x"), "a.tmp"), "--exclude=b.tmp"), "in.txt"));
        printLn("an output without a format:");
        run(&c, keys, plus(plus(plus(noWords(), "-o"), "out.json"), "in.txt"));
        printLn("two flags that exclude each other:");
        run(&c, keys, plus(plus(plus(noWords(), "-q"), "-v"), "in.txt"));
        printLn("jobs out of the range:");
        run(&c, keys, plus(plus(plus(noWords(), "-j"), "99"), "in.txt"));
        printLn("a format that is not one:");
        run(&c, keys, plus(plus(plus(noWords(), "-f"), "xml"), "in.txt"));
        printLn("no input:");
        run(&c, keys, plus(noWords(), "-v"));
        destroyCommand(c);
        return ExitSuccess();
    end;
end module body.
```

What it prints:

```text 055-arguments/009-clap-env-and-conflict
the file alone, the jobs from the environment:
input: in.txt
format: none
jobs: 4
output: none
exclude: 0
quiet: 0, verbose: 0
everything on the line, which wins over the environment:
input: in.txt
format: json
jobs: 8
output: out.json
exclude: 2
  skip: a.tmp
  skip: b.tmp
quiet: 0, verbose: 0
an output without a format:
convert: --output needs --format
Usage: convert [OPTIONS] <INPUT>
Try convert --help for more information.
two flags that exclude each other:
convert: --quiet cannot be given together with --verbose
Usage: convert [OPTIONS] <INPUT>
Try convert --help for more information.
jobs out of the range:
convert: 99 is out of range for --jobs, which takes 1 to 64
Usage: convert [OPTIONS] <INPUT>
Try convert --help for more information.
a format that is not one:
convert: xml is not allowed for --format, which takes json, text
Usage: convert [OPTIONS] <INPUT>
Try convert --help for more information.
no input:
convert: <INPUT> is required
Usage: convert [OPTIONS] <INPUT>
Try convert --help for more information.
```

### 4.4 What clap printed for the same command lines

`python3 scripts/clap-compare/compare.py <directory of the binaries>` runs every command
line that the three Hilde programmes run against the clap programme it models, with
`CONVERT_JOBS=4` in the environment for `convert` as `env.txt` has it, and compares with
the `program-stdout.txt` shown above.  Run on an aarch64 Linux host
with rustc 1.85.1, cargo 1.85.1 and clap 4.6.7, which declares `rust-version` 1.85, the
packages of `Cargo.lock` resolved for that compiler:

```text
clap-compare scenarios=21 same=8 both-refuse=11 differs=2 bad=0
```

- **same, 8:** every command line that is accepted and prints a result gives the same
  bytes in clap and in Hilde: for `greet` the defaults, a name with a count and a flag,
  and the version; for `pack` `add` with a flag and two files, the alias with a global
  counter before the subcommand, and the counter after it; for `convert` the
  environment alone and the line that wins over the environment.
- **both refuse, 11:** every command line that Hilde refuses, clap refuses with exit
  code 2: for `greet` a count out of its range, a Bool that is not one and a misspelt
  option; for `pack` no subcommand, `add` without a file and a misspelt subcommand; for
  `convert` an output without a format, two flags that exclude each other, jobs out of
  the range, a format that is not one, and no input.  The words differ, as said above;
  clap names a similar option or subcommand (`tip: a similar argument exists:
  '--name'`) where Hilde says "did you mean".
- **differs, 2:** the help of `greet` and the help of `pack add`.  The differences, all
  in the help and none in what a line gives:

| In the help | Hilde | clap 4.6.7 |
|---|---|---|
| the placeholder of a value | the name in capitals, `<TIMES>`, `<FILE>...` | the name as written, `<times>`, `<file>...`, unless `value_name("NAME")` is given |
| a range | `[range: 1 to 5]` after the text | nothing |
| a Bool that is parsed by `BoolishValueParser` | nothing | `[possible values: true, false]` |
| a counter | `-v, --verbose  More output [repeatable]` | `-v, --verbose...  More output` |
| the order of the options of a subcommand | the global counter first | the subcommand's own options first |
| the help of a subcommand | has `-V, --version` | has none (the programme does not call `propagate_version`) |

The tool checks itself: `--self-test` puts a wrong expectation into a run scenario and
makes a refused line a valid one, and ends 1 unless both are seen (`self-test-cases=2
self-test-wrong=0`).

## 5. Where to look next

- `standard/src/Arguments.hih`: every call above, with what it does.
- `standard/src/Arguments.test.hiq`: the tests of parsing, errors, help, the manual
  page and the completion scripts, and of argument files.
- `examples/learn-arguments`: a longer programme with subcommands, a global counter,
  a range and a choice.
