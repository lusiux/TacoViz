package Helper;

use strict;
use warnings;

sub getNeighbor {
	my $data = shift;
	my $search = shift;

	my $min;
	my $pair;
	foreach my $asc ( sort { $a <=> $b } keys %$data ) {
		my $diff = abs($search - $asc);
		if ( ! defined $min ) {
			$min = $diff;
			$pair = $data->{$asc};
		} elsif ( $diff < $min ) {
			$min = $diff;
			$pair = $data->{$asc};
		}
	}

	return { pair => $pair, error => $min };
}

sub getCenter {
	my $T0 = shift;
	my $T1 = shift;
	my $M0 = shift;
	my $M1 = shift;
	my $k = shift;

	return ( ($T1->{$k} * $M0->{$k}) - ($T0->{$k} * $M1->{$k}) ) / ($T1->{$k} - $T0->{$k});
}

sub getCenterX {
	return getCenter(@_, 'x');
}

sub getCenterY {
	return getCenter(@_, 'y');
}

sub getStretch {
	my $center = shift;
	my $T = shift;
	my $M = shift;
	my $k = shift;

	return ($M->{$k} - $center) / $T->{$k};
}

sub getStretchX {
	return getStretch(@_, 'x');
}

sub getStretchY {
	return getStretch(@_, 'y');
}

sub calcAscend {
	my $p1 = shift;
	my $p2 = shift;

	return ($p1->{y} - $p2->{y}) / ($p1->{x} - $p2->{x});
}

sub findFile {
	my $filename = shift;
	my $dirs = shift;

	foreach my $dir ( @{$dirs} ) {
		my $filePath = "$dir/$filename";
		if ( -e $filePath ) {
			return $filePath;
		}
	}

	printf STDERR "Looking for %s in (%s) failed\n", $filename, (join (',', @{$dirs}));
	return undef;
}


1;
