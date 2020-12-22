#! /bin/sh
export ANSIBLE_INVENTORY=/etc/ansible/hosts;export ANSIBLE_HOST_KEY_CHECKING=False;ansible-playbook deployment/playbooks/prep-db-node.yml --ask-pass -K
