# Autodatamosh

An automatic datamoshing script for AVI videos.

## Getting Started

First, install [Perl](https://www.perl.org/) if you don't have it.
It's included with OS X and lots of the Linuxes, but not Windows.

After that, either clone [this repo](https://github.com/grampajoe/Autodatamosh)
with Git or download the script directly with
[this link](https://raw.githubusercontent.com/grampajoe/Autodatamosh/master/autodatamosh.pl).

You're ready to break stuff!

### Preparing a Video

You'll need to create an AVI video using an MPEG-4 codec. You can do
that with a transcoding tool like [ffmpeg](https://www.ffmpeg.org/),
or with some video editing software.

### Breaking Stuff

Once you've got the video, open up a terminal, make sure you're in the
same directory as the `autodatamosh.pl` script, and run this:

```bash
./autodatamosh.pl -i /path/to/original.avi -o /path/to/datamoshed.avi
```

Replace `/path/to/original.avi` with the path of the video you prepared
earlier, and `/path/to/datamoshed.avi` with the path where you want to
save the datamoshed video.

That's it! Try to open the new video in a video player. I recommend
[VLC](http://www.videolan.org/vlc/index.html) because it copes with
how broken the datamoshed videos are really well.

## What it Does

Autodatamosh automatically datamoshes MPEG-4 encoded AVI videos.
Datamoshing is the process of removing image frames from a video to
produce an interesting visual effect. Autodatamosh can also duplicate
motion frames for a "sweeping" effect (see [Examples](#examples).)

In many cases, YOU MUST RE-ENCODE VIDEOS AFTER DATAMOSHING. The method
used by Autodatamosh leaves files chopped up and possibly unreadable by
some video players. Youtube and video players like VLC seem to have no
trouble understanding the chopped up files.

As with manual datamoshing techniques, you may also want to preserve
the original audio to be recombined with the video later, since
Autodatamosh brutally hacks through frames without regard for whether
they contain audio data. Leaving the audio in can also be fun, however.

## Usage

```
./autodatamosh.pl [-i FILE] [-o FILE] [-dprob N] [-dmin N] [-dmax N]
```

### Options

- `-i FILE`
	Input file. Default is stdin.

- `-o FILE`
	Output file. Default is stdout.

- `-dprob N`
	The probability (where N is between 0 and 1) that P-frames will
	be duplicated when an I-frame is removed, producing a sweeping
	effect. Default is 0.

- `-dmin N`
	Minumum number of frames to be duplicated. The actual amount
	duplicated will vary randomly between this and the value of
	dmax. Default is 10.

- `-dmax N`
	Maximum number of frames to be duplicated. The actual amount
	duplicated will vary randomly between this and the value of
	dmin. Default is 50.


## Examples

To do a standard datamosh using regular files for input and output:

```bash
./autodatamosh.pl -i input.avi -o output.avi
```

For some random (50%) sweeping effects between 5 and 30 frames long
using stdin for the input and stdout for the output:

```bash
cat input.avi | ./autodatamosh.pl -dprob .5 -dmin 5 -dmax 30 > output.avi
```

There are examples of videos datamoshed by this script in
[this playlist](https://www.youtube.com/playlist?list=PLfQLhVDCKp4kMEfMA6hbP0dIEOmvDMAdD).
