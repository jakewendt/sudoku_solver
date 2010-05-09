#!/usr/bin/perl -w

use strict;
use lib "/home/isdc/wendt/local/lib";
use lib "/Users/jake/local/lib";
#use lib "$ENV{HOME}/local/lib/";
use LWP::Simple;
use File::Basename;
use CGI; # qw(:standard);


while (1) {

	my $content;
	my $URL = "http://play.websudoku.com/?level=4";
	my ( $level, $number );

	unless (defined ($content = get $URL)) {
		print "could not get $URL\n";
	} else {

		my @lines = split "\n", $content;

		foreach ( @lines ) {
			next unless ( /Puzzle/ );
			next unless ( /websudoku/ );

#		print "line: $_ \n";
#>Easy Puzzle 4,108,824,932 <
			( $level, $number ) = ( />\s*(\w+)\s+Puzzle\s+([\d,]+)\s*</ );
#		print "Level: $level\n";
#		print "Number: $number\n";

		}
#	print "\n\n\n\n\n\n";

		foreach ( @lines ) {
			next unless ( /TABLE/ );
			next unless ( /CLASS/ );
			#print "line: $_ \n";

			my @fields = split ">", $_;

			my $count=0;
			print "Creating $level-$number\n";
			open OUT, "> $level-$number";
			foreach ( @fields ) {
				next unless ( /INPUT/ );
				#print "field: $_ \n";

				$count++;

				my ( $value ) = ( /VALUE="(\d)"/ );
				$value = " " unless $value;
				print OUT "$value;";
				print OUT "\n" unless ( $count % 9 );
			}
			close OUT;
			#print "Field count = $count\n";;

		}
	}
}







#	print "\n\nJAKE\n\n";
#	print end_html;
#	print "\n\n";

exit;


