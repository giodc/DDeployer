<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\SoftDeletes;

class Site extends Model
{
    use HasFactory, SoftDeletes;

    protected $fillable = [
        'name',
        'type',
        'domains',
        'status',
        'container_name',
        'database_name',
        'database_user',
        'database_password',
        'ssl_enabled',
        'cache_enabled',
        'php_version',
        'config',
        'created_by',
    ];

    protected $casts = [
        'domains' => 'array',
        'config' => 'array',
        'ssl_enabled' => 'boolean',
        'cache_enabled' => 'boolean',
    ];

    const TYPE_WORDPRESS = 'wordpress';
    const TYPE_LARAVEL = 'laravel';
    const TYPE_PHP = 'php';

    const STATUS_CREATING = 'creating';
    const STATUS_RUNNING = 'running';
    const STATUS_STOPPED = 'stopped';
    const STATUS_ERROR = 'error';

    public static function getTypes(): array
    {
        return [
            self::TYPE_WORDPRESS => 'WordPress',
            self::TYPE_LARAVEL => 'Laravel',
            self::TYPE_PHP => 'PHP',
        ];
    }

    public static function getStatuses(): array
    {
        return [
            self::STATUS_CREATING => 'Creating',
            self::STATUS_RUNNING => 'Running',
            self::STATUS_STOPPED => 'Stopped',
            self::STATUS_ERROR => 'Error',
        ];
    }

    public function deployments(): HasMany
    {
        return $this->hasMany(Deployment::class);
    }

    public function databases(): HasMany
    {
        return $this->hasMany(Database::class);
    }

    public function getPrimaryDomainAttribute(): ?string
    {
        return $this->domains[0] ?? null;
    }

    public function getContainerNameAttribute(): string
    {
        return "site-{$this->id}-" . str_replace(['.', '_'], '-', $this->name);
    }

    public function getDatabaseNameAttribute(): string
    {
        return "site_{$this->id}_" . str_replace(['.', '-'], '_', $this->name);
    }

    public function isRunning(): bool
    {
        return $this->status === self::STATUS_RUNNING;
    }

    public function isStopped(): bool
    {
        return $this->status === self::STATUS_STOPPED;
    }

    public function hasError(): bool
    {
        return $this->status === self::STATUS_ERROR;
    }
}
