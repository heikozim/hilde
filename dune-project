(lang dune 2.1)
; Modified by Heiko Zimmermann for Hilde, 2026.
(using menhir 2.0)

(name hilde)
(version 1.0.0)
(maintainers "Heiko Zimmermann <code@heiko-zimmermann.com>")
(bug_reports "code@heiko-zimmermann.com")

(package
 (name hilde)
 (synopsis "The bootstrapping compiler for Hilde")
 (description "The bootstrapping compiler for Hilde.")
 (depends
  (ppxlib (>= 0.25.1))
  (ppx_deriving (= 6.2.0))
  (ppx_sexp_conv (= v0.17.1))
  (sexplib (= v0.17.0))
  (ounit2 (= 2.2.7))
  (menhir (= 20260209))
  (zarith (= 1.12))
  (yojson (= 2.1.0))))

(generate_opam_files)
