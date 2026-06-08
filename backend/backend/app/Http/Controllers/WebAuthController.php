<?php

namespace App\Http\Controllers;

use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;

class WebAuthController extends Controller
{
    public function showLoginForm()
    {
        return view('login');
    }

    public function login(Request $request)
    {
        $data = $request->validate([
            'identifier' => 'required|string',
            'password' => 'required|string',
        ]);

        $user = User::where('email', $data['identifier'])
            ->orWhere('phone', $data['identifier'])
            ->first();

        if (! $user || ! Hash::check($data['password'], $user->password) || ! $user->is_active) {
            return redirect()->back()->withInput()->withErrors([
                'identifier' => 'Email/nomor HP atau password salah.',
            ]);
        }

        $token = $user->createToken('web-login-token')->plainTextToken;

        return redirect()->route('login')->with([
            'status' => 'Login berhasil. Token API telah dibuat.',
            'token' => $token,
            'user' => $user,
        ]);
    }
}
