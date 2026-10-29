# Hilde compiler errors

This page lists every error code the Hilde compiler in this repository
can report, with the message, what it means, and two examples: a module
that fails with exactly this code, and the correct form, which compiles.
The codes and their messages were read from the compiler's sources in
`lib/`; every example was taken from this page and compiled.

When the compiler refuses a program, it prints the kind of error, the
code, the module, the place in the source and a description. The code
names one place in the compiler that raises the error, so it stays the
same when the wording changes. The one exception is H9999, the code of
every internal error.

How to read an entry:

- The message is shown as the compiler printed it for the failing
  example: the kind of error on the first line, the description below.
- A code block that opens with ```` ```hilde fails H4012 ```` is a module
  that the compiler refuses with exactly that code.
- A code block that opens with ```` ```hilde ```` is the correct form. It
  compiles.
- A code block whose opening line says `file` and a path is a file beside
  the module above it, such as a template or a migration.
- A code block that opens with ```` ```sh command ```` is the command
  line the module above it is compiled with. Where there is none, it is
  `hilde compile` with the module's files, the modules of the standard
  library it imports, `--entrypoint=Example:main` and `--output`.
- Some codes cannot be reached by any program; their entries say so,
  and the overview marks them in its third column.

The catalog has 548 codes: 494 with examples and 54 that could not be
triggered; each of those 54 says why it stays.

## Overview

Every code in one table, in the order of the sections below. The last column
is the first sentence of the entry.

| Code | Section | Triggered | Meaning |
| --- | --- | --- | --- |
| H0001 | 1. Syntax | yes | The source text holds a character that starts no token. |
| H0003 | 1. Syntax | yes | A string literal is opened with a double quote and never closed. |
| H0004 | 1. Syntax | yes | A string in triple quotes is opened and never closed, so the file ends inside it. |
| H0005 | 1. Syntax | yes | The tokens do not form a program of the grammar. |
| H0006 | 1. Syntax | yes | The function pointer type Fn is written without type arguments. |
| H0007 | 1. Syntax | no | A character literal holds more than one character. |
| H0008 | 1. Syntax | yes | A reserved word stands where a name belongs. |
| H0009 | 1. Syntax | yes | An operator follows an operation without parentheses around it, such as a + b * c or a - b - c. |
| H0010 | 1. Syntax | yes | An index follows the closing bracket of a call. |
| H0011 | 1. Syntax | yes | A borrow takes a literal. |
| H0012 | 1. Syntax | yes | A field follows the closing bracket of a call. |
| H6018 | 1. Syntax | yes | In a string literal a backslash followed by white space joins two parts of the string, and the white space has to end in a second backslash. |
| H6058 | 1. Syntax | yes | A \u{...} escape in a string literal has no digits, more than six, a digit that is not hexadecimal, a code point above 10FFFF or a surrogate. |
| H2020 | 2. Types | yes | An instance names something that is not a type class. |
| H2021 | 2. Types | yes | An instance defines a method that its type class does not declare. |
| H2022 | 2. Types | yes | An instance leaves out a method of its type class. |
| H2023 | 2. Types | yes | The parameter of a type class is declared in the Region universe. |
| H2024 | 2. Types | yes | A record or union is declared in the Region universe. |
| H2025 | 2. Types | yes | An instance names a type class that is not declared in the module and not imported. |
| H2026 | 2. Types | yes | A type parameter of a generic function appears neither in its parameters nor in its return type, so no call could decide what it stands for. |
| H2031 | 2. Types | yes | A function or method ends without a return statement. |
| H2032 | 2. Types | yes | The argument of a generic instance uses the same type parameter twice. |
| H2033 | 2. Types | yes | A generic instance declares more type parameters than its argument uses. |
| H2034 | 2. Types | yes | The argument of an instance is a bare type parameter. |
| H2035 | 2. Types | yes | The argument of a generic instance mixes type parameters with concrete types. |
| H2037 | 2. Types | yes | A type parameter of a generic instance has the same name as the parameter of its type class. |
| H3003 | 2. Types | yes | One type parameter of a generic function would have to stand for two different types in the same call. |
| H3004 | 2. Types | yes | A type argument lies in a universe its type parameter does not allow, for example a Linear type where the parameter is Free. |
| H3007 | 2. Types | yes | An instance is given for a type whose universe the type class does not accept, for example a Linear type for a class over Free types. |
| H3008 | 2. Types | yes | The two operands of an arithmetic operator have different types. |
| H3009 | 2. Types | yes | An operand of an arithmetic operator is not a number. |
| H3010 | 2. Types | yes | A value of an unsigned type is negated. |
| H3012 | 2. Types | yes | A value is negated whose type has no instance of the type class TrappingNegation. |
| H3020 | 2. Types | yes | Something that is neither a function, a method nor a function pointer is called. |
| H3021 | 2. Types | yes | A function pointer is called with more or fewer arguments than its type has parameters. |
| H3022 | 2. Types | yes | A case that binds by name leaves out a case of the union. |
| H3023 | 2. Types | yes | A case looks into a union that another module exports only as an opaque type. |
| H3024 | 2. Types | yes | A case that binds by name is given a value of a named type that is not a union, such as a record. |
| H3025 | 2. Types | yes | A when that binds by name lists slots that the case of the union does not have, or leaves some out. |
| H3027 | 2. Types | yes | A value is converted to a type it cannot become. |
| H3029 | 2. Types | yes | The condition of an if, a while or an if expression is not a Bool. |
| H3030 | 2. Types | yes | A record or a case of a union is built with positional arguments. |
| H3031 | 2. Types | yes | A constructor is called with names that are not the slots of the record or of the case. |
| H3033 | 2. Types | yes | A let with braces takes apart a value of a built-in type, which has no slots. |
| H3034 | 2. Types | yes | A let with braces takes apart a record that another module exports only as an opaque type. |
| H3035 | 2. Types | yes | A let with braces names a set of slots that differs from the slots of the record. |
| H3037 | 2. Types | yes | An Option or an Either is thrown away by an expression statement. |
| H3038 | 2. Types | yes | The operator ? is applied to a value that is neither an Option nor an Either, so there is no failure to pass on. |
| H3039 | 2. Types | yes | The operator ? stands in a function that cannot pass the failure on: for an Option the function must return an Option, for an Either an Either with the same left type. |
| H3040 | 2. Types | yes | The operator ? stands inside a larger expression. |
| H3041 | 2. Types | yes | The value of a constant is not a constant expression, for example a function call. |
| H3043 | 2. Types | yes | A function pointer is called with named arguments. |
| H3044 | 2. Types | yes | The two branches of an if expression have different types. |
| H3045 | 2. Types | yes | The operand of not is not a Bool. |
| H3046 | 2. Types | yes | An operand of and or or is not a Bool. |
| H3049 | 2. Types | yes | A record has no slot of the given name. |
| H3050 | 2. Types | yes | A method of a type class is called with a value whose type has no instance of that class. |
| H3052 | 2. Types | yes | A slot is read from a record that another module exports only as an opaque type. |
| H3053 | 2. Types | yes | A slot is read from a value of a named type that is not a record, such as a union. |
| H3054 | 2. Types | yes | A binding in a case clause declares another type than the slot has. |
| H3055 | 2. Types | yes | A generic function whose type parameter appears only in its return type is called where no type is expected, so its type cannot be decided. |
| H3056 | 2. Types | yes | Inside a generic function a method of a type class is called on a value of a type parameter that lacks the constraint for that class. |
| H3057 | 2. Types | yes | A slot is read from a value of a built-in type, which has no slots. |
| H3058 | 2. Types | yes | The index operator s[i] is used on a value that is not a span. |
| H3060 | 2. Types | yes | A value has a different type from the one its place expects, for example in a return statement. |
| H3061 | 2. Types | yes | A generic function requires a type class of its type parameter, and the type given for it has no instance of that class. |
| H3062 | 2. Types | yes | An integer literal does not fit its type. |
| H3063 | 2. Types | yes | A type argument lies in a universe its type parameter does not accept, for example a Linear type for a parameter in Free. |
| H3064 | 2. Types | yes | A type name is not known: it is not declared in the module, not imported and not built in. |
| H3065 | 2. Types | yes | A case that binds by name is given a value that is neither a union nor a reference to a union. |
| H3071 | 2. Types | yes | A case uses patterns in one when and binds slots by name and type in another. |
| H3072 | 2. Types | yes | A case with patterns is given a reference. |
| H3073 | 2. Types | yes | A variable stands as a whole pattern in a case over a union. |
| H3074 | 2. Types | yes | A pattern can never be chosen, because the patterns before it already match every value it matches. |
| H3075 | 2. Types | yes | A case with patterns leaves out values. |
| H3076 | 2. Types | yes | An integer pattern stands where the value is not an integer. |
| H3077 | 2. Types | yes | A Bool pattern, true or false, stands where the value is not a Bool. |
| H3078 | 2. Types | yes | A literal or a bound of a range lies outside the type of the value. |
| H3079 | 2. Types | yes | The lower bound of a range is above its upper bound, so the range is empty. |
| H3080 | 2. Types | yes | A float literal stands as a pattern. |
| H3081 | 2. Types | yes | A string literal stands as a pattern. |
| H3082 | 2. Types | yes | The pattern _ stands where the value is not Free. |
| H3083 | 2. Types | yes | A variant pattern gives more or fewer sub-patterns than the variant has slots. |
| H3084 | 2. Types | yes | The alternatives of one when bind different variables. |
| H3085 | 2. Types | yes | A variable has one type in one alternative of a when and another type in another. |
| H3086 | 2. Types | yes | One pattern binds the same variable twice. |
| H3087 | 2. Types | yes | A name that begins with a lower-case letter takes sub-patterns. |
| H3088 | 2. Types | yes | A variant pattern names a case the union does not have. |
| H3089 | 2. Types | yes | A variant pattern stands where the value is not a union. |
| H3090 | 2. Types | yes | A case with patterns is given a value of a type it cannot decide on. |
| H3091 | 2. Types | yes | The pattern _ stands as a whole pattern in a case over a union. |
| H3092 | 2. Types | yes | A range stands where the value is not an integer. |
| H3093 | 2. Types | yes | A write reference to part of a value is taken through a read reference. |
| H3094 | 2. Types | yes | A function returns a reference to one of its local variables in a region its caller chooses. |
| H3095 | 2. Types | yes | The body of a generic function fixes one of the function's own type parameters. |
| H4001 | 2. Types | yes | A record or union declared Free contains a slot of a Linear type, or has a type parameter that is not Free. |
| H6026 | 2. Types | yes | A function, a method or a constructor is called with more or fewer arguments than it has parameters. |
| H6032 | 2. Types | yes | An instance joins a type class and a type that both come from other modules. |
| H6037 | 2. Types | yes | An instance of a type class from another module is given for a built-in type. |
| H6038 | 2. Types | yes | A type gets a second instance of the same type class. |
| H6039 | 2. Types | yes | A name that is called is neither a function nor a method nor a variable in scope. |
| H6041 | 2. Types | yes | An assignment has a function parameter on its left side. |
| H6042 | 2. Types | yes | An assignment changes a variable bound with let. |
| H6045 | 2. Types | yes | A variable has the same name as a declaration of the module, such as a function or a constant. |
| H6048 | 2. Types | yes | A generic type or a built-in type such as Pointer is given the wrong number of type arguments. |
| H3105 | 2. Types | yes | A constraint names a typeclass that its module does not import. |
| H3106 | 2. Types | yes | The C text of an @embed calls a function the programme imports through pragma Foreign_Import. |
| H3107 | 2. Types | yes | A comparison has operands of a type C cannot compare: a span, a record or a union. |
| H3108 | 2. Types | yes | A generic function compares values of a type variable, and a call makes it a span, a record or a union. |
| H3111 | 2. Types | yes | A method of a typeclass names the parameter of its class neither in a parameter nor in its result. |
| H3036 | 3. Linearity | yes | An expression statement throws away a value of a Linear type. |
| H4002 | 3. Linearity | yes | A linear variable goes out of scope without being consumed, for example a variable a when binds that its body does not use. |
| H4003 | 3. Linearity | yes | A linear variable from outside a loop is consumed in the loop body and not given a new value before the body ends. |
| H4004 | 3. Linearity | yes | The branches of an if or a case treat a linear variable differently: one consumes it and another does not. |
| H4005 | 3. Linearity | yes | One expression consumes the same linear variable twice, for example as two arguments of one call. |
| H4008 | 3. Linearity | yes | A linear variable is consumed a second time, in a later statement. |
| H4010 | 3. Linearity | yes | A var holding a linear value is given a new value before the old one is consumed. |
| H4012 | 3. Linearity | yes | A linear variable is not consumed when the function returns. |
| H4014 | 3. Linearity | yes | An assignment to a slot writes a value of a type that is not Free. |
| H4015 | 3. Linearity | yes | An if expression consumes a linear variable in one branch and not in the other. |
| H3002 | 4. Borrowing | yes | A reference or a span is handed to a task. |
| H3005 | 4. Borrowing | yes | The arrow -> reads a slot through a reference, and the value before it is not a reference. |
| H3018 | 4. Borrowing | yes | A variable bound with let is lent for writing. |
| H3019 | 4. Borrowing | yes | A function parameter is lent for writing. |
| H3026 | 4. Borrowing | yes | A write reference is converted with a colon to a read reference of another type or another region. |
| H3028 | 4. Borrowing | yes | A write reference is converted with a colon to something that is not a read reference. |
| H3032 | 4. Borrowing | yes | The operator ! reads the value behind a reference, and it is applied to something that is not a reference. |
| H3066 | 4. Borrowing | yes | A task of a lending scope is handed a reference of another borrow than the one the scope lends from. |
| H3067 | 4. Borrowing | yes | A task of a lending scope is handed a write reference. |
| H3068 | 4. Borrowing | yes | A task of a lending scope is started with an argument whose type is a type variable. |
| H3069 | 4. Borrowing | yes | A lending scope is handed to a task of another lending scope. |
| H3070 | 4. Borrowing | yes | A lending scope is handed to a task of a plain scope. |
| H4006 | 4. Borrowing | yes | A variable is consumed while it is lent for reading. |
| H4007 | 4. Borrowing | yes | A variable is consumed while it is lent for writing. |
| H4011 | 4. Borrowing | yes | A variable is borrowed that is already consumed, or borrowed in a way its current state does not allow. |
| H4013 | 4. Borrowing | yes | The operator ! reads the value behind a reference to a type that is not Free. |
| H6043 | 4. Borrowing | yes | A reference transform &( ... ) takes a path whose head is not a reference. |
| H6054 | 4. Borrowing | yes | An assignment writes through a read reference held in a var. |
| H6055 | 4. Borrowing | yes | A borrow statement reborrows with &~ a variable that is not a write reference. |
| H6059 | 4. Borrowing | yes | An index or a slot is taken of a constant of the module. |
| H2001 | 5. Modules | yes | The body defines a name of the interface as a different kind of declaration, for example a function where the interface declares a constant. |
| H2002 | 5. Modules | yes | A function has different type parameters, parameters or return type in the interface and in the body. |
| H2004 | 5. Modules | yes | The interface declares something that the body does not define. |
| H2005 | 5. Modules | yes | The interface declares an instance that the body does not define. |
| H2006 | 5. Modules | yes | The interface and the body given as a pair on the command line name different modules. |
| H2008 | 5. Modules | yes | A declaration has a different type in the interface and in the body, for example a constant. |
| H2009 | 5. Modules | yes | An opaque type is declared in one universe in the interface and defined in another in the body. |
| H2010 | 5. Modules | yes | The compilation was started with --forbid-unsafe-modules, and one of its modules is unsafe. |
| H2011 | 5. Modules | yes | A pragma is given the wrong arguments. |
| H2012 | 5. Modules | yes | A pragma has a name the compiler does not know. |
| H2013 | 5. Modules | yes | A safe module names a C library. |
| H2014 | 5. Modules | yes | The name in pragma Foreign_Library is empty. |
| H2015 | 5. Modules | yes | A module declares the same name twice. |
| H2016 | 5. Modules | yes | Two modules of one compilation have the same name. |
| H2017 | 5. Modules | yes | An import names a module that is not part of the compilation. |
| H2018 | 5. Modules | yes | A function generic over a type carries pragma Foreign_Export. |
| H2027 | 5. Modules | yes | Two imports give the same local name. |
| H2028 | 5. Modules | yes | A safe module imports from Hilde.Memory, whose raw pointers only unsafe modules may use. |
| H2029 | 5. Modules | yes | An import names something that its module defines only in the body. |
| H2030 | 5. Modules | yes | An import names something that its module does not have at all. |
| H2038 | 5. Modules | yes | A safe module uses @embed, which pastes C that the compiler does not check. |
| H2039 | 5. Modules | yes | A safe module binds a C function with pragma Foreign_Import. |
| H2040 | 5. Modules | yes | A function bound to C with Foreign_Import has type parameters. |
| H2041 | 5. Modules | yes | A pragma other than Foreign_Import or Foreign_Export stands before a function. |
| H2042 | 5. Modules | yes | A safe module names a C header with pragma Foreign_Header. |
| H2043 | 5. Modules | yes | The name in pragma Foreign_Header is not a header name. |
| H2044 | 5. Modules | yes | A program imports both Standard.Sqlite and Standard.SqlCipher. |
| H2045 | 5. Modules | yes | A program imports a module whose name begins with Bindings. |
| H2050 | 5. Modules | yes | The name a function is exported under is one that C cannot give it: not a C identifier, a keyword of C or main, a name beginning with hilde_, which the runtime keeps for its own, or a name another function is exported under already. |
| H2059 | 5. Modules | yes | A function bound to C with Foreign_Import returns Bool. |
| H3001 | 5. Modules | yes | A function exported to C with Foreign_Export has a parameter or return type that cannot cross to C, such as a span of anything but Nat8, a record with type parameters or a reference to a number. |
| H6060 | 5. Modules | yes | A call names a function another module declares and this module does not import. |
| H1001 | 6. Other | yes | The value of --entrypoint is not of the form Module:function. |
| H1002 | 6. Other | yes | A module on the command line is given as neither one body file nor an interface and a body joined by a comma. |
| H1003 | 6. Other | yes | The compile command has no --entrypoint. |
| H1004 | 6. Other | yes | The compile command names no module. |
| H1005 | 6. Other | yes | The compile command has no --output. |
| H1006 | 6. Other | yes | The compiler is told to leave out the entrypoint, and its target is neither C nor a library. |
| H1007 | 6. Other | yes | The value of --target-type is none of exe, c, tc, static and shared. |
| H1008 | 6. Other | yes | The value of --error-format is none of plain, json, hilde-json and json-lines. |
| H1009 | 6. Other | yes | A flag is given twice. |
| H1010 | 6. Other | no | The argument list of the compiler is empty, not even the name of the program is in it. |
| H1011 | 6. Other | yes | A flag that takes no value is given one, as in --flag=value. |
| H1012 | 6. Other | yes | A flag that takes a value is given without one. |
| H1013 | 6. Other | yes | A flag holds more than one equals sign, so it is neither --flag nor --flag=value. |
| H1014 | 6. Other | yes | The C compiler refused the C code the compiler generated. |
| H1015 | 6. Other | yes | The compiler could not open or write its output file, for example because its directory does not exist or the device is full. |
| H1016 | 6. Other | no | This is the message for a failure to write that is not a system error; a system error, such as a missing directory, is H1015. |
| H1017 | 6. Other | yes | hilde query asks about a module that is not on the command line. |
| H1018 | 6. Other | yes | hilde query is called without --module, so it does not know which module to describe. |
| H1019 | 6. Other | yes | hilde test is called without a path, so it has nowhere to look for tests. |
| H1020 | 6. Other | yes | hilde test is given two flags that exclude one another: two of the instruments --race, --memory and --valgrind, or --emit-c beside one of them. |
| H1021 | 6. Other | no | hilde test is given an instrument, --race, --memory or --valgrind, that this system cannot run: its C compiler does not build or run a programme with the instrument's flags, valgrind cannot be started, or the C compiler does not find valgrind's header valgrind/valgrind.h. |
| H1022 | 6. Other | yes | A path given to hilde test is neither a directory nor a .hiq file, for example because it does not exist. |
| H1023 | 6. Other | yes | hilde test searched the directories it was given and found no test file in them. |
| H1024 | 6. Other | yes | Two files under the paths of hilde test declare the same module, and a test file imports it. |
| H1025 | 6. Other | yes | A directory hilde test searches for modules holds an interface without the body of the same name beside it. |
| H1026 | 6. Other | yes | A library is built, --target-type=static, shared or wasm, and the command line names an entrypoint as well. |
| H1027 | 6. Other | yes | The output of a library does not end in the suffix of its kind, .a for --target-type=static and .so for shared, or is the suffix alone. |
| H1028 | 6. Other | yes | hilde test --contracts is given a seed or a number of rounds that is not a decimal number in its range. |
| H1029 | 6. Other | yes | hilde test is given --seed or --rounds without --contracts. |
| H1030 | 6. Other | yes | hilde guard is given an entrypoint that is not a function of a module on its command line. |
| H1031 | 6. Other | yes | hilde guard is given a vulnerability database it cannot read: a path that is not there, a file that is not JSON, or a record that is not in the OSV format. |
| H1032 | 6. Other | yes | An entry of --library-versions is not the name of a library as it is linked, a colon and a version of numbers separated by dots. |
| H1033 | 6. Other | yes | A path given to hilde fmt is neither a directory nor a .hih or .hiq file. |
| H1034 | 6. Other | yes | A file given to the compiler could not be opened or read: it does not exist, it is a directory, or it may not be read. |
| H1035 | 6. Other | yes | A --build-value has no =, a name that is not valid, a value that is not printable ASCII of at most 1024 bytes, or a name given twice. |
| H1036 | 6. Other | yes | SOURCE_DATE_EPOCH is set to something that is not one to eighteen decimal digits. |
| H1037 | 6. Other | yes | The first word is not a command of hilde. |
| H2046 | 6. Other | yes | A function of a test file has the name of a test and another form than a test's. |
| H2047 | 6. Other | yes | A test file declares no function with the name of a test. |
| H2048 | 6. Other | yes | A pragma Foreign_Library names a system the compiler does not know. |
| H2049 | 6. Other | yes | A pragma Foreign_Library has arguments it does not take, or its two in the other order. |
| H3059 | 6. Other | yes | A literal pattern handed to compile of Standard.Regex is one that the module would refuse when the program runs. |
| H5001 | 6. Other | yes | The entry point function takes more than one parameter. |
| H5002 | 6. Other | yes | The module named in --entrypoint has no function of the given name. |
| H5003 | 6. Other | yes | The entry point named in --entrypoint is not a function, for example a constant. |
| H5004 | 6. Other | yes | The entry point function is generic. |
| H5005 | 6. Other | yes | The module has an interface, and the interface does not declare the entry point function. |
| H5006 | 6. Other | yes | The one parameter of the entry point function is not of type RootCapability. |
| H5007 | 6. Other | yes | The entry point function does not return ExitCode. |
| H6001 | 6. Other | yes | The path in @bytes is empty, absolute or contains a .. part. |
| H6002 | 6. Other | yes | The file named in @bytes cannot be read, for example because it does not exist beside the module. |
| H6005 | 6. Other | yes | The command line holds an argument the compile or query command does not use, such as an unknown flag. |
| H6013 | 6. Other | yes | A borrow expression stands where no statement can hold the borrow, for example in the value of a constant. |
| H6020 | 6. Other | yes | A function binds the same name twice in the same scope, for example with two lets. |
| H6025 | 6. Other | yes | Two nested borrow statements give their regions the same name. |
| H6047 | 6. Other | yes | A list of type parameters names the same parameter twice. |
| H9999 | 6. Other | no | An internal error: the compiler reached a state its own checks should have ruled out. |
| H7001 | 7. Templates | yes | The name of a template is empty. |
| H7002 | 7. Templates | yes | The path of a template is absolute. |
| H7003 | 7. Templates | yes | The path of a template contains a .. part and so leaves the module's directory. |
| H7004 | 7. Templates | yes | A template file cannot be read, for example because it does not exist beside the module. |
| H7005 | 7. Templates | yes | A tag {{ or {% is opened and never closed. |
| H7006 | 7. Templates | yes | A comment {# is opened and never closed with #}. |
| H7007 | 7. Templates | yes | A {% raw %} is never closed with {% endraw %}. |
| H7008 | 7. Templates | yes | The {% endraw %} tag holds something after endraw. |
| H7009 | 7. Templates | yes | A number in a template is not a whole decimal number, such as 1.5. |
| H7011 | 7. Templates | yes | A string in a tag holds an escape other than `\n`, `\t`, `\r`, `\\`, `\'` and `\"`. |
| H7013 | 7. Templates | yes | A character stands in a tag that is no part of the template language. |
| H7014 | 7. Templates | yes | The expression in a tag lacks a symbol it needs, such as a closing parenthesis. |
| H7015 | 7. Templates | yes | A name is expected in a tag and something else stands there, for example after a point. |
| H7016 | 7. Templates | yes | The operator / or ** stands in a tag. |
| H7017 | 7. Templates | yes | An inline if mixes a |safe value with one that is not, or stands in a condition. |
| H7018 | 7. Templates | yes | The operator in asks something other than a name of the data, or for something other than a text. |
| H7019 | 7. Templates | yes | The arguments of a filter are not separated by commas or not closed. |
| H7020 | 7. Templates | yes | A macro is called with a keyword argument, name=value. |
| H7021 | 7. Templates | yes | The arguments of a macro call are not separated by commas or not closed. |
| H7022 | 7. Templates | yes | A call through a dot names no macro of an imported file. |
| H7023 | 7. Templates | yes | Square brackets hold something other than a name in quotes. |
| H7024 | 7. Templates | yes | A minus sign stands before a name. |
| H7025 | 7. Templates | yes | A symbol stands in a tag where an expression should begin. |
| H7026 | 7. Templates | yes | A tag holds no expression. |
| H7027 | 7. Templates | yes | An expression in a tag is followed by more text. |
| H7028 | 7. Templates | yes | A {% %} tag does not begin with a keyword. |
| H7029 | 7. Templates | yes | A {% %} tag uses a keyword this template language does not support, such as do. |
| H7030 | 7. Templates | yes | An {% include %} or {% extends %} takes the template's name and nothing after it. |
| H7031 | 7. Templates | yes | An {% include %} or {% extends %} takes a name that is not a string literal. |
| H7032 | 7. Templates | yes | An {% import %} lacks `as` and a name, or asks for the context. |
| H7033 | 7. Templates | yes | A template uses {% autoescape %}. |
| H7034 | 7. Templates | yes | A closing or continuing tag, such as {% endif %} or {% else %}, stands without its opening tag. |
| H7035 | 7. Templates | yes | An {% else %} of an {% if %} is not followed by {% endif %}. |
| H7036 | 7. Templates | yes | An {% if %} is never closed with {% endif %}. |
| H7037 | 7. Templates | yes | A {% for %} names more than three names. |
| H7038 | 7. Templates | yes | A {% for %} lacks the word in. |
| H7039 | 7. Templates | yes | Something other than `if` and a condition follows the sequence of a {% for %}. |
| H7040 | 7. Templates | yes | An {% else %} of a {% for %} is not followed by {% endfor %}. |
| H7041 | 7. Templates | yes | A {% for %} is never closed with {% endfor %}. |
| H7042 | 7. Templates | yes | A block is marked required. |
| H7043 | 7. Templates | yes | A {% block %} has no name, or something other than scoped after it. |
| H7044 | 7. Templates | yes | A {% block %} is never closed with {% endblock %}. |
| H7045 | 7. Templates | yes | An {% endblock %} names another block than the one it closes. |
| H7046 | 7. Templates | yes | The default of a macro parameter is not a literal. |
| H7047 | 7. Templates | yes | The parameters of a macro are not separated by commas. |
| H7048 | 7. Templates | yes | Text follows the parameter list of a macro. |
| H7049 | 7. Templates | yes | A {% macro %} is never closed with {% endmacro %}. |
| H7050 | 7. Templates | yes | A {% from ... import %} gives an imported macro another name with as. |
| H7051 | 7. Templates | yes | A {% from ... import %} names something other than macros. |
| H7052 | 7. Templates | yes | A {% from %} lacks the file name as a string, or the word import. |
| H7054 | 7. Templates | yes | A macro is defined twice with two bodies. |
| H7055 | 7. Templates | yes | A template imports macros from itself. |
| H7056 | 7. Templates | yes | A {% from ... import %} names a macro the file does not define. |
| H7057 | 7. Templates | yes | A template includes or extends itself, directly or through others. |
| H7058 | 7. Templates | yes | A template extends a second time. |
| H7059 | 7. Templates | yes | Text stands after {% extends %} outside a block. |
| H7060 | 7. Templates | yes | A value stands after {% extends %} outside a block. |
| H7061 | 7. Templates | yes | An {% if %} or a {% for %} stands after {% extends %} outside a block. |
| H7062 | 7. Templates | yes | An {% include %} stands after {% extends %} outside a block. |
| H7063 | 7. Templates | yes | super() stands in a block that no template above this one has. |
| H7064 | 7. Templates | yes | super() is given arguments. |
| H7065 | 7. Templates | yes | An {% extends %} stands inside another tag, such as an {% if %}. |
| H7066 | 7. Templates | yes | A template defines a block that no template it extends has. |
| H7067 | 7. Templates | yes | A value stands in a place of the HTML where no escaping makes it safe, such as inside a tag's name or attribute list. |
| H7069 | 7. Templates | yes | loop is used for something other than loop.index, loop.index0, loop.length, loop.first or loop.last. |
| H7070 | 7. Templates | yes | A macro brought in with {% from ... import %} uses the template's data. |
| H7071 | 7. Templates | yes | loop is used outside a {% for %}. |
| H7072 | 7. Templates | yes | A number compared in a condition is too large. |
| H7073 | 7. Templates | yes | A loop attribute is printed that cannot be printed. |
| H7075 | 7. Templates | yes | `\|length` is applied to something that is not a name of the data. |
| H7076 | 7. Templates | yes | A filter is used that this template language does not support. |
| H7077 | 7. Templates | yes | none is printed. |
| H7079 | 7. Templates | yes | A macro call stands with a filter in {{ }}. |
| H7080 | 7. Templates | yes | A loop attribute that is not a number stands where a number goes. |
| H7082 | 7. Templates | yes | A condition asks is defined. |
| H7083 | 7. Templates | yes | is none is asked of something that is not a name of the data. |
| H7084 | 7. Templates | yes | A condition uses a test this template language does not support. |
| H7085 | 7. Templates | yes | A string is compared with an operator other than == and !=. |
| H7086 | 7. Templates | yes | A comparison does not compare a name with a literal. |
| H7087 | 7. Templates | yes | Something that is not a condition stands as one, such as a string. |
| H7088 | 7. Templates | yes | A macro parameter that is given a literal is used with a field, as in x.name. |
| H7089 | 7. Templates | yes | A macro is called that is not defined. |
| H7090 | 7. Templates | yes | A macro calls itself. |
| H7091 | 7. Templates | yes | A macro is called with more arguments than it has parameters. |
| H7092 | 7. Templates | yes | A macro is called without a value for a parameter that has no default. |
| H7093 | 7. Templates | yes | A macro argument is neither a name nor a literal. |
| H7095 | 7. Templates | yes | The branches of an {% if %} end in different places of the HTML, for example one inside a script and one outside. |
| H7096 | 7. Templates | yes | A {% for %} walks over something that is not a name of the data. |
| H7097 | 7. Templates | yes | The body of a {% for %} ends in a different place of the HTML than it begins. |
| H7098 | 7. Templates | yes | The {% else %} of a {% for %} ends in a different place of the HTML than it begins. |
| H7099 | 7. Templates | yes | A module that uses @template does not import Standard.Template. |
| H7100 | 7. Templates | yes | A set block, a with, a filter or a call lacks its end tag. |
| H7101 | 7. Templates | yes | A set, with, filter or call tag is not in its form. |
| H7102 | 7. Templates | yes | The name of an import is printed or given twice. |
| H7103 | 7. Templates | yes | A set stands after extends and outside a block. |
| H7104 | 7. Templates | yes | A field is asked of a computed value. |
| H7105 | 7. Templates | yes | // or % divides by a name of the data, or by zero. |
| H7106 | 7. Templates | yes | An operand of arithmetic is not a number. |
| H7107 | 7. Templates | yes | ~ joins a |safe value to one that is escaped. |
| H7108 | 7. Templates | yes | The arguments of a filter or of loop.cycle are not in their form. |
| H7109 | 7. Templates | yes | A filter block names a filter that applies to a value. |
| H7110 | 7. Templates | yes | A set stands inside an if. |
| H7111 | 7. Templates | yes | A filter or set block does not stand in HTML text, or ends elsewhere. |
| H7112 | 7. Templates | yes | caller() stands in a macro called without a call block. |
| H7113 | 7. Templates | yes | The text of a set block is printed outside HTML text. |
| H7114 | 7. Templates | yes | @template names an unknown option. |
| H7115 | 7. Templates | yes | The key of _( ) is not a string literal. |
| H7116 | 7. Templates | yes | An argument of _( ) is named twice. |
| H7117 | 7. Templates | yes | {% catalog %} does not name one function. |
| H7118 | 7. Templates | yes | The text of a {% trans %} block is not one key. |
| H7119 | 7. Templates | yes | {% pluralize %} stands in a {% trans %} without count. |
| H7120 | 7. Templates | yes | Text stands between {% pluralize %} and {% endtrans %}. |
| H7121 | 7. Templates | yes | A template names its catalog twice. |
| H7122 | 7. Templates | yes | A translation stands before any {% catalog %}. |
| H7123 | 7. Templates | yes | A translation stands in a script or a JavaScript attribute. |
| H7124 | 7. Templates | yes | A translation stands with a filter or a ~. |
| H7125 | 7. Templates | yes | An argument of _( ) has no name. |
| H7126 | 7. Templates | yes | An argument of {% trans %} is named twice. |
| H7127 | 7. Templates | yes | A module whose template translates does not import Standard.I18n. |
| H7128 | 7. Templates | yes | {% catalog %} stands after {% extends %} outside a block. |
| H8001 | 8. SQL | yes | A string or a quoted name in the SQL is not closed. |
| H8002 | 8. SQL | yes | A comment `/*` in the SQL is not closed with `*/`. |
| H8003 | 8. SQL | yes | A blob literal x'...' does not hold an even number of hexadecimal digits. |
| H8004 | 8. SQL | yes | A number runs straight into a name, as in 18years. |
| H8005 | 8. SQL | yes | A name is quoted with backticks or brackets. |
| H8006 | 8. SQL | yes | A numbered parameter such as ?1 stands in the SQL. |
| H8007 | 8. SQL | yes | A named parameter such as :age stands in the SQL. |
| H8008 | 8. SQL | yes | A character stands in the SQL that the compiler does not read as SQL, such as #. |
| H8009 | 8. SQL | yes | A keyword is missing where the grammar needs it, such as BY after ORDER. |
| H8010 | 8. SQL | yes | A symbol is missing where the grammar needs it, such as the parenthesis after IN. |
| H8011 | 8. SQL | yes | A name is missing where the grammar needs one, such as the table after FROM. |
| H8012 | 8. SQL | yes | The SQL uses something SQLite knows and this compiler does not accept, because it could not give it a type, such as a subquery. |
| H8013 | 8. SQL | yes | A function other than count is given `*`. |
| H8014 | 8. SQL | yes | A column of the result is named without AS. |
| H8015 | 8. SQL | yes | OR in INSERT OR or UPDATE OR is followed by something other than ABORT, FAIL, IGNORE, REPLACE or ROLLBACK. |
| H8016 | 8. SQL | yes | The default of a column in a migration is not a literal, a signed number, CURRENT_TIME, CURRENT_DATE, CURRENT_TIMESTAMP or an expression in parentheses. |
| H8017 | 8. SQL | yes | A column type in a migration has a size, as in VARCHAR(40). |
| H8018 | 8. SQL | yes | After CONSTRAINT and its name, a table constraint is not PRIMARY KEY, UNIQUE, CHECK or FOREIGN KEY. |
| H8019 | 8. SQL | yes | WITHOUT after a table is not followed by ROWID. |
| H8020 | 8. SQL | yes | In the list of table options after a comma stands something other than STRICT or WITHOUT ROWID. |
| H8021 | 8. SQL | yes | CREATE INDEX lacks the parenthesis with the columns after the table. |
| H8022 | 8. SQL | yes | ALTER TABLE is followed by something other than RENAME, ADD or DROP. |
| H8023 | 8. SQL | yes | A migration creates something other than a table or an index, such as a view. |
| H8024 | 8. SQL | yes | A migration drops something other than a table or an index, such as a view. |
| H8025 | 8. SQL | yes | A migration holds a statement other than CREATE TABLE, CREATE INDEX, ALTER TABLE, DROP TABLE, DROP INDEX, INSERT, UPDATE and DELETE, such as PRAGMA. |
| H8026 | 8. SQL | yes | A query is not SELECT, INSERT, UPDATE or DELETE. |
| H8027 | 8. SQL | yes | The SQL names a table that the migrations do not build. |
| H8028 | 8. SQL | yes | The SQL names a column that the table does not have. |
| H8029 | 8. SQL | yes | A parameter stands where its type cannot be told, such as in ORDER BY. |
| H8030 | 8. SQL | yes | A column is qualified with a table or alias that the query does not have. |
| H8032 | 8. SQL | yes | A query names a column and has no FROM to take it from. |
| H8033 | 8. SQL | yes | No table of the query has a column of this name. |
| H8034 | 8. SQL | yes | More than one table of the query has a column of this name. |
| H8035 | 8. SQL | yes | A sign stands in front of something that is not a number. |
| H8036 | 8. SQL | yes | NOT stands in front of something that is not a condition. |
| H8037 | 8. SQL | yes | % takes two INTEGERs and is given a REAL. |
| H8038 | 8. SQL | yes | Arithmetic is done on something that is not a number. |
| H8039 | 8. SQL | yes | `\|\|` joins something that is not TEXT. |
| H8040 | 8. SQL | yes | A value is compared with NULL using = or a similar operator. |
| H8041 | 8. SQL | yes | Two values of different types are compared, such as TEXT with INTEGER. |
| H8042 | 8. SQL | yes | IS compares two values of different types, which can never be the same. |
| H8043 | 8. SQL | yes | A parameter is tested for NULL. |
| H8044 | 8. SQL | yes | LIKE or GLOB is given something that is not TEXT. |
| H8045 | 8. SQL | yes | A parameter stands on the left of IN. |
| H8046 | 8. SQL | yes | NULL stands on the left of IN. |
| H8047 | 8. SQL | yes | NULL stands in the list of IN. |
| H8048 | 8. SQL | yes | A value in the list of IN has another type than the value on the left, so the two can never be equal. |
| H8049 | 8. SQL | yes | A parameter stands on the left of BETWEEN. |
| H8050 | 8. SQL | yes | NULL stands on the left of BETWEEN. |
| H8051 | 8. SQL | yes | A bound of BETWEEN has another type than the value it is compared with. |
| H8052 | 8. SQL | yes | AND or OR joins something that is not a condition. |
| H8053 | 8. SQL | yes | `count(*)` stands outside the columns, HAVING and ORDER BY, such as in WHERE. |
| H8054 | 8. SQL | yes | An aggregate function stands outside the columns, HAVING and ORDER BY, such as in WHERE. |
| H8055 | 8. SQL | yes | DISTINCT stands inside a function that is not an aggregate. |
| H8056 | 8. SQL | yes | A function that takes one argument here is given another number. |
| H8057 | 8. SQL | yes | A function that takes a number, such as abs or sum, is given something else. |
| H8058 | 8. SQL | yes | count is given a parameter. |
| H8059 | 8. SQL | yes | min or max is given a parameter. |
| H8060 | 8. SQL | yes | min or max is given NULL. |
| H8061 | 8. SQL | yes | coalesce is given fewer than two arguments, or ifnull not exactly two. |
| H8062 | 8. SQL | yes | coalesce or ifnull is given only parameters, so its type cannot be told. |
| H8063 | 8. SQL | yes | The first value of coalesce or ifnull that is not a parameter is NULL. |
| H8064 | 8. SQL | yes | coalesce or ifnull is given values of different types. |
| H8065 | 8. SQL | yes | length is given something other than TEXT or BLOB. |
| H8066 | 8. SQL | yes | lower or upper is given something other than TEXT. |
| H8067 | 8. SQL | yes | The SQL calls a function whose type the compiler does not know. |
| H8068 | 8. SQL | yes | Two parameters meet at one operator, and neither gives the other a type. |
| H8069 | 8. SQL | yes | A WHERE, ON, HAVING or CHECK is given something that is not a condition. |
| H8070 | 8. SQL | yes | A column of the result has a name that cannot name a field of the row record, such as a name with a space or a Hilde keyword. |
| H8071 | 8. SQL | yes | `*` stands in a query without a table. |
| H8072 | 8. SQL | yes | `t.*` names a table or alias the query does not have. |
| H8073 | 8. SQL | yes | A column of the result is always NULL and so has no type. |
| H8074 | 8. SQL | yes | A column of the result that is not a plain column has no name. |
| H8075 | 8. SQL | yes | Two columns of the result have the same name. |
| H8076 | 8. SQL | yes | NULL is written into a column that is NOT NULL. |
| H8077 | 8. SQL | yes | A value of another type is written into a column. |
| H8078 | 8. SQL | yes | A value that may be NULL is written into a column that is NOT NULL. |
| H8079 | 8. SQL | yes | A table stands twice in FROM without an alias that tells the two apart. |
| H8081 | 8. SQL | yes | LIMIT or OFFSET is given something other than an INTEGER that is not NULL. |
| H8082 | 8. SQL | yes | The column list of an INSERT names a column twice. |
| H8083 | 8. SQL | yes | An INSERT leaves out a column that is NOT NULL and has no default. |
| H8084 | 8. SQL | yes | An INSERT has a column list and DEFAULT VALUES. |
| H8085 | 8. SQL | yes | A row of an INSERT has another number of values than there are columns. |
| H8086 | 8. SQL | yes | A column in a migration has the type ANY. |
| H8087 | 8. SQL | yes | A column in a migration has no type. |
| H8088 | 8. SQL | yes | A column in a migration has a type that a STRICT table does not know, such as DATE. |
| H8089 | 8. SQL | yes | A migration creates a table that exists already. |
| H8090 | 8. SQL | yes | A table is created without STRICT. |
| H8091 | 8. SQL | yes | A table defines a column twice. |
| H8092 | 8. SQL | yes | A table has more than one PRIMARY KEY. |
| H8093 | 8. SQL | yes | The PRIMARY KEY of a table names a column the table does not have. |
| H8094 | 8. SQL | yes | ALTER TABLE ADD COLUMN adds a column the table has already. |
| H8095 | 8. SQL | yes | ALTER TABLE ADD COLUMN adds a PRIMARY KEY. |
| H8096 | 8. SQL | yes | ALTER TABLE ADD COLUMN adds a NOT NULL column without a default. |
| H8097 | 8. SQL | yes | ALTER TABLE RENAME TO gives a table the name of a table that exists. |
| H8098 | 8. SQL | yes | ALTER TABLE RENAME COLUMN gives a column the name of a column the table has. |
| H8099 | 8. SQL | yes | ALTER TABLE DROP COLUMN drops the last column of a table. |
| H8100 | 8. SQL | yes | DROP TABLE drops a table that does not exist. |
| H8101 | 8. SQL | yes | CREATE INDEX creates an index whose name exists already. |
| H8102 | 8. SQL | yes | DROP INDEX drops an index that does not exist. |
| H8103 | 8. SQL | yes | A migration file cannot be read, for example because a directory carries the name of a migration. |
| H8104 | 8. SQL | yes | There is no directory migrations beside the module. |
| H8105 | 8. SQL | yes | The directory migrations holds no file that ends in .sql. |
| H8106 | 8. SQL | yes | A file in migrations is not called `<number>-<name>.sql` with a number from 1. |
| H8107 | 8. SQL | yes | The migrations are not numbered 1, 2, 3 and so on without a gap, or a number stands twice. |
| H8108 | 8. SQL | yes | A statement in a migration is not followed by ; before the next one begins. |
| H8109 | 8. SQL | yes | A migration holds a parameter ?. |
| H8110 | 8. SQL | yes | A module that uses @query, @execute or @migrations imports neither Standard.Sqlite nor Standard.SqlCipher. |
| H8111 | 8. SQL | yes | The SQL of one @query or @execute holds more than one statement. |
| H8112 | 8. SQL | yes | The SQL has another number of parameters ? than values are given. |
| H8113 | 8. SQL | yes | The row type of @query is not a record, written Name or Name[R] with R the region the row's text is lent under. |
| H8115 | 8. SQL | yes | @query is given a statement that returns no rows. |
| H8116 | 8. SQL | yes | @execute is given a statement that returns rows. |
| H2051 | 9. Contracts | yes | The body of a public function has requires, ensures or raises clauses. |
| H2052 | 9. Contracts | yes | A function imported from C has a contract. |
| H2053 | 9. Contracts | yes | An ensures names a variable that the function's body declares. |
| H2054 | 9. Contracts | yes | A function with an ensures has a parameter named result. |
| H2055 | 9. Contracts | yes | old is written where it has no meaning: in a requires, inside another old, or with other than one value. |
| H2056 | 9. Contracts | yes | A test function has a requires. |
| H2057 | 9. Contracts | yes | A record with an invariant can be built or written outside its module. |
| H3096 | 9. Contracts | yes | A condition uses a linear value itself instead of through a reference. |
| H3097 | 9. Contracts | yes | A condition takes a reference to write through. |
| H3098 | 9. Contracts | yes | A condition calls a function that reaches a binding module, C or a reference to write through. |
| H3099 | 9. Contracts | yes | A condition calls through a function pointer or a method of a type parameter. |
| H3100 | 9. Contracts | yes | old is given a value that is not free. |
| H3101 | 9. Contracts | yes | A function with a requires is taken as a function pointer. |
| H5008 | 9. Contracts | yes | The entry point function has a requires. |
| H2058 | 10. Error kinds | yes | An instance's method has a raises clause. |
| H3102 | 10. Error kinds | yes | A raise names a kind that the function's raises clause does not. |
| H3103 | 10. Error kinds | yes | A call can end with an error kind that the caller's raises clause does not name. |
| H3104 | 10. Error kinds | yes | A function with a raises clause is taken as a function pointer. |
| H2060 | 11. Never and slots | yes | A return stands in a function that returns Never. |
| H2061 | 11. Never and slots | yes | A function that returns Never has a path that comes to the end of its body. |
| H2062 | 11. Never and slots | yes | A function that returns Never carries an ensures clause. |
| H2063 | 11. Never and slots | yes | A slot has neither a default body nor an implementation in the programme. |
| H2064 | 11. Never and slots | yes | Two functions of the programme implement the same slot. |
| H2065 | 11. Never and slots | yes | An implementation of a slot has another signature than the slot. |
| H2066 | 11. Never and slots | yes | A pragma Implements names something that is not a slot. |
| H2067 | 11. Never and slots | yes | A pragma Slot or pragma Implements stands where it has no meaning. |
| H3109 | 11. Never and slots | yes | Never stands as the type of something that holds a value. |
| H3110 | 11. Never and slots | yes | A call of a function that returns Never is an argument or an operand. |
| H1038 | 12. Targets | yes | No compiler for wasm32-wasi is found. |
| H1039 | 12. Targets | yes | HILDE_WASM_CC names a compiler hilde does not know for WebAssembly. |
| H1040 | 12. Targets | no | hilde test --target=wasm finds no runtime for WebAssembly. |
| H1041 | 12. Targets | yes | --target names no target hilde builds for. |
| H1042 | 12. Targets | no | --target names another system than the one hilde runs on. |
| H1043 | 12. Targets | yes | --target=wasm is given with an archive or a shared object. |
| H1044 | 12. Targets | yes | The output of a programme for wasm does not end in .wasm. |
| H2068 | 12. Targets | yes | A pragma Targets names no target, one twice, one that does not exist, or an Instead that is no module. |
| H2069 | 12. Targets | yes | Another pragma than one pragma Targets stands before a module interface. |
| H2070 | 12. Targets | yes | A module outside the standard library names its targets. |
| H2071 | 12. Targets | yes | An interface of the standard library names no targets. |
| H2072 | 12. Targets | yes | A module names a target that one of its imports is not there for. |
| H2073 | 12. Targets | yes | A programme built for a target imports a module that is not there for it. |
| H1045 | 13. Packages | no | A package command was given, and hilde-pkg is not beside the compiler. |
| H1046 | 13. Packages | no | hilde-pkg is beside the compiler and could not be started. |
| H1501 | 13. Packages | no | The command needs a package, and there is no hilde.toml in the directory. |
| H1502 | 13. Packages | no | hilde.toml is not TOML; the message names the line and the column. |
| H1503 | 13. Packages | no | hilde.toml has a key or a table that a manifest does not have, such as a misspelt one. |
| H1504 | 13. Packages | no | A key hilde.toml must have is missing: the name or the version of the package, or the git URL or the version of a requirement. |
| H1505 | 13. Packages | no | A value has the wrong form: a name that is no module prefix, a version that is not vX.Y.Z, a capability that is none, or an argument of the wrong form. |
| H1506 | 13. Packages | no | One prefix comes from two git URLs, or a package is named otherwise than the prefix it is required by. |
| H1507 | 13. Packages | no | git is not on the PATH, and the command needs it. |
| H1508 | 13. Packages | no | git failed: a wrong URL, a repository that may not be read, or a programme that could not be started. |
| H1509 | 13. Packages | no | The repository has no tag of the version asked for; the suggestion names the tags nearest to it. |
| H1510 | 13. Packages | no | The tree of a package holds a symbolic link or a special file. |
| H1511 | 13. Packages | no | A release has no signature, and the policy of the package asks for one. |
| H1512 | 13. Packages | no | A signature does not hold, the key is not the one taken on first use, or a release is unsigned after a signed one. |
| H1513 | 13. Packages | no | The secret key cannot be read, is no signify key, or has a passphrase. |
| H1514 | 13. Packages | no | hilde.sum is missing, has a bad line, or lacks the line of a requirement. |
| H1515 | 13. Packages | no | A tree in vendor/ is missing, changed, or not named in hilde.sum. |
| H1516 | 13. Packages | no | Two majors of one package are required; a new major takes a new prefix. |
| H1517 | 13. Packages | no | The tree of a package is deeper than 64 directories. |
| H1518 | 13. Packages | no | A directory or a file of a package cannot be read. |
| H1519 | 13. Packages | no | A file or a directory cannot be written. |
| H1521 | 13. Packages | no | hilde new or a key would write over something that is there. |
| H1522 | 13. Packages | no | hilde doc finds no module or declaration of the name. |
| H1523 | 13. Packages | no | A target of hilde.toml is not allowed by the pragma Targets of a module the package reaches. |
| H1530 | 13. Packages | no | The version of a release is lower than its change of interface calls for, such as a break under a minor version. |
| H1531 | 13. Packages | no | A module of the package has no test file. |
| H1532 | 13. Packages | no | The tests of the package do not pass, or the compiler failed on it. |
| H1533 | 13. Packages | no | An exported function is called in no test. |
| H1534 | 13. Packages | no | The version of a release is not newer than the newest tag. |
| H1047 | 14. Sperli | no | A run command was given, and hilde-launcher is not beside the compiler. |
| H1048 | 14. Sperli | no | hilde-launcher is beside the compiler and could not be started. |
| H1601 | 14. Sperli | no | The peer showed no certificate, or one that the CA of the job does not vouch for, or offered a TLS version below 1.3. |
| H1602 | 14. Sperli | no | The subject of the certificate of the peer is not the job and the rank the connection is for. |
| H1603 | 14. Sperli | no | A host is listed in SPERLI_REFUSED_HOSTS, is host-a.invalid or host-b.invalid, or a name below one of them, or is on the deny list of the operator; a deny list cannot lift the rule. |
| H1604 | 14. Sperli | no | The join token of a peer has expired. |
| H1605 | 14. Sperli | no | The join token of a peer was made for another job. |
| H1606 | 14. Sperli | no | The join token of a peer was made for another rank, size, incarnation or host. |
| H1607 | 14. Sperli | no | The join token of a peer is malformed, or its signature does not hold under the public key of the launcher. |
| H1608 | 14. Sperli | no | A frame announces more payload than the limit of 16 MiB; it is refused before a payload byte is read. |
| H1609 | 14. Sperli | no | A frame belongs to an older incarnation of the job; its payload is read and dropped, and the wait goes on. |
| H1610 | 14. Sperli | no | The header of a frame breaks a rule of the protocol: an unknown type, a flag, service or membership epoch that is not 0, another job, other ranks, or a newer incarnation. |
| H1611 | 14. Sperli | no | A peer was lost: the connection closed, or no frame came within the silence limit. |
| H1612 | 14. Sperli | no | A peer sent an abort frame. |
| H1613 | 14. Sperli | no | The hello of a peer is missing, comes twice, has another version or offers no point-to-point service. |
| H1614 | 14. Sperli | no | The command line of hilde run or its host list is wrong: a missing or unknown option, a number out of range, no host, or a line that is no host and port. |
| H1615 | 14. Sperli | no | A rank could not be started, or the keys, certificates or ports of the job could not be made. |
| H1616 | 14. Sperli | no | The job description a rank was given on its standard input is malformed. |
| H1617 | 14. Sperli | no | A collective frame does not match the call it answers: another operation, type, reduce operation, phase, root or sequence number, or contributions of gather in different length. |
| H1618 | 14. Sperli | no | The arguments of a collective call are wrong: a root outside the job, an element type and reduce operation that do not go together, data that is no whole number of elements or blocks, or contributions of reduce in different length. |
| H1619 | 14. Sperli | no | A checkpoint file has another magic or version, or a job, epoch, rank, size or length that is not the one expected, or it is too short. |
| H1620 | 14. Sperli | no | The SHA-256 of the state in a checkpoint file is not the one in its header, or not the one the COMMIT file lists for the rank. |
| H1621 | 14. Sperli | no | A COMMIT file is malformed, is for another job or epoch, or its CompositeSig signature does not hold for the public key of the job. An epoch without a valid COMMIT file does not count. |
| H1622 | 14. Sperli | no | A resume found no epoch with a valid COMMIT file and all rank files, or the ranks did not agree on the epoch to resume. |
| H1623 | 14. Sperli | no | A resume was asked for a job of another number of ranks than the checkpoint was written with. Version 1 of the format requires the same size. |
| H1624 | 14. Sperli | no | A checkpoint was asked for while a send or receive was still open on this rank. |
| H1625 | 14. Sperli | no | A checkpoint could not be written or sent, or no checkpoint directory was named. |

