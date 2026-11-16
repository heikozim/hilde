Standard.Pcre: what PCRE2 finds through the binding (001), the match limit as a Left (002), and the table of patterns whose results differ between Standard.Regex and Standard.Pcre, each row through both engines (003).

004: groupStart and groupEnd for a group the pattern does not have, the largest Index among them, answer None.

005: Standard.PcreJit, the JIT of PCRE2 under W^X: every pattern through the interpreter and through machine code with the same hits, the match limit under both, a pattern the JIT refuses and its fall-back, the stack of machine code against the depth of the interpreter, and the control of the comparison.
