#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'AnyEvent::Log4perl' ) || print "Bail out!\n";
}

diag( "Testing AnyEvent::Log4perl $AnyEvent::Log4perl::VERSION, Perl $], $^X" );
