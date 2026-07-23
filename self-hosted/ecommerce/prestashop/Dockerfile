ARG PRESTASHOP_VERSION=latest
FROM prestashop/prestashop:${PRESTASHOP_VERSION}

ENV DB_SERVER=db \
    DB_NAME=app \
    DB_USER=app \
    DB_PASSWD=changeme \
    PS_INSTALL_AUTO=1 \
    PS_ERASE_DB=0 \
    PS_DOMAIN=localhost \
    PS_LANGUAGE=en \
    PS_COUNTRY=us \
    ADMIN_MAIL=admin@your-domain.example.com \
    ADMIN_PASSWD=changeme

# PrestaShop's own installer writes generated config, uploaded product
# images, and installed modules/themes directly into the webroot — the
# entire directory needs to persist, not just an uploads subfolder, or a
# redeploy loses the whole storefront, not just its content.
VOLUME ["/var/www/html"]

EXPOSE 80

HEALTHCHECK --interval=30s --timeout=5s --start-period=30s --retries=5 \
  CMD curl -fsS http://localhost:80/ || exit 1
