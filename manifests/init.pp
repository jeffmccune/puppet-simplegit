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
  Exec {
    path => ['/sbin', '/usr/sbin', '/bin', '/usr/bin']
  }

  package { 'git': }

  user { "$gituser":
    home    => "$githome",
    require => File["$githome"],
  }

  file { "$githome":
    ensure => directory,
  }
  file { "$githome/.bash_profile":
    ensure  => file,
    content => "PS1='[\u@\h \W]\$ '\n"
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

  # SELinux management, requires selinux module to manage the policytools
  # pacakge providing the semanage command
  exec { "semanage fcontext -a -t ssh_home_t $githome/.ssh":
    unless => "ls -Z $githome/.ssh | grep ssh_home_t",
    notify => Exec["restorecon -v $githome/.ssh"],
  }
  exec { "semanage fcontext -a -t ssh_home_t $githome/.ssh/authorized_keys":
    unless => "ls -Z $githome/.ssh/authorized_keys | grep ssh_home_t",
    notify => Exec["restorecon -v $githome/.ssh/authorized_keys"],
  }
  exec { "restorecon -v $githome/.ssh":
    refreshonly => true,
  }
  exec { "restorecon -v $githome/.ssh/authorized_keys":
    refreshonly => true,
  }
}
