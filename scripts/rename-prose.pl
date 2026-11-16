#!/usr/bin/env perl
#
# Part of Hilde, under the Apache License v2.0 with LLVM Exceptions.
# See LICENSE file for details.
#
# Copyright (c) 2026 Heiko Zimmermann <code@heiko-zimmermann.com>
# SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
#

# Brings the words of documentation along with a plan of hilde rename: exact
# pairs only, whole words only.  A pair stays out when the old name is also a
# function, starts with a capital or stands in a file named by --keep-from (a
# C name, for one).  A word that is part of a path, a file name, an option or a
# dotted name stays, and so does every fence that is not Hilde.
#
#     perl scripts/rename-prose.pl --plan=<json> [--keep-from=<file>]... [--apply] <file>...
#
# Prints one line per file and word.  Exit 0 done, 9 not run.
use strict;
use warnings;
use JSON::PP;

my ($plan, $apply, @keep, @files);
for my $a (@ARGV) {
	if ($a =~ /^--plan=(.*)/) { $plan = $1 }
	elsif ($a =~ /^--keep-from=(.*)/) { push @keep, $1 }
	elsif ($a eq '--apply') { $apply = 1 }
	else { push @files, $a }
}
defined $plan && @files or do { print "ABORT: usage -- nothing done\n"; exit 9 };

sub slurp {
	my ($f) = @_;
	open my $h, '<:raw', $f or do { print "ABORT: $f\n"; exit 9 };
	local $/;
	my $s = <$h>;
	close $h;
	return $s;
}

my $data = decode_json(slurp($plan));
my $entries = ref $data eq 'HASH' ? $data->{pairs} : $data;
my %pairs;
my %out;
for my $p (@$entries) {
	if ($p->{callable} || $p->{old} =~ /^[A-Z]/) { $out{$p->{old}} = 1; next }
	$pairs{$p->{old}} = $p->{new};
}
my %kept;
for my $f (@keep) {
	my $s = slurp($f);
	$kept{$1} = 1 while $s =~ /([A-Za-z_]\w*)/g;
}
delete @pairs{grep { $kept{$_} || $out{$_} } keys %pairs};

my $total = 0;
for my $f (@files) {
	my $s = slurp($f);
	my %hits;
	my $fence = '';
	my @lines = split /^/, $s;
	for my $l (@lines) {
		if ($l =~ /^\s*```(\S*)/) {
			if ($fence ne '') { $fence = '' } else { $fence = $1 eq '' ? 'other' : $1 }
			next;
		}
		next if $fence ne '' && $fence ne 'hilde' && $fence ne 'austral';
		$l =~ s{(?<![\w/.\-\$\@])([A-Za-z]\w*)(?![\w/\-]|\.\w)}{
			my $w = $1;
			if (exists $pairs{$w}) { $hits{$w}++; $pairs{$w} } else { $w } }ge;
	}
	for my $w (sort keys %hits) {
		print "$f $w -> $pairs{$w} x$hits{$w}\n";
		$total += $hits{$w};
	}
	if ($apply && %hits) {
		open my $h, '>:raw', $f or do { print "ABORT: $f\n"; exit 9 };
		print $h join('', @lines);
		close $h;
	}
}
print "rename-prose files=" . scalar(@files) . " pairs=" . scalar(keys %pairs) . " words=$total\n";
exit 0;
