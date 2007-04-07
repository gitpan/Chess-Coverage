# $Id: Coverage.pm,v 1.29 2007/04/07 22:59:02 gene Exp $

package Chess::Coverage;
our $VERSION = '0.00_2';
use strict;
use warnings;
use Carp;
use base 'Chess::Game';

sub coverage {
    my $self = shift;
    my $board = $self->get_board();
    my $cover = {};

    for my $piece ( @{ $self->get_pieces() } ) {
        my $square = $piece->get_current_square();
        my $player = $piece->get_player();

        $cover->{$square}{occupant} = whoami( $piece );

        my @reachable = $piece->reachable_squares();
        for my $i ( @reachable ) {
            if( $self->_move_allowed( $square, $i ) ) {
                push @{ $cover->{$square}{can_move_to} }, $i;
            }
            else {
                my $p = $board->get_piece_at( $i ) || next;
                if( $self->_line_of_sight( $square, $i ) ) {
                    if( $p->get_player() eq $player ) {
                        push @{ $cover->{$square}{protects} }, $i;
                    }
                    else {
                        push @{ $cover->{$square}{threatens} }, $i;
                        push @{ $cover->{$square}{can_move_to} }, $i;
                    }
                    push @{ $cover->{$square}{msg} },
                        whoami( $p ) .' - '. $self->get_message();
                }
            }
        }
    }

    return $cover;
}

sub _line_of_sight {
    # Lifted from Chess::Board to return 1 for adjacent pieces.
    my ($self, $sq1, $sq2) = @_;

    unless(Chess::Board->square_is_valid($sq1)) {
        carp "'$sq1' is not a valid square";
        return undef;
    }
    unless(Chess::Board->square_is_valid($sq2)) {
        carp "'$sq2' is not a valid square";
        return undef;
    }
    croak "Invalid Chess::Board reference" unless (ref($self));
    return 1 if $$self == Chess::Board::IDX_EMPTY_BOARD;

    my ($x1, $y1) = Chess::Board::_get_square_coords($sq1);
    my ($x2, $y2) = Chess::Board::_get_square_coords($sq2);
    my $hdist = abs($x2 - $x1);
    my $vdist = abs($y2 - $y1);

# GB 2007.04.07 - Adjacent pieces are in each other's "line of sight."
    return 1 if ($hdist == 0 && $vdist == 1) || ($hdist == 1 && ($vdist == 1 || $vdist == 0));
#    return undef unless ($hdist == 0 || $vdist == 0 || $hdist == $vdist);

    my $hdelta = $hdist ? $hdist / ($x2 - $x1) : 0;
    my $vdelta = $vdist ? $vdist / ($y2 - $y1) : 0;
    my $xcurr = $x1;
    my $ycurr = $y1;
#warn"s1: ($x1, $y1), s2: ($x2, $y2), h/v dist: $hdist / $vdist, h/v delta: $hdelta / $vdelta\n";

    my $r_board_arr = Chess::Board::_get_board_array_ref($$self);

    croak "Invalid Chess::Board reference" unless (defined($r_board_arr));

    if (($hdist == 0) && ($hdist == $vdist)) {
        return 0 if (defined($r_board_arr->[$ycurr][$xcurr]{piece}));
        return 1;
    }

    while (($xcurr != $x2) || ($ycurr != $y2)) {
        return 0 if (defined($r_board_arr->[$ycurr][$xcurr]{piece}));
        $xcurr += $hdelta;
        $ycurr += $vdelta;
    }

    return 1;
}

