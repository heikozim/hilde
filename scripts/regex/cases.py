#!/usr/bin/env python3
# The differential cases of Standard.Regex.
#
# One table, two consumers.  `python3 scripts/regex/cases.py` writes
#
#   test-programs/suites/043-regex/001-against-go/Test.hiq
#       -- the cases as a Hilde programme that prints what Standard.Regex
#          finds, and
#   scripts/regex/cases.json
#       -- the same cases for scripts/regex/oracle.go, which prints what
#          Go's regexp finds, in the same format, and
#   test-programs/suites/043-regex/002-deviations/Test.hiq and
#   scripts/regex/deviations.json
#       -- the table DEVIATIONS: what Standard.Regex does differently from
#          RE2 on purpose, and the messages of the patterns it refuses, and
#   test-programs/suites/043-regex/004-messages/Test.hiq and
#   scripts/regex/messages.json
#       -- every pattern of CASES, DEVIATIONS and EDGES, and whether
#          Standard.Regex's compile takes it or with which message.  The
#          compiler's check of literal patterns (lib/RegexCheck.ml) is
#          compared with that output by test/RegexCheckTest.ml.
#
# The expected output of the test is the ORACLE's output, not Hilde's:
#
#   go run scripts/regex/oracle.go scripts/regex/cases.json \
#       > test-programs/suites/043-regex/001-against-go/program-stdout.txt
#
# Go's regexp is the reference because it implements RE2's syntax and
# RE2's leftmost-first semantics, which is what Standard.Regex promises.
# Only its behaviour is used: its sources were not read for the engine.
#
# A case is (pattern, subject, rewrite).  Everything in CASES must behave
# the same in both engines.  What Standard.Regex does differently on purpose
# -- \C, the PCRE syntax, its own messages -- is in DEVIATIONS: the deviations
# test prints Standard.Regex's result and message for each, its expected
# output is that
# output as reviewed, and what Go does instead is what the oracle prints
# when it is run on deviations.json.
import json
import os

