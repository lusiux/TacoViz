package Taco::POI;

use strict;
use warnings;

use Data::Dumper;
use XML::Simple;

use Point;

sub new {
	my ($class, $data, $categoryData) = @_;

	my $self = {
		data => $data,
	};

	my $retVal = bless $self, $class;
	$retVal->transformData($categoryData);

	return $retVal;
}

sub transformData {
	my $self = shift;
	my $categoryData = shift;

	$self->{category} = $self->{data}->{type};
	if ( ! defined $self->{category} ) {
		$self->{category} = '';
	}

	my $catData = $categoryData->{lc($self->getCategory())};
	if ( ! defined $categoryData->{lc($self->getCategory())} ) {
		$catData = $categoryData->{''};
	}
	foreach my $key ( keys %$catData ) {
		if ( ! defined $self->{data}->{$key} ) {
			$self->{data}->{$key} = $catData->{$key};
		}
	}

	$self->{mapId} = $self->{data}->{MapID};

	$self->{x} = $self->{data}->{xpos};
	$self->{y} = $self->{data}->{zpos};

	$self->{point} = new Point($self->{x}, $self->{y});

	$self->{icon} = $self->{data}->{iconFile};

	if ( scalar keys %$catData == 0 ) {
		print STDERR Dumper($categoryData);
		printf STDERR "No category data for %s\n", $self->toString();
		exit;
	}

	$self->{icon} =~ s/\\/\//g;
}

sub getX {
	my $self = shift;
	return $self->{x};
}

sub getY {
	my $self = shift;
	return $self->{y};
}

sub getCategory {
	my $self = shift;
	return $self->{category};
}

sub getMapId {
	my $self = shift;
	return $self->{mapId};
}

sub getIcon {
	my $self = shift;
	return $self->{icon};
}

sub getPoint {
	my $self = shift;
	return $self->{point};
}

sub toString {
	my $self = shift;
	return sprintf "(Taco::POI, %f, %f, %d, %s, %s)", $self->getX(), $self->getY(), $self->getMapId(), $self->getCategory(), $self->getIcon();
}

package Taco;

use strict;
use warnings;

use Data::Dumper;
use XML::Simple;

sub new {
	my ($class) = @_;

	my $self = {
		pois => [],
		categories => {
			'' => {
				iconFile => 'Data\bigmarker.png',
			},
		},
	};

	my $retVal = bless $self, $class;

	$retVal->addFile("categorydata.xml");

	return $retVal;
}

sub addPOIs {
	my $self = shift;
	my $poiData = shift;

	foreach my $poi ( @$poiData ) {
		my $tacoPoi = new Taco::POI($poi, $self->{categories});
		push @{$self->{pois}}, $tacoPoi;
	}
}

sub addRoute {
	my $self = shift;
	my $routeData = shift;

	foreach my $route ( @$routeData ) {
		if ( defined $route->{POI} ) {
			$self->addPOIs($route->{POI});
		}
	}
}

sub addFile {
	my $self = shift;
	my $filename = shift;

	my $xml = XMLin($filename, KeyAttr => { MarkerCategory => '+name' }, ForceArray => [ 'POIs', 'Route', 'POI', 'MarkerCategory' ]);

	genCategories($xml, $self->{categories});

	if ( ! defined $xml->{POIs} ) {
		return;
	}

	foreach my $pois ( @{$xml->{POIs}} ) {
		if ( defined $pois->{Route} ) {
			$self->addRoute($pois->{Route});
		}
		if ( defined $pois->{POI} ) {
			$self->addPOIs($pois->{POI});
		}
	}
}

sub dumpCategoryData {
	my $self = shift;
	print Dumper $self->{categories};
}



# TODO:
# POIs and Routes to data struct

#'MarkerCategory' => {
#	'DisplayName' => 'GuildNews Guides',
#	'name' => 'gn_guides'
#	'MarkerCategory' => {
#		'DisplayName' => 'Zonen',
#		'name' => 'gn_zone'
#		'MarkerCategory' => {
#			'iconFile' => 'Data\\gn_pof_60.png',
#			'DisplayName' => 'Seiten',
#			'name' => 'gn_pages'
#		},
#	},
#},

sub copyHash {
	my $from = shift;
	my $to = shift;

	foreach my $key ( keys %{$from} ) {
		#printf "$key: %s\n", ref($from->{$key});
		if ( $key eq 'name' ) {
			next;
		} elsif ( $key eq 'MarkerCategory' ) {
			next;
		} elsif ( $key eq 'DisplayName' ) {
			next;
		} elsif ( ref($from->{$key}) eq 'HASH' ) {
			next;
		}
		$to->{$key} = $from->{$key};
	}
}

sub traverseMarkerCategory {
	my $data = shift;
	my $catString = shift;
	my $props = shift;
	my $categories = shift;

	foreach my $name ( keys %$data ) {
		my $cat = $data->{$name};
		my $newCatstring = $catString . $cat->{name};
		my $newProps = {};
		copyHash($props, $newProps);
		copyHash($cat, $newProps);
		$categories->{lc($newCatstring)} = $newProps;

		if ( defined $cat->{MarkerCategory} ) {
			traverseMarkerCategory($cat->{MarkerCategory}, $newCatstring . '.' , $newProps, $categories);
		}
	}
}

sub genCategories {
	my $data = shift;
	my $categories = shift;

	my $catString = '';
	my $props = {
		iconFile => 'Data\bigmarker.png',
	};
	$categories->{''} = $props;

	if ( defined $data->{MarkerCategory} ) {
		traverseMarkerCategory($data->{MarkerCategory}, $catString, $props, $categories);
	}
}

sub getPOIs {
	my $self = shift;

	return $self->{pois};
}

1;
