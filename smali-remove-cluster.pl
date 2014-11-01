#!/usr/bin/env perl

use FindBin;
use lib $FindBin::Bin;
use Smali;

while(<>){
	chomp;
	Smali::remove_one_smali($_);
}
