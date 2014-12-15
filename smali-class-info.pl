#!/usr/bin/env perl

use FindBin;
use lib $FindBin::Bin;
use Smali;
use Data::Dumper;

$pn = shift @ARGV or die "need package name";
print Dumper(Smali::smali_class($pn));
