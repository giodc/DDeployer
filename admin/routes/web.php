<?php

use App\Http\Controllers\DashboardController;
use App\Http\Controllers\SiteController;
use Illuminate\Support\Facades\Route;

/*
|--------------------------------------------------------------------------
| Web Routes
|--------------------------------------------------------------------------
*/

// Redirect root to dashboard
Route::get('/', function () {
    return redirect('/dashboard');
});

// Authentication routes
Auth::routes(['register' => false]); // Disable registration

// Protected routes
Route::middleware(['auth'])->group(function () {
    // Dashboard
    Route::get('/dashboard', [DashboardController::class, 'index'])->name('dashboard');
    
    // Sites management
    Route::resource('sites', SiteController::class);
    
    // Site actions
    Route::post('/sites/{site}/start', [SiteController::class, 'start'])->name('sites.start');
    Route::post('/sites/{site}/stop', [SiteController::class, 'stop'])->name('sites.stop');
    Route::get('/sites/{site}/logs', [SiteController::class, 'logs'])->name('sites.logs');
    
    // API routes for AJAX calls
    Route::prefix('api')->group(function () {
        Route::get('/sites/{site}/status', function (App\Models\Site $site) {
            $dockerService = app(App\Services\DockerService::class);
            return response()->json($dockerService->getSiteStatus($site));
        })->name('api.sites.status');
        
        Route::get('/system/info', function () {
            $controller = new DashboardController();
            $reflection = new ReflectionClass($controller);
            $method = $reflection->getMethod('getSystemInfo');
            $method->setAccessible(true);
            return response()->json($method->invoke($controller));
        })->name('api.system.info');
    });
});
