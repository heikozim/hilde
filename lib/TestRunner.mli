(*
   Part of the Hilde project, under the Apache License v2.0 with LLVM Exceptions.
   See LICENSE file for details.

   SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
*)
(** [hilde test]. *)
open CliParser

(** The modules of [hilde compile --modules]: those the given modules
    import, directly or through each other, found under [module_dirs] as
    [hilde test] finds them, put in front of [given]; [given] alone when
    [module_dirs] is empty.  A module that two directories both hold is
    refused with the error of [hilde test]. *)
val modules_for_compile : string list -> Compiler.module_source list -> Compiler.module_source list

(** One module that [hilde modules] lists: its name, the paths of its
    interface (none for a module of one body file) and body, and what it
    exports as pairs of a kind and a name, in the order written. *)
type module_listing = {
    listed_name: string;
    listed_interface: string option;
    listed_body: string;
    listed_exports: (string * string) list;
  }

(** The modules under [dirs], test files left out, sorted by name.  A
    module's exports are read from its interface, or from its body when it
    has none; a file that does not parse is raised as its parse error. *)
val list_modules : string list -> module_listing list

(** Find the test files under [paths] and the modules under [paths] and
    [module_dirs], build one programme per test file with [instrument], run
    each of its tests in a process of its own, and print a line per failed
    test, per test file and for the whole run.  With [emit_c] the C of each
    programme is written into that directory and nothing is built or run.
    With [contracts], every module under [paths] whose interface declares
    a function with a requires or an ensures gets a programme besides: each
    such function is called with inputs drawn from the seed that its
    requires accepts, and its ensures is checked.  Returns 0 when every test
    passed and every programme was built, 1 otherwise.  A refusal of the
    whole command line -- a path that is not there, no test file and no
    contract, an instrument this system cannot run -- is raised as a
    compiler error.  Each test file is built and run by a process of its own,
    so its C is the same whatever was built before it; with jobs above one
    that many at once, and the report and the C are the same; with test_jobs above one
    the tests of a file run that many at once, and with fresh_dirs each test
    starts in an empty working directory of its own.  With doc the example
    in the docstring of each exported function of the interfaces under the
    paths runs as a test; with json the lines of the run go to standard
    error and one JSON object with the counts to standard output. *)
val run :
  paths:string list ->
  module_dirs:string list ->
  instrument:instrument ->
  verbose:bool ->
  emit_c:string option ->
  contracts:contract_run option ->
  jobs:int ->
  test_jobs:int ->
  fresh_dirs:bool ->
  doc:bool ->
  json:bool ->
  mode:error_reporting_mode ->
  int