CASES = [
    # literals and concatenation
    ("abc", "xxabcxx", "<\\0>"),
    ("abc", "ab", "-"),
    ("", "abc", "."),
    ("a", "", "-"),
    ("", "", "."),
    ("h\u00e9llo", "oh h\u00e9llo", "[\\0]"),
    ("\u263a", "a\u263ab\u263a", "*"),
    # dot
    ("a.c", "abc a\u00e9c a\nc", "(\\0)"),
    ("(?s)a.c", "a\nc", "(\\0)"),
    (".", "\u00e9", "<\\0>"),
    ("...", "a\u263ab", "<\\0>"),
    # alternation and leftmost-first
    ("a|ab", "ab", "<\\0>"),
    ("ab|a", "ab", "<\\0>"),
    ("(a|ab)(c|bcd)(d*)", "abcd", "\\1/\\2/\\3"),
    ("x*|b", "b", "<\\0>"),
    ("cat|dog|bird", "hotdog bird cat", "[\\0]"),
    # repetition, greedy and lazy
    ("a*", "baaac", "<\\0>"),
    ("a+", "baaac aa", "<\\0>"),
    ("a?", "baa", "<\\0>"),
    ("a*?", "aaa", "<\\0>"),
    ("a+?", "aaa", "<\\0>"),
    ("a??b", "ab b", "<\\0>"),
    ("<.*>", "<a><b>", "{\\0}"),
    ("<.*?>", "<a><b>", "{\\0}"),
    ("(?U)<.*>", "<a><b>", "{\\0}"),
    ("(?U)<.*?>", "<a><b>", "{\\0}"),
    ("a{2}", "aaaaa", "<\\0>"),
    ("a{2,}", "aaaaa a", "<\\0>"),
    ("a{2,3}", "aaaaaaa", "<\\0>"),
    ("a{2,3}?", "aaaa", "<\\0>"),
    ("a{0}b", "ab", "<\\0>"),
    ("a{,2}", "a{,2}", "<\\0>"),
    ("x{1001}", "x", "-"),
    ("(ab){2}", "abababab", "<\\1>"),
    ("(a*)*", "b", "<\\0|\\1>"),
    ("(a*)+", "b", "<\\0|\\1>"),
    ("(a|b)*", "abba", "<\\1>"),
    ("(a+|b+)*c", "aabbc", "\\1"),
    # groups
    ("(a)(b)(c)", "abc", "\\3\\2\\1"),
    ("(?:ab)+", "ababx", "<\\0>"),
    ("(?P<word>\\w+)", "hi there", "[\\1]"),
    ("(?<word>\\w+)", "hi there", "[\\1]"),
    ("(a)|(b)", "b", "\\1-\\2"),
    ("((a)|(b))+", "ab", "\\1 \\2 \\3"),
    ("()", "ab", "|"),
    ("(a)(?:b)(c)", "abc", "\\2\\1"),
    # anchors
    ("^abc$", "abc", "ok"),
    ("^abc$", "abc\n", "ok"),
    ("^", "ab\ncd", "^"),
    ("$", "ab\ncd", "$"),
    ("(?m)^", "ab\ncd\n", "^"),
    ("(?m)$", "ab\ncd\n", "$"),
    ("(?m)^c", "ab\ncd", "C"),
    ("\\Aab", "abab", "X"),
    ("ab\\z", "abab", "X"),
    ("(?m)\\Aab", "x\nab", "X"),
    ("a$", "ba\n", "X"),
    ("(?m)a$", "ba\n", "X"),
    # word boundaries
    ("\\bfoo\\b", "foo foobar barfoo foo", "F"),
    ("\\Boo\\B", "foo boot", "O"),
    ("\\b", "ab cd", "|"),
    ("\\B", "ab cd", "|"),
    ("\\b\u00e9", "\u00e9t\u00e9", "E"),
    # classes
    ("[abc]+", "xxcabxx", "<\\0>"),
    ("[^abc]+", "abxyzc", "<\\0>"),
    ("[a-z]+", "ABcdEF", "<\\0>"),
    ("[a-]+", "a-b", "<\\0>"),
    ("[]a]+", "]a]b", "<\\0>"),
    ("[^]a]+", "]a]bc", "<\\0>"),
    ("[\\]]", "a]b", "<\\0>"),
    ("[\\d]+", "ab123", "<\\0>"),
    ("[\\D]+", "12ab3", "<\\0>"),
    ("[^\\s]+", " a b ", "<\\0>"),
    ("[[:alpha:]]+", "12abc34", "<\\0>"),
    ("[[:^alpha:]]+", "ab12cd", "<\\0>"),
    ("[[:digit:][:upper:]]+", "abC12d", "<\\0>"),
    ("[[:word:]]+", "a_b-c", "<\\0>"),
    ("[[:punct:]]+", "ab!?c", "<\\0>"),
    ("[\u00e0-\u00ff]+", "a\u00e9\u00e8b", "<\\0>"),
    ("[^a]", "\u00e9", "<\\0>"),
    ("[\\x{263a}-\\x{263c}]", "x\u263bx", "<\\0>"),
    ("[z-a]", "a", "-"),
    ("[a", "a", "-"),
    ("[[:foo:]]", "a", "-"),
    # perl classes
    ("\\d+", "ab 123 45", "<\\0>"),
    ("\\D+", "12ab34", "<\\0>"),
    ("\\w+", "  foo_bar9 ", "<\\0>"),
    ("\\W+", "ab, cd", "<\\0>"),
    ("\\s+", "a \t\n b", "<\\0>"),
    ("\\S+", "  ab  ", "<\\0>"),
    ("\\w", "\u00e9", "<\\0>"),
    # escapes
    ("\\x41", "zAz", "<\\0>"),
    ("\\x{263a}", "a\u263a", "<\\0>"),
    ("\\x{10FFFF}", "a", "-"),
    ("\\x{110000}", "a", "-"),
    ("\\101", "zAz", "<\\0>"),
    ("\\t\\n", "a\t\nb", "<\\0>"),
    ("\\.\\*\\+\\?", "a.*+?", "<\\0>"),
    ("\\Qa.b*\\E", "xa.b*y", "<\\0>"),
    ("\\Qa.b", "a.b", "<\\0>"),
    ("a\\-b", "a-b", "<\\0>"),
    ("\\q", "q", "-"),
    ("\\8", "8", "-"),
    # flags
    ("(?i)abc", "xABcx", "<\\0>"),
    ("(?i:ab)c", "ABc ABC", "<\\0>"),
    ("a(?i)b", "aB AB", "<\\0>"),
    ("(?i)[a-c]+", "xAbCx", "<\\0>"),
    ("(?i)[^a]", "A", "<\\0>"),
    ("(?i-i)a", "A", "<\\0>"),
    ("(?ims)a.b", "A\nB", "<\\0>"),
    ("(?x)a b", "a b", "<\\0>"),
    ("(?", "a", "-"),
    ("(?i", "a", "-"),
    # errors of structure
    ("(abc", "abc", "-"),
    ("abc)", "abc", "-"),
    ("*a", "a", "-"),
    ("a**", "a", "-"),
    ("a*+", "a", "-"),
    ("a{2,1}", "a", "-"),
    ("(?P<>a)", "a", "-"),
    ("(?P<1a>a)", "a", "-"),
    # what only PCRE has -- refused by both engines
    ("(a)\\1", "aa", "-"),
    ("a(?=b)", "ab", "-"),
    ("a(?!b)", "ac", "-"),
    ("(?<=a)b", "ab", "-"),
    ("(?<!a)b", "cb", "-"),
    ("(?>a+)", "aa", "-"),
    ("a++", "aa", "-"),
    # find_all and replace around empty matches
    ("a*", "abaa", "-"),
    ("a*?", "ab", "-"),
    ("b*", "abba", "X"),
    ("x*", "\u00e9\u00e9", "-"),
    ("", "\u263a", "-"),
    # rewrites
    ("(\\w+) (\\w+)", "hello world", "\\2 \\1"),
    ("(a)", "aa", "\\\\1"),
    ("(a)", "a", "\\9"),
    ("(a)", "a", "\\x"),
    ("(a)", "a", "\\"),
    ("a", "aaa", ""),
    # loops whose body can match the empty string
    ("(|a)*", "aa", "<\\0|\\1>"),
    ("(|a)+", "aa", "<\\0|\\1>"),
    ("(a|)*", "aa", "<\\0|\\1>"),
    ("(a?)*", "ab", "<\\0|\\1>"),
    ("(a*?)*", "aa", "<\\0|\\1>"),
    ("(a*)*?", "aa", "<\\0|\\1>"),
    ("(a*|b)*", "abb", "<\\0|\\1>"),
    ("(?:a*)*b", "aab", "<\\0>"),
    ("(a*){2,}", "b", "<\\0|\\1>"),
    ("(a|b|)*c", "abc", "<\\1>"),
    # a repetition after a flag group has nothing to repeat
    ("(?i)*", "a", "-"),
    ("(?i)+a", "a", "-"),
    # octal
    ("\\0", "a\x00b", "<\\0>"),
    ("\\012", "a\nb", "<\\0>"),
    ("\\1", "1", "-"),
    ("\\18", "18", "-"),
    ("\\17", "a\x0fb", "<\\0>"),
    ("\\377", "\u00ff", "<\\0>"),
    ("\\400", "\u0100", "<\\0>"),
    ("\\1234", "S4", "<\\0>"),
    ("[\\101-\\103]+", "zABCz", "<\\0>"),
    # a trailing backslash, in a pattern and a rewrite
    ("a\\", "a", "-"),
    ("(a)", "ab", "\\1\\"),
    # a text that is not UTF-8: each byte that does not begin a valid
    # sequence reads as U+FFFD, one byte wide.  A literal U+FFFD therefore
    # matches such a byte and must not become a prefix of three bytes.
    ("\\x{FFFD}", b"a\x80b", "<\\0>"),
    ("x\\x{FFFD}", b"x\x80", "<\\0>"),
    ("\\x{FFFD}y", b"\xffy", "<\\0>"),
    (".", b"\xc3", "<\\0>"),
    ("[^a]+", b"a\xe2\x82a", "<\\0>"),
    ("\\x{FFFD}+", b"\xef\xbf\xbd\x80\xff", "<\\0>"),
    ("a\\x{FFFD}b", b"a\xedb a\xef\xbf\xbdb", "<\\0>"),
    # anchored patterns: a match can begin only at offset 0
    ("\\Aab", "abab", "<\\0>"),
    ("^ab", "abab", "<\\0>"),
    ("(?m)^ab", "ab\nab", "<\\0>"),
    ("\\Aa*", "aab", "<\\0>"),
    ("\\A", "abc", "<\\0>"),
    ("(\\Aa|b)", "abab", "<\\0>"),
    ("\\Aa|\\Ab", "ba", "<\\0>"),
    ("(?:\\A)*a", "aa", "<\\0>"),
    # where a match can begin: the first byte decides
    ("[0-9]+", "abc 123 def 45", "<\\0>"),
    ("\u00e9+|x", "a\u00e9\u00e9 x", "<\\0>"),
    ("[\u0100-\u0200]", "a\u00ff\u0101", "<\\0>"),
    ("[a\u263a]b", "\u263ab ab", "<\\0>"),
    ("\\bfoo", "afoo foo", "<\\0>"),
    ("[\u00ff-\U0001F600]", "a\u00ff\U0001F600", "<\\0>"),
    ("(?i)[a-c]x", "zAx bx", "<\\0>"),
    # Unicode classes: categories of one letter and two, scripts,
    # Any, negated by \P and by ^ in the braces, inside a class and out.
    ("\\pL", "a1\u00e9", "<\\0>"),
    ("\\p{L}+", "ab12\u03b1\u03b2", "<\\0>"),
    ("\\p{Lu}", "aB\u00c9\u03a3", "<\\0>"),
    ("\\p{Ll}+", "ABc\u00e9\u03c3D", "<\\0>"),
    ("\\p{Greek}+", "abc \u03b1\u03b2\u03b3 def", "<\\0>"),
    ("\\p{Han}", "a\u4e00b", "<\\0>"),
    ("\\p{Cyrillic}+", "\u0416\u0436x", "<\\0>"),
    ("\\p{Latin}+", "abc\u00e9\u03b1", "<\\0>"),
    ("\\PL", "ab1c", "<\\0>"),
    ("\\P{L}+", "ab12--c", "<\\0>"),
    ("\\p{^L}+", "ab12--c", "<\\0>"),
    ("\\P{^L}+", "12ab", "<\\0>"),
    ("\\pN+", "x\u0661\u0662 3", "<\\0>"),
    ("\\p{Nd}+", "x\u0966\u0967y", "<\\0>"),
    ("\\p{Zs}", "a\u3000b", "<\\0>"),
    ("\\p{Sc}", "a$b\u20acc", "<\\0>"),
    ("\\p{P}+", "a.,;b", "<\\0>"),
    ("\\p{Any}+", "a\u00e9\u4e00", "<\\0>"),
    ("[\\pL]+", "a1b", "<\\0>"),
    ("[\\p{Lu}\\d]+", "aB1\u00c9x", "<\\0>"),
    ("[^\\p{L}]+", "ab12c", "<\\0>"),
    ("[\\P{L}x]+", "ab12xc", "<\\0>"),
    ("[\\p{Greek}\\p{Nd}]+", "a\u03b11b", "<\\0>"),
    ("\\p{Greek}\\p{Latin}", "\u03b1a", "<\\0>"),
    # The names are matched loosely, and Go takes long names, C with the
    # unassigned code points, LC, Assigned and ASCII.
    ("\\p{Cn}", "a\u0378b", "<\\0>"),
    ("\\p{C}+", "a\u0378\u0001b", "<\\0>"),
    ("\\p{latin}+", "\u03b1ab\u00e9", "<\\0>"),
    ("\\p{GREEK}+", "a\u03b1\u03b2", "<\\0>"),
    ("\\p{Letter}+", "12ab\u4e00", "<\\0>"),
    ("\\p{Uppercase_Letter}+", "aBC", "<\\0>"),
    ("\\p{l-u}+", "aBC", "<\\0>"),
    ("\\p{Old Italic}", "a\U00010300", "<\\0>"),
    ("\\p{LC}+", "\u02b0aB\u01c5", "<\\0>"),
    ("\\p{Assigned}+", "ab\u0378", "<\\0>"),
    ("\\p{ASCII}+", "ab\u00e9", "<\\0>"),
    ("\\p{digit}+", "a12", "<\\0>"),
    ("[\\P{Assigned}x]+", "ax\u0378", "<\\0>"),
    # Case folding by Unicode's simple folding orbits, as RE2.
    ("(?i)\u00e9", "\u00c9", "<\\0>"),
    ("(?i)k", "\u212a", "<\\0>"),
    ("(?i)s", "\u017f", "<\\0>"),
    ("(?i)[k]", "\u212a", "<\\0>"),
    ("(?i)\u03c3", "\u03a3\u03c2", "<\\0>"),
    ("(?i)[\u03b1-\u03b3]+", "\u0391\u0392\u0393", "<\\0>"),
    ("(?i)\u01c4", "\u01c5\u01c6", "<\\0>"),
    ("(?i)\u00df", "\u1e9e", "<\\0>"),
    ("(?i)\u00df", "ss", "<\\0>"),
    ("(?i)ss", "\u00df", "<\\0>"),
    ("(?i)[^k]", "\u212a", "<\\0>"),
    ("(?i)\\p{Lu}+", "abC", "<\\0>"),
    ("(?i)\u0416", "\u0436", "<\\0>"),
    ("(?i)stra\u00dfe", "STRA\u1e9eE", "<\\0>"),
    # a literal that every match contains, not at its start
    ("[a-z]+@example\\.com", "x y@example.com z@example.com", "<\\0>"),
    ("\\d+kg", "12 kg 34kg", "<\\0>"),
    ("[a-z]+ing", "nothing here", "<\\0>"),
    ("[a-z]+ing", "no match here", "<\\0>"),
    ("(a|b)cd(e|f)gh", "acdfgh bcdegh", "<\\0>"),
]