## 1. Syntax

### H0001

Message:

```text
Parse Error
Character not allowed in source text: `$`
```

The source text holds a character that starts no token. Outside comments and
strings only letters, digits, white space and the symbols of the language
may stand.

This module fails with H0001:

```hilde fails H0001
module body Example is
    function main(): ExitCode is
        let total: Int32 := 1 $ 2;
        printLn(total);
        return ExitSuccess();
    end;
end module body.
```

The correct form:

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

Message:

```text
Parse Error
End of file in string literal.
```

A string literal is opened with a double quote and never closed. The rest of
the file becomes part of the string, and the file ends inside it.

This module fails with H0003:

```hilde fails H0003
module body Example is
    function main(): ExitCode is
        printLn("unclosed);
        return ExitSuccess();
    end;
end module body.
```

The correct form:

```hilde
module body Example is
    function main(): ExitCode is
        printLn("closed");
        return ExitSuccess();
    end;
end module body.
```

### H0004

Message:

```text
Parse Error
End of file in triple string literal.
```

A string in triple quotes is opened and never closed, so the file ends
inside it.

This module fails with H0004:

```hilde fails H0004
module body Example is
    function main(): ExitCode is
        printLn("""unclosed);
        return ExitSuccess();
    end;
end module body.
```

The correct form:

```hilde
module body Example is
    function main(): ExitCode is
        printLn("""closed""");
        return ExitSuccess();
    end;
end module body.
```

### H0005

Message:

```text
Parse Error
Error during parse.
```

The tokens do not form a program of the grammar. A frequent cause is an
expression with two operators and no parentheses: Hilde has no operator
precedence.

This module fails with H0005:

```hilde fails H0005
module body Example is
    function main(): ExitCode is
        let total: Int32 := 1 +;
        printLn(total);
        return ExitSuccess();
    end;
end module body.
```

The correct form:

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

Message:

```text
Parse Error
Function pointer type specifier must have at least one argument.
```

The function pointer type Fn is written without type arguments. It needs at
least one, the return type, and before it the parameter types.

This module fails with H0006:

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

The correct form:

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

Message, from the source in `lib/Util.ml`:

```text
Character literal '`lit` is more than one character.
```

A character literal holds more than one character.  The lexer takes only
one character or one escape between the apostrophes, so the parser never
sees a longer literal; the one way in was `'''`, which is now the
apostrophe, as `'\''` is.

It stays because the parser checks what the lexer gives it: a change of the lexer that let a longer
literal through would be refused here and not turned into a wrong number.

Not triggered: no program was found that reaches this error.

### H0008

Message:

```text
Parse Error
`method` is a reserved word and cannot be a name. Rename it, for example to `way`; docs/syntax.en.md, section 1, lists the reserved words.

Suggested fix: `way`
```

A reserved word stands where a name belongs: the name of a function, a
let, a var, a constant, the variable of a for, a parameter, or the name
after as.  Words such as method, from and body read like good names
and are reserved all the same.

This module fails with H0008:

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

The correct form:

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

Message:

```text
Parse Error
Hilde has no operator precedence: an operator takes two operands, and only `+`, `*`, `and` and `or` can be chained with themselves. Put the operation before `*` in parentheses, as in `(a + b) * c`.

Suggested fix: `(1 + 2)`
```

Hilde has no operator precedence: an operator takes two atomic operands.
Only the associative operators +, *, and and or may form a chain of the same
operator, a + b + c, read from the left.  Any other operator after an
operation needs that operation in parentheses.  The message suggests the
parentheses around the operation before the operator.

This module fails with H0009:

```hilde fails H0009
module body Example is
    function main(): ExitCode is
        let total: Int32 := 1 + 2 * 3;
        printLn(total);
        return ExitSuccess();
    end;
end module body.
```

The correct form:

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

Message:

```text
Parse Error
An index stands after a name, not after a call. Bind the result of the call to a name first, `let text: Span[Nat8, R] := asSpan(&s);`, and index the name, `text[i]`.
```

An index stands after a name.  The result of a call is bound to a name
first, and the name is indexed.

This module fails with H0010:

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

The correct form:

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

Message:

```text
Parse Error
Only a variable can be borrowed, not the literal `21`. Bind the value to a name first, `let key: Nat64 := 21;`, and borrow the name, `&key`.
```

Only a variable can be borrowed.  A literal is bound to a name first,
and the name is borrowed.

This module fails with H0011:

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

The correct form:

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

Message:

```text
Parse Error
A field stands after a name, not after a call. Bind the result of the call to a name first, `let node: Node := nodeAt();`, and take the field of the name, `node.kind`.
```

A field stands after a name.  The result of a call is bound to a name
first, and the field of the name is taken.

This module fails with H0012:

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

The correct form:

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

Message:

```text
Generic Error
Bad whitespace escape sequence
```

In a string literal a backslash followed by white space joins two parts of
the string, and the white space has to end in a second backslash. Here
something else follows the white space.

This module fails with H6018:

```hilde fails H6018
module body Example is
    function main(): ExitCode is
        printLn("one \  two");
        return ExitSuccess();
    end;
end module body.
```

The correct form:

```hilde
module body Example is
    function main(): ExitCode is
        printLn("one \  \two");
        return ExitSuccess();
    end;
end module body.
```

### H6058

Message:

```text
Parse Error
A `\u{...}` escape takes one to six hexadecimal digits of a code point up to `10FFFF`, and no surrogate (`D800` to `DFFF`).
```

The escape \u{X} writes the code point X as UTF-8.  X is one to six
hexadecimal digits, at most 10FFFF, and not a surrogate, D800 to DFFF.

This module fails with H6058:

```hilde fails H6058
module body Example is
    function main(): ExitCode is
        printLn("\u{110000}");
        return ExitSuccess();
    end;
end module body.
```

The correct form:

```hilde
module body Example is
    function main(): ExitCode is
        printLn("caf\u{e9}");
        return ExitSuccess();
    end;
end module body.
```

## 2. Types

### H2020

Message:

```text
Declaration Error
Cannot create an instance for `Point` because it is not a typeclass.
```

An instance names something that is not a type class.

This module fails with H2020:

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

The correct form:

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

Message:

```text
Declaration Error
The typeclass `Describe` has no method named `explain`
```

An instance defines a method that its type class does not declare.

This module fails with H2021:

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

The correct form:

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

Message:

```text
Declaration Error
The instance `Describe(Int32)` does not implement every method of the typeclass.

Missing: `explain`.

An instance has to implement every method the typeclass declares, even one whose body does nothing: a method that is simply absent cannot be reported at the call site, only much later and as an internal error.
```

An instance leaves out a method of its type class. The message names the
missing methods.

This module fails with H2022:

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

The correct form:

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

Message:

```text
Declaration Error
The parameter for the typeclass `Measure` cannot be declared to be in the `Region` universe, because regions are distinct from types.

Consider using one of `Type`, `Linear`, or `Free` instead.
```

The parameter of a type class is declared in the Region universe. A region
is not a type, so a type class cannot range over regions.

This module fails with H2023:

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

The correct form:

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

Message:

```text
Declaration Error
The record `Point` was declared to belong to the `Region` universe, but regions are distinct from types.

Consider using one of `Type`, `Linear`, or `Free` instead.
```

A record or union is declared in the Region universe. Only type parameters
can stand for regions; a declared type belongs to Free, Linear or Type.

This module fails with H2024:

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

The correct form:

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

Message:

```text
Declaration Error
Cannot find typeclass with the name `Describe`
```

An instance names a type class that is not declared in the module and not
imported.

This module fails with H2025:

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

The correct form:

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

Message:

```text
Declaration Error
The type parameter `T` does not appear anywhere in the signature of the function.
```

A type parameter of a generic function appears neither in its parameters nor
in its return type, so no call could decide what it stands for.

This module fails with H2026:

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

The correct form:

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

Message:

```text
Declaration Error
The function `show` does not end in a return statement.
```

A function or method ends without a return statement. A function with
nothing to return still ends in return nil. Every path counts: a path ends
in a return, a raise, a call of a function that returns Never such as
abort, or a while whose condition is true. An if without an else that
returns only in its then branch leaves a path open.

This module fails with H2031:

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

The correct form:

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

Message:

```text
Declaration Error
Generic instances can only use each type parameter once in the argument.
```

The argument of a generic instance uses the same type parameter twice. Each
type parameter may appear only once in it.

This module fails with H2032:

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

The correct form:

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

Message:

```text
Declaration Error
The number of type parameters in the instance declaration must be the same as the number of type variables applied to the argument.
```

A generic instance declares more type parameters than its argument uses. The
type parameters and the variables applied in the argument must be the same
in number.

This module fails with H2033:

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

The correct form:

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

Message:

```text
Declaration Error
Typeclass arguments cannot be lone type parameters.
```

The argument of an instance is a bare type parameter. An instance is for a
named type, possibly with type parameters as its arguments.

This module fails with H2034:

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

The correct form:

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

Message:

```text
Declaration Error
The type `Int32` is not a type parameter, but generic instances must use either all type parameters or none of them in the argument.

Consider adding another generic parameter with universe `Free`
```

The argument of a generic instance mixes type parameters with concrete
types. It uses either type parameters only or no type parameters.

This module fails with H2035:

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

The correct form:

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

Message:

```text
Declaration Error
The type parameters in a generic instance declaration cannot have the same name as the type parameter in the corresponding typeclass. The colliding name is `T`.

Give the type parameter of the instance another name.
```

A type parameter of a generic instance has the same name as the parameter of
its type class. The two must be named differently.

This module fails with H2037:

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

The correct form:

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

Message:

```text
Type Error
The type parameter `T` cannot be bound to both `Int32` and `Bool`
```

One type parameter of a generic function would have to stand for two
different types in the same call.

This module fails with H3003:

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

The correct form:

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

Message:

```text
Type Error
The type parameter `T` must be `Free` but `Ticket` is `Linear`
```

A type argument lies in a universe its type parameter does not allow, for
example a Linear type where the parameter is Free.

This module fails with H3004:

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

The correct form:

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

Message:

```text
Type Error
Cannot define an instance with argument `Ticket` because it should belong to the `Free` universe, but it is actually in the `Linear` universe.
```

An instance is given for a type whose universe the type class does not
accept, for example a Linear type for a class over Free types.

This module fails with H3007:

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

The correct form:

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

Message:

```text
Type Error
Both operands to an arithmetic expression must be compatible types. The LHS has type `Int32` but the RHS has type `Int64`.
```

The two operands of an arithmetic operator have different types. Hilde
converts nothing implicitly; convert one operand first.

This module fails with H3008:

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

The correct form:

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

Message:

```text
Type Error
Both operands of an arithmetic operator must be numeric types, but `Bool` is not.
```

An operand of an arithmetic operator is not a number.

This module fails with H3009:

```hilde fails H3009
module body Example is
    function main(): ExitCode is
        let flag: Bool := true;
        printLn(flag + flag);
        return ExitSuccess();
    end;
end module body.
```

The correct form:

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

Message:

```text
Type Error
Negation is not defined for the unsigned type `Nat8`. Its values have no opposite inside the type.
```

A value of an unsigned type is negated. Nat8 to Nat64, Index and ByteSize
have no negative values.

This module fails with H3010:

```hilde fails H3010
module body Example is
    function main(): ExitCode is
        let n: Nat8 := 5;
        printLn(-n);
        return ExitSuccess();
    end;
end module body.
```

The correct form:

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

Message:

```text
Type Error
Negation is not defined for the type `Money`: it does not implement the typeclass `TrappingNegation`. Give it an instance if it should have a negation.
```

A value is negated whose type has no instance of the type class
TrappingNegation. A type of one's own can be given such an instance.

This module fails with H3012:

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

The correct form:

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

Message:

```text
Type Error
The type `Int32` is neither a function, method or function pointer, and cannot be called.
```

Something that is neither a function, a method nor a function pointer is
called.

This module fails with H3020:

```hilde fails H3020
module body Example is
    function main(): ExitCode is
        let n: Int32 := 5;
        printLn(n(1));
        return ExitSuccess();
    end;
end module body.
```

The correct form:

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

Message:

```text
Type Error
The callable `f` expects 2 arguments but 1 was given.
```

A function pointer is called with more or fewer arguments than its type has
parameters. A direct call of a function with the wrong number of arguments
is reported as H6026.

This module fails with H3021:

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

The correct form:

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

Message:

```text
Type Error
Non-exhaustive case statement.
```

A case that binds by name leaves out a case of the union. Every case of the
union needs its own when.

This module fails with H3022:

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

The correct form:

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

Message:

```text
Type Error
Union must be public or from the same module to be used in a case statement.
```

A case looks into a union that another module exports only as an opaque
type. Only a union that is public, or declared in the same module, can be
taken apart with case.

This module fails with H3023:

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

Beside it, `Library.hih`:

```hilde file Library.hih
module Library is
    type Shape: Free;

    function make(): Shape;
end module.
```

Beside it, `Library.hiq`:

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

The correct form:

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

Beside it, `Library.hih`:

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

Beside it, `Library.hiq`:

```hilde file Library.hiq
module body Library is
    function make(): Shape is
        return Circle(radius => 2);
    end;
end module body.
```

### H3024

Message:

```text
Type Error
The case expression has type `Point` which is not a union type.
```

A case that binds by name is given a value of a named type that is not a
union, such as a record.

This module fails with H3024:

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

The correct form:

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

Message:

```text
Type Error
The set of slots (`diameter`) in the case statement doesn't match the set of slots in the union definition (`radius`).
```

A when that binds by name lists slots that the case of the union does not
have, or leaves some out.

This module fails with H3025:

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

The correct form:

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

Message:

```text
Type Error
Cannot cast to `Int32` from `Bool`
```

A value is converted to a type it cannot become. A type annotation e : T
only gives a literal its type, turns a write reference into a read
reference, or tells a generic call its return type.

This module fails with H3027:

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

The correct form:

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

Message:

```text
Type Error
The condition in `if`-statements should be a boolean type, but is `Int32`
```

The condition of an if, a while or an if expression is not a Bool.

This module fails with H3029:

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

The correct form:

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

Message:

```text
Type Error
Arguments to record constructor must be named.
```

A record or a case of a union is built with positional arguments. Its
constructor takes named arguments only.

This module fails with H3030:

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

The correct form:

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

Message:

```text
Type Error
Arguments to record constructor have the wrong names.
```

A constructor is called with names that are not the slots of the record or
of the case.

This module fails with H3031:

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

The correct form:

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

Message:

```text
Type Error
The type `Int32` cannot be destructured because it is not a record.
```

A let with braces takes apart a value of a built-in type, which has no
slots. A union is reported as H3053.

This module fails with H3033:

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

The correct form:

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

Message:

```text
Type Error
The type `Point` is not a public record and so cannot be destructured.
```

A let with braces takes apart a record that another module exports only as
an opaque type. Its slots are not visible outside its module.

This module fails with H3034:

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

Beside it, `Library.hih`:

```hilde file Library.hih
module Library is
    type Point: Free;

    function make(): Point;
end module.
```

Beside it, `Library.hiq`:

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

The correct form:

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

Beside it, `Library.hih`:

```hilde file Library.hih
module Library is
    record Point: Free is
        x: Int32;
    end;

    function make(): Point;
end module.
```

Beside it, `Library.hiq`:

```hilde file Library.hiq
module body Library is
    function make(): Point is
        return Point(x => 1);
    end;
end module body.
```

### H3035

Message:

```text
Type Error
The set of slots mentioned differs from the set of slots in `Point`
```

A let with braces names a set of slots that differs from the slots of the
record. Every slot is named, and no other.

This module fails with H3035:

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

The correct form:

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

Message:

```text
Type Error
The value of this expression has type `Option[Int32]`, which carries a failure the caller is meant to look at, so it may not be thrown away. Handle it with a case statement, hand it to your own caller with the ? operator, or, if the failure really is to be ignored here, say so in the program with ignore(...).
```

An Option or an Either is thrown away by an expression statement. Such a
value carries a failure that someone must look at: handle it with case, pass
it on with ?, or discard it on purpose with ignore.

This module fails with H3037:

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

The correct form:

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

Message:

```text
Type Error
The `?` operator hands a failure back to the caller, so it needs a value that can carry one: an `Option` or an `Either`. This expression has type `Int32`.
```

The operator ? is applied to a value that is neither an Option nor an
Either, so there is no failure to pass on.

This module fails with H3038:

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

The correct form:

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

Message:

```text
Type Error
The `?` operator returns the failure out of the enclosing function, so that function has to be able to carry it. The operand has type `Option[Int32]` but the function returns `Int32`. For an Option the function must return an Option; for an Either it must return an Either whose left type is the same.
```

The operator ? stands in a function that cannot pass the failure on: for an
Option the function must return an Option, for an Either an Either with the
same left type.

This module fails with H3039:

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

The correct form:

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

Message:

```text
Type Error
The `?` operator may only stand as the whole right-hand side of a `let` binding or as a whole statement. It is an early return out of the enclosing function, and it is written where that return is visible on its own line rather than buried inside a larger expression.
```

The operator ? stands inside a larger expression. It may only be the whole
right side of a let or a whole statement, so that the early return is
visible on its own line.

This module fails with H3040:

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

The correct form:

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

Message:

```text
Type Error
The expression is not a valid constant expression.
```

The value of a constant is not a constant expression, for example a function
call.

This module fails with H3041:

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

The correct form:

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

Message:

```text
Type Error
You can't call a function pointer with a named argument list, because function pointers don't preserve parameter names, so we wouldn't know how to assign arguments to parameters.
```

A function pointer is called with named arguments. A function pointer does
not keep the names of the parameters, so its arguments are given by
position.

This module fails with H3043:

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

The correct form:

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

Message:

```text
Type Error
The branches of the `if`-expression have different types: `Int32` and `Bool`
```

The two branches of an if expression have different types.

This module fails with H3044:

```hilde fails H3044
module body Example is
    function main(): ExitCode is
        let flag: Bool := true;
        printLn(if flag then 1 else false);
        return ExitSuccess();
    end;
end module body.
```

The correct form:

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

Message:

```text
Type Error
The operand of a negation operator must be a boolean expression, but it has the type `Int32`
```

The operand of not is not a Bool.

This module fails with H3045:

```hilde fails H3045
module body Example is
    function main(): ExitCode is
        let n: Int32 := 1;
        printLn(not n);
        return ExitSuccess();
    end;
end module body.
```

The correct form:

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

Message:

```text
Type Error
Both operands of a conjunction operator must be boolean expressions, but they have types `Int32` and `Bool`
```

An operand of and or or is not a Bool.

This module fails with H3046:

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

The correct form:

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

Message:

```text
Type Error
The type `Point` has no slot with name `z`
```

A record has no slot of the given name.

This module fails with H3049:

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

The correct form:

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

Message:

```text
Type Error
The typeclass `Describe` has no instance which matches for `Int32`
```

A method of a type class is called with a value whose type has no instance
of that class.

This module fails with H3050:

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

The correct form:

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

Message:

```text
Type Error
The slot `x` is not publically visible in the type `Point` and so cannot be read.
```

A slot is read from a record that another module exports only as an opaque
type.

This module fails with H3052:

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

Beside it, `Library.hih`:

```hilde file Library.hih
module Library is
    type Point: Free;

    function make(): Point;
end module.
```

Beside it, `Library.hiq`:

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

The correct form:

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

Beside it, `Library.hih`:

```hilde file Library.hih
module Library is
    type Point: Free;

    function make(): Point;

    function pointX(p: Point): Int32;
end module.
```

Beside it, `Library.hiq`:

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

Message:

```text
Type Error
Cannot take a path of the type `Shape` because it is not a record.
```

A slot is read from a value of a named type that is not a record, such as a
union. A value of a built-in type is reported as H3057.

This module fails with H3053:

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

The correct form:

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

Message:

```text
Type Error
The slot `number` should have type `Int32` but is declared to have type `Int64`
```

A binding in a case clause declares another type than the slot has.

This module fails with H3054:

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

The correct form:

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

Message:

```text
Type Error
`None` is generic but unconstrained, so its type is ambiguous: its type is `Option[T]`, and nothing here decides `T`.

Give the value a type: declare the variable it goes into with one, or cast it.
```

A generic function whose type parameter appears only in its return type is
called where no type is expected, so its type cannot be decided. An
annotation with a colon decides it.

This module fails with H3055:

```hilde fails H3055
module body Example is
    function main(): ExitCode is
        ignore(None());
        return ExitSuccess();
    end;
end module body.
```

The correct form:

```hilde
module body Example is
    function main(): ExitCode is
        ignore(None() : Option[Int32]);
        return ExitSuccess();
    end;
end module body.
```

### H3056

Message:

```text
Type Error
The type parameter `T` does not implement the type class `Printable`

Consider adding a constraint to the type parameter.
```

Inside a generic function a method of a type class is called on a value of a
type parameter that lacks the constraint for that class.

This module fails with H3056:

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

The correct form:

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

Message:

```text
Type Error
Can't access the slot `value` because the type `Int32` is not a record.
```

A slot is read from a value of a built-in type, which has no slots.

This module fails with H3057:

```hilde fails H3057
module body Example is
    function main(): ExitCode is
        let n: Int32 := 5;
        printLn(n.value);
        return ExitSuccess();
    end;
end module body.
```

The correct form:

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

Message:

```text
Type Error
I can't use the array indexing operator here, because the type `Box` is not a span.
```

The index operator s[i] is used on a value that is not a span.

This module fails with H3058:

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

The correct form:

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

Message:

```text
Type Error
Expected a value of type `Int32`, but got a value of type `Bool`.
```

A value has a different type from the one its place expects, for example in
a return statement.

This module fails with H3060:

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

The correct form:

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

Message:

```text
Type Error
Type constraint not satisfied: the type `Point` does not implement the typeclass `Printable`.

This constraint is for the type variable `T`.
```

A generic function requires a type class of its type parameter, and the type
given for it has no instance of that class.

This module fails with H3061:

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

The correct form:

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

Message:

```text
Type Error
The integer `300` does not fit the type `Nat8`.
```

An integer literal does not fit its type.

This module fails with H3062:

```hilde fails H3062
module body Example is
    function main(): ExitCode is
        let n: Nat8 := 300;
        printLn(n);
        return ExitSuccess();
    end;
end module body.
```

The correct form:

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

Message:

```text
Type Error
The type parameter `T` is expected to be `Free` but the supplied argument is `Linear`
```

A type argument lies in a universe its type parameter does not accept, for
example a Linear type for a parameter in Free.

This module fails with H3063:

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

The correct form:

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

Message:

```text
Type Error
Unable to find a type with the name `Integer`.

Consider importing it, if it is defined in another module.
```

A type name is not known: it is not declared in the module, not imported and
not built in.

This module fails with H3064:

```hilde fails H3064
module body Example is
    function main(): ExitCode is
        let n: Integer := 1;
        printLn(n);
        return ExitSuccess();
    end;
end module body.
```

