<?php

namespace CodeCorner\SetupWizard\Steps;

class AdminStep extends Step
{
    public function key(): string
    {
        return 'admin';
    }

    public function title(): string
    {
        return 'Admin account';
    }

    public function description(): string
    {
        return 'Create the first administrator.';
    }

    public function fields(): array
    {
        $fields = [];

        foreach (config('setup-wizard.user.fields') as $name => $field) {
            $fields[$name] = ['label' => $field['label'], 'type' => $field['type'] ?? 'text', 'default' => $field['default'] ?? ''];

            if (in_array('confirmed', $field['rules'] ?? [], true)) {
                $fields[$name.'_confirmation'] = ['label' => 'Confirm '.strtolower($field['label']), 'type' => $field['type'] ?? 'text'];
            }
        }

        return $fields;
    }

    public function rules(): array
    {
        return collect(config('setup-wizard.user.fields'))->map(fn ($field) => $field['rules'] ?? [])->all();
    }

    public function action(): string
    {
        return 'Create admin and finish';
    }

    public function handle(array $data): void
    {
        app(config('setup-wizard.user.creator'))->create($data);
    }
}
