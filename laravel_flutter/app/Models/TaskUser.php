<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class TaskUser extends Model
{
    protected $fillable = [
        'user_id',
        'tache_id',
    ];

    public function user()
    {
        return $this->belongsTo(User::class);
    }

    public function tache()
    {
        return $this->belongsTo(Tache::class);
    }
}
