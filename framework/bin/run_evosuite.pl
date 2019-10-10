#!/usr/bin/env perl
#
#-------------------------------------------------------------------------------
# Copyright (c) 2014-2017 René Just, Darioush Jalali, and Defects4J contributors.
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.
#-------------------------------------------------------------------------------

=pod

=head1 NAME

run_evosuite.pl -- generate test suites using EvoSuite.

=head1 SYNOPSIS

  run_evosuite.pl -p project_id -v version_id -n test_id -o out_dir -c criterion [-ap approach] [-b search_budget] [-a assertion_timeout] [-t tmp_dir] [-D] [-A]

=head1 OPTIONS

=over 4

=item -p C<project_id>

Generate tests for this project id.
See L<Project|Project/"Available Project IDs"> module for available project IDs.

=item -v C<version_id>

Generate tests for this version id.
Format: C<\d+[bf]>.

=item -n C<test_id>

The id of the generated test suite (i.e., which run of the same configuration).

=item -o F<out_dir>

The root output directory for the generated test suite. The test suite and logs are
written to:
F<out_dir/project_id/version_id>.

=item -c C<criterion>

Generate tests for this criterion using the default search budget.
See below for supported test criteria.

=item -ap C<approach_id>

The selected approach to use (with or without RL)

=item -b C<search_budget>

Set a specific search budget (optional). See below for defaults.

=item -a C<assertion_timeout>

Set a specific timeout for assertion generation (optional).
The default is 300sec.

=item -t F<tmp_dir>

The temporary root directory to be used to check out the program version (optional).
The default is F</tmp>.

=item -D

Debug: Enable verbose logging and do not delete the temporary check-out directory
(optional).

=item -A

All relevant classes: Generate tests for all relevant classes (i.e., all classes
touched by the triggering tests). By default tests are generated only for
classes modified by the bug fix.


=back

=head1 DESCRIPTION

This script runs EvoSuite for a particular program version. Tests can be generated for 1)
all classes touched by the triggering test or 2) all classes that were modified to fix the
bug. The latter is the default behavior.

=head2 Supported test criteria and default search budgets

=over 4

=item * B<branch> => 100sec

=item * B<weakmutation> => 100sec

=item * B<strongmutation> => 200sec

=back

