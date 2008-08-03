# $Id: Coverage.pm 902 2008-08-03 06:45:35Z gene $

package Chess::Coverage;
our $VERSION = '0.02';
use strict;
use warnings;
use base 'Chess::Rep';

sub coverage {
    my $self = shift;

    my %cover = ();

    my %name = (
        0x01 => 'black pawn',
        0x02 => 'black knight',
        0x04 => 'black king',
        0x08 => 'black bishop',
        0x10 => 'black rook',
        0x20 => 'black queen',
        0x81 => 'white pawn',
        0x82 => 'white knight',
        0x84 => 'white king',
        0x88 => 'white bishop',
        0x90 => 'white rook',
        0xA0 => 'white queen',
    );

    for my $row (0 .. 7) {
        for my $col (0 .. 7) {
            my $i = Chess::Rep::get_index($row, $col);
            my $p = $name{ $self->get_piece_at($row, $col) } || '';
            my $f = Chess::Rep::get_field_id($i);

            $cover{$f}{index} = $i;

            my $moves = [];

            if ($p) {
                $cover{$f}{occupant} = $p;
                $moves = $self->_get_allowed_moves($i);
            }

            if (@$moves) {
                @$moves = map { Chess::Rep::get_field_id($_) } @$moves;
                $cover{$f}{move} = $moves;
            }

            for my $color (0, 0x80) {
                if($p && $self->is_attacked($i, $color)) {
                    my $c = $self->piece_color($i);
                    $cover{$f}{ $c == $color ? 'protected' : 'threatened' } = 1;;
                }
            }
        }
    }

    return \%cover;
}

1;

__END__

=head1 NAME

Chess::Coverage - Expose chess ply potential energy

=head1 SYNOPSIS

  use Chess::Coverage;
  $g = Chess::Coverage->new();
  $c = $g->coverage();

=head1 DESCRTIPTION

This module exposes the "potential energy" of a chess ply by returning
a hash reference of the board positions, pieces and their "attack
status."

* This module was a lot more complicated and slower, in the past.
Modern chess packages have allowed me to vastly simplify this (to a
single method, actually).

* Previous versions of this module B<listed> the board positions that
threatened or protected a given position.  This module does the
reverse (for the moment) and shows if positions are threatened or
protected with a simple true value.

=head1 METHODS

=head2 new()

Return a new C<Chess::Coverage> object.

=head2 coverage()

Return a data structure, keyed on board position, showing

  occupant   => Human readable string of the piece name and color
  index      => The C<Chess::Rep/Position> board position index.
  move       => List of positions that are legal moves by the occupying piece
  protected  => True (1) if the occupying piece is protected by its own color
  threatened => True (1) if the occupying piece is threatened by the opponent

=head1 TO DO

Get C<Chess::Rep> patched to return the indices of the attackers.

Produce images and animations of the coverage.

=head1 SEE ALSO

L<Chess::Rep>

=head1 AUTHOR

Gene Boggs E<lt>gene@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2007-2008, Gene Boggs.

This code is licensed under the same terms as Perl itself.

=cut