DEVIATIONS = [
    # A property name the tables do not know, and braces that do not close:
    # refused by both, with this engine's message and offset.
    ("\\p{Foo}", "a", "-"),
    ("\\p{L", "a", "-"),
    ("[\\p{Foo}]", "a", "-"),
    ("\\p", "a", "-"),
    ("\\p{}", "a", "-"),
    ("\\p{Latn}", "a", "-"),
    ("\\p{L&}", "a", "-"),
    ("\\p{Unknown}", "a", "-"),
    # \C, one byte whatever the encoding: RE2 has it, this engine refuses it.
    ("\\C", "a", "-"),
    # PCRE only: refused by both, and the message here names Standard.Pcre.
    ("(a)\\1", "aa", "-"),
    ("\\k<n>", "a", "-"),
    ("a(?=b)", "ab", "-"),
    ("a(?!b)", "ac", "-"),
    ("(?<=a)b", "ab", "-"),
    ("(?<!a)b", "cb", "-"),
    ("(?>a+)", "aa", "-"),
    ("a++", "aa", "-"),
    ("a?+", "a", "-"),
    ("(?'n'a)", "a", "-"),
    ("\\Z", "a", "-"),
    ("\\h", "a", "-"),
    ("\\R", "a", "-"),
    ("\\K", "a", "-"),
    ("\\G", "a", "-"),
    # the messages of the other refusals, with their byte offsets
    ("(abc", "a", "-"),
    ("abc)", "a", "-"),
    ("*a", "a", "-"),
    ("a**", "a", "-"),
    ("a{2,1}", "a", "-"),
    ("x{1001}", "a", "-"),
    ("[z-a]", "a", "-"),
    ("[a", "a", "-"),
    ("[[:foo:]]", "a", "-"),
    ("\\q", "a", "-"),
    ("\\x{110000}", "a", "-"),
    ("(?P<>a)", "a", "-"),
    ("(?", "a", "-"),
    ("a\\", "a", "-"),
]

