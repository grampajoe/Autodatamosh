#!/usr/bin/perl

# Autodatamosh script
# Copyright 2009, 2010 Joe Friedl <http://joefriedl.net>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>. 

use strict;
use warnings;

use Getopt::Long;

use File::Format::RIFF;
use Data::Dumper; # TEMPORARY, for testing


################
##            ##
##  DEFAULTS  ##
##            ##
################

# Use STDIN and STDOUT by default
open(our $infile,'<&STDIN');
open(our $outfile,'>&STDOUT');

my $infilename = '';
my $outfilename = '';

our $dprob = 0;	# P-frame duplication probability

our $dmin = 10;	# P-frame duplication minimum
our $dmax = 50; # P-frame duplication maximum



##############################
##                          ##
##  COMMAND LINE ARGUMENTS  ##
##                          ##
##############################

GetOptions(
	'i:s' => \$infilename,
	'o:s' => \$outfilename,
	'dmin:i' => \$dmin,
	'dmax:i' => \$dmax,
	'dprob:f' => \$dprob
);

# Ensure dmin is less than or equal to dmax
if ($dmin > $dmax)
{
	print STDERR "Warning: Duplication maximum is less than minimum. Using $dmin.\n";
	$dmax = $dmin;
}

# Attempt to open files if they were specified on the command line
if (length $infilename) { open($infile,'<',$infilename) or die("Could not open '".$infilename."': $!"); }
if (length $outfilename) { open($outfile,'>',$outfilename) or die("Could not open '".$outfilename."': $!"); }




#################
##             ##
##  THE MAGIC  ##
##             ##
#################

our $error = 0; # Error flag for the next section

our $istart = pack('H*','0001b0'); # I-frame marker


# Recursively reconstruct file
sub blowchunks
{
	my $data = shift;

	my @out;

	for my $chunk (@{$data})
	{
		my $id = $chunk->id;

		if ($id eq 'LIST')
		{
			my $data = $chunk->{data};

			my @moshed = blowchunks($data);
			my $list = new File::Format::RIFF::List($chunk->type, \@moshed);

			push(@out,$list);
		}
		else
		{
			next if ($chunk->size > 3 && substr($chunk->{'data'},1,3) eq $istart);

			push(@out, $chunk);
		}
	}

	return @out;
}

# Create a File::Format::RIFF object
eval # (try)
{
	our $riff = File::Format::RIFF->read($infile) or die("Error reading file \'$infilename\': $!");

	# Check the container type
	if ($riff->type !~ /^(AVI )$/)
	{
		$error = 1;

		print STDERR $riff->type." is not supported.\n";
	}
	else
	{
		my @data = $riff->data;

		my @moshed = blowchunks(\@data);
		my $out = new File::Format::RIFF($riff->type, \@moshed);

		$out->write($outfile);

		exit;
	}
};
if ($@) # (catch)
{
	# File::Format::RIFF doesn't like it
	$error = 1;

	print STDERR $@;
}

# Something's weird with the file, but allow the user to continue anyway
if ($error)
{
	print STDERR "Do you want to continue anyway? [y/n] ";

	read(STDIN,my $response,1);

	if ($response !~ /^(y|yes)$/i) { print STDERR "Aborting.\n"; exit 1; }
}


our $deleted = 0; # Deleted frame count

our $ndup = 0; # Number of times to duplicate P-frame

our $skip = 0; # Number of frames to skip before outputting duplicated P-frames

# Loop through blocks delimited by 00dc
{
	# Block delimiter
	local $/ = '00dc';

	# First I-frame flag, used to prevent first I-frame from being removed
	my $first = 1;


	while (<$infile>)
	{
		# Check for first I-frame or non-I-frame
		if ($first == 1 || (substr($_,5,3) ne $istart))
		{
			# If frames are to be skipped, do so
			if ($skip > 0) { $skip--; next; }

			# Frame duplication
			if ($ndup > 0)
			{
				# Catch any frames that were deleted while skipping
				$ndup += $deleted;

				# Duplicate
				for my $i (1..$ndup)
				{
					print $outfile $_;
				}

				# Reset duplicated and deleted count
				$ndup = $deleted = 0;
			}

			# If $deleted > 0, this is the first non-I-frame after deletion
			if ($deleted > 0)
			{
				# We need to output $deleted + 1 frames to include the current frame
				$deleted++;

				# Determine whether extra duplicates will be made. This produces a long, sweeping effect.
				$ndup = (rand() < $dprob) ? int(rand($dmax - $dmin)) + $dmin : 0;

				# Set frames to be skipped
				$skip = $ndup;

				# If no skipping is to be done, fill in gaps caused by deletions with current frame
				if ($skip <= 0)
				{
					for (my $i = 0; $i < $deleted; $i++)
					{
						print $outfile $_;
					}
				}
				else
				{
					# Add number of deleted frames to number of duplicate frames so they can be replaced after skipping
					$ndup += $deleted;
				}

				# Reset deleted frame counter
				$deleted = 0;
			}
			else
			{
				# If this was the first I-frame (and not just data at the beginning of the file), set first flag to 0
				if ($first && substr($_,5,3) eq $istart) { $first = 0; }

				# Dump data
				print $outfile $_;
			}
		}
		else
		{
			# An I-frame was present, increment deleted counter
			$deleted++;
		}
	}
}
