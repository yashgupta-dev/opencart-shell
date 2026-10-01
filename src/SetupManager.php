<?php

namespace CodeCorner\SetupWizard;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Str;
use Throwable;
use CodeCorner\SetupWizard\Steps\Step;

class SetupManager
{
    public function enabled(): bool
    {
        return config('setup-wizard.enabled') && app()->environment(config('setup-wizard.environments'));
    }

    /** Loopback-style allowlist on the raw socket address and Host header (blocks LAN access and DNS rebinding). */
    public function allowsRequest(Request $request): bool
    {
        if (! in_array($request->server->get('REMOTE_ADDR'), config('setup-wizard.allowed_ips'), true)) {
            return false;
        }

        $host = strtolower(trim((string) preg_replace('/:\d+$/', '', (string) $request->server->get('HTTP_HOST')), '[]'));

        return $host !== '' && Str::is(config('setup-wizard.allowed_hosts'), $host);
    }

    public function completed(): bool
    {
        if (is_file(config('setup-wizard.lock_file'))) {
            return true;
        }

        // Once the wizard has started, users created by its own seeders must not count as "already set up".
        if (is_file(config('setup-wizard.staged_file'))) {
            return false;
        }

        return config('setup-wizard.detect_existing') && $this->hasUsers();
    }

    public function markCompleted(): void
    {
        file_put_contents(config('setup-wizard.lock_file'), json_encode(['completed_at' => now()->toIso8601String()]));
    }

    public function reset(): void
    {
        @unlink(config('setup-wizard.lock_file'));
        @unlink(config('setup-wizard.staged_file'));
    }

    /** Hold .env values in a temp file so the dev server is not restarted mid-wizard. */
    public function stage(array $values): void
    {
        foreach ($values as $key => $value) {
            if (preg_match('/[\r\n\0]/', (string) $value)) {
                throw new \InvalidArgumentException("The value for {$key} cannot contain line breaks.");
            }
        }

        $file = config('setup-wizard.staged_file');
        file_put_contents($file, json_encode(array_merge($this->staged(), $values)), LOCK_EX);
        @chmod($file, 0600);
    }

    public function staged(): array
    {
        $file = config('setup-wizard.staged_file');

        return is_file($file) ? (json_decode(file_get_contents($file), true) ?: []) : [];
    }

    /** Apply staged values to runtime config so every step sees them without touching .env. */
    public function applyStaged(): void
    {
        $env = $this->staged();

        if (isset($env['APP_NAME'])) {
            config(['app.name' => $env['APP_NAME']]);
        }
        if (isset($env['APP_URL'])) {
            config(['app.url' => $env['APP_URL']]);
        }
        if (isset($env['DB_CONNECTION'])) {
            $driver = $env['DB_CONNECTION'];
            config(['database.default' => $driver]);
            foreach (['host', 'port', 'database', 'username', 'password'] as $key) {
                if (isset($env['DB_'.strtoupper($key)])) {
                    config(["database.connections.$driver.$key" => $env['DB_'.strtoupper($key)]]);
                }
            }
        }
    }

    /** Write staged values to .env. Call after the response is sent. */
    public function commitStaged(): void
    {
        if ($env = $this->staged()) {
            app(EnvWriter::class)->set($env);
        }
        @unlink(config('setup-wizard.staged_file'));
    }

    /** @return array<string, Step> keyed by step key */
    public function steps(): array
    {
        $steps = [];
        foreach (config('setup-wizard.steps') as $class) {
            $step = app($class);
            $steps[$step->key()] = $step;
        }

        return $steps;
    }

    /** Make the wizard work on a blank install: no .env, no APP_KEY, no sessions table yet. */
    public function prepareRuntime(): void
    {
        app(EnvWriter::class)->ensureBasics();
        config(['session.driver' => 'file', 'cache.default' => 'file']);
    }

    protected function hasUsers(): bool
    {
        try {
            $model = config('setup-wizard.user.model');

            return class_exists($model)
                && Schema::hasTable((new $model)->getTable())
                && $model::query()->exists();
        } catch (Throwable) {
            return false;
        }
    }
}
