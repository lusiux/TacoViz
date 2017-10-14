package Map;

use strict;
use warnings;

use Math::ConvexHull qw/convex_hull/;

use Image::Size;
use Point;
use Helper;

sub new {
	my ($class,$mapId, $filename, $centerX,$centerY,$stretchX, $stretchY) = @_;

	my $self = {
		mapId => $mapId,
		filename => $filename,
		center => {
			x => $centerX,
			y => $centerY,
		},
		stretch => {
			x => $stretchX,
			y => $stretchY,
		},
		pois => [],
		groups => [],
		cmd => ['convert', $filename],
		searchDirs => [],
	};

	return bless $self, $class;
}

sub setSearchPath {
	my $self = shift;

	$self->{searchDirs} = shift;
}

sub addImage {
	my $self = shift;
	my $img = shift;
	my $x = shift;
	my $y = shift;
	my $poi = shift;

	my $imgPath = Helper::findFile($img, $self->{searchDirs});
	if ( ! defined $imgPath ) {
		printf STDERR "Can't find file for %s\n", $poi->getIcon();
		exit 1;
	}
	if ( ! -e $imgPath ) {
		printf STDERR "Image for %s is not available\n", $poi->toString();
		exit 1;
	}
	my ($width, $height) = imgsize($imgPath);

	my $resize = 0;
	if ( $width > 70 ) {
		$height = $height * (32/$width);
		$width = 32;
		$resize = 1;
	}

	# Generate small version of img with stretch

	$x = $self->{center}->{x} + $x * $self->{stretch}->{x};
	$x -= ($width/2);
	$y = $self->{center}->{y} + $y * $self->{stretch}->{y};
	$y -= ($height/2);

	if ( $resize ) {
		push @{$self->{cmd}}, '(', $imgPath, '-resize', (sprintf "%dx%d", $width, $height), ')';
	} else {
		push @{$self->{cmd}}, $imgPath;
	}
	push @{$self->{cmd}}, '-geometry', (sprintf "+%d+%d", $x, $y), '-composite';
}

sub addPOI {
	my $self = shift;
	my $poi = shift;

	push @{$self->{pois}}, $poi;
}

sub stretch {
	my $self = shift;
	my $coord = shift;

	return $coord * $self->{stretch}->{x};
}

sub stretchXY {
	my $self = shift;
	my $coord = shift;
	my $dir = shift;

	return $self->{center}->{$dir} + $coord * $self->{stretch}->{$dir};
}

sub drawCircle {
	my $self = shift;
	my $centerX = $self->stretchXY(shift, 'x');
	my $centerY = $self->stretchXY(shift, 'y');
	my $radius = $self->stretch(shift);
	my $borderY = $centerY+$radius;

	push @{$self->{cmd}}, '-fill', 'transparent', '-stroke', 'white', '-strokewidth', 1, '-draw', "circle $centerX,$centerY $centerX,$borderY";
}

sub drawBox {
	my $self = shift;
	my $min = shift;
	my $max = shift;

	$min->{x} = int($self->stretchXY($min->{x}, 'x'));
	$min->{y} = int($self->stretchXY($min->{y}, 'y'));
	$max->{x} = int($self->stretchXY($max->{x}, 'x'));
	$max->{y} = int($self->stretchXY($max->{y}, 'y'));

	push @{$self->{cmd}}, '-fill', 'rgba(255,0,0,0.2)', '-draw', "rectangle $min->{x},$min->{y} $max->{x},$max->{y}";
	#push @{$self->{cmd}}, '-crop', (sprintf "%dx%d+%dx%d", $min->{x}, $min->{y}, $max->{x}, $max->{y}), '+repage';
}

