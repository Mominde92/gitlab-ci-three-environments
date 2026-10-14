# GitLab CI/CD: Dev, Stage and Live

[![CI](https://github.com/Mominde92/gitlab-ci-three-environments/actions/workflows/ci.yml/badge.svg)](https://github.com/Mominde92/gitlab-ci-three-environments/actions/workflows/ci.yml)
![GitLab CI](https://img.shields.io/badge/GitLab-CI%2FCD-FC6D26?logo=gitlab&logoColor=white)
![License](https://img.shields.io/badge/license-MIT-blue)

A small, copy-paste GitLab pipeline that gives a project **three isolated environments** and keeps untested code out of production.
It is the structure I use on production systems, simplified so it fits PHP, Laravel, Node.js or static sites.

```
 push to develop ──► validate ──► deploy_dev    (automatic)
 push to stage   ──► validate ──► deploy_stage  (automatic)
 merge to main   ──► validate ──► deploy_live   (manual button)
```

## What the pipeline does

1. **Validate** on every push and merge request. Out of the box it fails on any PHP syntax error; add your tests and linters here.
2. **Deploy** with `rsync --delete` over SSH, so the server matches the repository. `.env`, `storage/`, `.git/` and `node_modules/` are never touched.
3. **Run post-deploy commands** (optional), for example migrations and cache warm-up.
4. **Health check** the environment's URL. A broken release turns the pipeline red instead of failing silently.
5. **Live is manual**: production changes only when someone presses the button, and `resource_group` stops two deploys from running at once.

One deploy job is defined once (`.deploy`) and reused three times; each environment gets its own server details through **environment-scoped variables**, so the YAML is identical for Dev, Stage and Live.

## Setup

### 1. Prepare each server

```bash
sudo DEPLOY_USER=deploy ./scripts/setup-deploy-user.sh /var/www/app
```

It creates a `deploy` user, the app folder and an SSH key pair, and prints the values for the next step.

### 2. Add CI/CD variables in GitLab

*Settings → CI/CD → Variables.* Add each variable once per environment, using **Environment scope** `dev`, `stage` and `live`:

| Variable | Example | Notes |
|---|---|---|
| `DEPLOY_HOST` | `10.0.0.12` | Server IP or DNS name |
| `DEPLOY_USER` | `deploy` | |
| `APP_DIR` | `/var/www/app` | |
| `HEALTH_URL` | `https://stage.example.com/` | Must answer 2xx after a deploy |
| `SSH_PRIVATE_KEY` | *(private key)* | Protected |
| `SSH_KNOWN_HOSTS` | output of `ssh-keyscan <host>` | Prevents man-in-the-middle |
| `POST_DEPLOY_CMD` | `php artisan migrate --force && php artisan optimize` | Optional |

Mark secrets as **Protected** and **Masked**.

### 3. Protect the branches

*Settings → Repository → Protected branches*:

- `main` and `stage`: **no one** can push directly; changes arrive through merge requests.
- Require at least one approval on merge requests.
- Only Maintainers can run the manual `deploy_live` job.

### 4. Copy `.gitlab-ci.yml` into your project

Create the `develop` and `stage` branches, push, and watch the first pipeline in *Build → Pipelines*.

## Adapting it

- **Laravel**: `POST_DEPLOY_CMD="composer install --no-dev --optimize-autoloader && php artisan migrate --force && php artisan optimize"`
- **Node.js**: build in a job before deploy, then `POST_DEPLOY_CMD="npm ci --omit=dev && pm2 reload app"`
- **Static sites**: build in a job, rsync the build folder instead of `./`
- **Docker**: replace the rsync step with building and pushing an image, then `docker compose pull && docker compose up -d` over SSH

The full story behind this setup: [Dev, Stage and Live: a simple GitLab CI/CD pipeline](https://moumen-dev.com/blog/gitlab-ci-dev-stage-live/).

## Author

**Moamen Derine**, Senior Full Stack Developer & DevOps Engineer in Dubai.
[moumen-dev.com](https://moumen-dev.com) · [LinkedIn](https://www.linkedin.com/in/momin-derine/)

## License

[MIT](LICENSE)
