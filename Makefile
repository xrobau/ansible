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
	@echo ZFS Things:
	@echo -e "   make zfs"
	@echo -e "\t -- Installs the base packages for ZFS, and enables kexec"
	@echo -e "   make zfsconf"
	@echo -e "\t -- Runs the ansible playbook to set MOTD correctly, etc"
	@echo -e "   make zfsstatus"
	@echo -e "\t -- Shows you current zfs kernel module settings"

ANSBIN=/usr/bin/ansible-playbook
ANSIBLE_HOST_KEY_CHECKING=False
export ANSIBLE_HOST_KEY_CHECKING

.PHONY: setup docker
setup: $(ANSBIN) ansible-collections base-packages

development: setup
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

ansible-collections: ~/.ansible/collections/ansible_collections/community/general ~/.ansible/collections/ansible_collections/vyos/vyos ~/.ansible/collections/ansible_collections/vyos/vyos/MANIFEST.json ~/.ansible/collections/ansible_collections/ansible/posix/MANIFEST.json ~/.ansible/collections/ansible_collections/community/docker/MANIFEST.json ~/.ansible/collections/ansible_collections/community/mysql/MANIFEST.json ~/.ansible/roles/jhu-sheridan-libraries.postfix-smarthost/README.md ~/.ansible/roles/caddy_ansible.caddy_ansible/README.md ~/.ansible/roles/geerlingguy.php/README.md ~/.ansible/roles/geerlingguy.php-versions

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

~/.ansible/roles/caddy_ansible.caddy_ansible/README.md:
	ansible-galaxy install caddy_ansible.caddy_ansible

~/.ansible/roles/geerlingguy.php/README.md:
	ansible-galaxy install geerlingguy.php

~/.ansible/roles/geerlingguy.php-versions:
	ansible-galaxy install geerlingguy.php-versions

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

.PHONY: zfs
zfs: setup /etc/modprobe.d/zfs.arcmax.conf /etc/modprobe.d/zfs.defaults.conf kexec

.PHONY: zfsstatus
zfsstatus:
	@D="zfs_dirty_data_max l2arc_noprefetch l2arc_trim_ahead l2arc_write_max zfs_vdev_write_gap_limit zfs_txg_timeout zfs_vdev_cache_size"; \
		cd /sys/module/zfs/parameters; \
		for x in $$D; do \
			grep -H . $$x; \
		done

.PHONY: zfsconf
zfsconf /etc/hosts: /etc/ansible.hostname
	$(ANSBIN) zfsserver.yml -e hostname=$(shell cat /etc/ansible.hostname)

.PHONY: hostname
hostname /etc/ansible.hostname:
	@C=$(shell hostname); echo "Current hostname '$$C'"; read -p "Set hostname (blank to not change): " h; \
		if [ "$$h" ]; then \
			echo $$h > /etc/ansible.hostname; \
		else \
			if [ ! -s /etc/ansible.hostname ]; then \
				hostname > /etc/ansible.hostname; \
			fi; \
		fi

/etc/modprobe.d/zfs.arcmax.conf:
	@echo "If this machine is only going to be used as a fileserver then"
	@echo "all the memory on this machine will be assigned to ZFS apart from"
	@echo "16GB set aside for OS housekeeping (eg, replication, small docker"
	@echo "containers, those sorts of things). If it is going to be used for"
	@echo "other things, ZFS defaults to capping itself at half available"
	@echo "memory, wasting the other half on a file server."
	@read -p "Is this machine only going to be ONLY used as a file server [Yn]? " fsc; \
		R=$$(echo $$fsc | tr '[:upper:]' '[:lower:]' | cut -c1); \
		if [ "$$R" -a "$$R" != "y" ]; then \
			touch $@; \
		else \
			echo "options zfs zfs_arc_max=$$(awk '/MemTotal:/ { print ( $$2 * 1024 )-( 16 * 1024 * 1024 * 1024) } ' /proc/meminfo)" > $@; \
		fi

/etc/modprobe.d/zfs.defaults.conf:
	@echo "options zfs l2arc_noprefetch=0 zfs_dirty_data_max=17179869184 zfs_vdev_cache_size=16777216" > $@
	@echo "options zfs l2arc_trim_ahead=100 zfs_txg_timeout=120 l2arc_write_max=524288000 zfs_vdev_write_gap_limit=0" >> $@

.PHONY: kexec
kexec: /usr/sbin/kexec /etc/systemd/system/systemd-reboot.service.d/override.conf /etc/systemd/system/kexec-load.service

/usr/sbin/kexec:
	apt-get -y install kexec-tools

/etc/systemd/system/systemd-reboot.service.d/override.conf: override.conf
	mkdir -p $(@D)
	cp $< $@
	systemctl daemon-reload

/etc/systemd/system/kexec-load.service:  kexec-load.service
	cp $< $@
	systemctl enable kexec-load
	systemctl start kexec-load
	systemctl daemon-reload
