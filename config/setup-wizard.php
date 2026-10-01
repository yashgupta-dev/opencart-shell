<?php

use CodeCorner\SetupWizard\DefaultAdminCreator;
use CodeCorner\SetupWizard\Steps;

return [
    'enabled' => env('SETUP_WIZARD_ENABLED', true),

    // Wizard only runs in these environments. Keep it local-only unless you know why not.
    'environments' => ['local'],

    'path' => 'setup',
    'lock_file' => storage_path('app/setup-wizard.lock'),
    // Only these client IPs / Host headers may use the wizard (checked against REMOTE_ADDR, not proxy headers).
    // Docker/Sail: add your gateway IP, e.g. '172.18.0.1'. Valet/Herd: '*.test' is already allowed.
    'allowed_ips' => ['127.0.0.1', '::1'],
    'allowed_hosts' => ['localhost', '127.0.0.1', '::1', '*.localhost', '*.test'],

    'staged_file' => storage_path('app/setup-wizard.staged.json'),
    'redirect_after' => '/',

    // Treat the project as already set up if the user table already has rows.
    'detect_existing' => true,

    // Add, remove or reorder steps. Each class extends CodeCorner\SetupWizard\Steps\Step.
    'steps' => [
        Steps\RequirementsStep::class,
        Steps\AppStep::class,
        Steps\DatabaseStep::class,
        Steps\MigrateStep::class,
        Steps\AdminStep::class,
    ],

    'requirements' => [
        'php' => '8.1.0',
        'extensions' => ['pdo', 'mbstring', 'openssl', 'tokenizer', 'xml', 'ctype', 'json'],
        'writable' => [storage_path(), base_path('bootstrap/cache')],
    ],

    'database' => ['drivers' => ['mysql', 'pgsql', 'sqlite', 'sqlsrv']],

    'migrate' => [
        'fresh' => false,   // true = migrate:fresh (drops all tables!)
        'paths' => [],      // extra --path values, e.g. ['database/migrations/tenant']
    ],

    // Seeders the user can tick on the migration step.
    'seeders' => [
        ['class' => 'Database\\Seeders\\DatabaseSeeder', 'label' => 'Default seed data', 'default' => false],
    ],

    'user' => [
        'model' => 'App\\Models\\User',
        'creator' => DefaultAdminCreator::class,   // implement Contracts\AdminCreator to customise
        'unique_by' => 'email',
        'update_existing' => false,                // false = refuse to overwrite an existing user with the same unique_by
        'verify_email' => true,                    // sets email_verified_at if the column exists
        'attributes' => [],                        // forced extras, e.g. ['is_admin' => true, 'role' => 'admin']
        'fields' => [
            'name' => ['label' => 'Name', 'type' => 'text', 'rules' => ['required', 'string', 'max:255']],
            'email' => ['label' => 'Email', 'type' => 'email', 'rules' => ['required', 'email']],
            'password' => ['label' => 'Password', 'type' => 'password', 'rules' => ['required', 'min:8', 'confirmed']],
        ],
    ],
];
