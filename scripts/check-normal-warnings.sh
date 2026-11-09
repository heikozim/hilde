#!/bin/sh
# Judge the yardsticks in the log of one scripts/count-warnings.sh run.
# Normal, optimised and strict are zero on every column the gates measure,
# and a count above zero turns a gate red.
#
#     sh scripts/check-normal-warnings.sh <log> <prefix>
#
# <prefix> is what the lines of that log start with, `count-warnings' for a
# run of its own and `count-warnings' again for the second-compiler log,
# which is relabelled only when it is printed.
#
# Exit 0   the run finished (`DONE'), the three totals are 0, the strict
#          control saw its warning and the other controls gave their want.
# Exit 1   a total is a number above 0, the strict control did not see
#          exactly its one warning under -Wpedantic and none without it, or
#          a control of the counting form missed its want.
# Exit 9   the log carries no finished count -- "did not run", which is a
#          third answer and not a pass (PIT-054).
#
# A total of 0 says something only if the flags can see a warning at all,
# so the controls count-warnings.sh runs are judged with it: the positive
# file gives one warning, the clean file none, and the switch at -O1 what
# the compiler gives it, which the count states as its want.
# POSIX sh, no bashisms (SH-002): the OpenBSD guest runs it as ksh.
set -u

[ $# -eq 2 ] || { echo "usage: sh scripts/check-normal-warnings.sh <log> <prefix>" >&2; exit 9; }
log=$1
prefix=$2
[ -r "$log" ] || { echo "$prefix: normal-check NOT RUN -- $log is not readable"; exit 9; }

if ! grep -q "^$prefix: DONE\$" "$log"; then
	echo "$prefix: normal-check NOT RUN -- the count did not finish"
	exit 9
fi

value=$(grep "^$prefix: normal-total=" "$log" | tail -1 | sed "s/^$prefix: normal-total=//")
case "$value" in
	'')
		echo "$prefix: normal-check NOT RUN -- no normal-total line"
		exit 9
		;;
	*[!0-9]*)
		echo "$prefix: normal-check NOT RUN -- normal-total is [$value], not a number"
		exit 9
		;;
esac
# The optimised yardstick, the normal flags with -O1, is zero too.
opt=$(grep "^$prefix: optimised-total=" "$log" | tail -1 | sed "s/^$prefix: optimised-total=//")
case "$opt" in
	''|*[!0-9]*)
		echo "$prefix: normal-check NOT RUN -- optimised-total is [$opt], not a number"
		exit 9
		;;
esac
# The strict yardstick, the normal flags with -Wpedantic, is zero too.
strict=$(grep "^$prefix: strict-total=" "$log" | tail -1 | sed "s/^$prefix: strict-total=//")
case "$strict" in
	''|*[!0-9]*)
		echo "$prefix: normal-check NOT RUN -- strict-total is [$strict], not a number"
		exit 9
		;;
esac
ctl=$(grep "^$prefix: strict-control " "$log" | tail -1)
case "$ctl" in
	'')
		echo "$prefix: normal-check NOT RUN -- no strict-control line"
		exit 9
		;;
esac
ctl_ok=no
case "$ctl" in
	*" strict=1 (want 1) normal=0 (want 0)") ctl_ok=yes ;;
esac
cls=$(grep "^$prefix: controls " "$log" | tail -1)
case "$cls" in
	'')
		echo "$prefix: normal-check NOT RUN -- no controls line"
		exit 9
		;;
esac
cls_ok=no
case "$cls" in
	*" positive=1 (want 1) negative=0 (want 0) optimised=1 (want 1)") cls_ok=yes ;;
	*" positive=1 (want 1) negative=0 (want 0) optimised=0 (want 0)") cls_ok=yes ;;
esac
once=$(grep "^$prefix: untagged-control " "$log" | tail -1)
case "$once" in
	'')
		echo "$prefix: normal-check NOT RUN -- no untagged-control line"
		exit 9
		;;
esac
once_ok=no
case "$once" in
	*" said=1 (want 1)") once_ok=yes ;;
esac
if [ "$value" -eq 0 ] && [ "$opt" -eq 0 ] && [ "$strict" -eq 0 ] && [ "$ctl_ok" = yes ] && [ "$cls_ok" = yes ] &&
	[ "$once_ok" = yes ]; then
	echo "$prefix: normal-check want=0 got=0 ok, optimised want=0 got=0 ok, strict want=0 got=0 ok, strict control ok, controls ok, untagged control ok"
	exit 0
fi
echo "$prefix: normal-check want=0 got=$value, optimised want=0 got=$opt, strict want=0 got=$strict, strict control $ctl_ok, controls $cls_ok, untagged control $once_ok FAILED"
exit 1
