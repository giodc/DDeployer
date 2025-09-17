<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class Database extends Model
{
    use HasFactory;

    protected $fillable = [
        'site_id',
        'name',
        'username',
        'password',
        'host',
        'port',
        'charset',
        'collation',
        'size_mb',
        'status',
    ];

    const STATUS_ACTIVE = 'active';
    const STATUS_CREATING = 'creating';
    const STATUS_ERROR = 'error';

    public function site(): BelongsTo
    {
        return $this->belongsTo(Site::class);
    }

    public static function getStatuses(): array
    {
        return [
            self::STATUS_ACTIVE => 'Active',
            self::STATUS_CREATING => 'Creating',
            self::STATUS_ERROR => 'Error',
        ];
    }

    public function isActive(): bool
    {
        return $this->status === self::STATUS_ACTIVE;
    }
}
