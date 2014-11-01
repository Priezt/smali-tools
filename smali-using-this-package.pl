#!/usr/bin/env perl

use FindBin;
use lib $FindBin::Bin;
use Smali;

for(Smali::used_by(shift @ARGV)){
	print;
	print "\n";
}
