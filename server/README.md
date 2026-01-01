# Backend — server

Résumé
- API REST Node.js + Express
- ORM: Prisma avec PostgreSQL (schéma dans `prisma/schema.prisma`)
- Auth: JWT (`jsonwebtoken`) + `bcryptjs` pour le hash
- Tests: `vitest` + `supertest`

Prérequis
- Node.js 18+ et npm
- PostgreSQL accessible (local ou distant)

Installation
```bash
cd server
npm install
```

Variables d'environnement
- Copier `.env.example` → `.env` et remplir les valeurs :
  - `DATABASE_URL` (Postgres)
  - `PORT` (optionnel, default 4000)
  - `JWT_SECRET`

Exemple minimal (`.env`):
```
DATABASE_URL=postgresql://user:password@localhost:5432/coworkly
PORT=4000
JWT_SECRET=changeme_secure
```

Base de données (Prisma)
- Pour le développement (appliquer migrations locales et générer le client Prisma):
```bash
npx prisma generate
npx prisma migrate dev --name init
```
- Pour déploiement / CI (appliquer migrations générées):
```bash
npx prisma migrate deploy
npx prisma generate
```
- Pour inspecter la base ou lancer Studio:
```bash
npx prisma studio
```

Scripts utiles
- `npm run dev` — démarre le serveur en mode développement (nodemon)
- `npm test` — lance les tests (vitest)

Démarrer le serveur (dev)
```bash
npm run dev
```

Structure importante
- `index.js` — point d'entrée (middlewares, routes montées)
- `prisma/` — `schema.prisma` + `migrations/`
- `src/routes/` — routes (ex: `auth.js`, `rooms.js`, `seats.js`, `reservations.js`, `notifications.js`)
- `src/controllers/` — logique métier
- `src/middlewares/` — middlewares (auth, validation)
- `lib/` — helpers/utilitaires (`Validators.js`)
- `tests/` — suites de tests

Points d'API (extrait)
- `GET /health` — health-check
- Routes montées (préfixes) :
  - `/auth` — authentification (login, register, refresh…)
  - `/rooms` — gestion des salles
  - `/seats` — gestion des sièges
  - `/reservations` — réservations (création, annulation, liste)
  - `/notifications` — notifications utilisateur

Flux d'une requête (haut-niveau)
1. Requête HTTP arrive → Express route
2. Middlewares: CORS, parsing JSON, auth, validations
3. Contrôleur exécute la logique et appelle Prisma pour la BDD
4. Réponse envoyée; erreurs gérées par l'error handler global

Diagramme d'architecture (Mermaid)
```mermaid
flowchart LR
  Client -->|HTTP| API[Express API]
  API --> Middlewares
  Middlewares --> Controllers
  Controllers -->|Prisma Client| Postgres[(PostgreSQL)]
  Controllers --> Notifications[Notification Service]
  API -->|JWT| Auth[(Auth: JWT, Refresh tokens)]
```

Recommandations
- Documenter les endpoints via Swagger/OpenAPI.
- Vérifier `DATABASE_URL` et `JWT_SECRET` en CI/CD.
- Ajouter des exemples de requêtes (Postman collection) si besoin.

Tests
- Lancer tous les tests :
```bash
npm test
```

Support mobile (Flutter)
- L'app Flutter utilise la dépendance `http` pour appeler cette API. Configurer l'URL de base dans l'app (ex: `https://api.example.com` ou `http://localhost:4000` pour dev).

Contact / dépannage
- Si vous rencontrez des erreurs `Prisma` liées aux migrations, exécuter `npx prisma migrate reset` en dev (attention: supprime les données).

---

Fichier créé automatiquement par l'équipe de dev. Ajustez les exemples `.env` et la doc d'API selon vos routes réelles.
