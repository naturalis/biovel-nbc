# This manifests installs the biovel-mdc nexml-merger/extractor web service on the default
# ubuntu instances hosted by rackspace.

# update the $PATH environment variable for the Exec tasks.                                                                                                                                                 
Exec {
        path => [
                "/usr/local/sbin",
                "/usr/local/bin",
                "/usr/sbin",
                "/usr/bin",
                "/sbin",
                "/bin",
        ]
}

# packages to be installed
package {

  'apache2':	             ensure => installed;
  'libapache2-mod-perl2':    ensure => installed;
  'git':                     ensure => installed;
  'make':                    ensure => installed;
  'libyaml-perl':            ensure => installed;
  'libapreq2':               ensure => installed;
  'libapache2-request-perl': ensure => installed;
  'libwww-perl':             ensure => installed;
  'bioperl':                 ensure => installed;

} 

# ensure that web server is running 
service { 
  'httpd':
    enable  => true,
    ensure  => running,
    require => [ Package[ 'apache2' ], Exec[ 'start_httpd' ] ];
}

# create directory where web service can run
file {

  'webapp_dir':
    path    => '/usr/share/httpd',
    ensure  => directory;

  'webapp_perl_dir':
    path    => '/usr/share/httpd/Perl',
    ensure  => directory,  
    require => File[ 'webapp_dir' ];
  
  'webapp_include_file':
    path    => '/usr/share/httpd/Perl/biovel.pl',
    content => "use lib '/usr/share/httpd/Perl/biovel-nbc/lib';
                1;",
    ensure  => present,
    require => File[ 'webapp_dir' ];
}

# command line tasks
exec {

  # install Bio::Phylo
  'clone_bio_phylo':
    command => 'git clone https://github.com/rvosa/bio-phylo.git',
    cwd     => '/usr/local/src',
    creates => '/usr/local/src/bio-phylo',
    require => Package[ 'git' ];
  'make_install_bio_phylo':
    command => 'perl Makefile.PL && make install',
    cwd     => '/usr/local/src/bio-phylo',
    require => Exec[ 'clone_bio_phylo' ];

  # install https protocol for NWP
  'download_lwp_protocol_https':
    command => 'wget http://search.cpan.org/CPAN/authors/id/G/GA/GAAS/LWP-Protocol-https-6.04.tar.gz',
    cwd     => '/usr/local/src',
    creates => '/usr/local/src/LWP-Protocol-https-6.04.tar.gz',
    require => Package[ 'libwww-perl' ];
  'unzip_lwp_protocol_https':
    command => 'tar xvfz LWP-Protocol-https-6.04.tar.gz',
    cwd     => '/usr/local/src',
    creates => '/usr/local/src/LWP-Protocol-https-6.04/Makefile.PL',
    require => Exec[ 'download_lwp_protocol_https' ];
  'make_lwp_protocol_https':
    command => 'perl Makefile.PL && make install',
    cwd     => '/usr/local/src/LWP-Protocol-https-6.04',
    require => Exec[ 'unzip_lwp_protocol_https' ];
  
  # install mozilla certificates for downloading from remote URLs
  'download_mozilla_ca':
    command => 'wget  http://search.cpan.org/CPAN/authors/id/A/AB/ABH/Mozilla-CA-20130114.tar.gz',
    cwd     => '/usr/local/src',
    creates => '/usr/local/src/Mozilla-CA-20130114.tar.gz',
    require => Package[ 'libwww-perl' ];
  'unzip_mozilla_ca':
    command => 'tar xvfz Mozilla-CA-20130114.tar.gz',
    cwd     => '/usr/local/src',
    creates => '/usr/local/src/Mozilla-CA-20130114/Makefile.PL',
    require => Exec[ 'download_mozilla_ca' ];
  'make_mozilla_ca':
    command => 'perl Makefile.PL && make install',
    cwd     => '/usr/local/src/Mozilla-CA-20130114',
    require => Exec[ 'unzip_mozilla_ca' ];
  
  # clone biovel-nbc web service
  'clone_biovel-nbc':
    command => 'git clone https://github.com/naturalis/biovel-nbc.git',
    cwd     => '/usr/share/httpd/Perl',
    require => [ Package[ 'git' ], File[ 'webapp_dir' ] ];

  # change httpd configuration file to work with perl and biovel-nbc
  'conf_file_mod_perl':
    command => "echo $'### setting up perl for running web applications
                      'LoadModule perl_module $(find / -name mod_perl.so)
                >> /etc/apache2/httpd.conf",
    require => Package[ 'apache2', 'libapache2-mod-perl2' ];
  'conf_file_webapp_dir':
    command => "echo 'PerlRequire /usr/share/httpd/Perl/biovel.pl
                     <Location /biovel>
                         SetHandler perl-script
                         PerlResponseHandler Bio::BioVeL::Service
                     </Location>' >> /etc/apache2/httpd.conf",
    require => [ Package[ 'apache2' ], File[ 'webapp_include_file' ], Exec [ 'clone_biovel-nbc' ] ];

  # disable firewall to make port forwarding work
  'disable_firewall':
    command => 'iptables -F && iptables -A INPUT -p tcp --dport 80 -j ACCEPT';
  
  # start web server after changes to configuration file have been made
  'start_httpd':
    command => 'apachectl restart',
    require => [ Package[ 'apache2' ], Exec[ 'conf_file_mod_perl', 'conf_file_webapp_dir' ] ];
  
}