# Patterns for the messages test alone: the limits, exactly at and one past them,
# and bytes that are not UTF-8.
PROPERTY_NAMES = ['C', 'Other', 'Cc', 'Control', 'cntrl', 'Cf', 'Format', 'Cn', 'Unassigned', 'Co', 'Private_Use', 'Cs', 'Surrogate', 'L', 'Letter', 'LC', 'Cased_Letter', 'Ll', 'Lowercase_Letter', 'Lm', 'Modifier_Letter', 'Lo', 'Other_Letter', 'Lt', 'Titlecase_Letter', 'Lu', 'Uppercase_Letter', 'M', 'Mark', 'Combining_Mark', 'Mc', 'Spacing_Mark', 'Me', 'Enclosing_Mark', 'Mn', 'Nonspacing_Mark', 'N', 'Number', 'Nd', 'Decimal_Number', 'digit', 'Nl', 'Letter_Number', 'No', 'Other_Number', 'P', 'Punctuation', 'punct', 'Pc', 'Connector_Punctuation', 'Pd', 'Dash_Punctuation', 'Pe', 'Close_Punctuation', 'Pf', 'Final_Punctuation', 'Pi', 'Initial_Punctuation', 'Po', 'Other_Punctuation', 'Ps', 'Open_Punctuation', 'S', 'Symbol', 'Sc', 'Currency_Symbol', 'Sk', 'Modifier_Symbol', 'Sm', 'Math_Symbol', 'So', 'Other_Symbol', 'Z', 'Separator', 'Zl', 'Line_Separator', 'Zp', 'Paragraph_Separator', 'Zs', 'Space_Separator', 'Any', 'Assigned', 'ASCII']

