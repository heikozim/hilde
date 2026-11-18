#!/usr/bin/env perl
#
# Part of Hilde, under the Apache License v2.0 with LLVM Exceptions.
# See LICENSE file for details.
#
# Copyright (c) 2026 Heiko Zimmermann <code@heiko-zimmermann.com>
# SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
#

# Holds the case convention of Hilde sources: a variable, a parameter and a
# constant are snake_case, written with no capital; a function or method is
# camelCase; a module or type is PascalCase.  Record slots are not
# looked at here.
#
#     perl scripts/check-naming.pl [--json] [--self-test] [--rules=N001,N002,N003] <file or directory...>
#
# N001: a variable, a parameter or a constant with a capital (snake_case).
# N002: a function or method that is not camelCase; a bound C function may
# keep its C name (pragma Foreign_Import with the same External_Name).
# N003: a module, record, union or typeclass that is not PascalCase.
# --rules keeps only the codes named; the default is all three.
# Exit 0 clean, 1 a finding, 9 nothing read.
# A file named expected-bad-name.* is skipped: it is a test of this rule.
use strict;
use warnings;
use File::Find;

my $json = 0;
my $self = 0;
my %rules = map { $_ => 1 } qw(N001 N002 N003);
my @paths;
for my $a (@ARGV) {
	if ($a eq '--json') { $json = 1 }
	elsif ($a eq '--self-test') { $self = 1 }
	elsif ($a =~ /^--rules=(N00[123](?:,N00[123])*)$/) { %rules = map { $_ => 1 } split /,/, $1 }
	elsif ($a =~ /^--/) { print "check-naming: unknown option $a\n"; exit 9 }
	else { push @paths, $a }
}

# The source with comments and strings blanked, line breaks kept.
sub blank {
	my ($s) = @_;
	$s =~ s{("""(?:[^"\\]++|\\.|"(?!""))*+"""|"(?:[^"\\]++|\\.)*+"|'(?:\\.|[^'\\])'|--[^\n]*)}{
		my $m = $1; $m =~ s/[^\n]/ /g; $m }gse;
	return $s;
}

sub line_of {
	my ($s, $pos) = @_;
	return 1 + (substr($s, 0, $pos) =~ tr/\n//);
}

# Finds, in one source text, each binder whose name has a capital.
sub findings {
	my ($text) = @_;
	my $s = blank($text);
	my @out;
	my $add = sub {
		my ($name, $what, $pos) = @_;
		push @out, [line_of($s, $pos), $what, $name, 'N001'] if $name =~ /[A-Z]/;
	};
	while ($s =~ /\b(let|var)\s+([A-Za-z]\w*)\s*:/g) { $add->($2, 'variable', $-[2]) }
	while ($s =~ /\b(for|borrow)\s+([A-Za-z]\w*)/g) { $add->($2, 'variable', $-[2]) }
	while ($s =~ /\bconstant\s+([A-Za-z]\w*)\s*:/g) { $add->($1, 'constant', $-[1]) }
	while ($s =~ /\b(?:function|method)\s+\w+\s*\(([^()]*)\)/g) {
		my ($list, $base) = ($1, $-[1]);
		my $depth = 0;
		while ($list =~ /([\[\]])|([A-Za-z]\w*)\s*:/g) {
			if (defined $1) { $depth += $1 eq '[' ? 1 : -1; next }
			$add->($2, 'parameter', $base + $-[2]) if $depth == 0;
		}
	}
	while ($s =~ /\b(?:let|var)\s*\{([^}]*)\}/g) {
		my ($list, $base) = ($1, $-[1]);
		while ($list =~ /\bas\s+([A-Za-z]\w*)|([A-Za-z]\w*)\s*:/g) {
			if (defined $1) { $add->($1, 'variable', $base + $-[1]) }
		}
	}
	while ($s =~ /\b(?:function|method)\s+([A-Za-z_]\w*)/g) {
		my ($name, $pos) = ($1, $-[1]);
		# A bound C function may keep the name it has in C.
		next if substr($text, $pos > 300 ? $pos - 300 : 0, $pos > 300 ? 300 : $pos) =~ /External_Name\s*=>\s*"(\w+)"\s*\)\s*;\s*(?:function|method)\s+\z/ && $1 eq $name;
		push @out, [line_of($s, $pos), 'function', $name, 'N002']
			unless $name =~ /^[a-z][A-Za-z0-9]*(?:_[0-9][A-Za-z0-9]*)*$/;
	}
	while ($s =~ /(?<!end\s)\b(module(?:\s+body)?|record|union|typeclass)\s+([A-Za-z_][\w.]*)/g) {
		my ($what, $name, $pos) = ($1, $2, $-[2]);
		$what = 'module' if $what =~ /^module/;
		$what = 'type' unless $what eq 'module';
		my @parts = $what eq 'module' ? split(/\./, $name) : ($name);
		push @out, [line_of($s, $pos), $what, $name, 'N003']
			if grep { !/^[A-Z][A-Za-z0-9]*$/ } @parts;
	}
	return @out;
}

