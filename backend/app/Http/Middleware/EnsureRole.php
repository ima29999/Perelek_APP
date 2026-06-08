<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;

class EnsureRole
{
    public function handle(Request $request, Closure $next, string $roles)
    {
        $user = $request->user();

        if (! $user || ! $user->is_active) {
            return response()->json(["message" => "Akses ditolak."], 403);
        }

        $allowedRoles = explode('|', $roles);

        if (! in_array($user->role, $allowedRoles, true)) {
            return response()->json(["message" => "Role tidak memiliki izin untuk mengakses resource ini."], 403);
        }

        return $next($request);
    }
}