EDGES = [
    "(?:a{1000}){99}a{997}",
    "(?:a{1000}){99}a{998}",
    "(a{1000}){101}",
    "((a{1000}){1000}){1000}",
    "(" * 500 + "a" + ")" * 500,
    "(" * 501 + "a" + ")" * 501,
    "(?i)*",
    "(?i){2}",
    "(?i)+?",
    "(?i)*+",
    "a|*",
    "\\x{FFFFFFFFFFFF}",
    b"\xff",
    b"a\xc3",
    b"\xed\xa0\x80",
    b"\xef\xbf\xbd",
    b"[\xff]",
    b"\\Q\xff",
] + ["\\p{%s}" % n for n in PROPERTY_NAMES]


def encode(s):
    """s in plain ASCII: every byte of its UTF-8 encoding (or of s itself,
    when it is bytes) that is not a printable ASCII character, and every
    `%`, `"` and `\\`, written as `%XX`.  The repository takes ASCII only,
    and a Hilde literal processes escapes of its own (`\\n`, `\\\\` and
    more, lib/Escape.ml), so a backslash is never written as one."""
    data = s if isinstance(s, bytes) else s.encode("utf-8")
    out = []
    for b in data:
        c = chr(b)
        if 0x20 <= b < 0x7f and c not in '%"\\':
            out.append(c)
        else:
            out.append("%%%02X" % b)
    return "".join(out)


