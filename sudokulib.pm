
package sudokulib;

use POSIX; # for int(), floor() and ceil() functions

#	Don't use "my"!
#       next 3 statements required for use without using $ISDCConstants:: to prefix
use Exporter();
@ISA = qw ( Exporter );

#       That's plural for status.  Well, at least its unique.
@EXPORT = qw ( 
	%sudoku
	$filename
	$spaceholder
	$size
	$gWidth
	$gHeight
	$debug
	);

$filename = "";
$spaceholder = '_';
$size    = 9;
$gWidth  = 3;
$gHeight = 3;
%sudoku  = ();
$debug   = 0;
$quiet   = 1;
$string  = "";

$|=1;

##########################################################################################
##########################################################################################
##########################################################################################

sub ClearSudoku {
	foreach my $row ( 1 .. $size ) {
		foreach my $col ( 1 .. $size ) {
			$sudoku{$row}{$col}{'_'} = 1 unless ( exists $sudoku{$row}{$col} );
		}
	}
}


sub SolveSudoku {
	my ( $type ) = @_;
	$type = 1 unless $type;	#	just simple
	my $count = 0;
	foreach my $row ( sort{$a <=> $b}( keys(%sudoku) ) ) {
		foreach my $col ( sort{$a <=> $b}( keys ( %{$sudoku{$row}} ) ) ) {
			my @vals = sort{$a <=> $b}( keys ( %{$sudoku{$row}{$col}} ) );
			if ( ( @vals == 1 ) && ( $type >= 1 ) ) {
				#	Only one number in this box, so remove it from the others
				$count += &RemoveNumFrom ( $vals[0], $row, $col, $row,    0 );	#	Row
				$count += &RemoveNumFrom ( $vals[0], $row, $col,    0, $col );	#	Column
				$count += &RemoveNumFrom ( $vals[0], $row, $col,    0,    0 );	#	Group
			}

			if ( $type >= 2 ) {
				#	Look for a number that is only in the row/column/group once 
				#	and remove all the other numbers from that box
				$count += &SearchForUniq ( $row, $col,    0, $col ); #  Column
				$count += &SearchForUniq ( $row, $col, $row,    0 ); #  Row
				$count += &SearchForUniq ( $row, $col,    0,    0 ) if ( ( $col % $gWidth ) && ( $row % $gHeight ) ); #  Group
			}

			if ( $type >= 3 ) {
				#	Look for sets of numbers that as a group eliminate
				#	them from other boxes.
				$count += &SearchForReducable ( $row, $col,    0, $col ); #  Column
				$count += &SearchForReducable ( $row, $col, $row,    0 ); #  Row
				$count += &SearchForReducable ( $row, $col,    0,    0 ) if ( ( $col % $gWidth ) && ( $row % $gHeight ) ); #  Group
			}

			if ( $type >= 4 ) {
				#
				#	compare overlapping groups and columns
				#	compare overlapping groups and rows
				#
				#	Look for set of numbers in multiple boxes in a row/column, whose possible numbers
				#	eliminate a possiblity from a number in an overlapping group

				#	This'll be tough.

				$count += &CheckOverlaps ( $row, $col,    0, $col ); #  Column
				$count += &CheckOverlaps ( $row, $col, $row,    0 ); #  Row
			}

		}
	}
	return $count;
}





















##################################################
#	Universal routine
sub CheckOverlaps {
	my ( $row, $col, $okrow, $okcol, @vals ) = @_;
	my $count = 0;		#	the number of numbers removed
	my @matchrows;
	my @matchcols;

	#	define group....
	my @rows = &GetRows ( $row, $col, $okrow, $okcol );
	my @cols = &GetCols ( $row, $col, $okrow, $okcol );
	my $type = &GetType ( $row, $col, $okrow, $okcol );

	foreach my $row ( @rows ) {
		foreach my $col ( @cols ) {
			my @vals = sort{$a <=> $b}( keys ( %{$sudoku{$row}{$col}} ) );
			next unless ( @vals > 2 );
			#
			#	For each cell that is incomplete ( more than 1 possible value )...
			#
			#	Compare its values to those that have a @val <= its own @val
			#
			print "Comparing row:$row, col:$col, vals:@vals. type:$type\n" unless ( $quiet );

			ROW: foreach my $currow ( @rows ) {
				COL: foreach my $curcol ( @cols ) {
					print "Checking row:$currow, col:$curcol\n" unless ( $quiet );
					foreach my $allval ( 1..$size ) {
						next COL if ( ( exists $sudoku{$currow}{$curcol}{$allval} ) && ( ! grep /^$allval$/, @vals ) );
					}
					print "Checking row:$currow, col:$curcol.  MATCH!\n" unless ( $quiet );
					push @matchrows, $currow;
					push @matchcols, $curcol;
				}
			}
			if ( @matchrows == @vals ) {
				print "Found ",$#vals+1," cells that match @vals\n" unless ( $quiet );
			}

		}
	}

	return 0;
}






























