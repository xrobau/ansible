# Ansible makefile for doing stuff with things.
#

SHELL=/bin/bash

halp: setup
	@echo Read the makefile. But you probably want:
	@echo -e \ \ \ make development
	@echo -e \\t -- Puts everything in place for this machine to dev stuff
	@echo -e \ \ \ make update
	@echo -e \\t -- Updates this machine, purges old pkgs hanging around
	@echo -e \ \ \ make me
	@echo -e \\t -- Runs fast.yml against the IPs of this host

ANSBIN=/usr/bin/ansible-playbook
ANSIBLE_HOST_KEY_CHECKING=False
export ANSIBLE_HOST_KEY_CHECKING

.PHONY: setup docker
setup: $(ANSBIN) ansible-collections

development:
	ansible-playbook -i localhost, development.yml

update:
	apt-get update
	apt-get -y --purge autoremove
	apt-get -y dist-upgrade
	apt-get remove --purge $$(dpkg -l | awk '/^r/ {print $$2}')

.PHONY: me
me: setup
	@MYIPS=$$(ip -o addr | egrep -v '(\ lo|\ docker)' | awk '/inet / { print $$4 }' | cut -d/ -f1 | paste -sd ','); \
		echo ansible-playbook fast.yml -l $$MYIPS; \
		ansible-playbook fast.yml -l $$MYIPS

$(ANSBIN): | base-packages
	apt-get -y install ansible

ansible-collections: ~/.ansible/collections/ansible_collections/community/general ~/.ansible/collections/ansible_collections/vyos/vyos ~/.ansible/collections/ansible_collections/vyos/vyos/MANIFEST.json ~/.ansible/collections/ansible_collections/ansible/posix/MANIFEST.json ~/.ansible/collections/ansible_collections/community/docker/MANIFEST.json ~/.ansible/collections/ansible_collections/community/mysql/MANIFEST.json ~/.ansible/roles/jhu-sheridan-libraries.postfix-smarthost/README.md

~/.ansible/collections/ansible_collections/ansible/posix/MANIFEST.json:
	ansible-galaxy collection install ansible.posix

~/.ansible/collections/ansible_collections/vyos/vyos/MANIFEST.json:
	ansible-galaxy collection install vyos.vyos

~/.ansible/collections/ansible_collections/community/docker/MANIFEST.json:
	ansible-galaxy collection install community.docker

~/.ansible/collections/ansible_collections/community/mysql/MANIFEST.json:
	ansible-galaxy collection install community.mysql

~/.ansible/roles/jhu-sheridan-libraries.postfix-smarthost/README.md:
	ansible-galaxy install jhu-sheridan-libraries.postfix-smarthost

~/.ansible/collections/ansible_collections/community/general:
	@ansible-galaxy collection install community.general

~/.ansible/collections/ansible_collections/vyos/vyos:
	@ansible-galaxy collection install vyos.vyos

.PHONY: base-packages
base-packages: /usr/bin/wget /usr/bin/unzip /usr/bin/vim /usr/bin/ping

/usr/bin/wget:
	@apt-get -y install wget

/usr/bin/unzip:
	@apt-get -y install unzip

/usr/bin/vim:
	@apt-get -y install vim

/usr/bin/ping:
	@apt-get -y install iputils-ping

