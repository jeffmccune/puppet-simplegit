# Class: simplegit
# ===========================
#
# This class configures a simple git service using SSH and intended to be used
# in vagrant environments with Puppet Enterprise Code Manager.  The end goal is
# the ability to git push a control repository and have that repositry
# automatically available in a vagrant PE master.
#
# This module is meant to be run on a PE Monolithic Master.  It will configure
# SSH keys as per: https://docs.puppet.com/pe/2016.2/code_mgr_config.html
class simplegit (
  $gituser = 'git',
  $githome = '/var/lib/git',
  $sshkey = '/etc/puppetlabs/puppetserver/ssh/id-control_repo.rsa',
  $authorized_keys = [],
) {
  if $::osfamily != 'RedHat' {
    fail("Not supported on ${::osfamily}")
  }

  Package {
    ensure => present
  }
  File {
    owner => 'git',
    group => 'git',
    mode  => '0600',
  }
  Service {
    ensure => running,
    enable => true,
  }

  package { 'git': }

  user { "$gituser":
    home    => "$githome",
    require => File["$githome"],
  }

  file { "$githome":
    ensure => directory,
  }
  file { "$githome/.ssh":
    ensure => directory,
  }
  file { "$githome/.ssh/authorized_keys":
    ensure => file,
    mode   => '0644',
  }
  $authorized_keys.each |Integer $idx, String $pubkey| {
    file_line { "$githome/.ssh/authorized_keys:$idx":
      path    => "$githome/.ssh/authorized_keys",
      line    => "$pubkey",
      require => File["$githome/.ssh/authorized_keys"]
    }
  }
}
