<?php

namespace CodeCorner\SetupWizard\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use CodeCorner\SetupWizard\SetupManager;

class RedirectToSetup
{
    public function __construct(protected SetupManager $setup) {}

    public function handle(Request $request, Closure $next)
    {
        $path = trim(config('setup-wizard.path'), '/');
        $onWizard = $request->is($path, $path.'/*');

        // Clients that are not allowed never see the wizard and are never redirected to it.
        if (! $this->setup->allowsRequest($request)) {
            abort_if($onWizard, 403, 'The setup wizard is only available from localhost.');

            return $next($request);
        }

        if ($onWizard) {
            return $next($request);
        }

        if ($request->expectsJson()) {
            return response()->json(['message' => 'Application setup is not complete.'], 503);
        }

        return redirect('/'.$path);
    }
}
