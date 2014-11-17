#!/usr/bin/env perl

use FindBin;
use lib $FindBin::Bin;
use Smali;

$original_smali = shift @ARGV or die "need smali package name";
$target_prefix = shift @ARGV or die "need target prefix";

Smali::rename_smali($original_smali, $target_prefix);
