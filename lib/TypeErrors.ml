(* Modified by Heiko Zimmermann for Hilde, 2026. *)
open Error
open ErrorText
open Identifier
open Type

let arithmetic_incompatible_types ~lhs ~rhs =
  hilde_raise (H 3008) TypeError [
    Text "Both operands to an arithmetic expression must be compatible types. The LHS has type ";
    Type lhs;
    Text " but the RHS has type ";
    Type rhs;
    Text "."
  ]

let arithmetic_not_numeric ty =
  hilde_raise (H 3009) TypeError [
    Text "Both operands of an arithmetic operator must be numeric types, but ";
    Type ty;
    Text " is not."
  ]

let negation_of_unsigned ty =
  hilde_raise (H 3010) TypeError [
    Text "Negation is not defined for the unsigned type ";
    Type ty;
    Text ". Its values have no opposite inside the type."
  ]

let negation_not_defined ty =
  (* Since the type rule asks the resolver first, the only type that
     reaches this branch is Float32: it has no TrappingNegation instance
     and no TrappingArithmetic instance either, so "no arithmetic" is the
     whole truth about it.  Every other type without an instance gets
     negation_no_instance below, which says the one thing the compiler
     actually knows. *)
  internal_raise [
    Text "Negation is not defined for the type ";
    Type ty;
    Text ": the type has no arithmetic."
  ]

let negation_no_instance ty =
  hilde_raise (H 3012) TypeError [
    Text "Negation is not defined for the type ";
    Type ty;
    Text ": it does not implement the typeclass ";
    Code "TrappingNegation";
    Text ". Give it an instance if it should have a negation."
  ]

let cannot_borrow_immutable_var_mutably (name: identifier) =
  hilde_raise (H 3018) TypeError [
      Text "Cannot borrow the variable ";
      Code (ident_string name);
      Text " mutably because the variable is immutable."
    ]

let cannot_borrow_param_mutably (name: identifier) (ty: ty) =
  hilde_raise (H 3019) TypeError [
      Text "Cannot borrow the variable ";
      Code (ident_string name);
      Text " mutably because it is a function parameter, and therefore immutable.";
      Text "\nYou can move it to a mutable local variable: ";
      Code ("var mut_" ^ (ident_string name) ^ ": " ^ (type_string ty) ^ " := " ^ (ident_string name) ^ ";");
    ]

let call_non_callable ty =
  hilde_raise (H 3020) TypeError [
    Text "The type ";
    Type ty;
    Text " is neither a function, method or function pointer, and cannot be called."
  ]

let call_wrong_arity ~name ~expected ~actual =
  hilde_raise (H 3021) TypeError [
    Text "The callable ";
    Code (ident_string name);
    Text " expects ";
    Text (string_of_int expected);
    Text " argument";
    Text (if expected = 1 then " " else "s ");
    Text "but ";
    Text (string_of_int actual);
    Text (if actual = 1 then " was " else " were ");
    Text "given."
  ]

let case_non_exhaustive () =
  hilde_raise (H 3022) TypeError [
    Text "Non-exhaustive case statement."
  ]

let case_non_public () =
  hilde_raise (H 3023) TypeError [
    Text "Union must be public or from the same module to be used in a case statement."
  ]

let case_non_union ty =
  hilde_raise (H 3024) TypeError [
    Text "The case expression has type ";
    Type ty;
    Text " which is not a union type."
  ]

let case_wrong_slots (binding_names, slot_names) =
  hilde_raise (H 3025) TypeError [
    Text "The set of slots (";
    Code (String.concat ", " binding_names);
    Text ") in the case statement doesn't match the set of slots in the union definition (";
    Code (String.concat ", " slot_names);
    Text ")."
  ]

let cast_different_references ~different_types ~different_regions =
  let text = match different_types, different_regions with
  | true, false -> [
      Text "Cannot cast a reference to one with a different underlying type."
    ]
  | false, true -> [
      Text "Cannot cast a reference to one with a different underlying region."
    ]
  | _ -> [
      Text "Cannot cast to a different region"
    ]
  in
  hilde_raise (H 3026) TypeError text

let cast_invalid ~target ~source =
  hilde_raise (H 3027) TypeError [
    Text "Cannot cast to ";
    Type target;
    Text " from ";
    Type source
  ]

let cast_write_ref_to_non_ref () =
  hilde_raise (H 3028) TypeError [
    Text "Write references can only be casted to a read reference."
  ]

