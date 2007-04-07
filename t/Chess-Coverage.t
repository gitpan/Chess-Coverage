#!/usr/bin/perl
use strict;
use warnings;
use Test::More tests => 2;
use_ok 'Chess::Coverage';
my $g = eval { Chess::Coverage->new() };
print $@ if $@;
isa_ok $g, 'Chess::Coverage';
