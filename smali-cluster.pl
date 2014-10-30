#!/usr/bin/env perl

use FindBin;
use lib $FindBin::Bin;
use Smali;

$| = 1;
$root_package = shift @ARGV;

$cluster = Smali::get_cluster($root_package);

for(sort keys %$cluster){
	print $_."\n";
}
