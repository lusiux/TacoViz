#!/usr/bin/perl

use strict;
use warnings;

use XML::Simple;
use Data::Dumper;

use FindBin;
use lib "$FindBin::Bin/inc";

use Map;
use Taco;

my $img = $ARGV[0];
my $calFile = $img;
$calFile .= ".cal.xml";

my $xmlFilename = $ARGV[1];
my $outFile = $ARGV[2];

my $taco = new Taco($xmlFilename);
my $cal = XMLin($calFile);

my $pois = $taco->getPOIs( { MapID => $cal->{mapId} } );
my $map = new Map($cal->{mapId}, $img, $cal->{center}->{x}, $cal->{center}->{y}, $cal->{stretch}->{x}, $cal->{stretch}->{y});

foreach my $poi ( @$pois ) {
	$map->addPOI($poi);
}

$map->writeToFile($outFile);
