package Log::Log4perl::Appender::AE;
 
our @ISA = qw(Log::Log4perl::Appender);

use strict;
use warnings;

use AnyEvent;
use AnyEvent::Handle;

use Fcntl;
use constant _INTERNAL_DEBUG => 0;

our $VERSION = $AnyEvent::Log4perl::VERSION;

sub new {
  my ($class, %opt) = @_;
  my $self = {
    name    => "unknown name",
    umask   => undef,
    owner   => undef,
    group   => undef,
    autoflush => 1,
    syswrite  => 0,
    mode    => "append",
    binmode   => undef,
    utf8    => undef,
    create_at_logtime     => 0,
    header_text       => undef,
  };

=pod 
  if($self->{create_at_logtime}) {
    $self->{recreate}  = 1;
  }
 
  if(defined $self->{umask} and $self->{umask} =~ /^0/) {
      # umask value is a string, meant to be an oct value
    $self->{umask} = oct($self->{umask});
  }
 
  die "Mandatory parameter 'filename' missing" unless
    exists $self->{filename};
 
  bless $self, $class;
 
  if($self->{recreate_pid_write}) {
    print "Creating pid file",
        " $self->{recreate_pid_write}\n" if _INTERNAL_DEBUG;
    open FILE, ">$self->{recreate_pid_write}" or 
      die "Cannot open $self->{recreate_pid_write}";
    print FILE "$$\n";
    close FILE;
  }
 
    # This will die() if it fails
  $self->file_open() unless $self->{create_at_logtime};
=cut
  return $self;
}

1;