-- Part of Hilde, under the Apache License v2.0 with LLVM Exceptions.
-- See LICENSE file for details.
--
-- Copyright (c) 2026 Heiko Zimmermann <code@heiko-zimmermann.com>
-- SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

-- The notes of the example.  The compiler reads this file and checks every
-- query of the programme against the table it makes.
CREATE TABLE notes (
    id INTEGER PRIMARY KEY,
    content TEXT NOT NULL
) STRICT;
