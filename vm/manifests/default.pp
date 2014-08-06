## still TODO:
# need to install http://search.cpan.org/~carlos/Mo-0.38/lib/Mo/default.pod
# need http://search.cpan.org/CPAN/authors/id/I/IS/ISAAC/libapreq2-2.13.tar.gz, install with perl Makefile.PL --with-apache2-apxs=/path/to/apache2/bin/apxs
# need LWP::UserAgent
# need to install supersmart
# need SUPERSMART_HOME environment variable in httpd.conf
# also BIOVEL_HOME
# need to chown /var/www to www-user
# need Proc::ProcessTable
# make /var/www/html writable? sudo chcon -R unconfined_u:object_r:httpd_sys_rw_content_t:s0 /var/www/html
# need Mo::default
# need Sys::Info (might be in supersmart)
# need XML::Twig
# add handler for asynchronous service
# should add ServerName biovel.naturalis.nl to httpd.conf
# must add PerlSetEnv PATH ${PATH}:/usr/local/bin

# This manifests installs the biovel-nbc web services on the default
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

  'git':                     ensure => installed;
  'make':                    ensure => installed;
  'wget':                    ensure => installed;
  'libgdbm-dev'              ensure => installed; # required for manual mod_perl installation
  'libperl-dev'              ensure => installed;
  'libyaml-perl':            ensure => installed;
  'libwww-perl':             ensure => installed;
  'bioperl':                 ensure => installed;

} 

# ensure that web server is running 
#service { 
#  'httpd':
#    enable  => true,
#    ensure  => running,
#    require => [ Package[ 'apache2' ], Exec[ 'start_httpd' ] ];
#}

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

  # install apache http server
  'dl_apache':
    command => 'wget http://apache.mirror.triple-it.nl//httpd/httpd-2.2.27.tar.gz',
    cwd     => '/usr/local/src',
    creates => '/usr/local/src/httpd-2.2.27.tar.gz',
    require => Package[ 'wget' ];
  'unzip_apache':
    command => 'tar xvfz httpd-2.2.27.tar.gz',
    cwd     => '/usr/local/src'
    creates => '/usr/local/src/httpd-2.2.27',
    require => Exec[ 'dl_apache' ];
  'configure_apache':
    command => './configure --prefix=/etc/apache2',
    cwd     => '/usr/local/src/httpd-2.2.27',
    creates => '/usr/local/src/httpd-2.2.27/Makefile',
    require => Exec[ 'unzip_apache' ];
  'install_apache':
    command => 'make && make install',
    cwd     => '/usr/local/src/httpd-2.2.27',
    creates => '/etc/apache2/bin/apachectl',
    require => Exec[ 'configure_apache' ];

  #'symlink_apache':
  #  command => 'ln -s /etc/apache2/bin/apachectl .',
  #  cwd     => '/usr/sbin',
  #  creates => '/usr/sbin/apachectl',
  #  require => Exec[ 'install_apache' ];
  
  # install mod_perl
  'dl_mod_perl':
    command => 'wget http://apache.proserve.nl/perl/mod_perl-2.0.8.tar.gz',
    cwd     => '/usr/local/src',
    creates => '/usr/local/src/mod_perl-2.0.8.tar.gz',
    require => [ Package[ 'wget' ], Exec[ 'install_apache' ] ];
  'unzip_mod_perl':
    command => 'tar xvfz mod_perl-2.0.8.tar.gz',
    cwd     => '/usr/local/src',
    creates => '/usr/local/src/mod_perl-2.0.8',
    require => Exec[ 'dl_mod_perl' ];
  'make_makefile_mod_perl':
    command => 'perl Makefile.PL MP_APXS=/usr/local/apache2/bin/apxs',
    cwd     => '/usr/local/src/mod_perl-2.0.8',
    creates => '/usr/local/src/mod_perl-2.0.8/Makefile',
    require => [ Package[ 'libgdbm-dev', 'libperl-dev' ], Exec[ 'unzip_mod_perl' ] ];
  'install_mod_perl':
    command => 'make && make install',
    cwd     => '/usr/local/src/mod_perl-2.0.8',
    creates => '/usr/local/apache2/modules/mod_perl.so',
    require => Exec[ 'make_makefile_mod_perl' ];
    
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

  #install perl module JSON
   'dl_json':
     command => 'wget http://search.cpan.org/CPAN/authors/id/M/MA/MAKAMAKA/JSON-2.90.tar.gz',
     cwd     => '/usr/local/src',
     creates => '/usr/local/src/JSON-2.90';
   'unzip_json':
     command => 'tar xvfz JSON-2.90.tar.gz',
     cwd     => '/usr/local/src',
     creates => '/usr/local/src/JSON-2.90',
     require => Exec[ 'dl_json' ];
   'make_install_json':
     command => 'perl Makefile.PL && make install',
     cwd     => '/usr/local/src/JSON-2.90',
     require => Exec[ 'unzip_json' ];
  
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
#  'conf_file_mod_perl':
#    command => "echo $'### setting up perl for running web applications
#                      'LoadModule perl_module $(find / -name mod_perl.so)
#                >> /etc/apache2/httpd.conf",
#    require => Package[ 'apache2', 'libapache2-mod-perl2' ];
#  'conf_file_webapp_dir':
#    command => "echo 'PerlRequire /usr/share/httpd/Perl/biovel.pl
#                     <Location /biovel>
#                         SetHandler perl-script
#                         PerlResponseHandler Bio::BioVeL::Service
#                     </Location>' >> /etc/apache2/httpd.conf",
#    require => [ Package[ 'apache2' ], File[ 'webapp_include_file' ], Exec [ 'clone_biovel-nbc' ] ];

  # disable firewall to make port forwarding work
  'disable_firewall':
    command => 'iptables -F && iptables -A INPUT -p tcp --dport 80 -j ACCEPT';
  
  # start web server after changes to configuration file have been made
  #'start_httpd':
  #  command => 'apachectl restart',
  #  require => [ Package[ 'apache2' ], Exec[ 'conf_file_mod_perl', 'conf_file_webapp_dir' ] ];
  
}
