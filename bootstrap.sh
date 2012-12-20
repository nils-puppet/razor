!#/bin/bash

cd /usr/src; wget http://apt.puppetlabs.com/puppetlabs-release-precise.deb &&  dpkg -i puppetlabs-release-precise.deb

apt-get update
apt-get upgrade -y
apt-get dist-upgrade -y
apt-get install git puppet -y
