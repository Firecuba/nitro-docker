# Stage 1: Composer dependencies
FROM php:8.5-cli-alpine AS composer-builder

ARG COMMIT=f77e2b6

WORKDIR /app

# Install system dependencies and PHP extensions
RUN apk add --no-cache \
    git \
    zip \
    unzip \
    icu-dev \
    libzip-dev \
    libpng-dev \
    libjpeg-turbo-dev \
    freetype-dev \
    linux-headers

RUN docker-php-ext-configure gd --with-freetype --with-jpeg
RUN docker-php-ext-install -j$(nproc) \
    sockets \
    intl \
    pdo_mysql \
    zip \
    gd

# Install Composer
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

# Clone the repository
RUN git config --global --add safe.directory /app
RUN git clone --recurse-submodules https://github.com/ObjectRetros/atomcms.git .
RUN git checkout $COMMIT

# Upstream bug (re-verified against the current codebase after the 53ea66d -> f77e2b6
# update, since upstream rewrote the whole badge subsystem in between): UserBadge (a
# user's actual earned badges, shown in Housekeeping > Users > Badges) still doesn't
# implement the HasBadge interface, unlike every other model HabboBadgeColumn expects.
# HabboBadgeColumn::getBadgePath()/getBadgeName() silently return '' for any record that
# isn't a HasBadge instance, so every user's badge list renders as broken images.
# (The old shop-package and room-guild-badge variants of this bug are gone: shop packages
# now use a direct image upload (Storage::url($package->image)) instead of a badge code,
# and the website no longer has a room/guild detail page at all.)
COPY <<'EOF' /tmp/fix_user_badge.php
<?php
$path = "/app/app/Models/Game/Player/UserBadge.php";
$content = file_get_contents($path);

$old1 = "use Illuminate\Database\Eloquent\Relations\BelongsTo;";
$new1 = "use App\Models\Compositions\HasBadge;\nuse Illuminate\Database\Eloquent\Relations\BelongsTo;";
if (strpos($content, $old1) === false) {
    fwrite(STDERR, "fix_user_badge: import line not found (upstream may have changed)\n");
    exit(1);
}
$content = str_replace($old1, $new1, $content);

$old2 = "class UserBadge extends Model\n{";
$new2 = "class UserBadge extends Model implements HasBadge\n{";
if (strpos($content, $old2) === false) {
    fwrite(STDERR, "fix_user_badge: class declaration not found (upstream may have changed)\n");
    exit(1);
}
$content = str_replace($old2, $new2, $content);

$old3 = "    public function user(): BelongsTo\n    {\n        return \$this->belongsTo(User::class, 'user_id');\n    }\n}";
$new3 = "    public function user(): BelongsTo\n    {\n        return \$this->belongsTo(User::class, 'user_id');\n    }\n\n    public function getBadgePath(): string\n    {\n        return sprintf('%s%s.gif', setting('badges_path'), \$this->getBadgeName());\n    }\n\n    public function getBadgeName(): string\n    {\n        return \$this->badge_code ?: '';\n    }\n}";
if (strpos($content, $old3) === false) {
    fwrite(STDERR, "fix_user_badge: closing brace pattern not found (upstream may have changed)\n");
    exit(1);
}
$content = str_replace($old3, $new3, $content);

file_put_contents($path, $content);
echo "fix_user_badge: patched $path\n";
EOF
RUN php /tmp/fix_user_badge.php && rm /tmp/fix_user_badge.php

# Upstream bug: the homepage ('/') and the no-op '/login' redirect are grouped under the
# same throttle:15,1 limiter as the brute-force-sensitive auth routes (register, password
# reset). 15 requests/min is meant to slow down credential-stuffing on those POST routes,
# but it also caps plain homepage visits, so a handful of page loads/reloads in a minute
# (mobile Safari retries, multiple tabs, etc.) return 429 on the homepage itself.
COPY <<'EOF' /tmp/fix_homepage_throttle.php
<?php
$path = "/app/routes/web.php";
$content = file_get_contents($path);

