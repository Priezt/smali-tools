package Smali;

use Cwd;

our $cluster = {};

sub get_cluster{
	my $root_package = shift;
	$cluster = {};
	search_component_tree($root_package);
	return $cluster;
}

sub search_component_tree{
	my $parent = format_package_name(shift);
	#print $parent."\n";
	$cluster->{$parent} = 1;
	my @children = Smali::get_all_components($parent);
	for my $child (@children){
		next if $cluster->{$child};
		search_component_tree($child);
	}
}

sub format_package_name{
	my $pn = shift;
	$pn =~s /\.smali$//;
	$pn =~s /\./\//g;
	return $pn;
}

sub get_all_components{
	my $package_name = format_package_name(shift);
	my $fn = get_path_by_package($package_name);
	open F,"<",$fn;
	my $code = "";
	while(<F>){
		next if /^\s*\#/;
		$code .= $_;
	}
	close F;
	my @packages = ($code =~ /L([\w\/\$]+);/g);
	for(@packages){
		next if /^android\//;
		next if /^java\//;
		next if /^dalvik\//;
		$p->{$_} = 1;
	}
	return sort keys %$p;
}

sub get_smali_dir{
	my $current_dir = cwd();
	die "Not in a smali directory" unless $current_dir =~ /\bsmali\b/;

	my $smali_dir = $current_dir;
	$smali_dir =~s /\bsmali\b.*$/smali/;
	return $smali_dir;
}

sub get_path_by_package{
	my $package_name = shift;
	return get_smali_dir()."/".$package_name.".smali";
}

sub get_activity_name{
	open M,"<",get_manifest_path();
	my $content = join "", <M>;
	close M;
	die "Activity not found" unless $content =~ /<activity\s[^>]*\bandroid:name="([^"]+)"/i;
	my $activity = $1;
	$activity =~s /\./\//g;
	return $activity;
}

sub get_manifest_path{
	my $smali_dir = get_smali_dir();
	my $manifest = $smali_dir;
	$manifest =~s /\bsmali/AndroidManifest.xml/;
	return $manifest;
}

sub get_all_packages{
	my $smali_dir = get_smali_dir();
	my $find_output = `find $smali_dir -name '*.smali'`;
	return sort map {
		s/^.*\/smali\///;
		s/\.smali$//;
		$_;
	} grep {
		/./
	} split /[\r\n]+/, $find_output;
}

sub remove_cluster{
	my $package_name = format_package_name(shift);
	my $cluster = get_cluster($package_name);
	for(keys %$cluster){
		remove_one_smali($_);
	}
}

sub remove_one_smali{
	my $package_name = shift;
	my $path = get_path_by_package($package_name);
	return unless -f $path;
	my $parent = $path;
	$parent =~s /\/[^\/]*\.smali//;
	my $rm_command = "rm $path";
	system $rm_command;
	#print $rm_command."\n";
	unless(<$parent/*>){
		my $rmdir_command = "rmdir $parent";
		system $rmdir_command;
		#print $rmdir_command."\n";
	}
}

1;