let condition_not_boolean ~kind ~form ~ty =
  hilde_raise (H 3029) TypeError [
    Text "The condition in ";
    Code kind;
    Text "-";
    Text form;
    Text "s should be a boolean type, but is ";
    Type ty
  ]

let constructor_not_named declaration =
  hilde_raise (H 3030) TypeError [
    Text "Arguments to ";
    Text declaration;
    Text " constructor must be named."
  ]

let constructor_wrong_args declaration =
  hilde_raise (H 3031) TypeError [
    Text "Arguments to ";
    Text declaration;
    Text " constructor have the wrong names."
  ]

let dereference_non_reference ty =
  hilde_raise (H 3032) TypeError [
    Text "Only references can be dereferenced, but ";
    Type ty;
    Text " is not."
  ]

let dereference_non_free ty =
  hilde_raise (H 4013) LinearityError [
    Text "Cannot dereference non-free type ";
    Type ty
  ]

let destructure_non_record ty =
  hilde_raise (H 3033) TypeError [
    Text "The type ";
    Type ty;
    Text " cannot be destructured because it is not a record."
  ]

let destructure_not_public ty =
  hilde_raise (H 3034) TypeError [
    Text "The type ";
    Type ty;
    Text " is not a public record and so cannot be destructured."
  ]

let destructure_wrong_slots ty =
  hilde_raise (H 3035) TypeError [
    Text "The set of slots mentioned differs from the set of slots in ";
    Type ty;
  ]

let discard_linear universe =
  hilde_raise (H 3036) TypeError [
    Text "Cannot discard a value in the ";
    Code (universe_string universe);
    Text " universe."
  ]

(* The name says what is refused: not a value in a universe that
   forbids discarding -- that is discard_linear above -- but a RESULT, a
   value that carries a failure the caller was meant to look at. *)
let discard_result ty =
  hilde_raise (H 3037) TypeError [
    Text "The value of this expression has type ";
    Type ty;
    Text ", which carries a failure the caller is meant to look at, so it may not be thrown away. Handle it with a case statement, hand it to your own caller with the ? operator, or, if the failure really is to be ignored here, say so in the program with ignore(...)."
  ]

(* The ? operator. *)
let question_not_a_result ty =
  hilde_raise (H 3038) TypeError [
    Text "The ";
    Code "?";
    Text " operator hands a failure back to the caller, so it needs a value that can carry one: an ";
    Code "Option";
    Text " or an ";
    Code "Either";
    Text ". This expression has type ";
    Type ty;
    Text "."
  ]

let question_wrong_return_type ~operand ~rt =
  hilde_raise (H 3039) TypeError [
    Text "The ";
    Code "?";
    Text " operator returns the failure out of the enclosing function, so that function has to be able to carry it. The operand has type ";
    Type operand;
    Text " but the function returns ";
    Type rt;
    Text ". For an Option the function must return an Option; for an Either it must return an Either whose left type is the same."
  ]

let question_in_expression () =
  hilde_raise (H 3040) TypeError [
    Text "The ";
    Code "?";
    Text " operator may only stand as the whole right-hand side of a ";
    Code "let";
    Text " binding or as a whole statement. It is an early return out of the enclosing function, and it is written where that return is visible on its own line rather than buried inside a larger expression."
  ]

let expression_not_constant () =
  hilde_raise (H 3041) TypeError [
    Text "The expression is not a valid constant expression."
  ]

let for_bounds_non_integral ~bound ~ty =
  internal_raise [
    Text "The type of the ";
    Text bound;
    Text " value in the loop range is ";
    Type ty;
    Text " which is not ";
    Code "Index";
    Text "."
  ]

let embed_in_safe_module () =
  hilde_raise (H 2038) DeclarationError [
    Code "@embed";
    Text " pastes C straight into the generated program, and the compiler does not check that C. It is allowed only in a module that says so: write ";
    Code "pragma Unsafe_Module;";
    Text " above ";
    Code "module body";
    Text ", or move the ";
    Code "@embed";
    Text " into a module that already has the pragma."
  ]

let foreign_in_safe_module () =
  hilde_raise (H 2039) DeclarationError [
    Text "Can't declare a foreign function in a safe module."
  ]

let foreign_type_parameters () =
  hilde_raise (H 2040) DeclarationError [
    Text "Foreign functions can't have type parameters."
  ]

