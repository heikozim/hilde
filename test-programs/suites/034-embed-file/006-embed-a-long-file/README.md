A file of 4095 bytes and one of 4094, every byte from 0 to 255 in turn.
C17 asks a compiler to take only 4095 characters in a string literal, so
text of 4095 bytes or more is emitted as an array of bytes and shorter
text as a literal; both must give the same bytes back.
