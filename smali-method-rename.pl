#!/usr/bin/env perl

use FindBin;
use lib $FindBin::Bin;
use Smali;
use Data::Dumper;

$class = shift @ARGV or die "need class name";
$method = shift @ARGV or die "need method";
$new_name = shift @ARGV or die "need new name";
Smali::rename_method($class, $method, $new_name);
