package Gudule::Bot;

use warnings;
use strict;
use Bot::BasicBot::Pluggable;
use Carp;
use IO::Handle;
use Socket;

require Exporter;
our @ISA = qw( Exporter );
our %EXPORT_TAGS = ( 'all' => [ qw( ) ] );
our @EXPORT_OK   = ( @{ $EXPORT_TAGS{'all'} } );
our @EXPORT      = qw();

=head1 NAME

Gudule::Bot - Bot spawning functions for Gudule::Server.

=head1 VERSION

Version 3.01

=cut

our $VERSION = '3.01';


=head1 SYNOPSIS

    use Gudule::Bot;

    my $bot = Whatever::You::Want->new;
    Gudule::Bot->detach_run($bot);

=head1 FUNCTIONS

=over

=item C<< new >>

Create a new Gudule::Bot instance.

=cut

sub new {
    my ( $class, %args ) = @_;

    my @channels = split( /\n/, $args{channels} );
    my @altnicks = split( /\n/, $args{altnicks} );
    my @modules  = split( /\n/, $args{modules} );

    my $self = {
        server   => $args{server},
        nickname => $args{nickname},
        realname => $args{realname},
        username => $args{username},
        altnicks => \@altnicks,
        channels => \@channels,
        modules  => \@modules,
        dbpath   => $args{dbpath},
    };

    return bless ( $self, $class );
}


=back

=head1 AUTHOR

Guillaume Blairon, C<< <g at yom.be> >>

=head1 BUGS

Please report any to Guillaume Blairon C<< <g at yom.be> >>

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Gudule::Bot

=head1 COPYRIGHT & LICENSE

Copyright 2009 Guillaume Blairon, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of Gudule::Bot
