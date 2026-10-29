;;;; hilde-mode.el - Major mode for editing Hilde source files.  -*- lexical-binding: t -*-
;;;;
;;;; Copyright (C) 2021 Fernando Borretti
;;;;
;;;; Author: Fernando Borretti <fernando@borretti.me>
;;;; Maintainer: Fernando Borretti <fernando@borretti.me>
;;;; Created: 24 July, 2021
;;;; Version: 0.1.0
;;;; Keywords: languages
;;;;
;;;; Structure
;;;; ---------
;;;;
;;;;     1. Constants
;;;;     1. Syntax Highlighting
;;;;     1. Indentation
;;;;     1. Mode Definition
;;;;
;;;; Modified by Heiko Zimmermann for Hilde, 2026.
;;;;
;;;; The keywords and operators follow the compiler's lexer,
;;;; lib/Lexer.mll.  A keyword added there is added here as well.

(require 'cl-lib)

;;;; Section 1. Constants

(defconst hilde-keywords
  '("and" "or" "not" "module" "is" "body" "import" "as" "end" "constant" "type"
    "function" "generic" "record" "union" "case" "of" "when" "typeclass"
    "instance" "method" "if" "then" "else" "let" "var" "while" "for" "do" "from"
    "to" "borrow" "return" "skip" "pragma" "sizeof"
    "requires" "ensures" "invariant" "raises" "raise"))

