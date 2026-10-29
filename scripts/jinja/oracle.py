#!/usr/bin/env python3
# The oracle for the end-to-end tests of the template statement: Jinja2
# renders a template of a test directory with the test's data.json, and prints the
# result and one newline -- what the Hilde test prints with printLn.
#
#     python3 scripts/jinja/oracle.py <test-directory> <template> > program-stdout.txt
#
# Run where Jinja2 is installed -- on a host, not in the gate image, which
# has no Jinja2 -- and the output is committed as the expected output, the
# same arrangement as Go for the tests of Standard.Regex.  The settings are Jinja2's defaults
# except the two the order implies: autoescape is ON (escaping is on by
# default in @template) and an undefined name is an ERROR (in @template it
# does not compile).  Templates are read from the test directory, which is
# where @template reads them: beside the module.  A test that gives
# @template whitespace options has them in options.txt beside the template,
# words separated by spaces (trim_blocks, lstrip_blocks), and they are
# passed to Jinja2 as the settings of the same names.
import json
import os
import sys

import jinja2


def main():
    if len(sys.argv) != 3:
        sys.stderr.write("usage: oracle.py <test-directory> <template>\n")
        sys.exit(2)
    directory, name = sys.argv[1], sys.argv[2]
    with open(os.path.join(directory, "data.json"), encoding="utf-8") as f:
        data = json.load(f)
    options = {}
    path = os.path.join(directory, "options.txt")
    if os.path.exists(path):
        with open(path, encoding="utf-8") as f:
            for word in f.read().split():
                if word not in ("trim_blocks", "lstrip_blocks"):
                    sys.stderr.write("unknown option %s in %s\n" % (word, path))
                    sys.exit(2)
                options[word] = True
    env = jinja2.Environment(
        loader=jinja2.FileSystemLoader(directory),
        autoescape=True,
        undefined=jinja2.StrictUndefined,
        **options,
    )
    out = env.get_template(name).render(**data)
    sys.stdout.write(out + "\n")
    sys.stderr.write("jinja2 %s, %d bytes, options %s\n" % (jinja2.__version__, len(out.encode("utf-8")), sorted(options) or "none"))


if __name__ == "__main__":
    main()
