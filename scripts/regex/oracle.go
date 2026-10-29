// The oracle for the test of Standard.Regex against Go: Go's regexp on the
// cases of scripts/regex/cases.py, printed in the format the Hilde test
// prints.
//
//	go run scripts/regex/oracle.go scripts/regex/cases.json
//
// Only the standard library.  `replace` is not Go's ReplaceAllString -- its
// rewrite syntax is `$1`, not RE2's `\1` -- but the matches of
// FindAllStringSubmatchIndex spliced with RE2's rewrite rules, which is the
// definition Standard.Regex documents.
package main

import (
	"encoding/hex"
	"encoding/json"
	"fmt"
	"os"
	"regexp"
	"strings"
)

type testCase struct {
	Pattern string `json:"pattern"`
	Subject string `json:"subject"`
	// A subject that is not UTF-8 cannot be JSON text; it comes as hex.
	SubjectHex string `json:"subject_hex"`
	Rewrite    string `json:"rewrite"`
}

// expand writes rewrite with \0-\9 replaced by the groups of one match and
// \\ by one backslash; any other backslash is copied as it stands.
func expand(out *strings.Builder, text, rewrite string, m []int) {
	for i := 0; i < len(rewrite); i++ {
		c := rewrite[i]
		if c == '\\' && i+1 < len(rewrite) {
			d := rewrite[i+1]
			if d >= '0' && d <= '9' {
				g := int(d - '0')
				if 2*g+1 < len(m) && m[2*g] >= 0 && m[2*g+1] >= 0 {
					out.WriteString(text[m[2*g]:m[2*g+1]])
				}
				i++
				continue
			}
			if d == '\\' {
				out.WriteByte('\\')
				i++
				continue
			}
		}
		out.WriteByte(c)
	}
}

// escape writes every byte outside printable ASCII, and every '%', as %XX:
// the expected output is a file of the repository, which is ASCII.
func escape(s string) string {
	var b strings.Builder
	for i := 0; i < len(s); i++ {
		c := s[i]
		if c < ' ' || c > '~' || c == '%' {
			fmt.Fprintf(&b, "%%%02X", c)
		} else {
			b.WriteByte(c)
		}
	}
	return b.String()
}

func position(v int) string {
	if v < 0 {
		return "-"
	}
	return fmt.Sprint(v)
}

func main() {
	if len(os.Args) != 2 {
		fmt.Fprintln(os.Stderr, "usage: oracle cases.json")
		os.Exit(2)
	}
	data, err := os.ReadFile(os.Args[1])
	if err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(1)
	}
	var cases []testCase
	if err := json.Unmarshal(data, &cases); err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(1)
	}
	for n, c := range cases {
		if c.SubjectHex != "" {
			raw, err := hex.DecodeString(c.SubjectHex)
			if err != nil {
				fmt.Fprintln(os.Stderr, err)
				os.Exit(1)
			}
			c.Subject = string(raw)
		}
		fmt.Printf("case %d\n", n+1)
		re, err := regexp.Compile(c.Pattern)
		if err != nil {
			fmt.Println("error")
			continue
		}
		if re.MatchString(c.Subject) {
			fmt.Println("match yes")
		} else {
			fmt.Println("match no")
		}
		m := re.FindStringSubmatchIndex(c.Subject)
		if m == nil {
			fmt.Println("find none")
		} else {
			line := fmt.Sprintf("find %d %d", m[0], m[1])
			for g := 1; g < len(m)/2; g++ {
				line += " " + position(m[2*g]) + "," + position(m[2*g+1])
			}
			fmt.Println(line)
		}
		all := re.FindAllStringSubmatchIndex(c.Subject, -1)
		line := fmt.Sprintf("all %d", len(all))
		for _, a := range all {
			line += fmt.Sprintf(" %d,%d", a[0], a[1])
		}
		fmt.Println(line)
		var out strings.Builder
		copied := 0
		for _, a := range all {
			out.WriteString(c.Subject[copied:a[0]])
			expand(&out, c.Subject, c.Rewrite, a)
			copied = a[1]
		}
		out.WriteString(c.Subject[copied:])
		fmt.Printf("replace [%s]\n", escape(out.String()))
	}
	fmt.Fprintf(os.Stderr, "cases: %d\n", len(cases))
}
