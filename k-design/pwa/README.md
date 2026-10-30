<!-- K Design v0.7.0 — copié par scripts/build.mjs depuis pwa/. Ne pas éditer. -->
# Socle PWA des apps K

Livré par k-design (D24) pour K·Budget, K-Review et KPanel, par copie comme les tokens. Sans dépendance.

| Fichier | Rôle |
|---|---|
| `k-pwa-sw.conf` | Fragment nginx : cache du service worker Angular (cinq `location =`) |
| `k-pwa-check.mjs` | Contrôle de la version d'Angular, de la coquille, du manifeste, du `ngsw-config.json` et du nginx |
| `ecosystem.json` | Version mineure d'Angular de l'écosystème, lue par `k-pwa-check.mjs` |
| `app-update.ts` | `AppUpdateService` : mise à jour du service worker sans interface (voir « Service de mise à jour ») |
| `app-update.spec.ts` | Sa spec Vitest, exécutée par la CI de l'app |
| `README.md` | Ce fichier |

Pas de copie de `safety-worker.js` (Angular le publie à chaque build), d'`index.html` ni de `ngsw-config.json` (contenu propre à chaque app) : la coquille est vérifiée, pas livrée.

## Recevoir le socle

Dans le `k-design.json` de l'app, une entrée de `files` pour le dossier et la section `pwa` :

```json
{
  "app": "kreview",
  "version": "0.7.0",
  "files": {
    "pwa/": "deploy/k-pwa/"
  },
  "pwa": {
    "packageJson": "app/package.json",
    "index": "app/src/index.html",
    "manifest": "app/public/manifest.webmanifest",
    "ngswConfig": "app/ngsw-config.json",
    "nginx": ["app/nginx.conf"]
  }
}
```

Tous les chemins de `pwa` sont relatifs à la racine de l'app. `nginx` liste **chaque** fichier nginx qui sert les fichiers de la PWA : le `nginx.conf` de l'image de l'app (`app/nginx.conf` pour K·Budget et K-Review, `frontend/nginx.conf` pour KPanel). Un nginx de bordure qui ne fait que relayer vers l'app (le `deploy/nginx.conf` de K·Budget) n'en fait pas partie et n'inclut pas le fragment : ses `location =` n'ont pas de `proxy_pass`, ils y répondraient en 404. Le script de synchronisation conserve la section `pwa` telle quelle.

## Branchement en CI

Depuis la racine de l'app, après Node 22 :

```
node deploy/k-pwa/k-pwa-check.mjs
```

Le script lit `ecosystem.json` placé à côté de lui. Il liste tous les écarts, chacun avec son fichier et sa règle, et sort en code 1 s'il y en a. Il sort aussi en code 1, avec un message explicite, si la section `pwa` est absente, si un fichier listé est introuvable, si `nginx` est vide ou si `package.json` n'a aucun paquet Angular.

| Fichier | Règle |
|---|---|
| `packageJson` | chaque `@angular/*` et `@angular-devkit/*` (dependencies et devDependencies) en `~<mineure>.x`, mineure de `ecosystem.json` (`@angular/cdk` compris) |
| `index` | `meta viewport` avec `viewport-fit=cover`, `meta theme-color`, `link rel="manifest"`, `link rel="apple-touch-icon"` (balises en `>` ou `/>`) |
| `manifest` | `id`, `start_url`, `scope`, `display` = `standalone`, une icône 192x192, une 512x512, une icône `maskable` |
| `ngswConfig` | tout groupe d'assets dont les fichiers contiennent `/*.js` contient aussi `!/safety-worker.js` |
| `nginx` | une directive `include` vers `k-pwa-sw.conf`, et aucun des cinq `location =` du fragment redéclaré |

Limites : la valeur de `theme-color` reste à l'app (présence seulement) ; `start_url`, `scope` et `id` ne sont contrôlés que par leur présence, les valeurs relatives de K·Budget (`./`) sont acceptées.

## Service de mise à jour

`app-update.ts` est le service de mise à jour du service worker de K·Budget (KKS-446), rendu générique (D24, KKS-615). Il n'ajoute aucune interface : ni bandeau, ni bouton.

Contrat :

