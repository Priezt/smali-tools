package Smali;

use Cwd;
use Data::Dumper;

our $SMALI_DUMP_FILENAME = "smali-map.txt";
our $cluster = {};
our $map_cache = 0;

sub get_cluster{
	my $root_package = shift;
	$cluster = {};
	load_map_cache();
	search_component_tree($root_package);
	return $cluster;
}

sub load_map_cache{
	unless($map_cache){
		open DUMPFILE,"<",get_smali_dir()."/../".$SMALI_DUMP_FILENAME;
		my $content = join "", <DUMPFILE>;
		close DUMPFILE;
		my $VAR1;
		eval($content);
		$map_cache = $VAR1;
	}
	return $map_cache;
}

sub used_by{
	my $package_name = format_package_name(shift);
	my $rh_map = load_map_cache();
	return sort keys %{$rh_map->{$package_name}->{parents}};
}

sub cache_smali_map{
	my @packages = get_all_packages();
	my $rh_needed = {map {($_, 1)} @packages};
	my $rh_map = {};
	for my $p (@packages){
		$rh_map->{$p} = {
			'children' => {},
			'parents' => {},
		};
	}
	for my $p (@packages){
		my @children = get_all_components($p);
		for my $c (@children){
			if($rh_needed->{$c} and $p ne $c){
				$rh_map->{$p}->{children}->{$c} = 1;
				$rh_map->{$c}->{parents}->{$p} = 1;
			}
		}
	}
	open DUMPFILE,">",get_smali_dir()."/../".$SMALI_DUMP_FILENAME;
	print DUMPFILE Dumper($rh_map);
	close DUMPFILE;
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
	if($map_cache){
		return sort keys %{$map_cache->{$package_name}->{children}};
	}{
		my $fn = get_path_by_package($package_name);
		open F,"<",$fn;
		my $code = "";
		while(<F>){
			next if /^\s*\#/;
			$code .= $_;
		}
		close F;
		my $p = {};
		my @packages = ($code =~ /L([\w\/\$]+);/g);
		for(@packages){
			next if /^android\//;
			next if /^java\//;
			next if /^dalvik\//;
			$p->{$_} = 1;
		}
		return sort keys %$p;
	}
}

sub get_smali_dir{
	my $current_dir = cwd();
	die "Not in a smali directory" unless $current_dir =~ /\bsmali\b/;
	my $smali_dir = $current_dir;
	$smali_dir =~s /\bsmali\b.*$/smali/;
	return $smali_dir;
}

sub get_smali_backup_dir{
	my $current_dir = cwd();
	die "Not in a smali directory" unless $current_dir =~ /\bsmali\b/;
	my $smali_dir = $current_dir;
	$smali_dir =~s /\bsmali\b.*$/smali/;
	$smali_dir =~s /smali$/smali-backup/;
	return $smali_dir;
}
sub get_path_by_package{
	my $package_name = shift;
	return get_smali_dir()."/".$package_name.".smali";
}

sub get_backup_path_by_package{
	my $package_name = shift;
	return get_smali_backup_dir()."/".$package_name.".smali";
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

sub make_dir{
	my $dir = shift;
	$dir =~s /\/[^\/]*$//;
	system("mkdir -p $dir");
}

sub clear_empty_dir{
	my $dir = shift;
	$dir =~s /\/[^\/]*$//;
	while(`ls $dir | wc -l` == 0){
		system("rmdir $dir");
		$dir =~s /\/[^\/]*$//;
	}
}

sub remove_one_smali{
	my $package_name = format_package_name(shift);
	my $path = get_path_by_package($package_name);
	my $backup_path = get_backup_path_by_package($package_name);
	make_dir($backup_path);
	#print("mv $path $backup_path\n");
	system("mv $path $backup_path");
	clear_empty_dir($path);
}

1;

