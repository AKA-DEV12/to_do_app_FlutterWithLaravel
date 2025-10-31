<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;

use App\Http\Controllers\API\AuthController;
use App\Http\Controllers\Api\CategorieController as CategoriesController;
use App\Http\Controllers\Api\TachesController;
use App\Http\Controllers\Api\UsersController;

Route::get('/user', function (Request $request) {
    return $request->user();
})->middleware('auth:sanctum');

Route::group(['prefix' => 'auth', 'middleware' => 'api'], function ($router) {

    Route::post('enregistrement', [AuthController::class, 'register']);
    Route::post('login', [AuthController::class, 'login']);
    Route::post('logout', [AuthController::class, 'logout'])->middleware('auth:api');
    Route::post('refresh', [AuthController::class, 'refresh'])->middleware('auth:api');
    Route::get('profile', [AuthController::class, 'profile'])->middleware('auth:api');
    Route::put('profile', [AuthController::class, 'updateProfile'])->middleware('auth:api');
});

Route::group(['prefix' => 'auth', 'middleware' => ['api', 'auth:api']], function () {
    Route::apiResource('categories', CategoriesController::class);
    Route::apiResource('taches', TachesController::class);
    Route::post('taches/{id}/share', [TachesController::class, 'share']);
    Route::get('users', [UsersController::class, 'index']);
});
