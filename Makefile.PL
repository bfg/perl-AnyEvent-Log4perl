use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'AnyEvent::Log4perl',
    AUTHOR              => q{Brane F. Gracnar <bfg@frost.ath.cx>},
    VERSION_FROM        => 'lib/AnyEvent/Log4perl.pm',
    ABSTRACT_FROM       => 'lib/AnyEvent/Log4perl.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'AnyEvent-Log4perl-*' },
);
