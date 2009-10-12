#!/usr/bin/perl

# Autodatamosh script copyright 2009 Joe Friedl
# http://joefriedl.net
#
# Released under the GPLv3 license: http://www.gnu.org/licenses/gpl.html

use strict;
use warnings;

# Output flag
my $out = 1;

# Sequence counter
my $seq = 0;

# Bit pattern that marks the beginning of an I-frame.
# If the first part, "00dc" (ASCII), is found, the script can assume a
# new frame has started
my @pattern = split('',"00dc*****".pack("H*","0001b0"));

my @buf;
my $outbuf;
my $tmp;

# First I-frame flag
my $first = 1;

while (<STDIN>)
{
	# Split input into an array of 8-bit values
	@buf = split('',$_);

	# Initialize output
	$outbuf = '';

	for (my $i = 0; $i < @buf; $i++)
	{
		# If the pattern has started, stop output, start saving in $tmp,
		# and increment sequence counter
		if (($pattern[$seq] eq '*') || ($buf[$i] eq $pattern[$seq]))
		{
			$seq++;
			$tmp .= $buf[$i];

			if ($seq == @pattern)
			{
				# We've reached the end of the sequence

				# Continue output if this is the first frame
				if ($first)
				{
					$outbuf .= $tmp;
					$tmp = '';
					$seq = 0;

					$first = 0;
				}
				else
				{
					# Stop output and get rid of $tmp
					$tmp = '';
					$out = $seq = 0;
				}
			}
		}
		else
		{
			# If the sequence had started, dump $tmp if not within an I-frame
			if ($seq > 0)
			{
				# If a new frame started, start output back up
				# This will catch new frames after an I-frame
				if ($seq > 7) { $out = 1; }

				# If we're outputting, append $tmp to output
				if ($out) { $outbuf .= $tmp; }

				# Re-init $tmp
				$tmp = '';
			}

			# No frame container has been detected, output normally
			# if not within an I-frame
			if ($out) { $outbuf .= $buf[$i]; }

			# Reset sequence
			$seq = 0;
		}
	}

	# Dump output buffer
	print $outbuf;
}