=cut
my %criteria = ( branch         => 120,
                 weakmutation   => 120,
                 strongmutation => 120,
                 onlymutation => 120,
                 defuse => 120,
                 cbranch => 120,
                 ibranch => 120,
                 statement => 120,
                 rho => 120,
                 ambiguitiy => 120,
                 alldefs => 120,
                 exception => 120,
                 regression => 120,
                 readability => 120,
                 onlybranch => 120,
                 methodtrace => 120,
                 method => 120,
                 methodnoexception => 120,
                 onlyline => 120,
                 line => 120,
                 output => 120,
                 input => 120,
                 trycatch => 120,
                 default => 120,
		 mcc => 120,
		 "branch:mcc" => 120,
		 "branch:mcc:method" => 120,
		 "mcc:method" => 120,
		 "onlybranch:mcc" => 120,
                 "branch:line" => 120,
                 "branch:line:cbranch" => 120,
                 "branch:line:cbranch:weakmutation" => 120,
                 "branch:line:cbranch:weakmutation:method" => 120,
                 "branch:cbranch" => 120,
                 "branch:weakmutation" => 120,
                 "branch:weakmutation:cbranch" => 120,
                 "branch:weakmutation:cbranch:exception" => 120,
                 "cbranch:branch:line:weakmutation:output" => 120,
                 "branch:exception" => 120,
                 "branch:exception:cbranch" => 120,
                 "branch:weakmutation" => 120,
                 "branch:weakmutation:method" => 120,
                 "branch:output" => 120,
                 "branch:output:line" => 120,
                 "branch:output:line:weakmutation" => 120,
                 "branch:weakmutation:line" => 120,
                 "cbranch:weakmutation" => 120,
                 "branch:line:weakmutation:exception" => 120,
                 "branch:cbranch:weakmutation:output" => 120,
                 "branch:exception:line" => 120,
                 "branch:exception:line:methodnoexception" => 120,
                 "cbranch:weakmutation:output" => 120,
                 "branch:line:output:exception" => 120,
                 "cbranch:branch:line:exception" => 120,
                 "cbranch:exception" => 120,
                 "branch:exception:method" => 120,
                 "branch:line:method" => 120,
                 "branch:exception:line:method" => 120,
                 "branch:line:output:exception:method" => 120,
                 "branch:line:weakmutation:exception:method" => 120,
         "BRANCH"                      =>120,
		 "LINE"                      =>120,
		 "EXCEPTION"                 =>120,
		 "WEAKMUTATION"              =>120,
		 "OUTPUT"                    =>120,
		 "METHOD"                    =>120,
		 "CBRANCH"                   =>120,
		 "METHODNOEXCEPTION"         =>120,
         "STRONGMUTATION"	     =>120,
		 "BRANCH:LINE"                      =>120,
		 "BRANCH:EXCEPTION"                 =>120,
		 "BRANCH:WEAKMUTATION"              =>120,
		 "BRANCH:OUTPUT"                    =>120,
		 "BRANCH:METHOD"                    =>120,
		 "BRANCH:CBRANCH"                   =>120,
		 "BRANCH:METHODNOEXCEPTION"         =>120,
		 "LINE:EXCEPTION"                   =>120,
		 "LINE:METHOD"                      =>120,
		 "LINE:CBRANCH"                     =>120,
		 "LINE:METHODNOEXCEPTION"           =>120,
		 "LINE:WEAKMUTATION"                =>120,
		 "LINE:OUTPUT"                      =>120,
		 "CBRANCH:METHOD"                   =>120,
		 "CBRANCH:EXCEPTION"                =>120,
		 "CBRANCH:METHODNOEXCEPTION"        =>120,
		 "CBRANCH:WEAKMUTATION"             =>120,
		 "CBRANCH:OUTPUT"                   =>120,
		 "METHOD:EXCEPTION"                 =>120,
		 "METHOD:METHODNOEXCEPTION"         =>120,
		 "METHOD:WEAKMUTATION"              =>120,
		 "METHOD:OUTPUT"                    =>120,
		 "EXCEPTION:METHODNOEXCEPTION"      =>120,
		 "EXCEPTION:WEAKMUTATION"           =>120,
		 "EXCEPTION:OUTPUT"                 =>120,
		 "METHODNOEXCEPTION:WEAKMUTATION"   =>120,
		 "METHODNOEXCEPTION:OUTPUT"         =>120,
		 "WEAKMUTATION:OUTPUT"              =>120,
		 "BRANCH:LINE:OUTPUT"               =>120,
		 "BRANCH:LINE:CBRANCH"              =>120,
		 "BRANCH:LINE:METHODNOEXCEPTION"    =>120,
		 "BRANCH:LINE:EXCEPTION"            =>120,
		 "BRANCH:LINE:WEAKMUTATION"         =>120,
		 "BRANCH:LINE:METHOD"               =>120,
		 "BRANCH:METHOD:OUTPUT"             =>120,
		 "BRANCH:METHOD:CBRANCH"            =>120,
		 "BRANCH:METHOD:METHODNOEXCEPTION"  =>120,
		 "BRANCH:METHOD:EXCEPTION"          =>120,
		 "BRANCH:METHOD:WEAKMUTATION"       =>120,
		 "BRANCH:WEAKMUTATION:OUTPUT"       =>120,
		 "BRANCH:WEAKMUTATION:CBRANCH"      =>120,
		 "BRANCH:WEAKMUTATION:METHODNOEXCEPTION"     =>120,
		 "BRANCH:WEAKMUTATION:EXCEPTION"    =>120,
		 "BRANCH:EXCEPTION:OUTPUT"          =>120,
		 "BRANCH:EXCEPTION:CBRANCH"         =>120,
		 "BRANCH:EXCEPTION:METHODNOEXCEPTION"        =>120,
		 "BRANCH:METHODNOEXCEPTION:OUTPUT"  =>120,
		 "BRANCH:METHODNOEXCEPTION:CBRANCH" =>120,
		 "BRANCH:CBRANCH:OUTPUT"            =>120,
		 "LINE:METHOD:OUTPUT"               =>120,
		 "LINE:METHOD:CBRANCH"              =>120,
		 "LINE:METHOD:METHODNOEXCEPTION"    =>120,
		 "LINE:METHOD:EXCEPTION"            =>120,
		 "LINE:METHOD:WEAKMUTATION"         =>120,
		 "LINE:WEAKMUTATION:OUTPUT"         =>120,
		 "LINE:WEAKMUTATION:CBRANCH"        =>120,
		 "LINE:WEAKMUTATION:METHODNOEXCEPTION"      =>120,
		 "LINE:WEAKMUTATION:EXCEPTION"      =>120,
		 "LINE:EXCEPTION:OUTPUT"            =>120,
		 "LINE:EXCEPTION:CBRANCH"           =>120,
		 "LINE:EXCEPTION:METHODNOEXCEPTION"        =>120,
		 "LINE:METHODNOEXCEPTION:OUTPUT"    =>120,
		 "LINE:METHODNOEXCEPTION:CBRANCH"   =>120,
		 "LINE:CBRANCH:OUTPUT"              =>120,
		 "METHOD:WEAKMUTATION:OUTPUT"       =>120,
		 "METHOD:WEAKMUTATION:CBRANCH"      =>120,
		 "METHOD:WEAKMUTATION:METHODNOEXCEPTION"    =>120,
		 "METHOD:WEAKMUTATION:EXCEPTION"    =>120,
		 "METHOD:EXCEPTION:OUTPUT"          =>120,
		 "METHOD:EXCEPTION:CBRANCH"         =>120,
		 "METHOD:EXCEPTION:METHODNOEXCEPTION"        =>120,
		 "METHOD:METHODNOEXCEPTION:OUTPUT"  =>120,
		 "METHOD:METHODNOEXCEPTION:CBRANCH"  =>120,
		 "METHOD:CBRANCH:OUTPUT"             =>120,
		 "WEAKMUTATION:EXCEPTION:OUTPUT"     =>120,
		 "WEAKMUTATION:EXCEPTION:CBRANCH"    =>120,
		 "WEAKMUTATION:EXCEPTION:METHODNOEXCEPTION"  =>120,
		 "WEAKMUTATION:METHODNOEXCEPTION:OUTPUT"     =>120,
		 "WEAKMUTATION:METHODNOEXCEPTION:CBRANCH"    =>120,
		 "WEAKMUTATION:CBRANCH:OUTPUT"        =>120,
		 "EXCEPTION:METHODNOEXCEPTION:OUTPUT" =>120,
		 "EXCEPTION:METHODNOEXCEPTION:CBRANCH"       =>120,
		 "EXCEPTION:CBRANCH:OUTPUT"           =>120,
		 "METHODNOEXCEPTION:CBRANCH:OUTPUT"   =>120,
		 "LINE:BRANCH:EXCEPTION:WEAKMUTATION:OUTPUT:METHOD:METHODNOEXCEPTION:CBRANCH" => 120,
		 "LINE:BRANCH:EXCEPTION:WEAKMUTATION:STRONGMUTATION:OUTPUT:METHOD:METHODNOEXCEPTION:CBRANCH" => 120

               );

