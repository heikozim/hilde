(*
   Part of the Hilde project, under the Apache License v2.0 with LLVM Exceptions.
   See LICENSE file for details.

   SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
*)

(* The compile-time check of a literal pattern handed to Standard.Regex's
   `compile'.

   This is a port of the parser in standard/src/Regex.hiq, and of nothing
   else: it answers only whether that parser would refuse the pattern, and
   with which message and byte offset.  The two are held together by a test,
   not by care: test/RegexCheckTest.ml runs every pattern of
   scripts/regex/cases.json and deviations.json through this module and
   compares the answer with the expected output of the end-to-end test of
   Standard.Regex's messages, which is Standard.Regex's own answer for the
   same patterns.

   The Hilde parser records the FIRST failure and unwinds; this one raises
   at its first failure.  Up to that point both run the same steps, so the
   first failure is the same one.

   Positions and values are the Hilde module's, `none' included, so that
   every comparison below reads as it does there. *)

let none = 4294967295

let program_limit = 100000
let repeat_limit = 1000
let depth_limit = 500

(* The error codes of Regex.hiq, and their messages. *)
let e_missing_paren = 1
let e_unexpected_paren = 2
let e_missing_repeat_argument = 3
let e_bad_repeat = 4
let e_bad_repeat_count = 5
let e_missing_bracket = 6
let e_bad_range = 7
let e_bad_escape = 8
let e_trailing_backslash = 9
let e_bad_group = 10
let e_bad_flag = 11
let e_bad_utf8 = 12
let e_too_large = 13
let e_bad_hex = 14
let e_any_byte = 16
let e_bad_posix = 17
let e_too_deep = 18
let e_backreference = 20
let e_lookaround = 21
let e_atomic = 22
let e_pcre_only = 23

let reason (code: int): string =
  if code = e_missing_paren then "missing closing )"
  else if code = e_unexpected_paren then "unexpected )"
  else if code = e_missing_repeat_argument then "missing argument to repetition operator"
  else if code = e_bad_repeat then "bad repetition operator"
  else if code = e_bad_repeat_count then "invalid repeat count"
  else if code = e_missing_bracket then "missing closing ]"
  else if code = e_bad_range then "invalid character class range"
  else if code = e_bad_escape then "invalid escape sequence"
  else if code = e_trailing_backslash then "trailing backslash at end of expression"
  else if code = e_bad_group then "invalid or unsupported group syntax"
  else if code = e_bad_flag then "invalid or unsupported Perl syntax"
  else if code = e_bad_utf8 then "invalid UTF-8"
  else if code = e_too_large then "expression too large"
  else if code = e_bad_hex then "invalid escape sequence"
  else if code = e_any_byte then "\\C is not supported by this engine"
  else if code = e_bad_posix then "invalid character class range"
  else if code = e_too_deep then "expression nests too deeply"
  else if code = e_backreference then "backreferences are not supported -- they cannot be matched in linear time; Standard.Pcre has them"
  else if code = e_lookaround then "lookaround is not supported -- it cannot be matched in linear time; Standard.Pcre has it"
  else if code = e_atomic then "atomic groups and possessive repetition are not supported; Standard.Pcre has them"
  else if code = e_pcre_only then "this is PCRE syntax, not RE2 syntax; Standard.Pcre has it"
  else "invalid expression"

let message (code: int) (at: int): string =
  "Standard.Regex: " ^ (reason code) ^ " at byte " ^ (string_of_int at)

exception Refused of int * int

(* The tree, as far as the program size needs it. *)
type node =
  | Leaf
  | Empty
  | Capture of node
  | Concat of node list
  | Alternate of node list
  | Repeat of node * int * int

type state = {
    text: string;
    mutable pos: int;
  }

let fail (code: int) (at: int): 'a =
  raise (Refused (code, at))

let fail_here (st: state) (code: int): 'a =
  fail code st.pos

let size (st: state): int =
  String.length st.text

let byte_at (st: state) (at: int): int =
  if at >= size st then none else Char.code st.text.[at]

