package AnyEvent::Log4perl;

use strict;
use warnings;

use AnyEvent::Log;

=head1 NAME

AnyEvent::Log4perl - Make L<AnyEvent::Log> write logs using L<Log::Log4perl>

=cut

our $VERSION = '0.01';


# file modification watcher object.
my $w = undef;

# AnyEvent::Log infection flag
my $infected = 0;

=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

    use AnyEvent::Log4perl;

    my $foo = AnyEvent::Log4perl->new();
    ...

=head1 EXPORT

A list of functions that can be exported.  You can delete this section
if you don't export anything, such as for a purely object-oriented module.

=head1 CLASS METHODS

=head2 init_and_watch

 # Check configuration file for modifications every 30 seconds
 # and reload it on SIGHUP and SIGUSR1
 AnyEvent::Log4perl->init_and_watch($file, 30, 'HUP', 'USR1')

See also: L<Log::Log4perl/Automatic reloading of changed configuration files>.

=cut

sub init_and_watch {
  my ($class, $file, $seconds, @signals) = @_;
  # recreate file watcher
  $class->destroy;
  $w = AnyEvent::Log4perl::Watcher->new(
    file    => $file,
    watch   => $seconds,
    signals => \@signals,
    cb      => \&_modify_cb,
  );
}

=head2 destroy

Destroys file watcher.

=cut
sub destroy {
  my ($class) = @_;
  undef $w;
}

=head2 infect

Replaces L<AnyEvent::Log> implementation in a way that logging messages are
sent to L<Log::Log4perl> loggers.

=cut
sub infect {
  return if ($infected);

  no warnings;
  *AnyEvent::Log::_log = \& _ae_log;
  AE::log(debug => "Replaced AE::log logging function.");
}

sub _modify_cb {
  my ($file, $mtime) = @_;
  my $log = Log::Log4perl->get_logger(__PACKAGE__);

  # try to reconfigure loggers
  local $@;
  eval { Log::Log4perl->init($file) };
  if ($@) {
    $log->error("Exception while reconfiguring log4perl: $@");
    # rethrow exception
    die $@;
  }

  # looks like we were successfully reconfigured :)
  $log->info("Log4perl configuration was successfully reloaded [$file]");
}

sub _ae_log($$;@) {
  my ($ctx, $level, $fmt, @args) = @_;
  my $msg = (@args) ? sprintf($fmt, @args) : $fmt;

  no warnings;
  my $l = ($level ne 'info') ? $AnyEvent::Log::LEVEL2STR[$level] : 'info';
  $l = 'debug' if ($l eq '0');
  _log($l, $msg);
}

sub _log {
  my $lvl = shift;
  $lvl = 'info' unless (defined $lvl || $lvl eq 'note');
  $lvl = 'error' if ($lvl eq 'critical' || $lvl eq 'alert');
  $lvl = uc($lvl);

  # trick Log4perl to figure out the REAL caller :)
  no warnings;
  local $Log::Log4perl::caller_depth += 2;

  Log::Log4perl->get_logger()->log(Log::Log4perl::Level::to_priority($lvl), @_);
}
=head1 AUTHOR

Brane F. Gracnar

=head1 SEE ALSO

=over

=item * L<Log::Log4perl>: Best logging solution for perl

=item * L<Log::Log4perl::Appender::AE>: Async log4perl appender

=item * L<AnyEvent::Log>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2012 Brane F. Gracnar.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1;