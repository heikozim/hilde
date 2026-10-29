(*
   Part of Hilde, under the Apache License v2.0 with LLVM Exceptions.
   See LICENSE file for details.

   SPDX-FileCopyrightText: 2026 Heiko Zimmermann
   SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
*)
(* hilde guard: the attack surface of a programme, read from its
   monomorphic code after a whole compilation.  It lists the modules marked
   unsafe, the C libraries and headers the programme names, every foreign
   function with its C name, every C expression pasted in with @embed, and
   the exported functions; and for each foreign function and each embed,
   whether the programme can reach it from its roots.

   Reachability is a walk over the calls of the monomorphic code.  A call, a
   method call and a function taken as a pointer are each an edge; taking a
   pointer counts as reaching the function, since the call through it is not
   known.  The roots are the entrypoint, the exported functions and every
   function a constant's value calls; without an entrypoint and without an
   export every function is a root.  So the walk may count too much as
   reachable, never too little. *)
open Id
open Identifier
open Stages.Mtast
open Env
open EnvTypes
open EnvUtils
open Error

type node =
  | NodeDecl of decl_id
  | NodeMono of mono_id
  | NodeMethod of ins_meth_id

(* The functions a statement calls or takes the address of, and the C text
   of each embed in it, both in the order they are written. *)
let references (body: mstmt): node list * string list =
  let calls = ref [] and embeds = ref [] in
  let add n = calls := n :: !calls in
  let rec stmt (s: mstmt): unit =
    match s with
    | MSkip | MUnreachable -> ()
    | MLet (_, _, b) -> stmt b
    | MDestructure (_, e, b) -> expr e; stmt b
    | MAssign (a, b) -> expr a; expr b
    | MAssignVar (_, e) | MInitialAssign (_, e) -> expr e
    | MIf (c, a, b) -> expr c; stmt a; stmt b
    | MCase (e, whens, _) -> expr e; List.iter (fun (MTypedWhen (_, _, b)) -> stmt b) whens
    | MSwitch (e, arms, other) -> expr e; List.iter (fun (_, b) -> stmt b) arms; stmt other
    | MWhile (c, b) -> expr c; stmt b
    | MFor (_, a, b, body) -> expr a; expr b; stmt body
    | MBorrow { body; _ } -> stmt body
    | MBlock (a, b) -> stmt a; stmt b
    | MDiscarding e | MReturn e -> expr e
    | MRaise _ -> ()
    | MLetTmp (_, _, e) | MAssignTmp (_, e) -> expr e
  and expr (e: mexpr): unit =
    match e with
    | MNilConstant | MBoolConstant _ | MIntConstant _ | MFloatConstant _
    | MStringConstant _ | MConstVar _ | MParamVar _ | MLocalVar _
    | MTemporary _ | MSizeOf _ -> ()
    | MGenericFunVar (id, _) -> add (NodeMono id)
    | MConcreteFunVar (id, _) -> add (NodeDecl id)
    | MConcreteFuncall (id, _, args, _) -> add (NodeDecl id); List.iter expr args
    | MGenericFuncall (id, args, _) -> add (NodeMono id); List.iter expr args
    | MConcreteMethodCall (id, _, args, _) -> add (NodeMethod id); List.iter expr args
    | MGenericMethodCall (_, id, args, _) -> add (NodeMono id); List.iter expr args
    | MFptrCall (_, args, _) -> List.iter expr args
    | MCast (a, _) | MNegation a | MDeref a | MTypecast (a, _)
    | MSlotAccessor (a, _, _) | MPointerSlotAccessor (a, _, _) -> expr a
    | MComparison (_, a, b) | MConjunction (a, b) | MDisjunction (a, b)
    | MArrayIndex (a, b, _) | MSpanIndex (a, b, _) -> expr a; expr b
    | MIfExpression (a, b, c) -> expr a; expr b; expr c
    | MRecordConstructor (_, slots) -> List.iter (fun (_, v) -> expr v) slots
    | MUnionConstructor (_, _, slots) -> List.iter (fun (_, v) -> expr v) slots
    | MEmbed (_, text, args) -> embeds := text :: !embeds; List.iter expr args
  in
  stmt body;
  (List.rev !calls, List.rev !embeds)

