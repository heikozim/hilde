The ? operator on Either.  Left is the failure and Right the success --
the type says nothing about which, so the language decides it and this
test holds the decision.  3 and 4 give 7; 3 and -9 give the -9 that the
SECOND ? handed back.
