<?php

namespace CodeCorner\SetupWizard\Steps;

use CodeCorner\SetupWizard\SetupManager;

class AppStep extends Step
{
    public function key(): string
    {
        return 'app';
    }

    public function title(): string
    {
        return 'Application';
    }

    public function fields(): array
    {
        return [
            'app_name' => ['label' => 'Application name', 'default' => config('app.name')],
            'app_url' => ['label' => 'Application URL', 'type' => 'url', 'default' => config('app.url'), 'help' => 'The address you open in the browser.'],
        ];
    }

    public function rules(): array
    {
        return ['app_name' => ['required', 'string', 'max:100'], 'app_url' => ['required', 'url']];
    }

    public function handle(array $data): void
    {
        app(SetupManager::class)->stage(['APP_NAME' => $data['app_name'], 'APP_URL' => $data['app_url']]);
    }
}
