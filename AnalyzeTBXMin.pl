#!usr/bin/perl

use strict;
use warnings;
use XML::Twig;

# The purpose of this app is to scan TBX-Min files and determine the type of file, the
# number of entries present, which subject fields are present, and what the
# source/target language is. In addition it checks to see if the file is written in the
# old or current TBX-Min edition's standards. 
#
# The format of the output should be as follows. Any variation indicates an error in
# the format of the XML file.
#
#
#
#
#
# All done! Printing results:
#
# [Possible Warning Message displayed if not all terms contain a specified language]
#
# The file is [NOT] a tbxm file.
# The file format is [NOT] up to date.
# The source language is: " "
# The target language is: " "
# Total number of terms in file:
# Subject fields included:
# 
#
#
# File size: x bytes
# Done in x second(s)!

#################### User inputs desired file.
print "Welcome.\nPlease enter the file path to the .tbxm file below.\n";
my $path_to_TBX = <STDIN>;

open(my $file, $path_to_TBX) or
	print "File not found. Please try again.\n" 
	and exit;

	
print "The file was opened successfully.\n";

while(1) {

	print "Press (y) to continue.\n";
	my $Continue = <STDIN>;
	chomp($Continue); 
	$Continue=~tr/A-Z/a-z/;

	unless($Continue eq 'y') {next}

	last
}

print "Starting file analysis:\n";
#################### Lets start the clock.
my $start_run = time();
#################### Check the file size to print out later.
my $filesize = -s $file;
#################### Declare our variables that will be used later. Important for variables that will be used again outside of twig instances.
my $number_of_terms = 0;
my $TBXcheck = 0;
my $source;
my $target;
my @seen;
my $langcheck;
my $TBX2;
my $counter = 0;
my $counter2 = 0;
my $old = 0;
################### New twig instance to check for </TBX> tag at the end of the program
################### Working.

#### !!!!!!! Instead of creating a new twig for each tag you search for, it is much faster and more efficient to do it all in one go.  This is especially the case with very large TBX files, !!!!!!!
#### !!!!!!! so you don't have to read through each file every time you search for something. In my tests, this ran more than twice as fast after I made the change							!!!!!!!!
my $twig_instance = XML::Twig->new(
	twig_handlers => {
		
		TBX => sub {
			$TBXcheck++;
			
			################### Double-check for TBX-Min format, this time by looking at the dialect before the header.
			################### Working.
			my ($twig,$elt) = @_;
			$TBX2 = $elt->att("dialect");
		},
		
		################### New to twig instance to read the source language and target language from the tag found within the header.
		################### Working.
		languages => sub {
			my ($twig,$elt) = @_;
			$source = $elt->att("source");
			$target = $elt->att("target");
			print "Source Language: \"$source\"\n";
			print "Target Language: \"$target\"\n";	
			
		},
		
		################### Check to make sure that each term has a value for its language group FOR CURRENT VERSIONS OF TBX MIN !!!!!!!!!!!!!
		################### Working.
		langSet => sub { #Current Standard
			my ($twig,$elt) = @_;
			$langcheck = $elt->att("xml:lang");
			if(length($langcheck) == 0) {
			print "Warning! One or more terms does not contain a specified language!\n";
			$counter++;
			};
		},
		
		################### Check to make sure that each term has a value for its language group FOR OLD VERSIONS OF TBX MIN !!!!!!!!!!
		################### Working.
		langGroup => sub { #Old Standard
			my ($twig,$elt) = @_;
			$langcheck = $elt->att("xml:lang");
			if(length($langcheck) == 0) {
			print "Warning! One or more terms does not contain a specified language!\n";
			$counter2++;
			};
		},
		
		################### Check if file is in the Old TBX-Min format or in the Current format. Let the user know which kind of file they are working with.
		################### Working.
		termGroup => sub {
			$old++;
		},
		
		################### Determine number of terms present by checking for </term> tags.
		################### Working.
		term => sub {
			$number_of_terms++;
			print "Found $number_of_terms terms so far!\n";
			
		},
		
		################## Print out Subject fields used in document where <subjectField> tags occur.
		################### Working.
		subjectField => sub {
			my ($twig, $elt) = @_;   ### !!!!!! the first value passed in with @_ is the $twig object rather than the $path_to_TBX, which I don't believe gets passed in automatically !!!!!!
			print $elt->text_only()."\n";
			push @seen, $elt->text_only();
		}
	}
);

