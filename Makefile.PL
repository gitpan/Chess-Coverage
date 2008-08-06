#!/usr/bin/perl
use strict;
use warnings;
use ExtUtils::MakeMaker;
WriteMakefile(
    NAME => 'Chess::Coverage',
    VERSION_FROM => 'lib/Chess/Coverage.pm',
    PREREQ_PM => {},
    ($] >= 5.005
        ? (ABSTRACT_FROM => 'lib/Chess/Coverage.pm',
           AUTHOR => 'Gene Boggs <gene@cpan.org>')
        : ()
    ),
);
