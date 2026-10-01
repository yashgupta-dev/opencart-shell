<?php

namespace CodeCorner\SetupWizard\Steps;

class RequirementsStep extends Step
{
    public function key(): string
    {
        return 'requirements';
    }

    public function title(): string
    {
        return 'Requirements';
    }

    public function description(): string
    {
        return 'Checking that this machine can run the project.';
    }

    public function checks(): array
    {
        $config = config('setup-wizard.requirements');
        $checks = [[
            'label' => 'PHP '.$config['php'].' or newer (running '.PHP_VERSION.')',
            'ok' => version_compare(PHP_VERSION, $config['php'], '>='),
            'hint' => 'Upgrade PHP.',
        ]];

        foreach ($config['extensions'] as $extension) {
            $checks[] = ['label' => "PHP extension: {$extension}", 'ok' => extension_loaded($extension), 'hint' => "Enable the {$extension} extension in php.ini."];
        }

        foreach ($config['writable'] as $path) {
            $checks[] = ['label' => 'Writable: '.str_replace(base_path().DIRECTORY_SEPARATOR, '', $path), 'ok' => is_writable($path), 'hint' => 'Make this folder writable.'];
        }

        $checks[] = ['label' => 'Writable: .env', 'ok' => is_writable(base_path('.env')), 'hint' => 'Make the .env file writable.'];

        return $checks;
    }

    public function action(): string
    {
        return 'Looks good, continue';
    }

    public function handle(array $data): void {}
}
