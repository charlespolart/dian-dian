# syntax=docker/dockerfile:1.7
# Multi-stage build with named targets so the prod CI builds the `runtime`
# stage explicitly. Dev compose overlay can build `development` for a
# hot-reload container (uses tsx watch directly on the source).

# ---- builder: compile TypeScript ----------------------------------------
FROM node:22-alpine AS builder
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci
COPY tsconfig.json ./
COPY src ./src
RUN npm run build

# ---- runtime: lean production image, what GHCR pulls --------------------
FROM node:22-alpine AS runtime
WORKDIR /app
ENV NODE_ENV=production
# drizzle-kit is in `dependencies` (not devDeps) so migrations work here.
COPY package.json package-lock.json ./
RUN npm ci --omit=dev
COPY --from=builder /app/dist ./dist
COPY drizzle ./drizzle
COPY drizzle.config.ts ./
# Distinct port from a possible host postgres; matches PORT in compose.
EXPOSE 3001
CMD ["node", "dist/index.js"]

# ---- development: source-mounted hot reload via tsx ---------------------
# Used by ops/docker-compose.dev.yml. Bind-mounts the source over /app/src
# so saving a file restarts the server.
FROM node:22-alpine AS development
WORKDIR /app
ENV NODE_ENV=development
COPY package.json package-lock.json ./
RUN npm ci
COPY tsconfig.json drizzle.config.ts ./
COPY drizzle ./drizzle
COPY src ./src
EXPOSE 3001
CMD ["npx", "tsx", "watch", "src/index.ts"]
