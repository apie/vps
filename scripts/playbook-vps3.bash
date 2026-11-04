#!/bin/bash -v
ansible-playbook --inventory inventory/vps3 playbooks/vps3.yml --vault-password-file vault.passwd --diff
