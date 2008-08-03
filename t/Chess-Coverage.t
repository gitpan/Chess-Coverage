#!/usr/bin/perl
use strict;
use warnings;
use Test::More tests => 5;
my $class = 'Chess::Coverage';
use_ok $class;
my $g = eval { $class->new() };
print $@ if $@;
isa_ok $g, $class;
my $fen = 'rnbqkbnr/pp1ppppp/8/2p5/4P3/5N2/PPPP1PPP/RNBQKB1R b KQkq - 1 2';
$g = eval { $class->new($fen) };
print $@ if $@;
isa_ok $g, $class;
my $c = $g->coverage();
isa_ok $c, 'HASH';
is $c->{H8}{occupant}, 'black rook 16', 'H8 occupant';
