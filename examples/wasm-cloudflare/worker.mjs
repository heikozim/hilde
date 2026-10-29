// Part of Hilde, under the Apache License v2.0 with LLVM Exceptions.
// See LICENSE file for details.
//
// SPDX-FileCopyrightText: 2026 Heiko Zimmermann
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// The worker of Cloudflare: wrangler bundles text-stats.wasm as a
// WebAssembly.Module, which is instantiated once per isolate and answers
// every request through handler.mjs.
import wasm from "./text-stats.wasm";
import { loadHilde } from "../wasm-browser/hilde-wasm.js";
import { answer } from "./handler.mjs";

let hilde = null;

export default {
  async fetch(request) {
    if (hilde === null) {
      hilde = await loadHilde(wasm);
    }
    return answer(hilde, request);
  },
};
