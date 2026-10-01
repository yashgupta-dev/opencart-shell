<?php

namespace CodeCorner\SetupWizard;

use Illuminate\Console\Events\CommandStarting;
use Illuminate\Contracts\Http\Kernel;
use Illuminate\Support\Facades\Artisan;
use Illuminate\Support\Facades\Event;
use Illuminate\Support\Facades\Route;
use Illuminate\Support\ServiceProvider;
use CodeCorner\SetupWizard\Http\Controllers\SetupController;
use CodeCorner\SetupWizard\Http\Middleware\RedirectToSetup;

class SetupWizardServiceProvider extends ServiceProvider
{
    public function register(): void
    {
        $this->mergeConfigFrom(__DIR__.'/../config/setup-wizard.php', 'setup-wizard');
        $this->app->singleton(SetupManager::class);
    }

    public function boot(): void
    {
        $this->loadViewsFrom(__DIR__.'/../resources/views', 'setup-wizard');
        $this->publishes([__DIR__.'/../config/setup-wizard.php' => config_path('setup-wizard.php')], 'setup-wizard-config');
        $this->publishes([__DIR__.'/../resources/views' => resource_path('views/vendor/setup-wizard')], 'setup-wizard-views');

        $setup = $this->app->make(SetupManager::class);

        if ($this->app->runningInConsole()) {
            Artisan::command('setup:reset', function () use ($setup) {
                $setup->reset();
                $this->info('Setup lock removed. The wizard will run again on the next request.');
            })->purpose('Run the setup wizard again');

            Event::listen(CommandStarting::class, function (CommandStarting $event) use ($setup) {
                if ($event->command === 'serve' && $setup->enabled() && ! $setup->completed()) {
                    $event->output->writeln('<comment>Project is not set up yet. Open /'.config('setup-wizard.path').' in your browser to run the setup wizard.</comment>');
                }
            });

            return;
        }

        if (! $setup->enabled()) {
            return;
        }

        $setup->applyStaged();

        if ($setup->completed()) {
            // Finished: expose nothing but a redirect, so /setup never shows the wizard again.
            Route::get(config('setup-wizard.path').'/{any?}', [SetupController::class, 'completed'])->where('any', '.*');

            return;
        }

        $setup->prepareRuntime();

        Route::middleware('web')
            ->prefix(config('setup-wizard.path'))
            ->as('setup-wizard.')
            ->group(__DIR__.'/../routes/web.php');

        $this->app->make(Kernel::class)->prependMiddleware(RedirectToSetup::class);
    }
}
