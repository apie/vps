# ansible

Deploys the services on my VPSes. Run everything from this directory so `ansible.cfg` is used.

## Layout

| Path | What |
|---|---|
| `inventory/` | hosts (`vps`, `vps2`), plus `host_vars/` and `group_vars/` (must live here to be found) |
| `playbooks/provision/` | server setup: `provision-vps`, `provision-letsencrypt`, `user-setup`, `irc-setup`, with their own `files/`, `templates/`, `handlers/` |
| `playbooks/maintenance/` | `reboot_if_needed` |
| `playbooks/apps/` | one small playbook per app, nginx location templates in `templates/` |
| `playbooks/site.yml` | provision + all apps |
| `roles/app_user` | user, git checkout, `MAILTO` cron, config files from the vault |
| `roles/app_service` | on top of `app_user`: venv, systemd unit, nginx locations, restart |
| `roles/geerlingguy.*` | galaxy roles, not in git: `ansible-galaxy install -r requirements.yml` |
| `vault/` | ansible-vault encrypted secrets, one file per app |
| `scripts/` | helpers, e.g. `test_services_vps2.bash` |

## Deploying

```
ansible-playbook -i inventory/vps2 --vault-password-file vault.passwd playbooks/apps/<app>.yml
```

Add `--check --diff` first when changing a playbook. `lastfm-event-countdown` also needs
`-e local_checkout_directory=<path to the local checkout of lastfm-countdown-clock>`.

## Adding an app

- Runs as a service: copy `playbooks/apps/cachingproxy.yml` and use the `app_service` role.
  Pick the unit with `service_template` (`customservice`, `pythonservice`, `pythonvenvservice`),
  see `roles/app_service/defaults/main.yml` for the options.
- Cron job only: use the `app_user` role and add the pip installs and cron tasks in the playbook,
  see `playbooks/apps/seriesbot.yml`.
- Secrets: `ansible-vault create vault/<username>.yml` with a list of `{filename, content}`
  and pass it with `app_vault_file` / `app_config_files`.
