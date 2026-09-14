# HyrxMQ — self-contained broker + web dashboard container
#
# Multi-stage build:
#   Stage 1 (build): compiles binaries with pixi/mojo
#   Stage 2 (runtime): slim image with only the deployed artifacts
#
# Build:
#   docker build -t hyrxmq .
#
# Run:
#   docker run -p 8080:8080 -p 5673:5673 hyrxmq
#
# Custom ports:
#   docker run -p 9090:9090 -p 5672:5672 \
#     -e HYRXMQ_WEB_PORT=9090 -e HYRXMQ_PORT=5672 hyrxmq

# ── Stage 1: build ────────────────────────────────────────────────────────────
FROM ubuntu:22.04 AS build

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
        curl gcc g++ clang ca-certificates git xz-utils && \
    rm -rf /var/lib/apt/lists/*

# Install pixi.
RUN curl -fsSL https://pixi.sh/install.sh | bash
ENV PATH="/root/.pixi/bin:${PATH}"

# Install node (for frontend build).
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - && \
    apt-get install -y --no-install-recommends nodejs && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy manifest files first (layer cache for deps).
COPY pixi.toml pixi.lock* ./
COPY src/ src/
COPY vendor/ vendor/
COPY vendor/libcut_preload.so /usr/local/lib/libcut_preload.so

# Install deps + compile all binaries.
ENV HYRXMQ_HOST=0.0.0.0
RUN mkdir -p build && pixi install && \
    clang -O2 -c src/hyrxmq/shutdown_shim.c -o build/shutdown_shim.o && \
    pixi run mojo build -I src -I vendor/flare -Xlinker build/shutdown_shim.o src/hyrxmq_web/hyrxmq_web.mojo -o build/hyrxmq-web && \
    pixi run mojo build -I src -I vendor/flare -Xlinker build/shutdown_shim.o src/hyrxmq/main_listen.mojo -o build/hyrxmq-listen && \
    pixi run mojo build -I src -I vendor/flare src/hyrx/main.mojo -o build/hyrx && \
    cd src/hyrxmq_web/frontend && npm install && npm run build && \
    cd /app && gcc -O2 -fPIC -shared -o build/libflare_fs.so vendor/flare/flare/http/ffi/fs_wrapper.c

# Collect Mojo runtime shared libraries from the pixi environment.
RUN mkdir -p /runtime-libs && \
    cp /app/.pixi/envs/default/lib/libKGENCompilerRTShared.so /runtime-libs/ && \
    cp /app/.pixi/envs/default/lib/libMSupportGlobals.so /runtime-libs/ && \
    cp /app/.pixi/envs/default/lib/libAsyncRTRuntimeGlobals.so /runtime-libs/ && \
    cp /app/.pixi/envs/default/lib/libstdc++.so.6 /runtime-libs/ && \
    cp /app/.pixi/envs/default/lib/libgcc_s.so.1 /runtime-libs/ && \
    cp /app/.pixi/envs/default/lib/libcrypto.so.3 /runtime-libs/ && \
    cp /app/.pixi/envs/default/lib/libssl.so.3 /runtime-libs/ 2>/dev/null; true && \
    cp /usr/local/lib/libcut_preload.so /runtime-libs/

# ── Stage 2: runtime ──────────────────────────────────────────────────────────
FROM ubuntu:22.04 AS runtime

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        libgomp1 curl ca-certificates && \
    rm -rf /var/lib/apt/lists/*

# Non-root user.
RUN groupadd -r hyrx && useradd -r -g hyrx -d /app -s /sbin/nologin hyrx

WORKDIR /app

# Copy binaries.
COPY --from=build /app/build/hyrxmq-web /app/build/hyrxmq-web
COPY --from=build /app/build/hyrxmq-listen /app/build/hyrxmq-listen
COPY --from=build /app/build/hyrx /app/build/hyrx

# Copy flare FFI shlibs.
COPY --from=build /app/build/libflare_fs.so /app/build/libflare_fs.so
COPY vendor/libflare_tls.so /app/build/libflare_tls.so

# Copy Mojo runtime libs.
COPY --from=build /runtime-libs/ /usr/local/lib/

# Copy React dashboard build output.
COPY --from=build /app/src/hyrxmq_web/frontend/dist/ /app/src/hyrxmq_web/frontend/dist/

# Shared library cache.
RUN ldconfig /usr/local/lib /app/build

# Expose ports.
# 8080 = web dashboard (HTTP)
# 5673 = AMQP broker (TCP)
EXPOSE 8080 5673

# Runtime configuration.
ENV HYRXMQ_WEB_PORT=8080
ENV HYRXMQ_PORT=5673
ENV HYRXMQ_HOST=0.0.0.0
ENV LD_LIBRARY_PATH=/usr/local/lib:/app/build

# Health check.
HEALTHCHECK --interval=10s --timeout=3s --start-period=5s --retries=3 \
    CMD curl -sf http://127.0.0.1:${HYRXMQ_WEB_PORT}/health || exit 1

USER hyrx

CMD ["/app/build/hyrxmq-web"]
