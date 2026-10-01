<?php

namespace CodeCorner\SetupWizard;

use Illuminate\Encryption\Encrypter;

class EnvWriter
{
    public function path(): string
    {
        return base_path('.env');
    }

    public function ensureBasics(): void
    {
        if (! is_file($this->path())) {
            $example = base_path('.env.example');
            is_file($example) ? copy($example, $this->path()) : file_put_contents($this->path(), '');
        }

        if (blank(config('app.key'))) {
            $key = 'base64:'.base64_encode(Encrypter::generateKey(config('app.cipher')));
            $this->set(['APP_KEY' => $key]);
            config(['app.key' => $key]);
        }
    }

    public function set(array $values): void
    {
        $env = is_file($this->path()) ? file_get_contents($this->path()) : '';

        foreach ($values as $key => $value) {
            if (preg_match('/[\r\n\0]/', (string) $value)) {
                throw new \InvalidArgumentException("The value for {$key} cannot contain line breaks.");
            }

            $line = $key.'='.$this->format((string) $value);
            $pattern = '/^'.preg_quote($key, '/').'=.*$/m';

            $env = preg_match($pattern, $env)
                ? preg_replace_callback($pattern, fn () => $line, $env)
                : rtrim($env, "\n")."\n".$line."\n";
        }

        file_put_contents($this->path(), $env);
    }

    protected function format(string $value): string
    {
        return preg_match('/[\s#"\'\\\\$]/', $value) ? '"'.addcslashes($value, '"\\$').'"' : $value;
    }
}
