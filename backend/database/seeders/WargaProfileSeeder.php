<?php

namespace Database\Seeders;

use App\Models\User;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;

/**
 * WargaProfileSeeder
 *
 * Melengkapi data profil user warga yang sudah ada (dibuat oleh DemoDataSeeder)
 * dengan NIK dan nomor HP yang konsisten dan realistis.
 *
 * CATATAN: Seeder ini TIDAK mengubah tabel/migration. Hanya mengisi kolom
 * yang sudah ada (nik, phone, rt_rw, address) dengan data yang masuk akal.
 */
class WargaProfileSeeder extends Seeder
{
    public function run(): void
    {
        // Data profil lengkap per email (sesuai DemoDataSeeder)
        $profiles = [
            'naufalrzq@gmail.com'  => ['nik' => '3204211012980001', 'phone' => '081312345601', 'rt_rw' => 'RT 01/RW 05', 'address' => 'Jl. Mawar No. 12'],
            'keyshaaurl@gmail.com' => ['nik' => '3204214506020002', 'phone' => '081312345602', 'rt_rw' => 'RT 01/RW 05', 'address' => 'Jl. Mawar No. 14'],
            'dimss.adit@gmail.com' => ['nik' => '3204071503950003', 'phone' => '081312345603', 'rt_rw' => 'RT 01/RW 05', 'address' => 'Jl. Melati No. 3'],
            'mnd.putri@gmail.com'  => ['nik' => '3204494808000004', 'phone' => '081312345604', 'rt_rw' => 'RT 01/RW 05', 'address' => 'Jl. Melati No. 5'],
            'faizibrhm@gmail.com'  => ['nik' => '3204120997000005', 'phone' => '081312345605', 'rt_rw' => 'RT 01/RW 05', 'address' => 'Jl. Anggrek No. 8'],
            'syifasalsa@gmail.com' => ['nik' => '3204475007010006', 'phone' => '081312345606', 'rt_rw' => 'RT 01/RW 05', 'address' => 'Jl. Anggrek No. 10'],
            'bintangrmd@gmail.com' => ['nik' => '3204180199600007', 'phone' => '081312345607', 'rt_rw' => 'RT 01/RW 05', 'address' => 'Jl. Dahlia No. 2'],
            'naylahptri@gmail.com' => ['nik' => '3204464805030008', 'phone' => '081312345608', 'rt_rw' => 'RT 01/RW 05', 'address' => 'Jl. Dahlia No. 4'],
            'rianhdayat@gmail.com' => ['nik' => '3204130892000009', 'phone' => '081312345609', 'rt_rw' => 'RT 01/RW 05', 'address' => 'Jl. Mawar No. 15'],
            'sitiaminah@gmail.com' => ['nik' => '3204476710800010', 'phone' => '081312345610', 'rt_rw' => 'RT 01/RW 05', 'address' => 'Jl. Melati No. 7'],
            'arifrahman@gmail.com' => ['nik' => '3204250988000011', 'phone' => '081312345611', 'rt_rw' => 'RT 01/RW 05', 'address' => 'Jl. Anggrek No. 12'],
            'dewilestri@gmail.com' => ['nik' => '3204445511910012', 'phone' => '081312345612', 'rt_rw' => 'RT 01/RW 05', 'address' => 'Jl. Dahlia No. 6'],
            'ekopras@gmail.com'    => ['nik' => '3204030690000013', 'phone' => '081312345613', 'rt_rw' => 'RT 01/RW 05', 'address' => 'Jl. Mawar No. 18'],
            'fitrilest@gmail.com'  => ['nik' => '3204475506940014', 'phone' => '081312345614', 'rt_rw' => 'RT 01/RW 05', 'address' => 'Jl. Melati No. 9'],
            'gilangperm@gmail.com' => ['nik' => '3204220995000015', 'phone' => '081312345615', 'rt_rw' => 'RT 01/RW 05', 'address' => 'Jl. Anggrek No. 15'],
            'hendrawjy@gmail.com'  => ['nik' => '3204050888000016', 'phone' => '081312345616', 'rt_rw' => 'RT 01/RW 05', 'address' => 'Jl. Dahlia No. 8'],
        ];

        $updated = 0;
        foreach ($profiles as $email => $data) {
            $user = User::where('email', $email)->first();
            if (!$user) continue;

            // Hanya update jika kolom belum terisi
            $needsUpdate = empty($user->getRawOriginal('nik')) || empty($user->getRawOriginal('phone'));

            if ($needsUpdate) {
                // Bypass mutator enkripsi dengan update langsung agar tidak double encrypt
                User::where('email', $email)->update([
                    'rt_rw'   => $data['rt_rw'],
                    'address' => $data['address'],
                ]);

                // Gunakan model untuk set nik & phone agar enkripsi berjalan benar
                $user->nik   = $data['nik'];
                $user->phone = $data['phone'];
                $user->save();

                $updated++;
            }
        }

        $this->command->info("WargaProfileSeeder selesai: {$updated} profil warga dilengkapi.");
    }
}
