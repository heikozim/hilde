(*
   Part of the Hilde project, under the Apache License v2.0 with LLVM Exceptions.
   See LICENSE file for details.

   SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

   Hilde is derived from the Austral project and extends it substantially.
   Modified by Heiko Zimmermann, 2026.
*)
open CliUtil
open CliParser
open CliEngine
open HtmlError
open Error

let rec main (args: string list): unit =
  (* --dump-calltree holds for every command and may stand anywhere; it is
     taken out here, so that no command's parser has to know it. *)
  let dump_flag = "--dump-calltree" in
  Reporter.dump_requested := List.mem dump_flag args;
  let args = List.filter (fun a -> a <> dump_flag) args in
  try
    main' args;
    exit 0
  with Hilde_error error ->
    Printf.eprintf "%s" (render_error_to_plain error);
    html_error_dump error;
    dump_and_die ()

and main' (args: string list): unit =
  let arglist: arglist = parse_args args in
  let cmd: cmd = parse arglist in
  exec cmd

and dump_and_die _: unit =
  Reporter.dump ();
  exit (-1)
