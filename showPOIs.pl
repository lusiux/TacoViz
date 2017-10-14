#!/usr/bin/perl

use strict;
use warnings;

use XML::Simple;
use Data::Dumper;

use FindBin;
use lib "$FindBin::Bin/inc";

use Taco;
use WorldMap;

my $xmlFilename = $ARGV[0];
my $basename = $xmlFilename;
$basename =~ s/\.xml.*$//;

my $xmlDir = $xmlFilename;
$xmlDir =~ s/[^\/]+$//;
if ( $xmlDir eq '' ) {
	$xmlDir = '.';
}

my $searchDirs = [
	$xmlDir,
	"$xmlDir/..",
	"$xmlDir/POIs",
	$FindBin::Bin,
];

my $map = new WorldMap();
$map->setSearchPath($searchDirs);

my $taco = new Taco($searchDirs);
$taco->addFile($xmlFilename);

foreach my $poi ( @{$taco->getPOIs()} ) {
	$map->addPOI($poi);
}

$map->writeToFile($basename);
