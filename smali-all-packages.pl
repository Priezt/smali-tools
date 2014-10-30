#!/usr/bin/env perl

use FindBin;
use lib $FindBin::Bin;
use Smali;

for(Smali::get_all_packages()){
	print $_."\n";
}