(* A C function gives a truth value as an int, and the result is declared
   in C as the type of Bool, one byte: whatever lies above the lowest byte
   is lost, so 256 would come back false. *)
let foreign_bool_result () =
  hilde_raise (H 2059) DeclarationError [
    Text "A foreign function can't return ";
    Code "Bool";
    Text ". C gives a truth value as an int, and a Bool would keep only its lowest byte, so 256 would be false.";
    Break;
    Text "Import the C result as ";
    Code "Int32";
    Text " and compare it with ";
    Code "/= 0";
    Text "."
  ]

let raise_not_named ~kind ~allowed =
  let allowed_text = if allowed = [] then "no kinds (no raises clause)" else String.concat ", " allowed in
  hilde_raise (H 3102) TypeError [
      Text "The raise of ";
      Code kind;
      Text " is not among the kinds this function's raises clause names: ";
      Code allowed_text;
      Text ".  Name the kind in the raises clause of this function, or raise a kind it names."
    ]

let raises_exceeded ~callee ~unmet ~allowed =
  let kinds = String.concat ", " unmet in
  let allowed_text = if allowed = [] then "no kinds (no raises clause)" else String.concat ", " allowed in
  hilde_raise (H 3103) TypeError [
      Text "The call of ";
      Code callee;
      Text " can end with the error kind(s) ";
      Code kinds;
      Text ", but this function's raises clause names: ";
      Code allowed_text;
      Text ".  A function may call only the functions whose error kinds it has named; name the missing kind(s) in the raises clause of this function, or take the call out."
    ]

let raises_as_pointer ~name =
  hilde_raise (H 3104) TypeError [
      Text "The function ";
      Code name;
      Text " has a raises clause and cannot be taken as a function pointer.";
      Break;
      Text "A call through a pointer has no signature the compiler can hold against the caller's raises clause.  Call the function directly."
    ]

let fun_pointer_named_args () =
  hilde_raise (H 3043) TypeError [
    Text "You can't call a function pointer with a named argument list, because function pointers don't preserve parameter names, so we wouldn't know how to assign arguments to parameters."
  ]

let fun_invalid_pragmas () =
  hilde_raise (H 2041) DeclarationError [
    Text "Only import and export pragmas are allowed inside functions."
  ]

let if_inequal ~lhs ~rhs =
  hilde_raise (H 3044) TypeError [
    Text "The branches of the ";
    Code "if";
    Text "-expression have different types: ";
    Type lhs;
    Text " and ";
    Type rhs
  ]

let logical_operands_not_boolean ~operator ~types = match types with
| [ty] ->
    hilde_raise (H 3045) TypeError [
      Text "The operand of a ";
      Text operator;
      Text " operator must be a boolean expression, but it has the type ";
      Type ty
    ]
| [first; second] ->
    hilde_raise (H 3046) TypeError [
      Text "Both operands of a ";
      Text operator;
      Text " operator must be boolean expressions, but they have types ";
      Type first;
      Text " and ";
      Type second
    ]
  | _ ->
    internal_raise [
      Text "All operands of a logical operator must be boolean expressions."
    ]

let no_such_slot ~type_name ~slot_name =
  hilde_raise (H 3049) TypeError [
    Text "The type ";
    Code (ident_string type_name);
    Text " has no slot with name ";
    Code (ident_string slot_name)
  ]

let instance_for_builtin_type ty =
  (* Hilde: the fourth orphan case, when the foreign type is one the
     language itself owns.  "typeclass and type are both foreign" is true
     but unhelpful here -- the reader did not think of Nat8 as foreign. *)
  hilde_raise (H 6037) GenericError [
    Text "Orphan rule broken: ";
    Type ty;
    Text " is a built-in type. It belongs to the language and not to the module that names it, so it is foreign in every module except Hilde.Pervasive and Hilde.Memory, and the typeclass is foreign here too. Define a type of your own and give that the instance."
  ]

let overlapping_instances ~existing ~added ~ty =
  (* Hilde: uniqueness of instances is program-wide, so the two instances
     that overlap are usually in different modules.  "Instance overlaps."
     on its own does not say where to look, so both modules are named. *)
  hilde_raise (H 6038) GenericError [
    Text "Instance overlaps: the typeclass already has an instance for ";
    Type ty;
    Text ". The existing instance is in the module ";
    Code existing;
    Text ", the new one is in ";
    Code added;
    Text ". In one program a type may have at most one instance of a typeclass, whichever module declares it."
  ]

