// The oracle of the migration check of the end-to-end tests of the
// template statement: Go's
// html/template renders a .gohtml file of a test directory
// with the test's data.json, and the output goes to stdout as rendered.
//
//	go run scripts/jinja/go-oracle.go <test-directory> <page.gohtml> > program-stdout.txt
//
// Run on a host where Go is (the gate image has none), and the output is
// committed as the expected output of the test, whose .jinja rewrite of the
// same page must render the same bytes.  Only the standard library.
package main

import (
	"encoding/json"
	"fmt"
	"html/template"
	"os"
	"path/filepath"
)

func main() {
	if len(os.Args) != 3 {
		fmt.Fprintln(os.Stderr, "usage: go-oracle <test-directory> <page.gohtml>")
		os.Exit(2)
	}
	dir, name := os.Args[1], os.Args[2]
	raw, err := os.ReadFile(filepath.Join(dir, "data.json"))
	if err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(1)
	}
	var data map[string]interface{}
	if err := json.Unmarshal(raw, &data); err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(1)
	}
	t, err := template.ParseFiles(filepath.Join(dir, name))
	if err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(1)
	}
	if err := t.Execute(os.Stdout, data); err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(1)
	}
}