- recherche d'une version au lancement et à chaque retour au premier plan (`visibilitychange` vers `visible`) ;
- une version trouvée dans les `UPDATE_APPLY_WINDOW_MS` (3000 ms) qui suivent le début de la recherche est activée **puis** la page rechargée ; trouvée plus tard, elle est retenue pour le retour au premier plan suivant ;
- `VERSION_READY` reçu pendant l'usage est compté, jamais appliqué sur-le-champ : il s'applique au retour au premier plan suivant ; un compteur plutôt qu'un booléen, pour qu'un événement reçu après une application échouée reste détectable ;
- une activation qui échoue ou ne trouve rien n'entraîne aucun rechargement ;
- `unrecoverable` recharge toujours, immédiatement, sous une surface modale comme sur un parcours que l'app protège ;
- `refreshAndReload()` (bouton « Réessayer » d'un écran d'incompatibilité) cherche et active une version plus récente, puis recharge dans tous les cas ;
- `SwUpdate` n'est approché que si `isEnabled` : rien ne se passe en développement ni dans les tests.

### Branchement

Dans le `k-design.json` de l'app, une entrée par fichier, sous `src/` pour que le compilateur et le test les voient (emplacement conseillé : `core/pwa/`) :

```json
"files": {
  "pwa/app-update.ts": "app/src/app/core/pwa/app-update.ts",
  "pwa/app-update.spec.ts": "app/src/app/core/pwa/app-update.spec.ts"
}
```

KPanel : `frontend/src/app/core/pwa/`. Puis dans `app.config.ts` :

```ts
provideAppInitializer(() => inject(AppUpdateService).start()),
```

### Surfaces modales

Une version n'est jamais appliquée sous une surface modale ouverte : le rechargement y perdrait la saisie. Le service cherche `MODAL_SURFACE_SELECTOR` (`[role="dialog"], [role="alertdialog"], [data-modal-surface]`), toujours, sans réglage. Convention de l'écosystème : tout dialogue, feuille ou panneau qui contient une saisie porte `role="dialog"`, `role="alertdialog"` ou `data-modal-surface`, et n'est dans le DOM qu'ouvert.

### Critère propre à l'app

Le jeton facultatif `APP_UPDATE_CAN_APPLY` (`InjectionToken<() => boolean>`) ajoute un critère de l'app, évalué à chaque application. Absent, seul le contrôle des surfaces modales s'applique ; présent, une version ne s'applique que si le contrôle des surfaces modales **et** la fonction l'autorisent. Sinon elle reste retenue. Exemple de K·Budget, qui protège ses parcours de tâche (`/settings`, `/transactions/import`) :

```ts
{
  provide: APP_UPDATE_CAN_APPLY,
  useFactory: () => {
    const router = inject(Router);
    return () => !isTaskFlowRoute(router.url);
  },
},
```

### Tests

La spec livrée tourne dans la CI de l'app, pas dans celle de k-design, qui reste sans dépendance (D24). Elle ne dépend que d'Angular 22.2, de RxJS 7 et des globaux Vitest (`vi`, `describe`, `expect`, types `vitest/globals`, environnement jsdom). Les deux fichiers copiés restent exclus de l'analyse statique de l'app (`sonar.exclusions`, D14) ; ils ne s'éditent pas dans l'app.

## Fragment nginx

Dans le bloc `server` de chaque fichier nginx listé :

```nginx
include /etc/nginx/k-pwa-sw.conf;
```

Le Dockerfile de l'app copie `k-pwa-sw.conf` à ce chemin. Les règles propres à l'app restent dans son nginx : `= /custom-sw.js` (Web Push de K-Review), cache long des fichiers à empreinte, `/api/`, repli vers `index.html`. Elles ne doivent pas redéclarer les cinq `location =` du fragment (nginx refuse deux `location =` identiques).

**Piège d'`add_header`** : tout ou rien par niveau. Dès qu'un `location` pose un `add_header`, il n'hérite d'aucun de ceux du niveau `server`. À l'adoption, une app qui en pose au niveau `server` perd ces en-têtes sur les cinq chemins du fragment. Au 30 octobre 2026, aucun des trois `nginx.conf` d'app n'en pose au niveau `server`. Les en-têtes de sécurité du `deploy/nginx.conf` de K·Budget sont posés par la bordure sur les réponses qu'elle relaie : ils ne sont pas concernés.

## Coquille de référence

Dans le `<head>` d'`index.html` :

| Balise | Statut |
|---|---|
| `<meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover">` | requise : sans `viewport-fit=cover`, les `--k-safe-*` (D21) valent 0 |
| `<meta name="theme-color" content="…">` | requise, valeur libre (propre à l'app, réécrite à l'exécution par K·Budget et KPanel) |
| `<link rel="manifest" href="manifest.webmanifest">` | requise |
| `<link rel="apple-touch-icon" href="…">` | requise |
| `<meta name="apple-mobile-web-app-status-bar-style" content="black-translucent">` | facultative, non contrôlée |