if ($self) {
	my @good = findings("module body M is\nconstant max_size: Index := 1;\nfunction fooBar(some_arg: Index): Index is\nlet local_name: Index := \"camelCase\"; -- camelCase\nreturn local_name;\nend;\npragma Foreign_Import(External_Name => \"c_name\");\nfunction c_name(): Index is\nend;\nfunction sha3_256(): Index is\nreturn 0;\nend;\nrecord GoodName is end;\nend module body.\n");
	my @bad = findings("module body M is\nconstant maxSize: Index := 1;\nfunction f(someArg: Index): Index is\nlet localName: Index := 0;\nfor iVar from 0 to 1 do skip; end for;\nreturn 0;\nend;\nfunction Bad_Name(): Index is\nreturn 0;\nend;\nrecord bad_type is end;\nend module body.\n");
	my @names = map { $_->[2] } @bad;
	if (@good == 0 && "@names" =~ /localName/ && "@names" =~ /iVar/ && "@names" =~ /maxSize/ && "@names" =~ /someArg/ && "@names" =~ /Bad_Name/ && "@names" =~ /bad_type/ && @bad == 6) {
		print "check-naming self-test good=0 bad=6 ok\n";
		exit 0 unless @paths;
	} else {
		print "check-naming self-test FAILED good=" . scalar(@good) . " bad=" . scalar(@bad) . "\n";
		exit 1;
	}
}

my @files;
for my $p (@paths) {
	if (-d $p) {
		find({ no_chdir => 1, wanted => sub {
			if ($_ =~ m{(^|/)(_build|\.git|vendor)$}) { $File::Find::prune = 1; return }
			push @files, $_ if -f $_ && /\.hi[qh]$/;
		} }, $p);
	} elsif (-f $p) {
		push @files, $p;
	}
}
@files = sort grep { !m{/expected-bad-name\.[^/]*$} } @files;
if (!@files) {
	print "check-naming: nothing read\n";
	exit 9;
}

my @all;
for my $f (@files) {
	open my $h, '<', $f or do { print "check-naming: cannot read $f\n"; exit 9 };
	local $/;
	my $text = <$h>;
	close $h;
	push @all, map { [$f, @$_] } grep { $rules{$_->[3]} } findings($text);
}

if ($json) {
	my @items = map {
		sprintf('{"code":"%s","file":"%s","line":%d,"kind":"%s","name":"%s"}', $_->[4], @$_[0..3])
	} @all;
	printf "{\"command\":\"check-naming\",\"files\":%d,\"findings\":[%s]}\n", scalar(@files), join(',', @items);
} else {
	for my $x (@all) {
		my ($file, $line, $what, $name, $code) = @$x;
		my $want = $code eq 'N001' ? 'snake_case' : $code eq 'N002' ? 'camelCase' : 'PascalCase';
		printf "%s %s:%d: %s %s breaks the case rule, write it in %s\n", $code, $file, $line, $what, $name, $want;
	}
	printf "check-naming files=%d findings=%d\n", scalar(@files), scalar(@all);
}
exit(@all ? 1 : 0);
