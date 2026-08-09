import 'dart:io' show File;
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:http_parser/http_parser.dart';
import '../../core/api/api_client.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/theme_provider.dart';
import '../../core/utils/snackbar_helper.dart';
import '../../core/widgets/common_widgets.dart';
import '../auth/auth_provider.dart';
import '../../features/faq/faq_page.dart';
import '../../features/reports/report_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _rtRwCtrl = TextEditingController();
  final _curPassCtrl = TextEditingController();
  final _newPassCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();

  bool _saving = false;
  bool _obscureCur = true, _obscureNew = true, _obscureConf = true;

  XFile? _photoFile;
  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _prefillFromAuth();
  }

  void _prefillFromAuth() {
    final user = context.read<AuthProvider>().user;
    if (user != null) {
      _nameCtrl.text = user['name'] ?? '';
      _phoneCtrl.text = user['phone'] ?? '';
      _addressCtrl.text = user['address'] ?? '';
      _rtRwCtrl.text = user['rt_rw'] ?? '';
    }
  }

  Future<void> _pickPhoto(StateSetter modalState) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
        decoration: BoxDecoration(
            color: context.colorSurface,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(20))),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: context.colorBorder,
                  borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 20),
          Text('Foto Profil',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: context.colorTextPrimary)),
          const SizedBox(height: 16),
          ListTile(
              leading: const Icon(Icons.camera_alt_rounded,
                  color: AppColors.primary),
              title: Text('Kamera',
                  style: TextStyle(color: context.colorTextPrimary)),
              onTap: () => Navigator.pop(context, ImageSource.camera)),
          ListTile(
              leading: const Icon(Icons.photo_library_rounded,
                  color: AppColors.primary),
              title: Text('Galeri',
                  style: TextStyle(color: context.colorTextPrimary)),
              onTap: () => Navigator.pop(context, ImageSource.gallery)),
        ]),
      ),
    );
    if (source == null) return;

    final picked = await _picker.pickImage(
        source: source, imageQuality: 80, maxWidth: 800);

    if (picked != null) {
      setState(() => _photoFile = picked);
      modalState(() {}); // Memperbarui UI di dalam bottom sheet edit profil
    }
  }

  Future<void> _saveProfile(BuildContext dialogContext) async {
    setState(() => _saving = true);
    try {
      final fields = <String, dynamic>{
        'name': _nameCtrl.text.trim(),
        if (_phoneCtrl.text.isNotEmpty) 'phone': _phoneCtrl.text.trim(),
        if (_addressCtrl.text.isNotEmpty) 'address': _addressCtrl.text.trim(),
        if (_rtRwCtrl.text.isNotEmpty) 'rt_rw': _rtRwCtrl.text.trim(),
      };

      Response res;
      if (_photoFile != null) {
        final bytes = await _photoFile!.readAsBytes();
        String extension = _photoFile!.name.split('.').last.toLowerCase();
        if (extension == 'jpg') extension = 'jpeg';

        final formData = FormData.fromMap({
          '_method': 'PATCH',
          ...fields.map((k, v) => MapEntry(k, v.toString())),
          'profile_photo': MultipartFile.fromBytes(
            bytes,
            filename: _photoFile!.name,
            contentType: MediaType('image', extension),
          ),
        });

        res = await ApiClient().upload('/profile', formData);
      } else {
        res = await ApiClient().patch('/profile', data: fields);
      }

      if (res.data['success'] == true) {
        final currentPhotoUrl =
            context.read<AuthProvider>().user?['profile_photo'];
        if (currentPhotoUrl != null) {
          await NetworkImage(currentPhotoUrl).evict();
        }

        await context.read<AuthProvider>().refreshMe();

        if (mounted) {
          setState(() {
            _photoFile = null;
          });
          Navigator.pop(dialogContext);
          SnackBarHelper.show(context, 'Profil berhasil diperbarui.',
              isSuccess: true);
        }
      } else {
        throw Exception(res.data['message']);
      }
    } catch (e) {
      if (mounted) SnackBarHelper.show(context, 'Gagal: $e', isError: true);
    }
    if (mounted) setState(() => _saving = false);
  }

  Future<void> _changePassword(BuildContext dialogContext) async {
    if (_newPassCtrl.text != _confirmPassCtrl.text) {
      SnackBarHelper.show(context, 'Kata sandi baru tidak cocok.',
          isError: true);
      return;
    }
    if (_newPassCtrl.text.length < 8) {
      SnackBarHelper.show(context, 'Kata sandi min. 8 karakter.',
          isError: true);
      return;
    }
    setState(() => _saving = true);
    try {
      final res = await ApiClient().patch('/profile', data: {
        'current_password': _curPassCtrl.text,
        'new_password': _newPassCtrl.text,
        'new_password_confirmation': _confirmPassCtrl.text,
      });
      if (res.data['success'] == true) {
        _curPassCtrl.clear();
        _newPassCtrl.clear();
        _confirmPassCtrl.clear();
        if (mounted) {
          Navigator.pop(dialogContext);
          SnackBarHelper.show(context, 'Kata sandi berhasil diubah.',
              isSuccess: true);
        }
      } else {
        throw Exception(res.data['message']);
      }
    } catch (e) {
      if (mounted) SnackBarHelper.show(context, 'Gagal: $e', isError: true);
    }
    if (mounted) setState(() => _saving = false);
  }

  ImageProvider? _getProfileImage(Map<String, dynamic>? user) {
    if (_photoFile != null) {
      if (kIsWeb) {
        return NetworkImage(_photoFile!.path);
      } else {
        return FileImage(File(_photoFile!.path));
      }
    }
    if (user?['profile_photo'] != null) {
      return NetworkImage(user!['profile_photo']);
    }
    return null;
  }

  // Dialog Edit Profil & Akun
  void _showEditProfileBottomSheet() {
    _prefillFromAuth();
    showModalBottomSheet(
      context: context,
      isScrollControlled:
          true, // Tetap true agar bottom sheet bisa naik saat keyboard muncul
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            // Pindahkan batasan tinggi maksimum menggunakan ConstrainedBox di sini
            return ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.85,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: context.colorBg,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(24)),
                ),
                padding: EdgeInsets.fromLTRB(
                    16, 12, 16, MediaQuery.of(context).viewInsets.bottom + 80),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                              color: context.colorBorder,
                              borderRadius: BorderRadius.circular(2))),
                      const SizedBox(height: 24),
                      Text('Edit Profil',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: context.colorTextPrimary)),
                      const SizedBox(height: 24),
                      GestureDetector(
                        onTap: () => _pickPhoto(setModalState),
                        child: Stack(children: [
                          CircleAvatar(
                            radius: 50,
                            backgroundColor: AppColors.primary.withOpacity(0.1),
                            backgroundImage: _getProfileImage(
                                    context.watch<AuthProvider>().user) ??
                                const AssetImage(
                                    'assets/images/avatar-profil.png'),
                          ),
                          Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                width: 30,
                                height: 30,
                                decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                        color: Colors.white, width: 2)),
                                child: const Icon(Icons.camera_alt_rounded,
                                    size: 14, color: Colors.white),
                              )),
                        ]),
                      ),
                      const SizedBox(height: 24),
                      _field(_nameCtrl, 'Nama Lengkap', Icons.person_rounded),
                      const SizedBox(height: 14),
                      _field(_phoneCtrl, 'Nomor HP', Icons.phone_rounded,
                          keyboardType: TextInputType.phone),
                      const SizedBox(height: 14),
                      TextField(
                        controller: _addressCtrl,
                        maxLines: 3,
                        decoration: const InputDecoration(
                            labelText: 'Alamat',
                            prefixIcon: Padding(
                                padding: EdgeInsets.only(bottom: 40),
                                child: Icon(Icons.home_rounded, size: 20))),
                      ),
                      const SizedBox(height: 14),
                      _field(_rtRwCtrl, 'RT/RW', Icons.location_on_rounded),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _saving ? null : () => _saveProfile(context),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size.fromHeight(50),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: _saving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2))
                            : const Text('Simpan Perubahan'),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    ).then((_) {
      setState(() => _photoFile = null);
    });
  }

  // Dialog Ubah Password (Keamanan)
  void _showSecurityBottomSheet() {
    _curPassCtrl.clear();
    _newPassCtrl.clear();
    _confirmPassCtrl.clear();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Container(
              decoration: BoxDecoration(
                color: context.colorBg,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: EdgeInsets.fromLTRB(
                  16, 12, 16, MediaQuery.of(context).viewInsets.bottom + 80),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                              color: context.colorBorder,
                              borderRadius: BorderRadius.circular(2))),
                    ),
                    const SizedBox(height: 24),
                    Text('Keamanan',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: context.colorTextPrimary)),
                    const SizedBox(height: 16),
                    _passField(_curPassCtrl, 'Kata Sandi Lama', _obscureCur,
                        () => setModalState(() => _obscureCur = !_obscureCur)),
                    const SizedBox(height: 14),
                    _passField(_newPassCtrl, 'Kata Sandi Baru', _obscureNew,
                        () => setModalState(() => _obscureNew = !_obscureNew)),
                    const SizedBox(height: 14),
                    _passField(
                        _confirmPassCtrl,
                        'Konfirmasi Kata Sandi Baru',
                        _obscureConf,
                        () =>
                            setModalState(() => _obscureConf = !_obscureConf)),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed:
                          _saving ? null : () => _changePassword(context),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(50),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _saving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2))
                          : const Text('Ubah Kata Sandi'),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final isAdmin = context.read<AuthProvider>().isAdmin;
    final themeProvider = context.watch<ThemeProvider>();

    return Scaffold(
      backgroundColor: context.colorBg,
      appBar: AppBar(
        title: const Text('Profil Saya',
            style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: context.colorTextPrimary,
        actions: const [], // Menghapus tombol logout dari AppBar
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Info Profil Singkat
            const SizedBox(height: 16),
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 54,
                    backgroundColor: AppColors.primary.withOpacity(0.1),
                    backgroundImage: _getProfileImage(user) ??
                        const AssetImage('assets/images/avatar-profil.png'),
                  ),
                  const SizedBox(height: 14),
                  Text('${user?['name'] ?? '-'}',
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: context.colorTextPrimary)),
                  const SizedBox(height: 4),
                  Text(
                      isAdmin ? 'Administrator RT' : '${user?['email'] ?? '-'}',
                      style: TextStyle(
                          fontSize: 13, color: context.colorTextSecond)),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Tombol Utama: Edit Profil
            OutlinedButton.icon(
              onPressed: _showEditProfileBottomSheet,
              icon: const Icon(Icons.edit_rounded, size: 18),
              label: const Text('Edit Profil'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                side: BorderSide(color: AppColors.primary.withOpacity(0.5)),
                foregroundColor: AppColors.primary,
              ),
            ),
            const SizedBox(height: 32),

            // Bagian Tampilan (Tema)
            Text('TAMPILAN',
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                    color: context.colorTextHint)),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                child: AppearanceModeCard(
                  label: 'Daylight',
                  subtitle: 'Terang',
                  isDarkPreview: false,
                  selected: !themeProvider.isDark,
                  onTap: () => themeProvider.setDark(false),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AppearanceModeCard(
                  label: 'Midnight',
                  subtitle: 'Gelap',
                  isDarkPreview: true,
                  selected: themeProvider.isDark,
                  onTap: () => themeProvider.setDark(true),
                ),
              ),
            ]),
            const SizedBox(height: 24),

            // --- MENU LAPORAN
            Text('LAPORAN',
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                    color: context.colorTextHint)),
            const SizedBox(height: 12),
            ListTile(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ReportPage()),
              ),
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                    color: Colors.red.withOpacity(
                        0.1), // Menggunakan kecerahan merah/error sejalan dengan AppColors.error
                    borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.bar_chart_rounded,
                    color: Colors.red, size: 20),
              ),
              title: Text('Laporan',
                  style: TextStyle(
                      fontSize: 14,
                      color: context.colorTextPrimary,
                      fontWeight: FontWeight.w500)),
              trailing: Icon(Icons.chevron_right_rounded,
                  color: context.colorTextHint),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: context.colorBorder),
              ),
              tileColor: context.colorSurface,
            ),
            const SizedBox(height: 24),

            // Bagian Fitur Keamanan di Bawah Tampilan
            Text('KEAMANAN',
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                    color: context.colorTextHint)),
            const SizedBox(height: 12),
            ListTile(
              onTap: _showSecurityBottomSheet,
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.lock_rounded,
                    color: Colors.orange, size: 20),
              ),
              title: Text('Ubah Kata Sandi',
                  style: TextStyle(
                      fontSize: 14,
                      color: context.colorTextPrimary,
                      fontWeight: FontWeight.w500)),
              trailing: Icon(Icons.chevron_right_rounded,
                  color: context.colorTextHint),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: context.colorBorder),
              ),
              tileColor: context.colorSurface,
            ),
            const SizedBox(height: 12), // Jarak pemisah antar menu list tile

            // --- MENU FAQ & PANDUAN YANG BARU DITAMBAHKAN ---
            Text('FAQ',
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                    color: context.colorTextHint)),
            const SizedBox(height: 12),
            ListTile(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const FaqPage()),
              ),
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                    color: const Color(0xFF7C3AED).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.help_rounded,
                    color: Color(0xFF7C3AED), size: 20),
              ),
              title: Text('FAQ & Panduan',
                  style: TextStyle(
                      fontSize: 14,
                      color: context.colorTextPrimary,
                      fontWeight: FontWeight.w500)),
              trailing: Icon(Icons.chevron_right_rounded,
                  color: context.colorTextHint),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: context.colorBorder),
              ),
              tileColor: context.colorSurface,
            ),
            const SizedBox(height: 24),

            // Tombol Keluar (Logout) yang Baru dipindahkan di bawah Keamanan & FAQ
            ElevatedButton.icon(
              onPressed: () async =>
                  await context.read<AuthProvider>().logout(),
              icon: const Icon(Icons.logout_rounded, color: Colors.white),
              label: const Text(
                'Keluar',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red, // Background teks warna merah
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String label, IconData icon,
      {TextInputType keyboardType = TextInputType.text}) {
    return TextField(
      controller: ctrl,
      keyboardType: keyboardType,
      decoration:
          InputDecoration(labelText: label, prefixIcon: Icon(icon, size: 20)),
    );
  }

  Widget _passField(TextEditingController ctrl, String label, bool obscure,
      VoidCallback toggle) {
    return TextField(
      controller: ctrl,
      obscureText: obscure,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.lock_rounded, size: 20),
        suffixIcon: IconButton(
            icon: Icon(
                obscure
                    ? Icons.visibility_off_rounded
                    : Icons.visibility_rounded,
                size: 20),
            onPressed: toggle),
      ),
    );
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    _rtRwCtrl.dispose();
    _curPassCtrl.dispose();
    _newPassCtrl.dispose();
    _confirmPassCtrl.dispose();
    super.dispose();
  }
}