The correct form:

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

Message:

```text
Type Error
The type for the expression in a case statement must be a union or a reference to a union, but I got `Int32`
```

A case that binds by name is given a value that is neither a union nor a
reference to a union.

This module fails with H3065:

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

The correct form:

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

Message:

```text
Type Error
The when of `Circle` binds its slots by name and type, but this case uses patterns in another when.

A case either binds by name in every when, or uses patterns in every when: write the slots of `Circle` as patterns, one per slot in the order the union declares them.
```

A case uses patterns in one when and binds slots by name and type in
another. A case does one or the other in all its whens.

This module fails with H3071:

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

The correct form:

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

Message:

```text
Type Error
A case with patterns takes a value, but this one is given a reference of type `&[Shape, Region<16>]`.

Matching through a reference is not built; pass the value, or use the case that binds by name, which works on references.
```

A case with patterns is given a reference. Patterns match a value; a case
that binds by name works on references.

This module fails with H3072:

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

The correct form:

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

Message:

```text
Type Error
The variable `other` would match every value of the union `Shape`, and a case over a union has no catch-all.

List the variants; the compiler says which one is missing.
```

A variable stands as a whole pattern in a case over a union. It would match
every value, and a case over a union has no catch-all: every variant is
listed.

This module fails with H3073:

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

The correct form:

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

Message:

```text
Type Error
The pattern `5` can never be chosen: every value it matches is matched by a pattern before it.

Remove it, or move it before the pattern that covers it.
```

A pattern can never be chosen, because the patterns before it already match
every value it matches.

This module fails with H3074:

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

The correct form:

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

Message:

```text
Type Error
The case does not cover every value of `Nat8`: for example `10` matches no when.

Add a when for it.  A case has no else; over an integer a variable or `_` finishes it.
```

A case with patterns leaves out values. The message gives one of them; a
variable or _ at the end completes a case over an integer.

This module fails with H3075:

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

The correct form:

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

Message:

```text
Type Error
The integer pattern `1` stands where the value has the type `Bool`, which is not an integer type.
```

An integer pattern stands where the value is not an integer.

This module fails with H3076:

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

The correct form:

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

Message:

```text
Type Error
`true` is a Bool pattern, but the value here has the type `Int32`.
```

A Bool pattern, true or false, stands where the value is not a Bool.

This module fails with H3077:

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

The correct form:

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

Message:

```text
Type Error
The literal `256` is outside `Nat8`, whose values are `0 .. 255`.

A pattern never truncates or wraps a literal.
```

A literal or a bound of a range lies outside the type of the value. A
pattern never truncates or wraps a literal.

This module fails with H3078:

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

The correct form:

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

Message:

```text
Type Error
The range `9 .. 0` is empty: its lower bound is above its upper bound.

A range lists its lower bound first, and both bounds belong to it.
```

The lower bound of a range is above its upper bound, so the range is empty.

This module fails with H3079:

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

The correct form:

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

Message:

```text
Type Error
The float literal `1.5` cannot be a pattern.

A pattern compares for equality, and two floats that print alike need not be equal.  Only integer and Bool literals are patterns; bind the value to a variable and compare it in the body.
```

A float literal stands as a pattern. Two floats that print alike need not be
equal, so floats are not patterns; bind the value and compare it in the
body.

This module fails with H3080:

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

The correct form:

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

Message:

```text
Type Error
A string literal cannot be a pattern.

Only integer and Bool literals are patterns; bind the value to a variable and compare it in the body.
```

A string literal stands as a pattern. Only integer and Bool literals are
patterns.

This module fails with H3081:

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

The correct form:

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

Message:

```text
Type Error
`_` stands where the value has the type `Ticket`, which is not in the Free universe.

It would drop that value without anyone consuming it.  Bind it to a variable and consume it in the body.
```

The pattern _ stands where the value is not Free. It would drop a linear
value that nobody consumes; bind it to a variable and consume it.

This module fails with H3082:

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

The correct form:

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

Message:

```text
Type Error
The variant `Rectangle` has 2 slot(s), and the pattern gives 1 sub-pattern(s).

A variant pattern gives one sub-pattern for every slot, in the order the union declares them, so that no slot is left out unseen.
```

A variant pattern gives more or fewer sub-patterns than the variant has
slots. Every slot gets one, in the order the union declares them.

This module fails with H3083:

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

The correct form:

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

Message:

```text
Type Error
The alternatives of this when bind different variables: `a` is bound in one alternative and not in another.

The body runs after any of them, so every alternative binds the same variables.
```

The alternatives of one when bind different variables. The body runs after
any of them, so all bind the same variables.

This module fails with H3084:

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

The correct form:

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

Message:

```text
Type Error
The variable `x` has the type `Int8` in one alternative and `Int64` in another.

The body runs after any of them, so a variable has one type in every alternative.
```

A variable has one type in one alternative of a when and another type in
another.

This module fails with H3085:

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

The correct form:

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

Message:

```text
Type Error
The variable `a` is bound twice in one pattern.

A pattern binds each variable once; to compare two parts, bind both and compare them in the body.
```

One pattern binds the same variable twice. To compare two parts, bind both
under different names and compare them in the body.

This module fails with H3086:

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

The correct form:

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

Message:

```text
Type Error
`circle` takes sub-patterns, but its name begins with a lower-case letter, which makes it a variable.

Only a variant takes sub-patterns, and a variant's name begins with an upper-case letter.
```

A name that begins with a lower-case letter takes sub-patterns. Such a name
is a variable; only a variant, with an upper-case initial, takes
sub-patterns.

This module fails with H3087:

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

The correct form:

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

Message:

```text
Type Error
`Square` is not a variant of `Shape`.  Its variants are `Dot, Circle`.
```

A variant pattern names a case the union does not have. The message lists
the variants it has.

This module fails with H3088:

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

The correct form:

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

Message:

```text
Type Error
`Some` is a variant pattern, but the value here has the type `Int32`, which is not a union.
```

A variant pattern stands where the value is not a union.

This module fails with H3089:

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

The correct form:

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

Message:

```text
Type Error
A case with patterns decides on a union, an integer or a Bool, but this value has the type `Float64`.
```

A case with patterns is given a value of a type it cannot decide on.
Patterns decide on a union, an integer or a Bool.

This module fails with H3090:

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

The correct form:

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

Message:

```text
Type Error
`_` would match every value of the union `Shape`, and a case over a union has no catch-all.

List the variants; the compiler says which one is missing.
```

The pattern _ stands as a whole pattern in a case over a union. A case over
a union has no catch-all: every variant is listed.

This module fails with H3091:

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

The correct form:

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

Message:

```text
Type Error
The range `0 .. 1` stands where the value has the type `Bool`, which is not an integer type.
```

A range stands where the value is not an integer.

This module fails with H3092:

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

The correct form:

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

Message:

```text
Type Error
A write reference to part of a value needs a write reference to the value, but the path gives `&[Inner, R]`.

Start the path from a write reference, or take a read reference with `&(...)`.
```

A write reference to part of a value is taken through a read reference.
&!(path) needs the path to start from a write reference; through a read
reference only &(path) reads the part.

This module fails with H3093:

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

The correct form:

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

Message:

```text
Type Error
A reference made inside this function cannot be handed out as `R`.

`R` is a region parameter of the function: the caller chooses it, and it outlives the call.  The reference here has the region `Region<44>`, which ends inside the function.
```

A function returns a reference to one of its local variables in a region
its caller chooses. The caller's region outlives the call, and the local
variable does not.

This module fails with H3094:

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

The correct form:

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

Message:

```text
Type Error
The type parameter `T` would have to be `Int32` here.

The caller chooses the type parameters of a function; its body cannot fix one.
```

The body of a generic function fixes one of the function's own type
parameters. The caller chooses what a type parameter stands for, so the
body must work for every choice.

This module fails with H3095:

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

The correct form:

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

Message:

```text
Linearity Error
`Wallet` was declared to belong to the `Free` universe, but it contains a type that belongs to the `Linear` universe.
```

A record or union declared Free contains a slot of a Linear type, or has a
type parameter that is not Free. A Free value could be copied, and the
linear value inside it with it.

This module fails with H4001:

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

The correct form:

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

Message:

```text
Generic Error
Wrong number of arguments. Expected `2` and got `1`.
```

A function, a method or a constructor is called with more or fewer arguments
than it has parameters.

This module fails with H6026:

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

The correct form:

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

Message:

```text
Generic Error
Orphan rule broken: typeclass and type are both foreign.
```

An instance joins a type class and a type that both come from other modules.
An instance belongs to the module of its type class or of its type.

This module fails with H6032:

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

The correct form:

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

Message:

```text
Generic Error
Orphan rule broken: `Nat8` is a built-in type. It belongs to the language and not to the module that names it, so it is foreign in every module except Hilde.Pervasive and Hilde.Memory, and the typeclass is foreign here too. Define a type of your own and give that the instance.
```

An instance of a type class from another module is given for a built-in
type. A built-in type belongs to the language, so it counts as foreign in
every module; define a type of your own and give that the instance.

This module fails with H6037:

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

The correct form:

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

Message:

```text
Generic Error
Instance overlaps: the typeclass already has an instance for `Bool`. The existing instance is in the module `Example`, the new one is in `Example`. In one program a type may have at most one instance of a typeclass, whichever module declares it.
```

A type gets a second instance of the same type class. In one program a type
has at most one instance of a type class, whichever module declares it.

This module fails with H6038:

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

The correct form:

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

Message:

```text
Generic Error
I can't find a callable named `twice`.
```

A name that is called is neither a function nor a method nor a variable in
scope.

This module fails with H6039:

```hilde fails H6039
module body Example is
    function main(): ExitCode is
        printLn(twice(2));
        return ExitSuccess();
    end;
end module body.
```

The correct form:

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

Message:

```text
Generic Error
Cannot assign a value to a function parameter.
```

An assignment has a function parameter on its left side. Parameters cannot
be changed; copy the value into a var first.

This module fails with H6041:

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

The correct form:

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

Message:

```text
Generic Error
Cannot assign a value to `n` because it is immutable.
```

An assignment changes a variable bound with let. A variable that changes is
bound with var.

This module fails with H6042:

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

The correct form:

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

Message:

```text
Generic Error
The variable `limit` collides with the name of a declaration.
```

A variable has the same name as a declaration of the module, such as a
function or a constant.

This module fails with H6045:

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

The correct form:

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

Message:

```text
Generic Error
The type `Option` expects `1` type arguments, but I only found `2` arguments.
```

A generic type or a built-in type such as Pointer is given the wrong number
of type arguments.

This module fails with H6048:

```hilde fails H6048
module body Example is
    function main(): ExitCode is
        let n: Option[Int32, Bool] := None();
        ignore(n);
        return ExitSuccess();
    end;
end module body.
```

The correct form:

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

Message:

```text
Type Error
The typeclass `Sized` of a constraint is not imported here. A module, its interface too, imports every typeclass its constraints name, as in `import Shape (Sized);`.
```

A constraint of a generic function names a typeclass that the module
which declares the function imports neither in its interface nor in its
body.  The module imports every typeclass its constraints name; without this
check the compiler would stop with an internal error.

This module fails with H3105:

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

Beside it, `Shape.hih`:

```hilde file Shape.hih
module Shape is
    typeclass Sized(T: Free) is
        method sizeOf(value: T): Int32;
    end;

    instance Sized(Int32);
end module.
```

Beside it, `Shape.hiq`:

```hilde file Shape.hiq
module body Shape is
    instance Sized(Int32) is
        method sizeOf(value: Int32): Int32 is
            return 4;
        end;
    end;
end module body.
```

Beside it, `Measure.hih`:

```hilde file Measure.hih
module Measure is
    generic [T: Free(Sized)]
    function measure(value: T): Int32;
end module.
```

Beside it, `Measure.hiq`:

```hilde file Measure.hiq
module body Measure is
    generic [T: Free(Sized)]
    function measure(value: T): Int32 is
        return 0;
    end;
end module body.
```

The correct form:

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

Beside it, `Shape.hih`:

```hilde file Shape.hih
module Shape is
    typeclass Sized(T: Free) is
        method sizeOf(value: T): Int32;
    end;

    instance Sized(Int32);
end module.
```

Beside it, `Shape.hiq`:

```hilde file Shape.hiq
module body Shape is
    instance Sized(Int32) is
        method sizeOf(value: Int32): Int32 is
            return 4;
        end;
    end;
end module body.
```

Beside it, `Measure.hih`:

```hilde file Measure.hih
import Shape (Sized);

module Measure is
    generic [T: Free(Sized)]
    function measure(value: T): Int32;
end module.
```

Beside it, `Measure.hiq`:

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

Message:

```text
Type Error
The C text of this @embed names `abs`, a function the programme imports through pragma Foreign_Import as `cAbs`. The compiler declares an imported function under a name of its own, so in C the name `abs` is not declared. Call `cAbs` in Hilde instead.
```

The compiler declares a function imported from C under a name of its
own, so the C name is not declared in the text of an @embed, and cc
refused the programme with an implicit declaration.  The Hilde function
that imports it is called instead.  A function of the runtime that
lib/prelude.h declares is declared under its C name as well, and an @embed
may call it while a module imports it.

This module fails with H3106:

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

The correct form:

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

Message:

```text
Type Error
The operator `=` compares numbers, Bool, Unit, references, addresses and pointers, but its operands have the type `Span[Nat8, Static]`.

Compare the bytes of two texts with `Standard.Text.equal`.
```

A comparison becomes the operator of C, which compares scalars and
pointers only.  Two spans, two records or two unions would pass the type
checker without this check, and cc would refuse the generated C with
invalid operands.  Two
texts are compared by their bytes with Standard.Text.equal, a record by a
function that compares its slots.  A type variable passes here; H3108 is
the same check where a call gives it its type.

This module fails with H3107:

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

The correct form:

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

Message:

```text
Type Error
The operator `=` compares numbers, Bool, Unit, references, addresses and pointers, but in a use of a generic function its operands have the type `Span[Nat8, Static]`.

Take a function that compares two values as an argument, or a typeclass.
```

The type checker lets a comparison of values of a type variable through,
since a generic function that compares numbers is right.  Where a call gives
the variable a span, a record or a union, the comparison is refused at that
instance, as H3107 refuses it for a type written out; without it, cc would
refuse the generated C.

This module fails with H3108:

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

The correct form:

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

Message:

```text
Type Error
The method `size` names the parameter `T` of its typeclass neither in a parameter nor in its result, so no call can tell which instance it means.

Give it a parameter of that type, a witness whose value it need not read.
```

A call of a method finds the instance it means through the type that stands
for the parameter of the class: in an argument, or in the type the result is
taken as.  A method that names the parameter in neither leaves every call
without an instance; before, the type checker reached such a call and stopped
with an internal error.  The method is refused where the typeclass declares
it.

This module fails with H3111:

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

The correct form:

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

## 3. Linearity

### H3036

Message:

```text
Type Error
Cannot discard a value in the `Linear` universe.
```

An expression statement throws away a value of a Linear type. A linear value
is consumed: passed to a function, returned or taken apart.

This module fails with H3036:

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

The correct form:

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

Message:

```text
Linearity Error
Forgot to consume a linear variable: `value`.
```

A linear variable goes out of scope without being consumed, for example a
variable a when binds that its body does not use.

This module fails with H4002:

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

The correct form:

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

Message:

```text
Linearity Error
The  variable `ticket` was consumed in the loop, without afterwards being reassigned.
```

A linear variable from outside a loop is consumed in the loop body and not
given a new value before the body ends. The next pass would use it a second
time.

This module fails with H4003:

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

The correct form:

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

Message:

```text
Linearity Error
The variable `ticket` is used inconsistently in the branches of an if statement. In one branch it is consumed while in the other it is not yet consumed.
```

The branches of an if or a case treat a linear variable differently: one
consumes it and another does not.

This module fails with H4004:

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

The correct form:

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

Message:

```text
Linearity Error
The variable `ticket` is consumed multiple times within the same expression.
```

One expression consumes the same linear variable twice, for example as two
arguments of one call.

This module fails with H4005:

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

The correct form:

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

Message:

```text
Linearity Error
The variable `ticket` has already been consumed.
```

A linear variable is consumed a second time, in a later statement.

This module fails with H4008:

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

The correct form:

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

Message:

```text
Linearity Error
Cannot assign to the variable `ticket` because it is not yet consumed.

A variable of a linear type takes a new value only after its old one is consumed, and None() of an Option of a linear type is such a value too. Consume the old value first, or give each branch its own value and return it there instead of collecting it in a var.
```

A var holding a linear value is given a new value before the old one is
consumed. The old value would be lost.

This module fails with H4010:

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

The correct form:

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

Message:

```text
Linearity Error
The variable `ticket` is not consumed by the time of the return statement. Did you forget to call a destructor, or destructure the contents?
```

A linear variable is not consumed when the function returns.

This module fails with H4012:

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

The correct form:

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

Message:

```text
Linearity Error
Cannot assign to a path that ends in a type, `Ticket`, not in the Free universe.
```

An assignment to a slot writes a value of a type that is not Free. The old
value in the slot would be lost without being consumed.

This module fails with H4014:

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

The correct form:

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

Message:

```text
Linearity Error
The variable `box` is consumed in one branch of an if expression and not in the other, so one path leaves it unconsumed.

Consume it in both branches, or write the if as a statement whose branches each consume it.
```

One branch of an if expression runs, so a linear variable that only one
branch consumes is left unconsumed on the other path.  Both branches
consume it, or it is consumed before the if.

This module fails with H4015:

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

The correct form:

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

Message:

```text
Type Error
The argument of a task holds a reference or a span.

A task can outlive the borrow the reference comes from, so what is handed to `Standard.Task.spawn` must own everything it points at.  Move the value in, or copy what the task needs.
```

A reference or a span is handed to a task. A task can outlive the borrow the
reference comes from, so its argument owns everything it points at.

This module fails with H3002:

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

The correct form:

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

Message:

```text
Type Error
The type `Point` is not a reference.
```

The arrow -> reads a slot through a reference, and the value before it is
not a reference. A slot of a record value is read with a point.

This module fails with H3005:

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

The correct form:

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

Message:

```text
Type Error
Cannot borrow the variable `counter` mutably because the variable is immutable.
```

A variable bound with let is lent for writing. A variable that is lent for
writing is bound with var.

This module fails with H3018:

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

The correct form:

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

Message:

```text
Type Error
Cannot borrow the variable `counter` mutably because it is a function parameter, and therefore immutable.
You can move it to a mutable local variable: `var mut_counter: Counter := counter;`
```

A function parameter is lent for writing. Parameters cannot be changed; move
the value into a var first, as the message suggests.

This module fails with H3019:

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

The correct form:

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

Message:

```text
Type Error
Cannot cast a reference to one with a different underlying type.
```

A write reference is converted with a colon to a read reference of another
type or another region. The conversion keeps both.

This module fails with H3026:

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

The correct form:

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

Message:

```text
Type Error
Write references can only be casted to a read reference.
```

A write reference is converted with a colon to something that is not a read
reference.

This module fails with H3028:

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

The correct form:

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

Message:

```text
Type Error
Only references can be dereferenced, but `Int32` is not.
```

The operator ! reads the value behind a reference, and it is applied to
something that is not a reference.

This module fails with H3032:

```hilde fails H3032
module body Example is
    function main(): ExitCode is
        let n: Int32 := 5;
        printLn(!n);
        return ExitSuccess();
    end;
end module body.
```

The correct form:

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

Message:

```text
Type Error
The argument of a task in a lending scope holds a reference of another region.

A task started with `Standard.Task.spawnLending` may be lent only what the scope's own borrow lends -- the region the scope was opened for -- because only that borrow is sure to outlive the task.
```

A task of a lending scope is handed a reference of another borrow than the
one the scope lends from. That other borrow can end before the scope is
closed.

This module fails with H3066:

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

The correct form:

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

Message:

```text
Type Error
The argument of a task in a lending scope holds a write reference or a mutable span.

Tasks of a lending scope may only read what they are lent; two tasks holding the same thing to write would each see the other's half-done change.
```

A task of a lending scope is handed a write reference. Tasks of a lending
scope may only read what they are lent.

This module fails with H3067:

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

The correct form:

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

Message:

```text
Type Error
The argument of a task in a lending scope is of a type variable's type.

What a type variable stands for is not known where `Standard.Task.spawnLending` is called, so it cannot be checked for references of another region.  Call it where the argument's type is written out.
```

A task of a lending scope is started with an argument whose type is a type
variable. What it stands for is not known where the task is started, so the
regions cannot be checked there.

This module fails with H3068:

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

The correct form:

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

Message:

```text
Type Error
The argument of a task holds a lending scope.

A task that held the scope could keep it open after the borrow it lends from has ended.  Close the scope where it was opened.
```

A lending scope is handed to a task of another lending scope. A task that
held a scope could keep it open after its borrow ended; a scope is closed
where it was opened.

This module fails with H3069:

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

The correct form:

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

Message:

```text
Type Error
The argument of a task holds a lending scope.

A task that held the scope could keep it open after the borrow it lends from has ended.  Close the scope where it was opened.
```

A lending scope is handed to a task of a plain scope. The task could keep
the lending scope open after the borrow it lends from has ended.

This module fails with H3070:

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

The correct form:

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

Message:

```text
Linearity Error
The variable `ticket` cannot be consumed while it is borrowed (immutably).
```

A variable is consumed while it is lent for reading.

This module fails with H4006:

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

The correct form:

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

Message:

```text
Linearity Error
The variable `ticket` cannot be consumed while it is borrowed (mutably).
```

A variable is consumed while it is lent for writing.

This module fails with H4007:

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

The correct form:

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

Message:

```text
Linearity Error
Cannot borrow (immutably) the variable `ticket` because it is already consumed.
```

A variable is borrowed that is already consumed, or borrowed in a way its
current state does not allow.

This module fails with H4011:

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

The correct form:

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

Message:

```text
Linearity Error
Cannot dereference non-free type `Ticket`
```

The operator ! reads the value behind a reference to a type that is not
Free. Reading it would copy a linear value.

This module fails with H4013:

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

The correct form:

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

Message:

```text
Generic Error
The head of a reference transform expression must be of a reference type, but I got `Point`.

A path into a value is borrowed through a reference to the whole value: write a function that takes `r: &[T, R]` and returns `&(r->slot)`, and call it with `&value`.
```

A reference transform &( ... ) takes a path whose head is not a reference.
The head is a reference, and the path goes on with an arrow.

This module fails with H6043:

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

The correct form:

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

Message:

```text
Generic Error
Can't assign: lvalue is not a mutable reference: &[Int32, Region<17>]
```

An assignment writes through a read reference held in a var. Only a write
reference allows a change: borrow for writing, and hold the write
reference in the var.

This module fails with H6054:

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

The correct form:

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

Message:

```text
Generic Error
Cannot reborrow something that is not a mutable reference: Point
```

A borrow statement reborrows with &~ a variable that is not a write
reference.

This module fails with H6055:

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

The correct form:

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

Message:

```text
Generic Error
`digits` is a constant of the module, and an index or a slot is taken through a variable, which a constant is not. Bind the constant to a local first, as in `let local: T := digits;`, and index the local.
```

An index or a slot is read through a borrow of a variable, and a
constant is no variable.  The constant is bound to a local first, and
the local is indexed.

This module fails with H6059:

```hilde fails H6059
module body Example is
    constant digits: Span[Nat8, Static] := "0123456789";

    function main(): ExitCode is
        printLn(digits[1]);
        return ExitSuccess();
    end;
end module body.
```

The correct form:

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

## 5. Modules

### H2001

Message:

```text
Declaration Error
The interface requires `limit` to be a constant
```

The body defines a name of the interface as a different kind of declaration,
for example a function where the interface declares a constant.

This module fails with H2001:

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

Beside it, `Example.hih`:

```hilde file Example.hih
module Example is
    constant limit: Int32;

    function main(): ExitCode;
end module.
```

The correct form:

```hilde
module body Example is
    constant limit: Int32 := 5;

    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Beside it, `Example.hih`:

```hilde file Example.hih
module Example is
    constant limit: Int32;

    function main(): ExitCode;
end module.
```

### H2002

Message:

```text
Declaration Error
The interface declaration for `twice` and its implementation have different parameters.
```

A function has different type parameters, parameters or return type in the
interface and in the body. The message says which of them differ.

This module fails with H2002:

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

Beside it, `Example.hih`:

```hilde file Example.hih
module Example is
    function twice(n: Int32): Int32;

    function main(): ExitCode;
end module.
```

The correct form:

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

Beside it, `Example.hih`:

```hilde file Example.hih
module Example is
    function twice(n: Int32): Int32;

    function main(): ExitCode;
end module.
```

### H2004

Message:

```text
Declaration Error
`twice` has no corresponding body implementation.
```

The interface declares something that the body does not define.

This module fails with H2004:

```hilde fails H2004
module body Example is
    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Beside it, `Example.hih`:

```hilde file Example.hih
module Example is
    function twice(n: Int32): Int32;

    function main(): ExitCode;
end module.
```

The correct form:

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

Beside it, `Example.hih`:

```hilde file Example.hih
module Example is
    function twice(n: Int32): Int32;

    function main(): ExitCode;
end module.
```

### H2005

Message:

```text
Declaration Error
The instance `Describe` with type `Int32` has no corresponding body implementation.
```

The interface declares an instance that the body does not define.

This module fails with H2005:

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

Beside it, `Example.hih`:

```hilde file Example.hih
module Example is
    typeclass Describe(T: Free) is
        method describe(value: T): Int32;
    end;

    instance Describe(Int32);

    function main(): ExitCode;
end module.
```

The correct form:

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

Beside it, `Example.hih`:

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

Message:

```text
Declaration Error
Module interface and body have different names: `Sample` and `Example`
```

The interface and the body given as a pair on the command line name
different modules.

This module fails with H2006:

```hilde fails H2006
module body Example is
    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Beside it, `Example.hih`:

```hilde file Example.hih
module Sample is
    function main(): ExitCode;
end module.
```

The correct form:

```hilde
module body Example is
    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Beside it, `Example.hih`:

```hilde file Example.hih
module Example is
    function main(): ExitCode;
end module.
```

### H2008

Message:

```text
Declaration Error
The interface declaration for `limit` and its implementation have different types.
```

A declaration has a different type in the interface and in the body, for
example a constant.

This module fails with H2008:

```hilde fails H2008
module body Example is
    constant limit: Int64 := 5;

    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Beside it, `Example.hih`:

```hilde file Example.hih
module Example is
    constant limit: Int32;

    function main(): ExitCode;
end module.
```

The correct form:

```hilde
module body Example is
    constant limit: Int32 := 5;

    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Beside it, `Example.hih`:

```hilde file Example.hih
module Example is
    constant limit: Int32;

    function main(): ExitCode;
end module.
```

### H2009

Message:

```text
Declaration Error
The interface declaration for `Ticket` and its implementation have different universes.
```

An opaque type is declared in one universe in the interface and defined in
another in the body.

This module fails with H2009:

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

Beside it, `Example.hih`:

```hilde file Example.hih
module Example is
    type Ticket: Free;

    function main(): ExitCode;
end module.
```

The correct form:

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

Beside it, `Example.hih`:

```hilde file Example.hih
module Example is
    type Ticket: Linear;

    function main(): ExitCode;
end module.
```

### H2010

Message:

```text
Declaration Error
The module `Example` is unsafe, and this compilation was run with `--forbid-unsafe-modules`.

It is `Example.hiq`, and it carries `pragma Unsafe_Module;`, which is what lets a module hold a foreign function, an `@embed`, or an import from `Hilde.Memory`.

The modules that ship with the compiler are exempt; this applies to the modules named on the command line.
```

The compilation was started with --forbid-unsafe-modules, and one of its
modules is unsafe.

This module fails with H2010:

```hilde fails H2010
pragma Unsafe_Module;

module body Example is
    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Compiled with:

```sh command
hilde compile Example.hiq --entrypoint=Example:main --output=prog --forbid-unsafe-modules
```

The correct form:

```hilde
module body Example is
    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Compiled with:

```sh command
hilde compile Example.hiq --entrypoint=Example:main --output=prog --forbid-unsafe-modules
```

### H2011

Message:

```text
Declaration Error
Invalid Foreign_Import pragma.

This pragma takes exactly one argument, `External_Name`
```

A pragma is given the wrong arguments. The message says which argument it
takes, or that it takes none.

This module fails with H2011:

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

The correct form:

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

Message:

```text
Declaration Error
Unknown pragma `Unsafe_Modul`
```

A pragma has a name the compiler does not know. The pragmas are
Unsafe_Module, Foreign_Library, Foreign_Header, Foreign_Import and
Foreign_Export.

This module fails with H2012:

```hilde fails H2012
pragma Unsafe_Modul;

module body Example is
    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

The correct form:

```hilde
pragma Unsafe_Module;

module body Example is
    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

### H2013

Message:

```text
Declaration Error
Module `Example` is safe and can't name the C library `m`.

A safe module has no C to link against: it can hold neither a `pragma Foreign_Import` nor an `@embed`. Write `pragma Unsafe_Module;` above `module body`, or take the library declaration out.
```

A safe module names a C library. Only a module with pragma Unsafe_Module has
C to link against.

This module fails with H2013:

```hilde fails H2013
pragma Foreign_Library(Name => "m");

module body Example is
    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

The correct form:

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

Message:

```text
Declaration Error
The name in a `pragma Foreign_Library` must not be empty.

It is a library name, the `z` of `-lz`, not a linker switch.
```

The name in pragma Foreign_Library is empty. It is the name of a library,
the z of -lz.

This module fails with H2014:

```hilde fails H2014
pragma Unsafe_Module;
pragma Foreign_Library(Name => "");

module body Example is
    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

The correct form:

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

Message:

```text
Declaration Error
A declaration with the name `twice` already exists in the module `Example`.
```

A module declares the same name twice.

This module fails with H2015:

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

The correct form:

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

Message:

```text
Declaration Error
A module with the name `Example` already exists.
```

Two modules of one compilation have the same name.

This module fails with H2016:

```hilde fails H2016
module body Example is
    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Beside it, `Library.hih`:

```hilde file Library.hih
module Example is
    function answer(): Int32;
end module.
```

Beside it, `Library.hiq`:

```hilde file Library.hiq
module body Example is
    function answer(): Int32 is
        return 42;
    end;
end module body.
```

The correct form:

```hilde
module body Example is
    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Beside it, `Library.hih`:

```hilde file Library.hih
module Library is
    function answer(): Int32;
end module.
```

Beside it, `Library.hiq`:

```hilde file Library.hiq
module body Library is
    function answer(): Int32 is
        return 42;
    end;
end module body.
```

### H2017

Message:

```text
Declaration Error
Unknown module `Library`.
```

An import names a module that is not part of the compilation.  When a module of the compilation has a name a few letters away, the message adds Did you mean and that name.

This module fails with H2017:

```hilde fails H2017
import Library (answer);

module body Example is
    function main(): ExitCode is
        printLn(answer());
        return ExitSuccess();
    end;
end module body.
```

The correct form:

```hilde
import Library (answer);

module body Example is
    function main(): ExitCode is
        printLn(answer());
        return ExitSuccess();
    end;
end module body.
```

Beside it, `Library.hih`:

```hilde file Library.hih
module Library is
    function answer(): Int32;
end module.
```

Beside it, `Library.hiq`:

```hilde file Library.hiq
module body Library is
    function answer(): Int32 is
        return 42;
    end;
end module body.
```

### H2018

Message:

```text
Declaration Error
The function `keep` cannot be exported because it is generic over a type.

An exported function may be generic over regions only: a region has nothing to pass at run time.
```

A function generic over a type carries pragma Foreign_Export. C cannot call
it, because it has no single form. An exported function may be generic over
regions only: a region has nothing to pass at run time, and the function is
made once, for the static region.

This module fails with H2018:

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

The correct form:

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

Message:

```text
Declaration Error
Colliding imports: a declaration with name `question` has already been imported.

Consider giving it a different nickname using `as`, as in `import M (question as otherQuestion);`.
```

Two imports give the same local name. Give one of them another name with as.

This module fails with H2027:

```hilde fails H2027
import Library (answer, question as answer);

module body Example is
    function main(): ExitCode is
        printLn(answer());
        return ExitSuccess();
    end;
end module body.
```

Beside it, `Library.hih`:

```hilde file Library.hih
module Library is
    function answer(): Int32;

    function question(): Int32;
end module.
```

Beside it, `Library.hiq`:

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

The correct form:

```hilde
import Library (answer, question as ask);

module body Example is
    function main(): ExitCode is
        printLn(answer() * ask());
        return ExitSuccess();
    end;
end module body.
```

Beside it, `Library.hih`:

```hilde file Library.hih
module Library is
    function answer(): Int32;

    function question(): Int32;
end module.
```

Beside it, `Library.hiq`:

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

Message:

```text
Declaration Error
Cannot import from the `Hilde.Memory` module in a safe module.

Consider using a safe wrapper or adding `pragma Unsafe_Module;`
```

A safe module imports from Hilde.Memory, whose raw pointers only unsafe
modules may use.

This module fails with H2028:

```hilde fails H2028
import Hilde.Memory (Pointer);

module body Example is
    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

The correct form:

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

Message:

```text
Declaration Error
`secret` is private and cannot be imported.
```

An import names something that its module defines only in the body. What the
interface does not declare is private.

This module fails with H2029:

```hilde fails H2029
import Library (secret);

module body Example is
    function main(): ExitCode is
        printLn(secret());
        return ExitSuccess();
    end;
end module body.
```

Beside it, `Library.hih`:

```hilde file Library.hih
module Library is
    function answer(): Int32;
end module.
```

Beside it, `Library.hiq`:

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

The correct form:

```hilde
import Library (answer);

module body Example is
    function main(): ExitCode is
        printLn(answer());
        return ExitSuccess();
    end;
end module body.
```

Beside it, `Library.hih`:

```hilde file Library.hih
module Library is
    function answer(): Int32;
end module.
```

Beside it, `Library.hiq`:

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

Message:

```text
Declaration Error
No declaration with the name `question` in the module `Library`
```

An import names something that its module does not have at all.

This module fails with H2030:

```hilde fails H2030
import Library (question);

module body Example is
    function main(): ExitCode is
        printLn(question());
        return ExitSuccess();
    end;
end module body.
```

Beside it, `Library.hih`:

```hilde file Library.hih
module Library is
    function answer(): Int32;
end module.
```

Beside it, `Library.hiq`:

```hilde file Library.hiq
module body Library is
    function answer(): Int32 is
        return 42;
    end;
end module body.
```

The correct form:

```hilde
import Library (answer);

module body Example is
    function main(): ExitCode is
        printLn(answer());
        return ExitSuccess();
    end;
end module body.
```

Beside it, `Library.hih`:

```hilde file Library.hih
module Library is
    function answer(): Int32;
end module.
```

Beside it, `Library.hiq`:

```hilde file Library.hiq
module body Library is
    function answer(): Int32 is
        return 42;
    end;
end module body.
```

### H2038

Message:

```text
Declaration Error
`@embed` pastes C straight into the generated program, and the compiler does not check that C. It is allowed only in a module that says so: write `pragma Unsafe_Module;` above `module body`, or move the `@embed` into a module that already has the pragma.
```

A safe module uses @embed, which pastes C that the compiler does not check.
Only a module with pragma Unsafe_Module may do so.

This module fails with H2038:

```hilde fails H2038
module body Example is
    function main(): ExitCode is
        let n: Int32 := @embed(Int32, "42");
        printLn(n);
        return ExitSuccess();
    end;
end module body.
```

The correct form:

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

Message:

```text
Declaration Error
Can't declare a foreign function in a safe module.
```

A safe module binds a C function with pragma Foreign_Import.

This module fails with H2039:

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

The correct form:

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

Message:

```text
Declaration Error
Foreign functions can't have type parameters.
```

A function bound to C with Foreign_Import has type parameters. A C function
has one fixed signature.

This module fails with H2040:

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

The correct form:

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

Message:

```text
Declaration Error
Only import and export pragmas are allowed inside functions.
```

A pragma other than Foreign_Import or Foreign_Export stands before a
function. Module pragmas stand before module body.

This module fails with H2041:

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

The correct form:

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

Message:

```text
Declaration Error
Module `Example` is safe and can't name the C header `sys/utsname.h`.

A header gives C's own constants to an `@embed`, and a safe module can hold none. Write `pragma Unsafe_Module;` above `module body`, or take the header declaration out.
```

A safe module names a C header with pragma Foreign_Header.

This module fails with H2042:

```hilde fails H2042
pragma Foreign_Header(Name => "sys/utsname.h");

module body Example is
    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

The correct form:

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

Message:

```text
Declaration Error
The name in a `pragma Foreign_Header` is not a header name: `../secret.h`

It is what stands between the angle brackets of an `#include`, such as `openssl/evp.h`: letters, digits and `_ . / + -`, not empty, not starting with a slash, and without a `..` part.
```

The name in pragma Foreign_Header is not a header name. It is what stands
between the angle brackets of an include: letters, digits and _ . / + -, not
starting with a slash and without a .. part.

This module fails with H2043:

```hilde fails H2043
pragma Unsafe_Module;
pragma Foreign_Header(Name => "../secret.h");

module body Example is
    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

The correct form:

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

Message:

```text
Declaration Error
This programme links both `sqlite3` and `sqlcipher`, which export the same functions.

Import `Standard.Sqlite` or `Standard.SqlCipher`, not both.  The module that brought the second one is `Bindings.C.SqlCipher`.
```

A program imports both Standard.Sqlite and Standard.SqlCipher. The two C
libraries export the same functions, so a program links only one of them.

This module fails with H2044:

```hilde fails H2044
import Standard.Sqlite (Connection);
import Standard.SqlCipher (Connection as CipherConnection);

module body Example is
    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

The correct form:

```hilde
import Standard.Sqlite (Connection);

module body Example is
    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

### H2045

Message:

```text
Declaration Error
`Example` imports from `Bindings.Time`, a module that binds C.

Only the standard library imports a module whose name begins with `Bindings.`; a program imports the safe module built on it, whose name begins with `Standard.`.
```

A program imports a module whose name begins with Bindings. Such a module
binds C and is unsafe, and what makes it safe to call is checked at the
Standard module built on it, which is the one a program imports. Only a
module whose name begins with Standard. or Bindings. may import it.

This module fails with H2045:

```hilde fails H2045
import Bindings.Time (wallNanos);

module body Example is
    function main(): ExitCode is
        printLn(wallNanos() > 0);
        return ExitSuccess();
    end;
end module body.
```

The correct form:

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

Message:

```text
Declaration Error
The function `keep` cannot be exported under the name `hilde_keep`: names beginning with hilde_ belong to the runtime.
```

