<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Facades\Validator;

class UserController extends Controller
{
    // -------------------------------------------------------------------------
    // GET /api/admin/users  - Daftar warga (admin)
    // -------------------------------------------------------------------------
    public function index(Request $request)
    {
        $query = User::where('role', 'user');

        // Search
        if ($search = $request->get('search')) {
            $query->where(function ($q) use ($search) {
                $q->where('name', 'like', "%{$search}%")
                  ->orWhere('email', 'like', "%{$search}%")
                  ->orWhere('address', 'like', "%{$search}%")
                  ->orWhere('rt_rw', 'like', "%{$search}%");
            });
        }

        // Filter status
        if ($request->has('is_active')) {
            $query->where('is_active', (bool) $request->is_active);
        }

        $perPage = $request->get('per_page', 15);
        $users   = $query->orderBy('name')->paginate($perPage);

        return response()->json([
            'success' => true,
            'data'    => $users->through(fn($u) => $this->formatUser($u)),
        ]);
    }

    // -------------------------------------------------------------------------
    // POST /api/admin/users  - Tambah warga baru
    // -------------------------------------------------------------------------
    public function store(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'name'     => 'required|string|max:255',
            'email'    => 'required|email|unique:users,email',
            'password' => 'required|string|min:8',
            'nik'      => 'nullable|string|max:16',
            'phone'    => 'nullable|string|max:20',
            'address'  => 'nullable|string',
            'rt_rw'    => 'nullable|string|max:20',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Validasi gagal.',
                'errors'  => $validator->errors(),
            ], 422);
        }

        $user = User::create([
            'name'     => $request->name,
            'email'    => $request->email,
            'password' => Hash::make($request->password),
            'role'     => 'user',
            'nik'      => $request->nik,
            'phone'    => $request->phone,
            'address'  => $request->address,
            'rt_rw'    => $request->rt_rw,
            'is_active' => true,
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Warga berhasil ditambahkan.',
            'data'    => $this->formatUser($user),
        ], 201);
    }

    // -------------------------------------------------------------------------
    // GET /api/admin/users/{user}
    // -------------------------------------------------------------------------
    public function show(User $user)
    {
        $user->loadCount('payments');
        $user->load(['payments' => fn($q) => $q->latest()->limit(5)->with('invoice')]);

        return response()->json([
            'success' => true,
            'data'    => array_merge($this->formatUser($user), [
                'payments_count'  => $user->payments_count,
                'recent_payments' => $user->payments->map(fn($p) => [
                    'id'           => $p->id,
                    'invoice'      => $p->invoice?->title,
                    'amount'       => $p->amount,
                    'status'       => $p->status,
                    'payment_date' => $p->payment_date?->format('Y-m-d'),
                ]),
            ]),
        ]);
    }

    // -------------------------------------------------------------------------
    // PUT /api/admin/users/{user}
    // -------------------------------------------------------------------------
    public function update(Request $request, User $user)
    {
        $validator = Validator::make($request->all(), [
            'name'    => 'sometimes|string|max:255',
            'email'   => 'sometimes|email|unique:users,email,' . $user->id,
            'nik'     => 'nullable|string|max:16',
            'phone'   => 'nullable|string|max:20',
            'address' => 'nullable|string',
            'rt_rw'   => 'nullable|string|max:20',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Validasi gagal.',
                'errors'  => $validator->errors(),
            ], 422);
        }

        $user->update($request->only('name', 'email', 'nik', 'phone', 'address', 'rt_rw'));

        return response()->json([
            'success' => true,
            'message' => 'Data warga berhasil diperbarui.',
            'data'    => $this->formatUser($user->fresh()),
        ]);
    }

    // -------------------------------------------------------------------------
    // DELETE /api/admin/users/{user}  - Nonaktifkan warga
    // -------------------------------------------------------------------------
    public function destroy(User $user)
    {
        $user->update(['is_active' => false]);
        $user->delete(); // soft delete

        return response()->json([
            'success' => true,
            'message' => 'Warga berhasil dinonaktifkan.',
        ]);
    }

    // -------------------------------------------------------------------------
    // GET /api/profile  - Profil warga sendiri
    // -------------------------------------------------------------------------
    public function profile(Request $request)
    {
        $user = $request->user();
        $user->loadCount('payments');

        return response()->json([
            'success' => true,
            'data'    => $this->formatUser($user),
        ]);
    }

    // -------------------------------------------------------------------------
    // PATCH /api/profile  - Update profil sendiri
    // -------------------------------------------------------------------------
    public function updateProfile(Request $request)
    {
        $user      = $request->user();
        $validator = Validator::make($request->all(), [
            'name'             => 'sometimes|string|max:255',
            'phone'            => 'nullable|string|max:20',
            'address'          => 'nullable|string',
            'rt_rw'            => 'nullable|string|max:20',
            'profile_photo'    => 'nullable|image|mimes:jpg,jpeg,png|max:2048',
            'current_password' => 'required_with:new_password|string',
            'new_password'     => 'nullable|string|min:8|confirmed',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Validasi gagal.',
                'errors'  => $validator->errors(),
            ], 422);
        }

        // Ganti password
        if ($request->filled('new_password')) {
            if (!Hash::check($request->current_password, $user->password)) {
                return response()->json([
                    'success' => false,
                    'message' => 'Password lama tidak sesuai.',
                ], 422);
            }
            $user->password = Hash::make($request->new_password);
        }

        // Upload foto profil
        if ($request->hasFile('profile_photo')) {
            if ($user->profile_photo) {
                Storage::disk('public')->delete('profile_photos/' . $user->profile_photo);
            }
            $filename            = time() . '_' . $user->id . '.' . $request->file('profile_photo')->extension();
            $request->file('profile_photo')->storeAs('profile_photos', $filename, 'public');
            $user->profile_photo = $filename;
        }

        $user->fill($request->only('name', 'phone', 'address', 'rt_rw'));
        $user->save();

        return response()->json([
            'success' => true,
            'message' => 'Profil berhasil diperbarui.',
            'data'    => $this->formatUser($user->fresh()),
        ]);
    }

    // -------------------------------------------------------------------------
    // Helper
    // -------------------------------------------------------------------------
    private function formatUser(User $user): array
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
                ? url('storage/profile_photos/' . $user->profile_photo)
                : null,
            'ktp_photo'     => $user->ktp_photo
                ? url('storage/ktp_photos/' . $user->ktp_photo)
                : null,
            'is_active'     => $user->is_active,
            'created_at'    => $user->created_at?->format('Y-m-d H:i:s'),
        ];
    }
}
