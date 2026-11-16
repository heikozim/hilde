/*
    Part of Hilde, under the Apache License v2.0 with LLVM Exceptions.
    See LICENSE file for details.

    Copyright (c) 2026 Heiko Zimmermann <code@heiko-zimmermann.com>
    SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
*/

/*
 * Every part of the runtime prelude in one translation unit, in the order
 * the compiler writes them: for the fuzz targets and the controls that
 * compile the whole prelude.  A programme carries internal.h and only the
 * parts it needs.  The static analyser does not read this file, because it
 * follows the paths only of the functions of the file it is given.
 */

#include "internal.h"
#include "core.c"
#include "library.c"
#include "crypto.c"
#include "resolve.c"
#include "sandbox.c"
#include "path.c"
#include "file.c"
#include "system.c"
#include "signal.c"
#include "socket.c"
#include "process.c"
#include "task.c"
#include "task-none.c"
#include "shared.c"
#include "poller.c"