The name a function is exported under is one that C cannot give it: not a
C identifier, a keyword of C or main, a name beginning with hilde_, which
the runtime keeps for its own, or a name another function is exported
under already.

This module fails with H2050:

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

The correct form:

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

Message:

```text
Declaration Error
A foreign function can't return `Bool`. C gives a truth value as an int, and a Bool would keep only its lowest byte, so 256 would be false.

Import the C result as `Int32` and compare it with `/= 0`.
```

A function bound to C with Foreign_Import returns Bool.  A C function gives a
truth value as an int, which may be any value but 0 for true, and the
generated C reads only the lowest byte of it: isalpha of glibc answers 1024
for a letter, whose lowest byte is 0.  The C result is imported as Int32
and compared with /= 0 in Hilde.

This module fails with H2059:

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

The correct form:

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

Message:

```text
Type Error
The type `Span[Int32, R]` is not allowed in the signature of an exported function.
```

A function exported to C with Foreign_Export has a parameter or return type
that cannot cross to C, such as a span of anything but Nat8, a record with
type parameters or a reference to a number. What crosses, and how, stands in
docs/syntax.en.md, where a library is built.

This module fails with H3001:

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

The correct form:

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

Message:

```text
Generic Error
I can't find a callable named `size` here. The module `Other` declares one; import it, as in `import Other (size);`. A module interface imports what its own contracts call, apart from its body.
```

The function exists in another module, which the message names, but it
is not imported here.  An interface imports what its own requires and
ensures call: an import of the module body does not reach the interface.

This module fails with H6060:

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

Beside it, `Example.hih`:

```hilde file Example.hih
module Example is
    function count(n: Int32): Int32
        ensures size(result) >= 0;

    function main(): ExitCode;
end module.
```

Beside it, `Other.hih`:

```hilde file Other.hih
module Other is
    function size(n: Int32): Int32;
end module.
```

Beside it, `Other.hiq`:

```hilde file Other.hiq
module body Other is
    function size(n: Int32): Int32 is
        return n;
    end;
end module body.
```

The correct form:

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

Beside it, `Example.hih`:

```hilde file Example.hih
import Other (size);

module Example is
    function count(n: Int32): Int32
        ensures size(result) >= 0;

    function main(): ExitCode;
end module.
```

Beside it, `Other.hih`:

```hilde file Other.hih
module Other is
    function size(n: Int32): Int32;
end module.
```

Beside it, `Other.hiq`:

```hilde file Other.hiq
module body Other is
    function size(n: Int32): Int32 is
        return n;
    end;
end module body.
```

## 6. Other

This section holds the codes of the command line, of the entrypoint and of
the consistency checks inside the compiler. A consistency check guards a
state that an earlier stage of the compiler rules out; it cannot be reached
from a program, and its entry says which earlier check comes first.

H9999 does not stand at one place in the compiler: it is the code of its
function for internal errors, which is called wherever the compiler finds a
state that should not occur.

### H1001

Message:

```text
Command Line Arguments Error
Invalid entrypoint format `Example.main`

The entrypoint must be supplied in the form `Module:name`
```

The value of --entrypoint is not of the form Module:function.

This module fails with H1001:

```hilde fails H1001
module body Example is
    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Compiled with:

```sh command
hilde compile Example.hiq --entrypoint=Example.main --output=prog
```

The correct form:

```hilde
module body Example is
    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Compiled with:

```sh command
hilde compile Example.hiq --entrypoint=Example:main --output=prog
```

### H1002

Message:

```text
Command Line Arguments Error
Invalid module source format `Example.hiq,Example.hiq,Example.hiq`

Sources must be supplied as either`interface.hih,body.hiq` or `body.hiq`
```

A module on the command line is given as neither one body file nor an
interface and a body joined by a comma.

This module fails with H1002:

```hilde fails H1002
module body Example is
    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Compiled with:

```sh command
hilde compile Example.hiq,Example.hiq,Example.hiq --entrypoint=Example:main --output=prog
```

The correct form:

```hilde
module body Example is
    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Compiled with:

```sh command
hilde compile Example.hiq --entrypoint=Example:main --output=prog
```

### H1003

Message:

```text
Command Line Arguments Error
`--entrypoint` argument not provided.
```

The compile command has no --entrypoint. A program needs one; a C file
without one is built with --target-type=c and --no-entrypoint.

This module fails with H1003:

```hilde fails H1003
module body Example is
    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Compiled with:

```sh command
hilde compile Example.hiq --output=prog
```

The correct form:

```hilde
module body Example is
    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Compiled with:

```sh command
hilde compile Example.hiq --entrypoint=Example:main --output=prog
```

### H1004

Message:

```text
Command Line Arguments Error
The `compile` command must specify at least one module.
```

The compile command names no module.

This module fails with H1004:

```hilde fails H1004
module body Example is
    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Compiled with:

```sh command
hilde compile --entrypoint=Example:main --output=prog
```

The correct form:

```hilde
module body Example is
    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Compiled with:

```sh command
hilde compile Example.hiq --entrypoint=Example:main --output=prog
```

### H1005

Message:

```text
Command Line Arguments Error
`--output` argument not provided.
```

The compile command has no --output.

This module fails with H1005:

```hilde fails H1005
module body Example is
    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Compiled with:

```sh command
hilde compile Example.hiq --entrypoint=Example:main
```

The correct form:

```hilde
module body Example is
    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Compiled with:

```sh command
hilde compile Example.hiq --entrypoint=Example:main --output=prog
```

### H1006

Message:

```text
Command Line Arguments Error
`--no-entrypoint` requires `--target-type=c`, `static`, `shared` or `wasm`, because otherwise the compiler will try to build an executable, and will fail because there is no entrypoint function.
```

The compiler is told to leave out the entrypoint, and its target is
neither C nor a library. A programme without an entrypoint is written as C
or built as a library, for a programme of another language to link.

This module fails with H1006:

```hilde fails H1006
module body Example is
    function answer(): Int32 is
        return 42;
    end;
end module body.
```

Compiled with:

```sh command
hilde compile Example.hiq --no-entrypoint --output=prog
```

The correct form:

```hilde
module body Example is
    function answer(): Int32 is
        return 42;
    end;
end module body.
```

Compiled with:

```sh command
hilde compile Example.hiq --no-entrypoint --target-type=c --output=example.c
```

### H1007

Message:

```text
Command Line Arguments Error
Unknown target type `binary`
```

The value of --target-type is none of exe, c, tc, static and shared.

This module fails with H1007:

```hilde fails H1007
module body Example is
    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Compiled with:

```sh command
hilde compile Example.hiq --entrypoint=Example:main --output=prog --target-type=binary
```

The correct form:

```hilde
module body Example is
    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Compiled with:

```sh command
hilde compile Example.hiq --entrypoint=Example:main --output=prog --target-type=exe
```

### H1008

Message:

```text
Command Line Arguments Error
Unknown error reporting mode: `xml`. Valid values are `plain`, `json`, `hilde-json` and `json-lines`.
```

The value of --error-format is none of plain, json, hilde-json and json-lines.

This module fails with H1008:

```hilde fails H1008
module body Example is
    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Compiled with:

```sh command
hilde compile Example.hiq --entrypoint=Example:main --output=prog --error-format=xml
```

The correct form:

```hilde
module body Example is
    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Compiled with:

```sh command
hilde compile Example.hiq --entrypoint=Example:main --output=prog --error-format=json
```

### H1009

Message:

```text
Command Line Arguments Error
The argument `output` was given multiple times
```

A flag is given twice.

This module fails with H1009:

```hilde fails H1009
module body Example is
    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Compiled with:

```sh command
hilde compile Example.hiq --entrypoint=Example:main --output=prog --output=other
```

The correct form:

```hilde
module body Example is
    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Compiled with:

```sh command
hilde compile Example.hiq --entrypoint=Example:main --output=prog
```

### H1010

Message, from the source in `lib/CliUtil.ml`:

```text
Argument list must have at least one element in it, the path to the binary. Was the compiler invoked through a system call?
```

The argument list of the compiler is empty, not even the name of the program
is in it. A shell always passes the name, so only a program that starts the
compiler without it could reach this message.

It stays because a program can reach it without any Hilde source: one
that starts the compiler with execve and an empty argument list. The
check turns that into a message instead of an exception.

Not triggered: no program was found that reaches this error.

### H1011

Message:

```text
Command Line Arguments Error
Expected `forbid-unsafe-modules` to be a boolean flag, but it was given as a value flag.
```

A flag that takes no value is given one, as in --flag=value.

This module fails with H1011:

```hilde fails H1011
module body Example is
    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Compiled with:

```sh command
hilde compile Example.hiq --entrypoint=Example:main --output=prog --forbid-unsafe-modules=yes
```

The correct form:

```hilde
module body Example is
    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Compiled with:

```sh command
hilde compile Example.hiq --entrypoint=Example:main --output=prog --forbid-unsafe-modules
```

### H1012

Message:

```text
Command Line Arguments Error
Expected `output` to be a value flag, but it was given as a boolean flag.
```

A flag that takes a value is given without one.

This module fails with H1012:

```hilde fails H1012
module body Example is
    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Compiled with:

```sh command
hilde compile Example.hiq --entrypoint=Example:main --output
```

The correct form:

```hilde
module body Example is
    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Compiled with:

```sh command
hilde compile Example.hiq --entrypoint=Example:main --output=prog
```

### H1013

Message:

```text
Command Line Arguments Error
Invalid flag argument `--output=prog=bin`
```

A flag holds more than one equals sign, so it is neither --flag nor
--flag=value.

This module fails with H1013:

```hilde fails H1013
module body Example is
    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Compiled with:

```sh command
hilde compile Example.hiq --entrypoint=Example:main --output=prog=bin
```

The correct form:

```hilde
module body Example is
    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Compiled with:

```sh command
hilde compile Example.hiq --entrypoint=Example:main --output=prog
```

### H1014

Message, from the source in `lib/Util.ml`:

```text
Failed to run C compiler. Command: ... Exit code: ... Standard output: ... Standard error: ...
```

The C compiler refused the C code the compiler generated. With a correct
program this points at C pasted in with @embed, at a missing C library, or
at a fault in the compiler. The message quotes the C compiler's command and
its output. For --target-type=static the archiver ar(1) runs after the C
compiler; when it fails, the code is the same and the message begins Failed
to run the archiver ar.

This module fails with H1014:

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

The correct form:

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

Message:

```text
Command Line Arguments Error
Failed to write to file `missing/Example.c`:

missing/Example.c: No such file or directory
```

The compiler could not open or write its output file, for example because
its directory does not exist or the device is full.

This module fails with H1015:

```hilde fails H1015
module body Example is
    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Compiled with:

```sh command
hilde compile Example.hiq --entrypoint=Example:main --target-type=c --output=missing/Example.c
```

The correct form:

```hilde
module body Example is
    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Compiled with:

```sh command
hilde compile Example.hiq --entrypoint=Example:main --target-type=c --output=example.c
```

### H1016

Message, from the source in `lib/Util.ml`:

```text
Failed to write to file ...
```

This is the message for a failure to write that is not a system error; a
system error, such as a missing directory, is H1015. No way was found to
make writing fail otherwise.

It stays because it is the other branch of the handler that writes the
output file: a failure there that is not a system error. The check
turns it into a message that names the file instead of an exception.

Not triggered: no program was found that reaches this error.

### H1017

Message:

```text
Command Line Arguments Error
The module `Sample` is not on the command line, so there is nothing to query.
```

hilde query asks about a module that is not on the command line.

This module fails with H1017:

```hilde fails H1017
module body Example is
    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Compiled with:

```sh command
hilde query Example.hiq --module=Sample
```

The correct form:

```hilde
module body Example is
    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Compiled with:

```sh command
hilde query Example.hiq --module=Example
```

### H1018

Message:

```text
Command Line Arguments Error
`hilde query` needs `--module=Name`: the module to describe.
```

hilde query is called without --module, so it does not know which module to
describe.

This module fails with H1018:

```hilde fails H1018
module body Example is
    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Compiled with:

```sh command
hilde query Example.hiq
```

The correct form:

```hilde
module body Example is
    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Compiled with:

```sh command
hilde query Example.hiq --module=Example
```

### H1019

Message:

```text
Command Line Arguments Error
`hilde test` names no path: give the directories to search for test files, or test files by name.
```

hilde test is called without a path, so it has nowhere to look for tests.

This module fails with H1019:

```hilde fails H1019
module body Example.Test is
    function testNothing(): Unit is
        return nil;
    end;
end module body.
```

Run with:

```sh command
hilde test
```

The correct form:

```hilde
module body Example.Test is
    function testNothing(): Unit is
        return nil;
    end;
end module body.
```

Run with:

```sh command
hilde test Example.hiq
```

### H1020

Message:

```text
Command Line Arguments Error
The flags `--race` and `--memory` of `hilde test` exclude one another.

A run takes at most one of `--race`, `--memory` and `--valgrind`, and `--emit-c` builds and runs nothing, so it takes none of them.
```

hilde test is given two flags that exclude one another: two of the
instruments --race, --memory and --valgrind, or --emit-c beside one of them.

ThreadSanitizer and AddressSanitizer cannot be built into one programme, and
valgrind runs a programme built without either; --emit-c writes C and builds
nothing, so an instrument beside it would do nothing.

This module fails with H1020:

```hilde fails H1020
module body Example.Test is
    function testNothing(): Unit is
        return nil;
    end;
end module body.
```

Run with:

```sh command
hilde test --race --memory Example.hiq
```

The correct form:

```hilde
module body Example.Test is
    function testNothing(): Unit is
        return nil;
    end;
end module body.
```

Run with:

```sh command
hilde test Example.hiq
```

### H1021

Message, from the source in `lib/TestRunner.ml`:

```text
`hilde test <flag>` cannot run on this system: <what failed>
The answer was: <the first line the C compiler or valgrind wrote>
```

hilde test is given an instrument, --race, --memory or --valgrind, that this
system cannot run: its C compiler does not build or run a programme with the
instrument's flags, valgrind cannot be started, or the C compiler does not
find valgrind's header valgrind/valgrind.h.

hilde test asks before it builds anything: a programme that does nothing is
compiled with the flags and run, and valgrind is asked for its version and a
programme that reads its header is compiled.  The runtime needs the header
under --valgrind: it registers every task stack with valgrind.

It stays because the systems the gates run on differ in exactly this: in the
Linux gate every instrument runs, while OpenBSD's C compiler refuses
-fsanitize=address and -fsanitize=thread and the system has no valgrind. An
example here would say something else on the other system;
scripts/check-hilde-test.sh, which the OpenBSD gate runs, prints every
refusal with its words. In both gates it also puts a C compiler first on
PATH that refuses every -fsanitize option, and holds hilde test --race and
--memory to this error with that compiler's words and no test run.

Not triggered: no example reaches this error on every system the gates run
on.

### H1022

Message:

```text
Command Line Arguments Error
`missing` is neither a directory nor a file ending in .hiq.
```

A path given to hilde test is neither a directory nor a .hiq file, for
example because it does not exist.

This module fails with H1022:

```hilde fails H1022
module body Example.Test is
    function testNothing(): Unit is
        return nil;
    end;
end module body.
```

Run with:

```sh command
hilde test missing
```

The correct form:

```hilde
module body Example.Test is
    function testNothing(): Unit is
        return nil;
    end;
end module body.
```

Run with:

```sh command
hilde test Example.hiq
```

### H1023

Message:

```text
Command Line Arguments Error
There is no test file under `.`.

A test file is a module body whose file name ends in .test.hiq, or a .hiq file named on the command line.
```

hilde test searched the directories it was given and found no test file in
them.

This module fails with H1023:

```hilde fails H1023
module body Example is
    function double(n: Nat32): Nat32 is
        return n * 2;
    end;
end module body.
```

Run with:

```sh command
hilde test .
```

The correct form:

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

Run with:

```sh command
hilde test .
```

### H1024

Message:

```text
Command Line Arguments Error
The module `Example` is declared by two files, `./Example.hiq` and `./Other.hiq`, and a test programme imports it, so there is no telling which one it means.
```

Two files under the paths of hilde test declare the same module, and a test
file imports it.

A name that two files declare is refused only when a test programme needs
it; elsewhere in the directories it does no harm.

This module fails with H1024:

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

Run with:

```sh command
hilde test .
```

The correct form:

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

Run with:

```sh command
hilde test .
```

### H1025

Message:

```text
Command Line Arguments Error
The interface `./Other.hih` has no body `./Other.hiq` beside it, so its module cannot be compiled.
```

A directory hilde test searches for modules holds an interface without the
body of the same name beside it.

This module fails with H1025:

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

Run with:

```sh command
hilde test .
```

The correct form:

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

Run with:

```sh command
hilde test .
```

### H1026

Message:

```text
Command Line Arguments Error
`--target-type=static` builds a library, and a library has no entrypoint: `--entrypoint` cannot be given with it.

The functions a library offers are the ones marked `pragma Foreign_Export`, called from C after `hilde_start`.
```

A library is built, --target-type=static, shared or wasm, and the command line
names an entrypoint as well. A library has no entrypoint: C calls the
functions it exports, after hilde_start.

This module fails with H1026:

```hilde fails H1026
module body Example is
    pragma Foreign_Export(External_Name => "example_twice");
    function twice(x: Int32): Int32 is
        return x * 2;
    end;
end module body.
```

Compiled with:

```sh command
hilde compile Example.hiq --target-type=static --entrypoint=Example:main --output=libexample.a
```

The correct form:

```hilde
module body Example is
    pragma Foreign_Export(External_Name => "example_twice");
    function twice(x: Int32): Int32 is
        return x * 2;
    end;
end module body.
```

Compiled with:

```sh command
hilde compile Example.hiq --target-type=static --output=libexample.a
```

### H1027

Message:

```text
Command Line Arguments Error
The output of `--target-type=shared` must end in `.so`, and `libexample.a` does not.

The header is written beside the library under the same name ending in `.h`.
```

The output of a library does not end in the suffix of its kind, .a for
--target-type=static and .so for shared, or is the suffix alone. The
header is written beside the library under the same name ending in .h, so
the name has to say where its suffix begins.

This module fails with H1027:

```hilde fails H1027
module body Example is
    pragma Foreign_Export(External_Name => "example_twice");
    function twice(x: Int32): Int32 is
        return x * 2;
    end;
end module body.
```

Compiled with:

```sh command
hilde compile Example.hiq --target-type=shared --output=libexample.a
```

The correct form:

```hilde
module body Example is
    pragma Foreign_Export(External_Name => "example_twice");
    function twice(x: Int32): Int32 is
        return x * 2;
    end;
end module body.
```

Compiled with:

```sh command
hilde compile Example.hiq --target-type=shared --output=libexample.so
```

### H1028

Message:

```text
Command Line Arguments Error
The value of `--seed` is `18446744073709551616`, which is not a decimal number from 0 to 18446744073709551615.
```

hilde test --contracts is given a seed or a number of rounds that is not
a decimal number in its range.

A seed is a Nat64, from 0 to 18446744073709551615, since it is written into
the programme that draws the inputs as one; the rounds are from 1 to
100000, since a run of none would test nothing.

This module fails with H1028:

```hilde fails H1028
module body Example.Test is
    function testNothing(): Unit is
        return nil;
    end;
end module body.
```

Run with:

```sh command
hilde test --contracts --seed=18446744073709551616 Example.hiq
```

The correct form:

```hilde
module body Example.Test is
    function testNothing(): Unit is
        return nil;
    end;
end module body.
```

Run with:

```sh command
hilde test --contracts --seed=18446744073709551615 Example.hiq
```

### H1029

Message:

```text
Command Line Arguments Error
`--seed` is read only by `hilde test --contracts`, and this run has no `--contracts`.

Add `--contracts`, or leave the flag out.
```

hilde test is given --seed or --rounds without --contracts.

Only a run that tests contracts draws inputs, so without it the flag would
change nothing, and a flag that changes nothing is refused rather than
ignored.

This module fails with H1029:

```hilde fails H1029
module body Example.Test is
    function testNothing(): Unit is
        return nil;
    end;
end module body.
```

Run with:

```sh command
hilde test --seed=7 Example.hiq
```

The correct form:

```hilde
module body Example.Test is
    function testNothing(): Unit is
        return nil;
    end;
end module body.
```

Run with:

```sh command
hilde test --contracts --seed=7 Example.hiq
```

### H1030

Message:

```text
Command Line Arguments Error
The entrypoint `Example:start` is not a function of a module on the command line.
```

hilde guard is given an entrypoint that is not a function of a module on
its command line.

The walk over the programme's calls starts at the entrypoint, so a name
that is not there would leave nothing to walk from; it is refused rather
than read as no entrypoint at all.

This module fails with H1030:

```hilde fails H1030
module body Example is
    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Compiled with:

```sh command
hilde guard Example.hiq --entrypoint=Example:start
```

The correct form:

```hilde
module body Example is
    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Compiled with:

```sh command
hilde guard Example.hiq --entrypoint=Example:main
```

### H1031

Message:

```text
Command Line Arguments Error
The vulnerability database `missing.json` cannot be read: there is no such file or directory.
```

hilde guard is given a vulnerability database it cannot read: a path that is
not there, a file that is not JSON, or a record that is not in the OSV
format.

A check that could not read its database would find nothing, and a report
without findings would look like a programme without vulnerabilities; so
the database is read before the programme is compiled, and a fault in it
ends the command.

This module fails with H1031:

```hilde fails H1031
module body Example is
    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Compiled with:

```sh command
hilde guard Example.hiq --vulndb=missing.json
```

The correct form:

```hilde
module body Example is
    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Beside it, `osv.json`:

```json file osv.json
[]
```

Compiled with:

```sh command
hilde guard Example.hiq --vulndb=osv.json
```

### H1032

Message:

```text
Command Line Arguments Error
`sqlite3` in --library-versions is not a library, a colon and a version of numbers separated by dots, such as `--library-versions=sqlite3:3.46.1,tls:4.3.0`.
```

An entry of --library-versions is not the name of a library as it is
linked, a colon and a version of numbers separated by dots.

The versions are compared number by number with the ranges of the
advisories; a version in another form could not be compared, and is
refused rather than taken as no version.

This module fails with H1032:

```hilde fails H1032
module body Example is
    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Compiled with:

```sh command
hilde guard Example.hiq --library-versions=sqlite3
```

The correct form:

```hilde
module body Example is
    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Compiled with:

```sh command
hilde guard Example.hiq --library-versions=sqlite3:3.46.1
```

### H1033

Message:

```text
Command Line Arguments Error
hilde fmt: `Example.hiq.txt` is neither a directory nor a .hih or .hiq file.
```

A path given to hilde fmt is neither a directory, whose Hilde sources are
formatted, nor a file whose name ends in .hih or .hiq.  A file of another
kind is not taken for a source.

This module fails with H1033:

```hilde fails H1033
module body Example is
    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Compiled with:

```sh command
hilde fmt Example.hiq.txt
```

The correct form:

```hilde
module body Example is
    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Compiled with:

```sh command
hilde fmt Example.hiq
```

### H1034

Message:

```text
Command Line Arguments Error
Failed to read file `Missing.hiq`:

Missing.hiq: No such file or directory
```

A file given to the compiler could not be opened or read: it does not exist,
it is a directory, or it may not be read.  hilde check, hilde compile, hilde
test and hilde fmt report it so; before, the compiler ended with an exception
of OCaml.

This module fails with H1034:

```hilde fails H1034
module body Example is
    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Compiled with:

```sh command
hilde compile Missing.hiq --entrypoint=Example:main --target-type=c --output=example.c
```

The correct form:

```hilde
module body Example is
    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Compiled with:

```sh command
hilde compile Example.hiq --entrypoint=Example:main --target-type=c --output=example.c
```

### H1035

Message:

```text
Command Line Arguments Error
The build value `1channel=stable` is refused: the name is not valid.

It is written --build-value=name=value, the name a letter and then letters, digits, _, . or -, at most 64 bytes, the value printable ASCII, at most 1024 bytes, each name once.
```

A value given with --build-value, which a programme reads with
Standard.BuildInfo's value, is written name=value.  The name starts with a
letter and holds letters, digits, _, . and -, at most 64 bytes; the value is
printable ASCII, at most 1024 bytes; each name is given once.

This module fails with H1035:

```hilde fails H1035
module body Example is
    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Compiled with:

```sh command
hilde compile Example.hiq --entrypoint=Example:main --target-type=c --output=example.c --build-value=1channel=stable
```

The correct form:

```hilde
module body Example is
    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Compiled with:

```sh command
hilde compile Example.hiq --entrypoint=Example:main --target-type=c --output=example.c --build-value=channel=stable
```

### H1036

Message:

```text
Command Line Arguments Error
SOURCE_DATE_EPOCH is `17x0`, which is not a number of seconds since 1970: one to eighteen decimal digits.
```

SOURCE_DATE_EPOCH gives the time of the build that Standard.BuildInfo's
builtAt returns, so that two builds can give the same bytes.  A value that is
not a number of seconds ends hilde compile, whether or not the programme
imports the module, as the specification of the variable asks.

This module fails with H1036:

```hilde fails H1036
module body Example is
    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Compiled with:

```sh command
env SOURCE_DATE_EPOCH=17x0 hilde compile Example.hiq --entrypoint=Example:main --target-type=c --output=example.c
```

The correct form:

```hilde
module body Example is
    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Compiled with:

```sh command
env SOURCE_DATE_EPOCH=1700000000 hilde compile Example.hiq --entrypoint=Example:main --target-type=c --output=example.c
```

### H1037

Message:

```text
Command Line Arguments Error
Unknown command `chek`. The commands are build, compile, test, lsp, modules, fmt, check, query, guard, run, get, update, verify, export, new, install, doc, api-diff. Did you mean `check`?
```

The first word is not a command of hilde.  Before, hilde printed its usage
and ended with 0, so a tool that ran a command this compiler does not have,
such as check on an older one, took that for success.  The message names
the commands and, for a word a few letters away from one, that command.

This module fails with H1037:

```hilde fails H1037
module body Example is
    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Compiled with:

```sh command
hilde chek Example.hiq
```

The correct form:

```hilde
module body Example is
    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Compiled with:

```sh command
hilde check Example.hiq
```

### H2046

Message:

```text
Declaration Error
The function `testLength` has the name of a test, and a test has one of two forms:

`function testName(): Unit`, or, for a test that needs the root capability, `generic [R: Region] function testName(root: &![RootCapability, R]): Unit`.

In a test file every function whose name is test followed by a capital letter or a digit is a test.
```

A function of a test file has the name of a test and another form than a
test's.

The name makes it a test: test followed by a capital letter or a digit. A
test takes nothing and gives nothing back, or takes the root capability; a
function with a test's name in any other form is refused rather than left
out, because a test that is silently not run looks exactly like one that
passed.

This module fails with H2046:

```hilde fails H2046
module body Example.Test is
    function testLength(n: Nat32): Unit is
        return nil;
    end;
end module body.
```

Run with:

```sh command
hilde test Example.hiq
```

The correct form:

```hilde
module body Example.Test is
    function testLength(): Unit is
        return nil;
    end;
end module body.
```

Run with:

```sh command
hilde test Example.hiq
```

### H2047

Message:

```text
Declaration Error
The test file `Example.hiq` holds no test.

A test is a function whose name is test followed by a capital letter or a digit, such as `testLength`.
```

A test file declares no function with the name of a test.

This module fails with H2047:

```hilde fails H2047
module body Example.Test is
    function helper(): Unit is
        return nil;
    end;
end module body.
```

Run with:

```sh command
hilde test Example.hiq
```

The correct form:

```hilde
module body Example.Test is
    function testLength(): Unit is
        return nil;
    end;
end module body.
```

Run with:

```sh command
hilde test Example.hiq
```

### H2048

Message:

```text
Declaration Error
The system `linux` in a `pragma Foreign_Library` is not one this compiler knows.

It is compared with what `uname -s` prints on the machine that compiles the programme, and must be one of `Linux, OpenBSD, FreeBSD, NetBSD, Darwin`, written as it prints them.
```

A pragma Foreign_Library names a system the compiler does not know. The
system is compared with what uname -s prints, so it is written as uname
writes it, with its capitals. A misspelt system would never match, and its
library would never be linked, so it is refused instead.

This module fails with H2048:

```hilde fails H2048
pragma Unsafe_Module;
pragma Foreign_Library(Name => "m", System => "linux");

module body Example is
    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

The correct form:

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

Message:

```text
Declaration Error
Invalid `pragma Foreign_Library`.

It takes the argument `Name`, and after it, for a library linked on one system only, `System`: `pragma Foreign_Library(Name => "crypt", System => "Linux");`
```

A pragma Foreign_Library has arguments it does not take, or its two in the
other order. It takes Name, and after it System when the library is linked
on one system only.

This module fails with H2049:

```hilde fails H2049
pragma Unsafe_Module;
pragma Foreign_Library(System => "Linux", Name => "m");

module body Example is
    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

The correct form:

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

Message:

```text
Type Error
This pattern can never compile: `Standard.Regex: lookaround is not supported -- it cannot be matched in linear time; Standard.Pcre has it at byte 1`.  Standard.Regex's compile would return that as its Left when the programme runs; a literal pattern is checked now.
```

A literal pattern handed to compile of Standard.Regex is one that the module
would refuse when the program runs. A literal pattern is checked when the
program is compiled.

This module fails with H3059:

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

The correct form:

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

Message:

```text
Entrypoint Definition Error
The entrypoint function should take a single parameter with type `RootCapability`, or none at all, but it has several.
```

The entry point function takes more than one parameter. It takes none, or
one of type RootCapability.

This module fails with H5001:

```hilde fails H5001
module body Example is
    function main(root: RootCapability, n: Int32): ExitCode is
        surrenderRoot(root);
        return ExitSuccess();
    end;
end module body.
```

The correct form:

```hilde
module body Example is
    function main(root: RootCapability): ExitCode is
        surrenderRoot(root);
        return ExitSuccess();
    end;
end module body.
```

### H5002

Message:

```text
Entrypoint Definition Error
No function named `start` in module `Example`
```

The module named in --entrypoint has no function of the given name.

This module fails with H5002:

```hilde fails H5002
module body Example is
    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Compiled with:

```sh command
hilde compile Example.hiq --entrypoint=Example:start --output=prog
```

The correct form:

```hilde
module body Example is
    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Compiled with:

```sh command
hilde compile Example.hiq --entrypoint=Example:main --output=prog
```

### H5003

Message:

```text
Entrypoint Definition Error
The entrypoint must be a function.
```

The entry point named in --entrypoint is not a function, for example a
constant.

This module fails with H5003:

```hilde fails H5003
module body Example is
    constant start: Int32 := 1;

    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Compiled with:

```sh command
hilde compile Example.hiq --entrypoint=Example:start --output=prog
```

The correct form:

```hilde
module body Example is
    constant start: Int32 := 1;

    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Compiled with:

```sh command
hilde compile Example.hiq --entrypoint=Example:main --output=prog
```

### H5004

Message:

```text
Entrypoint Definition Error
The entrypoint function cannot be generic.
```

The entry point function is generic.

This module fails with H5004:

```hilde fails H5004
module body Example is
    generic [T: Free]
    function main(value: T): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

The correct form:

```hilde
module body Example is
    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

### H5005

Message:

```text
Entrypoint Definition Error
The entrypoint function is not public.

Consider declaring it in the module interface.
```

The module has an interface, and the interface does not declare the entry
point function. Declare it there.

This module fails with H5005:

```hilde fails H5005
module body Example is
    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Beside it, `Example.hih`:

```hilde file Example.hih
module Example is
end module.
```

The correct form:

```hilde
module body Example is
    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Beside it, `Example.hih`:

```hilde file Example.hih
module Example is
    function main(): ExitCode;
end module.
```

### H5006

Message:

```text
Entrypoint Definition Error
The type of the entrypoint argument must be `RootCapability` but it is `Int32`
```

The one parameter of the entry point function is not of type RootCapability.

This module fails with H5006:

```hilde fails H5006
module body Example is
    function main(n: Int32): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

The correct form:

```hilde
module body Example is
    function main(root: RootCapability): ExitCode is
        surrenderRoot(root);
        return ExitSuccess();
    end;
end module body.
```

### H5007

Message:

```text
Entrypoint Definition Error
The type of the entrypoint function must be `ExitCode` but it is `Int32`
```

The entry point function does not return ExitCode.

This module fails with H5007:

```hilde fails H5007
module body Example is
    function main(): Int32 is
        return 0;
    end;
end module body.
```

The correct form:

```hilde
module body Example is
    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

### H6001

Message:

```text
Generic Error
@bytes("../data.txt"): the path leaves the module's own directory, which is not allowed
```

The path in @bytes is empty, absolute or contains a .. part. A module may
only embed a file beside itself or below it.

This module fails with H6001:

```hilde fails H6001
module body Example is
    function main(): ExitCode is
        let data: Span[Nat8, Static] := @bytes("../data.txt");
        printLn(spanLength(data));
        return ExitSuccess();
    end;
end module body.
```

Beside it, `data.txt`:

```text file data.txt
Hello
```

The correct form:

```hilde
module body Example is
    function main(): ExitCode is
        let data: Span[Nat8, Static] := @bytes("data.txt");
        printLn(spanLength(data));
        return ExitSuccess();
    end;
end module body.
```

Beside it, `data.txt`:

```text file data.txt
Hello
```

### H6002

Message:

```text
Generic Error
@bytes("missing.txt"): cannot read it: ./missing.txt: No such file or directory
```

The file named in @bytes cannot be read, for example because it does not
exist beside the module.

This module fails with H6002:

```hilde fails H6002
module body Example is
    function main(): ExitCode is
        let data: Span[Nat8, Static] := @bytes("missing.txt");
        printLn(spanLength(data));
        return ExitSuccess();
    end;
end module body.
```

The correct form:

```hilde
module body Example is
    function main(): ExitCode is
        let data: Span[Nat8, Static] := @bytes("data.txt");
        printLn(spanLength(data));
        return ExitSuccess();
    end;
end module body.
```

Beside it, `data.txt`:

```text file data.txt
Hello
```

### H6005

Message:

```text
Generic Error
There are leftover arguments.
```

The command line holds an argument the compile or query command does not
use, such as an unknown flag.

This module fails with H6005:

```hilde fails H6005
module body Example is
    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Compiled with:

```sh command
hilde compile Example.hiq --entrypoint=Example:main --output=prog --verbose
```

The correct form:

```hilde
module body Example is
    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Compiled with:

```sh command
hilde compile Example.hiq --entrypoint=Example:main --output=prog
```

### H6013

Message:

```text
Generic Error
Borrow expressions not allowed in this context.
```

A borrow expression stands where no statement can hold the borrow, for
example in the value of a constant.

This module fails with H6013:

```hilde fails H6013
module body Example is
    constant limit: Int32 := 5;

    constant view: &[Int32, Static] := &limit;

    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

The correct form:

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

Message:

```text
Generic Error
The name `n` is bound already in this function. A name stays bound until the end of the block it was bound in, also after its value is consumed, so a second binding needs a name of its own, as in `value as otherN`.
```

A function binds the same name twice in the same scope, for example with two
lets. Hilde has no shadowing; give the second variable another name.

This module fails with H6020:

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

The correct form:

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

Message:

```text
Generic Error
Region map already has a region with this name
```

Two nested borrow statements give their regions the same name.

This module fails with H6025:

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

The correct form:

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

Message:

```text
Generic Error
Duplicate type parameter `T`
```

A list of type parameters names the same parameter twice.

This module fails with H6047:

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

The correct form:

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

Message, from the source in `lib/Error.ml`:

```text
Internal compiler error: ...

