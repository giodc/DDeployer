<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('databases', function (Blueprint $table) {
            $table->id();
            $table->foreignId('site_id')->constrained()->onDelete('cascade');
            $table->string('name');
            $table->string('username');
            $table->string('password');
            $table->string('host')->default('localhost');
            $table->integer('port')->default(3306);
            $table->string('charset')->default('utf8mb4');
            $table->string('collation')->default('utf8mb4_unicode_ci');
            $table->decimal('size_mb', 10, 2)->nullable();
            $table->enum('status', ['active', 'creating', 'error'])->default('creating');
            $table->timestamps();
            
            $table->index(['site_id']);
            $table->index(['status']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('databases');
    }
};
