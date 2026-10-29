(* Modified by Heiko Zimmermann for Hilde, 2026. *)
open Error
open Span

(* makes strings safe to put in html*)
val sanatize_string : string -> string

(* The line of source numbered line_num with the part the span covers
   wrapped for highlighting; the line unchanged when the span does not
   reach it.  Columns beyond the line are held to its end, so a span that
   does not fit the line never raises. *)
val line_err : string -> int -> span option -> string

(* returns a string of the html representation of the error *)
val render_error_to_html : hilde_error -> string

(* writes the html representation of the error to error.html, only after --dump-calltree *)
val html_error_dump : hilde_error -> unit
