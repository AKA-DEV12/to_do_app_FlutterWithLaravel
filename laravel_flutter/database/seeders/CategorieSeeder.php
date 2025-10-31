<?php

namespace Database\Seeders;

use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;
use App\Models\Categorie;

class CategorieSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        $categories = [
            ['name' => 'Programmation'],
            ['name' => 'Lecture'],
            ['name' => 'Sport'],
            ['name' => 'Gaming'],
        ];

        foreach ($categories as $category) {
            Categorie::create($category);
        }
    }
}