let byte_is (st: state) (at: int) (c: char): bool =
  at < size st && st.text.[at] = c

let is_ascii_digit (v: int): bool = v >= 48 && v <= 57

let hex_value (v: int): int =
  if is_ascii_digit v then v - 48
  else if v >= 97 && v <= 102 then v - 87
  else if v >= 65 && v <= 70 then v - 55
  else none

let is_word_byte (v: int): bool =
  is_ascii_digit v || (v >= 65 && v <= 90) || (v >= 97 && v <= 122) || v = 95

let is_continuation (v: int): bool =
  v <> none && v >= 0x80 && v <= 0xBF

(* runeAt: (value, width); an end is (none, 0), a bad sequence (0xFFFD, 1). *)
let rune_at (st: state) (at: int): int * int =
  if at >= size st then (none, 0)
  else
    let b0 = byte_at st at in
    let bad = (0xFFFD, 1) in
    if b0 < 0x80 then (b0, 1)
    else if b0 >= 0xC2 && b0 <= 0xDF then
      let b1 = byte_at st (at + 1) in
      if not (is_continuation b1) then bad
      else (((b0 - 0xC0) * 64) + (b1 - 0x80), 2)
    else if b0 >= 0xE0 && b0 <= 0xEF then
      let b1 = byte_at st (at + 1) and b2 = byte_at st (at + 2) in
      if not (is_continuation b1 && is_continuation b2) then bad
      else if b0 = 0xE0 && b1 < 0xA0 then bad
      else if b0 = 0xED && b1 > 0x9F then bad
      else ((((b0 - 0xE0) * 4096) + ((b1 - 0x80) * 64)) + (b2 - 0x80), 3)
    else if b0 >= 0xF0 && b0 <= 0xF4 then
      let b1 = byte_at st (at + 1) and b2 = byte_at st (at + 2) and b3 = byte_at st (at + 3) in
      if not (is_continuation b1 && is_continuation b2 && is_continuation b3) then bad
      else if b0 = 0xF0 && b1 < 0x90 then bad
      else if b0 = 0xF4 && b1 > 0x8F then bad
      else (((((b0 - 0xF0) * 262144) + ((b1 - 0x80) * 4096)) + ((b2 - 0x80) * 64)) + (b3 - 0x80), 4)
    else bad

(* patternRune: a bad sequence is width 0. *)
let pattern_rune (st: state) (at: int): int * int =
  let (value, width) = rune_at st at in
  if value = 0xFFFD && width = 1 then (none, 0) else (value, width)

let is_repeat_byte (v: int): bool = v = 42 || v = 43 || v = 63

let is_counted_repeat (st: state) (at: int): bool =
  if not (byte_is st at '{') then false
  else begin
    let i = ref (at + 1) and digits = ref 0 in
    while is_ascii_digit (byte_at st !i) do incr i; incr digits done;
    if !digits = 0 then false
    else if byte_is st !i '}' then true
    else if not (byte_is st !i ',') then false
    else begin
      incr i;
      while is_ascii_digit (byte_at st !i) do incr i done;
      byte_is st !i '}'
    end
  end

let read_number (st: state): int =
  let value = ref 0 in
  while is_ascii_digit (byte_at st st.pos) do
    if !value < 100000 then value := (!value * 10) + (byte_at st st.pos - 48);
    st.pos <- st.pos + 1
  done;
  !value

let is_pcre_group_start (c: int): bool =
  c = 35 || c = 40 || c = 39 || c = 82 || c = 38 || c = 43 || c = 124 || is_ascii_digit c

let is_pcre_escape (c: int): bool =
  c = 90 || c = 71 || c = 75 || c = 82 || c = 88 || c = 104 || c = 72 || c = 78

let is_octal (v: int): bool = v >= 48 && v <= 55

let is_perl_class (c: int): bool =
  c = 100 || c = 68 || c = 115 || c = 83 || c = 119 || c = 87

