package Gudule::Util;

use warnings;
use strict;
use Socket;

use Carp qw( croak );

require Exporter;
our @ISA       = qw( Exporter );
our @EXPORT_OK = qw( daemonize detach write_pid );

=head1 NAME

Gudule::Util - Various utility functions for Gudule::Server

=cut

=head1 FUNCTIONS

=over

=item C<< daemonize >>

Detach from current terminal.

=cut

sub daemonize {
    my ( $pid, $sessid );
    # Fork and exit parent
    if ($pid = fork) { exit 0; }

    # Detach from current terminal
    croak "Cannot detach from terminal\n"
      unless $sessid = POSIX::setsid();

    # Prevent possibility of acquiring from a terminal
    $SIG{HUP} = 'IGNORE';
    if ($pid = fork) { exit 0; }

    chdir "/";
    umask 0;

    # Close FDs
    close(STDIN);
    close(STDOUT);
    close(STDERR);

    return $$;
}

=item C<< write_pid >>

Write the master PID in specified path.

=cut

sub write_pid {
    my $pid = $$;
    my $pidpath = Gudule->config('', 'pidpath');
    $pidpath = $pidpath . '/' if ($pidpath =~ m/[^\/]$/);
    my $pidname = $pidpath . 'gudule.pid';

    die "Error writing PID: $pidpath is not writable"
      if (!-w $pidpath);
    die "Error writing PID: cannot open $pidname"
      if ( (-e $pidname) && (!-w $pidname) );
    die "Error writing PID: cannot unlink $pidname"
      if ( (-e $pidname) && (!unlink $pidname) );

    open(PID, '>'.$pidname);
    print PID "$pid\n";
    close PID;
    
    return 1;
}

=item C<< detach >>

Fork given Bot::BasicBot::Pluggable object and run the bot, giving the
process to POE. After that, you're unlikely to take it back.

=cut

sub detach {
    my $botref = shift;
    my $bot = $$botref;

    my $parentpid = $$;
    my ($kidfh, $dadfh);
    socketpair($kidfh, $dadfh, AF_UNIX, SOCK_STREAM, PF_UNSPEC)
      or die "socketpair: $!";

    if (my $pid = fork) {
        close $dadfh;
        return ($pid, $kidfh); # Parent
    } else {
        close $kidfh;
        chdir "/";
        umask 0;

        close(STDIN);
        STDOUT->fdopen( $dadfh, 'w' ) or die $!;
        STDERR->fdopen( $dadfh, 'w' ) or die $!;
        STDOUT->autoflush(1);
        STDERR->autoflush(1);

        my ( $name, undef ) = split(/ /, $0);
        $0 = ' ['. $bot->{nick} .' @ '. $bot->{server} .']';

        $bot->run || print "$!\n";
    }

    return;
}

=back

=head1 AUTHOR

Guillaume Blairon, C<< <g at yom.be> >>

=head1 BUGS

Please report any to Guillaume Blairon C<< <g at yom.be> >>

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Gudule::Util

=head1 COPYRIGHT & LICENSE

Copyright 2009 Guillaume Blairon, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of Gudule::Util
