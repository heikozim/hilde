// Modified by Heiko Zimmermann for Hilde, 2026.
import grammar from "./hilde.tmLanguage";
import { writeFile } from "fs";
import * as path from "path";
const syntaxPath = path.join(
  __dirname,
  "..",
  "syntaxes",
  "hilde.tmLanguage.json"
);

writeFile(syntaxPath, JSON.stringify(grammar, undefined, 4) + "\n", (err) => {
  if (err) console.error(`failed to write syntax: ${err}`);
});