(* A foreign function: its node, the module that declares it, its name in
   Hilde and its name in C. *)
type foreign = {
    node: node;
    home: module_name;
    name: identifier;
    c_name: string;
  }

(* Where an embed stands: in the body of a function, or in the value of a
   constant. *)
type site =
  | InBody of node
  | InConstant of decl_id

(* The calls of a whole programme: the edges of every function with a body,
   the embeds of each, the foreign functions, and what the values of the
   constants call. *)
type graph = {
    edges: (node, node list) Hashtbl.t;
    embeds: (site * string) list;
    foreigns: foreign list;
    bodies: node list;
    constant_calls: node list;
  }

let graph_of (modules: mono_module list): graph =
  let edges = Hashtbl.create 1024 in
  let embeds = ref [] and foreigns = ref [] and bodies = ref [] and constant_calls = ref [] in
  let body (n: node) (s: mstmt): unit =
    let (calls, texts) = references s in
    Hashtbl.replace edges n calls;
    bodies := n :: !bodies;
    List.iter (fun t -> embeds := (InBody n, t) :: !embeds) texts
  in
  let decl (home: module_name) (d: mdecl): unit =
    match d with
    | MFunction (id, _, _, _, s) -> body (NodeDecl id) s
    | MFunctionMonomorph (id, _, _, s) -> body (NodeMono id) s
    | MMethodMonomorph (id, _, _, s) -> body (NodeMono id) s
    | MConcreteInstance (_, _, _, methods) ->
       List.iter (fun (MConcreteMethod (id, _, _, _, s)) -> body (NodeMethod id) s) methods
    | MForeignFunction (id, name, _, _, c_name) ->
       foreigns := { node = NodeDecl id; home; name; c_name } :: !foreigns
    | MConstant (id, _, _, e) ->
       let (calls, texts) = references (MDiscarding e) in
       constant_calls := !constant_calls @ calls;
       List.iter (fun t -> embeds := (InConstant id, t) :: !embeds) texts
    | MRecord _ | MRecordMonomorph _ | MUnion _ | MUnionMonomorph _ -> ()
  in
  List.iter (fun (MonoModule (home, decls)) -> List.iter (decl home) decls) modules;
  { edges; embeds = List.rev !embeds; foreigns = List.rev !foreigns;
    bodies = List.rev !bodies; constant_calls = !constant_calls }

(* Every node the roots reach, the roots included. *)
let reachable (g: graph) (roots: node list): (node, unit) Hashtbl.t =
  let seen = Hashtbl.create 1024 in
  let rec visit (pending: node list): unit =
    match pending with
    | [] -> ()
    | n :: rest ->
       if Hashtbl.mem seen n then visit rest
       else begin
         Hashtbl.replace seen n ();
         let next = match Hashtbl.find_opt g.edges n with Some l -> l | None -> [] in
         visit (next @ rest)
       end
  in
  visit roots;
  seen

(* --- The report --------------------------------------------------------- *)

let decl_home (env: env) (id: decl_id): string =
  match get_decl_by_id env id with
  | Some d -> mod_name_string (module_name_from_id env (decl_mod_id d))
  | None -> "?"

let decl_label (env: env) (id: decl_id): string =
  match get_decl_by_id env id with
  | Some d ->
     let name = match decl_name d with Some i -> ident_string i | None -> "?" in
     decl_home env id ^ "." ^ name
  | None -> "?"

