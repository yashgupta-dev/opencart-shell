<?php

namespace CodeCorner\SetupWizard;

use Illuminate\Support\Arr;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Schema;
use CodeCorner\SetupWizard\Contracts\AdminCreator;

class DefaultAdminCreator implements AdminCreator
{
    public function create(array $data): mixed
    {
        $config = config('setup-wizard.user');
        $class = $config['model'];
        $model = new $class;
        $unique = $config['unique_by'];

        unset($data['password_confirmation']);

        // Laravel 11+ models hash via the "hashed" cast; older ones need it done here.
        if (isset($data['password']) && ($model->getCasts()['password'] ?? null) !== 'hashed') {
            $data['password'] = Hash::make($data['password']);
        }

        $attributes = array_merge($data, $config['attributes']);

        if ($config['verify_email'] && Schema::hasColumn($model->getTable(), 'email_verified_at')) {
            $attributes['email_verified_at'] = now();
        }

        $user = $class::query()->firstOrNew([$unique => $attributes[$unique]]);
        if ($user->exists && ! ($config['update_existing'] ?? false)) {
            throw new \RuntimeException("A user with this {$unique} already exists. Use a different {$unique}, or set user.update_existing to true.");
        }

        $user->forceFill(Arr::except($attributes, [$unique]))->save();

        return $user;
    }
}
