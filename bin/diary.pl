#!/usr/bin/perl
#****************************************************************************
# script::name= diary.pl
# script::desc= a simple diary for recording items that I am working on
# script::author= jdamon
# script::cvs= $Id$
# script::changed= $Date$
# script::modusr= $Author$
# script::notes=
# script::todo=
#****************************************************************************



#*******************************  LIBRARIES  ********************************
use lib ("/tools/mxlcad");
#use MXL::DB;
use DBI;
use Getopt::Std;
use strict;
use Getopt::Long;
use Date::Manip qw(/\S+/);
use YAML qw(Dump);
#****************************  GLOBAL VARIABLES  ****************************

my $FILE_LOCATION=$ENV{HOME};
my $FILE='.notes.db';

my %opts;
my @results;

my $query;
my $dbh;
my $sth;
my $RAKE_OPTIONS = "";
my $RAKE = "rake -I$ENV{HOME}/.rake $RAKE_OPTIONS ";

#**********************************  CODE  **********************************
#getopts("lnc:f:e:d:t", \%opts);
GetOptions(\%opts,
           "list|l",
           "counttasks|n",
           "clear",
           "delete|d:i",
           "tasksonly|t",
           "addtask|newtask=s",
           "duedate|due=s",
           "expcomplete|expected=s",
           "search|f|s=s",        # Search for a string
           "start=s",
           "parent=s",
          );
if( $opts{list} ) {
    system("DIARY=\"$ARGV[0]\" ${RAKE}  -s diary:writeTasks")
} elsif( $opts{addtask} ) {
    $opts{duedate} = UnixDate($opts{duedate},"%b %d %T %Y");
    $opts{expcomplete} = UnixDate( $opts{expcomplete}, "%b %d %T %Y");
    system("${RAKE}  -s diary:addTask[\"$opts{addtask}\",\"$opts{duedate}\",\"$opts{expcomplete}\",\"$opts{parent}\"]\n");
} elsif( $opts{search} ) {
    system("${RAKE}  -s diary:searchDiary[$opts{search}]");
} elsif( $opts{tasksonly} ) {
    system("${RAKE}  -s diary:listTasks")
} elsif( defined $opts{delete} && ! $opts{delete} ) {
    system("${RAKE}  -s diary:deleteLastDiary[\"$opts{delete}\"]")
} elsif( $opts{counttasks} ) {
    system("${RAKE}  -s diary:newlistTasks");
} elsif( $#ARGV == 0 ) {
    system("DIARY=\"$ARGV[0]\" ${RAKE}  -s diary:addDiary")
} elsif( $#ARGV < 0 ) {
    usage();
}


sub usage
{
 print "This command is used to list notes in ";
 print "a database.\n\n";
 print "diary.pl \"DIARY ENTRY\" | [OPTIONS]\n";
 print "          -addtask PROJECT -duedate DUEDATE -expcomplete EXPECTED_COMPLETED\n\n";
 print "          -l list all notes\n";
 print "          -t [TASK_REGEX?] list tasks matching regex\n";
 print "          -s <search string> seach for text\n";
 print "          -e <cmd> execute command and add to notes\n";
 print "          -d delete last entry\n";
 exit 2;
}




