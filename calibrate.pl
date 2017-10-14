#!/usr/bin/perl

use strict;
use warnings;

use XML::Simple;
use Data::Dumper;

use PDL;
use PDL::Primitive;

use FindBin;
use lib "$FindBin::Bin/inc";

use Point;
use Map;
use Taco;
use Helper;

my $mapId = shift @ARGV;
my $img = shift @ARGV;

my $taco = new Taco();
$taco->addFile("WPs.xml");
my $pois = [];
foreach my $poi ( @{$taco->getPOIs()} ) {
	if ( $poi->getMapId() == $mapId ) {
		push @$pois, $poi;
	}
}
if ( scalar @$pois < 2 ) {
	print STDERR "Could not find any WPs for $mapId\n";
	exit 1;
}

# Steigung berechnen
my $T = [ sort { $a->getX() <=> $b->getX() } @$pois ];
my $Tasc = {};
for ( my $i = 0; $i < scalar @$T; $i++ ) {
	for ( my $j = $i+1; $j < scalar @$T; $j++ ) {
		my $p1 = new Point( $T->[$i]->{x}, $T->[$i]->{y} );
		my $p2 = new Point( $T->[$j]->{x}, $T->[$j]->{y} );

		my $ascend = -1 * Helper::calcAscend($p1, $p2);

		printf "TACO: %s -> %s: %f\n", $p1->toString(), $p2->toString(), $ascend;
		$Tasc->{$ascend} = [$p1, $p2];
	}
}

my $M = [];

foreach my $wp ( @ARGV ) {
	my ($x, $y) = split 'x', $wp;
	push @$M, { x => $x, y => $y };
}
$M = [ sort { $a->{x} <=> $b->{x} } @$M ];

for ( my $i = 0; $i < scalar @$M; $i++ ) {
	for ( my $j = $i+1; $j < scalar @$M; $j++ ) {
		my $p1 = new Point( $M->[$i]->{x}, $M->[$i]->{y} );
		my $p2 = new Point( $M->[$j]->{x}, $M->[$j]->{y} );

		my $ascend = Helper::calcAscend($p1, $p2);
		printf "IMAG: %s -> %s: %f\n", $p1->toString(), $p2->toString(), $ascend;
	}
}

my $PMap = [];
my $centers = {
	x => [],
	y => [],
};

for ( my $i = 0; $i < scalar @$M; $i++ ) {
	for ( my $j = $i+1; $j < scalar @$M; $j++ ) {
		my $ascend = ($M->[$i]->{y} - $M->[$j]->{y}) / ($M->[$i]->{x} - $M->[$j]->{x});
		my $neigh = Helper::getNeighbor($Tasc, $ascend);
		if ( $neigh->{error} > 0.1 ) {
			printf "Map point combination has no equivalent in Taco data; Absolute error %f\n", $neigh->{error};
			next;
		}
		my $pair = $neigh->{pair};
		my $centerX = Helper::getCenterX( $pair->[0], $pair->[1], $M->[$i], $M->[$j]);
		my $centerY = Helper::getCenterY( $pair->[0], $pair->[1], $M->[$i], $M->[$j]);

		push @$PMap, { T => $pair->[0], M => $M->[$i] } ,  { T => $pair->[1], M => $M->[$j] };
		push @{$centers->{x}}, $centerX;
		push @{$centers->{y}}, $centerY;
	}
}

my $piddle = pdl @{$centers->{x}};
my ($mean,$prms,$median,$min,$max,$adev,$rms) = statsover $piddle;
printf "Mean Center X: $mean with rms $rms\n";
my $centerX = sprintf "%s", $mean;

$piddle = pdl @{$centers->{y}};
($mean,$prms,$median,$min,$max,$adev,$rms) = statsover $piddle;
printf "Mean Center Y: $mean with rms $rms\n";
my $centerY = sprintf "%s", $mean;

my $stretchs = {
	x => [],
	y => [],
};

foreach my $pair ( @$PMap ) {
	my $stretchX = Helper::getStretchX( $centerX, $pair->{T}, $pair->{M} );
	my $stretchY = Helper::getStretchY( $centerY, $pair->{T}, $pair->{M} );

	push @{$stretchs->{x}}, $stretchX;
	push @{$stretchs->{y}}, $stretchY;
}

$piddle = pdl @{$stretchs->{x}};
($mean,$prms,$median,$min,$max,$adev,$rms) = statsover $piddle;
printf "Mean Stretch X: $mean with rms $rms\n";
my $stretchX = sprintf "%s", $mean;

$piddle = pdl @{$stretchs->{y}};
($mean,$prms,$median,$min,$max,$adev,$rms) = statsover $piddle;
printf "Mean Stretch Y: $mean with rms $rms\n";
my $stretchY = sprintf "%s", $mean;

my $data = {
	center => {
		x => $centerX,
		y => $centerY,
	},
	stretch => {
		x => $stretchX,
		y => $stretchY,
	},
	mapId => $mapId,
	M => $M,
};

open CAL, "> $img.cal.xml" or die $!;
print CAL XMLout($data);
close CAL;

# instance Map object and add known WPs
my $map = new Map($mapId, $img, $centerX, $centerY, $stretchX, $stretchY);
$map->setSearchPath( [ $FindBin::Bin ] );
foreach my $pair ( @$PMap ) {
	$map->addImage('Data/cal.png', $pair->{T}->{x}, $pair->{T}->{y});
}

$map->writeToFile("$img.cal.jpg");

exit 0;
