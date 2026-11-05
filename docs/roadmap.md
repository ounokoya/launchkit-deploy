# Roadmap · deploy (Kubernetes)

Dépôt `launchkit-deploy` (GitHub ounokoya) : la mise en ligne de LaunchKit sur Kubernetes (k3s), démo publique sur
https://saas.koyad.com.

Légende : ✅ fait · 💡 proposé, à valider · 🚧 en cours

| Version | Thème | Statut |
|---|---|---|
| v0.1.0 | Démo en ligne sur k3s | ✅ (2026-11-05) |
| v0.2.0 | Images et déploiement par la CI | 💡 |
| v0.3.0 | Sauvegardes et supervision | 💡 |
| v1.0.0 | Installation chez un client | 💡 |

## v0.1.0 · Démo en ligne sur k3s ✅

- Espace `launchkit` à part sur un nœud k3s partagé, quota mémoire (2,25 Gio), un plafond par service.
- HTTPS par Let's Encrypt (Traefik), HTTP → HTTPS, HSTS ; routes `/` (web), `/api` (API), `/mail` (boîte de démo).
- Aucun e-mail ne sort du serveur ; démo remise à zéro chaque lundi ; secrets tirés sur le serveur.
- Images construites et chargées par `scripts/images.sh`, déploiement par `scripts/deploy.sh`.
- Vérifié en ligne : scénario A / B du web aux 3 tailles, OWASP ZAP (0 échec, 0 avertissement).

## v0.2.0 · Images et déploiement par la CI 💡

- GitHub Actions : construction des images, envoi sur GHCR, déploiement sur le serveur.
- Sécurité : Trivy sur les images et les manifestes ; actions GitHub épinglées par empreinte.
- Test de fumée après chaque déploiement (scénario A / B).

## v0.3.0 · Sauvegardes et supervision 💡

- Sauvegarde quotidienne d'ArangoDB, rapatriée hors du serveur.
- Alertes : site indisponible, mémoire proche du plafond, certificat proche de l'échéance.

## v1.0.0 · Installation chez un client 💡

- Le même kit, déployé pour un client : domaine, e-mails réels (SMTP), vrais paiements (Stripe).
