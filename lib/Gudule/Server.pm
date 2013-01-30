package Gudule::Server;

use warnings;
use strict;
require Exporter;

use Bot::BasicBot::Pluggable;
use Data::Dumper;
use Gudule::Config;
use Gudule::Util qw( daemonize detach write_pid );
use IO::Handle;
use IO::Select;
use POSIX;

=head1 NAME

Gudule::Server - Gudule IRC botserver

=head1 VERSION

Version 3.01

=cut

our $VERSION = '3.01';

=head1 SYNOPSIS

Start a Gudule IRC botserver.

    use Gudule::Server;

    my $server = Gudule::Server->server();
    $server->run; 

=cut

our @ISA = qw( Exporter );
our %EXPORT_TAGS = ( all => [ qw( ) ] );
our @EXPORT_OK   = ( @{ $EXPORT_TAGS{all} } );
our @EXPORT      = qw();

my $bots = {};
$| = 1;

=head1 FUNCTIONS

=over

=item C<< server >>

Returns Gudule::Server object.

=cut

my $server;

sub server {
    my $pkg = shift;
    return $server ||= bless {}, $pkg;
}

=item C<< run >>

Start the server.

=cut

sub run {
    my $self = shift;
    
    Gudule::Config->load;

    my $dbpath  = Gudule->config( '', 'dbpath' );

    daemonize if Gudule->config( '', 'daemon' );
    write_pid;
    
    foreach my $srv ( Gudule->srvlist ) {
        my $pid = spawn_bot($srv);
    }

    $0 .= ' [Master]'; 

    # Trap signals
    $SIG{HUP} = sub {
        Gudule->log("Reloading configuration");
        Gudule::Config->load;
    };

    # Prepare to read logs from kids
    my $socks = IO::Select->new();
    foreach my $pid ( keys %{ $bots } ) {
        $socks->add($bots->{$pid}->{fh});
    }

    while (1) {
        # Get logs
        foreach my $pid ( keys %{ $bots } ) {
            my ($log) = IO::Select->new($bots->{$pid}->{fh})
                                  ->can_read(0.05);
            next unless $log;
            my $srv = $bots->{$pid}->{srv};
            my $buf = <$log>;
            Gudule->log("$srv - $buf") if ($buf);
        }

        # Verify that all bots are alive
        foreach my $srv ( Gudule->srvlist ) {
            if ( !defined bot_is_alive($srv) ) {
                spawn_bot($srv);
            }
        }

        select(undef, undef, undef, 0.05) # Sleep 50ms
    }
}

sub bot_is_alive {
    my $srv = shift;
    foreach my $pid (keys %{ $bots }) {
        next if ( $srv ne $bots->{$pid}->{srv} );
        my $kid = waitpid($pid, WNOHANG);
        if ($kid < 0) {
            delete $bots->{$pid};
            return undef;
        }
        return 1;
    }
    return undef;
}

sub spawn_bot {
    my $srv = shift;

    Gudule->log("Spawning a bot on $srv");

    my ( $server, $port ) = split( /:/, $srv );
    my $dsn = 'dbi:SQLite:'. Gudule->config($srv, 'dbpath') .
              'gudule-'. $server .'.sqlite';

    my $bot = new Bot::BasicBot::Pluggable (
        server    => $server,
        port      => $port,
        nick      => Gudule->config($srv, 'nickname'),
        alt_nicks => Gudule->config($srv, 'altnicks'),
        username  => Gudule->config($srv, 'username'),
        name      => Gudule->config($srv, 'realname'),
        channels  => Gudule->config($srv, 'channels'),
        store     => {
            type  => 'DBI',
            dsn   => $dsn,
            table => 'basicbot',
        },
    );

    my $modules = Gudule->config($srv, 'modules');

    # Test if each module can be loaded
    foreach my $m ( split( /\n/, $modules ) ) {

        my $ret = eval { $bot->load( $m ); };

        if ( $@ ) {
            Gudule->log("Error loading $m ($@)");

            my $n;
            foreach my $mod ( split( /\n/, $modules ) ) {
                $n .= "$mod\n" if ( $mod ne $m );
            }

            Gudule::Config->set_conf($srv, 'modules', $n);
            Gudule->log("$m has been disabled");
            
            $bot->DESTROY;

            return undef;
        } else {
            Gudule->log("Loaded module $m");
        }
    }

    my ($pid, $fh) = detach( \$bot );

    $bots->{$pid}->{srv} = $srv;
    $bots->{$pid}->{fh}  = $fh; # Logging fh
    $bots->{$pid}->{ts}  = time;

    Gudule->log("Bot spawned, running as PID $pid");

    return $pid;
}

package Gudule;
use Data::Dumper;
use Gudule::Config qw( config srvlist set_conf );
use Sys::Syslog qw( :standard :macros );

sub log {
    shift;
    my $level = LOG_INFO;
    $level    = shift if @_ == 2;
    my $msg   = shift;
    chomp $msg;
    $msg .= "\n";

    my $ident = $0;
    my $opts  = 'ndelay, pid';
    my $facility = LOG_DAEMON;
    my $logto = Gudule->config('', 'log');

    if ( Gudule->config('', 'daemon') eq 0 ) {
        print POSIX::strftime('%D, %T', localtime) .' '. $msg;
        return;
    } elsif ( $logto eq 'syslog' ) {
        openlog( $ident, $opts, $facility );
        syslog( $level, $msg );
        return closelog();
    } elsif ( -w $logto ) {
        open( LOG, ">>$logto" );
        print LOG $msg;
        return;
    } else {
        die "ERROR: Cannot write to $logto";
    }

    return;
}

sub status {
    my $status = shift;
    my @name   = split(/ /, $0);
    my $bname  = $name[0];
    $0 = $bname .' ['. $status .']';
    return;
}

=back

=head1 AUTHOR

Guillaume Blairon, C<< <g at yom.be> >>

=head1 BUGS

Please report any to Guillaume Blairon C<< <g at yom.be> >>

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Gudule::Server

=head1 COPYRIGHT & LICENSE

Copyright 2009 Guillaume Blairon, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of Gudule::Server