##################################################
#	Universal routine
sub SearchForReducable {
	#  ( current row, current column, current row or 0, current column or 0 )
	my ( $workrow, $workcol, $okrow, $okcol ) = @_;
	my $count = 0;	#	the number of numbers removed
#	my @partlist;
#	my @fulllist;
#	my $match;
#	my $number;

	#	define group....
	my @rows = &GetRows ( $workrow, $workcol, $okrow, $okcol );
	my @cols = &GetCols ( $workrow, $workcol, $okrow, $okcol );
	my $type = &GetType ( $workrow, $workcol, $okrow, $okcol );

#	# Compile a list of all non-complete grouping values.
#	my @foundrows;
#	my @foundcols;
#	my @foundvals;
	foreach my $row ( @rows ) {
		foreach my $col ( @cols ) {
			my @vals = sort{$a <=> $b}( keys ( %{$sudoku{$row}{$col}} ) );
			next unless ( @vals > 1 );
			#
			#	For each cell that is incomplete ( more than 1 possible value )...
			#
			#	Compare its values to those that have a @val <= its own @val
			#
			$count += &CompareVals ( $row, $col, $okrow, $okcol, @vals );
			#
		}
	}
	return $count;
}

##################################################

sub CompareVals {
	my ( $row, $col, $okrow, $okcol, @vals ) = @_;

	#	define group....
	my @rows = &GetRows ( $row, $col, $okrow, $okcol );
	my @cols = &GetCols ( $row, $col, $okrow, $okcol );
	my $type = &GetType ( $row, $col, $okrow, $okcol );

	my @matchrows;
	my @matchcols;
	my $count = 0;

	print "\nComparing @vals\n" if ( $debug );

	ROW: foreach my $currow ( @rows ) {
		COL: foreach my $curcol ( @cols ) {
			#	Check to see that there are less values here
			#	probably unnecessary with the next check
			#my @curvals = sort{$a <=> $b}( keys ( %{$sudoku{$currow}{$curcol}} ) );
			#next unless ( ( @curvals > 1 ) && ( @curvals <= @vals ) );

			#	Check to see if any values other than those in @val exist in this cell
			#	If so, bail.
#			my @allvals = ( 1..$size );
#			foreach my $allval ( @allvals ) {
			foreach my $allval ( 1..$size ) {
				next COL if ( ( exists $sudoku{$currow}{$curcol}{$allval} ) && ( ! grep /^$allval$/, @vals ) );
			}
			push @matchrows, $currow;
			push @matchcols, $curcol;
		}
	}

	#	could be @matchcols just the same
	if ( @matchrows == @vals ) {
		print "Found ",$#vals+1," cells that match @vals\n" if ( $debug );
		for ( my $i=0; $i<=$#vals; $i++ ) {
			print "Row: $matchrows[$i], Col: $matchcols[$i]\n" if ( $debug );
		}
		foreach my $currow ( @rows ) {
			foreach my $curcol ( @cols ) {
				next if ( ( grep /^$currow$/, @matchrows ) && ( grep /^$curcol$/, @matchcols ) );
				foreach my $curval ( @vals ) {
					if ( exists ( $sudoku{$currow}{$curcol}{$curval} ) ) {
						print "Removing $curval from row $currow, column $curcol\n" if ( $debug );
						delete ( $sudoku{$currow}{$curcol}{$curval} );
						$count++;
					}
				}
			}
		}
	}
	return $count;
}

##################################################

sub GetType {

	my ( $workrow, $workcol, $okrow, $okcol ) = @_;
	my $type;

	#	working on a group
	if ( ( $okrow == 0 ) & ( $okcol == 0 ) ) {
		$type = "group";
	} elsif ( $okrow == 0 ) {
		$type = "column";
	} elsif ( $okcol == 0 ) {
		$type = "row";
	}

	return $type;
}

##################################################