This is a bug in the compiler.
```

An internal error: the compiler reached a state its own checks should have
ruled out. It is a fault in the compiler, not in the program.  The way in
this entry showed, a constraint naming a type class that is not imported,
is now H3105.

It stays because every internal error of the compiler carries it: a check that only a fault of the
compiler can reach raises H9999 rather than a code of its own.

Not triggered: no program was found that reaches this error.

## 7. Templates

Every example in this section is the same module: a linear record Page with
the fields title, motto, items, admin and count, and a function render that
writes the page through @template into a StringBuilder. The examples differ
in the template beside the module, and for the first codes in the name of
the template.

The message of a template error names the place in the template file.

### H7001

Message:

```text
Generic Error
@template: the template name is empty
```

The name of a template is empty.

This module fails with H7001:

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

Beside it, `page.jinja`:

```jinja file page.jinja
<p>{{ title }}</p>
```

The correct form:

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

Beside it, `page.jinja`:

```jinja file page.jinja
<p>{{ title }}</p>
```

### H7002

Message:

```text
Generic Error
@template: "/page.jinja": the path is absolute, and a template may only be read from beside the module
```

The path of a template is absolute. A template is read from beside the
module, or below it.

This module fails with H7002:

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

Beside it, `page.jinja`:

```jinja file page.jinja
<p>{{ title }}</p>
```

The correct form:

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

Beside it, `page.jinja`:

```jinja file page.jinja
<p>{{ title }}</p>
```

### H7003

Message:

```text
Generic Error
@template: "../page.jinja": the path leaves the module's own directory, which is not allowed
```

The path of a template contains a .. part and so leaves the module's
directory.

This module fails with H7003:

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

Beside it, `page.jinja`:

```jinja file page.jinja
<p>{{ title }}</p>
```

The correct form:

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

Beside it, `page.jinja`:

```jinja file page.jinja
<p>{{ title }}</p>
```

### H7004

Message:

```text
Generic Error
@template: "missing.jinja": cannot read it: ./missing.jinja: No such file or directory
```

A template file cannot be read, for example because it does not exist beside
the module.

This module fails with H7004:

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

Beside it, `page.jinja`:

```jinja file page.jinja
<p>{{ title }}</p>
```

The correct form:

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

Beside it, `page.jinja`:

```jinja file page.jinja
<p>{{ title }}</p>
```

### H7005

Message:

```text
Generic Error
@template: this tag is never closed with }}
```

A tag {{ or {% is opened and never closed.

This module fails with H7005:

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

Beside it, `page.jinja`:

```jinja file page.jinja
<p>{{ title</p>
```

The correct form:

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

Beside it, `page.jinja`:

```jinja file page.jinja
<p>{{ title }}</p>
```

### H7006

Message:

```text
Generic Error
@template: this comment is never closed with #}
```

A comment {# is opened and never closed with #}.

This module fails with H7006:

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

Beside it, `page.jinja`:

```jinja file page.jinja
<p>{# a note</p>
```

The correct form:

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

Beside it, `page.jinja`:

```jinja file page.jinja
<p>{# a note #}</p>
```

### H7007

Message:

```text
Generic Error
@template: this {% raw %} is never closed with {% endraw %}
```

A {% raw %} is never closed with {% endraw %}.

This module fails with H7007:

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

Beside it, `page.jinja`:

```jinja file page.jinja
<p>{% raw %}{{ title }}</p>
```

The correct form:

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

Beside it, `page.jinja`:

```jinja file page.jinja
<p>{% raw %}{{ title }}{% endraw %}</p>
```

### H7008

Message:

```text
Generic Error
@template: {% endraw %} is not closed with %}
```

The {% endraw %} tag holds something after endraw.

This module fails with H7008:

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

Beside it, `page.jinja`:

```jinja file page.jinja
<p>{% raw %}x{% endraw now %}</p>
```

The correct form:

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

Beside it, `page.jinja`:

```jinja file page.jinja
<p>{% raw %}x{% endraw %}</p>
```

### H7009

Message:

```text
Generic Error
@template: only whole decimal numbers are supported
```

A number in a template is not a whole decimal number, such as 1.5.

This module fails with H7009:

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

Beside it, `page.jinja`:

```jinja file page.jinja
<p>{{ 1.5 }}</p>
```

The correct form:

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

Beside it, `page.jinja`:

```jinja file page.jinja
<p>{{ 15 }}</p>
```

### H7011

Message:

```text
Generic Error
@template: the escape \x in a string is not supported
```

A string in a tag holds an escape other than `\n`, `\t`, `\r`, `\\`, `\'`
and `\"`.

This module fails with H7011:

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

Beside it, `page.jinja`:

```jinja file page.jinja
<p>{{ "a\x" }}</p>
```

The correct form:

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

Beside it, `page.jinja`:

```jinja file page.jinja
<p>{{ "a\n" }}</p>
```

### H7013

Message:

```text
Generic Error
@template: the character ; cannot stand here
```

A character stands in a tag that is no part of the template language.

This module fails with H7013:

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

Beside it, `page.jinja`:

```jinja file page.jinja
<p>{{ title; }}</p>
```

The correct form:

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

Beside it, `page.jinja`:

```jinja file page.jinja
<p>{{ title }}</p>
```

### H7014

Message:

```text
Generic Error
@template: expected )
```

The expression in a tag lacks a symbol it needs, such as a closing
parenthesis.

This module fails with H7014:

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

Beside it, `page.jinja`:

```jinja file page.jinja
<p>{{ (title }}</p>
```

The correct form:

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

Beside it, `page.jinja`:

```jinja file page.jinja
<p>{{ (title) }}</p>
```

### H7015

Message:

```text
Generic Error
@template: expected a name
```

A name is expected in a tag and something else stands there, for example
after a point.

This module fails with H7015:

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

Beside it, `page.jinja`:

```jinja file page.jinja
<p>{{ title. }}</p>
```

The correct form:

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

Beside it, `page.jinja`:

```jinja file page.jinja
<p>{{ title }}</p>
```

### H7016

Message:

```text
Generic Error
@template: the operator / divides into a fraction, and @template has no fractions; // divides into a whole number
```

An operator of Jinja2 that has no meaning here stands in a tag: / divides into a fraction, which a template here does not have, and ** raises to a power, which leaves every integer type after a few steps. // divides into a whole number.

This module fails with H7016:

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

Beside it, `page.jinja`:

```jinja file page.jinja
<p>{{ count / 2 }}</p>
```

The correct form:

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

Beside it, `page.jinja`:

```jinja file page.jinja
<p>{{ count // 2 }}</p>
```

### H7017

Message:

```text
Generic Error
@template: an inline if prints its two values the same way: both |safe, or neither
```

The two values of an inline if ... else are printed differently: one is marked |safe and the other is not. Or an inline if stands in a condition, where and and or say the same.

This module fails with H7017:

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

Beside it, `page.jinja`:

```jinja file page.jinja
<p>{{ title|safe if admin else "guest" }}</p>
```

The correct form:

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

Beside it, `page.jinja`:

```jinja file page.jinja
<p>{{ title if admin else "guest" }}</p>
```

### H7018

Message:

```text
Generic Error
@template: `in' asks for a text in quotes or a name of a string
```

The operator in asks a name of the data, a string for a part of it or a buffer for an element, and it asks for a text in quotes or a name of a string.

This module fails with H7018:

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

Beside it, `page.jinja`:

```jinja file page.jinja
<p>{% if 1 in items %}one{% endif %}</p>
```

The correct form:

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

Beside it, `page.jinja`:

```jinja file page.jinja
<p>{% if "a" in title %}one{% endif %}</p>
```

### H7019

Message:

```text
Generic Error
@template: expected , or )
```

The arguments of a filter are not separated by commas or not closed.

This module fails with H7019:

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

Beside it, `page.jinja`:

```jinja file page.jinja
<p>{{ title|trim(1 2) }}</p>
```

The correct form:

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

Beside it, `page.jinja`:

```jinja file page.jinja
<p>{{ title|trim }}</p>
```

### H7020

Message:

```text
Generic Error
@template: keyword arguments are not supported
```

A macro is called with a keyword argument, name=value. Arguments are given
by position.

This module fails with H7020:

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

Beside it, `page.jinja`:

```jinja file page.jinja
{% macro show(x) %}<p>{{ x }}</p>{% endmacro %}{{ show(x=title) }}
```

The correct form:

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

Beside it, `page.jinja`:

```jinja file page.jinja
{% macro show(x) %}<p>{{ x }}</p>{% endmacro %}{{ show(title) }}
```

### H7021

Message:

```text
Generic Error
@template: expected , or )
```

The arguments of a macro call are not separated by commas or not closed.

This module fails with H7021:

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

Beside it, `page.jinja`:

```jinja file page.jinja
{% macro show(x, y) %}<p>{{ x }}{{ y }}</p>{% endmacro %}{{ show(title title) }}
```

The correct form:

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

Beside it, `page.jinja`:

```jinja file page.jinja
{% macro show(x, y) %}<p>{{ x }}{{ y }}</p>{% endmacro %}{{ show(title, title) }}
```

### H7022

Message:

```text
Generic Error
@template: calling title.upper: there is no such macro; the part before the dot is not a name an {% import ... as %} gave, or the file has no macro of that name
```

A macro is called through a dot, and the part before it is not a name that an {% import ... as %} gave, or the file it names has no such macro. A method of a value cannot be called.

This module fails with H7022:

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

Beside it, `page.jinja`:

```jinja file page.jinja
<p>{{ title.upper() }}</p>
```

The correct form:

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

Beside it, `page.jinja`:

```jinja file page.jinja
<p>{{ title|upper }}</p>
```

### H7023

Message:

```text
Generic Error
@template: [ ] takes a name in quotes, as in a["b"]: an index into a list fails when the page is rendered if the list is shorter, which a compiled template cannot allow
```

Square brackets hold something other than a name in quotes. An index into a list fails when Jinja2 renders the page and the list is shorter; a compiled template does not allow that.

This module fails with H7023:

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

Beside it, `page.jinja`:

```jinja file page.jinja
<p>{{ items[0] }}</p>
```

The correct form:

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

Beside it, `page.jinja`:

```jinja file page.jinja
<p>{% for item in items %}{% if loop.first %}{{ item }}{% endif %}{% endfor %}</p>
```

### H7024

Message:

```text
Generic Error
@template: a minus sign stands before a number only; write 0 - x to subtract from zero
```

A minus sign stands before a name. A negative number is written with a minus sign before its digits; a name is subtracted from zero.

This module fails with H7024:

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

Beside it, `page.jinja`:

```jinja file page.jinja
<p>{{ -count }}</p>
```

The correct form:

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

Beside it, `page.jinja`:

```jinja file page.jinja
<p>{{ 0 - count }}</p>
```

### H7025

Message:

```text
Generic Error
@template: unexpected )
```

A symbol stands in a tag where an expression should begin.

This module fails with H7025:

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

Beside it, `page.jinja`:

```jinja file page.jinja
<p>{{ ) }}</p>
```

The correct form:

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

Beside it, `page.jinja`:

```jinja file page.jinja
<p>{{ title }}</p>
```

### H7026

Message:

```text
Generic Error
@template: an expression is missing
```

A tag holds no expression.

This module fails with H7026:

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

Beside it, `page.jinja`:

```jinja file page.jinja
<p>{{ }}</p>
```

The correct form:

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

Beside it, `page.jinja`:

```jinja file page.jinja
<p>{{ title }}</p>
```

### H7027

Message:

```text
Generic Error
@template: unexpected text after the expression
```

An expression in a tag is followed by more text.

This module fails with H7027:

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

Beside it, `page.jinja`:

```jinja file page.jinja
<p>{{ title title }}</p>
```

The correct form:

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

Beside it, `page.jinja`:

```jinja file page.jinja
<p>{{ title }}</p>
```

### H7028

Message:

```text
Generic Error
@template: a {% %} tag must begin with a keyword
```

A {% %} tag does not begin with a keyword.

This module fails with H7028:

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

Beside it, `page.jinja`:

```jinja file page.jinja
<p>{% = title %}</p>
```

The correct form:

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

Beside it, `page.jinja`:

```jinja file page.jinja
<p>{{ title }}</p>
```

### H7029

Message:

```text
Generic Error
@template: {% do %} is not supported
```

A {% %} tag uses a keyword this template language does not support, such as
do.

This module fails with H7029:

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

Beside it, `page.jinja`:

```jinja file page.jinja
{% do title %}<p>{{ title }}</p>
```

The correct form:

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

Beside it, `page.jinja`:

```jinja file page.jinja
<p>{{ title }}</p>
```

### H7030

Message:

```text
Generic Error
@template: {% include %} takes the template's name and nothing after it
```

An {% include %} or {% extends %} takes the template's name and nothing
after it.

This module fails with H7030:

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

Beside it, `page.jinja`:

```jinja file page.jinja
{% include "part.jinja" "more" %}
```

Beside it, `part.jinja`:

```jinja file part.jinja
<p>{{ title }}</p>
```

The correct form:

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

Beside it, `page.jinja`:

```jinja file page.jinja
{% include "part.jinja" %}
```

Beside it, `part.jinja`:

```jinja file part.jinja
<p>{{ title }}</p>
```

### H7031

Message:

```text
Generic Error
@template: {% include %} takes a string literal: a template chosen when the page is rendered cannot be compiled
```

An {% include %} or {% extends %} takes a name that is not a string literal.
A template chosen when the page is rendered cannot be compiled.

This module fails with H7031:

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

Beside it, `page.jinja`:

```jinja file page.jinja
{% include title %}
```

Beside it, `part.jinja`:

```jinja file part.jinja
<p>{{ title }}</p>
```

The correct form:

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

Beside it, `page.jinja`:

```jinja file page.jinja
{% include "part.jinja" %}
```

Beside it, `part.jinja`:

```jinja file part.jinja
<p>{{ title }}</p>
```

### H7032

Message:

```text
Generic Error
@template: {% import %} takes a string literal, `as' and a name: {% import "file" as name %}
```

An {% import %} lacks `as` and a name, or asks for the template's context with `with context`. An imported macro does not see the template's data.

This module fails with H7032:

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

Beside it, `page.jinja`:

```jinja file page.jinja
{% import "macros.jinja" %}<p>{{ title }}</p>
```

Beside it, `macros.jinja`:

```jinja file macros.jinja
{% macro show(text) %}<b>{{ text }}</b>{% endmacro %}
```

The correct form:

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

Beside it, `page.jinja`:

```jinja file page.jinja
{% import "macros.jinja" as lib %}<p>{{ lib.show(title) }}</p>
```

Beside it, `macros.jinja`:

```jinja file macros.jinja
{% macro show(text) %}<b>{{ text }}</b>{% endmacro %}
```

### H7033

Message:

```text
Generic Error
@template: {% autoescape %} is refused: escaping cannot be switched off for a stretch of template -- write |safe on the one value that is meant to go out unescaped, where a grep finds it
```

A template uses {% autoescape %}. Escaping cannot be switched off for a
stretch; mark the one value that goes out unescaped with `|safe`.

This module fails with H7033:

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

Beside it, `page.jinja`:

```jinja file page.jinja
{% autoescape false %}<p>{{ title }}</p>{% endautoescape %}
```

The correct form:

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

Beside it, `page.jinja`:

```jinja file page.jinja
<p>{{ title|safe }}</p>
```

### H7034

Message:

```text
Generic Error
@template: {% endif %} without the tag it belongs to
```

A closing or continuing tag, such as {% endif %} or {% else %}, stands
without its opening tag.

This module fails with H7034:

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

Beside it, `page.jinja`:

```jinja file page.jinja
<p>{{ title }}</p>{% endif %}
```

The correct form:

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

Beside it, `page.jinja`:

```jinja file page.jinja
<p>{{ title }}</p>
```

### H7035

Message:

```text
Generic Error
@template: {% else %} without {% endif %}
```

An {% else %} of an {% if %} is not followed by {% endif %}.

This module fails with H7035:

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

Beside it, `page.jinja`:

```jinja file page.jinja
{% if admin %}<p>admin</p>{% else %}<p>guest</p>
```

The correct form:

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

Beside it, `page.jinja`:

```jinja file page.jinja
{% if admin %}<p>admin</p>{% else %}<p>guest</p>{% endif %}
```

### H7036

Message:

```text
Generic Error
@template: {% if %} without {% endif %}
```

An {% if %} is never closed with {% endif %}.

This module fails with H7036:

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

Beside it, `page.jinja`:

```jinja file page.jinja
{% if admin %}<p>admin</p>
```

The correct form:

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

Beside it, `page.jinja`:

```jinja file page.jinja
{% if admin %}<p>admin</p>{% endif %}
```

### H7037

Message:

```text
Generic Error
@template: {% for %} takes one name, or two or three that unpack a Pair or a Triple of Standard.Tuples
```

A {% for %} names more than three names. One name takes the element; two or three unpack a Pair or a Triple of Standard.Tuples.

This module fails with H7037:

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

Beside it, `page.jinja`:

```jinja file page.jinja
{% for a, b, c, d in items %}{{ a }}{% endfor %}
```

The correct form:

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

Beside it, `page.jinja`:

```jinja file page.jinja
{% for item in items %}{{ item }}{% endfor %}
```

### H7038

Message:

```text
Generic Error
@template: expected `in' in {% for %}
```

A {% for %} lacks the word in.

This module fails with H7038:

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

Beside it, `page.jinja`:

```jinja file page.jinja
{% for item of items %}{{ item }}{% endfor %}
```

The correct form:

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

Beside it, `page.jinja`:

```jinja file page.jinja
{% for item in items %}{{ item }}{% endfor %}
```

### H7039

Message:

```text
Generic Error
@template: after {% for ... in ... %} only `if' and a condition may follow
```

Something other than `if` and a condition follows the sequence of a {% for %}, such as `recursive`.

This module fails with H7039:

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

Beside it, `page.jinja`:

```jinja file page.jinja
{% for item in items recursive %}{{ item }}{% endfor %}
```

The correct form:

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

Beside it, `page.jinja`:

```jinja file page.jinja
{% for item in items if item > 1 %}{{ item }}{% endfor %}
```

### H7040

Message:

```text
Generic Error
@template: {% else %} without {% endfor %}
```

An {% else %} of a {% for %} is not followed by {% endfor %}.

This module fails with H7040:

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

Beside it, `page.jinja`:

```jinja file page.jinja
{% for item in items %}{{ item }}{% else %}<p>none</p>
```

The correct form:

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

Beside it, `page.jinja`:

```jinja file page.jinja
{% for item in items %}{{ item }}{% else %}<p>none</p>{% endfor %}
```

### H7041

Message:

```text
Generic Error
@template: {% for %} without {% endfor %}
```

A {% for %} is never closed with {% endfor %}.

This module fails with H7041:

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

Beside it, `page.jinja`:

```jinja file page.jinja
{% for item in items %}{{ item }}
```

The correct form:

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

Beside it, `page.jinja`:

```jinja file page.jinja
{% for item in items %}{{ item }}{% endfor %}
```

### H7042

Message:

```text
Generic Error
@template: a `required' block is not supported
```

A block is marked required.

This module fails with H7042:

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

Beside it, `page.jinja`:

```jinja file page.jinja
{% block main required %}<p>{{ title }}</p>{% endblock %}
```

The correct form:

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

Beside it, `page.jinja`:

```jinja file page.jinja
{% block main %}<p>{{ title }}</p>{% endblock %}
```

### H7043

Message:

```text
Generic Error
@template: {% block %} takes a name, and `scoped' after it
```

A {% block %} has no name, or something other than scoped after it.

This module fails with H7043:

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

Beside it, `page.jinja`:

```jinja file page.jinja
{% block %}<p>{{ title }}</p>{% endblock %}
```

The correct form:

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

Beside it, `page.jinja`:

```jinja file page.jinja
{% block main %}<p>{{ title }}</p>{% endblock %}
```

### H7044

Message:

```text
Generic Error
@template: {% block main %} without {% endblock %}
```

A {% block %} is never closed with {% endblock %}.

This module fails with H7044:

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

Beside it, `page.jinja`:

```jinja file page.jinja
{% block main %}<p>{{ title }}</p>
```

The correct form:

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

Beside it, `page.jinja`:

```jinja file page.jinja
{% block main %}<p>{{ title }}</p>{% endblock %}
```

### H7045

Message:

```text
Generic Error
@template: {% endblock side %} closes {% block main %}
```

An {% endblock %} names another block than the one it closes.

This module fails with H7045:

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

Beside it, `page.jinja`:

```jinja file page.jinja
{% block main %}<p>{{ title }}</p>{% endblock side %}
```

The correct form:

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

Beside it, `page.jinja`:

```jinja file page.jinja
{% block main %}<p>{{ title }}</p>{% endblock main %}
```

### H7046

Message:

```text
Generic Error
@template: a macro parameter's default is a literal
```

The default of a macro parameter is not a literal.

This module fails with H7046:

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

Beside it, `page.jinja`:

```jinja file page.jinja
{% macro show(x=title) %}{{ x }}{% endmacro %}<p>{{ show() }}</p>
```

The correct form:

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

Beside it, `page.jinja`:

```jinja file page.jinja
{% macro show(x="none") %}{{ x }}{% endmacro %}<p>{{ show() }}</p>
```

### H7047

Message:

```text
Generic Error
@template: expected , or ) in the macro's parameters
```

The parameters of a macro are not separated by commas.

This module fails with H7047:

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

Beside it, `page.jinja`:

```jinja file page.jinja
{% macro show(x y) %}{{ x }}{% endmacro %}<p>{{ show(title, title) }}</p>
```

The correct form:

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

Beside it, `page.jinja`:

```jinja file page.jinja
{% macro show(x, y) %}{{ x }}{% endmacro %}<p>{{ show(title, title) }}</p>
```

### H7048

Message:

```text
Generic Error
@template: unexpected text after the macro's parameters
```

Text follows the parameter list of a macro.

This module fails with H7048:

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

Beside it, `page.jinja`:

```jinja file page.jinja
{% macro show(x) now %}{{ x }}{% endmacro %}<p>{{ show(title) }}</p>
```

The correct form:

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

Beside it, `page.jinja`:

```jinja file page.jinja
{% macro show(x) %}{{ x }}{% endmacro %}<p>{{ show(title) }}</p>
```

### H7049

Message:

```text
Generic Error
@template: {% macro show %} without {% endmacro %}
```

A {% macro %} is never closed with {% endmacro %}.

This module fails with H7049:

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

Beside it, `page.jinja`:

```jinja file page.jinja
{% macro show(x) %}{{ x }}
```

The correct form:

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

Beside it, `page.jinja`:

```jinja file page.jinja
{% macro show(x) %}{{ x }}{% endmacro %}<p>{{ show(title) }}</p>
```

### H7050

Message:

```text
Generic Error
@template: `as' in {% from ... import %} is not supported
```

A {% from ... import %} gives an imported macro another name with as.

This module fails with H7050:

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

Beside it, `page.jinja`:

```jinja file page.jinja
{% from "macros.jinja" import show as display %}<p>{{ display(title) }}</p>
```

Beside it, `macros.jinja`:

```jinja file macros.jinja
{% macro show(x) %}{{ x }}{% endmacro %}
```

The correct form:

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

Beside it, `page.jinja`:

```jinja file page.jinja
{% from "macros.jinja" import show %}<p>{{ show(title) }}</p>
```

Beside it, `macros.jinja`:

```jinja file macros.jinja
{% macro show(x) %}{{ x }}{% endmacro %}
```

### H7051

Message:

```text
Generic Error
@template: {% from "file" import a, b %} names the macros to import, and nothing else
```

A {% from ... import %} names something other than macros.

This module fails with H7051:

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

Beside it, `page.jinja`:

```jinja file page.jinja
{% from "macros.jinja" import 1 %}<p>{{ title }}</p>
```

Beside it, `macros.jinja`:

```jinja file macros.jinja
{% macro show(x) %}{{ x }}{% endmacro %}
```

The correct form:

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

Beside it, `page.jinja`:

```jinja file page.jinja
{% from "macros.jinja" import show %}<p>{{ show(title) }}</p>
```

Beside it, `macros.jinja`:

```jinja file macros.jinja
{% macro show(x) %}{{ x }}{% endmacro %}
```

### H7052

Message:

```text
Generic Error
@template: {% from %} takes a string literal and `import'
```

A {% from %} lacks the file name as a string, or the word import.

This module fails with H7052:

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

Beside it, `page.jinja`:

```jinja file page.jinja
{% from macros import show %}<p>{{ show(title) }}</p>
```

Beside it, `macros.jinja`:

```jinja file macros.jinja
{% macro show(x) %}{{ x }}{% endmacro %}
```

The correct form:

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

Beside it, `page.jinja`:

```jinja file page.jinja
{% from "macros.jinja" import show %}<p>{{ show(title) }}</p>
```

Beside it, `macros.jinja`:

```jinja file macros.jinja
{% macro show(x) %}{{ x }}{% endmacro %}
```

### H7054

Message:

```text
Generic Error
@template: the macro show is defined twice
```

A macro is defined twice with two bodies.

This module fails with H7054:

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

Beside it, `page.jinja`:

```jinja file page.jinja
{% macro show(x) %}{{ x }}{% endmacro %}{% macro show(x) %}<b>{{ x }}</b>{% endmacro %}<p>{{ show(title) }}</p>
```

The correct form:

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

Beside it, `page.jinja`:

```jinja file page.jinja
{% macro show(x) %}{{ x }}{% endmacro %}{% macro bold(x) %}<b>{{ x }}</b>{% endmacro %}<p>{{ show(title) }}</p>
```

### H7055

Message:

```text
Generic Error
@template: "macros.jinja" imports from itself
```

A template imports macros from itself.

This module fails with H7055:

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

Beside it, `page.jinja`:

```jinja file page.jinja
{% from "macros.jinja" import show %}<p>{{ show(title) }}</p>
```

Beside it, `macros.jinja`:

```jinja file macros.jinja
{% from "macros.jinja" import show %}{% macro show(x) %}{{ x }}{% endmacro %}
```

The correct form:

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

Beside it, `page.jinja`:

```jinja file page.jinja
{% from "macros.jinja" import show %}<p>{{ show(title) }}</p>
```

Beside it, `macros.jinja`:

```jinja file macros.jinja
{% macro show(x) %}{{ x }}{% endmacro %}
```

### H7056

Message:

```text
Generic Error
@template: "macros.jinja" has no macro display
```

A {% from ... import %} names a macro the file does not define.

This module fails with H7056:

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

Beside it, `page.jinja`:

```jinja file page.jinja
{% from "macros.jinja" import display %}<p>{{ title }}</p>
```

Beside it, `macros.jinja`:

```jinja file macros.jinja
{% macro show(x) %}{{ x }}{% endmacro %}
```

The correct form:

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

Beside it, `page.jinja`:

```jinja file page.jinja
{% from "macros.jinja" import show %}<p>{{ show(title) }}</p>
```

Beside it, `macros.jinja`:

```jinja file macros.jinja
{% macro show(x) %}{{ x }}{% endmacro %}
```

### H7057

Message:

```text
Generic Error
@template: "page.jinja" includes or extends itself: page.jinja -> part.jinja -> page.jinja
```

A template includes or extends itself, directly or through others.

This module fails with H7057:

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

Beside it, `page.jinja`:

```jinja file page.jinja
{% include "part.jinja" %}
```

Beside it, `part.jinja`:

```jinja file part.jinja
<p>{{ title }}</p>{% include "page.jinja" %}
```

The correct form:

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

Beside it, `page.jinja`:

```jinja file page.jinja
{% include "part.jinja" %}
```

Beside it, `part.jinja`:

```jinja file part.jinja
<p>{{ title }}</p>
```

### H7058

Message:

```text
Generic Error
@template: a template extends one other template, once
```

A template extends a second time.

This module fails with H7058:

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

Beside it, `page.jinja`:

```jinja file page.jinja
{% extends "base.jinja" %}{% extends "base.jinja" %}{% block main %}{{ title }}{% endblock %}
```

Beside it, `base.jinja`:

```jinja file base.jinja
<html>{% block main %}{% endblock %}</html>
```

The correct form:

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

Beside it, `page.jinja`:

```jinja file page.jinja
{% extends "base.jinja" %}{% block main %}{{ title }}{% endblock %}
```

Beside it, `base.jinja`:

```jinja file base.jinja
<html>{% block main %}{% endblock %}</html>
```

### H7059

Message:

```text
Generic Error
@template: text after {% extends %} and outside a block is dropped by Jinja2; here it is refused
```

Text stands after {% extends %} outside a block. Jinja2 would drop it; here
it is refused.

This module fails with H7059:

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

Beside it, `page.jinja`:

```jinja file page.jinja
{% extends "base.jinja" %}lost text{% block main %}{{ title }}{% endblock %}
```

Beside it, `base.jinja`:

```jinja file base.jinja
<html>{% block main %}{% endblock %}</html>
```

The correct form:

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

Beside it, `page.jinja`:

```jinja file page.jinja
{% extends "base.jinja" %}{% block main %}{{ title }}{% endblock %}
```

Beside it, `base.jinja`:

```jinja file base.jinja
<html>{% block main %}{% endblock %}</html>
```

### H7060

Message:

```text
Generic Error
@template: a value after {% extends %} and outside a block is dropped by Jinja2; here it is refused
```

A value stands after {% extends %} outside a block.

This module fails with H7060:

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

Beside it, `page.jinja`:

```jinja file page.jinja
{% extends "base.jinja" %}{{ title }}{% block main %}{{ title }}{% endblock %}
```

Beside it, `base.jinja`:

```jinja file base.jinja
<html>{% block main %}{% endblock %}</html>
```

The correct form:

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

Beside it, `page.jinja`:

```jinja file page.jinja
{% extends "base.jinja" %}{% block main %}{{ title }}{% endblock %}
```

Beside it, `base.jinja`:

```jinja file base.jinja
<html>{% block main %}{% endblock %}</html>
```

### H7061

Message:

```text
Generic Error
@template: an if or a for after {% extends %} and outside a block is dropped by Jinja2; here it is refused
```

An {% if %} or a {% for %} stands after {% extends %} outside a block.

This module fails with H7061:

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

Beside it, `page.jinja`:

```jinja file page.jinja
{% extends "base.jinja" %}{% if admin %}{% endif %}{% block main %}{{ title }}{% endblock %}
```

Beside it, `base.jinja`:

```jinja file base.jinja
<html>{% block main %}{% endblock %}</html>
```

The correct form:

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

Beside it, `page.jinja`:

```jinja file page.jinja
{% extends "base.jinja" %}{% block main %}{% if admin %}{{ title }}{% endif %}{% endblock %}
```

Beside it, `base.jinja`:

```jinja file base.jinja
<html>{% block main %}{% endblock %}</html>
```

### H7062

Message:

```text
Generic Error
@template: an include after {% extends %} and outside a block is dropped by Jinja2; here it is refused
```

An {% include %} stands after {% extends %} outside a block.

This module fails with H7062:

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

Beside it, `page.jinja`:

```jinja file page.jinja
{% extends "base.jinja" %}{% include "part.jinja" %}{% block main %}{{ title }}{% endblock %}
```

Beside it, `base.jinja`:

```jinja file base.jinja
<html>{% block main %}{% endblock %}</html>
```

Beside it, `part.jinja`:

```jinja file part.jinja
<p>{{ title }}</p>
```

The correct form:

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

Beside it, `page.jinja`:

```jinja file page.jinja
{% extends "base.jinja" %}{% block main %}{% include "part.jinja" %}{% endblock %}
```

Beside it, `base.jinja`:

```jinja file base.jinja
<html>{% block main %}{% endblock %}</html>
```

Beside it, `part.jinja`:

```jinja file part.jinja
<p>{{ title }}</p>
```

### H7063

Message:

```text
Generic Error
@template: super() in a block that no template above this one has
```

super() stands in a block that no template above this one has.

This module fails with H7063:

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

Beside it, `page.jinja`:

```jinja file page.jinja
{% block main %}{{ super() }}<p>{{ title }}</p>{% endblock %}
```

The correct form:

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

Beside it, `page.jinja`:

```jinja file page.jinja
{% block main %}<p>{{ title }}</p>{% endblock %}
```

### H7064

Message:

```text
Generic Error
@template: super() takes no arguments
```

super() is given arguments.

This module fails with H7064:

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

Beside it, `page.jinja`:

```jinja file page.jinja
{% extends "base.jinja" %}{% block main %}{{ super(1) }}{{ title }}{% endblock %}
```

Beside it, `base.jinja`:

```jinja file base.jinja
<html>{% block main %}{% endblock %}</html>
```

The correct form:

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

Beside it, `page.jinja`:

```jinja file page.jinja
{% extends "base.jinja" %}{% block main %}{{ super() }}{{ title }}{% endblock %}
```

Beside it, `base.jinja`:

```jinja file base.jinja
<html>{% block main %}{% endblock %}</html>
```

### H7065

Message:

```text
Generic Error
@template: {% extends %} stands at the top level of a template, once
```

An {% extends %} stands inside another tag, such as an {% if %}. It stands
at the top level, once.

This module fails with H7065:

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

Beside it, `page.jinja`:

```jinja file page.jinja
{% if admin %}{% extends "base.jinja" %}{% endif %}<p>{{ title }}</p>
```

Beside it, `base.jinja`:

```jinja file base.jinja
<html>{% block main %}{% endblock %}</html>
```

The correct form:

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

Beside it, `page.jinja`:

```jinja file page.jinja
{% extends "base.jinja" %}{% block main %}{{ title }}{% endblock %}
```

Beside it, `base.jinja`:

```jinja file base.jinja
<html>{% block main %}{% endblock %}</html>
```

### H7066

Message:

```text
Generic Error
@template: the block side is defined here, and no template this one extends has a block of that name; Jinja2 drops it without a word, and here it is refused
```

A template defines a block that no template it extends has. Jinja2 would
drop it; here it is refused.

This module fails with H7066:

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

Beside it, `page.jinja`:

```jinja file page.jinja
{% extends "base.jinja" %}{% block side %}{{ title }}{% endblock %}
```

Beside it, `base.jinja`:

```jinja file base.jinja
<html>{% block main %}{% endblock %}</html>
```

The correct form:

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

Beside it, `page.jinja`:

```jinja file page.jinja
{% extends "base.jinja" %}{% block main %}{{ title }}{% endblock %}
```

Beside it, `base.jinja`:

```jinja file base.jinja
<html>{% block main %}{% endblock %}</html>
```

### H7067

Message:

```text
Generic Error
@template: a value cannot stand in a tag, between its attributes: there is no escaping that makes that safe
```

A value stands in a place of the HTML where no escaping makes it safe, such
as inside a tag's name or attribute list.

This module fails with H7067:

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

Beside it, `page.jinja`:

```jinja file page.jinja
<div {{ title }}>x</div>
```

The correct form:

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

Beside it, `page.jinja`:

```jinja file page.jinja
<div title="{{ title }}">x</div>
```

### H7069

Message:

```text
Generic Error
@template: `loop' can only be asked for loop.index, loop.index0, loop.revindex, loop.revindex0, loop.length, loop.first, loop.last and loop.cycle(...), inside a {% for %}
```

loop is used for something other than loop.index, loop.index0, loop.length,
loop.first or loop.last.

This module fails with H7069:

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

Beside it, `page.jinja`:

```jinja file page.jinja
{% for item in items %}{{ loop }}{% endfor %}
```

The correct form:

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

Beside it, `page.jinja`:

```jinja file page.jinja
{% for item in items %}{{ loop.index }}{% endfor %}
```

### H7070

Message:

```text
Generic Error
@template: title: a macro brought in with {% from ... import %} or {% import %} does not see the template's data, as in Jinja2 -- pass it as an argument
```

A macro brought in with {% from ... import %} uses the template's data. Such
a macro sees only its arguments.

This module fails with H7070:

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

Beside it, `page.jinja`:

```jinja file page.jinja
{% from "macros.jinja" import show %}<p>{{ show() }}</p>
```

Beside it, `macros.jinja`:

```jinja file macros.jinja
{% macro show() %}{{ title }}{% endmacro %}
```

The correct form:

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

Beside it, `page.jinja`:

```jinja file page.jinja
{% from "macros.jinja" import show %}<p>{{ show(title) }}</p>
```

Beside it, `macros.jinja`:

```jinja file macros.jinja
{% macro show(x) %}{{ x }}{% endmacro %}
```

### H7071

Message:

```text
Generic Error
@template: `loop' only exists inside a {% for %}
```

loop is used outside a {% for %}.

This module fails with H7071:

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

Beside it, `page.jinja`:

```jinja file page.jinja
<p>{{ loop.index }}</p>
```

The correct form:

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

Beside it, `page.jinja`:

```jinja file page.jinja
{% for item in items %}{{ loop.index }}{% endfor %}
```

### H7072

Message:

```text
Generic Error
@template: this number is too large
```

A number compared in a condition is too large.

This module fails with H7072:

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

Beside it, `page.jinja`:

```jinja file page.jinja
{% if count > 99999999999999999999 %}many{% endif %}
```

The correct form:

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

Beside it, `page.jinja`:

```jinja file page.jinja
{% if count > 99 %}many{% endif %}
```

### H7073

Message:

```text
Generic Error
@template: loop.cycle cannot be printed
```

A loop attribute is printed that cannot be printed.

This module fails with H7073:

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

Beside it, `page.jinja`:

```jinja file page.jinja
{% for item in items %}{{ loop.cycle }}{% endfor %}
```

The correct form:

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

Beside it, `page.jinja`:

```jinja file page.jinja
{% for item in items %}{{ loop.index }}{% endfor %}
```

### H7075

Message:

```text
Generic Error
@template: |length is supported on a name of the data only
```

`|length` is applied to something that is not a name of the data.

This module fails with H7075:

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

Beside it, `page.jinja`:

```jinja file page.jinja
<p>{{ "abc"|length }}</p>
```

The correct form:

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

Beside it, `page.jinja`:

```jinja file page.jinja
<p>{{ title|length }}</p>
```

### H7076

Message:

```text
Generic Error
@template: the filter |wordcount is not supported
```

A filter is used that this template language does not support.

This module fails with H7076:

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

Beside it, `page.jinja`:

```jinja file page.jinja
<p>{{ title|wordcount }}</p>
```

The correct form:

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

Beside it, `page.jinja`:

```jinja file page.jinja
<p>{{ title|upper }}</p>
```

### H7077

Message:

```text
Generic Error
@template: none cannot be printed: an Option is printed by asking `is not none' first
```

none is printed. An Option is printed after asking is not none.

This module fails with H7077:

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

Beside it, `page.jinja`:

```jinja file page.jinja
<p>{{ none }}</p>
```

The correct form:

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

Beside it, `page.jinja`:

```jinja file page.jinja
{% if motto is not none %}<p>{{ motto }}</p>{% endif %}
```

### H7079

Message:

```text
Generic Error
@template: a macro call stands alone in {{ }}, without filters
```

A macro call stands with a filter in {{ }}. A macro call stands alone.

This module fails with H7079:

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

Beside it, `page.jinja`:

```jinja file page.jinja
{% macro show(x) %}{{ x }}{% endmacro %}<p>{{ show(title)|upper }}</p>
```

The correct form:

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

Beside it, `page.jinja`:

```jinja file page.jinja
{% macro show(x) %}{{ x|upper }}{% endmacro %}<p>{{ show(title) }}</p>
```

### H7080

Message:

```text
Generic Error
@template: loop.first is not a number
```

A loop attribute that is not a number stands where a number goes, in a comparison or in arithmetic. loop.first and loop.last are conditions.

This module fails with H7080:

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

Beside it, `page.jinja`:

```jinja file page.jinja
{% for item in items %}{% if loop.first > 0 %}{{ item }}{% endif %}{% endfor %}
```

The correct form:

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

Beside it, `page.jinja`:

```jinja file page.jinja
{% for item in items %}{% if loop.index > 1 %}{{ item }}{% endif %}{% endfor %}
```

### H7082

Message:

```text
Generic Error
@template: `is defined' cannot be asked: the template is compiled against one data type, so every name is known when the programme is compiled, and a name that does not exist is a compile error already
```

A condition asks is defined. The template is compiled against one data type,
so every name is known when the program is compiled.

This module fails with H7082:

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

Beside it, `page.jinja`:

```jinja file page.jinja
{% if title is defined %}<p>{{ title }}</p>{% endif %}
```

The correct form:

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

Beside it, `page.jinja`:

```jinja file page.jinja
<p>{{ title }}</p>
```

### H7083

Message:

```text
Generic Error
@template: `is none' is supported on a name of the data only
```

is none is asked of something that is not a name of the data.

This module fails with H7083:

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

Beside it, `page.jinja`:

```jinja file page.jinja
{% if "x" is none %}<p>none</p>{% endif %}
```

The correct form:

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

Beside it, `page.jinja`:

```jinja file page.jinja
{% if motto is none %}<p>none</p>{% endif %}
```

### H7084

Message:

```text
Generic Error
@template: the test `is even' is not supported
```

A condition uses a test this template language does not support.

This module fails with H7084:

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

Beside it, `page.jinja`:

```jinja file page.jinja
{% if count is even %}<p>even</p>{% endif %}
```

The correct form:

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

Beside it, `page.jinja`:

```jinja file page.jinja
{% if count == 2 %}<p>two</p>{% endif %}
```

### H7085

Message:

```text
Generic Error
@template: a string can only be compared with == and !=
```

A string is compared with an operator other than == and !=.

This module fails with H7085:

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

Beside it, `page.jinja`:

```jinja file page.jinja
{% if title < "m" %}<p>early</p>{% endif %}
```

The correct form:

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

Beside it, `page.jinja`:

```jinja file page.jinja
{% if title == "m" %}<p>m</p>{% endif %}
```

### H7086

Message:

```text
Generic Error
@template: only a name compared with a literal, or with a computed number, is supported
```

A comparison does not compare a name with a literal.

This module fails with H7086:

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

Beside it, `page.jinja`:

```jinja file page.jinja
{% if count > count %}<p>more</p>{% endif %}
```

