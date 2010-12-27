#!/usr/bin/env perl

use Test::More tests => 2;

BEGIN {
    use_ok('URI::Escape');
    use_ok( 'App::ZofCMS::Plugin::CurrentPageURI' );
}

diag( "Testing App::ZofCMS::Plugin::CurrentPageURI $App::ZofCMS::Plugin::CurrentPageURI::VERSION, Perl $], $^X" );
