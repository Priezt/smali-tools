#!/usr/bin/env perl

use FindBin;
use lib $FindBin::Bin;
use Smali;

$dir = shift @ARGV;
die "need directory" unless -d $dir;
@files = `find $dir`;
for(@files){
	chomp;
	my $cluster = Smali::get_cluster($_);
	map {
		$merged_cluster->{$_} = 1;
	} keys %$cluster;
}
for(sort keys %$merged_cluster){
	print $_."\n";
}
