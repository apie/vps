# Plan: reorganize the ansible folder

Written 2026-10-15. Nothing in here has been executed yet.

## Problems today

- 19 playbooks sit in the repo root, mixed with config. Three kinds are mixed together:
  server setup (`provision-*`, `user-setup`, `irc-setup`, `reboot_if_needed`),
  per-app deploys (`aoc_alert_bot`, `birthdaymailer`, `cachingproxy`, `albumscrobbles`,
  `lastfm-event-countdown`, `logandremovebot`, `mastermind`, `nosfeed`, `seriesbot`,
  `startpagina`, `telegram_members`), and nothing else.
- Every app playbook repeats the same steps (add user, git checkout, venv + pip,
  systemd unit, enable/start, nginx locations, restart). `cachingproxy.yml` is a typical copy.
- Playbooks refer to `templates/...`, `files/...` and `handlers/main.yml` with paths
  relative to the repo root. That is why `handlers/main.yml` is pulled in with `import_tasks`
  inside a `handlers:` block.
- `templates/` and `files/` mix shared items (`pythonservice.service.j2`) with app-specific
  ones (`cachingproxy.locations.j2`, `files/irssi/`, `files/index.html`).
- `vars/main.yml` holds global nginx/firewall/certbot settings, and `vault/*.yml` holds
  per-app secrets, so each app's config is spread over 3-4 places.
- Housekeeping: `todo.txt` (only commented-out tasks and ideas), `test_services_vps2.bash`
  at the root, an untracked `vault.passwd` next to the code.

## Target layout

```
ansible.cfg
requirements.yml
inventory/            (unchanged; later maybe group_vars/ next to it)
group_vars/all/       vars.yml (was vars/main.yml)
host_vars/            (unchanged)
playbooks/
  provision/          provision-vps, provision-letsencrypt, user-setup, irc-setup
  maintenance/        reboot_if_needed
  apps/               one small playbook per app
  site.yml            imports provision/* then apps/* (optional)
roles/
  geerlingguy.*       (galaxy, git-ignored, as now)
  app_service/        local role: the shared deploy steps (see below)
files/                shared files only; app-specific ones go to roles/app files or apps/<name>/
templates/            moves into roles/app_service/templates (+ nginx location templates per app)
vault/                unchanged for now (per-app secrets)
scripts/              test_services_vps2.bash
docs/ or README.md    short description of how to deploy one app
```

## The key change: a local `app_service` role

Parameters per app: `username`, `repo_name`, `python_version`, `service_type`
(custom / python / pythonvenv / gunicorn), `service_script_filename`,
`service_working_dir`, `nginx_location_template` (optional), `secrets_file` (optional).
Tasks: user, git checkout, venv, systemd template, enable/start, nginx locations,
restart (the handlers `reload systemctl` / `reload nginx` move into the role).

Each app playbook then shrinks to roughly 15 lines: hosts, vars, `roles: [app_service]`,
plus its few special extra tasks (e.g. telegram DB copy, cron jobs for birthdaymailer).

## Steps (each is one commit, deploy-safe)

1. Commit or stash the current untracked work first (new playbooks, vault files,
   `gunicornservice.service.j2`, `https-vhost.j2`) so the reorg starts from a clean tree.
2. Pure moves with `git mv`: playbooks into `playbooks/*`, scripts into `scripts/`,
   `vars/main.yml` into `group_vars/all/`. Fix `import_tasks`/`src:` paths. Update
   `ansible.cfg` (`roles_path = ./roles`, and add `inventory = inventory`, `vault_password_file = vault.passwd`
   if wanted). Check with `ansible-playbook --syntax-check` on every playbook.
3. Create `roles/app_service` (note `.gitignore` currently ignores all of `roles/`; change
   it to ignore only `roles/geerlingguy.*` so the local role is tracked).
4. Convert `cachingproxy` first as the pilot. Verify with `--check --diff` against vps2
   (it must report no changes), then convert the other apps one at a time.
5. Move app-specific templates/files next to their apps, delete the leftovers, drop `todo.txt`
   or turn it into a README section.
6. Add `playbooks/site.yml` and a short README with the deploy commands.

## Decisions to make before starting

- Do the app deploys really differ enough (gunicorn vs venv vs plain python) to need
  `service_type`, or should it be only a choice of template?
- Where should `vault.passwd` live (it is git-ignored, but sits in the repo root)?
- Keep `vars/` and `vault/` names to avoid breaking the deploy flow of the app repos
  (the note in `startpagina.yml` says a push to some repos triggers a deploy), or
  rename them as above? Check whether any external repo/CI refers to paths here.

## Risk

All moves are path-only until step 4. Use `--check --diff` on each converted playbook
before a real run, since these deploy to production (vps, vps2).