(* A method as its instance's module and its name, and that module. *)
let method_place (env: env) (id: ins_meth_id): string * string =
  match get_instance_method env id with
  | Some (InsMethRec { name; instance_id; _ }) ->
     (decl_home env instance_id ^ "." ^ ident_string name, decl_home env instance_id)
  | None -> ("?", "?")

(* A function as its module and its name, and that module. *)
let node_place (env: env) (n: node): string * string =
  match n with
  | NodeDecl id -> (decl_label env id, decl_home env id)
  | NodeMethod id -> method_place env id
  | NodeMono id ->
     (match get_monomorph env id with
      | Some (MonoFunction { function_id; _ }) -> (decl_label env function_id, decl_home env function_id)
      | Some (MonoInstanceMethod { method_id; _ }) -> method_place env method_id
      | _ -> ("?", "?"))

(* The roots of the walk, and how they were chosen, in words. *)
let roots_of (env: env) (g: graph) (entry: decl_id option): node list * string =
  let exports = List.map (fun (id, _) -> NodeDecl id) (get_export_functions env) in
  let export_monos =
    List.concat_map
      (fun n ->
        match n with
        | NodeMono id ->
           (match get_monomorph env id with
            | Some (MonoFunction { function_id; _ })
                 when List.exists (fun (e, _) -> e = function_id) (get_export_functions env) -> [n]
            | _ -> [])
        | _ -> [])
      g.bodies
  in
  match entry, exports with
  | None, [] -> (g.bodies @ g.constant_calls, "no entrypoint and no export, so every function")
  | Some id, _ -> (NodeDecl id :: exports @ export_monos @ g.constant_calls,
                   "the entrypoint, the exported functions and the values of the constants")
  | None, _ -> (exports @ export_monos @ g.constant_calls,
                "the exported functions and the values of the constants")

let one_line (text: string): string =
  String.map (fun ch -> if ch = '\n' || ch = '\r' || ch = '\t' then ' ' else ch) text

let words (l: string list): string =
  match l with [] -> "none" | _ -> String.concat " " l

(* The modules built into the compiler, which every programme has. *)
let built_in (home: string): bool =
  String.length home > 6 && String.sub home 0 6 = "Hilde."

(* Lines sorted, each distinct one once, with its count when it stands more
   than once: a generic function has one body for each set of types it is
   used with. *)
let grouped (lines: string list): string list =
  let rec go (l: string list): string list =
    match l with
    | [] -> []
    | x :: rest ->
       let same = List.length (List.filter (fun y -> y = x) rest) in
       let rest = List.filter (fun y -> y <> x) rest in
       (if same = 0 then x else Printf.sprintf "%s (%d times)" x (same + 1)) :: go rest
  in
  go (List.sort compare lines)

let starts_reachable (line: string): bool =
  String.length line > 11 && String.sub line 2 9 = "reachable"

(* Vulnerabilities.  An
   advisory in the OSV format names a C library as its package, the ranges of
   its versions it affects, and the C functions through which it is reached,
   in the place Go's database puts them: affected[].ecosystem_specific
   .imports[].symbols.  A programme is told of an advisory only when it links
   the library, its version was given and lies in a range, and it reaches one
   of the functions. *)
type advisory = {
    adv_id: string;
    adv_package: string;
    adv_ranges: (int list * int list option) list;
    adv_symbols: string list;
    adv_summary: string;
  }

(* A version as the numbers between its dots: "3.39.2" is [3; 39; 2].  None
   when it is anything else. *)
let version_parts (v: string): int list option =
  let parts = String.split_on_char '.' v in
  let digits (p: string): bool =
    p <> "" && String.length p <= 9 && String.for_all (fun ch -> ch >= '0' && ch <= '9') p
  in
  if parts <> [] && List.for_all digits parts then Some (List.map int_of_string parts) else None

(* Numbers compared one by one, a missing one counting as 0: 3.39 = 3.39.0. *)
let rec compare_versions (a: int list) (b: int list): int =
  match a, b with
  | [], [] -> 0
  | x :: a', [] -> if x <> 0 then compare x 0 else compare_versions a' []
  | [], y :: b' -> if y <> 0 then compare 0 y else compare_versions [] b'
  | x :: a', y :: b' -> if x <> y then compare x y else compare_versions a' b'

let affects (version: int list) (adv: advisory): bool =
  List.exists
    (fun (introduced, fixed) ->
      compare_versions introduced version <= 0
      && (match fixed with None -> true | Some f -> compare_versions version f < 0))
    adv.adv_ranges

let database_error (source: string) (why: string): 'a =
  hilde_raise (H 1031) CliError [
      Text "The vulnerability database ";
      Code source;
      Text (" cannot be read: " ^ why ^ ".")
    ]

(* The advisories of one OSV record, one for each affected package. *)
let advisories_of_record (source: string) (json: Yojson.Basic.t): advisory list =
  (* A field of an object; null for a field that is not there and for a
     value that is not an object, as OSV leaves optional parts out. *)
  let member (name: string) (j: Yojson.Basic.t): Yojson.Basic.t =
    match j with
    | `Assoc fields -> (match List.assoc_opt name fields with Some v -> v | None -> `Null)
    | _ -> `Null
  in
  let text (j: Yojson.Basic.t): string =
    match j with `String s -> s | _ -> database_error source "a field that should be a string is not"
  in
  let list_of (j: Yojson.Basic.t): Yojson.Basic.t list =
    match j with `List l -> l | `Null -> [] | _ -> database_error source "a field that should be a list is not"
  in
  let version (s: string): int list =
    if s = "0" then [0] else
      match version_parts s with
      | Some v -> v
      | None -> database_error source ("the version " ^ s ^ " is not numbers separated by dots")
  in
  match json with
  | `Assoc _ ->
     let id = text (member "id" json) in
     let summary = (match member "summary" json with `String s -> s | _ -> "") in
     List.map
       (fun affected ->
         let package = text (member "name" (member "package" affected)) in
         let ranges =
           List.concat_map
             (fun range ->
               let events = list_of (member "events" range) in
               let rec pairs (open_at: int list option) (l: Yojson.Basic.t list) =
                 match l with
                 | [] -> (match open_at with Some i -> [(i, None)] | None -> [])
                 | e :: rest ->
                    (match member "introduced" e, member "fixed" e with
                     | `String i, _ -> pairs (Some (version i)) rest
                     | _, `String f ->
                        (match open_at with
                         | Some i -> (i, Some (version f)) :: pairs None rest
                         | None -> pairs None rest)
                     | _ -> pairs open_at rest)
               in
               pairs None events)
             (list_of (member "ranges" affected))
         in
         let symbols =
           List.concat_map
             (fun imp -> List.map text (list_of (member "symbols" imp)))
             (list_of (member "imports" (member "ecosystem_specific" affected)))
         in
         { adv_id = id; adv_package = package; adv_ranges = ranges;
           adv_symbols = List.sort_uniq compare symbols; adv_summary = one_line summary })
       (list_of (member "affected" json))
  | _ -> database_error source "a record is not an object"

