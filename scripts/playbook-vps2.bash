#!/bin/bash -v
ansible-playbook --inventory inventory/vps2 playbooks/vps2.yml --vault-password-file vault.passwd --diff
