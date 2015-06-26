use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'NCI::OCG::TARGET::Circos',
    AUTHOR              => q/Leandro Hermida <leandro.hermida@nih.gov>/,
    VERSION_FROM        => 'lib/NCI/TARGET/Circos.pm',
    ABSTRACT            => 'NCI TARGET Circos Plot Viewer',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES => {},
    PREREQ_PM => {
        'Clone'                     => 0,
        'JSON::XS'                  => 0,
        'JSON'                      => 0,
        'YAML'                      => 0,
        'Image::Info'               => 0,
        'Image::Size'               => 0,
        'Module::Refresh'           => 0,
        'Template'                  => 0,
        'Plack'                     => 0,
        'Test::More'                => 0,
        'Dancer'                    => 1.3112,
        'Dancer::Plugin::Thumbnail' => 0,
        'Starman'                   => 0,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'NCI-TARGET-Circos-*' },
);
