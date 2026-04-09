# ═══════════════════════════════════════════
# Rocket Shield VPN — Web App Container
# ═══════════════════════════════════════════
FROM nginx:alpine

LABEL maintainer="Rocket Shield VPN"
LABEL description="Educational VPN app for young explorers"

# Copy the single-file app
COPY index.html /usr/share/nginx/html/index.html
COPY icon-512.png /usr/share/nginx/html/icon-512.png

# Nginx config for SPA
RUN echo 'server { \
    listen 80; \
    server_name _; \
    root /usr/share/nginx/html; \
    index index.html; \
    location / { \
        try_files $uri $uri/ /index.html; \
    } \
    gzip on; \
    gzip_types text/html text/css application/javascript; \
}' > /etc/nginx/conf.d/default.conf

EXPOSE 80

HEALTHCHECK --interval=30s --timeout=3s \
    CMD wget -q --spider http://localhost/ || exit 1
