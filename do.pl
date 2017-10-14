#!/usr/bin/perl

use strict;
use warnings;

use XML::Simple;
use Data::Dumper;

#my $xml = XMLin("tw_pof_adv_refugeesupplyrun.xml");
my $xml = XMLin("bones.xml");

my $pois = $xml->{POIs}->{POI};

#print Dumper $pois;

my $maps = {
	1210 => {
		height => 1500,
		width => 3000,
	},
};

# 625x648 = "-731.879" "-96.8578"
# 1295x508 = "705.271" "202.643"
# 1469x774 = "1080.6" "-367.688"

my $T = [
	{
		x => -731.879,
		y => -96.8578,
	},
	{
		x => 705.271,
		y => 202.643,
	},
];

my $M = [
#	{
#		x => 565,
#		y => 616,
#	},
#	{
#		x => 1235,
#		y => 477,
#	},
	{
		x => 270,
		y => 632,
	},
	{
		x => 1375,
		y => 401,
	},
];

sub getCenterX {
	my $T0 = shift;
	my $T1 = shift;
	my $M0 = shift;
	my $M1 = shift;

	#return ( ($T1->{x} * $M0->{x}) - ($T0->{x} * $M1->{x}) ) / ($T1->{x} - $T0->{x});
	return ( ($T1->{x} * $M0->{x}) - ($T0->{x} * $M1->{x}) ) / ($T1->{x} - $T0->{x});

}

sub getCenterY {
	my $T0 = shift;
	my $T1 = shift;
	my $M0 = shift;
	my $M1 = shift;

	return (( $T1->{y} * $M0->{y}) - ( $T0->{y} * $M1->{y}) ) / ($T1->{y} - $T0->{y});
}

my $centerX = getCenterX( @$T, @$M );
my $centerY = getCenterY( @$T, @$M );

printf "Center X: $centerX\n";
printf "Center Y: $centerY\n";

sub getStretchX {
	my $center = shift;
	my $T = shift;
	my $M = shift;

	return ($M->{x} - $center) / $T->{x};
}

sub getStretchY {
	my $center = shift;
	my $T = shift;
	my $M = shift;

	return ($centerY - $M->{y}) / ( - 1 * $T->{y} );
}

my $stretchX = getStretchX( $centerX, $T->[0], $M->[0] );
my $stretchY = getStretchY( $centerY, $T->[0], $M->[0] );

printf "Stretch X: $stretchX\n";
printf "Stretch Y: $stretchY\n";

my $cmd;

my $count = 200;
foreach my $poi ( @$pois ) {
	if ( ! defined $poi->{iconFile} ) {
		$poi->{iconFile} = 'Data/gn_pof_60.png';
	}
	printf "%s: %fx%f\n", $poi->{iconFile}, $poi->{xpos}, $poi->{zpos};

	my $x = ($poi->{xpos}+$maps->{$poi->{MapID}}->{width}/2)/ $maps->{$poi->{MapID}}->{width} * 1414;
	my $y = 692 - ($poi->{zpos}+$maps->{$poi->{MapID}}->{height}/2) / $maps->{$poi->{MapID}}->{height} * 692;

	$x = $centerX + $poi->{xpos} * $stretchX;
	#$x = 1920 - $x - 106 - 34/2;
	$x = $x - 34/2;
	$y = $centerY + $poi->{zpos} * $stretchY;
#	$y = 1080 - $y;
	$y -= 34/2;

	printf "%s: %fx%f\n", $poi->{iconFile}, $x, $y;
	$poi->{iconFile} =~ s/\\/\//g;

	$cmd .= sprintf " -page \"+%d+%d\" %s ", $x, $y, $poi->{iconFile};
	$count --;
	if ( $count == 0 ) {
		last;
	}
}

# convert Gebleichte-Knochen-2.jpg -page "+162+529" gn_pof_4.png -layers merge +repage out.jpg

