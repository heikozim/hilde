// Part of Hilde, under the Apache License v2.0 with LLVM Exceptions.
// See LICENSE file for details.
//
// SPDX-FileCopyrightText: 2026 Heiko Zimmermann
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// Loads a library that hilde built for wasm32-wasi (--target-type=wasm) in
// a browser, in a worker of Cloudflare or in node.  The few calls of WASI
// such a library makes are answered here: what it writes to its standard
// output and error goes to the console, the clocks and random bytes come
// from the host; every other call answers that WASI has no such thing
// (ENOSYS), as a library that only computes never needs one.

const ENOSYS = 52;

function wasiImports(view, log) {
  const known = {
    fd_write(fd, iovs, count, written) {
      const memory = view();
      const words = new Uint32Array(memory.buffer);
      let total = 0;
      let text = "";
      for (let i = 0; i < count; i++) {
        const base = words[(iovs >> 2) + 2 * i];
        const length = words[(iovs >> 2) + 2 * i + 1];
        text += new TextDecoder().decode(new Uint8Array(memory.buffer, base, length));
        total += length;
      }
      log(fd, text);
      words[written >> 2] = total;
      return 0;
    },
    clock_time_get(id, precision, out) {
      const nanos = BigInt(Date.now()) * 1000000n;
      new BigUint64Array(view().buffer, out, 1)[0] = nanos;
      return 0;
    },
    random_get(buffer, length) {
      crypto.getRandomValues(new Uint8Array(view().buffer, buffer, length));
      return 0;
    },
    environ_sizes_get(count, size) {
      const words = new Uint32Array(view().buffer);
      words[count >> 2] = 0;
      words[size >> 2] = 0;
      return 0;
    },
    environ_get() {
      return 0;
    },
    args_sizes_get(count, size) {
      const words = new Uint32Array(view().buffer);
      words[count >> 2] = 0;
      words[size >> 2] = 0;
      return 0;
    },
    args_get() {
      return 0;
    },
    proc_exit(code) {
      throw new Error("the module ended with " + code);
    },
  };
  return new Proxy(known, {
    get(target, name) {
      return name in target ? target[name] : () => ENOSYS;
    },
  });
}

// The library ready to be called: its exports, and text helpers that move
// bytes in and out of its memory.  source is a WebAssembly.Module, as a
// worker of Cloudflare gets it, or the bytes of the .wasm file.
export async function loadHilde(source, log = (fd, text) => console.log(text.replace(/\n$/, ""))) {
  let instance = null;
  const view = () => instance.exports.memory;
  const imports = { wasi_snapshot_preview1: wasiImports(view, log) };
  if (source instanceof WebAssembly.Module) {
    instance = await WebAssembly.instantiate(source, imports);
  } else {
    instance = (await WebAssembly.instantiate(source, imports)).instance;
  }
  const e = instance.exports;
  if (e._initialize) {
    e._initialize();
  }
  e.hilde_start();
  return {
    exports: e,
    // Copies text into the module's memory; the caller gives it back.
    put(text) {
      const bytes = new TextEncoder().encode(text);
      const address = e.hilde_wasm_alloc(bytes.length);
      if (address === 0) {
        throw new Error("the module has no memory for " + bytes.length + " bytes");
      }
      new Uint8Array(view().buffer, address, bytes.length).set(bytes);
      return { address, length: bytes.length };
    },
    take(place) {
      const text = new TextDecoder().decode(new Uint8Array(view().buffer, place.address, place.length));
      e.hilde_wasm_free(place.address);
      return text;
    },
    end() {
      e.hilde_end();
    },
  };
}

// The two functions of TextStats on one text: its words, and the text with
// its letters a to z made capitals.
export function textStats(hilde, text) {
  const place = hilde.put(text);
  const out = hilde.put(text);
  const words = hilde.exports.stats_words(place.address, place.length);
  const turned = hilde.exports.stats_upper(place.address, place.length, out.address, out.length);
  hilde.take(place);
  return { words, turned, upper: hilde.take(out) };
}
