# LaunchKit · deploy

**LaunchKit** is a SaaS starter kit built as a portfolio demo: sign-up with e-mail check, organizations, members
and roles, a simulated Pro plan, a sample « Projects » module and a super admin back office, on the web and on
Android / iOS. This repository puts the demo online; it is live at **https://saas.koyad.com**.

| Repository | What |
|---|---|
| [launchkit-server](https://github.com/ounokoya/launchkit-server) | API (ASP.NET Core 10, ArangoDB) and Rust worker (e-mails, simulated payments) |
| [launchkit-web](https://github.com/ounokoya/launchkit-web) | Site and web app (SvelteKit 2, Svelte 5) |
| [launchkit-mobile](https://github.com/ounokoya/launchkit-mobile) | Android and iOS app (Flutter) — demo APK in its releases |
| launchkit-deploy (this one) | Kubernetes manifests (k3s) and scripts |

## What runs

```
https://saas.koyad.com ──► Traefik (k3s, Let's Encrypt)
                             ├── /        web (SvelteKit) ──► api (inside the cluster)
                             ├── /api     api (ASP.NET Core) ──► ArangoDB
                             └── /mail    Mailpit (demo inbox)  ◄── worker (Rust, SMTP)
```

Everything lives in the `launchkit` namespace of a k3s node shared with other apps: nothing else is touched, only
Traefik is shared. A quota caps the memory of the namespace (2.25 GiB of limits); each service has its own limit
(ArangoDB 1 GiB, API 512 MiB, web 256 MiB, worker and Mailpit 128 MiB).

- **No e-mail leaves the server.** The worker sends every message to Mailpit, public at `/mail/`: visitors sign up
  with made-up `@demo.test` addresses and read their links there. Everyone sees every demo e-mail: no real data.
- **The demo is reset every Monday at 04:00 UTC** (CronJob `reset`): visitors' accounts, organizations, projects and
  e-mails are deleted; the super admin stays.
- **Secrets are drawn on the server** (`scripts/secrets.sh`) and never leave it.

## Deploy

From a machine with Docker and SSH access to the server, next to the `launchkit-server` and `launchkit-web` checkouts:

```bash
scripts/images.sh 0.1.0               # builds api, worker, web and loads them into the k3s of the server
scripts/deploy.sh 0.1.0 --dry-run     # checks the manifests on the server
scripts/deploy.sh 0.1.0               # namespace, secrets, services, ingress, weekly reset
```

`SERVER` (default `root@31.57.224.79`) chooses the server. The images are loaded directly (no registry yet).

Check: `ssh root@31.57.224.79 'k3s kubectl -n launchkit get pods'`. Remove everything:
`k3s kubectl delete namespace launchkit` (the data volume goes with it).

| Manifest | Content |
|---|---|
| `k8s/00-namespace.yaml` | namespace and memory quota |
| `k8s/10-arangodb.yaml` | ArangoDB 3.12, 5 GiB volume |
| `k8s/20-mailpit.yaml` | Mailpit, demo inbox at `/mail/` |
| `k8s/30-api.yaml`, `k8s/40-worker.yaml`, `k8s/50-web.yaml` | the three LaunchKit services |
| `k8s/60-ingress.yaml` | HTTPS (Let's Encrypt), HTTP → HTTPS, routes `/`, `/api`, `/mail` |
| `k8s/70-reset.yaml` | weekly reset of the demo |

Roadmap: [docs/roadmap.md](docs/roadmap.md).
