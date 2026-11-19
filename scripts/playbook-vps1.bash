#!/bin/bash -v
ansible-playbook --inventory inventory/vps playbooks/vps1.yml --vault-password-file vault.passwd --diff --become-password-file become-vps1.passwd