def hilde_literal(s):
    """A Hilde string literal for s, decoded by the test at run time."""
    return '"' + encode(s) + '"'


HEADER = """-- Generated by scripts/regex/cases.py -- do not edit; edit the table there.
--
@WHAT@
import Standard.String (
    String,
    destroyString,
    length,
    nthByte,
    getSpan,
    asSpan
);
import Standard.StringBuilder (
    StringBuilder,
    makeStringBuilder,
    writeByte,
    finalize
);
import Standard.Buffer (
    Buffer,
    destroyFree,
    length as bufferLength,
    nth
);
import Standard.Regex (
    Regex,
    compile,
    destroyRegex,
    groupCount,
    match,
    Found,
    find,
    foundStart,
    foundEnd,
    groupStart,
    groupEnd,
    destroyFound,
    Hit,
    find_all,
    replace
);

module body Test is
    constant ten: Nat8 := 10;
    constant sixteen: Nat8 := 16;

    function nibble(c: Nat8): Nat8 is
        if c <= '9' then
            return c - '0';
        end if;
        return (c - 'A') + ten;
    end;

    -- The literals of this file are ASCII: every other byte, and every
    -- %, quote and backslash, is written %xx (scripts/regex/cases.py).
    function decode(encoded: Span[Nat8, Static]): String is
        var out: StringBuilder := makeStringBuilder();
        let size: Index := spanLength(encoded);
        var i: Index := 0;
        while i < size do
            let c: Nat8 := encoded[i];
            if c = '%' then
                let high: Nat8 := nibble(encoded[i + 1]);
                let low: Nat8 := nibble(encoded[i + 2]);
                writeByte(&!out, (high * sixteen) + low);
                i := i + 3;
            else
                writeByte(&!out, c);
                i := i + 1;
            end if;
        end while;
        return finalize(out);
    end;

    generic [R: Region]
    function compileText(pattern: &[String, R]): Either[String, Regex] is
        let size: Index := length(pattern);
        if size = 0 then
            return compile("");
        end if;
        return compile(getSpan(pattern, 0, size - 1));
    end;

    function hexDigit(value: Nat8): Nat8 is
        if value < ten then
            return value + '0';
        end if;
        return (value - ten) + 'A';
    end;

    -- The expected output is a file of the repository, which is ASCII, so
    -- the text is printed with the same %xx escape the literals use.
    generic [R: Region]
    function printText(text: &[String, R]): Unit is
        let size: Index := length(text);
        var out: StringBuilder := makeStringBuilder();
        writeByte(&!out, '[');
        var i: Index := 0;
        while i < size do
            let c: Nat8 := nthByte(text, i);
            if (c < ' ') or ((c > '~') or (c = '%')) then
                writeByte(&!out, '%');
                writeByte(&!out, hexDigit(c / sixteen));
                writeByte(&!out, hexDigit(c - ((c / sixteen) * sixteen)));
            else
                writeByte(&!out, c);
            end if;
            i := i + 1;
        end while;
        writeByte(&!out, ']');
        let shown: String := finalize(out);
        printLn(getSpan(&shown, 0, length(&shown) - 1));
        destroyString(shown);
        return nil;
    end;

    function printOption(value: Option[Index]): Unit is
        case value of
            when Some(value as v: Index) do
                print(v);
            when None do
                print("-");
        end case;
        return nil;
    end;

    generic [R: Region, S: Region]
    function printFind(re: &[Regex, R], text: &[String, S]): Unit is
        case find(re, asSpan(text)) of
            when Some(value as f: Found) do
                print("find ");
                print(foundStart(&f));
                print(" ");
                print(foundEnd(&f));
                let groups: Index := groupCount(re);
                var g: Index := 1;
                while g <= groups do
                    print(" ");
                    printOption(groupStart(&f, g));
                    print(",");
                    printOption(groupEnd(&f, g));
                    g := g + 1;
                end while;
                printLn("");
                destroyFound(f);
            when None do
                printLn("find none");
        end case;
        return nil;
    end;

    generic [R: Region, S: Region]
    function printAll(re: &[Regex, R], text: &[String, S]): Unit is
        let hits: Buffer[Hit] := find_all(re, asSpan(text));
        let count: Index := bufferLength(&hits);
        print("all ");
        print(count);
        var i: Index := 0;
        while i < count do
            let hit: Hit := nth(&hits, i);
            print(" ");
            print(hit.start);
            print(",");
            print(hit.stop);
            i := i + 1;
        end while;
        printLn("");
        destroyFree(hits);
        return nil;
    end;

    function check(number: Index, pattern: Span[Nat8, Static], subject: Span[Nat8, Static],
                   rewrite: Span[Nat8, Static], showMessage: Bool): Unit is
        print("case ");
        printLn(number);
        let text: String := decode(subject);
        let source: String := decode(pattern);
        let compiled: Either[String, Regex] := compileText(&source);
        destroyString(source);
        case compiled of
            when Right(right as re: Regex) do
                if match(&re, asSpan(&text)) then
                    printLn("match yes");
                else
                    printLn("match no");
                end if;
                printFind(&re, &text);
                printAll(&re, &text);
                let with: String := decode(rewrite);
                let out: String := replace(&re, asSpan(&text), asSpan(&with));
                print("replace ");
                printText(&out);
                destroyString(out);
                destroyString(with);
                destroyRegex(re);
            when Left(left as message: String) do
                if showMessage then
                    print("error ");
                    printText(&message);
                else
                    printLn("error");
                end if;
                destroyString(message);
        end case;
        destroyString(text);
        return nil;
    end;

    -- Only whether compile takes the pattern, and if not, its message.
    function checkCompile(number: Index, pattern: Span[Nat8, Static]): Unit is
        print("case ");
        printLn(number);
        let source: String := decode(pattern);
        let compiled: Either[String, Regex] := compileText(&source);
        destroyString(source);
        case compiled of
            when Right(right as re: Regex) do
                printLn("ok");
                destroyRegex(re);
            when Left(left as message: String) do
                print("error ");
                printText(&message);
                destroyString(message);
        end case;
        return nil;
    end;

    function main(): ExitCode is
"""

