#!/usr/bin/env perl

use FindBin;
use lib $FindBin::Bin;
use Smali;

for my $root_package(@ARGV){
	my $cluster = Smali::get_cluster($root_package);
	map {
		$merged_cluster->{$_} = 1;
	} keys %$cluster;
}
for(sort keys %$merged_cluster){
	print $_."\n";
}
