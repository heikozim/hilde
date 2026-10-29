The negative control that the older rule is untouched: a discarded LINEAR
value is still refused, and refused by the type checker through
Errors.discard_linear, not by the parser.  A syntax error would be no
control: it proves only that the parser refuses something.