FOOTER = """        return ExitSuccess();
    end;
end module body.
"""


def write_test(root, name, table, show_message, what):
    test = os.path.join(root, "test-programs", "suites", "043-regex", name)
    os.makedirs(test, exist_ok=True)
    lines = []
    for number, (pattern, subject, rewrite) in enumerate(table, 1):
        lines.append("        check(%d, %s, %s, %s, %s);\n" % (
            number, hilde_literal(pattern), hilde_literal(subject), hilde_literal(rewrite),
            "true" if show_message else "false"))
    with open(os.path.join(test, "Test.hiq"), "w", encoding="utf-8", newline="\n") as f:
        f.write(HEADER.replace("@WHAT@", what) + "".join(lines) + FOOTER)


def json_case(pattern, subject, rewrite):
    """One case for the oracle.  JSON text is UTF-8, so a subject that is
    not -- bytes -- goes as hex in `subject_hex', and the oracle decodes it."""
    case = {"pattern": pattern}
    if isinstance(subject, bytes):
        case["subject"] = ""
        case["subject_hex"] = subject.hex()
    else:
        case["subject"] = subject
    case["rewrite"] = rewrite
    return case


def write_json(path, table):
    cases = [json_case(p, s, r) for (p, s, r) in table]
    with open(path, "w", encoding="utf-8", newline="\n") as f:
        json.dump(cases, f, ensure_ascii=True, indent=1)
        f.write("\n")


