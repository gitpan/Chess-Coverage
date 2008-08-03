# $Id: Coverage.pm 900 2008-08-03 02:24:08Z gene $

package Chess::Coverage;
our $VERSION = '0.01';
use strict;
use warnings;
use Carp;
use base 'Chess::Rep';

sub coverage {
    my $self = shift;
    my %cover = ();
    my %name = (
        p => 'pawn',
        n => 'knight',
        b => 'bishop',
        r => 'rook',
        q => 'queen',
        k => 'king',
    );

    for my $row (0 .. 7) {
        for my $col (0 .. 7) {
            my $i = Chess::Rep::get_index($row, $col);
            my $p = $name{ $self->get_piece_at($row, $col) } || '';
            my $x = $self->piece_color($i);
            my $f = Chess::Rep::get_field_id($i);
            
            $cover{$f}{index} = $i;
            $cover{$f}{occupant} = ($x ? 'black' : 'white') . " $p" if $p;
            
            my $moves = $self->_get_allowed_moves($i) if $p;
            if ($moves && @$moves) {
                @$moves = map { Chess::Rep::get_field_id($_) } @$moves;
                $cover{$f}{move} = $moves;
            }   
            
            for my $color (0, 1) {
                if($self->is_attacked($i, $color)) {
                    $cover{$f}{ $x == $color ? 'protected' : 'threatened' } = 1;
                }   
            }   
        }   
    }

    return \%cover;
}

__END__

=head1 NAME

Chess::Coverage - Expose chess ply potential energy

=head1 SYNOPSIS

  use Chess::Coverage;
  $g = Chess::Coverage->new();
  $c = $g->coverage();
  use Data::Dumper; $Data::Dumper::Sortkeys=1; die Dumper($c);

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

Produce an image of the coverage.

=head1 SEE ALSO

L<Chess::Rep>

=head1 AUTHOR

Gene Boggs E<lt>gene@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2007-2008, Gene Boggs.

This code is licensed under the same terms as Perl itself.

=cut
