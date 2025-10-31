<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\Tache;
use App\Models\User;
use Illuminate\Support\Facades\Auth;

class TachesController extends Controller
{
    public function index()
    {
        $userId = Auth::guard('api')->id();
        $taches = Tache::with(['category', 'owner'])
            ->where('owner_id', $userId)
            ->orWhereHas('sharedUsers', function ($q) use ($userId) {
                $q->where('users.id', $userId);
            })
            ->get();

        return response()->json($taches);
    }

    public function store(Request $request)
    {
        // Normalize common Flutter/web payload keys to backend expectations
        if ($request->has('categoryId')) {
            $request->merge(['category_id' => (int) $request->input('categoryId')]);
        }
        if ($request->has('status')) {
            $request->merge(['etat' => $request->input('status')]);
        }
        if ($request->has('dueDate')) {
            $request->merge(['date' => $request->input('dueDate')]);
        }

        $validated = $request->validate([
            'title' => 'required|string|max:255',
            'description' => 'nullable|string',
            'date' => 'required|date',
            'category_id' => 'required|exists:categories,id',
            // Default is set in DB; allow omission
            'etat' => 'sometimes|string|max:50',
        ]);

        $tache = Tache::create(array_merge($validated, [
            'owner_id' => Auth::guard('api')->id(),
        ]));
        return response()->json($tache, 201);
    }

    public function show($id)
    {
        $tache = Tache::with(['category', 'owner', 'sharedUsers'])->findOrFail($id);
        $userId = Auth::guard('api')->id();
        // Autoriser la consultation si owner ou partagé avec l'utilisateur
        if ($tache->owner_id !== $userId && !$tache->sharedUsers->contains('id', $userId)) {
            return response()->json(['message' => 'Non autorisé'], 403);
        }
        return response()->json($tache);
    }

    public function update(Request $request, $id)
    {
        $tache = Tache::findOrFail($id);
        if ($tache->owner_id !== Auth::guard('api')->id()) {
            return response()->json(['message' => 'Seul le propriétaire peut modifier cette tâche'], 403);
        }

        // Normalize common Flutter/web payload keys to backend expectations
        if ($request->has('categoryId')) {
            $request->merge(['category_id' => (int) $request->input('categoryId')]);
        }
        if ($request->has('status')) {
            $request->merge(['etat' => $request->input('status')]);
        }
        if ($request->has('dueDate')) {
            $request->merge(['date' => $request->input('dueDate')]);
        }

        $validated = $request->validate([
            'title' => 'required|string|max:255',
            'description' => 'nullable|string',
            'date' => 'required|date',
            'category_id' => 'required|exists:categories,id',
            'etat' => 'sometimes|string|max:50',
        ]);

        $tache->update($validated);

        return response()->json($tache);
    }

    public function destroy($id)
    {
        $tache = Tache::findOrFail($id);
        if ($tache->owner_id !== Auth::guard('api')->id()) {
            return response()->json(['message' => 'Seul le propriétaire peut supprimer cette tâche'], 403);
        }
        $tache->delete();

        return response()->json(['message' => 'Tâche supprimée avec succès.']);
    }

    public function share(Request $request, $id)
    {
        $tache = Tache::with('sharedUsers')->findOrFail($id);
        if ($tache->owner_id !== Auth::guard('api')->id()) {
            return response()->json(['message' => 'Seul le propriétaire peut partager cette tâche'], 403);
        }

        $validated = $request->validate([
            'email' => 'sometimes|email|exists:users,email',
            'user_id' => 'sometimes|exists:users,id',
            'user_ids' => 'sometimes|array',
            'user_ids.*' => 'integer|exists:users,id',
        ]);

        $ids = collect();
        if (isset($validated['user_ids'])) {
            $ids = collect($validated['user_ids']);
        } elseif (isset($validated['user_id'])) {
            $ids = collect([$validated['user_id']]);
        } elseif (isset($validated['email'])) {
            $user = User::where('email', $validated['email'])->first();
            if ($user) {
                $ids = collect([$user->id]);
            }
        }

        $ids = $ids->unique()->reject(function ($uid) {
            return $uid === Auth::guard('api')->id();
        });

        if ($ids->isEmpty()) {
            return response()->json(['message' => 'Aucun utilisateur valide pour le partage'], 422);
        }

        $already = $tache->sharedUsers()->pluck('users.id')->toArray();
        $toAttach = $ids->diff($already)->values()->all();
        if (!empty($toAttach)) {
            $tache->sharedUsers()->attach($toAttach);
        }

        return response()->json([
            'message' => 'Tâche partagée avec succès.',
            'tache' => $tache->load(['sharedUsers:id,name,email'])
        ]);
    }
}
