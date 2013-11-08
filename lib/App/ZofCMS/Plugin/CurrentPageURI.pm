package App::ZofCMS::Plugin::CurrentPageURI;

use warnings;
use strict;
our $VERSION = '0.0102';

use URI::Escape;

sub new { bless {}, shift }

sub process {
    my ( $self, $t, $q, $config ) = @_;

    my %conf = (
        prefix          => '',
        protocol        => 'http://',
        is_mod_rewrite  => 1,
        quiet_index     => 1,
        %{ delete $config->conf->{plug_current_page_uri} || {} },
        %{ delete $t->{plug_current_page_uri}     || {} },
    );
    
    $conf{protocol} = $conf{protocol}->( $t, $q, $config )
        if ref $conf{protocol} eq 'CODE';
    
    my $original_page = $q->{page};
    $original_page = ''
        if $original_page eq 'index' and $conf{quiet_index};

    my $q_page = ($q->{dir} || '') . ($original_page || '');
    my @q_args = map uri_escape($_), 
        grep { $_ ne 'dir' and $_ ne 'page' } sort keys %$q;

    my $q_string = join '&', map "$_=" . uri_escape( $q->{$_} ), @q_args;

    my %uris;
    if ( $conf{is_mod_rewrite} ) {

        %uris = (
            page    => $q_page,
            page_q  => $q_page
                . ( length($q_string) ? '?' . $q_string : '' ),
        );
    }
    else {
        %uris = (
            page    => '/index.pl?page=' . uri_escape($q_page),
            page_q  => '/index.pl?page=' . uri_escape($q_page)
                . ( length($q_string) ? '&' . $q_string : '' ),
        );
    }
    
    $uris{page_full} = join '', $conf{protocol},
        @ENV{ qw/SERVER_NAME  REQUEST_URI/ };

    $uris{"$conf{prefix}$_"} = delete $uris{$_}
        for keys %uris;

    @{ $t->{t} }{ keys %uris } = values %uris;
}

1;

__END__

=encoding utf8

=head1 NAME

App::ZofCMS::Plugin::CurrentPageURI - ZofCMS plugin to automatically add current page URI into templates

=head1 SYNOPSIS

In your L<HTML::Template> template:

    <tmpl_var escape='html' name='page'>
    <tmpl_var escape='html' name='page_q'>
    <tmpl_var escape='html' name='page_full'>

In your ZofCMS Template:

    plugins => [ qw/CurrentPageURI/ ],

If current page's URI is C<http://zcms/?text=lalala>, the results are:

    /
    /?text=lalala
    http://zcms/?text=lalala

Optional configuration (defaults are shown):

    plug_current_page_uri => {
        prefix          => '',
        protocol        => 'http://',
        is_mod_rewrite  => 1,
        quiet_index     => 1,
    },

=head1 DESCRIPTION

The module is a ZofCMS plugin that provides means to stuff your
L<HTML::Template> template (or more accurately your C<{t}> special key)
with three variables that are representations of the current page's
webroot-relative URI, webroot-relative URI with query parameters
attached, and finally the full URI (with the protocol, domain name,
and query parameters).

This documentation assumes you've read
L<App::ZofCMS>, L<App::ZofCMS::Config> and L<App::ZofCMS::Template>

=head1 FIRST-LEVEL ZofCMS TEMPLATE KEYS

=head2 C<plugins>

    plugins => [ qw/CurrentPageURI/ ],

First and obvious, you need to stick C<CurrentPageURI> in the list of
your plugins. B<NOTE: plugin will STILL run even if>
C<plug_current_page_uri> B<is not specified> (in that case,
all default values will be assumed).

=head2 C<plug_current_page_uri>

    # default values are shown
    plug_current_page_uri => {
        prefix          => '',
        protocol        => 'http://',
        is_mod_rewrite  => 1,
        quiet_index     => 1,
    },

B<Optional>. Takes a hashref as a value that specifies plugin's
configuration. Can be specified either in Main Config file,
ZofCMS Template, or both, in which case all values will be
congregated into one hashref with values in ZofCMS Template
taking precedence. If not specified, all the defaults will be assumed.
Possible keys/values are as follows:

