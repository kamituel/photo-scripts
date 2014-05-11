#!/usr/bin/perl -w
use strict;
use File::Basename;

#### CONFIG ####

$|++;

my $CONVERT_PARAMS = '-resize 1950x1950\> -quality 65';
my $MENCODER_PARAMS_NEX = '-ovc lavc  -lavcopts vcodec=mpeg4:mbd=2:trell -vf scale=640:360,harddup -ofps 25 -oac copy -really-quiet';
my $MENCODER_PARAMS_IPHONE = '-ovc lavc  -lavcopts vcodec=mpeg4:mbd=2:trell -vf scale=640:360,harddup -ofps 25 -oac pcm -really-quiet';

# List known files along with command to convert them.
# If files of other types are found in the $SOURCE_DIR,
# execution will be aborted.
my %FILE_TYPES = (
	"jpg", qq(convert "__INPUT__" $CONVERT_PARAMS "__OUTPUT__"),
	"mts", qq(mencoder "__INPUT__" -o "__OUTPUT_avi_" $MENCODER_PARAMS_NEX),
	"mov", qq(mencoder "__INPUT__" -o "__OUTPUT_avi_" $MENCODER_PARAMS_IPHONE),
	"mpg", qq(mencoder "__INPUT__" -o "__OUTPUT_avi_" $MENCODER_PARAMS_IPHONE),
	"avi", qq(mencoder "__INPUT__" -o "__OUTPUT_avi_" $MENCODER_PARAMS_IPHONE),
	"mp4", qq(mencoder "__INPUT__" -o "__OUTPUT_avi_" $MENCODER_PARAMS_IPHONE),
	"3gp", qq(mencoder "__INPUT__" -o "__OUTPUT_avi_" $MENCODER_PARAMS_IPHONE),
	"wav", qq(lame --abr 192 "__INPUT__" "__OUTPUT__"),
#	"cr2", undef,		we do not tolerate RAW files. Those are supposed to be placed in _raw subdirectory
#	"arw", undef
);

my $BASE_DIR = "/Users/kls/Desktop/Volumes/seagate/zdjecia";

# Directory where raw files are kept. This directory will not be modified.
my $INPUT_DIR = $BASE_DIR . "/raw";

# Output directory.
my $OUTPUT_DIR = $BASE_DIR . "/medium";

#### CODE ####

die "Directory $INPUT_DIR does not exist.\n" unless ( -d $INPUT_DIR );
die "Directory $OUTPUT_DIR does not exist.\n" unless ( -d $OUTPUT_DIR );

my $pattern = shift;

my $count_dirs = 0;
my $count_files = 0;

# Validation
print "Validating source folder ($INPUT_DIR)...\n";
print "Pattern: $pattern\n" if defined $pattern;
my $validate_result = iterate_over_dir(
	sub { 
		my $dir = shift;
		print "\r  $dir                                               ";

		# Skip directory if it's name does not match the pattern
		if ( defined $pattern and length($pattern) > 0 and not ($dir =~ /$pattern/i) ) {
			return 0;
		}

		# Abort unless destination dir exists or can be created.
		my $out = "$OUTPUT_DIR/$dir";
	 	return "Output dir $dir cannot be created.\n" unless ( -d $out or mkdir $out );

		$count_dirs++;

		return undef;
	},
	sub {
		my ($dir, $file) = @_;

		# Check if file is a directory
  		unless (-f $INPUT_DIR."/".$dir."/".$file) {
			unless ( $file eq "_raw" ) {
    				return "$dir/$file is not a regular file, can not process\n";
			} else {
				return undef;
			}
  		}

		# Check if file is of a known type
		my ($extension) = $file =~ /\.([^.]+)$/;
  		unless ( exists($FILE_TYPES{lc($extension)}) ) {
   			return "$dir/$file: unknown type\n";
  		}

		$count_files++;

		return undef;
	}
);

die "\n\n$validate_result\nFound errors, aborted." if length($validate_result) > 0;

print "\nProcessing files...\n";

my $count_dirs2 = 0;
my $count_files2 = 0;
my $total_input_size = 1;
my $total_output_size = 1;

# Processing
iterate_over_dir(
	sub {
		my $dir = shift;

		# Skip directory if it's name does not match the pattern
		if ( defined $pattern and length($pattern) > 0 and not ($dir =~ /$pattern/i) ) {
			return 0;
		}

		$count_dirs2++;

		return undef;
	}, 
	sub {
		my ($dir, $file) = @_;
		return undef if $file eq "_raw";
		my ($basename, $extension) = $file =~ /(.*)\.([^.]+)$/;
		my $cmd = $FILE_TYPES{lc($extension)};
		return undef unless defined $cmd;

		$extension = $1 if $cmd =~ /__OUTPUT_([^_\s]+)_/;

		# Do not process files that exist in output directory.
		return undef if -f "$OUTPUT_DIR/$dir/$basename.$extension";

		($cmd =~ s/__INPUT__/$INPUT_DIR\/$dir\/$file/g);
		($cmd =~ s/__OUTPUT_.*?_/$OUTPUT_DIR\/$dir\/$basename\.$extension/g);

		$count_files2++;
		print "\r  Dir [$count_dirs2/$count_dirs] $dir                                                  "; 
		print "\r\n  File [$count_files2/$count_files] $file                                              ";
		my $ratio = int(100*$total_output_size/$total_input_size);
		print "\r\n  Total size: input=".int($total_input_size/1024/1024)."MB output=".int($total_output_size/1024/1024)."MB ratio=$ratio%                                         ";
		print "\x1b[A";
		print "\x1b[A";
		`$cmd`;

		$total_input_size += -s "$INPUT_DIR/$dir/$file";
		$total_output_size += -s "$OUTPUT_DIR/$dir/$basename.$extension";

		return undef;
	}
);

###### SUBS #######

sub get_extension {
  my $filename = shift;
  ($filename =~ /.*\.(.*)/);
  return $1;
}

sub iterate_over_dir {
  my $on_dir_cbk = shift;			# Callback. Returns:
						#    undef (if ok),
						#    zero (if dir should be skipped)
						#    error message (script will abort).
  my $on_file_cbk = shift;

  my $ret = "";

  # Iterate over dirs (D) in ./
  opendir my $source, $INPUT_DIR or die "Could not list files in ".$INPUT_DIR;
  my @folders = readdir $source;

  foreach my $dir (@folders) {
	next if $dir =~ /^\./;

	my $dir_cbk_ret = $on_dir_cbk->($dir);
	if ( not defined $dir_cbk_ret ) {
        } elsif ( $dir_cbk_ret == 0 ) {
		next;
	} else {
		$ret .= $dir_cbk_ret;
		return $ret;
	}

	opendir my $folder, $INPUT_DIR."/".$dir or die "Could not list files in $INPUT_DIR/$dir\n";
	my @files = readdir $folder;
	foreach my $file (@files) {
		next if $file =~ /^\./;
		my $cbk_ret = $on_file_cbk->($dir, $file);
   		$ret .= $cbk_ret if defined $cbk_ret and length($cbk_ret) > 1;
	}
	closedir $folder;
  }

  closedir $source;
  return $ret;
}


