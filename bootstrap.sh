!#/bin/bash

cd /usr/src; wget http://apt.puppetlabs.com/puppetlabs-release-precise.deb &&  dpkg -i puppetlabs-release-precise.deb

apt-get update
apt-get upgrade -y
apt-get dist-upgrade -y
apt-get install git puppet -y

puppet module install puppetlabs/razor
puppet module install saz-dnsmasq

mkdir /etc/puppet/manifests/nodes


cat /etc/puppet/manifests/site.pp << EOF
import "nodes/*"

EOF

cd /etc/puppet/manifests/nodes/; wget https://raw.github.com/nils-puppet/razor/master/nodes/razor.pp
puppet apply /etc/puppet/manifests/site.pp
