<?php

namespace CodeCorner\SetupWizard\Steps;

use Illuminate\Support\Facades\DB;
use RuntimeException;
use CodeCorner\SetupWizard\SetupManager;

class DatabaseStep extends Step
{
    public function key(): string
    {
        return 'database';
    }

    public function title(): string
    {
        return 'Database';
    }

    public function description(): string
    {
        return 'The database must already exist. The details are saved to your .env file when setup finishes.';
    }

    public function fields(): array
    {
        $drivers = config('setup-wizard.database.drivers');
        $current = config('database.default');

        return [
            'driver' => ['label' => 'Driver', 'type' => 'select', 'options' => array_combine($drivers, $drivers), 'default' => $current],
            'host' => ['label' => 'Host', 'default' => config("database.connections.$current.host", '127.0.0.1'), 'help' => 'Not used for SQLite.'],
            'port' => ['label' => 'Port', 'default' => config("database.connections.$current.port")],
            'database' => ['label' => 'Database name', 'default' => config("database.connections.$current.database"), 'help' => 'For SQLite, a file path such as database/database.sqlite.'],
            'username' => ['label' => 'Username', 'default' => config("database.connections.$current.username")],
            'password' => ['label' => 'Password', 'type' => 'password'],
        ];
    }

    public function rules(): array
    {
        return [
            'driver' => ['required', 'in:'.implode(',', config('setup-wizard.database.drivers'))],
            'host' => ['nullable', 'required_unless:driver,sqlite', 'string'],
            'port' => ['nullable', 'integer'],
            'database' => ['required', 'string'],
            'username' => ['nullable', 'string'],
            'password' => ['nullable', 'string'],
        ];
    }

    public function handle(array $data): void
    {
        $driver = $data['driver'];
        $base = config("database.connections.$driver") ?? throw new RuntimeException("No '$driver' connection in config/database.php.");
        $database = $data['database'];

        if ($driver === 'sqlite') {
            $database = str_replace('\\', '/', $database);
            $root = str_replace('\\', '/', base_path());

            if (! preg_match('~^(/|[A-Za-z]:/)~', $database)) {
                $database = $root.'/'.$database;
            }

            if (str_contains($database, '..') || ! str_starts_with($database, $root.'/') || ! preg_match('/\.(sqlite3?|db)$/i', $database)) {
                throw new RuntimeException('The SQLite database must be a .sqlite or .db file inside the project folder.');
            }

            @mkdir(dirname($database), 0775, true);
            touch($database);
            $overrides = ['database' => $database];
        } else {
            $overrides = array_filter([
                'host' => $data['host'] ?? null, 'port' => $data['port'] ?? null,
                'database' => $database, 'username' => $data['username'] ?? null, 'password' => $data['password'] ?? null,
            ], fn ($value) => $value !== null && $value !== '');
        }

        config(['database.connections.setup_test' => array_merge($base, $overrides)]);

        try {
            DB::connection('setup_test')->getPdo();
        } catch (\Throwable $e) {
            throw new RuntimeException('Could not connect: '.$e->getMessage());
        } finally {
            DB::purge('setup_test');
        }

        app(SetupManager::class)->stage(array_filter([
            'DB_CONNECTION' => $driver,
            'DB_HOST' => $overrides['host'] ?? null,
            'DB_PORT' => $overrides['port'] ?? null,
            'DB_DATABASE' => $overrides['database'],
            'DB_USERNAME' => $overrides['username'] ?? null,
            'DB_PASSWORD' => $overrides['password'] ?? null,
        ], fn ($value) => $value !== null));
    }
}