def main():
    here = os.path.dirname(os.path.abspath(__file__))
    root = os.path.dirname(os.path.dirname(here))
    write_test(root, "001-against-go", CASES, False,
               "-- Every case of CASES, run through Standard.Regex.  The expected output\n"
               "-- is Go's regexp on the same table (scripts/regex/oracle.go), so a line that\n"
               "-- differs is a place where this engine and RE2's semantics part.")
    write_test(root, "002-deviations", DEVIATIONS, True,
               "-- Every case of DEVIATIONS, run through Standard.Regex, with the message of\n"
               "-- each refusal.  The expected output is this engine's own, reviewed.")
    write_json(os.path.join(here, "cases.json"), CASES)
    write_json(os.path.join(here, "deviations.json"), DEVIATIONS)
    patterns = [p for (p, _, _) in CASES] + [p for (p, _, _) in DEVIATIONS] + EDGES
    test = os.path.join(root, "test-programs", "suites", "043-regex", "004-messages")
    os.makedirs(test, exist_ok=True)
    lines = ["        checkCompile(%d, %s);\n" % (n, hilde_literal(p)) for n, p in enumerate(patterns, 1)]
    with open(os.path.join(test, "Test.hiq"), "w", encoding="utf-8", newline="\n") as f:
        f.write(HEADER.replace("@WHAT@",
                               "-- Every pattern of CASES, DEVIATIONS and EDGES, and whether compile\n"
                               "-- takes it.  test/RegexCheckTest.ml holds the compiler's check against\n"
                               "-- this output.") + "".join(lines) + FOOTER)
    with open(os.path.join(here, "messages.json"), "w", encoding="utf-8", newline="\n") as f:
        json.dump([encode(p) for p in patterns], f, ensure_ascii=True, indent=1)
        f.write("\n")
    print("cases: %d deviations: %d messages: %d" % (len(CASES), len(DEVIATIONS), len(patterns)))


if __name__ == "__main__":
    main()