=pod

=head2 EvoSuite configuration

The filename of an optional EvoSuite configuration file can be provided with the
environment variable C<EVO_CONFIG_FILE>. The default configuration file of EvoSuite
is: F<framework/util/evo.config>.

=cut
use strict;
use warnings;

use FindBin;
use File::Basename;
use Cwd qw(abs_path);
use Getopt::Std;
use Pod::Usage;

use lib abs_path("$FindBin::Bin/../core");
use Constants;
use Utils;
use Project;
use Log;


#
# Process arguments and issue usage message if necessary.
#
my %cmd_opts;
getopts('p:v:o:n:t:c:h:b:a:ACD', \%cmd_opts) or pod2usage(1);

pod2usage(1) unless defined $cmd_opts{p} and
                    defined $cmd_opts{v} and
                    defined $cmd_opts{n} and
                    defined $cmd_opts{o} and
                    defined $cmd_opts{c};
my $PID = $cmd_opts{p};
# Instantiate project
my $project = Project::create_project($PID);

my $VID = $cmd_opts{v};
# Verify that the provided version id is valid
my $BID = Utils::check_vid($VID)->{bid};
$project->contains_version_id($VID) or die "Version id ($VID) does not exist in project: $PID";

my $TID = $cmd_opts{n};
$TID =~ /^\d+$/ or die "Wrong test_id format (\\d+): $TID!";
my $OUT_DIR = $cmd_opts{o};
my $CRITERION = $cmd_opts{c};
my $BUDGET = $cmd_opts{b};
my $TIMEOUT = $cmd_opts{a} // 300;

