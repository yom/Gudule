use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Gudule::Server',
    AUTHOR              => 'Guillaume Blairon <g@yom.be>',
    VERSION_FROM        => 'lib/Gudule/Server.pm',
    ABSTRACT_FROM       => 'lib/Gudule/Server.pm',
    PL_FILES            => {},
    EXE_FILES           => [ 'gudule' ],
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Gudule-*' },
);