let no_suitable_instance ~typeclass ~ty =
  hilde_raise (H 3050) TypeError [
    Text "The typeclass ";
    Code (ident_string typeclass);
    Text " has no instance which matches for ";
    Type ty
  ]

let path_not_public ~type_name ~slot_name =
  hilde_raise (H 3052) TypeError [
    Text "The slot ";
    Code (ident_string slot_name);
    Text " is not publically visible in the type ";
    Code (ident_string type_name);
    Text " and so cannot be read."
  ]

let path_not_record ty =
  hilde_raise (H 3053) TypeError [
    Text "Cannot take a path of the type ";
    Type ty;
    Text " because it is not a record."
  ]

let slot_wrong_type ~name ~expected ~actual =
  (* Region<N> is the region of a borrow of a local variable, which has no
     name in the source. *)
  let anonymous: bool =
    let s = type_string expected in
    let rec has i =
      (i + 7 <= String.length s) && ((String.sub s i 7 = "Region<") || has (i + 1))
    in
    has 0
  in
  hilde_raise (H 3054) TypeError ([
    Text "The slot ";
    Code (ident_string name);
    Text " should have type ";
    Type expected;
    Text " but is declared to have type ";
    Type actual
  ] @ (if anonymous then [
    Break;
    Text "The region of a borrow of a local variable has no name in the source, so a span or reference taken from it cannot be bound with a declared type. Use the value inside the expression that borrows, or take the variable as a parameter of a function, ";
    Code "c: &[T, R]";
    Text ", where its region is R."
  ] else []))

(* ty is the type left open, with the type parameters no argument decided;
   the message names both, so that the reader sees what to write down. *)
let unconstrained_generic_function name ty =
  let open_names: string list =
    List.map
      (fun (TypeVariable (n, _, _, _)) -> ident_string n)
      (TypeVarSet.TypeVarSet.elements (TypeSystem.type_variables ty))
  in
  let params: text_elem list =
    List.concat
      (List.mapi (fun i n -> if i = 0 then [Code n] else [Text ", "; Code n]) open_names)
  in
  hilde_raise (H 3055) TypeError ([
    Code (ident_string name);
    Text " is generic but unconstrained, so its type is ambiguous: its type is ";
    Type ty;
    Text ", and nothing here decides "
  ] @ params @ [
    Text ".";
    Break;
    Text "Give the value a type: declare the variable it goes into with one, or cast it."
  ])

let unconstrained_type_parameter ~typeclass ~typaram =
  hilde_raise (H 3056) TypeError [
    Text "The type parameter ";
    Code (ident_string typaram);
    Text " does not implement the type class ";
    Code (ident_string typeclass);
    Break;
    Text "Consider adding a constraint to the type parameter."
  ]

let unknown_name ~kind ~name =
  hilde_raise (H 6039) GenericError [
    Text "I can't find a ";
    Text kind;
    Text " named ";
    Code (ident_string name);
    Text "."
  ]

let cannot_assign_to_constant _ =
  internal_raise [
      Text "Cannot assign a value to a constant."
    ]

let cannot_assign_to_parameter _ =
  hilde_raise (H 6041) GenericError [
      Text "Cannot assign a value to a function parameter."
    ]

let cant_assign_to_immutable_var (name: identifier) =
  hilde_raise (H 6042) GenericError [
      Text "Cannot assign a value to ";
      Code (ident_string name);
      Text " because it is immutable."
    ]

let ref_transform_needs_ref ty =
  hilde_raise (H 6043) GenericError [
      Text "The head of a reference transform expression must be of a reference type, but I got ";
      Type ty;
      Text ".";
      Break;
      Text "A path into a value is borrowed through a reference to the whole value: write a function that takes ";
      Code "r: &[T, R]";
      Text " and returns ";
      Code "&(r->slot)";
      Text ", and call it with ";
      Code "&value";
      Text "."
    ]

let embed_names_import ~(c: string) ~(hilde: identifier) =
  hilde_raise (H 3106) TypeError [
      Text "The C text of this @embed names ";
      Code c;
      Text ", a function the programme imports through pragma Foreign_Import as ";
      Code (ident_string hilde);
      Text ". The compiler declares an imported function under a name of its own, so in C the name ";
      Code c;
      Text " is not declared. Call ";
      Code (ident_string hilde);
      Text " in Hilde instead."
    ]

