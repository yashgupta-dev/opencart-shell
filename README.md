# Laravel Setup Wizard

Install it, run `php artisan serve`, open the URL: a fresh project walks you through
requirements, app settings, database, migrations and seeders, and the first admin account.

## Install

```bash
composer require codecorner/laravel-setup-wizard --dev
php artisan vendor:publish --tag=setup-wizard-config
php artisan serve
```

Before the project is set up, `artisan serve` prints a reminder and every web request
redirects to `/setup`. Once the last step finishes, a lock file is written to
`storage/app/setup-wizard.lock` and the wizard's routes are no longer loaded.

## Configure (`config/setup-wizard.php`)

- `user.model`: your user model (`App\Models\Admin`, etc.).
- `user.fields`: form fields and validation rules for the first admin.
- `user.attributes`: forced values, e.g. `['is_admin' => true]` or `['role' => 'admin']`.
- `user.creator`: your own class implementing `Contracts\AdminCreator` (assign roles, send mail, ...).
- `seeders`: seeder classes the user can tick on the migration step.
- `migrate.fresh` / `migrate.paths`: `migrate:fresh` or extra migration paths.
- `steps`: add, remove, or reorder steps. Custom steps extend `Steps\Step`.
- `environments`: defaults to `['local']`. The wizard never runs elsewhere.

## Notes

- Settings are held in `storage/app/setup-wizard.staged.json` and written to `.env` once, after the last step, so `artisan serve` restarts only at the very end.
- The database must exist already (SQLite files are created for you).
- Run `php artisan setup:reset` to remove the lock and run the wizard again.
- If the user table already has rows, the project counts as set up (`detect_existing`).

## Security

- Local only: runs when `APP_ENV` is in `environments` (default `local`), and only for clients in `allowed_ips`
  with a Host header matching `allowed_hosts`. Don't add `0.0.0.0` or `*`. Never run `artisan serve --host=0.0.0.0` on an unconfigured project.
- An existing user is never overwritten unless `user.update_existing` is `true`.
- Secrets sit in `storage/app/setup-wizard.staged.json` (mode 0600) until the last step, then move to `.env`.
- SQLite paths are limited to `.sqlite`/`.db` files inside the project; values with line breaks are rejected.
