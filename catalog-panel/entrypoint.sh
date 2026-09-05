#!/bin/sh
set -e

# Generate config.php from environment (never baked into the image).
cat > /var/www/html/config.php <<PHP
<?php
\$language = '${CATALOG_LANGUAGE:-en}';

\$db_host = '${MYSQL_HOST:-db}';
\$db_user = '${MYSQL_USER}';
\$db_pass = '${MYSQL_PASSWORD}';
\$db_name = '${MYSQL_DATABASE}';

\$url_images = '${CATALOG_IMAGES_URL}';
\$url_icons  = '${CATALOG_ICONS_URL}';
?>
PHP

exec "$@"