sub _move_allowed {
    # Lifted from Chess::Game to ignore the "alternating turn" check.
    # XXX Not sure how to do all this legality checking, e.g. with
    # XXX a flag or resetting a value or something, so I copy-pasted:
    my ($self, $sq1, $sq2) = @_;
    unless (Chess::Board->square_is_valid($sq1)) {
    carp "Invalid square '$sq1'";
    return 0;
    }
    unless (Chess::Board->square_is_valid($sq2)) {
    carp "Invalid square '$sq2'";
    return 0;
    }
    croak "Invalid Chess::Game reference" unless (ref($self));
    my $obj_data = Chess::Game::_get_game($$self);
    croak "Invalid Chess::Game reference" unless ($obj_data);
    my $player1 = $obj_data->{players}[0];
    my $player2 = $obj_data->{players}[1];
    my $board = $obj_data->{board};
    my $piece = $board->get_piece_at($sq1);
    unless (defined($piece)) {
    carp "No piece at '$sq1'";
    return undef;
    }
    my $player = $piece->get_player();
# GB 2007.04.07 - Ignore whose turn it is for coverage analysis.
#    my $movelist = $obj_data->{movelist};
#    my $last_moved = $movelist->get_last_moved();
#    if ((defined($last_moved) and $last_moved eq $player) or
#    (!defined($last_moved) and $player ne $player1)) {
#    $obj_data->{message} = "Not your turn";
#    return 0;
#    }
    return 0 unless ($piece->can_reach($sq2));
    my $capture = $board->get_piece_at($sq2);
    if (defined($capture)) {
    unless ($capture->get_player() ne $player) {
        $obj_data->{message} = "You can't capture your own piece";
        return 0;
    }
    if ($piece->isa('Chess::Piece::Pawn')) {
        unless (abs(Chess::Board->horz_distance($sq1, $sq2)) == 1) {
        $obj_data->{message} = "Pawns may only capture diagonally";
        return 0;
        }
    }
    elsif ($piece->isa('Chess::Piece::King')) {
        unless (abs(Chess::Board->horz_distance($sq1, $sq2)) < 2) {
        $obj_data->{message} = "You can't capture while castling";
        return 0;
        }
    }
    }
    else {
    if ($piece->isa('Chess::Piece::Pawn')) {
        my $ml = $obj_data->{movelist};
        unless (Chess::Board->horz_distance($sq1, $sq2) == 0 or
                Chess::Game::_is_valid_en_passant($obj_data, $piece, $sq1, $sq2)) {
        $obj_data->{message} = "Pawns must capture on a diagonal move";
        return 0;
        }
    }
    }
    my $valid_castle = 0;
    my $clone = $self->clone();
    my $r_clone = Chess::Game::_get_game($$clone);
    my $king = $r_clone->{_kings}[($player eq $player1 ? 0 : 1)];
    if ($piece->isa('Chess::Piece::King')) {
    my $hdist = Chess::Board->horz_distance($sq1, $sq2);
    if (abs($hdist) == 2) {
        _mark_threatened_kings($r_clone);
        unless (!$king->threatened()) {
        $obj_data->{message} = "Can't castle out of check";
        return 0;
        }
        if ($hdist > 0) {
        return 0 unless (_is_valid_short_castle($obj_data, $piece, $sq1, $sq2));
        $valid_castle = Chess::Game::MOVE_CASTLE_SHORT;
        }
        else {
        return 0 unless (_is_valid_long_castle($obj_data, $piece, $sq1, $sq2));
        $valid_castle = Chess::Game::MOVE_CASTLE_LONG;
        }
    }
    }
    elsif (!$piece->isa('Chess::Piece::Knight')) {
    my $board_c = $board->clone();
    $board_c->set_piece_at($sq1, undef);
    $board_c->set_piece_at($sq2, undef);
    unless ($board_c->line_is_open($sq1, $sq2)) {
        $obj_data->{message} = "Line '$sq1' - '$sq2' is blocked";
        return 0;
    }
    }
    if (!$valid_castle) {
    $clone->make_move($sq1, $sq2, 0);
    Chess::Game::_mark_threatened_kings($r_clone);
    unless (!$king->threatened()) {
        $obj_data->{message} = "Move leaves your king in check";
        return 0;
    }
    }
    else {
    if ($valid_castle == Chess::Game::MOVE_CASTLE_SHORT) {
        my $tsq = Chess::Board->square_right_of($sq1);
            $clone->make_move($sq1, $tsq, 0);
        Chess::Game::_mark_threatened_kings($r_clone);
        unless (!$king->threatened()) {
        $obj_data->{message} = "Can't castle through check";
        return 0;
        }
        $clone->make_move($tsq, $sq2, 0);
        Chess::Game::_mark_threatened_kings($r_clone);
        unless (!$king->threatened()) {
        $obj_data->{message} = "Move leaves your king in check";
        return 0;
        }
    }
    else {
        my $tsq = Chess::Board->square_left_of($sq1);
        $clone->make_move($sq1, $tsq, 0);
        Chess::Game::_mark_threatened_kings($r_clone);
        unless (!$king->threatened()) {
        $obj_data->{message} = "Can't castle through check";
        return 0;
        }
        $clone->make_move($tsq, $sq2, 0);
        Chess::Game::_mark_threatened_kings($r_clone);
        unless (!$king->threatened()) {
        $obj_data->{message} = "Move leaves your king in check";
        return 0;
        }
    }
    }
    $obj_data->{message} = '';
    return 1;
}

sub _whoami {
    my $piece = shift;
    my $square = $piece->get_current_square();
    my $name = ref $piece;
    $name =~ s/^(?:\w+::)+(.*)$/lc($1)/e;
    return wantarray
        ? ( $square, $piece->get_player(), $name )
        : join ' ', $square, $piece->get_player(), $name;
    
}

__END__

=head1 NAME

Chess::Coverage - Visualize the potential energy between chess moves

=head1 SYNOPSIS

  use Chess::Coverage;
  $g = Chess::Coverage->new();
  $c = $g->coverage();
  use Data::Dumper; $Data::Dumper::Sortkeys=1; die Dumper($c);

=head1 DESCRTIPTION

This is a B<vastly> simplified rewrite of the old
C<Games::Chess::Coverage> modules based on the new C<Chess> module.

=head1 METHODS

=head2 new

Return a new C<Chess::Coverage> object which inherits from the
C<Chess> module.

=head1 TO DO

Almost everything...

$i = $g->image();    # get the image object

$g->draw();          # vizualize the board

=head1 SEE ALSO

L<Chess>

=head1 AUTHOR

Gene Boggs E<lt>gene@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2007, Gene Boggs Licensed under the same terms as Perl itself.

=cut
