#!/bin/bash

## Timezone
echo "Europe/Berlin" > /etc/timezone
dpkg-reconfigure -fnoninteractive tzdata

## Network
cat >>/etc/network/interfaces<<EOF

auto eth1 
iface eth1 inet static 
        address 10.10.20.1 
	netmask 255.255.255.0 
	up /sbin/iptables -t nat -A POSTROUTING -s '10.10.20/24' -j MASQUERADE
EOF
ifup eth1
sysctl -w net.ipv4.ip_forward=1
sysctl -p

## Requirements
cd /usr/src; wget http://apt.puppetlabs.com/puppetlabs-release-precise.deb && dpkg -i puppetlabs-release-precise.deb
apt-get update
apt-get upgrade -y
apt-get dist-upgrade -y
apt-get install git puppet -y
apt-key adv --keyserver 'keyserver.ubuntu.com' --recv-keys '7F0CEB10'

## Puppet
puppet module install puppetlabs/razor
puppet module install saz-dnsmasq
mkdir /etc/puppet/manifests/nodes
cat > /etc/puppet/manifests/site.pp << EOF
import "nodes/*"

EOF

## Razor
cat >>/etc/puppet/manifests/nodes/razor.pp<<EOF
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

	class { 'razor':
		address => $ipaddress_eth1,
		username => 'razor',
		directory => '/opt/razor'
}
  
	rz_image { "ubuntu-12.04.1-server-amd64":
		ensure  => present,
		type    => 'os', 
		version => '12.04.1',
		source  => 'http://releases.ubuntu.com/precise/ubuntu-12.04.1-server-amd64.iso',
}

    rz_model { 'controller_model':
		ensure      => present,
		description => 'Controller Ubuntu Model',
		image       => 'ubuntu-12.04.1-server-amd64',
		metadata    => {'domainname' => 'mivitec.net', 'hostname_prefix' => 'controller', 'root_password' => 'password'},
		template    => 'ubuntu_precise',
}

    rz_model { 'compute_model':
		ensure      => present,
		description => 'Compute Ubuntu Model',
		image       => 'ubuntu-12.04.1-server-amd64',
		metadata    => {'domainname' => 'mivitec.net', 'hostname_prefix' => 'compute', 'root_password' => 'password'},
		template    => 'ubuntu_precise',
}	

    rz_tag { "controller_node1_eth0":
        tag_label   => "controller_node1_eth0",
        tag_matcher => [ {
                        'key'     => 'macaddress_eth0',
                        'compare' => 'equal',
                        'value'   => "00:0C:29:3F:D5:83",
                    } ],
}

    rz_tag {"compute_node1_eth0":
        tag_label   => "compute_node1_eth0",
        tag_matcher => [ {
                        'key'     => 'macaddress_eth0',
                        'compare' => 'equal',
                        'value'   => "00:0C:29:C1:D9:A7",
                        'inverse' => "yes",
                    } ],
}


    rz_tag {"compute_node2_eth0":
        tag_label   => "compute_node2_eth0",
        tag_matcher => [ {
                        'key'     => 'macaddress_eth0',
                        'compare' => 'equal',
                        'value'   => "00:0C:29:B4:87:34",
                        'inverse' => "yes",
                    } ],
}
    

	rz_policy { 'controller_policy':
	  ensure  => present,
	  broker  => 'none',
	  model   => 'controller_model',
	  enabled => 'true',
	  tags    => ['controller_node1_eth0'],
	  template => 'linux_deploy',
	  maximum => 1,
}

	rz_policy { 'compute_policy_node':
	  ensure  => present,
	  broker  => 'none',
	  model   => 'compute_model',
	  enabled => 'true',
	  tags    => ['compute_node1_eth0','compute_node2_eth0'],
	  template => 'linux_deploy',
	  maximum => 3,
	}	

}
EOF