let octal_escape (st: state) (first: int): int =
  let value = ref first and digits = ref 1 in
  while !digits < 3 && is_octal (byte_at st st.pos) do
    value := (!value * 8) + (byte_at st st.pos - 48);
    st.pos <- st.pos + 1;
    incr digits
  done;
  !value

let hex_escape (st: state) (at: int): int =
  if byte_is st st.pos '{' then begin
    st.pos <- st.pos + 1;
    let value = ref 0 and digits = ref 0 in
    while hex_value (byte_at st st.pos) <> none do
      if !value <= 0x10FFFF then value := (!value * 16) + hex_value (byte_at st st.pos);
      st.pos <- st.pos + 1;
      incr digits
    done;
    if !digits = 0 || not (byte_is st st.pos '}') then fail e_bad_hex at;
    st.pos <- st.pos + 1;
    if !value > 0x10FFFF then fail e_bad_hex at;
    !value
  end else begin
    let high = hex_value (byte_at st st.pos) and low = hex_value (byte_at st (st.pos + 1)) in
    if high = none || low = none then fail e_bad_hex at;
    st.pos <- st.pos + 2;
    (high * 16) + low
  end

let escaped_value (st: state): int =
  let at = st.pos in
  let c = byte_at st (at + 1) in
  if c = none then fail e_trailing_backslash at;
  st.pos <- at + 2;
  if c = 97 then 7
  else if c = 102 then 12
  else if c = 116 then 9
  else if c = 110 then 10
  else if c = 114 then 13
  else if c = 118 then 11
  else if c = 120 then hex_escape st at
  else if c >= 49 && c <= 55 then
    (if is_octal (byte_at st st.pos) then octal_escape st (c - 48)
     else fail e_backreference at)
  else if c = 56 || c = 57 then fail e_backreference at
  else if c = 48 then octal_escape st 0
  else if c = 107 || c = 103 then fail e_backreference at
  else if is_pcre_escape c then fail e_pcre_only at
  else if c = 67 then fail e_any_byte at
  else if c < 128 && not (is_word_byte c) then c
  else fail e_bad_escape at

(* The scripts of Scripts.txt 17.0.0, written by
   scripts/unicode/make-property-tables.py --ocaml.  Not edited by hand. *)