The correct form:

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

Beside it, `page.jinja`:

```jinja file page.jinja
{% if count > 1 %}<p>more</p>{% endif %}
```

### H7087

Message:

```text
Generic Error
@template: this cannot be used as a condition
```

Something that is not a condition stands as one, such as a string.

This module fails with H7087:

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

Beside it, `page.jinja`:

```jinja file page.jinja
{% if "yes" %}<p>yes</p>{% endif %}
```

The correct form:

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

Beside it, `page.jinja`:

```jinja file page.jinja
{% if admin %}<p>yes</p>{% endif %}
```

### H7088

Message:

```text
Generic Error
@template: the parameter x is a literal here, and a literal has no fields
```

A macro parameter that is given a literal is used with a field, as in
x.name.

This module fails with H7088:

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

Beside it, `page.jinja`:

```jinja file page.jinja
{% macro show(x) %}{{ x.name }}{% endmacro %}<p>{{ show("a") }}</p>
```

The correct form:

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

Beside it, `page.jinja`:

```jinja file page.jinja
{% macro show(x) %}{{ x }}{% endmacro %}<p>{{ show("a") }}</p>
```

### H7089

Message:

```text
Generic Error
@template: there is no macro show
```

A macro is called that is not defined.

This module fails with H7089:

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

Beside it, `page.jinja`:

```jinja file page.jinja
<p>{{ show(title) }}</p>
```

The correct form:

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

Beside it, `page.jinja`:

```jinja file page.jinja
{% macro show(x) %}{{ x }}{% endmacro %}<p>{{ show(title) }}</p>
```

### H7090

Message:

```text
Generic Error
@template: the macro show calls itself: show -> show; a template is expanded when the programme is compiled, and a recursion would not end
```

A macro calls itself. A template is expanded when the program is compiled,
and a recursion would not end.

This module fails with H7090:

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

Beside it, `page.jinja`:

```jinja file page.jinja
{% macro show(x) %}{{ show(x) }}{% endmacro %}<p>{{ show(title) }}</p>
```

The correct form:

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

Beside it, `page.jinja`:

```jinja file page.jinja
{% macro show(x) %}{{ x }}{% endmacro %}<p>{{ show(title) }}</p>
```

### H7091

Message:

```text
Generic Error
@template: the macro show takes 1 arguments
```

A macro is called with more arguments than it has parameters.

This module fails with H7091:

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

Beside it, `page.jinja`:

```jinja file page.jinja
{% macro show(x) %}{{ x }}{% endmacro %}<p>{{ show(title, title) }}</p>
```

The correct form:

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

Beside it, `page.jinja`:

```jinja file page.jinja
{% macro show(x) %}{{ x }}{% endmacro %}<p>{{ show(title) }}</p>
```

### H7092

Message:

```text
Generic Error
@template: the macro show needs a value for x
```

A macro is called without a value for a parameter that has no default.

This module fails with H7092:

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

Beside it, `page.jinja`:

```jinja file page.jinja
{% macro show(x) %}{{ x }}{% endmacro %}<p>{{ show() }}</p>
```

The correct form:

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

Beside it, `page.jinja`:

```jinja file page.jinja
{% macro show(x) %}{{ x }}{% endmacro %}<p>{{ show(title) }}</p>
```

### H7093

Message:

```text
Generic Error
@template: a macro argument is a name or a literal
```

A macro argument is neither a name nor a literal.

This module fails with H7093:

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

Beside it, `page.jinja`:

```jinja file page.jinja
{% macro show(x) %}{{ x }}{% endmacro %}<p>{{ show(title|upper) }}</p>
```

The correct form:

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

Beside it, `page.jinja`:

```jinja file page.jinja
{% macro show(x) %}{{ x|upper }}{% endmacro %}<p>{{ show(title) }}</p>
```

### H7095

Message:

```text
Generic Error
@template: the branches of this {% if %} end in different places in the HTML: a <script> element and HTML text
```

The branches of an {% if %} end in different places of the HTML, for example
one inside a script and one outside.

This module fails with H7095:

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

Beside it, `page.jinja`:

```jinja file page.jinja
{% if admin %}<script>{% endif %}<p>{{ title }}</p>
```

The correct form:

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

Beside it, `page.jinja`:

```jinja file page.jinja
{% if admin %}<b>admin</b>{% endif %}<p>{{ title }}</p>
```

### H7096

Message:

```text
Generic Error
@template: {% for %} walks over a name of the data only
```

A {% for %} walks over something that is not a name of the data.

This module fails with H7096:

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

Beside it, `page.jinja`:

```jinja file page.jinja
{% for c in "abc" %}{{ c }}{% endfor %}
```

The correct form:

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

Beside it, `page.jinja`:

```jinja file page.jinja
{% for item in items %}{{ item }}{% endfor %}
```

### H7097

Message:

```text
Generic Error
@template: the body of this {% for %} ends in a different place in the HTML than it begins: HTML text and a <script> element
```

The body of a {% for %} ends in a different place of the HTML than it
begins.

This module fails with H7097:

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

Beside it, `page.jinja`:

```jinja file page.jinja
{% for item in items %}<script>{% endfor %}
```

The correct form:

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

Beside it, `page.jinja`:

```jinja file page.jinja
{% for item in items %}<b>{{ item }}</b>{% endfor %}
```

### H7098

Message:

```text
Generic Error
@template: the {% else %} of this {% for %} ends in a different place in the HTML than it begins
```

The {% else %} of a {% for %} ends in a different place of the HTML than it
begins.

This module fails with H7098:

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

Beside it, `page.jinja`:

```jinja file page.jinja
{% for item in items %}{{ item }}{% else %}<script>{% endfor %}
```

The correct form:

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

Beside it, `page.jinja`:

```jinja file page.jinja
{% for item in items %}{{ item }}{% else %}<b>none</b>{% endfor %}
```

### H7099

Message:

