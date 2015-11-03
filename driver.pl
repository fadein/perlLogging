# This test program logs all of the numbers from 0 to 256; which log level it uses
# depends on the number.  Which numbers are shown on the screen will depend on the
# verbosity level. You can set this by giving this program a number on the command line.
#
# For example, if you run this program like this
# perl driver.pl -1
# you shouldn't see anything.
#
# If you instead run it like this
# perl driver 4
# you should see 258 lines of output.
#
# In any case, all of the output goes into files with names beginning with
# 'squares.log'.


# If you put Logging.pm somewhere under $PERL5LIB you won't need to "use lib 'perllib';"
use lib 'perllib';

# The list of names in the qw() are variables and subroutines defined in Logging.pm.
# You may refer to them by prefixing them with "Logging::", but as that's a lot
# of extra typing you can tell Perl to put those names into the current scope.
#
# An example of why you wouldn't just want to import all of the names would be if
# your program already has a variable named ERROR; you wouldn't want to clobber it
# with the one from Logging.
#
# This way you can choose which variable names to introduce into your program, and
# which ones you don't mind referring to the long way
use Logging qw(Log LogSize LogCount LogVerbosity ERROR WARNING DEFAULT INFO DEBUG);

# This governs which messages are printed to STDOUT.  All messages are written
# to the log file, but we don't always want to flood the screen.  You may call
# this function and change this level whenever you wish.  The logging levels
# are just numbers from -1 to 4.
# When LogVerbosity is set to -1 nothing is written to the screen.
# When LogVerbosity is set to 0 we will only be shown error messages.
# When LogVerbosity is set to 1 we are shown warnings as well as errors.
# When LogVerbosity is set to 4 everything that is written in the log is also
# printed to the screen.
LogVerbosity($ARGV[0]);

# Change the name of the log file - rolled over logs will get names like squares.log.N
Logging::LogName('logs/squares.log');

# How many bytes per log file
LogSize(1 << 12);

# How many old log files to keep
LogCount(5);

Log("The maximum size of %s is %d bytes\n", Logging::LogName(), LogSize());

for my $i (0 .. 256) {

	# log 0 and 256 as ERRORs
	if ($i == 0 or $i == 256) {
		Log(ERROR, sprintf "%d squared is %d\n", $i, $i ** 2);
	}

	# log powers of 2 as WARNINGs
	elsif (not ($i & ($i - 1))) {
		Log(WARNING, sprintf "%d squared is %d\n", $i, $i ** 2); 
	}

	# log multiples of 10 at DEFAULT level, and add a line break to the log
	elsif (not $i % 10) {
		Logging::LogBreak();
		Log(sprintf "%d squared is %d\n", $i, $i ** 2); 
	}

	# log even numbers at INFO
	elsif (not $i % 2) {
		Log(INFO, sprintf "%d squared is %d\n", $i, $i ** 2); 
	}

	# log everything else (that's the odd numbers) at DEBUG level
	else {
		Log(DEBUG, sprintf "%d squared is %d\n", $i, $i ** 2); 
	}
}
