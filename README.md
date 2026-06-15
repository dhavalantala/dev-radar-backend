# dev-radar
Application based on Omnistack 10 

- The main technologies used are : Nodejs , React and React Native
- This repository covers backend only. 
  <br> For the frontend part please access - [dev-radar-frontend](https://github.com/mgiatti/dev-radar-frontend)
  <br> For the mobile part please access - [dev-radar-mobile](https://github.com/mgiatti/dev-radar-mobile)

# important
to get things work you should create a .env file in the root of your project with the following parameters:

- DB_ADMIN_USERNAME - database user name
- DB_ADMIN_PASSWORD - database admin password
- DB_NAME - database name
- DB_HOST - database host
- DB_PORT - database port (not used in URI connection)
- DB_PREFIX - database prefix
- GITHUB_API - github api url - default https://api.github.com
- LISTEN_PORT - port to be listen to the webservice

For more info please check dotenv - https://www.npmjs.com/package/dotenv

# Dev Radar Backend — Dockerized 🐳

> A real-world Docker Compose practice project.
> Node.js + MongoDB + Socket.io backend fully containerized.
> Based on Omnistack 10 by Rocketseat.

---

## 📁 Project Structure

```
dev-radar-backend/
├── src/
│   ├── index.js                # Express app entry point
│   ├── routes.js               # All API routes
│   ├── controllers/
│   │   ├── DevController.js    # CRUD for developers
│   │   └── SearchController.js # Search devs by tech + location
│   ├── models/
│   │   └── Dev.js              # Mongoose model
│   ├── utils/
│   │   └── databaseUtils.js    # MongoDB connection string builder
│   └── websocket.js            # Socket.io setup
├── Dockerfile                  # Node.js container definition
├── docker-compose.yml          # Full stack orchestration
├── .env                        # Environment variables (never commit!)
├── .dockerignore               # Files to exclude from build
├── package.json
└── yarn.lock
```

---

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────┐
│                  docker compose up                  │
│                                                     │
│  ┌───────────────────┐      ┌───────────────────┐   │
│  │  devradar-backend │      │     mongodb        │   │
│  │                   │      │                   │   │
│  │  Node.js 18       │─────►│  mongo:6.0        │   │
│  │  Express          │      │                   │   │
│  │  nodemon          │      │  volume:          │   │
│  │  Socket.io        │      │  mongo-data ✅    │   │
│  │                   │      │                   │   │
│  │  port 3333        │      │  port 27017       │   │
│  └───────────────────┘      └───────────────────┘   │
│                                                     │
│         devradar-network (bridge) ✅                │
└─────────────────────────────────────────────────────┘
```

---

## 🐳 Docker Concepts Used

| Concept | Where it's applied |
|---------|-------------------|
| Dockerfile + layer caching | `COPY package.json` before `COPY src/` |
| Named volume | `mongo-data:/data/db` — MongoDB data persists |
| Bind mount | `./src:/app/src` — hot reload without rebuild |
| ENV file | `.env` injected via `env_file` |
| Custom network | `devradar-network` — containers talk by name |
| `depends_on` + healthcheck | backend waits for MongoDB to be healthy |
| `restart: unless-stopped` | auto-recovers from crashes |
| Container DNS | app connects to `mongodb` by name, not IP |

---

## ⚙️ Configuration

### `.env`

```env
DB_ADMIN_USERNAME=admin
DB_ADMIN_PASSWORD=password123
DB_NAME=devradar?authSource=admin
DB_HOST=mongodb
DB_PORT=27017
DB_PREFIX=mongodb
GITHUB_API=https://api.github.com
LISTEN_PORT=3333
```

> ⚠️ Never commit `.env` to Git — add it to `.gitignore`
> `DB_HOST=mongodb` → container name, not localhost
> `authSource=admin` → MongoDB root user lives in admin db

---

## 📄 Dockerfile

```dockerfile
FROM node:18-slim

WORKDIR /app

# Copy package files first — layer caching!
# As long as package.json doesn't change, yarn install is cached
COPY package*.json yarn.lock ./

# Install dependencies
RUN yarn install --frozen-lockfile

# Copy source code — changes often, goes last
COPY src/ ./src/

EXPOSE 3333

CMD ["yarn", "dev"]
```

---

## 📄 docker-compose.yml

```yaml
services:

  mongodb:
    image: mongo:6.0
    container_name: mongodb
    restart: unless-stopped
    environment:
      MONGO_INITDB_ROOT_USERNAME: admin
      MONGO_INITDB_ROOT_PASSWORD: password123
      MONGO_INITDB_DATABASE: devradar
    volumes:
      - mongo-data:/data/db
    networks:
      - devradar-network
    healthcheck:
      test: ["CMD", "mongosh", "--eval", "db.adminCommand('ping')"]
      interval: 10s
      timeout: 5s
      retries: 5

  backend:
    build: .
    container_name: devradar-backend
    restart: unless-stopped
    ports:
      - "3333:3333"
    env_file:
      - .env
    networks:
      - devradar-network
    depends_on:
      mongodb:
        condition: service_healthy
    volumes:
      - ./src:/app/src

networks:
  devradar-network:
    driver: bridge

volumes:
  mongo-data:
    driver: local
```

---

## 🚀 How to Run

### Prerequisites
- Docker Desktop installed and running
- Port `3333` free on your Mac

### Start the stack

```bash
# Clone the repo
git clone https://github.com/mgiatti/dev-radar-backend.git
cd dev-radar-backend

# Create .env file (see Configuration section above)

# Start everything
docker compose up --build

# Or run in background
docker compose up --build -d
```

### Verify it's running

```bash
docker compose ps
```

Expected output:
```
NAME                STATUS
devradar-backend    running
mongodb             running (healthy)
```

---

## 🔧 Useful Commands

```bash
# ── Start / Stop ─────────────────────────────────────────
docker compose up --build          # build + start
docker compose up -d               # start in background
docker compose stop                # stop containers (keep data)
docker compose down                # stop + remove containers
docker compose down -v             # stop + remove containers + volumes (wipes DB!)

# ── Logs ─────────────────────────────────────────────────
docker compose logs                # all services
docker compose logs backend        # backend only
docker compose logs mongodb        # mongodb only
docker compose logs -f backend     # follow live logs

# ── Debugging ────────────────────────────────────────────
docker compose ps                  # check status of services
docker compose exec backend bash   # shell into backend container
docker compose exec mongodb mongosh # open MongoDB shell
docker compose restart backend     # restart one service

# ── Rebuild ──────────────────────────────────────────────
docker compose up --build          # rebuild images + start
docker compose build --no-cache    # force full rebuild
```

---

## 🌐 API Routes

Base URL: `http://localhost:3333`

| Method | Route | Description |
|--------|-------|-------------|
| GET | `/devs` | List all developers |
| POST | `/devs` | Create a new developer |
| PUT | `/devs` | Update a developer |
| DELETE | `/devs` | Delete a developer |
| GET | `/search` | Search devs by tech + location |

---

## 🧪 Testing with curl

### Get all devs
```bash
curl http://localhost:3333/devs
```

### Create a dev
```bash
curl -X POST http://localhost:3333/devs \
  -H "Content-Type: application/json" \
  -d '{
    "github_username": "dhavalantala",
    "techs": "Docker, Python, Machine Learning",
    "latitude": -23.5505,
    "longitude": -46.6333
  }'
```

### Search devs by tech and location
```bash
curl "http://localhost:3333/search?techs=Docker&latitude=-23.5505&longitude=-46.6333"
```

### Update a dev
```bash
curl -X PUT http://localhost:3333/devs \
  -H "Content-Type: application/json" \
  -d '{
    "github_username": "dhavalantala",
    "techs": "Docker, Python, ML, DevOps"
  }'
```

### Delete a dev
```bash
curl -X DELETE http://localhost:3333/devs \
  -H "Content-Type: application/json" \
  -d '{"github_username": "dhavalantala"}'
```

---

## 🐛 Troubleshooting

### `Authentication failed` — MongoDB auth error
```
UserNotFound: Could not find user "admin" for db "devradar"
```
**Fix:** Add `?authSource=admin` to `DB_NAME` in `.env`:
```
DB_NAME=devradar?authSource=admin
```
Then run `docker compose down -v && docker compose up --build`

---

### `Couldn't find package.json in /app`
```
error Couldn't find a package.json file in "/app"
```
**Fix:** Bind mount is overriding `/app`. Check `docker-compose.yml` volumes section — make sure you're mounting `./src:/app/src` not `./:/app`

---

### `Container name already in use`
```
Conflict. The container name "/mongodb" is already in use
```
**Fix:** Old container still exists from a previous run:
```bash
docker rm -f mongodb devradar-backend
docker compose up --build
```

---

### `version` is obsolete warning
```
the attribute `version` is obsolete
```
**Fix:** Remove the `version:` line from `docker-compose.yml` — it's not needed in modern Docker Compose.

---

## 💡 Key Learnings from this Project

### Why `DB_HOST=mongodb` and not `localhost`?
Inside Docker, each container has its own `localhost`.
If you use `localhost`, the backend looks for MongoDB inside itself — not found!
Using the container name `mongodb` lets Docker DNS resolve it to the correct container IP.

### Why `authSource=admin`?
MongoDB creates the root user (`admin`) in the `admin` database.
The app connects to `devradar` database.
Without `authSource=admin`, MongoDB looks for the user in `devradar` — not found!

### Why `depends_on` with `healthcheck`?
Without it, the backend starts before MongoDB is ready and crashes.
`condition: service_healthy` makes Docker wait until MongoDB passes its health check before starting the backend.

### Why bind mount `./src:/app/src`?
During development, you want to edit code and see changes immediately.
The bind mount makes your local `src/` folder appear inside the container.
Nodemon watches for changes and restarts automatically — no rebuild needed!

---

## 📝 Progress

| Task | Status |
|------|--------|
| Cloned repo | ✅ |
| Created Dockerfile | ✅ |
| Created docker-compose.yml | ✅ |
| Fixed MongoDB auth issue | ✅ |
| App connected to MongoDB | ✅ |
| Tested API with curl | ✅ |

---

*Practice project for Docker → DevOps learning journey*
*Stack: Node.js 18 · MongoDB 6.0 · Express · Socket.io · Docker Compose*
*Platform: macOS · Docker Desktop*