```text
Generic Error
@template: a module that uses @template imports Standard.Template -- e.g. `import Standard.Template (Render);' -- because the generated code calls it, and its instances come with the import
```

A module that uses @template does not import Standard.Template. The
generated code calls it, and its instances come with the import.

This module fails with H7099:

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

Beside it, `page.jinja`:

```jinja file page.jinja
<p>{{ title }}</p>
```

The correct form:

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

Beside it, `page.jinja`:

```jinja file page.jinja
<p>{{ title }}</p>
```

### H7100

Message:

```text
Generic Error
@template: {% with %} without {% endwith %}
```

A {% set %} block, a {% with %}, a {% filter %} or a {% call %} is not closed by its end tag.

This module fails with H7100:

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

Beside it, `page.jinja`:

```jinja file page.jinja
{% with name = title %}<p>{{ name }}</p>
```

The correct form:

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

Beside it, `page.jinja`:

```jinja file page.jinja
{% with name = title %}<p>{{ name }}</p>{% endwith %}
```

### H7101

Message:

```text
Generic Error
@template: {% set %} takes one name, = and one value
```

The tag of a {% set %}, a {% with %}, a {% filter %} or a {% call %} is not in its form: set takes one name, = and a value; with takes names with = and values, separated by commas; filter takes filters separated by |; call takes one macro call, and caller() takes no parameters.

This module fails with H7101:

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

Beside it, `page.jinja`:

```jinja file page.jinja
{% set a b = title %}<p>{{ a }}</p>
```

The correct form:

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

Beside it, `page.jinja`:

```jinja file page.jinja
{% set a = title %}<p>{{ a }}</p>
```

### H7102

Message:

```text
Generic Error
@template: the name lib is an import's: it stands for the macros of a file, and a macro is called, not printed
```

The name an {% import ... as %} gave is printed, or given to two imports. It stands for the macros of a file, and hides a field of the data with the same name, as in Jinja2.

This module fails with H7102:

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

Beside it, `page.jinja`:

```jinja file page.jinja
{% import "macros.jinja" as lib %}<p>{{ lib }}</p>
```

Beside it, `macros.jinja`:

```jinja file macros.jinja
{% macro show(text) %}<b>{{ text }}</b>{% endmacro %}
```

The correct form:

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

Beside it, `page.jinja`:

```jinja file page.jinja
{% import "macros.jinja" as lib %}<p>{{ lib.show(title) }}</p>
```

Beside it, `macros.jinja`:

```jinja file macros.jinja
{% macro show(text) %}<b>{{ text }}</b>{% endmacro %}
```

### H7103

Message:

```text
Generic Error
@template: a {% set %} after {% extends %} and outside a block is refused: whether a block sees it depends on the order in which Jinja2 runs the two templates
```

A {% set %} stands after {% extends %} and outside every block. Whether a block of the parent sees the name depends on the order in which Jinja2 runs the two templates; set it inside the block.

This module fails with H7103:

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

Beside it, `page.jinja`:

```jinja file page.jinja
{% extends "base.jinja" %}{% set name = title %}{% block main %}{{ name }}{% endblock %}
```

Beside it, `base.jinja`:

```jinja file base.jinja
<main>{% block main %}{% endblock %}</main>
```

The correct form:

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

Beside it, `page.jinja`:

```jinja file page.jinja
{% extends "base.jinja" %}{% block main %}{% set name = title %}{{ name }}{% endblock %}
```

Beside it, `base.jinja`:

```jinja file base.jinja
<main>{% block main %}{% endblock %}</main>
```

### H7104

Message:

```text
Generic Error
@template: name is a value that a {% set %} or a {% with %} computed, and a computed value has no fields
```

A field is asked of a name that a {% set %} or a {% with %} bound to a computed value, such as a text joined with ~. Only a name of the data has fields.

This module fails with H7104:

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

Beside it, `page.jinja`:

```jinja file page.jinja
{% set name = title ~ "!" %}<p>{{ name.length }}</p>
```

The correct form:

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

Beside it, `page.jinja`:

```jinja file page.jinja
{% set name = title ~ "!" %}<p>{{ name }}</p>
```

### H7105

Message:

```text
Generic Error
@template: // divides by a number written in the template only: a divisor from the data could be zero, and a division by zero stops the programme
```

// or % divides by a name of the data, or by zero. A divisor from the data could be zero, and a division by zero stops the programme; the divisor is a number written in the template.

This module fails with H7105:

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

Beside it, `page.jinja`:

```jinja file page.jinja
<p>{{ count // count }}</p>
```

The correct form:

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

Beside it, `page.jinja`:

```jinja file page.jinja
<p>{{ count // 2 }}</p>
```

### H7106

Message:

```text
Generic Error
@template: this is not a number: + - * // % take numbers, names of the data and the numbers of loop
```

An operand of + - * // % is something other than a number: a text, a filter or a condition.

This module fails with H7106:

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

Beside it, `page.jinja`:

```jinja file page.jinja
<p>{{ count + "1" }}</p>
```

The correct form:

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

Beside it, `page.jinja`:

```jinja file page.jinja
<p>{{ count + 1 }}</p>
```

### H7107

Message:

```text
Generic Error
@template: ~ joins texts that are escaped when printed; a |safe value or a {% set %} block's text cannot be joined to them -- print it on its own
```

The operator ~ joins a value marked |safe, or the text of a {% set %} block, to a text that is escaped when printed. What comes out would be half escaped; print the |safe value on its own.

This module fails with H7107:

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

Beside it, `page.jinja`:

```jinja file page.jinja
<p>{{ title|safe ~ "!" }}</p>
```

The correct form:

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

Beside it, `page.jinja`:

```jinja file page.jinja
<p>{{ title|safe }}!</p>
```

### H7108

Message:

```text
Generic Error
@template: |truncate takes a length at least as long as its ending, and a leeway of at least 0
```

The arguments of |replace, |truncate, |center, |join or loop.cycle are not literals of the kind the filter takes, or not in their range: the length of |truncate is at least the length of its ending.

This module fails with H7108:

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

Beside it, `page.jinja`:

```jinja file page.jinja
<p>{{ title|truncate(2) }}</p>
```

The correct form:

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

Beside it, `page.jinja`:

```jinja file page.jinja
<p>{{ title|truncate(20) }}</p>
```

### H7109

Message:

```text
Generic Error
@template: the filter |join cannot stand in {% filter %}: it applies to a value, not to written text
```

A {% filter %} block names a filter that applies to a value, such as |join or |length, not to the text the block writes.

This module fails with H7109:

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

Beside it, `page.jinja`:

```jinja file page.jinja
{% filter join %}<p>{{ title }}</p>{% endfilter %}
```

The correct form:

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

Beside it, `page.jinja`:

```jinja file page.jinja
{% filter upper %}<p>{{ title }}</p>{% endfilter %}
```

### H7110

Message:

```text
Generic Error
@template: {% set name %} inside an {% if %} is refused: in Jinja2 the name is still there after the {% endif %} when the branch ran, and missing when it did not, which a compiled template cannot follow; set it before the {% if %}, or use {% with %}
```

A {% set %} stands inside an {% if %}. In Jinja2 the name is still there after the {% endif %} when the branch ran, and missing when it did not; a compiled template cannot follow that. Set the name before the {% if %}, or use {% with %}.

This module fails with H7110:

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

Beside it, `page.jinja`:

```jinja file page.jinja
{% if admin %}{% set name = title %}{% endif %}<p>{{ title }}</p>
```

The correct form:

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

Beside it, `page.jinja`:

```jinja file page.jinja
{% if admin %}{% with name = title %}<p>{{ name }}</p>{% endwith %}{% endif %}
```

### H7111

Message:

```text
Generic Error
@template: a {% set %} or {% filter %} block stands in HTML text and ends there; this one stands in the value of the attribute title
```

A {% filter %} block stands somewhere other than in HTML text, or the text a {% set %} or {% filter %} block writes ends somewhere other than where it began. What such a block writes is escaped as HTML text.

This module fails with H7111:

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

Beside it, `page.jinja`:

```jinja file page.jinja
<a title="{% filter upper %}{{ title }}{% endfilter %}">x</a>
```

The correct form:

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

Beside it, `page.jinja`:

```jinja file page.jinja
<a title="{{ title|upper }}">x</a>
```

### H7112

Message:

```text
Generic Error
@template: caller() stands in a macro that a {% call %} block calls
```

caller() stands in a macro that is called without a {% call %} block, or it is given arguments. Jinja2 fails when it renders such a call.

This module fails with H7112:

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

Beside it, `page.jinja`:

```jinja file page.jinja
{% macro box() %}<div>{{ caller() }}</div>{% endmacro %}<p>{{ box() }}</p>
```

The correct form:

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

Beside it, `page.jinja`:

```jinja file page.jinja
{% macro box() %}<div>{{ caller() }}</div>{% endmacro %}{% call box() %}{{ title }}{% endcall %}
```

### H7113

Message:

```text
Generic Error
@template: the text of a {% set %} block is HTML, escaped already, and is printed in HTML text only, not in the value of the attribute title
```

The text a {% set %} block wrote is printed somewhere other than in HTML text, such as in an attribute. It is HTML, escaped already, and is printed as it stands.

This module fails with H7113:

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

Beside it, `page.jinja`:

```jinja file page.jinja
{% set cell %}<b>{{ title }}</b>{% endset %}<a title="{{ cell }}">x</a>
```

The correct form:

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

Beside it, `page.jinja`:

```jinja file page.jinja
{% set cell %}<b>{{ title }}</b>{% endset %}<p>{{ cell }}</p>
```

### H7114

Message:

```text
Generic Error
@template: "strict": @template knows the options trim_blocks and lstrip_blocks
```

The fourth argument of @template names an option other than trim_blocks and lstrip_blocks.

This module fails with H7114:

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

Beside it, `page.jinja`:

```jinja file page.jinja
<p>{{ title }}</p>
```

The correct form:

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

Beside it, `page.jinja`:

```jinja file page.jinja
<p>{{ title }}</p>
```

### H7115

Message:

```text
Generic Error
@template: _( ) takes the key first, as a string literal, as in _("Greeting")
```

The first argument of _( ) is the key, written as a string literal: the name of a case of the catalog's keys. A name of the data or an expression in its place would be a key chosen when the page is rendered, which the compiler cannot check.

This module fails with H7115:

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

Beside it, `page.jinja`:

```jinja file page.jinja
{% catalog messages %}<p>{{ _(user) }}</p>
```

The correct form:

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

Beside it, `page.jinja`:

```jinja file page.jinja
{% catalog messages %}<p>{{ _("Greeting", name=user) }}</p>
```

### H7116

Message:

```text
Generic Error
@template: _( ) is given name twice
```

Each argument of _( ) has a name of its own; the same name twice would leave open which value the placeholder takes.

This module fails with H7116:

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

Beside it, `page.jinja`:

```jinja file page.jinja
{% catalog messages %}<p>{{ _("Greeting", name=user, name=user) }}</p>
```

The correct form:

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

Beside it, `page.jinja`:

```jinja file page.jinja
{% catalog messages %}<p>{{ _("Greeting", name=user) }}</p>
```

### H7117

Message:

```text
Generic Error
@template: {% catalog %} takes the name of a function of no arguments that gives the catalog, as in {% catalog messages %}
```

{% catalog %} takes the name of a function of no arguments that gives the catalog, without quotes; the module that holds the @template has the function or imports it.

This module fails with H7117:

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

Beside it, `page.jinja`:

```jinja file page.jinja
{% catalog "messages" %}<p>{{ _("Greeting", name=user) }}</p>
```

The correct form:

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

Beside it, `page.jinja`:

```jinja file page.jinja
{% catalog messages %}<p>{{ _("Greeting", name=user) }}</p>
```

### H7118

Message:

```text
Generic Error
@template: the text of a {% trans %} block is its key, one name such as Greeting; the texts of the languages stand in the catalog
```

The text between {% trans %} and {% pluralize %} or {% endtrans %} is the key, one name such as Greeting. The texts of the languages stand in the catalog, not in the template.

This module fails with H7118:

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

Beside it, `page.jinja`:

```jinja file page.jinja
{% catalog messages %}<p>{% trans name=user %}Hello, {{ name }}!{% endtrans %}</p>
```

The correct form:

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

Beside it, `page.jinja`:

```jinja file page.jinja
{% catalog messages %}<p>{% trans name=user %}Greeting{% endtrans %}</p>
```

### H7119

Message:

```text
Generic Error
@template: {% pluralize %} needs count=... in its {% trans %}: the count chooses the form
```

The count chooses the plural form, so a {% trans %} block with {% pluralize %} names it: count=... in its tag.

This module fails with H7119:

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

Beside it, `page.jinja`:

```jinja file page.jinja
{% catalog messages %}<p>{% trans %}Items{% pluralize %}{% endtrans %}</p>
```

The correct form:

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

Beside it, `page.jinja`:

```jinja file page.jinja
{% catalog messages %}<p>{% trans count=count %}Items{% pluralize %}{% endtrans %}</p>
```

### H7120

Message:

```text
Generic Error
@template: between {% pluralize %} and {% endtrans %} nothing may stand: the plural forms are in the catalog
```

In Jinja2 the text after {% pluralize %} is the plural form. Here the forms of every language stand in the catalog, so nothing may stand there.

This module fails with H7120:

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

Beside it, `page.jinja`:

```jinja file page.jinja
{% catalog messages %}<p>{% trans count=count %}Items{% pluralize %}{{ count }} items{% endtrans %}</p>
```

The correct form:

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

Beside it, `page.jinja`:

```jinja file page.jinja
{% catalog messages %}<p>{% trans count=count %}Items{% pluralize %}{% endtrans %}</p>
```

### H7121

Message:

```text
Generic Error
@template: a template names its catalog once, with one {% catalog %}
```

A template takes its translations from one catalog, named once with {% catalog %}.

This module fails with H7121:

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

Beside it, `page.jinja`:

```jinja file page.jinja
{% catalog messages %}{% catalog messages %}<p>{{ _("Greeting", name=user) }}</p>
```

The correct form:

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

Beside it, `page.jinja`:

```jinja file page.jinja
{% catalog messages %}<p>{{ _("Greeting", name=user) }}</p>
```

### H7122

Message:

```text
Generic Error
@template: a translation needs the template's catalog: {% catalog name %} before it
```

A translation needs the catalog it comes from: {% catalog name %} stands before the first _( ) or {% trans %} of the template.

This module fails with H7122:

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

Beside it, `page.jinja`:

```jinja file page.jinja
<p>{{ _("Greeting", name=user) }}</p>
```

The correct form:

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

Beside it, `page.jinja`:

```jinja file page.jinja
{% catalog messages %}<p>{{ _("Greeting", name=user) }}</p>
```

### H7123

Message:

```text
Generic Error
@template: a translation is text for HTML and cannot stand in a <script> element
```

A translation is text for HTML, escaped for the place it lands in, and cannot stand where a JavaScript expression goes.

This module fails with H7123:

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

Beside it, `page.jinja`:

```jinja file page.jinja
{% catalog messages %}<script>var t = {{ _("Greeting", name=user) }};</script>
```

The correct form:

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

Beside it, `page.jinja`:

```jinja file page.jinja
{% catalog messages %}<p>{{ _("Greeting", name=user) }}</p>
```

### H7124

Message:

```text
Generic Error
@template: a translation stands alone in {{ }} or a {% trans %} block, without filters and without ~
```

A translation stands alone in {{ }} or as a {% trans %} block; a filter or a ~ would change a text that is the same for every language only in the catalog.

This module fails with H7124:

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

Beside it, `page.jinja`:

```jinja file page.jinja
{% catalog messages %}<p>{{ _("Greeting", name=user)|upper }}</p>
```

The correct form:

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

Beside it, `page.jinja`:

```jinja file page.jinja
{% catalog messages %}<p>{{ _("Greeting", name=user) }}</p>
```

### H7125

Message:

```text
Generic Error
@template: after the key, _( ) takes its arguments as name=value
```

After the key, _( ) takes its arguments as name=value: the name is the placeholder {name} of the text it fills.

This module fails with H7125:

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

Beside it, `page.jinja`:

```jinja file page.jinja
{% catalog messages %}<p>{{ _("Greeting", user) }}</p>
```

The correct form:

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

Beside it, `page.jinja`:

```jinja file page.jinja
{% catalog messages %}<p>{{ _("Greeting", name=user) }}</p>
```

### H7126

Message:

```text
Generic Error
@template: {% trans %} is given name twice
```

Each argument in the tag of {% trans %} has a name of its own.

This module fails with H7126:

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

Beside it, `page.jinja`:

```jinja file page.jinja
{% catalog messages %}<p>{% trans name=user, name=user %}Greeting{% endtrans %}</p>
```

The correct form:

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

Beside it, `page.jinja`:

```jinja file page.jinja
{% catalog messages %}<p>{% trans name=user %}Greeting{% endtrans %}</p>
```

### H7127

Message:

```text
Generic Error
@template: a module whose template translates imports Standard.I18n -- e.g. import Standard.I18n (Catalog); -- because the generated code calls it
```

The code a translation becomes calls Standard.I18n, so the module that holds the @template imports it, as it imports Standard.Template.

This module fails with H7127:

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

Beside it, `page.jinja`:

```jinja file page.jinja
{% catalog messages %}<p>{{ _("Greeting", name=user) }}</p>
```

The correct form:

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

Beside it, `page.jinja`:

```jinja file page.jinja
{% catalog messages %}<p>{{ _("Greeting", name=user) }}</p>
```

### H7128

Message:

```text
Generic Error
@template: {% catalog %} after {% extends %} stands in the template that is extended or in a block, where the text it serves is
```

In a template that extends another, only the blocks are kept. {% catalog %} stands in the extended template, before the blocks it serves.

This module fails with H7128:

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

Beside it, `base.jinja`:

```jinja file base.jinja
<main>{% block main %}{% endblock %}</main>
```

Beside it, `page.jinja`:

```jinja file page.jinja
{% extends "base.jinja" %}{% catalog messages %}{% block main %}{{ _("Greeting", name=user) }}{% endblock %}
```

The correct form:

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

Beside it, `base.jinja`:

```jinja file base.jinja
{% catalog messages %}<main>{% block main %}{% endblock %}</main>
```

Beside it, `page.jinja`:

```jinja file page.jinja
{% extends "base.jinja" %}{% block main %}{{ _("Greeting", name=user) }}{% endblock %}
```

## 8. SQL

Every example in this section opens a database in memory, applies the
migrations beside the module with @migrations and runs one statement in the
function run, with @query or @execute. The failing example and the correct
form differ in that statement or in the migration files.

A query is checked when the program is compiled, against the schema the
migrations build. The message of an error in a query gives the line and
column in the SQL; the message of an error in a migration begins with
migration and names the place in the file.

Beside every module of this section lies the following file, unless the
example shows files of its own; then it has only those.

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

Message:

```text
Generic Error
@query: a string is not closed (line 1, column 37 of the SQL)
```

A string or a quoted name in the SQL is not closed.

This module fails with H8001:

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

The correct form:

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

Message:

```text
Generic Error
@query: a comment is not closed (line 1, column 24 of the SQL)
```

A comment `/*` in the SQL is not closed with `*/`.

This module fails with H8002:

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

The correct form:

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

Message:

```text
Generic Error
@execute: a blob literal is an even number of hexadecimal digits (line 1, column 32 of the SQL)
```

A blob literal x'...' does not hold an even number of hexadecimal digits.

This module fails with H8003:

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

The correct form:

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

Message:

```text
Generic Error
@query: a number runs into a name (line 1, column 36 of the SQL)
```

A number runs straight into a name, as in 18years.

This module fails with H8004:

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

The correct form:

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

Message:

```text
Generic Error
@query: a name is quoted with double quotes here, not with ` or [ ] (line 1, column 8 of the SQL)
```

A name is quoted with backticks or brackets. Quote it with double quotes.

This module fails with H8005:

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

The correct form:

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

Message:

```text
Generic Error
@query: a numbered parameter (?NNN) is not accepted: write ? and give the values in order (line 1, column 36 of the SQL)
```

A numbered parameter such as ?1 stands in the SQL. Write ? and give the
values in order.

This module fails with H8006:

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

The correct form:

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

Message:

```text
Generic Error
@query: a named parameter is not accepted: write ? and give the values in order (line 1, column 36 of the SQL)
```

A named parameter such as :age stands in the SQL. Write ? and give the
values in order.

This module fails with H8007:

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

The correct form:

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

Message:

```text
Generic Error
@query: the character '#' is not SQL this compiler reads (line 1, column 40 of the SQL)
```

A character stands in the SQL that the compiler does not read as SQL, such
as #.

This module fails with H8008:

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

The correct form:

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

Message:

```text
Generic Error
@query: expected BY, found name (line 1, column 30 of the SQL)
```

A keyword is missing where the grammar needs it, such as BY after ORDER.

This module fails with H8009:

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

The correct form:

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

Message:

```text
Generic Error
@query: expected (, found 18 (line 1, column 37 of the SQL)
```

A symbol is missing where the grammar needs it, such as the parenthesis
after IN.

This module fails with H8010:

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

The correct form:

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

Message:

```text
Generic Error
@query: expected a table, found WHERE (line 1, column 18 of the SQL)
```

A name is missing where the grammar needs one, such as the table after FROM.

This module fails with H8011:

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

The correct form:

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

Message:

```text
Generic Error
@query: a subquery is not accepted in the SQL the compiler checks (line 1, column 37 of the SQL)
```

The SQL uses something SQLite knows and this compiler does not accept,
because it could not give it a type, such as a subquery.

This module fails with H8012:

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

The correct form:

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

Message:

```text
Generic Error
@query: sum(*): only count takes * (line 1, column 8 of the SQL)
```

A function other than count is given `*`.

This module fails with H8013:

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

The correct form:

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

Message:

```text
Generic Error
@query: a column alias is written with AS (line 1, column 20 of the SQL)
```

A column of the result is named without AS.

This module fails with H8014:

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

The correct form:

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

Message:

```text
Generic Error
@execute: expected ABORT, FAIL, IGNORE, REPLACE or ROLLBACK after OR (line 1, column 11 of the SQL)
```

OR in INSERT OR or UPDATE OR is followed by something other than ABORT,
FAIL, IGNORE, REPLACE or ROLLBACK.

This module fails with H8015:

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

The correct form:

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

Message:

```text
Generic Error
migration: expected a default value, found now
```

The default of a column in a migration is not a literal, a signed number,
CURRENT_TIME, CURRENT_DATE, CURRENT_TIMESTAMP or an expression in
parentheses.

This module fails with H8016:

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

Beside it, `migrations/1-schema.sql`:

```sql file migrations/1-schema.sql
CREATE TABLE users (
    id INTEGER PRIMARY KEY,
    name TEXT NOT NULL,
    created TEXT NOT NULL DEFAULT now
) STRICT;
```

The correct form:

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

Beside it, `migrations/1-schema.sql`:

```sql file migrations/1-schema.sql
CREATE TABLE users (
    id INTEGER PRIMARY KEY,
    name TEXT NOT NULL,
    created TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
) STRICT;
```

### H8017

Message:

```text
Generic Error
migration: a size after the type name is not a STRICT type (INT, INTEGER, REAL, TEXT, BLOB)
```

A column type in a migration has a size, as in VARCHAR(40). A STRICT table
knows INT, INTEGER, REAL, TEXT and BLOB, without a size.

This module fails with H8017:

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

Beside it, `migrations/1-schema.sql`:

```sql file migrations/1-schema.sql
CREATE TABLE users (
    id INTEGER PRIMARY KEY,
    name VARCHAR(40) NOT NULL
) STRICT;
```

The correct form:

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

Beside it, `migrations/1-schema.sql`:

```sql file migrations/1-schema.sql
CREATE TABLE users (
    id INTEGER PRIMARY KEY,
    name TEXT NOT NULL
) STRICT;
```

### H8018

Message:

```text
Generic Error
migration: expected a table constraint, found KEY
```

After CONSTRAINT and its name, a table constraint is not PRIMARY KEY,
UNIQUE, CHECK or FOREIGN KEY.

This module fails with H8018:

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

Beside it, `migrations/1-schema.sql`:

```sql file migrations/1-schema.sql
CREATE TABLE users (
    id INTEGER,
    name TEXT NOT NULL,
    CONSTRAINT users_key KEY (id)
) STRICT;
```

The correct form:

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

Beside it, `migrations/1-schema.sql`:

```sql file migrations/1-schema.sql
CREATE TABLE users (
    id INTEGER,
    name TEXT NOT NULL,
    CONSTRAINT users_key PRIMARY KEY (id)
) STRICT;
```

### H8019

Message:

```text
Generic Error
migration: expected ROWID after WITHOUT
```

WITHOUT after a table is not followed by ROWID.

This module fails with H8019:

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

Beside it, `migrations/1-schema.sql`:

```sql file migrations/1-schema.sql
CREATE TABLE users (
    id INTEGER PRIMARY KEY,
    name TEXT NOT NULL
) STRICT, WITHOUT ROWS;
```

The correct form:

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

Beside it, `migrations/1-schema.sql`:

```sql file migrations/1-schema.sql
CREATE TABLE users (
    id INTEGER PRIMARY KEY,
    name TEXT NOT NULL
) STRICT, WITHOUT ROWID;
```

### H8020

Message:

```text
Generic Error
migration: expected STRICT or WITHOUT ROWID, found WITHOUT_ROWID
```

In the list of table options after a comma stands something other than
STRICT or WITHOUT ROWID.

This module fails with H8020:

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

Beside it, `migrations/1-schema.sql`:

```sql file migrations/1-schema.sql
CREATE TABLE users (
    id INTEGER PRIMARY KEY,
    name TEXT NOT NULL
) STRICT, WITHOUT_ROWID;
```

The correct form:

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

Beside it, `migrations/1-schema.sql`:

```sql file migrations/1-schema.sql
CREATE TABLE users (
    id INTEGER PRIMARY KEY,
    name TEXT NOT NULL
) STRICT, WITHOUT ROWID;
```

### H8021

Message:

```text
Generic Error
migration: expected ( after the table
```

CREATE INDEX lacks the parenthesis with the columns after the table.

This module fails with H8021:

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

Beside it, `migrations/1-schema.sql`:

```sql file migrations/1-schema.sql
CREATE TABLE users (
    id INTEGER PRIMARY KEY,
    name TEXT NOT NULL
) STRICT;

CREATE INDEX users_name ON users name;
```

The correct form:

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

Beside it, `migrations/1-schema.sql`:

```sql file migrations/1-schema.sql
CREATE TABLE users (
    id INTEGER PRIMARY KEY,
    name TEXT NOT NULL
) STRICT;

CREATE INDEX users_name ON users (name);
```

### H8022

Message:

```text
Generic Error
migration: expected RENAME, ADD or DROP after ALTER TABLE
```

ALTER TABLE is followed by something other than RENAME, ADD or DROP.

This module fails with H8022:

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

Beside it, `migrations/1-schema.sql`:

```sql file migrations/1-schema.sql
CREATE TABLE users (
    id INTEGER PRIMARY KEY,
    name TEXT NOT NULL
) STRICT;

ALTER TABLE users MODIFY name TEXT;
```

The correct form:

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

Beside it, `migrations/1-schema.sql`:

```sql file migrations/1-schema.sql
CREATE TABLE users (
    id INTEGER PRIMARY KEY,
    name TEXT NOT NULL
) STRICT;

ALTER TABLE users ADD COLUMN nickname TEXT;
```

### H8023

Message:

```text
Generic Error
migration: CREATE VIEW is not accepted in a migration, which creates a table (CREATE TABLE) or an index (CREATE INDEX, CREATE UNIQUE INDEX)
```

A migration creates something other than a table or an index, such as a
view.

This module fails with H8023:

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

Beside it, `migrations/1-schema.sql`:

```sql file migrations/1-schema.sql
CREATE TABLE users (
    id INTEGER PRIMARY KEY,
    name TEXT NOT NULL
) STRICT;

CREATE VIEW names AS SELECT name FROM users;
```

The correct form:

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

Beside it, `migrations/1-schema.sql`:

```sql file migrations/1-schema.sql
CREATE TABLE users (
    id INTEGER PRIMARY KEY,
    name TEXT NOT NULL
) STRICT;

CREATE INDEX users_name ON users (name);
```

### H8024

Message:

```text
Generic Error
migration: DROP VIEW is not accepted in a migration
```

A migration drops something other than a table or an index, such as a view.

This module fails with H8024:

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

Beside it, `migrations/1-schema.sql`:

```sql file migrations/1-schema.sql
CREATE TABLE users (
    id INTEGER PRIMARY KEY,
    name TEXT NOT NULL
) STRICT;

DROP VIEW names;
```

The correct form:

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

Beside it, `migrations/1-schema.sql`:

```sql file migrations/1-schema.sql
CREATE TABLE users (
    id INTEGER PRIMARY KEY,
    name TEXT NOT NULL
) STRICT;

CREATE INDEX users_name ON users (name);

DROP INDEX users_name;
```

### H8025

Message:

```text
Generic Error
migration: a migration may hold CREATE TABLE, CREATE INDEX, ALTER TABLE, DROP TABLE, DROP INDEX, INSERT, UPDATE and DELETE, not PRAGMA
```

A migration holds a statement other than CREATE TABLE, CREATE INDEX, ALTER
TABLE, DROP TABLE, DROP INDEX, INSERT, UPDATE and DELETE, such as PRAGMA.

This module fails with H8025:

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

Beside it, `migrations/1-schema.sql`:

```sql file migrations/1-schema.sql
PRAGMA foreign_keys = ON;

CREATE TABLE users (
    id INTEGER PRIMARY KEY,
    name TEXT NOT NULL
) STRICT;
```

The correct form:

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

Beside it, `migrations/1-schema.sql`:

```sql file migrations/1-schema.sql
CREATE TABLE users (
    id INTEGER PRIMARY KEY,
    name TEXT NOT NULL
) STRICT;
```

### H8026

Message:

```text
Generic Error
@execute: a query is SELECT, INSERT, UPDATE or DELETE, not CREATE (line 1, column 1 of the SQL)
```

A query is not SELECT, INSERT, UPDATE or DELETE. A table is created in a
migration.

This module fails with H8026:

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

The correct form:

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

Beside it, `migrations/1-schema.sql`:

```sql file migrations/1-schema.sql
CREATE TABLE tags (
    id INTEGER PRIMARY KEY,
    label TEXT NOT NULL
) STRICT;
```

### H8027

Message:

```text
Generic Error
@query: there is no table user in the schema the migrations build (line 1, column 18 of the SQL)
```

The SQL names a table that the migrations do not build.

This module fails with H8027:

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

The correct form:

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

Message:

```text
Generic Error
@execute: table users has no column years (line 1, column 18 of the SQL)
```

The SQL names a column that the table does not have.

This module fails with H8028:

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

The correct form:

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

Message:

```text
Generic Error
@query: the type of parameter 1 cannot be told from where it stands: compare it with a column, or put it where a column's value goes (line 1, column 33 of the SQL)
```

A parameter stands where its type cannot be told, such as in ORDER BY. A
parameter takes its type from a column it is compared with or stored into.

This module fails with H8029:

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

The correct form:

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

Message:

```text
Generic Error
@query: there is no table or alias u in this query (line 1, column 8 of the SQL)
```

A column is qualified with a table or alias that the query does not have.

This module fails with H8030:

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

The correct form:

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

Message:

```text
Generic Error
@query: name: this query has no table to take a column from (line 1, column 8 of the SQL)
```

A query names a column and has no FROM to take it from.

This module fails with H8032:

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

The correct form:

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

Message:

```text
Generic Error
@query: no table of this query has a column mail (users) (line 1, column 30 of the SQL)
```

No table of the query has a column of this name.

This module fails with H8033:

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

The correct form:

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

Message:

```text
Generic Error
@query: more than one table of this query has a column id: name the table, as in t.id (line 1, column 48 of the SQL)
```

More than one table of the query has a column of this name. Name the table
in front of it.

This module fails with H8034:

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

The correct form:

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

Message:

```text
Generic Error
@query: a sign in front of TEXT: only a number has one (line 1, column 33 of the SQL)
```

A sign stands in front of something that is not a number.

This module fails with H8035:

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

The correct form:

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

Message:

```text
Generic Error
@query: NOT of TEXT: NOT takes a condition (line 1, column 30 of the SQL)
```

NOT stands in front of something that is not a condition.

This module fails with H8036:

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

The correct form:

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

Message:

```text
Generic Error
@query: % takes two INTEGERs (line 1, column 36 of the SQL)
```

% takes two INTEGERs and is given a REAL.

This module fails with H8037:

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

The correct form:

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

Message:

```text
Generic Error
@query: INTEGER + TEXT: arithmetic takes numbers (INTEGER or REAL) (line 1, column 34 of the SQL)
```

Arithmetic is done on something that is not a number.

This module fails with H8038:

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

The correct form:

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

Message:

```text
Generic Error
@query: TEXT || INTEGER: || joins TEXT to TEXT (line 1, column 13 of the SQL)
```

`||` joins something that is not TEXT.

This module fails with H8039:

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

The correct form:

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

Message:

```text
Generic Error
@query: a comparison with NULL is never true: write IS NULL or IS NOT NULL (line 1, column 36 of the SQL)
```

A value is compared with NULL using = or a similar operator. Such a
comparison is never true; write IS NULL or IS NOT NULL.

This module fails with H8040:

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

The correct form:

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

Message:

```text
Generic Error
@query: TEXT = INTEGER: SQLite compares these without converting, and the answer is always the same (line 1, column 35 of the SQL)
```

Two values of different types are compared, such as TEXT with INTEGER.
SQLite compares them without converting, and the answer never depends on the
values.

This module fails with H8041:

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

The correct form:

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

Message:

```text
Generic Error
@query: TEXT IS INTEGER: the two can never be the same (line 1, column 35 of the SQL)
```

IS compares two values of different types, which can never be the same.

This module fails with H8042:

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

The correct form:

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

Message:

```text
Generic Error
@query: a parameter tested for NULL: the value is known where it is given (line 1, column 32 of the SQL)
```

A parameter is tested for NULL. Its value is known where it is given, in the
program.

This module fails with H8043:

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

The correct form:

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

Message:

```text
Generic Error
@query: INTEGER LIKE TEXT: LIKE compares TEXT with TEXT (line 1, column 34 of the SQL)
```

LIKE or GLOB is given something that is not TEXT.

This module fails with H8044:

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

The correct form:

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

Message:

```text
Generic Error
@query: a parameter on the left of IN: put a column there (line 1, column 32 of the SQL)
```

A parameter stands on the left of IN. A column stands there.

This module fails with H8045:

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

The correct form:

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

Message:

```text
Generic Error
@query: NULL IN (...) is never true (line 1, column 35 of the SQL)
```

NULL stands on the left of IN. That is never true.

This module fails with H8046:

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

The correct form:

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

Message:

```text
Generic Error
@query: NULL in an IN list is never matched (line 1, column 59 of the SQL)
```

NULL stands in the list of IN. It is never matched.

This module fails with H8047:

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

The correct form:

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

Message:

```text
Generic Error
@query: INTEGER IN (... TEXT ...): the two can never be equal (line 1, column 38 of the SQL)
```

A value in the list of IN has another type than the value on the left, so
the two can never be equal.

This module fails with H8048:

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

The correct form:

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

Message:

```text
Generic Error
@query: a parameter on the left of BETWEEN: put a column there (line 1, column 32 of the SQL)
```

A parameter stands on the left of BETWEEN. A column stands there.

This module fails with H8049:

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

The correct form:

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

Message:

```text
Generic Error
@query: NULL BETWEEN ... is never true (line 1, column 35 of the SQL)
```

NULL stands on the left of BETWEEN. That is never true.

This module fails with H8050:

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

The correct form:

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

Message:

```text
Generic Error
@query: BETWEEN compares INTEGER with TEXT (line 1, column 42 of the SQL)
```

A bound of BETWEEN has another type than the value it is compared with.

This module fails with H8051:

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

The correct form:

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

Message:

```text
Generic Error
@query: INTEGER AND TEXT: AND joins conditions (line 1, column 39 of the SQL)
```

AND or OR joins something that is not a condition.

This module fails with H8052:

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

The correct form:

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

Message:

```text
Generic Error
@query: count(*) here: an aggregate stands in the columns, HAVING or ORDER BY (line 1, column 30 of the SQL)
```

`count(*)` stands outside the columns, HAVING and ORDER BY, such as in
WHERE.

This module fails with H8053:

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

The correct form:

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

Message:

```text
Generic Error
@query: max() here: an aggregate stands in the columns, HAVING or ORDER BY (line 1, column 30 of the SQL)
```

An aggregate function stands outside the columns, HAVING and ORDER BY, such
as in WHERE.

This module fails with H8054:

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

The correct form:

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

Message:

```text
Generic Error
@query: DISTINCT inside a function that is not an aggregate (line 1, column 8 of the SQL)
```

DISTINCT stands inside a function that is not an aggregate.

This module fails with H8055:

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

The correct form:

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

Message:

```text
Generic Error
@query: count() takes one argument here (line 1, column 8 of the SQL)
```

A function that takes one argument here is given another number.

This module fails with H8056:

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

The correct form:

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

Message:

```text
Generic Error
@query: abs() of TEXT: it takes a number (line 1, column 30 of the SQL)
```

A function that takes a number, such as abs or sum, is given something else.

This module fails with H8057:

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

The correct form:

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

Message:

```text
Generic Error
@query: count() of a parameter (line 1, column 8 of the SQL)
```

count is given a parameter.

This module fails with H8058:

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

The correct form:

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

Message:

```text
Generic Error
@query: max() of a parameter (line 1, column 45 of the SQL)
```

min or max is given a parameter.

This module fails with H8059:

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

The correct form:

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

Message:

```text
Generic Error
@query: max(NULL) (line 1, column 45 of the SQL)
```

min or max is given NULL.

This module fails with H8060:

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

The correct form:

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

Message:

```text
Generic Error
@query: ifnull() takes two arguments (line 1, column 30 of the SQL)
```

coalesce is given fewer than two arguments, or ifnull not exactly two.

This module fails with H8061:

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

The correct form:

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

Message:

```text
Generic Error
@query: coalesce() of parameters only has no type (line 1, column 38 of the SQL)
```

coalesce or ifnull is given only parameters, so its type cannot be told.

This module fails with H8062:

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

The correct form:

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

Message:

```text
Generic Error
@query: coalesce() whose first value is NULL (line 1, column 39 of the SQL)
```

The first value of coalesce or ifnull that is not a parameter is NULL.

This module fails with H8063:

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

The correct form:

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

Message:

```text
Generic Error
@query: coalesce() of TEXT and INTEGER (line 1, column 46 of the SQL)
```

coalesce or ifnull is given values of different types.

This module fails with H8064:

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

The correct form:

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

Message:

```text
Generic Error
@query: length() of INTEGER: it takes TEXT or BLOB (line 1, column 30 of the SQL)
```

length is given something other than TEXT or BLOB.

This module fails with H8065:

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

The correct form:

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

Message:

```text
Generic Error
@query: upper() of INTEGER: it takes TEXT (line 1, column 30 of the SQL)
```

lower or upper is given something other than TEXT.

This module fails with H8066:

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

The correct form:

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

Message:

```text
Generic Error
@query: trim() is not one of the functions whose type the compiler knows: count, sum, total, avg, min, max, coalesce, ifnull, length, lower, upper, abs (line 1, column 30 of the SQL)
```

The SQL calls a function whose type the compiler does not know. It knows
count, sum, total, avg, min, max, coalesce, ifnull, length, lower, upper and
abs.

This module fails with H8067:

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

The correct form:

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

Message:

```text
Generic Error
@query: two parameters meet, and neither says what type the other is (line 1, column 30 of the SQL)
```

Two parameters meet at one operator, and neither gives the other a type.

This module fails with H8068:

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

The correct form:

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

Message:

```text
Generic Error
@query: the WHERE condition is TEXT, and it has to be a condition (line 1, column 30 of the SQL)
```

A WHERE, ON, HAVING or CHECK is given something that is not a condition.

This module fails with H8069:

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

The correct form:

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

Message:

```text
Generic Error
@query: the column loud name cannot name a field of the row type: give it a name with AS (line 1, column 8 of the SQL)
```

A column of the result has a name that cannot name a field of the row
record, such as a name with a space or a Hilde keyword.

This module fails with H8070:

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

The correct form:

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

Message:

```text
Generic Error
@query: * without a table (line 1, column 8 of the SQL)
```

`*` stands in a query without a table.

This module fails with H8071:

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

The correct form:

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

Message:

```text
Generic Error
@query: there is no table or alias u in this query (line 1, column 8 of the SQL)
```

`t.*` names a table or alias the query does not have.

This module fails with H8072:

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

The correct form:

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

Message:

```text
Generic Error
@query: this column is always NULL and has no type (line 1, column 14 of the SQL)
```

A column of the result is always NULL and so has no type.

This module fails with H8073:

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

The correct form:

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

Message:

```text
Generic Error
@query: a column that is not a plain column needs a name: write AS (line 1, column 8 of the SQL)
```

A column of the result that is not a plain column has no name. Give it one
with AS.

This module fails with H8074:

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

The correct form:

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

Message:

```text
Generic Error
@query: two columns of the result are called name: rename one with AS (line 1, column 8 of the SQL)
```

Two columns of the result have the same name.

This module fails with H8075:

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

The correct form:

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

Message:

```text
Generic Error
@execute: NULL into name, which is NOT NULL (line 1, column 34 of the SQL)
```

NULL is written into a column that is NOT NULL.

This module fails with H8076:

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

The correct form:

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

Message:

```text
Generic Error
@execute: TEXT into age, a INTEGER column: a STRICT table refuses it (line 1, column 42 of the SQL)
```

A value of another type is written into a column. A STRICT table refuses it
when the program runs.

This module fails with H8077:

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

The correct form:

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

Message:

```text
Generic Error
@execute: a value that may be NULL into name, which is NOT NULL (line 1, column 25 of the SQL)
```

A value that may be NULL is written into a column that is NOT NULL.

This module fails with H8078:

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

The correct form:

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

Message:

```text
Generic Error
@query: users stands twice in FROM: give one an alias (line 1, column 29 of the SQL)
```

A table stands twice in FROM without an alias that tells the two apart.

This module fails with H8079:

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

The correct form:

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

Message:

```text
Generic Error
@query: LIMIT and OFFSET take an INTEGER that is not NULL (line 1, column 30 of the SQL)
```

LIMIT or OFFSET is given something other than an INTEGER that is not NULL.

This module fails with H8081:

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

The correct form:

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

Message:

```text
Generic Error
@execute: name is named twice (line 1, column 26 of the SQL)
```

The column list of an INSERT names a column twice.

This module fails with H8082:

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

The correct form:

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

Message:

```text
Generic Error
@execute: the INSERT leaves out name, which is NOT NULL and has no DEFAULT (line 1, column 13 of the SQL)
```

An INSERT leaves out a column that is NOT NULL and has no default.

This module fails with H8083:

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

The correct form:

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

Message:

```text
Generic Error
@execute: DEFAULT VALUES with a column list (line 1, column 13 of the SQL)
```

An INSERT has a column list and DEFAULT VALUES.

This module fails with H8084:

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

The correct form:

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

Message:

```text
Generic Error
@execute: a row of 1 values for 2 columns (line 1, column 13 of the SQL)
```

A row of an INSERT has another number of values than there are columns.

This module fails with H8085:

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

The correct form:

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

Message:

```text
Generic Error
migration: extra is ANY: a column the compiler checks against has one of INT, INTEGER, REAL, TEXT, BLOB
```

A column in a migration has the type ANY. The compiler checks a query
against a column that has INT, INTEGER, REAL, TEXT or BLOB.

This module fails with H8086:

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

Beside it, `migrations/1-schema.sql`:

```sql file migrations/1-schema.sql
CREATE TABLE users (
    id INTEGER PRIMARY KEY,
    name TEXT NOT NULL,
    extra ANY
) STRICT;
```

The correct form:

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

Beside it, `migrations/1-schema.sql`:

```sql file migrations/1-schema.sql
CREATE TABLE users (
    id INTEGER PRIMARY KEY,
    name TEXT NOT NULL,
    extra TEXT
) STRICT;
```

### H8087

Message:

```text
Generic Error
migration: nickname has no type: a STRICT table gives every column one
```

A column in a migration has no type. A STRICT table gives every column one.

This module fails with H8087:

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

Beside it, `migrations/1-schema.sql`:

```sql file migrations/1-schema.sql
CREATE TABLE users (
    id INTEGER PRIMARY KEY,
    name TEXT NOT NULL,
    nickname
) STRICT;
```

The correct form:

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

Beside it, `migrations/1-schema.sql`:

```sql file migrations/1-schema.sql
CREATE TABLE users (
    id INTEGER PRIMARY KEY,
    name TEXT NOT NULL,
    nickname TEXT
) STRICT;
```

### H8088

Message:

```text
Generic Error
migration: born is DATE, which is not a STRICT type: INT, INTEGER, REAL, TEXT, BLOB
```

A column in a migration has a type that a STRICT table does not know, such
as DATE.

This module fails with H8088:

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

Beside it, `migrations/1-schema.sql`:

```sql file migrations/1-schema.sql
CREATE TABLE users (
    id INTEGER PRIMARY KEY,
    name TEXT NOT NULL,
    born DATE
) STRICT;
```

The correct form:

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

Beside it, `migrations/1-schema.sql`:

```sql file migrations/1-schema.sql
CREATE TABLE users (
    id INTEGER PRIMARY KEY,
    name TEXT NOT NULL,
    born TEXT
) STRICT;
```

### H8089

Message:

```text
Generic Error
migration: table users exists already
```

A migration creates a table that exists already.

This module fails with H8089:

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

Beside it, `migrations/1-schema.sql`:

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

The correct form:

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

Beside it, `migrations/1-schema.sql`:

```sql file migrations/1-schema.sql
CREATE TABLE users (
    id INTEGER PRIMARY KEY,
    name TEXT NOT NULL
) STRICT;

ALTER TABLE users ADD COLUMN email TEXT;
```

### H8090

Message:

```text
Generic Error
migration: table users is not STRICT: without STRICT, SQLite stores a value of any type in any column, and the types the compiler checks would not hold
```

A table is created without STRICT. Without it SQLite stores a value of any
type in any column, and the types the compiler checks would not hold.

This module fails with H8090:

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

Beside it, `migrations/1-schema.sql`:

```sql file migrations/1-schema.sql
CREATE TABLE users (
    id INTEGER PRIMARY KEY,
    name TEXT NOT NULL
);
```

The correct form:

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

Beside it, `migrations/1-schema.sql`:

```sql file migrations/1-schema.sql
CREATE TABLE users (
    id INTEGER PRIMARY KEY,
    name TEXT NOT NULL
) STRICT;
```

### H8091

Message:

```text
Generic Error
migration: column name is defined twice
```

A table defines a column twice.

This module fails with H8091:

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

Beside it, `migrations/1-schema.sql`:

```sql file migrations/1-schema.sql
CREATE TABLE users (
    id INTEGER PRIMARY KEY,
    name TEXT NOT NULL,
    name TEXT
) STRICT;
```

The correct form:

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

Beside it, `migrations/1-schema.sql`:

```sql file migrations/1-schema.sql
CREATE TABLE users (
    id INTEGER PRIMARY KEY,
    name TEXT NOT NULL,
    nickname TEXT
) STRICT;
```

### H8092

Message:

```text
Generic Error
migration: table users has more than one PRIMARY KEY
```

A table has more than one PRIMARY KEY.

This module fails with H8092:

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

Beside it, `migrations/1-schema.sql`:

```sql file migrations/1-schema.sql
CREATE TABLE users (
    id INTEGER PRIMARY KEY,
    name TEXT NOT NULL PRIMARY KEY
) STRICT;
```

The correct form:

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

Beside it, `migrations/1-schema.sql`:

```sql file migrations/1-schema.sql
CREATE TABLE users (
    id INTEGER PRIMARY KEY,
    name TEXT NOT NULL UNIQUE
) STRICT;
```

### H8093

Message:

```text
Generic Error
migration: the PRIMARY KEY names user_id, which is not a column of users
```

The PRIMARY KEY of a table names a column the table does not have.

This module fails with H8093:

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

Beside it, `migrations/1-schema.sql`:

```sql file migrations/1-schema.sql
CREATE TABLE users (
    id INTEGER,
    name TEXT NOT NULL,
    PRIMARY KEY (user_id)
) STRICT;
```

The correct form:

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

Beside it, `migrations/1-schema.sql`:

```sql file migrations/1-schema.sql
CREATE TABLE users (
    id INTEGER,
    name TEXT NOT NULL,
    PRIMARY KEY (id)
) STRICT;
```

### H8094

Message:

```text
Generic Error
migration: table users has a column name already
```

ALTER TABLE ADD COLUMN adds a column the table has already.

This module fails with H8094:

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

Beside it, `migrations/1-schema.sql`:

```sql file migrations/1-schema.sql
CREATE TABLE users (
    id INTEGER PRIMARY KEY,
    name TEXT NOT NULL
) STRICT;

ALTER TABLE users ADD COLUMN name TEXT;
```

The correct form:

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

Beside it, `migrations/1-schema.sql`:

```sql file migrations/1-schema.sql
CREATE TABLE users (
    id INTEGER PRIMARY KEY,
    name TEXT NOT NULL
) STRICT;

ALTER TABLE users ADD COLUMN nickname TEXT;
```

### H8095

Message:

```text
Generic Error
migration: ALTER TABLE ADD COLUMN cannot add a PRIMARY KEY
```

ALTER TABLE ADD COLUMN adds a PRIMARY KEY. SQLite cannot add one to an
existing table.

This module fails with H8095:

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

Beside it, `migrations/1-schema.sql`:

```sql file migrations/1-schema.sql
CREATE TABLE users (
    id INTEGER PRIMARY KEY,
    name TEXT NOT NULL
) STRICT;

ALTER TABLE users ADD COLUMN code INTEGER PRIMARY KEY;
```

The correct form:

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

Beside it, `migrations/1-schema.sql`:

```sql file migrations/1-schema.sql
CREATE TABLE users (
    id INTEGER PRIMARY KEY,
    name TEXT NOT NULL
) STRICT;

ALTER TABLE users ADD COLUMN code INTEGER;

CREATE UNIQUE INDEX users_code ON users (code);
```

### H8096

Message:

```text
Generic Error
migration: city is NOT NULL without a DEFAULT, and SQLite refuses to add such a column to a table that has rows
```

ALTER TABLE ADD COLUMN adds a NOT NULL column without a default. SQLite
refuses to add such a column to a table that has rows.

This module fails with H8096:

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

Beside it, `migrations/1-schema.sql`:

```sql file migrations/1-schema.sql
CREATE TABLE users (
    id INTEGER PRIMARY KEY,
    name TEXT NOT NULL
) STRICT;

ALTER TABLE users ADD COLUMN city TEXT NOT NULL;
```

The correct form:

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

Beside it, `migrations/1-schema.sql`:

```sql file migrations/1-schema.sql
CREATE TABLE users (
    id INTEGER PRIMARY KEY,
    name TEXT NOT NULL
) STRICT;

ALTER TABLE users ADD COLUMN city TEXT NOT NULL DEFAULT '';
```

### H8097

Message:

```text
Generic Error
migration: table users exists already
```

ALTER TABLE RENAME TO gives a table the name of a table that exists.

This module fails with H8097:

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

Beside it, `migrations/1-schema.sql`:

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

The correct form:

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

Beside it, `migrations/1-schema.sql`:

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

Message:

```text
Generic Error
migration: table users has a column name already
```

ALTER TABLE RENAME COLUMN gives a column the name of a column the table has.

This module fails with H8098:

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

Beside it, `migrations/1-schema.sql`:

```sql file migrations/1-schema.sql
CREATE TABLE users (
    id INTEGER PRIMARY KEY,
    name TEXT NOT NULL,
    email TEXT
) STRICT;

ALTER TABLE users RENAME COLUMN email TO name;
```

The correct form:

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

Beside it, `migrations/1-schema.sql`:

```sql file migrations/1-schema.sql
CREATE TABLE users (
    id INTEGER PRIMARY KEY,
    name TEXT NOT NULL,
    email TEXT
) STRICT;

ALTER TABLE users RENAME COLUMN email TO mail;
```

### H8099

Message:

```text
Generic Error
migration: a table cannot lose its last column
```

ALTER TABLE DROP COLUMN drops the last column of a table. Drop the table
instead.

This module fails with H8099:

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

Beside it, `migrations/1-schema.sql`:

```sql file migrations/1-schema.sql
CREATE TABLE users (
    id INTEGER PRIMARY KEY,
    name TEXT NOT NULL
) STRICT;

CREATE TABLE tags (label TEXT) STRICT;

ALTER TABLE tags DROP COLUMN label;
```

The correct form:

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

Beside it, `migrations/1-schema.sql`:

```sql file migrations/1-schema.sql
CREATE TABLE users (
    id INTEGER PRIMARY KEY,
    name TEXT NOT NULL
) STRICT;

CREATE TABLE tags (label TEXT) STRICT;

DROP TABLE tags;
```

### H8100

Message:

```text
Generic Error
migration: there is no table tags to drop
```

DROP TABLE drops a table that does not exist.

This module fails with H8100:

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

Beside it, `migrations/1-schema.sql`:

```sql file migrations/1-schema.sql
CREATE TABLE users (
    id INTEGER PRIMARY KEY,
    name TEXT NOT NULL
) STRICT;

DROP TABLE tags;
```

The correct form:

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

Beside it, `migrations/1-schema.sql`:

```sql file migrations/1-schema.sql
CREATE TABLE users (
    id INTEGER PRIMARY KEY,
    name TEXT NOT NULL
) STRICT;

DROP TABLE IF EXISTS tags;
```

### H8101

Message:

```text
Generic Error
migration: index users_key exists already
```

CREATE INDEX creates an index whose name exists already.

This module fails with H8101:

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

Beside it, `migrations/1-schema.sql`:

```sql file migrations/1-schema.sql
CREATE TABLE users (
    id INTEGER PRIMARY KEY,
    name TEXT NOT NULL
) STRICT;

CREATE INDEX users_key ON users (name);

CREATE INDEX users_key ON users (id, name);
```

The correct form:

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

Beside it, `migrations/1-schema.sql`:

```sql file migrations/1-schema.sql
CREATE TABLE users (
    id INTEGER PRIMARY KEY,
    name TEXT NOT NULL
) STRICT;

CREATE INDEX users_key ON users (name);

CREATE INDEX users_id_name ON users (id, name);
```

### H8102

Message:

```text
Generic Error
migration: there is no index users_name to drop
```

DROP INDEX drops an index that does not exist.

This module fails with H8102:

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

Beside it, `migrations/1-schema.sql`:

```sql file migrations/1-schema.sql
CREATE TABLE users (
    id INTEGER PRIMARY KEY,
    name TEXT NOT NULL
) STRICT;

DROP INDEX users_name;
```

The correct form:

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

Beside it, `migrations/1-schema.sql`:

```sql file migrations/1-schema.sql
CREATE TABLE users (
    id INTEGER PRIMARY KEY,
    name TEXT NOT NULL
) STRICT;

DROP INDEX IF EXISTS users_name;
```

### H8103

Message:

```text
Generic Error
@query: cannot read ./migrations/2-more.sql: it is a directory, not a file
```

A migration file cannot be read, for example because a directory carries the
name of a migration.

This module fails with H8103:

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

Beside it, `migrations/1-schema.sql`:

```sql file migrations/1-schema.sql
CREATE TABLE users (
    id INTEGER PRIMARY KEY,
    name TEXT NOT NULL
) STRICT;
```

Beside it, `migrations/2-more.sql/README`:

```text file migrations/2-more.sql/README
This directory is not a migration.
```

The correct form:

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

Beside it, `migrations/1-schema.sql`:

```sql file migrations/1-schema.sql
CREATE TABLE users (
    id INTEGER PRIMARY KEY,
    name TEXT NOT NULL
) STRICT;
```

### H8104

Message:

```text
Generic Error
@query: there is no directory ./migrations: the schema a query is checked against is the migrations beside the module
```

There is no directory migrations beside the module. The schema a query is
checked against is built from the migrations in that directory.

This module fails with H8104:

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

Beside it, `migration/1-schema.sql`:

```sql file migration/1-schema.sql
CREATE TABLE users (
    id INTEGER PRIMARY KEY,
    name TEXT NOT NULL
) STRICT;
```

The correct form:

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

Beside it, `migrations/1-schema.sql`:

```sql file migrations/1-schema.sql
CREATE TABLE users (
    id INTEGER PRIMARY KEY,
    name TEXT NOT NULL
) STRICT;
```

### H8105

Message:

```text
Generic Error
@query: ./migrations holds no .sql file
```

The directory migrations holds no file that ends in .sql.

This module fails with H8105:

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

Beside it, `migrations/1-schema.txt`:

```sql file migrations/1-schema.txt
CREATE TABLE users (
    id INTEGER PRIMARY KEY,
    name TEXT NOT NULL
) STRICT;
```

The correct form:

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

Beside it, `migrations/1-schema.sql`:

```sql file migrations/1-schema.sql
CREATE TABLE users (
    id INTEGER PRIMARY KEY,
    name TEXT NOT NULL
) STRICT;
```

### H8106

Message:

```text
Generic Error
@query: ./migrations/schema.sql: a migration is called <number>-<name>.sql, numbered from 1
```

A file in migrations is not called `<number>-<name>.sql` with a number from 1.

This module fails with H8106:

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

Beside it, `migrations/schema.sql`:

```sql file migrations/schema.sql
CREATE TABLE users (
    id INTEGER PRIMARY KEY,
    name TEXT NOT NULL
) STRICT;
```

The correct form:

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

Beside it, `migrations/1-schema.sql`:

```sql file migrations/1-schema.sql
CREATE TABLE users (
    id INTEGER PRIMARY KEY,
    name TEXT NOT NULL
) STRICT;
```

### H8107

Message:

```text
Generic Error
@query: ./migrations/3-email.sql: migration 2 is missing or doubled; they are numbered 1, 2, 3 ... without a gap
```

The migrations are not numbered 1, 2, 3 and so on without a gap, or a number
stands twice.

This module fails with H8107:

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

Beside it, `migrations/1-schema.sql`:

```sql file migrations/1-schema.sql
CREATE TABLE users (
    id INTEGER PRIMARY KEY,
    name TEXT NOT NULL
) STRICT;
```

Beside it, `migrations/3-email.sql`:

```sql file migrations/3-email.sql
ALTER TABLE users ADD COLUMN email TEXT;
```

The correct form:

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

Beside it, `migrations/1-schema.sql`:

```sql file migrations/1-schema.sql
CREATE TABLE users (
    id INTEGER PRIMARY KEY,
    name TEXT NOT NULL
) STRICT;
```

Beside it, `migrations/2-email.sql`:

```sql file migrations/2-email.sql
ALTER TABLE users ADD COLUMN email TEXT;
```

### H8108

Message:

```text
Generic Error
migration: expected ; after the statement, found CREATE
```

A statement in a migration is not followed by ; before the next one begins.

This module fails with H8108:

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

Beside it, `migrations/1-schema.sql`:

```sql file migrations/1-schema.sql
CREATE TABLE users (
    id INTEGER PRIMARY KEY,
    name TEXT NOT NULL
) STRICT

CREATE INDEX users_name ON users (name);
```

The correct form:

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

Beside it, `migrations/1-schema.sql`:

```sql file migrations/1-schema.sql
CREATE TABLE users (
    id INTEGER PRIMARY KEY,
    name TEXT NOT NULL
) STRICT;

CREATE INDEX users_name ON users (name);
```

### H8109

Message:

```text
Generic Error
migration: a migration has no parameters
```

A migration holds a parameter ?. A migration is run as it stands, so a
parameter in it has nothing to stand for.

This module fails with H8109:

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

Beside it, `migrations/1-schema.sql`:

```sql file migrations/1-schema.sql
CREATE TABLE users (
    id INTEGER PRIMARY KEY,
    name TEXT NOT NULL
) STRICT;

INSERT INTO users (name) VALUES (?);
```

The correct form:

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

Beside it, `migrations/1-schema.sql`:

```sql file migrations/1-schema.sql
CREATE TABLE users (
    id INTEGER PRIMARY KEY,
    name TEXT NOT NULL
) STRICT;

INSERT INTO users (name) VALUES ('ann');
```

### H8110

Message:

```text
Generic Error
@migrations: a module that uses @migrations imports Standard.Sqlite or Standard.SqlCipher -- e.g. `import Standard.Sqlite (Connection);' -- because the generated code calls it
```

A module that uses @query, @execute or @migrations imports neither
Standard.Sqlite nor Standard.SqlCipher. The generated code calls one of
them, and the import chooses which.

This module fails with H8110:

```hilde fails H8110
module body Example is
    function main(): ExitCode is
        printLn(@migrations);
        return ExitSuccess();
    end;
end module body.
```

The correct form:

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

Message:

```text
Generic Error
@execute: one statement per query; found DELETE after it (line 1, column 20 of the SQL)
```

The SQL of one @query or @execute holds more than one statement.

This module fails with H8111:

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

The correct form:

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

Message:

```text
Generic Error
@query: the SQL has 1 parameter and 0 values are given
```

The SQL has another number of parameters ? than values are given.

This module fails with H8112:

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

The correct form:

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

Message:

```text
Generic Error
@query: the row type is a record, written `Name' or `Name[R]' with R the region the row's text is lent under
```

The row type of @query is not a record, written Name or Name[R] with R the
region the row's text is lent under.

This module fails with H8113:

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

The correct form:

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

Message:

```text
Generic Error
@query: this statement returns no rows: write it with @execute, or add RETURNING
```

@query is given a statement that returns no rows. Write it with @execute, or
add RETURNING.

This module fails with H8115:

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

The correct form:

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

Message:

```text
Generic Error
@execute: this statement returns rows: write it with @query ... for
```

@execute is given a statement that returns rows. Write it with @query ...
for.

This module fails with H8116:

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

The correct form:

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

## 9. Contracts

A function's contract is its requires and ensures clauses
(docs/syntax.en.md, section 3). The errors of this chapter come
from where a contract stands and from its conditions, which may only
read.

### H2051

Message:

```text
Declaration Error
The body of the public function `half` holds a contract.

The contract of a public function stands in its interface only: it is written at `Example.hih:3`.  Remove the requires, ensures and raises clauses from the body.
```

The body of a public function has requires, ensures or raises clauses.
A public function's contract is written once, in its interface, where
every caller reads it. The message names the place of the interface's
contract, or of the declaration when the interface has none.

This module fails with H2051:

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

Beside it, `Example.hih`:

```hilde file Example.hih
module Example is
    function half(n: Nat32): Nat32
        requires n > 0;

    function main(): ExitCode;
end module.
```

The correct form:

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

Beside it, `Example.hih`:

```hilde file Example.hih
module Example is
    function half(n: Nat32): Nat32
        requires n > 0;

    function main(): ExitCode;
end module.
```

### H2052

Message:

```text
Declaration Error
The function `cAbs` is imported from C and has a contract.

A contract is checked by statements put into the body of its function, and a foreign function has none.  Write the contract on a Hilde function that calls it.
```

A function imported from C has a contract.
The compiler checks a contract with statements it puts into the body of
the function, and a function imported with Foreign_Import has no body of
its own.

This module fails with H2052:

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

The correct form:

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

Message:

```text
Declaration Error
The ensures of `addThree` names `limit`, which the body of the function also declares.

An ensures sees the parameters, result and the names of modules; checked at a return, it would read the body's variable instead.  Rename the variable in the body.
```

An ensures names a variable that the function's body declares.
An ensures is checked at every return, where the body's variables are
still in scope; a name the body declares would be read there instead of
the module's name of the same spelling. The ensures reads the
parameters, result and old values only.

This module fails with H2053:

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

The correct form:

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

Message:

```text
Declaration Error
The function `doubled` has an ensures and a parameter named `result`.

In an ensures, result is the value the function returns.  Rename the parameter.
```

A function with an ensures has a parameter named result.
In an ensures the name result stands for the value the function
returns, so a parameter of that name could not be read there.

This module fails with H2054:

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

The correct form:

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

Message:

```text
Declaration Error
An old(e) stands in a requires.

old(e) stands only in an ensures, takes one value, and does not nest: it is the value e had when the function was entered.
```

old is written where it has no meaning: in a requires, inside another old, or with other than one value.
old(e) is the value e had when the function was entered, read again
when it returns; in a requires, which is checked at the entrance, it
would say nothing. The first line of the message says which of the
three it was.

This module fails with H2055:

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

The correct form:

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

Message:

```text
Declaration Error
The test `testHalf` has a requires.

A violated requires names the call that broke it, and a test is called by hilde test, not by a call in the programme.  Check the condition in the test's body instead.
```

A test function has a requires.
A violated requires names the call that broke it, and nothing in the
programme calls a test: hilde test does. A test checks what it needs in
its body, with the assertions of Standard.Testing.

This module fails with H2056:

```hilde fails H2056
module body Example.Test is
    function testHalf(): Unit
        requires argumentCount() > 0
    is
        return nil;
    end;
end module body.
```

Run with:

```sh command
hilde test Example.hiq
```

The correct form:

```hilde
module body Example.Test is
    function testHalf(): Unit is
        return nil;
    end;
end module body.
```

Run with:

```sh command
hilde test Example.hiq
```

### H2057

Message:

```text
Declaration Error
The record `Range` has an invariant, and its slots can be reached outside its module: its slots stand in the interface.

An invariant is checked where a value leaves its module, which holds only when no other module can build the record or write its slots.  Declare the type opaque in the interface, type Name: Universe;, and the record in the body.
```

A record with an invariant can be built or written outside its module.
An invariant is checked at the returns of the module's public functions,
where a value leaves the module. That holds it only if no other module
can build the record or assign its slots, which is so when the interface
declares the type opaque or not at all. A module without an interface
has no private record.

This module fails with H2057:

```hilde fails H2057
module body Example is
    function main(): ExitCode is
        let r: Range := Range(low => 1, high => 2);
        printLn(r.high);
        return ExitSuccess();
    end;
end module body.
```

Beside it, `Example.hih`:

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

The correct form:

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

Beside it, `Example.hih`:

```hilde file Example.hih
module Example is
    type Range: Free;

    function make(low: Nat32, high: Nat32): Range;

    function main(): ExitCode;
end module.
```

### H3096

Message:

```text
Type Error
This condition uses the linear value `token` itself, which would consume it.

A condition only reads: read a linear value through a reference, `&token`.
```

A condition uses a linear value itself instead of through a reference.
A condition only reads. A linear value used itself is consumed, and the
function would have lost it before its body ran.

This module fails with H3096:

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

The correct form:

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

Message:

```text
Type Error
This condition makes a reference to write through, with `&!`, `&~` or a writable span.

A condition only reads: take a read reference with & instead.
```

A condition takes a reference to write through.
A condition only reads, so a reference to write through has no place in
it; a write reference that is a parameter is read with &.

This module fails with H3097:

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

The correct form:

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

Message:

```text
Type Error
This condition calls `Example.countedTwice -> Example.bump`, which asks for a reference to write through.

A condition only reads: every function it calls, and every function those call, stays out of the binding modules and C, and asks for no reference to write through.
```

A condition calls a function that reaches a binding module, C or a reference to write through.
The compiler follows every call of a condition through the bodies of the
functions it reaches, to any depth. The message gives the chain of calls
and what its last function does: it stands in a module whose name begins
with Bindings., it is imported from C or writes C with @embed, or it
takes a reference to write through. The compiler's own module
Hilde.Pervasive is not looked into; its parameters are.

This module fails with H3098:

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

The correct form:

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

Message:

```text
Type Error
This condition calls through the function pointer f, so the function that runs is not known where the condition is checked.

A condition only reads, and the compiler has to see every function it calls to know that.  Call a function by its name.
```

A condition calls through a function pointer or a method of a type parameter.
Which function runs is decided later, by the value of the pointer or by
the type the parameter stands for, and the compiler cannot look into it
where the condition is checked.

This module fails with H3099:

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

The correct form:

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

Message:

```text
Type Error
old takes a value of the type `Token`, which is not in the Free universe.

old copies a value when the function is entered, and only a free value can be copied.
```

old is given a value that is not free.
old keeps a copy of its value from the entrance to the return, and a
linear value cannot be copied.

This module fails with H3100:

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

The correct form:

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

Message:

```text
Type Error
The function `half` has a requires and cannot be taken as a function pointer.

A violated requires names the call that broke it, and a call through a pointer has no place the compiler can name.  Call the function directly, or write a function without a requires that calls it.
```

A function with a requires is taken as a function pointer.
The compiler hands every call of a function with a requires the place
of the call, for the message of a violated condition; a call through a
pointer has no such place.

This module fails with H3101:

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

The correct form:

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

Message:

```text
Entrypoint Definition Error
The entrypoint function has a requires.

A violated requires names the call that broke it, and the entrypoint is called by the system, not by a call in the programme.  Check the condition at the start of the function's body instead.
```

The entry point function has a requires.
A violated requires names the call that broke it, and no call in the
programme calls the entry point.

This module fails with H5008:

```hilde fails H5008
module body Example is
    function main(): ExitCode
        requires argumentCount() > 0
    is
        return ExitSuccess();
    end;
end module body.
```

The correct form:

```hilde
module body Example is
    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

## 10. Error kinds

A function's raises clause names the error kinds it can end with
(docs/syntax.en.md, section 3). The errors of this chapter come from where
a clause stands and from the raises and calls that exceed it.

### H2058

Message:

```text
Declaration Error
The method `measure` of an instance has a raises clause.

The raises clause of a method stands in the typeclass, where every instance and every caller reads it.  Remove the clause from the instance, and write it at the method's declaration in the typeclass.
```

The method of an instance has a raises clause.
The raises clause of a method stands once, at the method's declaration in
the typeclass, where every instance and every caller reads it; an
instance inherits it. A clause on the instance's method would be a second
promise nothing holds to the first, so it is refused. The message names
the method.

This module fails with H2058:

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

The correct form:

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

Message:

```text
Type Error
The raise of `Denied` is not among the kinds this function's raises clause names: `NotFound`.  Name the kind in the raises clause of this function, or raise a kind it names.
```

A raise names a kind that the function's raises clause does not.
A function may raise only the kinds its own clause names. The message
names the kind raised and the kinds the clause holds, or says that the
function has no clause.

This module fails with H3102:

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

The correct form:

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

Message:

```text
Type Error
The call of `Example.pick` can end with the error kind(s) `NotFound`, but this function's raises clause names: `no kinds (no raises clause)`.  A function may call only the functions whose error kinds it has named; name the missing kind(s) in the raises clause of this function, or take the call out.
```

A call can end with an error kind that the caller's raises clause does
not name.
A function may call only functions whose error kinds it names itself, so
a kind never reaches a caller that did not promise it; the entry point is
held to the same rule. The message names the callee, the kinds that are
missing and the kinds the caller names. A method call is held to the
clause at the typeclass's declaration of the method.

This module fails with H3103:

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

The correct form:

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

Message:

```text
Type Error
The function `pick` has a raises clause and cannot be taken as a function pointer.

A call through a pointer has no signature the compiler can hold against the caller's raises clause.  Call the function directly.
```

A function with a raises clause is taken as a function pointer.
A call through a pointer has no signature the compiler can hold against
the caller's clause, so such a function is called by its name only.

This module fails with H3104:

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

The correct form:

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

## 11. Never and slots

### H2060

Message:

```text
Declaration Error
A return stands in a function that returns `Never`.

A function that returns Never does not come back: it ends in a call of a function that returns Never, in a raise or in a loop that never ends.
```

A return stands in a function that returns Never. Such a function has no
value to give back, so no path through it reaches a return.

This module fails with H2060:

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

The correct form:

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

Message:

```text
Declaration Error
The function `stop` returns `Never` but a path through it comes to its end.

Every path ends in a call of a function that returns Never, in a raise or in a while whose condition is true.
```

A function that returns Never has a path that comes to the end of its
body. Here the if has no else, so the path where b is false falls through.

This module fails with H2061:

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

The correct form:

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

Message:

```text
Declaration Error
The function `stop` returns `Never` and has an ensures.

An ensures speaks of the state at a return, and a function that returns Never does not return: the clause would hold of nothing.  Remove it; a requires stays allowed.
```

A function that returns Never carries an ensures clause. The clause would
be checked at a return, and there is none.

This module fails with H2062:

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

The correct form:

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

Message:

```text
Declaration Error
The slot `Greeting.greet` has no default body and no function of the programme implements it.

Give the declaration a body in the module, or mark one function with pragma Implements(Name => "Greeting.greet").
```

A slot has neither a default body nor an implementation in the
programme. The check runs when the last module of the programme is
compiled.

This module fails with H2063:

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

Beside it, `Greeting.hih`:

```hilde file Greeting.hih
module Greeting is
    -- Says hello; the programme implements it.
    pragma Slot;
    function greet(): Unit;
end module.
```

Beside it, `Greeting.hiq`:

```hilde file Greeting.hiq
module body Greeting is
end module body.
```

The correct form:

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

Beside it, `Greeting.hih`:

```hilde file Greeting.hih
module Greeting is
    -- Says hello; the programme implements it.
    pragma Slot;
    function greet(): Unit;
end module.
```

Beside it, `Greeting.hiq`:

```hilde file Greeting.hiq
module body Greeting is
end module body.
```

### H2064

Message:

```text
Declaration Error
The slot `Hilde.Pervasive.onOverflow` is implemented twice: by `Example.first` and by `Example.second`.

A slot has one implementation in a programme; remove the pragma Implements from one of them.
```

Two functions of the programme implement the same slot. A slot has one
implementation, so the compiler would not know which to call.

This module fails with H2064:

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

The correct form:

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

Message:

```text
Declaration Error
The function `Example.handled` implements the slot `Hilde.Pervasive.onOverflow` but its signature differs: the parameter message: Span[Nat8, Static] of the slot is text: Span[Nat8, Static] in the implementation.

An implementation has the parameters of the slot, with their names and types, and its result type.
```

An implementation of a slot has another signature than the slot. The
parameters must agree in number, name and type, and the result types
must be the same.

This module fails with H2065:

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

The correct form:

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

Message:

```text
Declaration Error
The function `Example.handled` implements `Hilde.Pervasive.nowhere`, which is not a slot of a module compiled before it.

The name is Module.function of a declaration with pragma Slot, and the implementing module imports that module.
```

A pragma Implements names something that is not a slot. The name is
looked up among the slots of the modules compiled before this one.

This module fails with H2066:

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

The correct form:

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

Message:

```text
Declaration Error
A function generic over a type cannot be a slot or implement one.

pragma Slot stands at a function declaration in an interface, and pragma Implements at a function definition that is not a slot; neither at a function generic over anything but regions.
```

A pragma Slot or pragma Implements stands where it has no meaning: Slot
at a function definition, Implements at a declaration of an interface,
either at a function generic over a type, or both at the same function.
A slot generic over regions only is allowed: a region has no run-time
form, and every instantiation is the same function. The first
line of the message names which.

This module fails with H2067:

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

The correct form:

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

Message:

```text
Type Error
`Never` cannot be the type of a parameter: it has no value.

Only the return type of a function or a method may be Never.
```

Never stands as the type of something that holds a value: a parameter,
a variable, a slot of a record or union, a constant, a conversion, a
size, a function pointer or a type argument. Never has no value, so only
the result of a function or a method can have it.

This module fails with H3109:

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

The correct form:

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

Message:

```text
Type Error
A call that does not come back stands where its value would be passed on.

Its result is Never; call it as a statement of its own.
```

A call of a function that returns Never is an argument or an operand.
The call never gives a value, so the expression around it could never be
finished. A let, an assignment, a return and a branch of an if expression
may still hold such a call.

This module fails with H3110:

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

The correct form:

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

## 12. Targets

The targets a programme is built for, `hilde build --target`, the compiler and the runtime
for WebAssembly hilde finds, and pragma Targets, with which the standard library says which
targets each module is there for.

### H1038

Message:

```text
Command Line Arguments Error
No compiler for WebAssembly was found.

hilde looks for zig, given as `HILDE_ZIG` or on the path, and then for clang on the path with `wasm-ld` and the C library of WASI, in `WASI_SYSROOT`, /usr/share/wasi-sysroot, /opt/wasi-sdk/share/wasi-sysroot or where Debian's wasi-libc puts it. Install zig, or clang with lld and wasi-libc.

A compiler for WebAssembly is needed only for --target=wasm and --target-type=wasm; zig is taken at version 0.17.0 only.
```

No compiler for wasm32-wasi is found.  hilde finds it itself: zig, given as HILDE_ZIG or on the
path, which brings the C library of WASI, else clang on the path with wasm-ld and the C library
of WASI.  HILDE_WASM_CC=zig or clang takes that one and fails when it is missing; then the
message names it.  The example takes the path away.

This module fails with H1038:

```hilde fails H1038
module body Example is
    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Compiled with:


```sh command
env HILDE_ZIG= PATH=/nonexistent hilde build Example.hiq --target=wasm --entrypoint=Example:main --output=prog.wasm
```

The correct form:

```hilde
module body Example is
    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Compiled with:


```sh command
hilde build Example.hiq --entrypoint=Example:main --output=prog
```

### H1039

Message:

```text
Command Line Arguments Error
`HILDE_WASM_CC` is `gcc`, which is not a compiler hilde knows for WebAssembly.

It is `zig` or `clang`, or not set, and then zig is taken when it is there.
```

HILDE_WASM_CC names a compiler hilde does not know for WebAssembly.  It chooses between the two
hilde looks for, zig and clang; a misspelt name is refused rather than taken for not set.

This module fails with H1039:

```hilde fails H1039
module body Example is
    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Compiled with:


```sh command
env HILDE_WASM_CC=gcc hilde build Example.hiq --target=wasm --entrypoint=Example:main --output=prog.wasm
```

The correct form:

```hilde
module body Example is
    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Compiled with:


```sh command
hilde build Example.hiq --entrypoint=Example:main --output=prog
```

### H1040

Message, from the source in `lib/Util.ml`:

```text
No runtime for WebAssembly was found to run the tests.

hilde runs a module for wasm32-wasi with wasmtime, given as `HILDE_WASMTIME` or on the path.
```

hilde test --target=wasm finds no runtime for WebAssembly.  The test programmes are command
modules, and wasmtime runs them.

It stays because a run of the tests without a runtime has to say what is missing.  It is not
triggered here because a module is built before it runs, and a gate that has a
compiler for wasm32-wasi has wasmtime as well.

Not triggered: no program was found that reaches this error.

### H1041

Message:

```text
Command Line Arguments Error
`--target=wsam` names no target hilde builds for.

The targets are `linux, openbsd, freebsd, darwin, wasm`.
```

--target names no target hilde builds for.  The names are the five of pragma Targets; for a
name a few letters away from one the message suggests that one.

This module fails with H1041:

```hilde fails H1041
module body Example is
    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Compiled with:


```sh command
hilde build Example.hiq --target=wsam --entrypoint=Example:main --output=prog
```

The correct form:

```hilde
module body Example is
    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Compiled with:


```sh command
hilde build Example.hiq --entrypoint=Example:main --output=prog
```

### H1042

Message, from the source in `lib/CliParser.ml`:

```text
`--target=<name>` asks for a binary of another system, and hilde builds a binary only for the system it runs on, <host>.

Build on a machine of `<name>`, or build a module for WebAssembly with `--target=wasm`.
```

--target names another system than the one hilde runs on.  A binary is built by the C compiler
of the machine and linked against its C library, so it is built on a machine of the system it
is for; only WebAssembly, a module that runs on every system, is built anywhere.

It stays because a binary for another system cannot be built here.  It is not triggered here
because which system is foreign depends on the machine the catalog is
compiled on, and the gates run on four.

Not triggered: no program was found that reaches this error.

### H1043

Message:

```text
Command Line Arguments Error
`--target=wasm` cannot build `--target-type=static`: there is no archive and no shared object for WebAssembly.

A programme with an entrypoint becomes a command module, `--target-type=wasm` a library module, a reactor.
```

--target=wasm is given with an archive or a shared object.  WebAssembly has two forms of a
module: a command, a programme with main, and a reactor, a library whose host calls it.

This module fails with H1043:

```hilde fails H1043
module body Example is
    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Compiled with:


```sh command
hilde build Example.hiq --target=wasm --target-type=static --output=libexample.a
```

The correct form:

```hilde
module body Example is
    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Compiled with:


```sh command
hilde build Example.hiq --target=wasm --target-type=c --entrypoint=Example:main --output=prog.c
```

### H1044

Message:

```text
Command Line Arguments Error
The output of `--target=wasm` is a module for wasm32-wasi and must end in `.wasm`, and `prog` does not.
```

The output of a programme for wasm does not end in .wasm.  A module is no binary of the system:
its name says what it is, and wasmtime and a host of JavaScript take it by that name.

This module fails with H1044:

```hilde fails H1044
module body Example is
    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Compiled with:


```sh command
hilde build Example.hiq --target=wasm --entrypoint=Example:main --output=prog
```

The correct form:

```hilde
module body Example is
    function main(): ExitCode is
        return ExitSuccess();
    end;
end module body.
```

Compiled with:


```sh command
hilde build Example.hiq --target=wasm --target-type=c --entrypoint=Example:main --output=prog.c
```

### H2068

Message:

```text
Declaration Error
Invalid `pragma Targets`: plan9 is no target.

It takes `Names`, the targets separated by one space each, out of `linux, openbsd, freebsd, darwin, wasm`, and after it, where another module does the work on the other targets, `Instead`: `pragma Targets(Names => "linux openbsd freebsd darwin", Instead => "Standard.Regex");`
```

A pragma Targets names no target, one twice, one that does not exist, or an Instead that is no
module.  Instead names a module by its full name, and only where a target is left out.

This module fails with H2068:

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

Beside it, `Thing.hih`:


```hilde file Thing.hih
pragma Targets(Names => "linux plan9");
module Standard.Thing is
    function size(): Index;
end module.
```

Beside it, `Thing.hiq`:


```hilde file Thing.hiq
module body Standard.Thing is
    function size(): Index is
        return 1;
    end;
end module body.
```

The correct form:

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

Beside it, `Thing.hih`:


```hilde file Thing.hih
pragma Targets(Names => "linux openbsd freebsd darwin wasm");
module Standard.Thing is
    function size(): Index;
end module.
```

Beside it, `Thing.hiq`:


```hilde file Thing.hiq
module body Standard.Thing is
    function size(): Index is
        return 1;
    end;
end module body.
```

### H2069

Message:

```text
Declaration Error
`pragma Unsafe_Module` cannot stand before a module interface.

Only `pragma Targets` stands there, once.
```

Another pragma than one pragma Targets stands before a module interface.  What a module binds
and whether it is unsafe stands before its body.

This module fails with H2069:

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

Beside it, `Thing.hih`:


```hilde file Thing.hih
pragma Unsafe_Module;
pragma Targets(Names => "linux openbsd freebsd darwin wasm");
module Standard.Thing is
    function size(): Index;
end module.
```

Beside it, `Thing.hiq`:


```hilde file Thing.hiq
module body Standard.Thing is
    function size(): Index is
        return 1;
    end;
end module body.
```

The correct form:

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

Beside it, `Thing.hih`:


```hilde file Thing.hih
pragma Targets(Names => "linux openbsd freebsd darwin wasm");
module Standard.Thing is
    function size(): Index;
end module.
```

Beside it, `Thing.hiq`:


```hilde file Thing.hiq
module body Standard.Thing is
    function size(): Index is
        return 1;
    end;
end module body.
```

### H2070

Message:

```text
Declaration Error
`Thing` names its targets with `pragma Targets`, and only a module of the standard library does.

A programme is there for the targets of the modules it imports: what differs between the targets is in the standard library, and a programme holds no code for one target only.
```

A module outside the standard library names its targets.  A programme does not choose the
targets it is built for: it is there for those of the modules it imports, and the compiler holds
it to them.  The standard library is a module whose name begins with Standard. or Bindings.

This module fails with H2070:

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

Beside it, `Thing.hih`:


```hilde file Thing.hih
pragma Targets(Names => "linux openbsd freebsd darwin wasm");
module Thing is
    function size(): Index;
end module.
```

Beside it, `Thing.hiq`:


```hilde file Thing.hiq
module body Thing is
    function size(): Index is
        return 1;
    end;
end module body.
```

The correct form:

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

Beside it, `Thing.hih`:


```hilde file Thing.hih
module Thing is
    function size(): Index;
end module.
```

Beside it, `Thing.hiq`:


```hilde file Thing.hiq
module body Thing is
    function size(): Index is
        return 1;
    end;
end module body.
```

### H2071

Message:

```text
Declaration Error
The module `Standard.Thing` of the standard library names no targets.

Its interface says before its imports which targets it is there for: `pragma Targets(Names => "linux openbsd freebsd darwin wasm");`
```

An interface of the standard library names no targets.  Every module whose name begins with
Standard. says which targets it is there for, so that a programme built for one finds out at
its imports, not in the link.

This module fails with H2071:

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

Beside it, `Thing.hih`:


```hilde file Thing.hih
module Standard.Thing is
    function size(): Index;
end module.
```

Beside it, `Thing.hiq`:


```hilde file Thing.hiq
module body Standard.Thing is
    function size(): Index is
        return 1;
    end;
end module body.
```

The correct form:

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

Beside it, `Thing.hih`:


```hilde file Thing.hih
pragma Targets(Names => "linux openbsd freebsd darwin wasm");
module Standard.Thing is
    function size(): Index;
end module.
```

Beside it, `Thing.hiq`:


```hilde file Thing.hiq
module body Standard.Thing is
    function size(): Index is
        return 1;
    end;
end module body.
```

### H2072

Message:

```text
Declaration Error
`Standard.Thing` names the target `wasm`, but imports `Standard.Other`, which is not there for it.

A module is there only for targets all its imports are there for: take `wasm` out of its pragma Targets, or make the import there for it.
```

A module names a target that one of its imports is not there for.  This holds whatever the
programme is built for, so the targets of the standard library cannot claim more than they have.

This module fails with H2072:

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

Beside it, `Thing.hih`:


```hilde file Thing.hih
pragma Targets(Names => "linux openbsd freebsd darwin wasm");
import Standard.Other (
    one
);
module Standard.Thing is
    function size(): Index;
end module.
```

Beside it, `Thing.hiq`:


```hilde file Thing.hiq
module body Standard.Thing is
    function size(): Index is
        return 1;
    end;
end module body.
```

Beside it, `Other.hih`:


```hilde file Other.hih
pragma Targets(Names => "linux openbsd freebsd darwin");
module Standard.Other is
    function one(): Index;
end module.
```

Beside it, `Other.hiq`:


```hilde file Other.hiq
module body Standard.Other is
    function one(): Index is
        return 1;
    end;
end module body.
```

The correct form:

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

Beside it, `Thing.hih`:


```hilde file Thing.hih
pragma Targets(Names => "linux openbsd freebsd darwin");
import Standard.Other (
    one
);
module Standard.Thing is
    function size(): Index;
end module.
```

Beside it, `Thing.hiq`:


```hilde file Thing.hiq
module body Standard.Thing is
    function size(): Index is
        return 1;
    end;
end module body.
```

Beside it, `Other.hih`:


```hilde file Other.hih
pragma Targets(Names => "linux openbsd freebsd darwin");
module Standard.Other is
    function one(): Index;
end module.
```

Beside it, `Other.hiq`:


```hilde file Other.hiq
module body Standard.Other is
    function one(): Index is
        return 1;
    end;
end module body.
```

### H2073

Message:

```text
Declaration Error
`Standard.Thing` is not there for the target `wasm`, and `Example` imports it.

It is there for linux, openbsd, freebsd, darwin. Take `Standard.Other` instead.

Suggested fix: `Standard.Other`
```

A programme built for a target imports a module that is not there for it.  The message names
the targets the module is there for and, where its pragma Targets names one, the module to take
instead; --error-format=json and hilde-json carry that module as a suggestion.

This module fails with H2073:

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

Beside it, `Thing.hih`:


```hilde file Thing.hih
pragma Targets(Names => "linux openbsd freebsd darwin", Instead => "Standard.Other");
module Standard.Thing is
    function size(): Index;
end module.
```

Beside it, `Thing.hiq`:


```hilde file Thing.hiq
module body Standard.Thing is
    function size(): Index is
        return 1;
    end;
end module body.
```

Compiled with:


```sh command
hilde build Thing.hih,Thing.hiq Example.hiq --target=wasm --target-type=c --entrypoint=Example:main --output=prog.c
```

The correct form:

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

Beside it, `Thing.hih`:


```hilde file Thing.hih
pragma Targets(Names => "linux openbsd freebsd darwin wasm");
module Standard.Thing is
    function size(): Index;
end module.
```

Beside it, `Thing.hiq`:


```hilde file Thing.hiq
module body Standard.Thing is
    function size(): Index is
        return 1;
    end;
end module body.
```

Compiled with:


```sh command
hilde build Thing.hih,Thing.hiq Example.hiq --target=wasm --target-type=c --entrypoint=Example:main --output=prog.c
```

## 13. Packages

The package commands, which hilde-pkg carries out beside the compiler: get, update, verify,
export, new, install, doc and api-diff.  docs/package-manager.en.md describes them.

### H1045

Message, from the source in `lib/CliParser.ml`:

```text
The package commands are carried out by `path`, which is not there.
Build it beside the compiler with `make hilde-pkg`, or install both with `make install`.
```

A package command was given, and hilde-pkg is not beside the compiler.

It stays because no example brings it about, since the compiler of the gates has hilde-pkg beside it; scripts/check-pkg.sh runs the package commands.

### H1046

Message, from the source in `lib/CliParser.ml`:

```text
`path` could not be started: why.
Check that it may be run, or build it again with `make hilde-pkg`.
```

hilde-pkg is beside the compiler and could not be started.

It stays because no example brings it about, since the compiler of the gates has hilde-pkg beside it; scripts/check-pkg.sh runs the package commands.

### H1501

Message, from the source in `pkg/src/Export.hiq`:

```text
no hilde.toml in .
```

The command needs a package, and there is no hilde.toml in the directory.

It stays because it is a message of hilde-pkg, which the examples of this catalog, compiled by the compiler, do not run; scripts/check-pkg.sh brings it about in both gates.

### H1502

Message, from the source in `pkg/src/Manifest.hiq`:

```text
hilde.toml is not TOML: what, at line L, column C
```

hilde.toml is not TOML; the message names the line and the column.

It stays because it is a message of hilde-pkg, which the examples of this catalog, compiled by the compiler, do not run; scripts/check-pkg.sh brings it about in both gates.

### H1503

Message, from the source in `pkg/src/Manifest.hiq`:

```text
hilde.toml has the key k in table, which a manifest does not have
```

hilde.toml has a key or a table that a manifest does not have, such as a misspelt one.

It stays because it is a message of hilde-pkg, which the examples of this catalog, compiled by the compiler, do not run; scripts/check-pkg.sh brings it about in both gates.

### H1504

Message, from the source in `pkg/src/Manifest.hiq`:

```text
package.name is missing in hilde.toml
```

A key hilde.toml must have is missing: the name or the version of the package, or the git URL or the version of a requirement.

It stays because it is a message of hilde-pkg, which the examples of this catalog, compiled by the compiler, do not run; scripts/check-pkg.sh brings it about in both gates.

### H1505

Message, from the source in `pkg/src/Get.hiq`:

```text
hilde get takes Prefix@vX.Y.Z, not text
```

A value has the wrong form: a name that is no module prefix, a version that is not vX.Y.Z, a capability that is none, or an argument of the wrong form.

It stays because it is a message of hilde-pkg, which the examples of this catalog, compiled by the compiler, do not run; scripts/check-pkg.sh brings it about in both gates.

### H1506

Message, from the source in `pkg/src/Get.hiq`:

```text
the package at URL is named N, and P requires it as Q
```

One prefix comes from two git URLs, or a package is named otherwise than the prefix it is required by.

It stays because it is a message of hilde-pkg, which the examples of this catalog, compiled by the compiler, do not run; scripts/check-pkg.sh brings it about in both gates.

### H1507

Message, from the source in `pkg/src/Export.hiq`:

```text
git is not on PATH, and hilde export reads the tags with git
```

git is not on the PATH, and the command needs it.

It stays because it is a message of hilde-pkg, which the examples of this catalog, compiled by the compiler, do not run; scripts/check-pkg.sh brings it about in both gates.

### H1508

Message, from the source in `pkg/src/Git.hiq`:

```text
git cannot list the tags of URL: git said: line
```

git failed: a wrong URL, a repository that may not be read, or a programme that could not be started.

It stays because it is a message of hilde-pkg, which the examples of this catalog, compiled by the compiler, do not run; scripts/check-pkg.sh brings it about in both gates.

### H1509

Message, from the source in `pkg/src/Git.hiq`:

```text
the repository URL has no tag vX.Y.Z
```

The repository has no tag of the version asked for; the suggestion names the tags nearest to it.

It stays because it is a message of hilde-pkg, which the examples of this catalog, compiled by the compiler, do not run; scripts/check-pkg.sh brings it about in both gates.

### H1510

Message, from the source in `pkg/src/Tree.hiq`:

```text
a package holds only files and directories, not a link or a special file: path
```

The tree of a package holds a symbolic link or a special file.

It stays because it is a message of hilde-pkg, which the examples of this catalog, compiled by the compiler, do not run; scripts/check-pkg.sh brings it about in both gates.

### H1511

Message, from the source in `pkg/src/Get.hiq`:

```text
the release of P has no signature, and policy.require-signatures is true
```

A release has no signature, and the policy of the package asks for one.

It stays because it is a message of hilde-pkg, which the examples of this catalog, compiled by the compiler, do not run; scripts/check-pkg.sh brings it about in both gates.

### H1512

Message, from the source in `pkg/src/Get.hiq`:

```text
the signature of P does not hold for its tree and its key
```

A signature does not hold, the key is not the one taken on first use, or a release is unsigned after a signed one.

It stays because it is a message of hilde-pkg, which the examples of this catalog, compiled by the compiler, do not run; scripts/check-pkg.sh brings it about in both gates.

### H1513

Message, from the source in `pkg/src/Export.hiq`:

```text
path is not a secret key of signify without a passphrase
```

The secret key cannot be read, is no signify key, or has a passphrase.

It stays because it is a message of hilde-pkg, which the examples of this catalog, compiled by the compiler, do not run; scripts/check-pkg.sh brings it about in both gates.

### H1514

Message, from the source in `pkg/src/Sum.hiq`:

```text
hilde.sum, line N: what
```

hilde.sum is missing, has a bad line, or lacks the line of a requirement.

It stays because it is a message of hilde-pkg, which the examples of this catalog, compiled by the compiler, do not run; scripts/check-pkg.sh brings it about in both gates.

### H1515

Message, from the source in `pkg/src/Verify.hiq`:

```text
vendor/ has no tree P, which hilde.sum names
```

A tree in vendor/ is missing, changed, or not named in hilde.sum.

It stays because it is a message of hilde-pkg, which the examples of this catalog, compiled by the compiler, do not run; scripts/check-pkg.sh brings it about in both gates.

### H1516

Message, from the source in `pkg/src/Get.hiq`:

```text
P is required as vA by X and as vB by Y
```

Two majors of one package are required; a new major takes a new prefix.

It stays because it is a message of hilde-pkg, which the examples of this catalog, compiled by the compiler, do not run; scripts/check-pkg.sh brings it about in both gates.

### H1517

Message, from the source in `pkg/src/Tree.hiq`:

```text
the tree is deeper than 64 directories at: path
```

The tree of a package is deeper than 64 directories.

It stays because it is a message of hilde-pkg, which the examples of this catalog, compiled by the compiler, do not run; scripts/check-pkg.sh brings it about in both gates.

### H1518

Message, from the source in `pkg/src/Tree.hiq`:

```text
a directory cannot be read: path
```

A directory or a file of a package cannot be read.

It stays because it is a message of hilde-pkg, which the examples of this catalog, compiled by the compiler, do not run; scripts/check-pkg.sh brings it about in both gates.

### H1519

Message, from the source in `pkg/src/Export.hiq`:

```text
llms.txt or man/man3 cannot be written in root
```

A file or a directory cannot be written.

It stays because it is a message of hilde-pkg, which the examples of this catalog, compiled by the compiler, do not run; scripts/check-pkg.sh brings it about in both gates.

### H1521

Message, from the source in `pkg/src/Main.hiq`:

```text
the directory is there already: path
```

hilde new or a key would write over something that is there.

It stays because it is a message of hilde-pkg, which the examples of this catalog, compiled by the compiler, do not run; scripts/check-pkg.sh brings it about in both gates.

### H1522

Message, from the source in `pkg/src/Main.hiq`:

```text
no module or declaration X in src, vendor/ or the standard library
```

hilde doc finds no module or declaration of the name.

It stays because it is a message of hilde-pkg, which the examples of this catalog, compiled by the compiler, do not run; scripts/check-pkg.sh brings it about in both gates.

### H1523

Message, from the source in `pkg/src/Targets.hiq`:

```text
hilde.toml names the target T, and a module the package reaches does not allow it: M
```

A target of hilde.toml is not allowed by the pragma Targets of a module the package reaches.

It stays because it is a message of hilde-pkg, which the examples of this catalog, compiled by the compiler, do not run; scripts/check-pkg.sh brings it about in both gates.

### H1530

Message, from the source in `pkg/src/Export.hiq`:

```text
the interface changed as a major release does since vA, and hilde.toml says vB
```

The version of a release is lower than its change of interface calls for, such as a break under a minor version.

It stays because it is a message of hilde-pkg, which the examples of this catalog, compiled by the compiler, do not run; scripts/check-pkg.sh brings it about in both gates.

### H1531

Message, from the source in `pkg/src/Export.hiq`:

```text
a release needs a test file for each module, and these are missing: files
```

A module of the package has no test file.

It stays because it is a message of hilde-pkg, which the examples of this catalog, compiled by the compiler, do not run; scripts/check-pkg.sh brings it about in both gates.

### H1532

Message, from the source in `pkg/src/Export.hiq`:

```text
the tests of the package do not pass: last line
```

The tests of the package do not pass, or the compiler failed on it.

It stays because it is a message of hilde-pkg, which the examples of this catalog, compiled by the compiler, do not run; scripts/check-pkg.sh brings it about in both gates.

### H1533

Message, from the source in `pkg/src/Export.hiq`:

```text
every exported function must be called in a test, and these are not: names
```

An exported function is called in no test.

It stays because it is a message of hilde-pkg, which the examples of this catalog, compiled by the compiler, do not run; scripts/check-pkg.sh brings it about in both gates.

### H1534

Message, from the source in `pkg/src/Export.hiq`:

```text
hilde.toml says vA, and the newest tag is vB
```

The version of a release is not newer than the newest tag.

It stays because it is a message of hilde-pkg, which the examples of this catalog, compiled by the compiler, do not run; scripts/check-pkg.sh brings it about in both gates.

## 14. Sperli

The run command and the cluster layer: hilde run, which hilde-launcher carries out beside the compiler, and the refusals of a Sperli job, H1601 to H1625.  docs/sperli.en.md describes them.

### H1047

Message, from the source in `lib/CliParser.ml`:

```text
The command run is carried out by `path`, which is not there.
Build it beside the compiler with `make hilde-launcher`, or install both with `make install`.
```

A run command was given, and hilde-launcher is not beside the compiler.

It stays because it is a message of hilde run, which the examples of this catalog, compiled by the compiler, do not run; the tests of standard/src/Sperli.test.hiq and test-programs/suites/100-sperli bring it about in the gates.

### H1048

Message, from the source in `lib/CliParser.ml`:

```text
`path` could not be started: why.
Check that it may be run, or build it again with `make hilde-launcher`.
```

hilde-launcher is beside the compiler and could not be started.

It stays because it is a message of hilde run, which the examples of this catalog, compiled by the compiler, do not run; the tests of standard/src/Sperli.test.hiq and test-programs/suites/100-sperli bring it about in the gates.

### H1601

Message, from the source in `standard/src/SperliError.hiq`:

```text
the peer has no certificate of the job CA
```

The peer showed no certificate, or one that the CA of the job does not vouch for, or offered a TLS version below 1.3.

It stays because it is a refusal of a Sperli job, which the examples of this catalog, compiled by the compiler, do not run; the tests of standard/src/Sperli.test.hiq and test-programs/suites/100-sperli bring it about in the gates.

### H1602

Message, from the source in `standard/src/SperliError.hiq`:

```text
the subject of the certificate is not the job and rank of the peer
```

The subject of the certificate of the peer is not the job and the rank the connection is for.

It stays because it is a refusal of a Sperli job, which the examples of this catalog, compiled by the compiler, do not run; the tests of standard/src/Sperli.test.hiq and test-programs/suites/100-sperli bring it about in the gates.

### H1603

Message, from the source in `standard/src/SperliError.hiq`:

```text
the host is refused
```

A host is listed in SPERLI_REFUSED_HOSTS, is host-a.invalid or host-b.invalid, or a name below one of them, or is on the deny list of the operator; a deny list cannot lift the rule.

It stays because it is a refusal of a Sperli job, which the examples of this catalog, compiled by the compiler, do not run; the tests of standard/src/Sperli.test.hiq and test-programs/suites/100-sperli bring it about in the gates.

### H1604

Message, from the source in `standard/src/SperliError.hiq`:

```text
the join token has expired
```

The join token of a peer has expired.

It stays because it is a refusal of a Sperli job, which the examples of this catalog, compiled by the compiler, do not run; the tests of standard/src/Sperli.test.hiq and test-programs/suites/100-sperli bring it about in the gates.

### H1605

Message, from the source in `standard/src/SperliError.hiq`:

```text
the join token is for another job
```

The join token of a peer was made for another job.

It stays because it is a refusal of a Sperli job, which the examples of this catalog, compiled by the compiler, do not run; the tests of standard/src/Sperli.test.hiq and test-programs/suites/100-sperli bring it about in the gates.

### H1606

Message, from the source in `standard/src/SperliError.hiq`:

```text
the join token is for another rank, size, incarnation or host
```

The join token of a peer was made for another rank, size, incarnation or host.

It stays because it is a refusal of a Sperli job, which the examples of this catalog, compiled by the compiler, do not run; the tests of standard/src/Sperli.test.hiq and test-programs/suites/100-sperli bring it about in the gates.

### H1607

Message, from the source in `standard/src/SperliError.hiq`:

```text
the join token is malformed or its signature does not hold
```

The join token of a peer is malformed, or its signature does not hold under the public key of the launcher.

It stays because it is a refusal of a Sperli job, which the examples of this catalog, compiled by the compiler, do not run; the tests of standard/src/Sperli.test.hiq and test-programs/suites/100-sperli bring it about in the gates.

### H1608

Message, from the source in `standard/src/SperliError.hiq`:

```text
the frame is larger than the limit
```

A frame announces more payload than the limit of 16 MiB; it is refused before a payload byte is read.

It stays because it is a refusal of a Sperli job, which the examples of this catalog, compiled by the compiler, do not run; the tests of standard/src/Sperli.test.hiq and test-programs/suites/100-sperli bring it about in the gates.

### H1609

Message, from the source in `standard/src/SperliError.hiq`:

```text
the frame is from an older incarnation
```

A frame belongs to an older incarnation of the job; its payload is read and dropped, and the wait goes on.

It stays because it is a refusal of a Sperli job, which the examples of this catalog, compiled by the compiler, do not run; the tests of standard/src/Sperli.test.hiq and test-programs/suites/100-sperli bring it about in the gates.

### H1610

Message, from the source in `standard/src/SperliError.hiq`:

```text
the header of the frame breaks the protocol
```

The header of a frame breaks a rule of the protocol: an unknown type, a flag, service or membership epoch that is not 0, another job, other ranks, or a newer incarnation.

It stays because it is a refusal of a Sperli job, which the examples of this catalog, compiled by the compiler, do not run; the tests of standard/src/Sperli.test.hiq and test-programs/suites/100-sperli bring it about in the gates.

### H1611

Message, from the source in `standard/src/SperliError.hiq`:

```text
the peer was lost
```

A peer was lost: the connection closed, or no frame came within the silence limit.

It stays because it is a refusal of a Sperli job, which the examples of this catalog, compiled by the compiler, do not run; the tests of standard/src/Sperli.test.hiq and test-programs/suites/100-sperli bring it about in the gates.

### H1612

Message, from the source in `standard/src/SperliError.hiq`:

```text
the peer aborted the job
```

A peer sent an abort frame.

It stays because it is a refusal of a Sperli job, which the examples of this catalog, compiled by the compiler, do not run; the tests of standard/src/Sperli.test.hiq and test-programs/suites/100-sperli bring it about in the gates.

### H1613

Message, from the source in `standard/src/SperliError.hiq`:

```text
the hello of the peer is missing, repeated or not acceptable
```

The hello of a peer is missing, comes twice, has another version or offers no point-to-point service.

It stays because it is a refusal of a Sperli job, which the examples of this catalog, compiled by the compiler, do not run; the tests of standard/src/Sperli.test.hiq and test-programs/suites/100-sperli bring it about in the gates.

### H1614

Message, from the source in `standard/src/SperliError.hiq`:

```text
the command line or the host list is wrong
```

The command line of hilde run or its host list is wrong: a missing or unknown option, a number out of range, no host, or a line that is no host and port.

It stays because it is a refusal of a Sperli job, which the examples of this catalog, compiled by the compiler, do not run; the tests of standard/src/Sperli.test.hiq and test-programs/suites/100-sperli bring it about in the gates.

### H1615

Message, from the source in `standard/src/SperliError.hiq`:

```text
a rank could not be started
```

A rank could not be started, or the keys, certificates or ports of the job could not be made.

It stays because it is a refusal of a Sperli job, which the examples of this catalog, compiled by the compiler, do not run; the tests of standard/src/Sperli.test.hiq and test-programs/suites/100-sperli bring it about in the gates.

### H1616

Message, from the source in `standard/src/SperliError.hiq`:

```text
the job description is malformed
```

The job description a rank was given on its standard input is malformed.

It stays because it is a refusal of a Sperli job, which the examples of this catalog, compiled by the compiler, do not run; the tests of standard/src/Sperli.test.hiq and test-programs/suites/100-sperli bring it about in the gates.

### H1617

Message, from the source in `standard/src/SperliError.hiq`:

```text
the collective frame does not match the call
```

A collective frame does not match the call it answers: another operation, type, reduce operation, phase, root or sequence number, or contributions of gather in different length.

It stays because it is a refusal of a Sperli job, which the examples of this catalog, compiled by the compiler, do not run; the tests of standard/src/Sperli.test.hiq and test-programs/suites/100-sperli bring it about in the gates.

### H1618

Message, from the source in `standard/src/SperliError.hiq`:

```text
the arguments of the collective call are wrong
```

The arguments of a collective call are wrong: a root outside the job, an element type and reduce operation that do not go together, data that is no whole number of elements or blocks, or contributions of reduce in different length.

It stays because it is a refusal of a Sperli job, which the examples of this catalog, compiled by the compiler, do not run; the tests of standard/src/Sperli.test.hiq and test-programs/suites/100-sperli bring it about in the gates.

### H1619

Message, from the source in `standard/src/SperliError.hiq`:

```text
the checkpoint file is not the one expected
```

A checkpoint file has another magic or version, or a job, epoch, rank, size or length that is not the one expected, or it is too short.

It stays because it is a refusal of a Sperli job, which the examples of this catalog, compiled by the compiler, do not run; the tests of standard/src/SperliCkpt.test.hiq and test-programs/suites/100-sperli bring it about in the gates.

### H1620

Message, from the source in `standard/src/SperliError.hiq`:

```text
the SHA-256 of the checkpoint file does not match
```

The SHA-256 of the state in a checkpoint file is not the one in its header, or not the one the COMMIT file lists for the rank.

It stays because it is a refusal of a Sperli job, which the examples of this catalog, compiled by the compiler, do not run; the tests of standard/src/SperliCkpt.test.hiq and test-programs/suites/100-sperli bring it about in the gates.

### H1621

Message, from the source in `standard/src/SperliError.hiq`:

```text
the COMMIT file is malformed or its signature does not hold
```

A COMMIT file is malformed, is for another job or epoch, or its CompositeSig signature does not hold for the public key of the job. An epoch without a valid COMMIT file does not count.

It stays because it is a refusal of a Sperli job, which the examples of this catalog, compiled by the compiler, do not run; the tests of standard/src/SperliCkpt.test.hiq and test-programs/suites/100-sperli bring it about in the gates.

### H1622

Message, from the source in `standard/src/SperliError.hiq`:

```text
no epoch can be resumed
```

A resume found no epoch with a valid COMMIT file and all rank files, or the ranks did not agree on the epoch to resume.

It stays because it is a refusal of a Sperli job, which the examples of this catalog, compiled by the compiler, do not run; the tests of standard/src/SperliCkpt.test.hiq and test-programs/suites/100-sperli bring it about in the gates.

### H1623

Message, from the source in `standard/src/SperliError.hiq`:

```text
the job has another size than the checkpoint
```

A resume was asked for a job of another number of ranks than the checkpoint was written with. Version 1 of the format requires the same size.

It stays because it is a refusal of a Sperli job, which the examples of this catalog, compiled by the compiler, do not run; the tests of standard/src/SperliCkpt.test.hiq and test-programs/suites/100-sperli bring it about in the gates.

### H1624

Message, from the source in `standard/src/SperliError.hiq`:

```text
a send or receive is still open
```

A checkpoint was asked for while a send or receive was still open on this rank.

It stays because it is a refusal of a Sperli job, which the examples of this catalog, compiled by the compiler, do not run; the tests of standard/src/SperliCkpt.test.hiq and test-programs/suites/100-sperli bring it about in the gates.

### H1625

Message, from the source in `standard/src/SperliError.hiq`:

```text
the checkpoint could not be written or sent
```

A checkpoint could not be written or sent, or no checkpoint directory was named.

It stays because it is a refusal of a Sperli job, which the examples of this catalog, compiled by the compiler, do not run; the tests of standard/src/SperliCkpt.test.hiq and test-programs/suites/100-sperli bring it about in the gates.