$old = <<<'OLD'
    Route::middleware(['guest', 'throttle:15,1'])->withoutMiddleware('force.staff.2fa')->group(function () {
        Route::get('/login', static fn () => to_route('welcome'))->name('login');
        Route::get('/', HomeController::class)->name('welcome');

        Route::get('/register', [RegisteredUserController::class, 'create']);
OLD;

$new = <<<'NEW'
    Route::middleware('guest')->withoutMiddleware('force.staff.2fa')->group(function () {
        Route::get('/login', static fn () => to_route('welcome'))->name('login');
        Route::get('/', HomeController::class)->name('welcome');
    });

    Route::middleware(['guest', 'throttle:15,1'])->withoutMiddleware('force.staff.2fa')->group(function () {
        Route::get('/register', [RegisteredUserController::class, 'create']);
NEW;

if (strpos($content, $old) === false) {
    fwrite(STDERR, "fix_homepage_throttle: pattern not found (upstream may have changed)\n");
    exit(1);
}
file_put_contents($path, str_replace($old, $new, $content));
echo "fix_homepage_throttle: patched $path\n";
EOF
RUN php /tmp/fix_homepage_throttle.php && rm /tmp/fix_homepage_throttle.php

# Install composer dependencies
RUN composer install \
    --no-interaction \
    --no-dev \
    --prefer-dist \
    --optimize-autoloader \
    --no-scripts

# Generate optimized autoload files
RUN composer dump-autoload --optimize


# Stage 2: Node/NPM build
FROM node:20-alpine AS npm-builder

WORKDIR /app

# Copy application files from composer stage
COPY --from=composer-builder /app /app

# Install dependencies and build assets
RUN yarn install --frozen-lockfile
RUN yarn run build:atom
RUN yarn run build:dusk

# Clean up node_modules to save space
RUN rm -rf node_modules


# Stage 3: Final image with serversideup/php (nginx + PHP-FPM)
FROM serversideup/php:8.5-fpm-nginx-alpine

ENV PHP_OPCACHE_ENABLE=1

WORKDIR /var/www/html

# Switch to root for setup
USER root

# Copy application from npm-builder
COPY --from=npm-builder --chown=www-data:www-data /app /var/www/html

# Create necessary directories and set permissions
RUN mkdir -p \
    storage/framework/cache \
    storage/framework/sessions \
    storage/framework/views \
    storage/logs \
    bootstrap/cache \
    && chown -R www-data:www-data /var/www/html/storage /var/www/html/bootstrap/cache \
    && chmod -R 775 /var/www/html/storage /var/www/html/bootstrap/cache

# Custom nginx configuration for Laravel
COPY <<'EOF' /etc/nginx/server-opts.d/laravel.conf
# Security headers
add_header X-Frame-Options "SAMEORIGIN" always;
add_header X-Content-Type-Options "nosniff" always;
add_header X-XSS-Protection "1; mode=block" always;

# CORS headers for /gamedata directory and all subdirectories
location ~ ^/gamedata/ {
    # Always add CORS headers
    add_header Access-Control-Allow-Origin "*" always;
    add_header Access-Control-Allow-Methods "GET, POST, PUT, DELETE, OPTIONS" always;
    add_header Access-Control-Allow-Headers "DNT,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type,Range,Authorization,X-CSRF-TOKEN" always;
    add_header Access-Control-Expose-Headers "Content-Length,Content-Range" always;
    add_header Access-Control-Allow-Credentials "false" always;
    
    # Handle preflight requests
    if ($request_method = 'OPTIONS') {
        add_header Access-Control-Allow-Origin "*" always;
        add_header Access-Control-Allow-Methods "GET, POST, PUT, DELETE, OPTIONS" always;
        add_header Access-Control-Allow-Headers "DNT,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type,Range,Authorization,X-CSRF-TOKEN" always;
        add_header Access-Control-Max-Age 86400 always;
        add_header Content-Type "text/plain; charset=utf-8" always;
        add_header Content-Length 0 always;
        return 204;
    }
    
    try_files $uri $uri/ @fallback;
}

# Fallback for gamedata requests
location @fallback {
    add_header Access-Control-Allow-Origin "*" always;
    add_header Access-Control-Allow-Methods "GET, POST, PUT, DELETE, OPTIONS" always;
    add_header Access-Control-Allow-Headers "DNT,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type,Range,Authorization,X-CSRF-TOKEN" always;
    try_files $uri /index.php?$query_string;
}

# Static file caching. try_files falls through to Laravel for any matching
# extension that isn't a physical file (e.g. Livewire's dynamic /livewire/livewire.js
# route), instead of 404ing before the request ever reaches PHP-FPM.
location ~* \.(jpg|jpeg|png|gif|ico|css|js|svg|woff|woff2|ttf|eot)$ {
    expires 1y;
    add_header Cache-Control "public, immutable";
    try_files $uri /index.php?$query_string;
}
EOF

# PHP configuration overrides
RUN echo 'max_execution_time = 300' >> /usr/local/etc/php/conf.d/custom.ini \
    && echo 'upload_max_filesize = 20M' >> /usr/local/etc/php/conf.d/custom.ini \
    && echo 'post_max_size = 20M' >> /usr/local/etc/php/conf.d/custom.ini \
    && echo 'memory_limit = 256M' >> /usr/local/etc/php/conf.d/custom.ini \
    && echo 'opcache.enable=1' >> /usr/local/etc/php/conf.d/custom.ini \
    && echo 'opcache.memory_consumption=256' >> /usr/local/etc/php/conf.d/custom.ini \
    && echo 'opcache.interned_strings_buffer=16' >> /usr/local/etc/php/conf.d/custom.ini \
    && echo 'opcache.max_accelerated_files=10000' >> /usr/local/etc/php/conf.d/custom.ini

# Set correct ownership
RUN chown -R www-data:www-data /var/www/html

RUN install-php-extensions sockets intl gd

COPY --chmod=755 ./entrypoint.d/ /etc/entrypoint.d/

# Switch back to www-data user
USER www-data

RUN php artisan storage:link --force --silent

# serversideup/php uses S6 overlay to manage nginx + php-fpm
# No need to specify CMD, it's handled by the base image