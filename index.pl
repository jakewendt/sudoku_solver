#!/usr/bin/perl

use File::Basename;
use CGI qw(:standard);
use sudokulib;

print header;
print "\n";

my $puzzledir = "./puzzles";
my $puzzle = param ( "puzzle" );
my $string = param ( "string" );

if ( ( $string ) && ( $puzzle ) ) {
	print "A string or a puzzle.  Choose!";
}
#$puzzle = "Evil-1,885,076,276" unless ( $puzzle );
#$string = ".85..921...1..54..........97..34.9.............4.97..24..........85..1...529..68." unless ( $string );

#	since different versions of perl handle multiple styles differently, 
#	I just set sudoku.css to import default.css (NOT ANYMORE)

#	In this list, the latter ones overright any conflicting settings of those before it....


print start_html( 
	-title      => "Sudo Ku", 
	-style      => { src => "sudoku.css" }
);

print "<div id='container'>\n";
print "<div id='table'> <div id='cell'> <div id='wrapper' > \n";
print "<div id='content'> \n";

print "<center><h1>Sudoku Solver</h1></center>\n";
print "<hr />\n";


&sudokulib::ClearSudoku();
if ( $puzzle ) {
	&sudokulib::ReadSudoku ( "$puzzledir/$puzzle" );
}
elsif ( $string ) {
	&sudokulib::ReadString ( "$string" );
} else {
	&sudokulib::ReadForm ( &CGI::Vars() );					#	this function is a bit of a problem
}

&sudokulib::ClearSudoku();
&sudokulib::Sudoku2HTML( "input" );

print "<div id='puzzledivider'>&nbsp</div>\n";

if ( param( "Solve" ) =~ /y/i ) {
	my $removed = 1;
	my $loop = 0;
	my $incomplete;
	my $quiet = 1;
	&sudokulib::FillSudoku ();
	while ( $removed ) {
		$loop++;
		$removed = &sudokulib::SolveSudoku ( 1 );
		unless ( $removed ) {
			$removed = &sudokulib::SolveSudoku ( 2 );
			unless ( $removed ) {
				$removed = &sudokulib::SolveSudoku ( 3 );
				unless ( $removed ) {
					$removed = &sudokulib::SolveSudoku ( 4 );
				}
			}
		}
	}
}
&sudokulib::Sudoku2HTML( "output" );
print "</div>\n"; #	content



# #	Load the above read puzzle into a string when reading it.
#	Add a button here, that when pushed, passes this puzzle string to the solver
#
#	print "<a class='button' href='?puzzle=$puzzle&Solve=yes'>Solve</a>" if ( $puzzle );
#	print "<a class='button' href='?string=$string&Solve=yes'>Solve</a>" if ( $string );
#<div style="display: block; width: 700px; padding-top: 0px; text-align: justify; font-size:16px; margin: auto;" >

print <<ENDLINE;
<div id='description'>
This sudoku solver is currently under development.  Simply add ?string=
followed by a string of the 81 characters of the given sudoku puzzle.  Use a
"." for the blanks.  Multiple values are allowed, but must be separated by a
",".  This will load the puzzle into the left grid.  If you use too many or 
too few, it will be obvious as the grid will look incorrect.  So far, this
solver has solved about 85% of all of the Evil class from WebSudoku.com.  I'm
working on that last 15%.
I am also working on a more user friendly method of doing this, instead of this
string type thing I got goin here.
For the time being, suck it up.

</div>
ENDLINE

print "<center><a href='?string=.85..921...1..54..........97..34.9.............4.97..24..........85..1...529..68.'>An example of a currently unsolved puzzle</a></center>\n";

print "</div>\n"; #	wrapper
print "</div>\n"; #	cell
print "</div>\n"; #	table
print "</div>\n"; #	container

print end_html;
print "\n\n";

exit;

