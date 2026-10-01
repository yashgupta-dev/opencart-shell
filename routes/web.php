<?php

use Illuminate\Support\Facades\Route;
use CodeCorner\SetupWizard\Http\Controllers\SetupController;

Route::get('/', [SetupController::class, 'show'])->name('show');
Route::get('/{step}', [SetupController::class, 'show']);
Route::post('/{step}', [SetupController::class, 'store'])->name('store');
