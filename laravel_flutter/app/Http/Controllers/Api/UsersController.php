<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Support\Facades\Auth;

class UsersController extends Controller
{
    public function index()
    {
        $currentId = Auth::guard('api')->id();
        $users = User::query()
            ->when($currentId, fn($q) => $q->where('id', '!=', $currentId))
            ->select(['id', 'name', 'email'])
            ->orderBy('name')
            ->get();
        return response()->json($users);
    }
}
