#!/bin/sh
set -e

echo "🔑 Seeding housekeeping permissions..."
php /var/www/html/artisan db:seed --class=HousekeepingPermissionSeeder --force
echo "✅ Housekeeping permissions seeded"