(defconst hilde-builtin-types
  '("Free" "Linear" "Type" "Region" "Span"))

(defconst hilde-constants
  '("nil" "true" "false"))

(defconst hilde-directives
  '("@embed" "@bytes" "@template" "@query" "@execute" "@migrations"))

;; The regexps below are matched against the code of a line: its text with
;; strings, character constants and the comment removed.
;; A line that ends with one of these words opens a block.
(defconst hilde-indent-regexp
  "\\_<\\(is\\|then\\|do\\|else\\|of\\)[ \t]*$")
;; A declaration whose contract follows on the next lines.
(defconst hilde-signature-regexp
  "^[ \t]*\\(function\\|method\\)\\_>[^;]*$")
(defconst hilde-contract-end-regexp
  "^[ \t]*\\(requires\\|ensures\\|raises\\)\\_>.*;[ \t]*$")
;; A statement that goes on in the next line.
(defconst hilde-continue-regexp
  "\\(:=\\|=>\\|[-+*/=<>]\\|\\_<and\\|\\_<or\\|\\_<not\\)[ \t]*$")
(defconst hilde-deindent-2-regexp
  "^[ \t]*end[ \t]+case\\_>")
(defconst hilde-deindent-1-regexp
  "^[ \t]*\\(end\\_>\\|else\\_>\\|[])}]\\)")
;; A case of a union, as against the case statement, which ends in of.
(defconst hilde-union-case-regexp
  "^[ \t]*case[ \t]+[[:alpha:]][_[:alnum:]]*[ \t]*\\(is\\|;\\)[ \t]*$")
;; A line that goes on with the expression of the line before.
(defconst hilde-leading-operator-regexp
  "^[ \t]*\\(and\\|or\\)\\_>")
(defconst hilde-when-regexp
  "^[ \t]*when\\_>")
(defconst hilde-of-regexp
  "\\_<of[ \t]*$")

(defconst hilde-default-tab-width 4)

;;;; Section 1. Syntax Highlighting
;;;;

;; Build a new syntax-table from scratch to avoid any defaults:
(defconst hilde-syntax-table
  (let ((table (make-char-table 'syntax-table)))
    (modify-syntax-entry   ?\#        "_"  table) ;; hex/bin/oct constants.
    (modify-syntax-entry   ?\!        "."  table)
    (modify-syntax-entry   ?\&        "."  table)
    (modify-syntax-entry   ?\(        "()" table)
    (modify-syntax-entry   ?\)        ")(" table)
    (modify-syntax-entry '(?\* . ?\/) "."  table)
    (modify-syntax-entry '(?0  . ?9 ) "w"  table)
    (modify-syntax-entry '(?\: . ?\>) "."  table)
    (modify-syntax-entry   ?\?        "."  table) ;; propagation.
    (modify-syntax-entry   ?@         "_"  table) ;; @embed and the others.
    (modify-syntax-entry '(?A  . ?Z ) "w"  table)
    (modify-syntax-entry   ?\[        "(]" table)
    (modify-syntax-entry   ?\]        ")[" table)
    (modify-syntax-entry   ?_         "_"  table)
    (modify-syntax-entry '(?a  . ?z ) "w"  table)
    (modify-syntax-entry   ?\{        "(}" table)
    (modify-syntax-entry   ?\}        "){" table)
    (modify-syntax-entry   ?\|        "."  table) ;; alternative patterns.
    (modify-syntax-entry   ?\~        "."  table) ;; &~ reborrow.
    table))

;; https://www.gnu.org/software/emacs/manual/html_node/elisp/Faces-for-Font-Lock.html
;; The first rule that matches a stretch of text gives it its face.
(defvar hilde-font-lock-keywords
  (list
   ;; Comments
   (cons "--.*" font-lock-comment-face)
   ;; Strings, using the syntax-table (above) would interfere with comments.
   ;; A triple string is a docstring; a string may span lines.
   (cons "\"\"\"\\([^\"]*\\(\"[^\"]\\|\"\"[^\"]\\)\\)*[^\"]*\"\"\"" font-lock-doc-face)
   (cons "\"\\([^\"\\\\]\\|\\\\[^z-a]\\)*\"" font-lock-string-face)
   (cons "'\\([^\\\\]\\|\\\\[nrt\\\\]\\)'" font-lock-string-face)
   ;; The directives that read files, SQL or C at compile time.
   (cons (concat (regexp-opt hilde-directives) "\\_>") font-lock-preprocessor-face)
   (cons "\\_<pragma[ \t]+\\([[:alpha:]][_[:alnum:]]*\\)" '(1 font-lock-preprocessor-face))
   ;; The names a declaration introduces
   (cons "\\_<\\(?:function\\|method\\)[ \t]+\\([[:alpha:]][_[:alnum:]]*\\)"
         '(1 font-lock-function-name-face))
   (cons "\\_<\\(?:record\\|union\\|typeclass\\|type\\|instance\\)[ \t]+\\([[:alpha:]][_[:alnum:]]*\\)"
         '(1 font-lock-type-face))
   (cons "\\_<constant[ \t]+\\([[:alpha:]][_[:alnum:]]*\\)" '(1 font-lock-constant-face))
   ;; Keywords, constants and the built-in types
   (cons (regexp-opt hilde-keywords 'symbols) font-lock-keyword-face)
   (cons (regexp-opt hilde-constants 'symbols) font-lock-constant-face)
   (cons (concat (regexp-opt hilde-builtin-types 'symbols) "!?") font-lock-builtin-face)
   ;; Numbers: decimal with ' as a group separator, #x, #o and #b.
   (cons "\\_<\\(?:[0-9][0-9']*\\(?:\\.[0-9][0-9']*\\(?:[eE][+-]?[0-9][0-9']*\\)?\\)?\\|#x[0-9a-fA-F][0-9a-fA-F']*\\|#o[0-7][0-7']*\\|#b[01][01']*\\)"
         font-lock-constant-face)
   ;; Types and constructors start with a capital letter.
   (cons "\\_<[[:upper:]][_[:alnum:]]*\\_>" font-lock-type-face)
   ;; Calls and named arguments
   (cons "\\_<\\([[:lower:]][_[:alnum:]]*\\)(" '(1 font-lock-function-name-face))
   (cons "\\_<\\([[:alpha:]][_[:alnum:]]*\\)[ \t]*=>" '(1 font-lock-variable-name-face))
   ))

;;;; Section 1. Indentation
;;;;

(defun hilde-in-triple-string-p ()
  "Return non-nil when the current line starts inside a triple string."
  (let ((end (line-beginning-position))
        (count 0))
    (save-excursion
      (goto-char (point-min))
      (while (search-forward "\"\"\"" end t)
        (setq count (1+ count))))
    (= (% count 2) 1)))

(defun hilde-line-code ()
  "Return the code of the current line: its text with strings, character
constants and the comment turned into blanks, so that columns stay."
  (let ((text (buffer-substring-no-properties (line-beginning-position)
                                              (line-end-position)))
        (blank (lambda (match) (make-string (length match) ?\s))))
    (setq text (replace-regexp-in-string "\"\\([^\"\\\\]\\|\\\\.\\)*\"" blank text t t))
    (setq text (replace-regexp-in-string "'\\([^\\\\]\\|\\\\.\\)'" blank text t t))
    (replace-regexp-in-string "--.*\\'" blank text t t)))

(defun hilde-paren-balance (code)
  "Return the number of brackets CODE opens minus the number it closes."
  (let ((balance 0))
    (dolist (char (string-to-list code) balance)
      (cond ((memq char '(?\( ?\[ ?\{)) (setq balance (1+ balance)))
            ((memq char '(?\) ?\] ?\})) (setq balance (1- balance)))))))

(defun hilde-string-line-p ()
  "Return non-nil when the current line belongs to a string: it is inside
or starts a triple string, or it goes on with a string of the line before
and so starts with a backslash."
  (or (hilde-in-triple-string-p)
      (save-excursion
        (beginning-of-line)
        (looking-at "[ \t]*\\(\\\\\\|.*\"\"\"\\)"))))

(defun hilde-previous-code-line ()
  "Move to the closest line before the current one that holds code: not
blank, not only a comment, not part of a triple string and not the
continuation of a string, which starts with a backslash.  Return nil and
stay when there is none."
  (let ((start (point))
        (found nil))
    (while (and (not found) (= (forward-line -1) 0))
      (unless (or (string-match-p "\\`[ \t]*\\'" (hilde-line-code))
                  (hilde-string-line-p))
        (setq found t)))
    (unless found (goto-char start))
    found))

(defun hilde-line-continues-p ()
  "Return non-nil when the code line before this one ends in an operator,
so that this line goes on with its statement."
  (save-excursion
    (and (hilde-previous-code-line)
         (string-match-p hilde-continue-regexp (hilde-line-code)))))

(defun hilde-open-bracket-column (code)
  "Return the column of the last bracket CODE leaves open, or nil."
  (let ((i (1- (length code)))
        (depth 0)
        (column nil))
    (while (and (>= i 0) (not column))
      (let ((char (aref code i)))
        (cond ((memq char '(?\) ?\] ?\})) (setq depth (1+ depth)))
              ((memq char '(?\( ?\[ ?\{))
               (if (= depth 0) (setq column i) (setq depth (1- depth))))))
      (setq i (1- i)))
    column))

(defun hilde-union-slot-p (base-indent)
  "Return non-nil when the closest code line above the current one that is
indented less than BASE-INDENT is a case of a union."
  (save-excursion
    (let ((found nil) (result nil))
      (while (and (not found) (hilde-previous-code-line))
        (when (< (current-indentation) base-indent)
          (setq found t
                result (string-match-p hilde-union-case-regexp (hilde-line-code)))))
      result)))

(defun hilde-query-for-p (indent)
  "Return non-nil when the closest code line above the current one that is
indented INDENT or less is the for of a query, on the line after @query."
  (save-excursion
    (let ((found nil) (result nil))
      (while (and (not found) (hilde-previous-code-line))
        (when (and (<= (current-indentation) indent)
                   (not (string-match-p "\\`[ \t]*else\\_>" (hilde-line-code))))
          (setq found t
                result (and (string-match-p "\\`[ \t]*for\\_>" (hilde-line-code))
                            (hilde-previous-code-line)
                            (string-match-p "\\`[ \t]*@query\\_>" (hilde-line-code))))))
      result)))

(defun hilde-calculate-indentation ()
  "Return the indentation of the current line, taken from the code line
before it.  One level more after a line that ends with is, then, do, else
or of, after one that ends in an operator, before a line that starts with
and or or, and after the signature of a function whose contract follows.
A line in an open bracket lines up after the bracket, or one level in when
the bracket ends its line.  One level less at end, else, a closing
bracket, a when after the body of another when, a case of a union after
the slots of another, after the last clause of a contract and after the
end of a continued statement; two levels less at end case and at the end
of a union whose last case has slots."
  (save-excursion
    (beginning-of-line)
    (let ((current (buffer-substring-no-properties (point) (line-end-position)))
          base-code base-indent anchor-continues)
      (if (not (hilde-previous-code-line))
          0
        (setq base-code (hilde-line-code))
        ;; A line that closes brackets opened above is measured from the
        ;; line that opened them.
        (let ((balance (hilde-paren-balance base-code)))
          (save-excursion
            (while (and (< balance 0) (hilde-previous-code-line))
              (setq balance (+ balance (hilde-paren-balance (hilde-line-code)))))
            (setq base-indent (current-indentation))
            (setq anchor-continues (hilde-line-continues-p))))
        (let* ((open (and (> (hilde-paren-balance base-code) 0)
                          (hilde-open-bracket-column base-code)))
               (indent
                (cond
                 ((string-match-p hilde-indent-regexp base-code)
                  (+ base-indent hilde-default-tab-width))
                 (open
                  (if (string-match-p "\\`[ \t]*\\'" (substring base-code (1+ open)))
                      (+ base-indent hilde-default-tab-width)
                    (1+ open)))
                 ;; The for of a query stands on the line after it.
                 ((string-match-p "\\`[ \t]*@query\\_>[^;]*\\'" base-code)
                  (+ base-indent hilde-default-tab-width))
                 ((string-match-p hilde-signature-regexp base-code)
                  (+ base-indent hilde-default-tab-width))
                 ((string-match-p hilde-contract-end-regexp base-code)
                  (- base-indent hilde-default-tab-width))
                 ((string-match-p hilde-continue-regexp base-code)
                  (if anchor-continues
                      base-indent
                    (+ base-indent hilde-default-tab-width)))
                 ((and anchor-continues (string-match-p ";[ \t]*$" base-code))
                  (- base-indent hilde-default-tab-width))
                 (t base-indent))))
          (cond
           ((string-match-p hilde-deindent-2-regexp current)
            (setq indent (- indent (* 2 hilde-default-tab-width))))
           ((string-match-p hilde-deindent-1-regexp current)
            (setq indent (- indent hilde-default-tab-width))
            (when (and (string-match-p "\\`[ \t]*end\\_>" current)
                       (not (string-match-p hilde-union-case-regexp base-code))
                       (not (string-match-p hilde-indent-regexp base-code))
                       (hilde-union-slot-p base-indent))
              (setq indent (- indent hilde-default-tab-width)))
            (when (and (string-match-p "\\`[ \t]*end[ \t]+for\\_>" current)
                       (hilde-query-for-p indent))
              (setq indent (- indent hilde-default-tab-width))))
           ((and (string-match-p hilde-when-regexp current)
                 (not (string-match-p hilde-of-regexp base-code)))
            (setq indent (- indent hilde-default-tab-width)))
           ((and (string-match-p hilde-union-case-regexp current)
                 (not (string-match-p hilde-union-case-regexp base-code))
                 (not (string-match-p hilde-indent-regexp base-code)))
            (setq indent (- indent hilde-default-tab-width)))
           ((and (string-match-p hilde-leading-operator-regexp current)
                 (not open)
                 (not (string-match-p hilde-continue-regexp base-code)))
            (setq indent
                  (if (string-match-p hilde-leading-operator-regexp base-code)
                      base-indent
                    (+ base-indent hilde-default-tab-width)))))
          (max indent 0))))))

(defun hilde-indent-line ()
  "Indent the current line of Hilde code.  A line inside a triple string,
and one that goes on with a string and starts with a backslash, keeps its
indentation."
  (unless (or (hilde-in-triple-string-p)
              (save-excursion (beginning-of-line) (looking-at "[ \t]*\\\\")))
    (let ((offset (- (current-column) (current-indentation))))
      (indent-line-to (hilde-calculate-indentation))
      (when (> offset 0)
        (move-to-column (+ (current-indentation) offset))))))

;;;; Section 1. Mode Definition
;;;;

(define-derived-mode hilde-mode fundamental-mode "Hilde"
  :syntax-table hilde-syntax-table
  "Major mode for editing Hilde source text."
  (setq-local font-lock-defaults '((hilde-font-lock-keywords)))
  (setq-local comment-start "-- ")
  (setq-local comment-start-skip "--+[ \t]*")
  (setq-local comment-end "")
  (setq-local indent-tabs-mode nil)
  (setq-local tab-width hilde-default-tab-width)
  (setq-local indent-line-function 'hilde-indent-line))


(add-to-list 'auto-mode-alist '("\\.hih\\'" . hilde-mode))
(add-to-list 'auto-mode-alist '("\\.hiq\\'" . hilde-mode))

(provide 'hilde-mode)
