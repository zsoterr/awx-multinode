#! /bin/sh
export ANSIBLE_INVENTORY=/etc/ansible/hosts;export ANSIBLE_HOST_KEY_CHECKING=False;ansible-playbook deployment/playbooks/prep-install-docker.yml --ask-pass -K
