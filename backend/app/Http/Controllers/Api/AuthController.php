<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Password;
use Illuminate\Support\Facades\Validator;
use Illuminate\Validation\ValidationException;

class AuthController extends Controller
{
    // -------------------------------------------------------------------------
    // POST /api/auth/login
    // -------------------------------------------------------------------------
    public function login(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'email'    => 'required|email',
            'password' => 'required|string|min:6',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Validasi gagal.',
                'errors'  => $validator->errors(),
            ], 422);
        }

        $user = User::where('email', $request->email)->first();

        if (!$user || !Hash::check($request->password, $user->password)) {
            return response()->json([
                'success' => false,
                'message' => 'Email atau password salah.',
            ], 401);
        }

        if (!$user->is_active) {
            return response()->json([
                'success' => false,
                'message' => 'Akun Anda telah dinonaktifkan. Hubungi administrator.',
            ], 403);
        }

        // Hapus token lama
        $user->tokens()->delete();

        $tokenName = $user->role === 'admin' ? 'admin-token' : 'user-token';
        $token     = $user->createToken($tokenName)->plainTextToken;

        return response()->json([
            'success' => true,
            'message' => 'Login berhasil.',
            'data'    => [
                'token' => $token,
                'user'  => $this->userResource($user),
            ],
        ]);
    }

    // -------------------------------------------------------------------------
    // POST /api/auth/logout
    // -------------------------------------------------------------------------
    public function logout(Request $request)
    {
        $request->user()->currentAccessToken()->delete();

        return response()->json([
            'success' => true,
            'message' => 'Logout berhasil.',
        ]);
    }

    // -------------------------------------------------------------------------
    // POST /api/auth/refresh
    // -------------------------------------------------------------------------
    public function refresh(Request $request)
    {
        $user = $request->user();
        $user->tokens()->delete();

        $tokenName = $user->role === 'admin' ? 'admin-token' : 'user-token';
        $token     = $user->createToken($tokenName)->plainTextToken;

        return response()->json([
            'success' => true,
            'message' => 'Token diperbarui.',
            'data'    => [
                'token' => $token,
                'user'  => $this->userResource($user),
            ],
        ]);
    }

    // -------------------------------------------------------------------------
    // GET /api/auth/me
    // -------------------------------------------------------------------------
    public function me(Request $request)
    {
        return response()->json([
            'success' => true,
            'data'    => $this->userResource($request->user()),
        ]);
    }

    // -------------------------------------------------------------------------
    // POST /api/auth/forgot-password
    // -------------------------------------------------------------------------
    public function forgotPassword(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'email' => 'required|email|exists:users,email',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Email tidak ditemukan.',
                'errors'  => $validator->errors(),
            ], 422);
        }

        $status = Password::sendResetLink($request->only('email'));

        return response()->json([
            'success' => $status === Password::RESET_LINK_SENT,
            'message' => $status === Password::RESET_LINK_SENT
                ? 'Link reset password telah dikirim ke email Anda.'
                : 'Gagal mengirim link reset password.',
        ]);
    }

    // -------------------------------------------------------------------------
    // POST /api/auth/reset-password
    // -------------------------------------------------------------------------
    public function resetPassword(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'token'    => 'required',
            'email'    => 'required|email',
            'password' => 'required|min:8|confirmed',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Validasi gagal.',
                'errors'  => $validator->errors(),
            ], 422);
        }

        $status = Password::reset(
            $request->only('email', 'password', 'password_confirmation', 'token'),
            function (User $user, string $password) {
                $user->forceFill(['password' => Hash::make($password)])->save();
                $user->tokens()->delete();
            }
        );

        return response()->json([
            'success' => $status === Password::PASSWORD_RESET,
            'message' => $status === Password::PASSWORD_RESET
                ? 'Password berhasil direset. Silakan login.'
                : 'Token tidak valid atau sudah kedaluwarsa.',
        ], $status === Password::PASSWORD_RESET ? 200 : 400);
    }

    // -------------------------------------------------------------------------
    // Helper
    // -------------------------------------------------------------------------
    private function userResource(User $user): array
    {
        return [
            'id'            => $user->id,
            'name'          => $user->name,
            'email'         => $user->email,
            'role'          => $user->role,
            'nik'           => $user->nik,
            'phone'         => $user->phone,
            'address'       => $user->address,
            'rt_rw'         => $user->rt_rw,
            'profile_photo' => $user->profile_photo
                ? asset('storage/profile_photos/' . $user->profile_photo)
                : null,
            'is_active'     => $user->is_active,
        ];
    }
}
