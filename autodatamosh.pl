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

our $first = 1; # First I-frame flag
our $deleted = 0; # Deleted frame count
our $ndup = 0; # Number of times to duplicate P-frame
our $skip = 0; # Number of frames to skip before outputting duplicated P-frames

# Recursively reconstruct file
sub blowchunks
{
	my $data = shift; # Input chunks

	my @out; # Output chunks

	for my $chunk (@{$data})
	{
		my $id = $chunk->id;

		if ($id eq 'LIST')
		{
			# Iterate through chunks within LIST
			my $data = $chunk->{data};

			my @moshed = blowchunks($data);
			my $list = new File::Format::RIFF::List($chunk->type, \@moshed);

			push(@out,$list);
		}
		else
		{
			# Look at first few bytes for the I-frame marker
			if ($chunk->size > 3 && substr($chunk->{'data'},1,3) eq $istart)
			{
				next if (!$first) or $first = 0;
			}

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
		print STDERR $riff->type." is not supported.\n";
	}
	else
	{
		my @data = $riff->data;

		my @moshed = blowchunks(\@data);
		my $out = new File::Format::RIFF($riff->type, \@moshed);

		$out->write($outfile);

		exit 0;
	}
};
if ($@) # (catch)
{
	# File::Format::RIFF doesn't like it
	print STDERR $@;
	exit 1;
}