sub drawPolygon {
	my $self = shift;
	my $points = shift;

	my $centerX = 0;
	my $centerY = 0;
	foreach my $point ( @$points ) {
		$centerX += $point->[0];
		$centerY += $point->[1];
	}

	$centerX /= scalar @$points;
	$centerY /= scalar @$points;

	#$self->addImage('Data/bigmarker.png', $centerX, $centerY);

	my $c = new Point($centerX, $centerY);
	foreach my $point ( @$points ) {
		my $p1 = new Point($point->[0], $point->[1]);
		$p1->sub($c);
		$p1->diff($p1->length());
		$p1->mult(50);

		$point->[0] += $p1->{x};
		$point->[1] += $p1->{y};
	}

	my $polygon = "polygon";
	foreach my $point ( @$points ) {
		$polygon .= sprintf " %d,%d", $self->stretchXY($point->[0],'x'), $self->stretchXY($point->[1],'y');
	}

	push @{$self->{cmd}}, '-fill', 'rgba(0,255,0,0.3)', '-draw', $polygon;
}

sub writeToFile {
	my $self = shift;
	my $outFile = shift;

	foreach my $poi ( @{$self->{pois}} ) {
		$self->addImage($poi->getIcon(), $poi->getX(), $poi->getY(), $poi);
	}

	foreach my $group ( @{$self->{groups}} ) {
		$self->drawBox($group->{box}->{min}, $group->{box}->{max});
		$self->drawPolygon($group->{hull});
		foreach my $poi ( @{$group->{pois}} ) {
			$self->addImage($poi->getIcon(), $poi->getX(), $poi->getY(), $poi);
			#$self->drawCircle($poi->getX(), $poi->getY(), $group->{distance});
		}
	}


	push @{$self->{cmd}}, '-layers', 'merge', '+repage', $outFile;
	#print join ' ', @{$self->{cmd}};
	#print "\n";
	system @{$self->{cmd}};
}

sub formGroups {
	my $self = shift;
	my $distance = shift;
	my $minGroupSize = shift;

	my $lones = [];
	my $pois = [ @{$self->{pois}} ];
	while ( scalar @$pois ) {
		my $poi = shift @$pois;

		my ($group, $others) = getNext($poi, $pois, $distance);

		if ( scalar @$group < $minGroupSize ) {
			push @$lones, @$group;
			next;
		} else {
			push @{$self->{groups}}, {
				pois => $group,
				distance => $distance,
			};
		}

		$pois = $others;
	}

	foreach my $group ( @{$self->{groups}} ) {
		$group->{box} = boundingBox($group->{pois});
		$group->{hull} = hull($group->{pois});
	}
}

sub getNext {
	my $point = shift;
	my $pois = shift;
	my $dist = shift;
	my $group;

	my $others = [ @$pois ];
	my $toProccess = [ $point ];

	while ( scalar @{$toProccess} ) {
		my $p1 = shift @$toProccess;
		push @$group, $p1;

		my $visited = [];
		while ( scalar @{$others} ) {
			my $poi = shift @$others;

			if ( $poi->getPoint()->dist($p1->getPoint()) < $dist ) {
				push @$toProccess, $poi;
			} else {
				push @$visited, $poi;
			}
		}
		$others = $visited;
	}

	return ($group, $others);
}

sub boundingBox {
	my $points = shift;

	my $point = $points->[0];

	my $coords = {
		min => {
			x => $point->getX(),
			y => $point->getY(),
		},
		max => {
			x => $point->getX(),
			y => $point->getY(),
		},
	};

	foreach my $point ( @$points ) {
		if ( $point->getX() < $coords->{min}->{x} ) {
			$coords->{min}->{x} = $point->getX();
		} elsif ( $point->getX() > $coords->{max}->{x} ) {
			$coords->{max}->{x} = $point->getX();
		}

		if ( $point->getY() < $coords->{min}->{y} ) {
			$coords->{min}->{y} = $point->getY();
		} elsif ( $point->getY() > $coords->{max}->{y} ) {
			$coords->{max}->{y} = $point->getY();
		}
	}

	$coords->{min}->{x}-=50;
	$coords->{min}->{y}-=50;
	$coords->{max}->{x}+=50;
	$coords->{max}->{y}+=50;

	return $coords;
}

sub hull {
	my $pois = shift;
	my $points = [];

	foreach my $poi ( @{$pois} ) {
		push @$points, [$poi->getX(), $poi->getY()];
	}

	return convex_hull($points);
}

1;