(* The advisories of a JSON text: one OSV record, or a list of them. *)
let advisories_of_string (source: string) (content: string): advisory list =
  let json =
    try Yojson.Basic.from_string content with
    | Yojson.Json_error why -> database_error source ("it is not JSON: " ^ one_line why)
  in
  match json with
  | `List records -> List.concat_map (advisories_of_record source) records
  | _ -> advisories_of_record source json

(* The advisories of a file, or of every file ending in .json in a
   directory, in the order of their names. *)
let read_database (path: string): advisory list =
  let read_file (file: string): string =
    try In_channel.with_open_bin file In_channel.input_all with
    | Sys_error why -> database_error path why
  in
  if Sys.file_exists path && Sys.is_directory path then
    let names =
      List.sort compare
        (List.filter (fun n -> Filename.check_suffix n ".json") (Array.to_list (Sys.readdir path)))
    in
    List.concat_map (fun n -> advisories_of_string path (read_file (Filename.concat path n))) names
  else if Sys.file_exists path then
    advisories_of_string path (read_file path)
  else
    database_error path "there is no such file or directory"

(* What the vulnerability part of the report is given: the advisories, where
   they came from, and the versions the programme's libraries were given. *)
type vulnerability_check = {
    advisories: advisory list;
    source: string;
    versions: (string * string) list;
  }

let range_text (adv: advisory): string =
  String.concat ", "
    (List.map
       (fun (i, f) ->
         let dotted v = String.concat "." (List.map string_of_int v) in
         match f with
         | Some f -> dotted i ^ " to before " ^ dotted f
         | None -> dotted i ^ " on")
       adv.adv_ranges)

(* The lines of the vulnerability part and the number of advisories reached. *)
let vulnerability_lines (check: vulnerability_check) (libraries: string list)
      (reached_names: string list): string list * int =
  let linked = List.filter (fun a -> List.mem a.adv_package libraries) check.advisories in
  let packages = List.sort_uniq compare (List.map (fun a -> a.adv_package) linked) in
  let status =
    List.map
      (fun p ->
        let mine = List.filter (fun a -> a.adv_package = p) linked in
        match List.assoc_opt p check.versions with
        | Some v -> Printf.sprintf "  %s %s: %d advisories checked" p v (List.length mine)
        | None -> Printf.sprintf "  %s: no version given, %d advisories not checked" p (List.length mine))
      packages
  in
  let in_range =
    List.filter
      (fun a ->
        match List.assoc_opt a.adv_package check.versions with
        | Some v -> (match version_parts v with Some v -> affects v a | None -> false)
        | None -> false)
      linked
  in
  let no_function = List.filter (fun a -> a.adv_symbols = []) in_range in
  let reached =
    List.filter_map
      (fun a ->
        match List.filter (fun s -> List.mem s reached_names) a.adv_symbols with
        | [] -> None
        | hit -> Some (a, hit))
      in_range
  in
  let lines =
    List.sort compare
      (List.map
         (fun (a, hit) ->
           Printf.sprintf "  reached  %s  %s %s (affected: %s) through %s: %s" a.adv_id a.adv_package
             (List.assoc a.adv_package check.versions) (range_text a) (String.concat " " hit) a.adv_summary)
         reached)
  in
  let unreached = List.length in_range - List.length reached - List.length no_function in
  ([ Printf.sprintf "vulnerabilities: %d advisories in %s, %d of them for the libraries linked"
       (List.length check.advisories) check.source (List.length linked) ]
   @ status @ lines
   @ [ Printf.sprintf "vulnerabilities reached: %d; in the versions given but not reached: %d; naming no function: %d"
         (List.length reached) unreached (List.length no_function) ],
   List.length reached)

(* The report as lines of text, each part sorted, so that the same
   programme gives the same report. *)
(* --- Capabilities --------------------------------------------------------- *)

(* A package of the build, from its hilde.toml: its module prefix, the
   capabilities it declares, and the file that declares them. *)
type package_rule = {
    prefix: string;
    declared: string list;
    manifest: string;
  }

(* Whether the module is the prefix or below it. *)
let belongs (m: string) (p: string): bool =
  m = p || (String.length m > String.length p && String.sub m 0 (String.length p + 1) = p ^ ".")

(* The package a module belongs to: the one with the longest prefix. *)
let owner (packages: package_rule list) (m: string): package_rule option =
  List.fold_left
    (fun best p ->
      if belongs m p.prefix then
        match best with
        | Some b when String.length b.prefix >= String.length p.prefix -> best
        | _ -> Some p
      else best)
    None packages

(* What the modules of each package do that a package has to declare:
   unsafe for a module of its own with pragma Unsafe_Module, foreign for a
   foreign function of its own that the programme reaches, embed for an
   embed of its own that it reaches.  The standard library and the modules
   built into the compiler belong to no package and declare nothing.  The
   lines of the report, and how many capabilities are used undeclared. *)
let capability_lines (env: env) (modules: mono_module list) ~(entry: decl_id option)
      ~(unsafe: (module_name * string) list) ~(packages: package_rule list): string list * int =
  if packages = [] then ([], 0) else begin
    let g = graph_of modules in
    let (roots, _) = roots_of env g entry in
    let seen = reachable g roots in
    let used: (string * string, unit) Hashtbl.t = Hashtbl.create 16 in
    let note (m: string) (cap: string): unit =
      match owner packages m with
      | Some p -> Hashtbl.replace used (p.prefix, cap) ()
      | None -> ()
    in
    List.iter (fun (m, _) -> note (mod_name_string m) "unsafe") unsafe;
    List.iter (fun f -> if Hashtbl.mem seen f.node then note (mod_name_string f.home) "foreign") g.foreigns;
    List.iter
      (fun (site, _) ->
        match site with
        | InBody n when Hashtbl.mem seen n -> note (snd (node_place env n)) "embed"
        | InBody _ -> ()
        | InConstant id -> note (decl_home env id) "embed")
      g.embeds;
    let caps = ["unsafe"; "foreign"; "embed"] in
    let sorted = List.sort (fun a b -> compare a.prefix b.prefix) packages in
    let undeclared = ref 0 in
    let lines =
      List.concat_map
        (fun p ->
          let uses = List.filter (fun c -> Hashtbl.mem used (p.prefix, c)) caps in
          let missing = List.filter (fun c -> not (List.mem c p.declared)) uses in
          undeclared := !undeclared + List.length missing;
          Printf.sprintf "  %s (%s): declares %s; uses %s" p.prefix p.manifest (words p.declared) (words uses)
          :: List.map
               (fun c ->
                 Printf.sprintf "  undeclared: %s uses %s, which %s does not name in [package] capabilities"
                   p.prefix c p.manifest)
               missing)
        sorted
    in
    (Printf.sprintf "capabilities of the packages: %d, undeclared: %d" (List.length packages) !undeclared :: lines,
     !undeclared)
  end

let report (env: env) (modules: mono_module list) ~(entry: decl_id option)
      ~(unsafe: (module_name * string) list) ~(libraries: string list)
      ~(headers: string list) ~(vulnerabilities: vulnerability_check option): string * int =
  let g = graph_of modules in
  let (roots, chosen) = roots_of env g entry in
  let seen = reachable g roots in
  let mark n = if Hashtbl.mem seen n then "reachable" else "unreached" in
  let reached_names =
    List.filter_map (fun f -> if Hashtbl.mem seen f.node then Some f.c_name else None) g.foreigns
  in
  let (vuln_lines, reached_count) =
    match vulnerabilities with
    | None -> ([], 0)
    | Some check -> vulnerability_lines check libraries reached_names
  in
  let foreigns =
    List.map
      (fun f ->
        (mod_name_string f.home,
         Printf.sprintf "  %s  %s.%s -> %s" (mark f.node) (mod_name_string f.home)
           (ident_string f.name) f.c_name))
      g.foreigns
  in
  let embeds =
    List.map
      (fun (site, text) ->
        let (state, where, home) =
          match site with
          | InBody n -> let (w, h) = node_place env n in (mark n, w, h)
          | InConstant id -> ("reachable", decl_label env id, decl_home env id)
        in
        (home, Printf.sprintf "  %s  %s: %s" state where (one_line text)))
      g.embeds
  in
  let own l = grouped (List.map snd (List.filter (fun (h, _) -> not (built_in h)) l)) in
  let inside l = List.map snd (List.filter (fun (h, _) -> built_in h) l) in
  let count l = List.length l and live l = List.length (List.filter starts_reachable l) in
  let foreign_lines = own foreigns and embed_lines = own embeds in
  let foreign_in = inside foreigns and embed_in = inside embeds in
  let export_lines =
    List.sort compare
      (List.map (fun (id, c) -> Printf.sprintf "  %s -> %s" (decl_label env id) c)
         (get_export_functions env))
  in
  let unsafe_lines =
    List.sort compare
      (List.map (fun (m, path) -> Printf.sprintf "  %s (%s)" (mod_name_string m) path) unsafe)
  in
  String.concat "\n"
    ([ "hilde guard: the attack surface of the programme";
       "roots: " ^ chosen;
       Printf.sprintf "unsafe modules on the command line: %d" (count unsafe_lines) ]
     @ unsafe_lines
     @ [ "libraries: " ^ words libraries;
         "headers: " ^ words headers;
         Printf.sprintf "foreign functions: %d, reachable: %d" (count foreign_lines) (live foreign_lines) ]
     @ foreign_lines
     @ [ Printf.sprintf "embeds: %d, reachable: %d" (count embed_lines) (live embed_lines) ]
     @ embed_lines
     @ [ Printf.sprintf "exported functions: %d" (count export_lines) ]
     @ export_lines
     @ [ Printf.sprintf "built into the compiler, not listed: foreign functions %d, reachable %d; embeds %d, reachable %d"
           (count foreign_in) (live foreign_in) (count embed_in) (live embed_in) ]
     @ vuln_lines)
  ^ "\n", reached_count
