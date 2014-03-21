# This manifests installs the biovel-mdc nexml-merger/extractor web service on a virtual machine.
# The service will be deployed on an apache server running on the virtual guest.

# packages to be installed
package {

  "httpd":	ensure => installed;
  "mod_perl":   ensure => installed;
  
} 

# ensure that web server is running
service { 
	"mysqld":
	  enable  => true,
	  ensure  => running,
	  require => Package["httpd"],
}

# command line tasks
exec {
  "conf_mod_perl":
    command => "echo $'\n### setting up perl for running web applications\n'LoadModule perl_module $(find / -name mod_perl.so) >> /etc/httpd/conf/httpd.conf",
    require => [Package [ 'httpd', 'mod_perl' ] ];
  
  

  
}
