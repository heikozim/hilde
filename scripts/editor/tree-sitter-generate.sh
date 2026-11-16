#!/usr/bin/env bash
#
# Part of Hilde, under the Apache License v2.0 with LLVM Exceptions.
# See LICENSE file for details.
#
# Copyright (c) 2026 Heiko Zimmermann <code@heiko-zimmermann.com>
# SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
#

# Makes src/parser.c, src/grammar.json and src/node-types.json of
# editor/tree-sitter-hilde from grammar.js, and parses every module of the
# standard library and the examples with the new parser.  It runs in a
# container that is made fresh for each run: the newest node image of the
# release line named below is pulled first, and the newest tree-sitter-cli
# is installed into it, so a fix of either is in every run.  Nothing of it
# is kept on the host but the files written into the tree.
#
#     bash scripts/editor/tree-sitter-generate.sh <tree>
#
# Exit 0 when the parser was made and every file parses cleanly, 1 when a
# file does not, 9 when nothing ran.
[ "${BASH_VERSINFO[0]:-0}" -ge 4 ] || { echo "ABORT: bash ${BASH_VERSION} too old" >&2; exit 9; }
set -u
tree=${1:?tree}
[ -r "$tree/editor/tree-sitter-hilde/grammar.js" ] || { echo "ABORT: $tree has no editor/tree-sitter-hilde -- nothing ran" >&2; exit 9; }
command -v docker > /dev/null 2>&1 || { echo "ABORT: docker not on PATH -- nothing ran" >&2; exit 9; }
# Under rootless Docker the root of the container is the user on the host,
# so the files belong to that user; under the Docker of the system the
# container runs as that user.
user=(--user "$(id -u):$(id -g)")
if [ -S "/run/user/$(id -u)/docker.sock" ]; then
	export DOCKER_HOST="unix:///run/user/$(id -u)/docker.sock"
	user=()
fi
image=node:22-trixie
docker pull --quiet "$image" > /dev/null || { echo "ABORT: docker pull $image failed -- nothing ran" >&2; exit 9; }
echo "image=$image $(docker image inspect "$image" --format '{{.Id}}')"
# The tree is mounted to write the three generated files.
docker run --rm -i "${user[@]}" -e HOME=/tmp -e npm_config_cache=/tmp/npm \
	-v "$tree:/src" -w /src/editor/tree-sitter-hilde "$image" bash -c '
set -u
npm install --silent --global --prefix /tmp/ts tree-sitter-cli@latest > /tmp/npm.log 2>&1 || { tail -5 /tmp/npm.log; exit 9; }
export PATH=/tmp/ts/bin:$PATH
echo "tree-sitter=$(tree-sitter --version)"
tree-sitter generate --abi 14 || exit 1
printf "\n" >> src/grammar.json
printf "\n" >> src/node-types.json
./parse-all.sh
' < /dev/null