$twig_instance->parsefile($path_to_TBX);  


### Sort out the unique values of the subject field array @seen
sub uniq {
    my %seen;
    grep !$seen{$_}++, @_;
}
my @filtered = uniq(@seen);


######### !!!!!!!! It is more common to see the If-Else construct laid out as I have changed it to look below.  It is also easier to follow from a code-maintainance standpoint   !!!!!!!!!!

################### Print out errors and warnings about issues discovered.
if($TBXcheck eq '0') { 
	print "The file is not a tbxm file.\n"
}
else {
	print "The file is a tbxm file. \n";
}

if($TBX2 eq "TBX-Min") { 
	print "Confirmed\n"
}
else {
	print "File not Confirmed\n";
};

if($old > 0) { 
	print "The file format is NOT up to date.\n"
}
else {
	print "The file format is up to date.\n";
};
	
print "Total Number of Terms in File: $number_of_terms\n"; 

################## Stop the clock. Subtract Start time from End time.
my $end_run = time();
my $run_time = $end_run - $start_run;
#################### Print out final results for user!

print "\n\nAll done! Printing results:\n\n";



if($counter > 0) { #For Current files
	print "!!! Warning! One or more terms does not contain a specified language! !!!\n\n";
}; 
	
if($counter2 > 0) { #For Out-dated files
	print "!!! Warning! One or more terms does not contain a specified language! !!!\n\n";
}; 
#-----------
if($TBXcheck eq '1' and $TBX2 eq 'TBX-Min') { 
	print "The file is a tbxm file.\n"
}
else {
	print "!!!!! The file is NOT a tbxm file. !!!!!\n";
};
#-----------
if($old > 0) { 
	print "The file format is NOT up to date.\n"
}
else {
	print "The file format is up to date.\n";
};
#-----------
print "The source language is: \"$source\"\n";
print "The target language is: \"$target\"\n";
print "Total number of terms in file: $number_of_terms\n"; 
print "Subject fields included:\n";
print "$_\n" for @filtered;
print "\n\nFile size: $filesize bytes\n";
print "Done in $run_time second(s)!\n\n\n\n";

# Lets ask if the user would like a copy of the results in a seperate file
# Working.

print "Would you like a copy of the results?\n";
print "The file will be saved to your computer.\n(y/n)\n";
my $lastq = <STDIN>;


chomp($lastq);
$lastq=~tr/A-Z/a-z/;
if($lastq eq 'n') {
	exit
};



while(1) {

chomp($lastq); 
$lastq=~tr/A-Z/a-z/;

unless($lastq eq 'y') {next}

last
}


################ If they say yes!

my $printfile = "Results.txt";

unless(open FILE, '>::',$printfile) {
	die "\nUnable to create $printfile\n";
}

###################################################################
###################################################################
# Results again, but this time for the file.

print FILE "\n\nAll done! Printing results:\n\n";


if($counter > 0) { #For Current files
	print FILE "!!! Warning! One or more terms does not contain a specified language! !!!\n\n";
}; 
	
if($counter2 > 0) { #For Out-dated files
	print FILE "!!! Warning! One or more terms does not contain a specified language! !!!\n\n";
}; 
#-----------
if($TBXcheck eq '1' and $TBX2 eq 'TBX-Min') { 
	print FILE "The file is a tbxm file.\n"
}
else {
	print FILE "!!!!! The file is NOT a tbxm file. !!!!!\n";
};
#-----------
if($old > 0) { 
	print FILE "The file format is NOT up to date.\n"
}
else {
	print FILE "The file format is up to date.\n";
};
#-----------
print FILE "The source language is: \"$source\"\n";
print FILE "The target language is: \"$target\"\n";
print FILE "Total number of terms in file: $number_of_terms\n"; 
print FILE "Subject fields included:\n";
print FILE "$_\n" for @filtered;
print FILE "\n\nFile size: $filesize bytes\n";
print FILE "Done in $run_time second(s)!\n\n";

close FILE;

##### First working: 12/24/16
##### Version 2 working: 1/11/16
##### Author: Kaden Carr
##### For the TBX Research Group.