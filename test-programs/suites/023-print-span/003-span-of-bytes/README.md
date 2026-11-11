print on a Span of Nat8 writes its bytes as they are, all at once: a zero
byte, the byte 127 and a line feed included, and in the order of the prints
around it.  An empty span writes nothing.
