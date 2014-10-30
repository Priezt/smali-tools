#!/usr/bin/env perl

use FindBin;
use lib $FindBin::Bin;
use Smali;

my $root_package = shift @ARGV or die "Need root package name";
Smali::remove_cluster($root_package);
