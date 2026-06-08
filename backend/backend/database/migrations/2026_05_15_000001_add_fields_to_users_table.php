<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->string('role')->default('user')->after('password');
            $table->string('nik')->nullable()->after('role');
            $table->string('phone')->nullable()->unique()->after('nik');
            $table->string('address')->nullable()->after('phone');
            $table->string('rt_rw')->nullable()->after('address');
            $table->string('ktp_photo')->nullable()->after('rt_rw');
            $table->string('profile_photo')->nullable()->after('ktp_photo');
            $table->boolean('is_active')->default(true)->after('profile_photo');
            $table->softDeletes();
        });
    }

    public function down(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->dropSoftDeletes();
            $table->dropColumn(['role', 'nik', 'phone', 'address', 'rt_rw', 'ktp_photo', 'profile_photo', 'is_active']);
        });
    }
};