#		<POI MapID="1210" xpos="-234.784" ypos="58.9271" zpos="667.127" type="gn_guides.gn_zone.gn_bones" GUID="OzWG87RLKk+XXv+yHzZT0Q==" iconFile="Data\gn_pof_7.png"/>
#		<POI MapID="1210" xpos="-378.923" ypos="56.4267" zpos="556.319" type="gn_guides.gn_zone.gn_bones" GUID="N/I0buW9JEqFW0weqNXNRg==" iconFile="Data\9.png"/>
#		<POI MapID="1210" xpos="-493.468" ypos="-9.51488" zpos="-515.28" type="gn_guides.gn_zone.gn_bones" GUID="nHq/UTychEC77to0dNdU2A==" iconFile="Data\gn_pof_3.png"/>
#		<POI MapID="1210" xpos="-1249.92" ypos="-33.046" zpos="-212.745" type="gn_guides.gn_zone.gn_bones" GUID="kR/u91QBT0CNkqNV01VSJQ==" iconFile="Data\gn_pof_2.png"/>
#		<POI MapID="1210" xpos="-850.558" ypos="13.7489" zpos="303.926" type="gn_guides.gn_zone.gn_bones" GUID="yPDfP+fosUuEx8dqqSRqLg==" iconFile="Data\gn_pof_5.png"/>
#		<POI MapID="1210" xpos="-937.639" ypos="46.6894" zpos="363.215" type="gn_guides.gn_zone.gn_bones" GUID="JUXFcCDL0kyhhWYwx37UTA==" iconFile="Data\gn_pof_6.png"/>
#		<POI MapID="1210" xpos="-1092.69" ypos="38.3123" zpos="469.563" type="gn_guides.gn_zone.gn_bones" GUID="FM/XPhgLDEG0AT6Wc1OPcw==" iconFile="Data\gn_pof_8.png"/>
#		<POI MapID="1210" xpos="-501.463" ypos="33.8878" zpos="422.131" type="gn_guides.gn_zone.gn_bones" GUID="NrOeoVIDHkCMVs6tkcfbgw==" iconFile="Data\gn_pof_10.png"/>
#		<POI MapID="1210" xpos="291.663" ypos="58.8759" zpos="514.348" type="gn_guides.gn_zone.gn_bones" GUID="x9hcfMt33kyVZzt1+N0u/Q==" iconFile="Data\gn_pof_15.png"/>
#		<POI MapID="1210" xpos="1025.06" ypos="100.002" zpos="46.5524" type="gn_guides.gn_zone.gn_bones" GUID="3ZT4g4pYV0uEGu6TM7IS7g==" iconFile="Data\gn_pof_20.png"/>
#		<POI MapID="1210" xpos="285.763" ypos="4.25085" zpos="-351.313" type="gn_guides.gn_zone.gn_bones" GUID="DjIPun9TBUGgm6PW7P9vIw==" iconFile="Data\gn_pof_13.png"/>
#		<POI MapID="1210" xpos="172.656" ypos="80.164" zpos="-155.588" type="gn_guides.gn_zone.gn_bones" GUID="QTjJ13zxHUmvVRH1ibiZpg==" iconFile="Data\gn_pof_12.png"/>
#		<POI MapID="1210" xpos="-1231.48" ypos="14.6279" zpos="-598.258" type="gn_guides.gn_zone.gn_bones" GUID="z5SA/kngKEipK6hkI3fLow==" iconFile="Data\gn_pof_4.png"/>
#		<POI MapID="1210" xpos="-897.145" ypos="87.9447" zpos="18.604" type="gn_guides.gn_zone.gn_bones" GUID="UTQUJ5BLt0SRcdf/iXIAJw==" iconFile="Data\gn_pof_1.png"/>
#		<POI MapID="1210" xpos="553.256" ypos="278.755" zpos="333.342" type="gn_guides.gn_zone.gn_bones" GUID="JGSt2upePkeAabLmed/91w==" iconFile="Data\gn_pof_18.png"/>
#		<POI MapID="1210" xpos="572.397" ypos="146.824" zpos="195.986" type="gn_guides.gn_zone.gn_bones" GUID="L9Sf3Xug/0WTcfm7lpC/5Q==" iconFile="Data\gn_pof_19.png"/>
#		<POI MapID="1210" xpos="482.655" ypos="69.9016" zpos="14.8764" type="gn_guides.gn_zone.gn_bones" GUID="D4e8ij8ibkWinxiYB9VcEg==" iconFile="Data\gn_pof_11.png"/>
printf "convert 1210.jpg %s -layers merge +repage out.jpg\n", $cmd;


