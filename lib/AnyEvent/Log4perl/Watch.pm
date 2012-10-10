package AnyEvent::Log4perl::Watch;

use strict;
use warnings;

use AnyEvent;
use Carp qw(croak);

our $VERSION = $AnyEvent::Log4perl::VERSION;

=head1 NAME

File modification watcher powered by L<AnyEvent>.

=head1 OBJECT CONSTRUCTOR

 # create watcher...
 my $w = AnyEvent::Log4perl::Watch->new(
   file    => '/path/to/log4perl.conf',   # required
   cb      => $cb,                        # required
   watch   => 30,
   signals => [ qw(HUP USR1) ],
 );

=cut
sub new {
  my($class, %opt) = @_;

  my $file = delete($opt{file});
  my $cb = delete($opt{cb});
  croak "Undefined file argument" unless (defined $file);
  croak "Undefined cb argument"   unless (defined $cb);

  my $self = {
    file   => $file,
    _cb    => $cb,
    _watch => 0,
    _mtime => 0,
    _w_s   => [],
    _w_t   => undef,
  };
  bless($self, $class);

  $self->watch($opt{watch} || 30);
  $self->signals($opt{signals}) if (exists($opt{signals}));

  return $self;
};

sub DESTROY {
  my ($self) = @_;
  return unless (defined $self);
  $self->destroy;
}

=head1 METHODS

=cut

=head2 file

Gets/sets watched file

 my $file = $w->file;     # get watched file
 $w->file($new_file);     # sets watched file

=cut
sub file {
  my ($self, $file) = @_;
  return $self->{file} unless (defined $file);
  
  $self->{_mtime} = 0;
  $self->{file} = $file;
}

=head2 watch

Gets/sets watch check for modifications interval

 my $secs = $w->watch;    # are we watching?
 $w->watch(15);           # check for modifications every 15 seconds

=cut
sub watch {
  my ($self, $secs) = @_;
  return $self->{_watch} unless (defined $secs);
  
  undef $self->{_w_t};
  $self->{_w_t} = AE::timer($secs, $secs, sub { $self->_fcheck });
}

=head2 signals

Gets/sets registered signals on which file should be reloaded.

  my @sigs = $w->signals;     # returns list of watched signals...    
  $w->signals(qw(HUP USR1));  # check for modification on HUP and USR1 signals.

=cut
sub signals {
  my $self = shift;
  unless (@_) {
    my @res;
    map { push(@res, $_->[0]) } @{$self->{_w_s}};
    return @res;
  }

  my $l = (ref($_[0]) eq 'ARRAY') ? $_[0] : \@_;
  $self->{_w_s} = [];
  foreach my $name (@{$l}) {
    next unless (exists($SIG{$name}));
    push(
      @{$self->{_w_s}},
      [ $name, AE::signal($name, sub { $self->_fcheck }) ]
    );
  }
}

=head2 cb

Gets/sets callback which is fired when file is changed.

 # get current callback
 my $cb = $w->cb;
 
 # set new callback
 $w->cb(sub {
   my ($file, $mtime) = @_;
   print "File $file has changed.\n";
   
   # modified_cb is fired again after <watch> seconds
   # if callback throws exception even if file didnt change
   if (rand() > 0.5) {
     die "Reloading failed :)\n";
   }
 });

=cut
sub cb {
  my ($self, $cb) = @_;
  return $self->{_cb} unless (defined $cb && ref($cb) eq 'CODE');
  $self->{_cb} = $cb;
}

=head2 destroy

Destroys all active watchers.

=cut
sub destroy {
  my ($self) = @_;
  $self->{_w_s} = [];
  undef $self->{_w_t};
  $self->{_watch} = 0;
}

sub _fcheck {
  my ($self) = @_;
  return unless (defined $self->{file});
  my @s = stat($self->{file});
  return unless (@s);
  
  # file changed!
  if ($s[9] != $self->{_mtime}) {
    if ($self->_fchanged()) {
      $self->{_mtime} = $s[9];
    }
  }
}

sub _fchanged {
  my ($self) = @_;
  return 0 unless (defined $self->{_cb});
  local $@;
  eval { $self->{_cb}->() };
  return ($@) ? 0 : 1;
}

=head2 SEE ALSO

=over

=item * L<AnyEvent::Log4perl>

=item * L<AnyEvent>, L<AE>

=back

=head2 AUTHOR

Brane F. Gracnar

=head1 LICENSE AND COPYRIGHT

Copyright 2012 Brane F. Gracnar.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1;