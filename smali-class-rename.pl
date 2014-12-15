#!/usr/bin/env perl

use FindBin;
use lib $FindBin::Bin;
use Smali;
use Data::Dumper;

$old_class = shift @ARGV or die "need old class name";
$new_class = shift @ARGV or die "need new class name";
Smali::rename_class($old_class, $new_class);
