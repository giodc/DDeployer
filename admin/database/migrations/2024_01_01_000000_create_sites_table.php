<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('sites', function (Blueprint $table) {
            $table->id();
            $table->string('name');
            $table->enum('type', ['wordpress', 'laravel', 'php']);
            $table->json('domains');
            $table->enum('status', ['creating', 'running', 'stopped', 'error'])->default('creating');
            $table->string('container_name')->unique();
            $table->string('database_name')->nullable();
            $table->string('database_user')->nullable();
            $table->string('database_password')->nullable();
            $table->boolean('ssl_enabled')->default(false);
            $table->boolean('cache_enabled')->default(true);
            $table->string('php_version')->default('8.3');
            $table->json('config')->nullable();
            $table->unsignedBigInteger('created_by')->nullable();
            $table->timestamps();
            $table->softDeletes();
            
            $table->index(['status']);
            $table->index(['type']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('sites');
    }
};
