package Smali;

use Cwd;
use Data::Dumper;
use File::Slurp;

our $SMALI_DUMP_FILENAME = "smali-map.txt";
our $SMALI_LOG_FILENAME = "smali-log.txt";
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
		my $dump_filename = get_smali_dir()."/../".$SMALI_DUMP_FILENAME;
		unless(-e $dump_filename){
			cache_smali_map();
		}
		open DUMPFILE,"<",$dump_filename;
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
	system("mv '$path' '$backup_path'");
	clear_empty_dir($path);
}

sub copy_smali{
	my $old_package_name = format_package_name(shift);
	my $new_package_name = format_package_name(shift);
	my $old_path = get_path_by_package($old_package_name);
	my $new_path = get_path_by_package($new_package_name);
	make_dir($new_path);
	system("cp '$old_path' '$new_path'");
}

sub change_prefix{
	my $old_prefix = shift;
	my $new_prefix = shift;
	for my $package_to_be_modified (get_all_packages()){
		my $old_name = $package_to_be_modified;
		next unless $old_name =~ /^$old_prefix/;
		my $new_name = $old_name;
		$new_name =~s /^$old_prefix/$new_prefix/;
		print $old_name." -> ".$new_name."\n";
		copy_smali($old_name, $new_name);
		remove_one_smali($old_name);
	}
	for my $package_to_be_modified (get_all_packages()){
		change_prefix_for_one_file($old_prefix, $new_prefix, $package_to_be_modified);
	}
}

sub rename_smali{
	my $old_package_name = format_package_name(shift);
	my $target_prefix = shift;
	my $target_dir = get_smali_dir()."/".$target_prefix."/";
	my $new_surfix = $old_package_name;
	$new_surfix =~s /\//_/g;
	my $new_package_name = $target_prefix."/".$new_surfix;
	copy_smali($old_package_name, $new_package_name);
	remove_one_smali($old_package_name);
	for my $package_to_be_modified (get_all_packages()){
		replace_one_file($old_package_name, $new_package_name, $package_to_be_modified);
	}
}

sub change_prefix_for_one_file{
	my $old_prefix = shift;
	my $new_prefix = shift;
	my $target_smali_package = format_package_name(shift);
	my $filename = get_path_by_package($target_smali_package);
	my $content = read_file($filename);
	$content =~s /L$old_prefix/L$new_prefix/g;
	write_file($filename, $content);
}

sub replace_one_file{
	my $old_package_name = format_package_name(shift);
	my $new_package_name = format_package_name(shift);
	my $target_smali_package = format_package_name(shift);
	my $filename = get_path_by_package($target_smali_package);
	my $content = read_file($filename);
	$content =~s /L$old_package_name;/L$new_package_name;/g;
	write_file($filename, $content);
}

sub smali_class{
	my $package_name = format_package_name(shift);
	my $filename = get_path_by_package($package_name);
	my $sf= {
		package_name => $package_name,
		filename => $filename,
	};
	open SMALI_FILE,"<",$filename;
	while(<SMALI_FILE>){
		chomp;
		if(/^\.super\s+L(.+);/){
			$sf->{super} = $1;
		}elsif(/^\.implements\s+L(.+);/){
			$sf->{implements} = [] unless $sf->{implements};
			push @{$sf->{implements}}, $1;
		}elsif(/^\.field\s+.*\b(\w+)\:(.+)/){
			$sf->{fields} = {} unless $sf->{fields};
			$sf->{fields}->{$1} = $2;
		}elsif(/^\.method\s+[^\(]*\s+(\S+\(\S+)/){
			$sf->{methods} = [] unless $sf->{methods};
			push @{$sf->{methods}}, $1;
		}
	}
	close SMALI_FILE;
	return $sf;
}

sub log{
	my $msg = shift;
	my $log_file = get_smali_dir()."/".$SMALI_LOG_FILENAME;
	append_file($log_file, $msg."\n");
}

sub rename_class{
	my $old_class = format_package_name(shift);
	my $new_class = format_package_name(shift);
	Smali::log("rename class: $old_class ==> $new_class");
	copy_smali($old_class, $new_class);
	remove_one_smali($old_class);
	for my $package_to_be_modified (get_all_packages()){
		replace_one_file($old_class, $new_class, $package_to_be_modified);
	}
}

sub rename_method{
	my $class = format_package_name(shift);
	my $method = shift;
	my $new_name = shift;
	Smali::log("rename method: L$class;->$method ==> $new_name");
	$method =~ /^([^\(]+)(\(.+)$/;
	my $old_name = $1;
	my $signature_part = $2;
	my $new_method = $new_name.$signature_part;
	my $fn = get_path_by_package($class);
	my $content = read_file($fn);
	$content =~s /(\.method\s+[^\r\n]*\s+)\Q$method\E($|[\r\n\s])/$1.$new_method.$2/eg;
	write_file($fn, $content);
	for my $package_to_be_modified (get_all_packages()){
		my $target_package_name = format_package_name($package_to_be_modified);
		my $target_filename = get_path_by_package($target_package_name);
		my $content = read_file($target_filename);
		$content =~s /(L\Q$class\E;->)\Q$method\E($|[\r\n\s])/$1.$new_method.$2/ge;
		write_file($target_filename, $content);
	}
}

1;

