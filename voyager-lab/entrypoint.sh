#!/bin/bash
set -e
cd /var/www/html

# --- .env ---
if [ ! -f .env ]; then
    cp .env.example .env
fi

sed -i \
    -e "s/^APP_ENV=.*/APP_ENV=local/" \
    -e "s/^APP_DEBUG=.*/APP_DEBUG=true/" \
    -e "s#^APP_URL=.*#APP_URL=${APP_URL:-http://localhost:8080}#" \
    -e "s/^DB_CONNECTION=.*/DB_CONNECTION=mysql/" \
    -e "s/^DB_HOST=.*/DB_HOST=db/" \
    -e "s/^DB_PORT=.*/DB_PORT=3306/" \
    -e "s/^DB_DATABASE=.*/DB_DATABASE=voyager/" \
    -e "s/^DB_USERNAME=.*/DB_USERNAME=voyager/" \
    -e "s/^DB_PASSWORD=.*/DB_PASSWORD=voyager/" \
    .env

# App key
if ! grep -q "^APP_KEY=base64:" .env; then
    php artisan key:generate --force
fi

# --- wait for MySQL ---
echo "Waiting for MySQL..."
until mysqladmin ping -h db -uvoyager -pvoyager --skip-ssl --silent 2>/dev/null; do
    sleep 3
    echo "  ...still waiting for db"
done
echo "MySQL is up."

# --- install Voyager once (skip if already installed) ---
INSTALLED=$(mysql -h db -uvoyager -pvoyager --skip-ssl voyager -N -e "SHOW TABLES LIKE 'data_types';" 2>/dev/null || true)
if [ -z "$INSTALLED" ]; then
    echo "Installing Voyager (with dummy data + default admin)..."
    php artisan migrate --force || true
    php artisan voyager:install --with-dummy </dev/null
else
    echo "Voyager already installed, skipping."
fi

# storage symlink must exist every start (container layer is ephemeral on recreate)
rm -f public/storage 2>/dev/null || true
php artisan storage:link 2>/dev/null || ln -s ../storage/app/public public/storage

# Ensure Voyager admin routes are registered (voyager:install only adds these on a
# fresh install; routes/web.php is baked in the image, so re-add every start).
if ! grep -q "Voyager::routes" routes/web.php; then
cat >> routes/web.php <<'ROUTES'

Route::group(['prefix' => 'admin'], function () {
    Voyager::routes();
});
ROUTES
fi
# Ensure App\Models\User uses Voyager's trait (provides hasPermission(), etc.).
# voyager:install patches this on a fresh install only, so re-apply every start.
if ! grep -q "VoyagerUser" app/Models/User.php; then
    sed -i 's/use Laravel\\Sanctum\\HasApiTokens;/&\nuse TCG\\Voyager\\Traits\\VoyagerUser;/' app/Models/User.php
    sed -i 's/use HasApiTokens, HasFactory, Notifiable;/use HasApiTokens, HasFactory, Notifiable, VoyagerUser;/' app/Models/User.php
    sed -i 's/class User extends Authenticatable/class User extends Authenticatable implements \\TCG\\Voyager\\Contracts\\User/' app/Models/User.php
fi
php artisan route:clear >/dev/null 2>&1 || true
php artisan config:clear >/dev/null 2>&1 || true

# Permissions for uploads / cache
chown -R www-data:www-data storage bootstrap/cache public/storage 2>/dev/null || true
chmod -R 775 storage bootstrap/cache 2>/dev/null || true

# Disable Laravel Ignition routes (/_ignition/*, incl. health-check + execute-solution)
cat > /etc/apache2/conf-enabled/disable-ignition.conf <<'IGN'
<LocationMatch "^/_ignition">
    Require all denied
</LocationMatch>
IGN

exec apache2-foreground
