<?php

namespace App\Http\Controllers\API;

use App\Http\Controllers\API\BaseController as BaseController;
use App\Models\User;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Facades\Auth;
use Illuminate\Http\Request;
use PHPOpenSourceSaver\JWTAuth\Facades\JWTAuth;


class AuthController extends BaseController
{
    /*
    *
    * Register
    */

    public function register(Request $request)
    {

        $validator = Validator::make($request->all(), [
            'name' => 'required',
            'email' => 'required|email|unique:users',
            'password' => 'required',
            'c_password' => 'required|same:password',
        ]);

        if ($validator->fails()) {
            return $this->sendError('Validation Error.', $validator->errors());
        }

        $data = $request->all();
        $data['password'] = bcrypt($data['password']);
        $user = User::create($data);
        $success['user'] =  $user;

        return $this->sendResponse($success, 'Utilisateur enregistré avec succès.');
    }

    public function login()
    {

        $infos = request(['email', 'password']);

        if (!$token = Auth::guard('api')->attempt($infos)) {

            return $this->sendError('Unauthorised.', ['error' => 'Non autorisé, Veuillez vérifier vos identifiants ou vous enregistrer.']);
        }

        $success = $this->respondWithToken($token);

        return $this->sendResponse($success, 'Utilisateur connecté avec succès.');
    }

    public function profile()
    {

        $userId = Auth::guard('api')->id();
        $user = User::find($userId);

        return $this->sendResponse($user, 'Le token actualise a été renvoyé avec succès.');
    }

    public function updateProfile(Request $request)
    {
        $userId = Auth::guard('api')->id();
        $user = User::findOrFail($userId);

        $validator = Validator::make($request->all(), [
            'name' => 'sometimes|required|string|max:255',
            'email' => 'sometimes|required|email|unique:users,email,' . $user->id,
            'password' => 'sometimes|nullable|min:6|confirmed',
        ]);

        if ($validator->fails()) {
            return $this->sendError('Validation Error.', $validator->errors(), 422);
        }

        $data = $validator->validated();
        if (array_key_exists('password', $data) && $data['password']) {
            $data['password'] = bcrypt($data['password']);
        } else {
            unset($data['password']);
        }

        $user->update($data);

        return $this->sendResponse($user->fresh(), 'Profil mis à jour avec succès.');
    }

    public function logout()
    {
        Auth::guard('api')->logout();

        return $this->sendResponse([], 'Déconnection reussie.');
    }

    /**
     * Refresh a token.
     *
     * @return \Illuminate\Http\JsonResponse
     */
    public function refresh()
    {
        $success = $this->respondWithToken(JWTAuth::refresh(JWTAuth::getToken()));

        return $this->sendResponse($success, 'Raffraichissement du token reussi.');
    }

    /**
     * Get the token array structure.
     *
     * @param  string $token
     *
     * @return \Illuminate\Http\JsonResponse
     */
    protected function respondWithToken($token)
    {
        return [
            'access_token' => $token,
            'token_type' => 'bearer',
            'expires_in' => config('jwt.ttl') * 60
        ];
    }
}
