/* A control of scripts/check-ubsan-trap.sh: a call through a pointer of
   another function type, which the function check of UBSan in trap mode
   must stop with a trap.  On OpenBSD the check reads the bytes in front of
   the called function, which only a programme linked with
   --no-execute-only may do; without it the read ends in a segmentation
   fault, which the script counts as a failure.  The pointer is volatile so
   that the call stays indirect. */
static int twice(long x)
{
	return (int)(2 * x);
}

int main(void)
{
	int (*volatile call)(int) = (int (*)(int))(void (*)(void))twice;

	return call(1) == 2 ? 0 : 1;
}