Limite connue de `apple-mobile-web-app-status-bar-style` : la valeur est unique pour toute l'app, elle ne suit pas le thème. Avec `black-translucent` la barre d'état de l'iPhone reste transparente sur le contenu, et en thème clair son texte blanc se lit mal sur un fond clair.

## Cloudflare

Le fragment nginx ne suffit pas derrière Cloudflare : sa mise en cache réécrit le `Cache-Control` des `.js` avec le « Browser Cache TTL » de zone (4 heures par défaut), et le `no-cache` posé par nginx n'atteint pas le navigateur. Une Cache Rule manuelle, hors du code, est nécessaire.

Reprise de KPanel `deploy/README.md` §4.1 « Cloudflare et service worker (KKS-493) » et de K-Review `deploy/README.md` §6.3 :

1. Dashboard Cloudflare, zone de l'app → Caching → **Cache Rules** → *Create rule*.
2. Condition : **Hostname** égal à l'hôte de l'app **et** **URI Path** égal à `/ngsw-worker.js` (K-Review : aussi `/custom-sw.js`, le script enregistré, qui importe `/ngsw-worker.js`).
3. Cache eligibility : **Bypass cache** ; Browser TTL : **Respect origin**.

Ne pas désactiver la protection anti-bots : `no-transform` sur `index.html` suffit contre l'injection du script de détection.

Contrôles, **à travers Cloudflare** (depuis le LAN le défaut est invisible), avec le nom d'hôte de l'app :

```bash
curl -fsS https://<hôte>/index.html | grep -c challenge-platform   # attendu : 0 (KPanel §4.1)
curl -sI https://<hôte>/ngsw-worker.js | grep -iE 'cache-control|cf-cache-status'   # attendu : no-cache, DYNAMIC (KPanel §4.1, K-Review §6.3)
```

Symptôme d'une règle absente : `/ngsw/state` affiche `Driver state: EXISTING_CLIENTS_ONLY (Degraded due to failed initialization: Hash mismatch …)` (KPanel §4.1).

## Retirer un service worker fautif

Le service worker vit chez le visiteur et survit au conteneur : revenir à l'image précédente ne l'atteint pas. Angular publie `safety-worker.js` à chaque build : il désinscrit le worker installé et vide ses caches. Sa règle nginx (`no-cache`) est dans le fragment, son exclusion du `ngsw-config.json` est contrôlée.

Reprise de K·Budget `docs/deployment.md` (« Removing a faulty web app from installed browsers ») et de K-Review `deploy/README.md` §11.1 :

1. **Arrêter tout outil de mise à jour automatique** (Watchtower) : recréer le conteneur annulerait l'étape 2.
2. **Servir le worker de secours à la place du vrai**, depuis le conteneur en cours d'exécution :

   ```bash
   docker compose exec app sh -c \
     'cp /usr/share/nginx/html/safety-worker.js /usr/share/nginx/html/ngsw-worker.js'
   ```

   K-Review : remplacer aussi `custom-sw.js`, le script enregistré (`… && cp /usr/share/nginx/html/safety-worker.js /usr/share/nginx/html/custom-sw.js`).
3. **Attendre que les appareils le récupèrent** : le navigateur relit `/ngsw-worker.js` à chaque lancement (servi `no-cache`), puis le worker de secours se désinscrit. Un appareil qui n'a pas rouvert l'app n'est corrigé qu'à son prochain lancement. Si un CDN ou un proxy est devant, il doit transmettre `Cache-Control: no-cache` pour ce fichier (d'où la Cache Rule ci-dessus).
4. **Déployer une image saine** (version corrigée ou précédente, puis `docker compose pull && docker compose up -d`) : le conteneur recréé rend le vrai `ngsw-worker.js`.

L'étape 2 ne survit pas à un redémarrage ou à une recréation du conteneur : c'est un palliatif, pas une livraison. Pour un seul appareil : désinscrire le worker dans les outils du navigateur (Application, Service Workers) ou effacer les données du site. Le retrait durable (K-Review §11.1, temps 2) retire l'enregistrement du service worker du démarrage de l'app et `"serviceWorker"` de la configuration de production d'`angular.json`, sans quoi le build continue d'émettre le vrai `ngsw-worker.js`.
