// Part of Hilde, under the Apache License v2.0 with LLVM Exceptions.
// See LICENSE file for details.
//
// SPDX-FileCopyrightText: 2026 Heiko Zimmermann
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// The answer of the worker, run in node on the module built from
// ../wasm-browser/TextStats.hiq, with the Request and Response node has:
//
//     node test.mjs text-stats.wasm
import { readFileSync } from "node:fs";
import { loadHilde } from "../wasm-browser/hilde-wasm.js";
import { answer } from "./handler.mjs";

const hilde = await loadHilde(readFileSync(process.argv[2]));
const requests = [
  new Request("https://example.test/", { method: "POST", body: "Hilde at the edge" }),
  new Request("https://example.test/", { method: "GET" }),
  new Request("https://example.test/", { method: "POST", body: "x".repeat(65537) }),
];
for (const request of requests) {
  const response = await answer(hilde, request);
  console.log(response.status + " " + (await response.text()).trimEnd());
}
hilde.end();