let comparison_symbol (op: Common.comparison_operator): string =
  match op with
  | Common.Equal -> "=" | Common.NotEqual -> "/="
  | Common.LessThan -> "<" | Common.LessThanOrEqual -> "<="
  | Common.GreaterThan -> ">" | Common.GreaterThanOrEqual -> ">="

(* A comparison whose operands have a type that C cannot compare with its
   own operators: a span, a record or a union. *)
let comparison_not_defined (op: Common.comparison_operator) (ty: ty) =
  let sym = comparison_symbol op in
  let hint = match ty with
    | Span _ | SpanMut _ ->
       [Text "Compare the bytes of two texts with "; Code "Standard.Text.equal"; Text "."]
    | _ ->
       [Text "Write a function that compares the values slot by slot."]
  in
  hilde_raise (H 3107) TypeError ([
      Text "The operator ";
      Code sym;
      Text " compares numbers, Bool, Unit, references, addresses and pointers, but its operands have the type ";
      Type ty;
      Text ".";
      Break
    ] @ hint)

(* A method of a typeclass whose parameters and result do not name the
   parameter of its class: a call could not tell which instance it means,
   and the type checker would find no binding for the parameter at the
   call.  It is refused where it is declared. *)
let method_without_class_parameter (method_name: identifier) (typaram_name: identifier) =
  hilde_raise (H 3111) TypeError [
      Text "The method ";
      Code (ident_string method_name);
      Text " names the parameter ";
      Code (ident_string typaram_name);
      Text " of its typeclass neither in a parameter nor in its result, so no call can tell which instance it means.";
      Break;
      Text "Give it a parameter of that type, a witness whose value it need not read."
    ]

(* The same for a comparison of values of a type variable, found where the
   generic function is instantiated: ty is the type the variable stands
   for in that use, a span, a record or a union. *)
let comparison_instance_not_defined (op: Common.comparison_operator) (ty: ty) =
  hilde_raise (H 3108) TypeError [
      Text "The operator ";
      Code (comparison_symbol op);
      Text " compares numbers, Bool, Unit, references, addresses and pointers, but in a use of a generic function its operands have the type ";
      Type ty;
      Text ".";
      Break;
      Text "Take a function that compares two values as an argument, or a typeclass."
    ]

(* A call of a function that another module declares and this one does not
   import.  An interface that names it in a requires or an ensures imports
   it itself: what the body imports does not reach the interface. *)
let callable_not_imported (name: identifier) (mn: module_name) =
  hilde_raise (H 6060) GenericError [
      Text "I can't find a callable named ";
      Code (ident_string name);
      Text " here. The module ";
      Code (mod_name_string mn);
      Text " declares one; import it, as in ";
      Code ("import " ^ (mod_name_string mn) ^ " (" ^ (ident_string name) ^ ");");
      Text ". A module interface imports what its own contracts call, apart from its body."
    ]

(* A path, an index or a slot, on a constant of the module: a path is read
   through a borrow, and a constant cannot be borrowed. *)
let path_of_constant (name: identifier) =
  hilde_raise (H 6059) GenericError [
      Code (ident_string name);
      Text " is a constant of the module, and an index or a slot is taken through a variable, which a constant is not. Bind the constant to a local first, as in ";
      Code ("let local: T := " ^ (ident_string name) ^ ";");
      Text ", and index the local."
    ]

let var_collides_with_decl (name: identifier) =
  hilde_raise (H 6045) GenericError [
      Text "The variable ";
      Code (ident_string name);
      Text " collides with the name of a declaration."
    ]

let cant_access_slot_not_record (slot_name: identifier) (ty: ty) =
  hilde_raise (H 3057) TypeError [
      Text "Can't access the slot ";
      Code (ident_string slot_name);
      Text " because the type ";
      Type ty;
      Text " is not a record."
    ]

let cant_index_not_span (ty: ty) =
  hilde_raise (H 3058) TypeError [
      Text "I can't use the array indexing operator here, because the type ";
      Type ty;
      Text " is not a span."
    ]

(* A literal pattern handed to Standard.Regex's compile
   that the module would refuse at run time.  The message is the module's
   own, from lib/RegexCheck.ml. *)
let regex_pattern_refused (message: string) =
  hilde_raise (H 3059) TypeError [
      Text "This pattern can never compile: ";
      Code message;
      Text ".  Standard.Regex's compile would return that as its Left when the programme runs; a literal pattern is checked now."
    ]
