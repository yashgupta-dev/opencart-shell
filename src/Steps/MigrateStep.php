<?php

namespace CodeCorner\SetupWizard\Steps;

use Illuminate\Support\Facades\Artisan;
use RuntimeException;

class MigrateStep extends Step
{
    public function key(): string
    {
        return 'migrate';
    }

    public function title(): string
    {
        return 'Tables and data';
    }

    public function description(): string
    {
        return config('setup-wizard.migrate.fresh')
            ? 'Warning: this drops every table and rebuilds the database.'
            : 'Creates the database tables, then runs the seeders you pick.';
    }

    public function fields(): array
    {
        $seeders = collect(config('setup-wizard.seeders'));

        if ($seeders->isEmpty()) {
            return [];
        }

        return ['seeders' => [
            'label' => 'Seeders to run',
            'type' => 'checkboxes',
            'options' => $seeders->pluck('label', 'class')->all(),
            'default' => $seeders->where('default', true)->pluck('class')->all(),
        ]];
    }

    public function rules(): array
    {
        $classes = collect(config('setup-wizard.seeders'))->pluck('class')->all();

        return ['seeders' => ['nullable', 'array'], 'seeders.*' => ['in:'.implode(',', $classes)]];
    }

    public function action(): string
    {
        return 'Run migrations';
    }

    public function handle(array $data): void
    {
        $this->artisan(config('setup-wizard.migrate.fresh') ? 'migrate:fresh' : 'migrate', ['--force' => true]);

        foreach (config('setup-wizard.migrate.paths') as $path) {
            $this->artisan('migrate', ['--force' => true, '--path' => $path]);
        }

        foreach ($data['seeders'] ?? [] as $class) {
            $this->artisan('db:seed', ['--class' => $class, '--force' => true]);
        }
    }

    protected function artisan(string $command, array $options): void
    {
        if (Artisan::call($command, $options) !== 0) {
            throw new RuntimeException("`php artisan $command` failed:\n".trim(Artisan::output()));
        }
    }
}
