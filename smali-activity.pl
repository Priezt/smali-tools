#!/usr/bin/env perl

use FindBin;
use lib $FindBin::Bin;
use Smali;

print Smali::get_activity_name()."\n";
