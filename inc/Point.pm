package Point;

use strict;
use warnings;

sub new {
	my ($class,$x,$y) = @_;

	my $self = {
		x => $x,
		y => $y,
	};

	return bless $self, $class;
}

sub toString {
	my $self = shift;
	return sprintf "(%.02f, %.02f)", $self->{x}, $self->{y};
}

sub getX {
	my $self = shift;
	return $self->{x};
}

sub getY {
	my $self = shift;
	return $self->{y};
}

sub length {
	my $self = shift;

	return abs((($self->getX() ** 2 + $self->getY() ** 2) ** 0.5));
}

sub dist {
	my $p1 = shift;
	my $p2 = shift;

	return abs((($p1->getX() - $p2->getX()) ** 2 + ($p1->getY() - $p2->getY()) ** 2) ** 0.5);
}

sub sub {
	my $p1 = shift;
	my $p2 = shift;

	$p1->{x} -= $p2->{x};
	$p1->{y} -= $p2->{y};
}

sub diff {
	my $p1 = shift;
	my $length = shift;

	$p1->{x} /= $length;
	$p1->{y} /= $length;
}

sub mult {
	my $p1 = shift;
	my $length = shift;

	$p1->{x} *= $length;
	$p1->{y} *= $length;
}

1;