let script_names = [
    "Adlam"; "Ahom"; "Anatolian_Hieroglyphs"; "Arabic"; "Armenian";
    "Avestan"; "Balinese"; "Bamum"; "Bassa_Vah"; "Batak"; "Bengali";
    "Beria_Erfe"; "Bhaiksuki"; "Bopomofo"; "Brahmi"; "Braille"; "Buginese";
    "Buhid"; "Canadian_Aboriginal"; "Carian"; "Caucasian_Albanian";
    "Chakma"; "Cham"; "Cherokee"; "Chorasmian"; "Common"; "Coptic";
    "Cuneiform"; "Cypriot"; "Cypro_Minoan"; "Cyrillic"; "Deseret";
    "Devanagari"; "Dives_Akuru"; "Dogra"; "Duployan";
    "Egyptian_Hieroglyphs"; "Elbasan"; "Elymaic"; "Ethiopic"; "Garay";
    "Georgian"; "Glagolitic"; "Gothic"; "Grantha"; "Greek"; "Gujarati";
    "Gunjala_Gondi"; "Gurmukhi"; "Gurung_Khema"; "Han"; "Hangul";
    "Hanifi_Rohingya"; "Hanunoo"; "Hatran"; "Hebrew"; "Hiragana";
    "Imperial_Aramaic"; "Inherited"; "Inscriptional_Pahlavi";
    "Inscriptional_Parthian"; "Javanese"; "Kaithi"; "Kannada"; "Katakana";
    "Kawi"; "Kayah_Li"; "Kharoshthi"; "Khitan_Small_Script"; "Khmer";
    "Khojki"; "Khudawadi"; "Kirat_Rai"; "Lao"; "Latin"; "Lepcha"; "Limbu";
    "Linear_A"; "Linear_B"; "Lisu"; "Lycian"; "Lydian"; "Mahajani";
    "Makasar"; "Malayalam"; "Mandaic"; "Manichaean"; "Marchen";
    "Masaram_Gondi"; "Medefaidrin"; "Meetei_Mayek"; "Mende_Kikakui";
    "Meroitic_Cursive"; "Meroitic_Hieroglyphs"; "Miao"; "Modi"; "Mongolian";
    "Mro"; "Multani"; "Myanmar"; "Nabataean"; "Nag_Mundari"; "Nandinagari";
    "New_Tai_Lue"; "Newa"; "Nko"; "Nushu"; "Nyiakeng_Puachue_Hmong";
    "Ogham"; "Ol_Chiki"; "Ol_Onal"; "Old_Hungarian"; "Old_Italic";
    "Old_North_Arabian"; "Old_Permic"; "Old_Persian"; "Old_Sogdian";
    "Old_South_Arabian"; "Old_Turkic"; "Old_Uyghur"; "Oriya"; "Osage";
    "Osmanya"; "Pahawh_Hmong"; "Palmyrene"; "Pau_Cin_Hau"; "Phags_Pa";
    "Phoenician"; "Psalter_Pahlavi"; "Rejang"; "Runic"; "Samaritan";
    "Saurashtra"; "Sharada"; "Shavian"; "Siddham"; "Sidetic"; "SignWriting";
    "Sinhala"; "Sogdian"; "Sora_Sompeng"; "Soyombo"; "Sundanese"; "Sunuwar";
    "Syloti_Nagri"; "Syriac"; "Tagalog"; "Tagbanwa"; "Tai_Le"; "Tai_Tham";
    "Tai_Viet"; "Tai_Yo"; "Takri"; "Tamil"; "Tangsa"; "Tangut"; "Telugu";
    "Thaana"; "Thai"; "Tibetan"; "Tifinagh"; "Tirhuta"; "Todhri";
    "Tolong_Siki"; "Toto"; "Tulu_Tigalari"; "Ugaritic"; "Vai"; "Vithkuqi";
    "Wancho"; "Warang_Citi"; "Yezidi"; "Yi"; "Zanabazar_Square";
  ]

(* The names of the general categories and of the three sets Go's regexp
   takes besides, the list of categoryNames in
   standard/src/UnicodeProperties.hiq without the codes. *)
let category_names = [
    "C"; "Other"; "Cc"; "Control"; "cntrl"; "Cf"; "Format"; "Cn"; "Unassigned";
    "Co"; "Private_Use"; "Cs"; "Surrogate"; "L"; "Letter"; "LC"; "Cased_Letter";
    "Ll"; "Lowercase_Letter"; "Lm"; "Modifier_Letter"; "Lo"; "Other_Letter";
    "Lt"; "Titlecase_Letter"; "Lu"; "Uppercase_Letter"; "M"; "Mark";
    "Combining_Mark"; "Mc"; "Spacing_Mark"; "Me"; "Enclosing_Mark"; "Mn";
    "Nonspacing_Mark"; "N"; "Number"; "Nd"; "Decimal_Number"; "digit"; "Nl";
    "Letter_Number"; "No"; "Other_Number"; "P"; "Punctuation"; "punct"; "Pc";
    "Connector_Punctuation"; "Pd"; "Dash_Punctuation"; "Pe";
    "Close_Punctuation"; "Pf"; "Final_Punctuation"; "Pi";
    "Initial_Punctuation"; "Po"; "Other_Punctuation"; "Ps";
    "Open_Punctuation"; "S"; "Symbol"; "Sc"; "Currency_Symbol"; "Sk";
    "Modifier_Symbol"; "Sm"; "Math_Symbol"; "So"; "Other_Symbol"; "Z";
    "Separator"; "Zl"; "Line_Separator"; "Zp"; "Paragraph_Separator"; "Zs";
    "Space_Separator"; "Any"; "Assigned"; "ASCII" ]

(* A name as the loose matching of Unicode compares it: capital ASCII
   letters made small, spaces, underscores and hyphens left out. *)
