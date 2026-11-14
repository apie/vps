#!/bin/bash -v
ansible-playbook --inventory inventory/vps3 playbooks/apps/d87.nl.yml --vault-password-file vault.passwd --diff --tags static
