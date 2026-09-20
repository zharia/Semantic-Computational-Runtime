# HyrxMQ website — multi-stage production image
#
# Stage 1 builds the React/TypeScript site with Node.
# Stage 2 serves the static output with an unprivileged nginx on port 8080.
#
# Build:
#   docker build -t hyrxmq-website:latest .
#
# Run:
#   docker run --rm -p 8080:8080 hyrxmq-website:latest

# ── Stage 1: build ────────────────────────────────────────────────────────────
FROM node:20-alpine AS build

WORKDIR /app

# Dependency layer (cache-friendly).
COPY package.json package-lock.json ./
RUN npm ci

# Source + production build.
COPY tsconfig.json vite.config.ts index.html ./
COPY src ./src
COPY public ./public
RUN npm run build

# ── Stage 2: runtime ──────────────────────────────────────────────────────────
FROM nginxinc/nginx-unprivileged:1.27-alpine AS runtime

# Unprivileged nginx listens on 8080 as a non-root user.
COPY docker/nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=build /app/dist /usr/share/nginx/html

EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD wget -qO- http://127.0.0.1:8080/healthz || exit 1

# Base image already runs as uid 101 (nginx).
CMD ["nginx", "-g", "daemon off;"]
