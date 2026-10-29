The largest value a 64-bit size_t holds, written as a literal.  It is the
other end of the same bound, and it also pins the assumption the table
makes -- if size_t is ever not 64 bits on a supported target, this test is
where that shows up.
