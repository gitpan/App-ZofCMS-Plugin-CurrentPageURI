use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'App::ZofCMS::Plugin::CurrentPageURI',
    license             => 'perl',
    dist_author         => q{Zoffix Znet <zoffix@cpan.org>},
    dist_version_from   => 'lib/App/ZofCMS/Plugin/CurrentPageURI.pm',
    build_requires => {
        'Test::More' => 0,
    },
    build_recommends => {
        'App::ZofCMS::Test::Plugin' => 0.0104,
    },
    requires => {
        'URI::Escape' => 3.29,
    },
    add_to_cleanup      => [ 'App-ZofCMS-Plugin-CurrentPageURI-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