let loose (name: string): string =
  String.concat ""
    (List.filter_map
       (fun c -> if c = ' ' || c = '_' || c = '-' then None else Some (String.make 1 (Char.lowercase_ascii c)))
       (List.of_seq (String.to_seq name)))

let is_property (name: string): bool =
  let n = loose name in
  n <> ""
  && (List.exists (fun c -> loose c = n) category_names
      || List.exists (fun s -> loose s = n) script_names)

(* \p or \P at at, read as propertyClass in Regex.hiq reads it: one letter,
   or a name in braces with a ^ first; refused at the backslash when the
   braces do not close or the name is not a property. *)
let property_class (st: state) (at: int): unit =
  let name_start = ref (at + 2) and name_end = ref (at + 3) in
  if !name_start >= size st then fail e_bad_posix at;
  if byte_is st !name_start '{' then begin
    incr name_start;
    if byte_is st !name_start '^' then incr name_start;
    let k = ref !name_start in
    while !k < size st && not (byte_is st !k '}') do incr k done;
    if !k >= size st then fail e_bad_posix at;
    name_end := !k;
    st.pos <- !k + 1
  end else st.pos <- !name_end;
  let name = String.sub st.text !name_start (!name_end - !name_start) in
  if not (is_property name) then fail e_bad_posix at

let posix_names = [
    "alnum"; "alpha"; "ascii"; "blank"; "cntrl"; "digit"; "graph";
    "lower"; "print"; "punct"; "space"; "upper"; "word"; "xdigit" ]

let posix_class (st: state): unit =
  let opening = st.pos in
  st.pos <- st.pos + 2;
  if byte_is st st.pos '^' then st.pos <- st.pos + 1;
  let name_start = st.pos in
  while st.pos < size st && not (byte_is st st.pos ':') do st.pos <- st.pos + 1 done;
  if not (byte_is st st.pos ':' && byte_is st (st.pos + 1) ']') then fail e_bad_posix opening;
  let name = String.sub st.text name_start (st.pos - name_start) in
  st.pos <- st.pos + 2;
  if not (List.mem name posix_names) then fail e_bad_posix opening

let class_value (st: state): int =
  if byte_is st st.pos '\\' then begin
    let c = byte_at st (st.pos + 1) in
    if c = 98 then fail_here st e_bad_escape;
    escaped_value st
  end else begin
    let (value, width) = pattern_rune st st.pos in
    if width = 0 then fail_here st e_bad_utf8;
    st.pos <- st.pos + width;
    value
  end

let class_item (st: state): unit =
  if byte_is st st.pos '[' && byte_is st (st.pos + 1) ':' then posix_class st
  else begin
    let perl =
      if byte_is st st.pos '\\' then begin
        let c = byte_at st (st.pos + 1) in
        if is_perl_class c then (st.pos <- st.pos + 2; true)
        else if c = 112 || c = 80 then (property_class st st.pos; true)
        else false
      end else false
    in
    if not perl then begin
      let low = class_value st in
      if byte_is st st.pos '-' && not (byte_is st (st.pos + 1) ']') then begin
        let dash = st.pos in
        if st.pos + 1 >= size st then fail e_missing_bracket dash;
        st.pos <- st.pos + 1;
        let high = class_value st in
        if high < low then fail e_bad_range dash
      end
    end
  end

let parse_class (st: state): node =
  let opening = st.pos in
  st.pos <- opening + 1;
  if byte_is st st.pos '^' then st.pos <- st.pos + 1;
  let items = ref 0 and going = ref true in
  while !going do
    if st.pos >= size st then fail e_missing_bracket opening;
    if byte_is st st.pos ']' && !items > 0 then begin
      st.pos <- st.pos + 1;
      going := false
    end else begin
      class_item st;
      incr items
    end
  done;
  Leaf

let parse_quoted (st: state): node =
  st.pos <- st.pos + 2;
  let pieces = ref [] and going = ref true in
  while !going do
    if st.pos >= size st then going := false
    else if byte_is st st.pos '\\' && byte_is st (st.pos + 1) 'E' then begin
      st.pos <- st.pos + 2;
      going := false
    end else begin
      let (_, width) = pattern_rune st st.pos in
      if width = 0 then fail_here st e_bad_utf8;
      st.pos <- st.pos + width;
      pieces := Leaf :: !pieces
    end
  done;
  match !pieces with
  | [] -> Empty
  | [p] -> p
  | ps -> Concat (List.rev ps)

