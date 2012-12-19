node build {
	class { 'sudo':
		config_file_replace => false,
}

	dnsmasq::conf { 'another-config':
        ensure  => present,
        content => "interface=eth1\ndhcp-range=10.10.20.100,10.10.20.150,12h\ndhcp-boot=pxelinux.0\ndhcp-option=3,10.10.20.1\ndhcp-option=6,8.8.8.8"
}

	class { 'tftp':
		address   => '10.10.20.1',
}

	file {'motd':
      		ensure  => file,
      		path    => '/etc/motd',
      		mode    => 0644,
      		content => "Welcome to ${hostname},\na ${operatingsystem} island in the sea of ${domain}.\n",
}

	file { "/etc/hosts":
        	owner => root,
        	group => root,
        	mode => 644,
        	content => template("hosts/hosts.erb"),
}

	class { 'razor':
		address => $ipaddress_eth1,
		username => 'razor',
		directory => '/opt/razor'
}
  
	rz_image { "ubuntu-12.04.1-server-amd64.iso":
		ensure  => present,
		type    => 'os', 
		version => '12.04.1',
		source  => "http://de.archive.ubuntu.com/ubuntu/dists/precise/main/installer-amd64/current/images/netboot/mini.iso",
}

	rz_broker { 'puppet_broker':
		ensure      => present,
#	  	description => 'puppet',
		plugin      => 'puppet',
		servers     => [ "$fqdn" ]	
}

    rz_model { 'controller_model':
		ensure      => present,
		description => 'Controller Ubuntu Model',
		image       => 'ubuntu-12.04.1-server-amd64.iso',
		metadata    => {'domainname' => 'razor.lan', 'hostname_prefix' => 'controller', 'root_password' => 'password'},
		template    => 'ubuntu_precise',
}

    rz_model { 'compute_model':
		ensure      => present,
		description => 'Compute Ubuntu Model',
		image       => 'ubuntu-12.04.1-server-amd64.iso',
		metadata    => {'domainname' => 'razor.lan', 'hostname_prefix' => 'compute', 'root_password' => 'password'},
		template    => 'ubuntu_precise',
}	
	

    rz_tag { "mac_eth1_of_the_controller":
        tag_label   => "mac_eth1_of_the_controller",
        tag_matcher => [ {
                        'key'     => 'mk_hw_nic1_serial',
                        'compare' => 'equal',
                        'value'   => "00:0C:29:52:A1:D2,",
                    } ],
}

    # a tag to identify my <compute?.hostname>
    rz_tag { "not_mac_eth1_of_the_controller":
        tag_label   => "not_mac_eth1_of_the_controller",
        tag_matcher => [ {
                        'key'     => 'mk_hw_nic1_serial',
                        'compare' => 'equal',
                        'value'   => "08:00:27:64:9b:22",
                        'inverse' => "yes",
                    } ],
}
    

	rz_policy { 'controller_policy':
	  ensure  => present,
	  broker  => 'none',
	  model   => 'controller_model',
	  enabled => 'true',
	  tags    => ['mac_eth1_of_the_controller'],
	  template => 'linux_deploy',
	  maximum => 1,
	}

	rz_policy { 'compute_policy':
	  ensure  => present,
	  broker  => 'none',
	  model   => 'compute_model',
	  enabled => 'true',
	  tags    => ['not_mac_eth1_of_the_controller'],
	  template => 'linux_deploy',
	  maximum => 3,
	}	
}
