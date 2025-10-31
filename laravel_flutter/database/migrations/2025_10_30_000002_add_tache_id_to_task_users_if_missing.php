<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    public function up(): void
    {
        if (!Schema::hasTable('task_users')) {
            return;
        }

        Schema::table('task_users', function (Blueprint $table) {
            if (!Schema::hasColumn('task_users', 'user_id')) {
                $table->foreignId('user_id')->nullable()->constrained('users')->nullOnDelete();
            }
            if (!Schema::hasColumn('task_users', 'tache_id')) {
                // Ne pas utiliser after('user_id') pour éviter l'erreur si user_id est absent
                $table->foreignId('tache_id')->nullable()->constrained('taches')->cascadeOnDelete();
            }
        });

        // Optionnel: si une ancienne colonne 'task_id' existe, on copie les valeurs
        if (Schema::hasColumn('task_users', 'task_id') && Schema::hasColumn('task_users', 'tache_id')) {
            DB::statement('UPDATE task_users SET tache_id = task_id WHERE tache_id IS NULL');
        }

        // Les foreignId ci-dessus ajoutent déjà les contraintes si possible
    }

    public function down(): void
    {
        // Ne pas supprimer automatiquement pour éviter la perte de données
    }
};