let parse_escape (st: state): node =
  let at = st.pos in
  let c = byte_at st (at + 1) in
  if c = none then fail e_trailing_backslash at;
  if c = 98 || c = 66 || c = 65 || c = 122 then (st.pos <- at + 2; Leaf)
  else if c = 81 then parse_quoted st
  else if is_perl_class c then (st.pos <- at + 2; Leaf)
  else if c = 112 || c = 80 then (property_class st at; Leaf)
  else (ignore (escaped_value st); Leaf)

let skip_group_name (st: state): bool =
  st.pos <- st.pos + 1;
  let count = ref 0 in
  while is_word_byte (byte_at st st.pos) do st.pos <- st.pos + 1; incr count done;
  if !count = 0 then false
  else if not (byte_is st st.pos '>') then false
  else (st.pos <- st.pos + 1; true)

(* 1: (?flags) alone; 2: (?flags:re). *)
let parse_flags (st: state): int =
  let start = st.pos in
  let seen = ref 0 and saw_minus = ref false and result = ref 0 in
  while !result = 0 do
    let c = byte_at st st.pos in
    if c = 105 || c = 109 || c = 115 || c = 85 then (incr seen; st.pos <- st.pos + 1)
    else if c = 45 then begin
      if !saw_minus then fail e_bad_flag start;
      saw_minus := true;
      st.pos <- st.pos + 1
    end else if c = 41 then begin
      if !seen = 0 then fail e_bad_flag start;
      st.pos <- st.pos + 1;
      result := 1
    end else if c = 58 then (st.pos <- st.pos + 1; result := 2)
    else fail e_bad_flag start
  done;
  !result

let rec parse_alternation (st: state) (depth: int): node =
  if depth > depth_limit then fail_here st e_too_deep;
  let first = parse_concat st depth in
  if not (byte_is st st.pos '|') then first
  else begin
    let branches = ref [first] in
    while byte_is st st.pos '|' do
      st.pos <- st.pos + 1;
      branches := parse_concat st depth :: !branches
    done;
    Alternate (List.rev !branches)
  end

and parse_concat (st: state) (depth: int): node =
  let pieces = ref [] and going = ref true in
  while !going do
    if st.pos >= size st then going := false
    else if byte_is st st.pos '|' then going := false
    else if byte_is st st.pos ')' then going := false
    else
      match parse_repeat st depth with
      | Some piece -> pieces := piece :: !pieces
      | None -> ()
  done;
  match !pieces with
  | [] -> Empty
  | [p] -> p
  | ps -> Concat (List.rev ps)

and parse_repeat (st: state) (depth: int): node option =
  let atom = parse_atom st depth in
  let c = byte_at st st.pos in
  if is_repeat_byte c then begin
    let op_at = st.pos in
    st.pos <- st.pos + 1;
    let (minimum, maximum) = if c = 42 then (0, none) else if c = 43 then (1, none) else (0, 1) in
    Some (finish_repeat st atom minimum maximum op_at)
  end else if is_counted_repeat st st.pos then begin
    let op_at = st.pos in
    st.pos <- st.pos + 1;
    let minimum = read_number st in
    let maximum =
      if byte_is st st.pos ',' then begin
        st.pos <- st.pos + 1;
        if byte_is st st.pos '}' then none else read_number st
      end else minimum
    in
    st.pos <- st.pos + 1;
    if minimum > repeat_limit then fail e_bad_repeat_count op_at;
    if maximum <> none && (maximum > repeat_limit || maximum < minimum) then fail e_bad_repeat_count op_at;
    Some (finish_repeat st atom minimum maximum op_at)
  end else atom

