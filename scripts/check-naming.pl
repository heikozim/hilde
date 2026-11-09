#!/usr/bin/env perl
#
# Part of Hilde, under the Apache License v2.0 with LLVM Exceptions.
# See LICENSE file for details.
#
# Copyright (c) 2026 Heiko Zimmermann <code@heiko-zimmermann.com>
# SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
#

# Holds the case convention of Hilde sources: a variable, a parameter and a
# constant are snake_case, written with no capital.  Functions, types, modules
# and record slots are not looked at here.
#
#     perl scripts/check-naming.pl [--json] [--self-test] <file or directory...>
#
# Each finding has the code N001.  Exit 0 clean, 1 a finding, 9 nothing read.
# A file named expected-bad-name.* is skipped: it is a test of this rule.
use strict;
use warnings;
use File::Find;

my $json = 0;
my $self = 0;
my @paths;
for my $a (@ARGV) {
	if ($a eq '--json') { $json = 1 }
	elsif ($a eq '--self-test') { $self = 1 }
	else { push @paths, $a }
}

# The source with comments and strings blanked, line breaks kept.
sub blank {
	my ($s) = @_;
	$s =~ s{("""(?:\\"""|.)*?"""|"(?:\\.|[^"\\])*"|'(?:\\.|[^'\\])'|--[^\n]*)}{
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
		push @out, [line_of($s, $pos), $what, $name] if $name =~ /[A-Z]/;
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
	return @out;
}

if ($self) {
	my @good = findings("module body M is\nconstant max_size: Index := 1;\nfunction fooBar(some_arg: Index): Index is\nlet local_name: Index := \"camelCase\"; -- camelCase\nreturn local_name;\nend;\nend module body.\n");
	my @bad = findings("module body M is\nconstant maxSize: Index := 1;\nfunction f(someArg: Index): Index is\nlet localName: Index := 0;\nfor iVar from 0 to 1 do skip; end for;\nreturn 0;\nend;\nend module body.\n");
	my @names = map { $_->[2] } @bad;
	if (@good == 0 && "@names" =~ /localName/ && "@names" =~ /iVar/ && "@names" =~ /maxSize/ && "@names" =~ /someArg/ && @bad == 4) {
		print "check-naming self-test good=0 bad=4 ok\n";
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
	push @all, [$f, @$_] for findings($text);
}

if ($json) {
	my @items = map {
		sprintf('{"code":"N001","file":"%s","line":%d,"kind":"%s","name":"%s"}', @$_)
	} @all;
	printf "{\"command\":\"check-naming\",\"files\":%d,\"findings\":[%s]}\n", scalar(@files), join(',', @items);
} else {
	printf "N001 %s:%d: %s %s has a capital, write it in snake_case\n", @$_ for @all;
	printf "check-naming files=%d findings=%d\n", scalar(@files), scalar(@all);
}
exit(@all ? 1 : 0);
