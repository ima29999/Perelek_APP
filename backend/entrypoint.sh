#!/bin/sh
set -e

DB_HOST="${DB_HOST:-mysql}"
DB_PORT="${DB_PORT:-3306}"
DB_USERNAME="${DB_USERNAME:-root}"
DB_PASSWORD="${DB_PASSWORD:-root}"

echo "Menunggu MySQL di ${DB_HOST}:${DB_PORT} siap..."
until php -r "new PDO('mysql:host=${DB_HOST};port=${DB_PORT}', '${DB_USERNAME}', '${DB_PASSWORD}');" > /dev/null 2>&1; do
  sleep 2
done
echo "MySQL siap."

if [ ! -f .env ]; then
  echo "Membuat .env dari .env.example..."
  cp .env.example .env
fi

if ! grep -q "^APP_KEY=base64:" .env; then
  echo "Generate APP_KEY..."
  php artisan key:generate --force
fi

echo "Menjalankan migrasi..."
php artisan migrate --force

chmod -R 775 storage bootstrap/cache || true

exec "$@"