sub GetCols {

	my ( $workrow, $workcol, $okrow, $okcol ) = @_;
	my @cols;

	#	working on a group
	if ( ( $okrow == 0 ) & ( $okcol == 0 ) ) {
		my $colStart = floor ( ($workcol-1) / $gWidth ) * $gWidth + 1;
		my $colEnd   = ceil  ( $workcol / $gWidth ) * $gWidth ;
		@cols = ( $colStart..$colEnd );
	} elsif ( $okrow == 0 ) {
		@cols = ( $okcol );
	} elsif ( $okcol == 0 ) {
		@cols = ( 1..$size );
	}

	return @cols;
}

##################################################

sub GetRows {

	my ( $workrow, $workcol, $okrow, $okcol ) = @_;
	my @rows;

	#	working on a group
	if ( ( $okrow == 0 ) & ( $okcol == 0 ) ) {
		my $rowStart = floor ( ($workrow-1) / $gHeight ) * $gHeight + 1;
		my $rowEnd   = ceil  ( $workrow / $gHeight ) * $gHeight ;
		@rows = ( $rowStart..$rowEnd );
	} elsif ( $okrow == 0 ) {
		@rows = ( 1..$size );
	} elsif ( $okcol == 0 ) {
		@rows = ( $okrow );
	}

	return @rows;
}

##################################################
#	Universal routine
sub SearchForUniq {
	#  ( current row, current column, current row or 0, current column or 0 )
	my ( $workrow, $workcol, $okrow, $okcol ) = @_;
	my $count = 0;
	my @partlist;
	my @fulllist;
	my $match;
	my $number;

	#	define group....
	my @rows = &GetRows ( $workrow, $workcol, $okrow, $okcol );
	my @cols = &GetCols ( $workrow, $workcol, $okrow, $okcol );
#	my $type = &GetType ( $workrow, $workcol, $okrow, $okcol );

	# Compile a list of all non-complete row values.
	foreach my $row ( @rows ) {
		foreach my $col ( @cols ) {
			my @vals = sort{$a <=> $b}( keys ( %{$sudoku{$row}{$col}} ) );
			push @fulllist, @vals;
			push @partlist, @vals if ( @vals > 1 );
		}
	}

	#	Are there any unique numbers in the $partline that are?
	if ( @partlist ) {
		UNIQ: for ( my $i=1; $i<=$size; $i++ ) {
			#print "Checking $i in @partlist.\n" if ( $debug );
			my $match = 0;
			foreach ( @partlist ) {
				$match++ if ( $_ == $i );
			}
			if ( $match == 1 ) {
				#print "Checking $i in @fulllist.\n" if ( $debug );
				$match = 0;
				foreach ( @fulllist ) {
					$match++ if ( $_ == $i );
				}
				if ( $match == 1 ) {
					print "Found $i that could be set in the $workrow,$workcol\n" if ( $debug );
					$number = $i;
					last UNIQ;
				}
			}
		}

		# Clean the cell containing the matched number
		if ( $number ) {
			CLEAN: foreach my $row ( @rows ) {
				foreach my $col ( @cols ) {
					my @vals = sort{$a <=> $b}( keys ( %{$sudoku{$row}{$col}} ) );
					next if ( @vals == 1 );
	
					if ( exists ( $sudoku{$row}{$col}{$number} ) ) {
						foreach ( sort{$a <=> $b}( keys ( %{$sudoku{$row}{$col}} ) ) ) {
							delete ( $sudoku{$row}{$col}{$_} ) unless ( $_ == $number );
						}
						last CLEAN;
					}
				}
			}
			$count++;
		}
	}

	return $count;
}


##################################################
#	Universal removing routine

sub RemoveNumFrom {	
	#  ( value 2B removed, current row, current column, current row or 0, current column or 0 )
	my ( $value, $workrow, $workcol, $okrow, $okcol ) = @_;
	my $count = 0;

	#	define group....
	my @rows = &GetRows ( $workrow, $workcol, $okrow, $okcol );
	my @cols = &GetCols ( $workrow, $workcol, $okrow, $okcol );
	my $type = &GetType ( $workrow, $workcol, $okrow, $okcol );

	print "Removing $value from all squares in $type, except row $workrow, column $workcol.\n" if ( $debug );

	foreach my $row ( @rows ) {
		#print "Checking group row $row\n" if ( $debug );
		foreach my $col ( @cols ) {
			#print "Checking group column $col\n" if ( $debug );
			next if ( ( $workcol == $col ) && ( $workrow == $row ) );
			if ( exists ( $sudoku{$row}{$col}{$value} ) ) {
				print "Removing $value from row $row, column $col\n" if ( $debug );
				delete ( $sudoku{$row}{$col}{$value} );
				$count++;
			}
		}
	}
	return $count;
}