# Validate criterion and set search budget
my $default = $criteria{$CRITERION};
unless (defined $default) {
    die "Unknown criterion: $CRITERION!";
}
$BUDGET = $BUDGET // $default;
# Enable debugging if flag is set
$DEBUG = 1 if defined $cmd_opts{D};

my $CLASSES = defined $cmd_opts{A} ? "loaded_classes" : "modified_classes";
$CLASSES = defined $cmd_opts{C} ? "selected_classes" :  $CLASSES;

# List of target classes
my $TARGET_CLASSES = "$SCRIPT_DIR/projects/$PID/$CLASSES/$BID.src";

# Temporary directory for project checkout
my $TMP_DIR = Utils::get_tmp_dir($cmd_opts{t});
system("mkdir -p $TMP_DIR");

# Set working directory
$project->{prog_root} = $TMP_DIR;


my $approach = $cmd_opts{h};
print("It will use the approach $approach");
unless (defined $approach) {
   $approach = "EVSNORL";
   print("It will use the defaults approach $approach");
}

=pod

=head2 Logging

By default, the script logs all errors and warnings to F<run_evosuite.log> in
the temporary project root.
Upon success, the log of this script is appended to:
F<out_dir/logs/C<project_id>.C<version_id>.log>.

=cut
# Log file in output directory
my $LOG_DIR = "$OUT_DIR/logs";
my $LOG_FILE = "$LOG_DIR/$PID.$VID.log";
system("mkdir -p $LOG_DIR");

# Checkout and compile project
$project->checkout_vid($VID) or die "Cannot checkout!";
$project->compile() or die "Cannot compile!";

# Open temporary log file
my $LOG = Log::create_log("$TMP_DIR/run_evosuite.log");

$LOG->log_time("Start test generation");

open(LIST, "<$TARGET_CLASSES") or die "Could not open list of target classes $TARGET_CLASSES: $!";
my @classes = <LIST>;
close(LIST);
# Iterate over all modified classes
my $log = "$TMP_DIR/$PID.$VID.$CRITERION.$TID.log";
foreach my $class (@classes) {
    chomp $class;
    $LOG->log_msg("Generate tests for: $class : $CRITERION : ${BUDGET}s");
    # Call evosuite with criterion, time, and class name
    my $config = "$UTIL_DIR/evo.config";
    # Set config to environment variable if defined
    $config = $ENV{EVO_CONFIG_FILE} // $config;
    $project->run_evosuite($CRITERION, $BUDGET, $class, $approach, $TIMEOUT, $config, $log) or die "Failed to generate tests!";
}
# Copy log file for this version id and test criterion to output directory
system("mv $log $LOG_DIR") == 0 or die "Cannot copy log file!";

=pod

=head2 Test suites

The source files of the generated test suite are compressed into an archive with the
following name:
F<C<project_id>-C<version_id>-evosuite-C<criterion>.C<test_id>.tar.bz2>

Examples:

=over 4

=item * F<Lang-12b-evosuite-weakmutation.1.tar.bz2>

=item * F<Lang-12f-evosuite-branch.2.tar.bz2>

=back

The test suite archive is written to:
F<out_dir/C<project_id>/evosuite-C<criterion>/C<test_id>>

=cut

# Compress generated tests
(my $cri_no_semicolon = $CRITERION) =~ s/:/-/g;
my $archive = "$PID-$VID-evosuite-$cri_no_semicolon.$TID.tar.bz2";
if (system("tar -cjf $TMP_DIR/$archive -C $TMP_DIR/evosuite-$CRITERION/ .") != 0) {
    $LOG->log_msg("Error: cannot archive and ompress test suite!");
} else {
    # Move test suite to OUT_DIR/pid/suite_src/test_id
    #
    # e.g., .../Lang/evosuite-branch/1
    #
    my $dir = "$OUT_DIR/$PID/evosuite-$cri_no_semicolon/$TID";
    system("mkdir -p $dir && mv $TMP_DIR/$archive $dir") == 0 or die "Cannot move test suite archive to output directory!";
}

$LOG->log_time("End test generation");

# Close temporary log and append content to log file in output directory
$LOG->close();
system("cat $LOG->{file_name} >> $LOG_FILE");

# Remove temporary directory
system("rm -rf $TMP_DIR") unless $DEBUG;
