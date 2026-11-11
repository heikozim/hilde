#!/bin/sh
# Build and run the controls of scripts/signal/controls.c.
#
#     sh scripts/signal/check-controls.sh <scratch-dir>
#
# Run from the root of the tree.  <scratch-dir> must exist; the binaries
# of the controls are written there as signal-control-<n>.  Control 1 is
# built with -DHILDE_LIBRARY, control 4 only on Linux.  Each must build
# without a warning and end with 0.
#
# Exit 0 every control passed; 1 to 4 the number that failed; 9 nothing
# ran.  POSIX sh, no bashisms.
set -u

[ $# -eq 1 ] || { echo "usage: sh scripts/signal/check-controls.sh <scratch-dir>" >&2; exit 9; }
scratch=$1
src=scripts/signal/controls.c
[ -d "$scratch" ] || { echo "signal-controls: NOT RUN -- $scratch is not a directory"; exit 9; }
[ -r "$src" ] || { echo "signal-controls: NOT RUN -- $src is missing; run it from the root of the tree"; exit 9; }
command -v cc > /dev/null 2>&1 || { echo "signal-controls: NOT RUN -- no cc"; exit 9; }

controls="1 2 3"
[ "$(uname -s)" = Linux ] && controls="$controls 4"
failed=0
for n in $controls; do
	flags=""
	[ "$n" = 1 ] && flags="-DHILDE_LIBRARY"
	bin="$scratch/signal-control-$n"
	log="$scratch/signal-control-$n.log"
	if ! cc -std=c17 -Wall -Wextra -Wpedantic -Werror $flags -DSIGNAL_CONTROL="$n" "$src" -lpthread -o "$bin" > "$log" 2>&1; then
		echo "signal-controls: control $n FAILED to build, see $log"
		failed=$((failed + 1))
		continue
	fi
	"$bin"
	rc=$?
	if [ "$rc" -eq 0 ]; then
		echo "signal-controls: control $n passed"
	else
		echo "signal-controls: control $n FAILED with exit $rc"
		failed=$((failed + 1))
	fi
done
echo "signal-controls: failed=$failed"
exit "$failed"