##################################################

sub FillSudoku {
	foreach my $row ( sort{$a <=> $b}( keys(%sudoku) ) ) {
		foreach my $col ( sort{$a <=> $b}( keys ( %{$sudoku{$row}} ) ) ) {
			if ( exists ( $sudoku{$row}{$col}{'_'} ) ) {
				delete ( $sudoku{$row}{$col}{'_'} );
				for ( my $i=1; $i<=$size; $i++ ) {
					$sudoku{$row}{$col}{$i} = 1;
				}
			}
		}
	}
}

##################################################

sub CountIncomplete {

	my $incomplete = 0;

	foreach my $row ( sort{$a <=> $b}( keys(%sudoku) ) ) {
		foreach my $col ( sort{$a <=> $b}( keys ( %{$sudoku{$row}} ) ) ) {
			my @vals = sort{$a <=> $b}(keys ( %{$sudoku{$row}{$col}} ) );
			$incomplete++ if ( @vals > 1 );
		}
	}

	return $incomplete;
}

##################################################

sub ShowSudoku {

	my $RED   = "[1;31;43m";
	my $RESET = "[0m";

	print "\n";
	foreach my $row ( sort{$a <=> $b}( keys(%sudoku) ) ) {
		#print "ROW $row : ";
		foreach my $col ( sort{$a <=> $b}( keys ( %{$sudoku{$row}} ) ) ) {
			my @vals = sort{$a <=> $b}(keys ( %{$sudoku{$row}{$col}} ) );
			print "$RED" if ( @vals > 1 );	#	bold
			#	print "[7m" if ( @vals > 1 );	#	inverse
			foreach my $val ( @vals ) {
				print "$val";
				print "," unless ( ( $val =~ /_/ ) || ( $val == $vals[$#vals] ) );
			}
			print "$RESET" if ( @vals > 1 );
			print "\t";
			print "\t" unless ( ( $col % $gWidth ) || ( $col == $size ) );
		}
		print "\n\n" unless ( $row % $gHeight );
		print "\n";
	}
	print "\n";
}

##################################################

sub ReadSudoku {

	my ( $filename ) = @_;

	my %grid;
	my $row = 1;

	open CURFILE, $filename;
	while (<CURFILE>) {
		chomp;
		next if ( /^\s*#/ );
		next if ( /^\s*$/ );
		my @cols = split ";", $_;
		my $col = 1;
		for ( $col = 1; $col <= $size; $col++ ) {
			$_ = ( $cols[$col-1] ) ? $cols[$col-1] : '_';
			my @values = split ",", $_;
			foreach my $value ( @values ) {
				$value =~ s/\s*//g;
				$value = "$spaceholder" unless ( /\d+/ );
				$grid{$row}{$col}{$value} = 1;
			}
			print "Grid Row $row Col $col = ",keys(%{$grid{$row}{$col}}),"\n" if ( $debug );
		}
		print "WARNING : last column was ",$col-1,". Expected $size.\n" unless ( $col == $size+1 );
		$row++;
	}
	print "WARNING : last row was ",$row-1,". Expected $size.\n" unless ( $row == $size+1 );
	close CURFILE;

	%sudoku = %grid;
}

##################################################

sub ReadString {

	my ( $string ) = @_;
	my $multiple_values;	#	flag to say that the next value may also be in this square
	my %grid;

	#	no real method for changing size in web version yet

	#	one char at a time
	#	expecting "1-9", "." and MAYBE ","s
	my @values = split //, $string;
	my $row = 1;
	my $col = 0;

	foreach my $value ( @values ) {
		chomp $value;
		if ( $value eq "," ) {
			$multiple_values=1;
		}
		else {
			unless ( $multiple_values ) {
				if ( $col >= $size ) {
					$row++;
					$col = 0;
				}
				$col++;
			}
			$value = $spaceholder if ( $value eq '.' );
			$grid{$row}{$col}{$value} = 1;
			$multiple_values = 0;
			#print "Row: $row ; Col: $col; $value ; \n";
		}
	}

	%sudoku = %grid;
}

##################################################

sub ReadForm {
	my %hash = @_;

	my $multiple_values;	#	flag to say that the next value may also be in this square
	my %grid;
	my $row = 1;
	my $col = 0;

	foreach ( sort keys ( %hash ) ) {
		next if ( $_ =~ /Solve/ );
#		print "$_: $hash{$_}<br />\n";

		#	no real method for changing size in web version yet

		#	one char at a time
		#	expecting "1-9", "." and MAYBE ","s
		my @values = split //, $hash{$_};
		push @values, "." unless ( @values );
	
		foreach my $value ( @values ) {
			chomp $value;
			if ( $value eq "," ) {
				$multiple_values = 1;
			} else {
				unless ( $multiple_values ) {
					if ( $col >= $size ) {
						$row++;
						$col = 0;
					}
					$col++;
				}
				$value = $spaceholder if ( $value eq '.' );
				$grid{$row}{$col}{$value} = 1;
				$multiple_values = 0;
#				print "Row: $row ; Col: $col; $value ; <br />\n";
			}
		}
	}

	%sudoku = %grid;
}

##################################################

sub WriteSudoku {		#	a lot like ShowSudoku

	my ( $filename ) = @_;

	my %grid;
	my $row = 1;

	open OUTFILE, ">$filename";

		foreach my $row ( sort{$a <=> $b}( keys(%sudoku) ) ) {
			foreach my $col ( sort{$a <=> $b}( keys ( %{$sudoku{$row}} ) ) ) {
				my @vals = sort{$a <=> $b}( keys ( %{$sudoku{$row}{$col}} ) );
				foreach my $val ( @vals ) {
					print OUTFILE "$val";
					print OUTFILE "," unless ( ( $val =~ /_/ ) || ( $val == $vals[$#vals] ) );
				}
				print OUTFILE ";";
			}
			print OUTFILE "\n";
		}

	close OUTFILE;
}

##################################################

sub Sudoku2HTML {
	my ( $id ) = @_;
	#my $RED   = "[1;31;43m";
	#my $RESET = "[0m";

	#print "In Sudoku2HTML\n";
	print "<div class=\"puzzle\"";
	print " id=\"$id\" " if ( $id );
	print ">\n";
	print "<form action=\"index.pl\" method=\"\">\n" if ( $id =~ /input/ );
	foreach my $row ( sort{$a <=> $b}( keys(%sudoku) ) ) {
		#print "ROW $row : ";
		foreach my $col ( sort{$a <=> $b}( keys ( %{$sudoku{$row}} ) ) ) {
			my @vals = sort{$a <=> $b}(keys ( %{$sudoku{$row}{$col}} ) );
			#print "$RED" if ( @vals > 1 );	#	bold
			#	print "[7m" if ( @vals > 1 );	#	inverse
			print "<div class=\"cell\">";
			print "<input type=\"text\" size=\"3\" name=\"${row}${col}\" value=\"" if ( $id =~ /input/ );
			foreach my $val ( @vals ) {
				print "$val" unless ( $val =~ /_/ );
				print ", " unless ( ( $val =~ /_/ ) || ( $val == $vals[$#vals] ) );
			}
			print "\" />" if ( $id =~ /input/ );
			print "</div>\n";
			#print "$RESET" if ( @vals > 1 );
			#print "\t";
			#print "\t" unless ( ( $col % $gWidth ) || ( $col == $size ) );
		}
		#print "\n\n" unless ( $row % $gHeight );
		#print "\n";
	}
	#print "\n";
	print "<input type=\"hidden\" name=\"Solve\" value=\"y\" />\n" if ( $id =~ /input/ );
	print "<center><input type=\"submit\" value=\"Solve\" /></center>\n" if ( $id =~ /input/ );
	print "</form>\n" if ( $id =~ /input/ );
	print "</div>\n";
}

##################################################















__END__ 


Set Attribute Mode	<ESC>[{attr1};...;{attrn}m

    * Sets multiple display attribute settings. The following lists standard attributes:

0	Reset all attributes
1	Bright
2	Dim
4	Underscore	
5	Blink
7	Reverse
8	Hidden

	Foreground Colours
30	Black
31	Red
32	Green
33	Yellow
34	Blue
35	Magenta
36	Cyan
37	White

	Background Colours
40	Black
41	Red
42	Green
43	Yellow
44	Blue
45	Magenta
46	Cyan
47	White