and finish_repeat (st: state) (atom: node option) (minimum: int) (maximum: int) (op_at: int): node =
  match atom with
  | None -> fail e_missing_repeat_argument op_at
  | Some a ->
     if byte_is st st.pos '?' then st.pos <- st.pos + 1
     else if byte_is st st.pos '+' then fail_here st e_atomic;
     if is_repeat_byte (byte_at st st.pos) || is_counted_repeat st st.pos then fail_here st e_bad_repeat;
     Repeat (a, minimum, maximum)

and parse_atom (st: state) (depth: int): node option =
  let at = st.pos in
  let c = byte_at st at in
  if c = 40 then parse_group st depth
  else if c = 91 then Some (parse_class st)
  else if c = 46 || c = 94 || c = 36 then (st.pos <- at + 1; Some Leaf)
  else if c = 92 then Some (parse_escape st)
  else if is_repeat_byte c then fail e_missing_repeat_argument at
  else if c = 123 && is_counted_repeat st at then fail e_missing_repeat_argument at
  else begin
    let (_, width) = pattern_rune st at in
    if width = 0 then fail e_bad_utf8 at;
    st.pos <- at + width;
    Some Leaf
  end

and parse_group (st: state) (depth: int): node option =
  let opening = st.pos in
  st.pos <- opening + 1;
  let capture = ref true in
  if byte_is st st.pos '*' then fail e_pcre_only opening;
  let flags_only =
    if byte_is st st.pos '?' then begin
      st.pos <- st.pos + 1;
      let c = byte_at st st.pos in
      if c = 58 then (st.pos <- st.pos + 1; capture := false; false)
      else if c = 61 || c = 33 then fail e_lookaround opening
      else if c = 62 then fail e_atomic opening
      else if is_pcre_group_start c then fail e_pcre_only opening
      else if c = 80 then begin
        st.pos <- st.pos + 1;
        if byte_is st st.pos '=' then fail e_backreference opening;
        if byte_is st st.pos '>' then fail e_pcre_only opening;
        if not (byte_is st st.pos '<') then fail e_bad_group opening;
        if not (skip_group_name st) then fail e_bad_group opening;
        false
      end else if c = 60 then begin
        if byte_is st (st.pos + 1) '=' || byte_is st (st.pos + 1) '!' then fail e_lookaround opening;
        if not (skip_group_name st) then fail e_bad_group opening;
        false
      end else begin
        let result = parse_flags st in
        if result = 1 then true else (capture := false; false)
      end
    end else false
  in
  if flags_only then None
  else begin
    let inner = parse_alternation st (depth + 1) in
    if not (byte_is st st.pos ')') then fail e_missing_paren opening;
    st.pos <- st.pos + 1;
    if !capture then Some (Capture inner) else Some inner
  end

(* How many instructions emitNode writes for a node, saturated just above
   the limit: the answer is compared with the limit and nothing else, and a
   pattern like ((a{1000}){1000}){1000} must not overflow on the way. *)
let cap (n: int): int = if n > program_limit then program_limit + 1 else n

let rec program_size (n: node): int =
  match n with
  | Leaf -> 1
  | Empty -> 0
  | Capture inner -> cap (2 + program_size inner)
  | Concat children -> List.fold_left (fun acc c -> cap (acc + program_size c)) 0 children
  | Alternate children ->
     let k = List.length children in
     cap ((List.fold_left (fun acc c -> cap (acc + program_size c)) 0 children) + (2 * (k - 1)))
  | Repeat (child, minimum, maximum) ->
     let s = program_size child in
     let copies = cap (minimum * s) in
     if maximum = none then cap (copies + 2 + s)
     else cap (copies + cap ((maximum - minimum) * (1 + s)))

(* None when Standard.Regex's compile would accept the pattern; otherwise
   its message. *)
let check (pattern: string): string option =
  let st = { text = pattern; pos = 0 } in
  try
    let root = parse_alternation st 0 in
    if st.pos < size st then fail_here st e_unexpected_paren;
    if cap (program_size root + 3) > program_limit then fail e_too_large 0;
    None
  with Refused (code, at) ->
    Some (message code at)
