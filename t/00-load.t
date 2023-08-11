#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Module::NamespaceSubroutines' ) || print "Bail out!\n";
}

diag( "Testing Module::NamespaceSubroutines $Module::NamespaceSubroutines::VERSION, Perl $], $^X" );
