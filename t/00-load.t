#!perl -T

use Test::More tests => 5;

BEGIN {
	use_ok( 'Gudule::Server' );
	use_ok( 'Gudule::Config' );
	use_ok( 'Gudule::Util' );
	use_ok( 'Gudule::Bot' );
}

diag( "Testing Gudule $Gudule::Server::VERSION, Perl $], $^X" );