=head3 C<prefix>

    plug_current_page_uri => {
        prefix => '',
    ...
    
    plug_current_page_uri => {
        prefix => 'la_page_',
    ...

B<Optional>. Takes a string as a value that specifies the prefix
to use for the C<< <tmpl_var> >> variables
(see HTML::Template VARIABLES section below). For example,
by default C<page_q> variable is set to the current page plus
query. If we set C<prefix> to value C<la_page_>, then C<la_page_page_q>
will be set to original C<page_q>'s value. B<Defaults to:> C<''>
(empty string) 

=head3 C<protocol>

    plug_current_page_uri => {
        protocol => 'http://',
    ...

    plug_current_page_uri => {
        protocol => sub {
            my ( $t, $q, $config ) = @_;
            return 'http://';
        },
    ...

B<Optional>. Takes a string that contains the protocol to prepend to
C<page_full> variable (see below) or a subref that returns such a
string. If subref is specified, its C<@_> array will contain:
C<$t>, C<$q>, C<$config> (in that order) where C<$t> is ZofCMS Template
hashref, C<$q> is the query parameter hashref and C<$config> is the
L<App::ZofCMS::Config> object. B<Defaults to:> C<http://>

=head3 C<is_mod_rewrite>

    plug_current_page_uri => {
        is_mod_rewrite => 1,
    ...

B<Optional>. Takes either true or false values. If set to a true value,
the plugin will assume that you're using Apache's C<mod_rewrite>
to rewrite your URIs into a clean form, thusly: C</foo?bar=ber>
to internally become C</index.pl?page=/foo&bar=ber>. If set to a false
value, plugin will create fully blown URIs with C<index.pl> in them.
B<Defaults to:> C<1>

=head3 C<quiet_index>

    plug_current_page_uri => {
        quiet_index => 1,
    ...

B<Optional>. Takes either true or false values. If set to a true value,
plugin will rename pages called C<index> to empty string. In other
words, while normally webroot URI would result in query parameter
C<< $q->{page} >> set to value C<index> and the plugin spitting out
the URI as C</index>; when C<quiet_index> is turned on, the plugin will
modify it to C</> (without the C<index> part). Note: this does B<NOT>
modify the value in the query parameters hashref; the change is 
local to the plugin. B<Defaults to:> C<1>

=head1 HTML::Template VARIABLES

    <tmpl_var escape='html' name='page'>
    <tmpl_var escape='html' name='page_q'>
    <tmpl_var escape='html' name='page_full'>

If current page's URI is C<http://zcms/?text=lalala> and all the
defaults are used, the output will be:

    /
    /?text=lalala
    http://zcms/?text=lalala

Plugin adds three variables into C<{t}> ZofCMS Template special key,
for you to use in your L<HTML::Template> Template. Below their
default names are shown; plugin's argument C<prefix> specifies the
string to prepend to these default names. Examples show output
when current page's URI is C<http://zcms/?text=lalala>.

=head2 C<page>

    <tmpl_var escape='html' name='page'>

    Output: /

This variable will contain the current page's URI relative to
web-root and query parameters omitted.

=head2 C<page_q>

    <tmpl_var escape='html' name='page_q'>

    Output: /?text=lalala

This variable will contain the current page's URI relative to
web-root with all query parameters appended. The query parameters
will be escaped using L<URI::Escape>.

=head2 C<page_full>

    <tmpl_var escape='html' name='page_full'>

    Output: http://zcms/?text=lalala

This variable will contain the current page's full URI all query
parameters appended. B<Note:> this variale will actually be
derived from C<%ENV>, thus the query escapes might be less strict
as they won't be done by this plugin.

=head1 REQUIRED MODULES

This plugin needs L<URI::Escape> version 3.29 or greater.

=head1 AUTHOR

Zoffix Znet, C<< <zoffix at cpan.org> >>
(L<http://zoffix.com/>, L<http://haslayout.net/>,
L<http://mind-power-book.com/>)

=head1 BUGS

Please report any bugs or feature requests to C<bug-app-zofcms-plugin-currentpageuri at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=App-ZofCMS-Plugin-CurrentPageURI>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc App::ZofCMS::Plugin::CurrentPageURI

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=App-ZofCMS-Plugin-CurrentPageURI>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/App-ZofCMS-Plugin-CurrentPageURI>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/App-ZofCMS-Plugin-CurrentPageURI>

=item * Search CPAN

L<http://search.cpan.org/dist/App-ZofCMS-Plugin-CurrentPageURI/>

=back


=head1 LICENSE AND COPYRIGHT

Copyright 2010 Zoffix Znet.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut
