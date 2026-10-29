// Part of Hilde, under the Apache License v2.0 with LLVM Exceptions.
// See LICENSE file for details.
//
// SPDX-FileCopyrightText: 2026 Heiko Zimmermann
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// The answer of the worker: a POST carries text, at most 65536 bytes, and
// the answer is JSON with its words and the text in capitals, as the
// library TextStats, built by hilde for wasm32-wasi, computes them.  Every
// other request is refused.
import { textStats } from "../wasm-browser/hilde-wasm.js";

const MOST = 65536;

export async function answer(hilde, request) {
  if (request.method !== "POST") {
    return new Response("POST the text\n", { status: 405, headers: { allow: "POST" } });
  }
  const text = await request.text();
  if (new TextEncoder().encode(text).length > MOST) {
    return new Response("at most " + MOST + " bytes\n", { status: 413 });
  }
  const r = textStats(hilde, text);
  return new Response(JSON.stringify({ words: r.words, upper: r.upper }) + "\n", {
    headers: { "content-type": "application/json" },
  });
}
