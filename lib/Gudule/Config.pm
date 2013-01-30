package Gudule::Config;

use warnings;
use strict;

use Carp;
use Config::Std;
use Data::Dumper;
use Getopt::Long;
use Pod::Usage;

=head1 NAME

Gudule::Config - Config handlers for Gudule::Server.

=head1 VERSION

Version 3.01

=cut

our $VERSION = '3.01';

our @ISA       = qw( Exporter );
our @EXPORT    = qw( load config srvlist set_conf );
our @EXPORT_OK = qw( );

my %conf;

our (
    %cfgfile,
    %cmdline,
    %servers,
    $config,
    $help,
    $man
);

=head1 SYNOPSIS

This module is used by Gudule::Server to set its configuration from
command line or configuration files. 

=head1 EXPORT

The C<load> and C<config> functions are exported.

=head1 FUNCTIONS

=over

=item C<< load >>

Load config defaults from (in order of precedence) :
1 - Command line
2 - Configuration file
3 - Hardcoded values

=cut

sub load {
    GetOptions (
        "c|config=s"   => \$cmdline{config},
        "n|nick=s"     => \$cmdline{nickname},
        "a|altnick=s@" => \$cmdline{altnicks},
        "u|username=s" => \$cmdline{username},
        "r|realname=s" => \$cmdline{realname},
        "m|module=s@"  => \$cmdline{modules},
        "dbpath=s"     => \$cmdline{dbpath},
        "pidpath=s"    => \$cmdline{pidpath},
        "daemon!"      => \$cmdline{daemon},
        "h|help"       => \$help,
        "man"          => \$man,
    ) or pod2usage(2);

    pod2usage(1) if $help;
    pod2usage(-exitstatus => 0, -verbose => 2) if $man;

    # Default config
    $config = choose_conf( '', 'config'  , '/etc/gudule.conf' );

    my %c;
    read_config $config => %c # Needed @ reload, 2nd arg must be empty
      if ( -e $config && -r $config );
    %cfgfile = %c; 

    choose_conf( '', 'nickname', 'gudule' );
    choose_conf( '', 'altnicks', "gudule_\ngud" );
    choose_conf( '', 'username', 'gudule v' . $VERSION );
    choose_conf( '', 'realname', 'gudule' );
    choose_conf( '', 'modules' , "Loader\nAuth" );
    choose_conf( '', 'dbpath'  , '/var/lib/gudule' );
    choose_conf( '', 'pidpath' , '/var/run/gudule' );
    choose_conf( '', 'daemon'  , 1 );
    choose_conf( '', 'log'     , 'syslog' );

    my $dbpath  = config('', 'dbpath');
    my $pidpath = config('', 'pidpath');
    die "ERROR: cannot write to $dbpath"  unless (-w  $dbpath);
    die "ERROR: cannot write to $pidpath" unless (-w $pidpath);

    # Load servers config
    foreach my $srv (keys %cfgfile) {
        next if ($srv eq '');
        server_conf( $srv, $cfgfile{$srv} );
    }

    Gudule->log("Loaded config");

    return;
}

=item C<< choose_conf($section, $name, $default) >>

Set default config from command line, or config file, or supplied
default, in that order.

=cut

sub choose_conf {
    my ( $section, $name, $default ) = @_;

    return set_conf( $section, $name, $cmdline{$name} )
      if defined $cmdline{$name};

    return set_conf( $section, $name, $cfgfile{''}{$name} )
      if defined $cfgfile{''}{$name};

    return set_conf( $section, $name, $default );
}

=item C<< server_conf($server, $config_hashref) >>

Set up config for given server, using supplied config or defaults.

=cut

sub server_conf {
    my ( $srv, $cfg_href ) = @_;

    # Set defaults, ensuring nothing will be undefined.
    set_conf( $srv, 'nickname', config('', 'nickname') );
    set_conf( $srv, 'altnicks', config('', 'altnicks') );
    set_conf( $srv, 'username', config('', 'username') );
    set_conf( $srv, 'realname', config('', 'realname') );
    set_conf( $srv, 'modules',  config('', 'modules')  );
    set_conf( $srv, 'dbpath',   config('', 'dbpath')  );
    
    # Then use supplied config
    foreach my $k (keys %{ $cfg_href }) {
        set_conf( $srv, $k, $cfg_href->{$k} );
    }
}

=item C<< set_conf($section, $key, $value) >>

The C<set_conf()> subroutine takes three arguments: the config section
('' for global settings, 'server:...' for server configs), the key, and
the value.

=cut

sub set_conf {
    shift if (scalar @_ == 4);
    my ( $s, $k, $v ) = @_;
    return $conf{$s}{$k} = $v;
}

=item C<< config($section, $key) >>

The C<config()> subroutine takes two arguments: the config section and
the key. It will return the associated value or undef.

=cut

sub config {
    shift if (@_ == 3);
    my ( $s, $k ) = @_;
#    die "No config variable '$k'" unless defined $conf{$k};
    return $conf{$s}{$k};
}

=item C<< srvlist() >>

The C<srvlist()> subroutine returns an array containing all configured
IRC servers.

=cut

sub srvlist {
    my @list;
    foreach my $k (keys %conf) {
        next if ( $k eq '' );
        push @list, $k;
    }
    return @list;
}

=back

=head1 AUTHOR

Guillaume Blairon, C<< <g at yom.be> >>

=head1 BUGS

Please report any to Guillaume Blairon C<< <g at yom.be> >>

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Gudule::Config

=head1 COPYRIGHT & LICENSE

Copyright 2009 Guillaume Blairon, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1; # End of Gudule::Config
