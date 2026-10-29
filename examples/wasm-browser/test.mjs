// Part of Hilde, under the Apache License v2.0 with LLVM Exceptions.
// See LICENSE file for details.
//
// SPDX-FileCopyrightText: 2026 Heiko Zimmermann
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// The page's loader and its call of TextStats, run in node on the module
// built from TextStats.hiq:
//
//     node test.mjs text-stats.wasm
import { readFileSync } from "node:fs";
import { loadHilde, textStats } from "./hilde-wasm.js";

const hilde = await loadHilde(readFileSync(process.argv[2]));
for (const text of ["Hilde runs in the browser.", "", "  two   words  "]) {
  const r = textStats(hilde, text);
  console.log(r.words + " " + r.turned + " [" + r.upper + "]");
}
hilde.end();
