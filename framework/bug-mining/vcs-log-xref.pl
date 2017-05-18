#! /usr/bin/env perl
#
#-------------------------------------------------------------------------------
# Copyright (c) 2014-2015 René Just, Darioush Jalali, and Defects4J contributors.
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

vcs-log-xref.pl -- Parses the development history log for a project screening it with a
                      regular expression, and validates that they pass
                      a test provided by a script that can verify they are bugs (as opposed to
                      improvements, pull requests, etc.)

=head1 SYNOPSIS

vcs-log-xref.pl vcs-type -b bug-matching-perl-regexp -l commit-log -r repository -c command-to-verify

=head1 DESCRIPTION

C<vcs-type> is one of C<git> or C<svn>.

C<commit-log> is the part of the development history that you wish to cross-reference with an issue tracker.
This file may be obtained for example by running C<git log>.

C<bug-matching-perl-regexp> is the perl regular expression that will match the issue (e.g., /LANG-(\d+)/mi),
and the C<repository> is the path to the git repo for this project (this argument is ignored for SVN).

C<command-to-verify> is a command to run that will verify whether a given issue ID is a bug.
The framework currently supplies two auxillary scripts (C<verify-bug-file.sh> and C<verify-bug-sf-tracker.sh>)
that help with this task. You may also supply your own.

=cut

use strict;
use warnings;

use File::Basename;
use Getopt::Std;
use List::Util qw(all pairmap);
use Pod::Usage;

my %supported_vcs = (
    'git' => {
            'get_commits' => sub {
                            my ($fh, $command, $regexp) = @_;
                            die unless all {defined $_} ($fh, $command, $regexp);
                            my @results = ();
                            my $commit = '';
                            while (<$fh>) {
                                chomp ;
                                if (/^commit (.*)/) {
                                    <$fh>; # author line -> uninteresting
                                    <$fh>; # date line   -> uninteresting
                                    $commit = $1;
                                    next;
                                }
                                next unless $commit; # skip lines before first commit info.
                                if (my $bug_number = eval('$_ =~' . "$regexp" . '; $1')) {
                                   
				                					#This condition was set to work with Guava, may not mork for other.
			                  					#Omit this condition if you running another project.
		                							if (my $bug =eval('$bug_number =~' . "/.*?\\s*#?(\\d+)/" . '; $1')){

                                   #next unless system("${command} ${bug_number}") == 0; # skip bug ids that do not

									                  #This is work just for Guava.
					                  				#For other project delete this one and use the previous one.
		                  							next unless system("${command} ${bug}") == 0; # skip bug ids that do not

                                    my $parent = _git_get_parent($commit);
                                    next unless $parent; # skip revisions without parent:
                                                         # this can be the first revision or
                                                         # due to bad history rewriting
                                    push @results, ($parent, $commit);
                                    $commit = '';        # unset to skip lines until next commit
                                }
                            }
                            return \@results;
                }
        },
    'svn' => {
            'get_commits' => sub {
                                my ($fh, $command, $regexp) = @_;
                                die unless all {defined $_} ($fh, $command, $regexp);
                                my @results = ();
                                my $commit = '';
                                while (<$fh>) {
                                    chomp;
                                    if (/^r(\d+) \| .* \| \d+ line/) {
                                        $commit = $1;
                                        next;
                                    }
                                    next unless $commit; # skip lines before first commit info.
                                    if (my $bug_number = eval('$_ =~' . "$regexp" . '; $1')) {
                                        next unless system("${command} ${bug_number}") == 0; # skip bug ids that do not
                                                                                             # pass the test

                                        my $parent = $commit - 1;
                                        next unless $parent > 0; # skip first revision
                                        push @results, ($parent, $commit);
                                        $commit = '';        # unset to skip lines until next commit
                                    }
                                }
                                return \@results;
                    }
        }
);

my $vcs_name = shift @ARGV;
die "usage: " . basename($0) . " vcs_type \n" .
    "\t supported vcs types: " . join (' ', sort keys (%supported_vcs))
        unless defined $vcs_name and
               defined $supported_vcs{$vcs_name};
my %vcs = %{$supported_vcs{$vcs_name}};

sub _usage {
    die "usage: " . basename($0) . "\n"
                . "\t -b bug-matching-perl-regexp \n"
                . "\t -l commit-log\n"
                . "\t -r repository\n"
                . "\t -c command-to-verify\n"
                ;
}
my %cmd_opts;
getopts('b:l:r:c:', \%cmd_opts) or _usage();

my ($regexp, $logfile, $repo, $command) =
        ($cmd_opts{b},
         $cmd_opts{l},
         $cmd_opts{r},
         $cmd_opts{c},
 );

_usage() unless all {defined $_} ($regexp, $logfile, $repo, $command);

open my $fh, $logfile or die "could not open commit-log $logfile";
my @commits = @{$vcs{'get_commits'}($fh, $command, $regexp)};
close $fh;
print join ('', (pairmap {"$a,$b\n"} @commits));

###########################
sub _git_get_parent {
    my $commit = shift;
    die unless $commit;
    my @parents = _git_get_parent_revisions($commit);
    die "too many parents" unless (@parents == 1);
    return $parents[0];
}

sub _git_get_parent_revisions {
    my $revision_no = shift;
    die unless $revision_no;
    # returns a string <revision-no> <parent1> <parent2> <parent3> ...
    my $result = `git --git-dir=${repo} rev-list --parents -n 1 ${revision_no}`;
    die unless $? == 0;
    chomp $result;
    die "Could not run git" unless $? == 0;
    my @split_var = split / /, $result;
    return @split_var[1,]
}
