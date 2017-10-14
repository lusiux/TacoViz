package WorldMap;

use strict;
use warnings;

use XML::Simple;

use Map;

sub new {
	my ($class) = @_;

	my $self = {
		maps => {},
		failedMaps => {},
		searchDirs => [],
	};

	return bless $self, $class;
}

sub setSearchPath {
	my $self = shift;
	$self->{searchDirs} = shift;
}

sub addPOI {
	my $self = shift;
	my $poi = shift;

	if ( defined $self->{failedMaps}->{$poi->getMapId()} ) {
		return 1;
	}

	if ( ! defined $self->{maps}->{$poi->getMapId()} ) {
		if ( $self->openMap($poi->getMapId()) ) {
			return 2;
		}
	}

	$self->{maps}->{$poi->getMapId()}->addPOI($poi);
	return 0;
}

sub writeToFile {
	my $self = shift;
	my $basename = shift;

	foreach my $mapId ( keys %{$self->{maps}} ) {
		$self->{maps}->{$mapId}->writeToFile("${basename}.${mapId}.jpg");
	}
}

sub openMap {
	my $self = shift;
	my $mapId = shift;

	my $img = "maps/$mapId.jpg";
	my $calFile = $img . ".cal.xml";
	if ( ! -e $img || ! -e $calFile ) {
		$self->{failedMaps}->{$mapId} = 1;
		print STDERR "No map or calibration data for $mapId available\n";
		return 1;
	}

	my $cal = XMLin($calFile);
	my $map = new Map($cal->{mapId}, $img, $cal->{center}->{x}, $cal->{center}->{y}, $cal->{stretch}->{x}, $cal->{stretch}->{y});
	$map->setSearchPath($self->{searchDirs});
	$self->{maps}->{$mapId} = $map;
	return 0;
}

sub getMap {
	my $self = shift;
	my $mapId = shift;

	return $self->{maps}->{$mapId};
}

sub formGroups {
	my $self = shift;

	foreach my $mapId ( keys %{$self->{maps}} ) {
		my $map = $self->{maps}->{$mapId};
		$map->formGroups(@_);
	}
}

1;
