<?php

namespace App\Helpers;

use App\Models\Notification;
use App\Models\User;

class NotifHelper
{
    // ── Kirim ke SATU user ────────────────────────────────────────────
    public static function send(
        int    $userId,
        string $type,
        string $title,
        string $body,
        array  $data = []
    ): void {
        Notification::create([
            'user_id' => $userId,
            'type'    => $type,
            'title'   => $title,
            'body'    => $body,
            'data'    => $data,
        ]);
    }

    // ── Kirim ke SEMUA warga aktif (broadcast) ────────────────────────
    public static function broadcast(
        string $type,
        string $title,
        string $body,
        array  $data = [],
        bool   $includeAdmin = false
    ): void {
        $query = User::where('is_active', true);

        if (! $includeAdmin) {
            $query->where('role', 'warga');
        }

        $userIds = $query->pluck('id');
        $now     = now();

        $rows = $userIds->map(fn ($id) => [
            'user_id'    => $id,
            'type'       => $type,
            'title'      => $title,
            'body'       => $body,
            'data'       => json_encode($data),
            'read_at'    => null,
            'created_at' => $now,
            'updated_at' => $now,
        ])->toArray();

        // Bulk insert agar efisien meski warga banyak
        collect($rows)->chunk(500)->each(fn ($chunk) =>
            Notification::insert($chunk->toArray())
        );
    }

    // ── Kirim ke ADMIN saja ───────────────────────────────────────────
    public static function notifyAdmins(
        string $type,
        string $title,
        string $body,
        array  $data = []
    ): void {
        $adminIds = User::where('role', 'admin')
            ->where('is_active', true)
            ->pluck('id');

        $now  = now();
        $rows = $adminIds->map(fn ($id) => [
            'user_id'    => $id,
            'type'       => $type,
            'title'      => $title,
            'body'       => $body,
            'data'       => json_encode($data),
            'read_at'    => null,
            'created_at' => $now,
            'updated_at' => $now,
        ])->toArray();

        if (! empty($rows)) {
            Notification::insert($rows);
        }
    }

    // ── Tipe-tipe yang tersedia (konstanta) ────────────────────────────
    const TYPE_PAYMENT      = 'payment';
    const TYPE_INVOICE      = 'invoice';
    const TYPE_ANNOUNCEMENT = 'announcement';
    const TYPE_EVENT        = 'event';
    const TYPE_SYSTEM       = 'system';
}
