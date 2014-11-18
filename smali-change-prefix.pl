#!/usr/bin/env perl

use FindBin;
use lib $FindBin::Bin;
use Smali;

$old_prefix = shift @ARGV or die "need old prefix";
$new_prefix = shift @ARGV or die "need new prefix";

Smali::change_prefix($old_prefix, $new_prefix);
