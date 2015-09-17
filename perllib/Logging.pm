package Logging;
our $VERSION = '1.3';

# Logging Interface
# If the first argument to Log() is an integer, it is taken to represent the
# log level or priority of that message.  The message is printed when its level
# is <= $Verbosity.
#
# In other words - a higher loglevel = more messages.
# When writing logging, remember that less interesting messages should be tagged with
# a higher loglevel.
#
# The default log level is DEFAULT, which matches the default value of
# $Verbosity.  The rest of the arguments are passed to printf() - if the first
# argument is not a proper printf format string, then the following arguments
# will not be printed.

use strict; use warnings;
use Exporter;

# Symbolic Perl names for each of the log levels.
use constant NONE    => -1;
use constant ERROR   => 0;
use constant WARNING => 1;
use constant DEFAULT => 2;
use constant INFO    => 3;
use constant DEBUG   => 4;


# Default settings
# If you want to inspect or adjust these in your program, use the
# similarly-named function to access their values.  These functions help to
# ensure that these settings always have sensible values (eg. valid log levels,
# non-negative sizes).

# the name of the logfile to write to
my $logName = 'Logging.log';

# default log level
my $logVerbosity = DEFAULT;

# the default log size is 1 Megabyte
my $logSize = 1 << 20;

# by default we keep three previous logs
my $logCount = 3;


# These are the "string" names for each of the log levels; if I want to note
# which log level a message was printed with this will be more useful than
# a number like 1 or 3.
our @LogLevels = qw(ERROR WARNING DEFAULT INFO DEBUG);

our @ISA       = q(Exporter);
our @EXPORT_OK = qw(LogName LogVerbosity LogSize LogCount LogRollover Break Log

	&ERROR &WARNING &DEFAULT &INFO &DEBUG);


sub LogName (;$) {
	my $n = shift;
	if (defined $n) {
		$logName = $n;
	}
	return $logName;
}

sub LogVerbosity (;$) {
	my $n = shift;
	if (defined $n) {
		# this makes sure that we pass in a valid debug level;
		# if the requested level is outside of the set of constants
		# defined above I just set it to DEFAULT
		if ($n == NONE or
			$n == ERROR or
			$n == WARNING or
			$n == INFO or
			$n == DEBUG) {
			$logVerbosity = $n;
		}
		else {
			$logVerbosity = DEFAULT;
		}
	}
	return $logVerbosity;
}


sub LogSize (;$) {
	my $n = shift;
	if (defined $n and $n >= 0) {
		$logSize = $n + 0;
	}
	return $logSize;
}


sub LogCount (;$) {
	my $n = shift;
	if (defined $n and $n >= 0) {
		$logCount = $n + 0;
	}
	return $logCount;
}


# roll the log over when it gets too big
sub LogRollover () {
	use File::Copy;
	use Carp;

	if (-f $logName and -s $logName >= LogSize()) {

		# File::Glob, by default, sorts the filenames it returns
		my @from = grep { -f } <$logName $logName.[1-9]>;
		return unless @from;

		# If the 1st file we globbed is not equal to the base filename, then we may
		# create a new file with the base filename and not clobber anything
		return if $from[0] ne $logName;

		# If there is a gap in the files' numbering, we only need to shift
		# files up to that point and may leave the rest alone
		my $i = 1;
		for (; $i < $logCount; ++$i) {
			# if a file is out-of-sequence, set $i to the missing log #
			last if not defined $from[$i] or $from[$i] !~ /$logName\.$i/;
		}

		# unlink the highest-numbered log, if we need the room
		if ($i == $logCount and -f "$logName.$i") {
			unless (unlink "$logName.$i") {
				carp "Unable to remove '$logName.$i': $!";
			}
		}

		# starting from the top, increment each files' log index
		for (; $i > 1; --$i) {
			my $new = "$logName.$i";
			my $old = sprintf '%s.%d', $logName, $i - 1;
			unless (move($old, $new)) {
				carp "Unable to move '$old' to '$new': $!";
			}
		}

		# finally, add .1 to the newest log file's name
		unless (move($logName, "$logName.1")) {
			carp "Unable to move '$logName' to '$logName.1': $!";
		}
	}
}


# Print a break line to distinguish a new section of the log
sub Break () {
	LogRollover();
	if (open my $logFH, '>>', $logName) {
		print $logFH "\n\n--------------------------------------------------------------------------------\n";
		close $logFH;
	}
}

# Print a message to the screen if the loglevel suffices.  Write everything out to
# the designated log file.  Newlines must be supplied by the user.
#
# If the 1st argument looks like a number, then it is interpreted as a log
# level for this call.  If no log level is given, the prevailing log level is
# used.  If you want to print a message which begins with an integer you should
# explicitly use a log level to avoid this ambiguity.
#
# If you pass more than one message to Log(), then they are passed on to
# printf() for processing.  That is, the 1st message argument is regarded as
# a format string and the remaining arguments are plugged in to the supplied
# designators.
my ($prev, $line, $count) = ('', '', 1);
sub Log ($@) {
	use Scalar::Util qw(looks_like_number);
	my $logLevel = looks_like_number $_[0] ? shift : DEFAULT;
	my $formatted = $#_ > 0;
	LogRollover();

	# write everything out to the log file, taking care that the file is
	# always closed when we're done so that it gets flushed on all OSes
	if (open my $logFH, '>>', $logName) {
		if ($formatted) {
			printf $logFH "<%.3s %s> $_[0]", $LogLevels[$logLevel], scalar localtime, @_[1 .. $#_];
		}
		else {
			printf $logFH "<%.3s %s> %s", $LogLevels[$logLevel], scalar localtime, $_[0];
		}
		close $logFH;
	}

	# print to screen if we care about this loglevel, and do line-per-line
	# flood protection
	if ($logVerbosity >= $logLevel) {
		if ($formatted) {
			$line = sprintf $_[0], @_[1 .. $#_];
		}
		else {
			$line = $_[0];
		}

		if ($line eq $prev) {
			$count++;
		}
		else {
			printf "\t...repeated %d times\n", $count if $count > 1;
			print $line;
			($count, $prev) = (1, $line);
		}
	}
}

1;
