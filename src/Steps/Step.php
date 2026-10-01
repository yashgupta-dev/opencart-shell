<?php

namespace CodeCorner\SetupWizard\Steps;

/**
 * Extend this to add your own wizard step, then list the class in config('setup-wizard.steps').
 * Throw an exception from handle() to show its message to the user and stay on the step.
 */
abstract class Step
{
    abstract public function key(): string;

    abstract public function title(): string;

    abstract public function handle(array $data): void;

    public function description(): string
    {
        return '';
    }

    /** @return array<string, array{label: string, type?: string, default?: mixed, options?: array, help?: string}> */
    public function fields(): array
    {
        return [];
    }

    public function rules(): array
    {
        return [];
    }

    /** @return array<int, array{label: string, ok: bool, hint: string}> */
    public function checks(): array
    {
        return [];
    }

    public function canContinue(): bool
    {
        return collect($this->checks())->every(fn ($check) => $check['ok']);
    }

    public function action(): string
    {
        return 'Continue';
    }
}
