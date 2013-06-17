#!/bin/bash
#
# Script to bootstrap puppet on a freshly provisioned box
# currently supports only ubuntu and redhat.
#

# Redhat or Ubuntu?
if [ -r /etc/redhat-release ]; then
  OPERATINGSYSTEM="redhat"
  if [ -n "`grep 'release 6' /etc/redhat-release`" ]; then
    RELEASE="6"
  elif [ -n "`grep 'release 5' /etc/redhat-release`" ]; then
    RELEASE="5"
  else
    echo "This script is not designed for this release, exitting."
    exit 1
  fi

elif uname -v | grep Ubuntu >/dev/null; then
  OPERATINGSYSTEM="ubuntu"
  CODENAME="`grep DISTRIB_CODENAME /etc/lsb-release | awk -F= '{ print $2 }'`"
else
  echo "This script is not designed for this platform, exitting."
  exit 1
fi

#
# UBUNTU LOGIC
#
if [ "$OPERATINGSYSTEM" == "ubuntu" ]; then
  # install puppetlabs repo
  wget -qO "/tmp/puppetlabs-release-${CODENAME}.deb" http://apt.puppetlabs.com/puppetlabs-release-${CODENAME}.deb
  dpkg -i /tmp/puppetlabs-release-${CODENAME}.deb

  # make sure the system is upto date
  apt-get -qq update
  apt-get -y dist-upgrade

  # install puppet and git
  apt-get -y install puppet git

fi

#
# REDHAT LOGIC
#
if [ "$OPERATINGSYSTEM" == "redhat" ]; then
  rpm -ivh http://yum.puppetlabs.com/el/${RELEASE}/products/x86_64/puppetlabs-release-${RELEASE}-7.noarch.rpm

  # make sure the system is upto date
  yum clean all
  yum -y update

  # install puppet and git
  yum -y install puppet git

fi

#
# COMMON LOGIC
#

#
# Install some puppet modules from the forge
#
cd /etc/puppet/modules
git clone https://github.com/puppetlabs/puppetlabs-apache.git apache
git clone https://github.com/puppetlabs/puppetlabs-stdlib.git stdlib
git clone https://github.com/puppetlabs/puppetlabs-concat.git concat
git clone https://github.com/puppetlabs/puppetlabs-firewall.git firewall



if [ ! -d /etc/puppet/manifests ]; then mkdir /etc/puppet/manifests; fi
wget -O /etc/puppet/manifests/bootstrap.pp https://raw.github.com/mikenowak/random/master/configs/bootstrap.pp

wget -O /etc/puppet/node.sh https://raw.github.com/mikenowak/random/master/scripts/node.sh
chmod +x /etc/puppet/node.sh

puppet apply --show_diff --verbose --node_terminus exec --external_nodes /etc/puppet/node.sh /etc/puppet/manifests/bootstrap.pp

# reboot for a good measure
echo 'now you should init 6'