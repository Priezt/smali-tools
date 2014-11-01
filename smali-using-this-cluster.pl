#!/usr/bin/env perl

use FindBin;
use lib $FindBin::Bin;
use Smali;

while(<>){
	chomp;
	$p->{$_} = 1;
}

for my $package_name (sort keys %$p){
	my @parents = Smali::used_by($package_name);
	if(~~@parents > 0){
		for my $parent (@parents){
			next if $p->{$parent};
			push @result, "$parent -> $package_name";
		}
	}
}

for(sort @result){
	print;
	print "\n";
}
