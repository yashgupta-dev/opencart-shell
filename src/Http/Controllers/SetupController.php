<?php

namespace CodeCorner\SetupWizard\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Routing\Controller;
use Illuminate\Support\Str;
use Throwable;
use CodeCorner\SetupWizard\SetupManager;

class SetupController extends Controller
{
    public function __construct(protected SetupManager $setup) {}

    protected function page(array $data)
    {
        return response()->view('setup-wizard::wizard', $data)->withHeaders([
            'X-Frame-Options' => 'DENY',
            'Cache-Control' => 'no-store',
            'Referrer-Policy' => 'no-referrer',
        ]);
    }

    public function completed()
    {
        return redirect(config('setup-wizard.redirect_after'));
    }

    public function show(?string $step = null)
    {
        $steps = $this->setup->steps();
        $done = session('setup.done', []);
        $first = collect(array_keys($steps))->first(fn ($key) => ! in_array($key, $done)) ?? array_key_last($steps);
        $key = $step && isset($steps[$step]) && ($step === $first || in_array($step, $done)) ? $step : $first;

        return $this->page(['steps' => $steps, 'current' => $steps[$key], 'done' => $done]);
    }

    public function store(Request $request, string $step)
    {
        $steps = $this->setup->steps();
        abort_unless(isset($steps[$step]), 404);
        $current = $steps[$step];

        if (! $current->canContinue()) {
            return back()->withErrors(['setup' => 'Fix the items marked below, then try again.']);
        }

        $data = $request->validate($current->rules());

        $this->setup->stage([]); // marks the wizard as in progress

        try {
            $current->handle($data);
        } catch (Throwable $e) {
            return back()->withInput($request->except('password', 'password_confirmation'))
                ->withErrors(['setup' => Str::limit($e->getMessage(), 600)]);
        }

        session()->put('setup.done', array_values(array_unique([...session('setup.done', []), $step])));

        if ($step === array_key_last($steps)) {
            $this->setup->markCompleted();
            app()->terminating(fn () => $this->setup->commitStaged());

            return $this->page([
                'steps' => $steps, 'current' => $current, 'done' => array_keys($steps),
                'finished' => true, 'url' => config('setup-wizard.redirect_after'),
            ]);
        }

        return redirect()->route('setup-wizard.show');
    }
}
