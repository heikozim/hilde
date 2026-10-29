/* A control of scripts/check-ubsan-trap.sh: a signed overflow, which
   UBSan in trap mode must stop with a trap.  It prints nothing; the signal
   is the report.  The variable is volatile so that the addition is done at
   run time. */
#include <limits.h>

int main(void)
{
	volatile int x = INT_MAX;

	x = x + 1;
	return x == INT_MIN ? 0 : 1;
}
