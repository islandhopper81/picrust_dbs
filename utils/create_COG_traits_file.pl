#!/usr/bin/env perl

# creates a COG trait file for picrust

use strict;
use warnings;

use Getopt::Long;
use Pod::Usage;
use Carp;
use Readonly;
use version; our $VERSION = qv('0.0.1');
use Log::Log4perl qw(:easy);
use Log::Log4perl::CommandLine qw(:all);
use UtilSY qw(:all);
use Table;

# Subroutines #
sub check_params;
sub _is_defined;

# Variables #
my ($dafe_db, $genomes_file, $cog_meta_file, $out_file, $help, $man);

my $options_okay = GetOptions (
    "dafe_db:s" => \$dafe_db,
	"genomes_file:s" => \$genomes_file,
	"cog_meta_file:s" => \$cog_meta_file,
    "out_file:s" => \$out_file,
    "help|h" => \$help,                  # flag
    "man" => \$man,                     # flag (print full man page)
);

# set up the logging environment
my $logger = get_logger();

# check for input errors
if ( $help ) { pod2usage(0) }
if ( $man ) { pod2usage(-verbose => 3) }
check_params();


########
# MAIN #
########

# read in the genomes file
$logger->info("Reading in the genome file");
open my $GEN, "<", $genomes_file or
	$logger->logdie("cannot open --genomes_file");

my @genomes = ();
foreach my $line ( <$GEN> ) {
	chomp $line;

	push @genomes, $line;
}
	
close($GEN);

# create the output table.
# 1. get a list of all the cogs (for columns)
# 2. use the list of genomes (for rows)

$logger->info("Creating the output table");
my $cog_meta_tbl = Table->new();
$cog_meta_tbl->load_from_file($cog_meta_file);
my $all_cogs_aref = $cog_meta_tbl->get_row_names();
my $cog_count = $cog_meta_tbl->get_row_count();

# create a row for each genome in the output table
my $out_tbl = Table->new();
foreach my $g ( @genomes ) {
	my @vals = (0) x $cog_count;
	$out_tbl->add_row($g, \@vals, $all_cogs_aref);
}



# go through each genome
$logger->info("Query each genome");
my $tbl = Table->new();
my $missing = 0;
foreach my $g ( @genomes ) {
	$logger->debug("genome: $g");
	my $file = "$dafe_db/$g/all_annote.txt";

	if ( ! -f $file ) {
		$logger->warn("Cannot find annotation file: $file");
		$missing++;
		$out_tbl->drop_row($g);
		next;
	}

	$tbl->load_from_file($file);

	my $cog_aref = $tbl->get_col("cog");

	foreach my $cog ( @{$cog_aref} ) {
		if ( $cog eq "NA" ) { next; }

		$logger->debug("Looking at COG: $cog");
		
		if ( $out_tbl->has_col($cog) ) {
			# increment the the cog count for this gneome
			$out_tbl->set_value_at($g, $cog, $out_tbl->get_value_at($g, $cog) + 1);
		}
	}
}

# print the final table
$out_tbl->save($out_file);
print "missing: $missing\n";


########
# Subs #
########
sub check_params {
	# check for required variables
	if ( ! defined $out_file) { 
		pod2usage(-message => "ERROR: required --out_file not defined\n\n",
					-exitval => 2); 
	}
	if ( ! defined $genomes_file) { 
		pod2usage(-message => "ERROR: required --genomes_file not defined\n\n",
					-exitval => 2); 
	}
	if ( ! defined $cog_meta_file) { 
		pod2usage(-message => "ERROR: required --cog_meta_file not defined\n\n",
					-exitval => 2); 
	}
	if ( ! defined $dafe_db ) {
		pod2usage(-message => "ERROR: required --dafe_db not defined\n\n",
					-exitval => 2);
	}

	# make sure required files are non-empty
	if ( defined $genomes_file and ! -e $genomes_file ) { 
		pod2usage(-message => "ERROR: --genomes_file $genomes_file is an empty file\n\n",
					-exitval => 2);
	}
	if ( defined $cog_meta_file and ! -e $cog_meta_file ) { 
		pod2usage(-message => "ERROR: --cog_meta_file $cog_meta_file is an empty file\n\n",
					-exitval => 2);
	}

	# make sure required directories exist
	if ( ! -d $dafe_db ) { 
		pod2usage(-message => "ERROR: --dafe_db is not a directory\n\n",
					-exitval => 2); 
	}
	
	return 1;
}


__END__

# POD

=head1 NAME

create_cog_traits_file.pl - creates a picrust trait file of COGs


=head1 VERSION

This documentation refers to version 0.0.1


=head1 SYNOPSIS

    create_cog_traits_file.pl
        --dafe_db dafe_db/
        --genomes_file genome_list.txt
        --cog_meta cognames2003-2014.tab
        --out_file cog_traits.tab
        
        [--help]
        [--man]
        [--debug]
        [--verbose]
        [--quiet]
        [--logfile logfile.log]

    --dafe_db       Path to DAFE database
    --genomes_file  Path to file with list of genomes to query
    --cog_meta      Path to cog metadata file
    --out_file      Path to where trait output table can be printed
    --help | -h     Prints USAGE statement
    --man           Prints the man page
    --debug	        Prints Log4perl DEBUG+ messages
    --verbose       Prints Log4perl INFO+ messages
    --quiet	        Suppress printing ERROR+ Log4perl messages
    --logfile       File to save Log4perl messages


=head1 ARGUMENTS
    
=head2 --file | -f

Path to an input file
    
=head2 --var | -v

Path to an input variable   
 
=head2 [--help | -h]
    
An optional parameter to print a usage statement.

=head2 [--man]

An optional parameter to print he entire man page (i.e. all documentation)

=head2 [--debug]

Prints Log4perl DEBUG+ messages.  The plus here means it prints DEBUG
level and greater messages.

=head2 [--verbose]

Prints Log4perl INFO+ messages.  The plus here means it prints INFO level
and greater messages.

=head2 [--quiet]

Suppresses print ERROR+ Log4perl messages.  The plus here means it suppresses
ERROR level and greater messages that are automatically printed.

=head2 [--logfile]

File to save Log4perl messages.  Note that messages will also be printed to
STDERR.
    

=head1 DESCRIPTION

[FULL DESCRIPTION]

=head1 CONFIGURATION AND ENVIRONMENT
    
No special configurations or environment variables needed
    
    
=head1 DEPENDANCIES

version
Getopt::Long
Pod::Usage
Carp
Readonly
version
Log::Log4perl qw(:easy)
Log::Log4perl::CommandLine qw(:all)
UtilSY qw(:all)

=head1 AUTHOR

Scott Yourstone     scott.yourstone81@gmail.com
    
    
=head1 LICENCE AND COPYRIGHT

Copyright (c) 2015, Scott Yourstone
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met: 

1. Redistributions of source code must retain the above copyright notice, this
   list of conditions and the following disclaimer. 
2. Redistributions in binary form must reproduce the above copyright notice,
   this list of conditions and the following disclaimer in the documentation
   and/or other materials provided with the distribution. 

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

The views and conclusions contained in the software and documentation are those
of the authors and should not be interpreted as representing official policies, 
either expressed or implied, of the FreeBSD Project.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.


=cut
