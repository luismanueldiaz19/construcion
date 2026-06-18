<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Http\Request;

class UserController extends Controller
{
    /**
     * Display a listing of the resource.
     */
    public function index()
    {
        $users = User::orderBy('id', 'desc')->get();
        return response()->json($users);
    }

    /**
     * Remove the specified resource from storage.
     */
    public function destroy($id)
    {
        $user = User::findOrFail($id);

        // Prevenir la eliminación del usuario administrador principal
        if ($user->username === 'ludeveloper') {
            return response()->json(['message' => 'No se puede eliminar al usuario administrador.'], 403);
        }

        $user->delete();
        return response()->json(['message' => 'Usuario eliminado correctamente.']);
    }
}
