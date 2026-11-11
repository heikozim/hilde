# 095-i18n

Translations in templates and in code, `Standard.I18n`.

001 renders one page in English, in German and in a language the catalog
does not have, which gives the default; with a plural through `_()` and
through a `{% trans %}` block, and a user name with markup that the
escaping of its place takes.  The catalog is a module of its own.  014
renders with one catalog from several tasks at once, 015 with a catalog
in the module that holds the `@template`.

002 to 013 must not compile, each with its message: an unknown key, at the
template's line, and a language that misses a key, at the language's case
(both from the type checker), then one test per message of the
translations in a template, H7115 to H7124.
