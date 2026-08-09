import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/api/api_client.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/snackbar_helper.dart';

class WargaFormPage extends StatefulWidget {
  final int? userId;
  const WargaFormPage({super.key, this.userId});
  @override
  State<WargaFormPage> createState() => _WargaFormPageState();
}

class _WargaFormPageState extends State<WargaFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _nikCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _rtRwCtrl = TextEditingController();

  bool _loading = false;
  bool _loadingData = false;
  bool _obscurePass = true;

  bool get isEdit => widget.userId != null;

  @override
  void initState() {
    super.initState();
    if (isEdit) _loadData();
  }

  // Fungsi navigasi dengan fallback ke rute halaman daftar warga
  void _handleBackNavigation() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/admin/warga');
    }
  }

  Future<void> _loadData() async {
    setState(() => _loadingData = true);
    try {
      final res = await ApiClient().get('/admin/users/${widget.userId}');
      if (res.data['success'] == true) {
        final u = res.data['data'];
        _nameCtrl.text = u['name'] ?? '';
        _emailCtrl.text = u['email'] ?? '';
        _nikCtrl.text = u['nik'] ?? '';
        _phoneCtrl.text = u['phone'] ?? '';
        _addressCtrl.text = u['address'] ?? '';
        _rtRwCtrl.text = u['rt_rw'] ?? '';
      }
    } catch (_) {}
    setState(() => _loadingData = false);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final data = {
        'name': _nameCtrl.text.trim(),
        'email': _emailCtrl.text.trim(),
        if (_nikCtrl.text.isNotEmpty) 'nik': _nikCtrl.text.trim(),
        if (_phoneCtrl.text.isNotEmpty) 'phone': _phoneCtrl.text.trim(),
        if (_addressCtrl.text.isNotEmpty) 'address': _addressCtrl.text.trim(),
        if (_rtRwCtrl.text.isNotEmpty) 'rt_rw': _rtRwCtrl.text.trim(),
        if (!isEdit && _passCtrl.text.isNotEmpty) 'password': _passCtrl.text,
      };

      final res = isEdit
          ? await ApiClient().put('/admin/users/${widget.userId}', data: data)
          : await ApiClient().post('/admin/users', data: data);

      if (res.data['success'] == true) {
        if (mounted) {
          SnackBarHelper.show(context,
              isEdit ? 'Data warga diperbarui.' : 'Warga baru ditambahkan.',
              isSuccess: true);
          context.go('/admin/warga');
        }
      } else {
        throw Exception(res.data['message'] ?? 'Gagal menyimpan');
      }
    } catch (e) {
      if (mounted) {
        final msg = e.toString().contains('Exception:')
            ? e.toString().replaceAll('Exception: ', '')
            : 'Gagal menyimpan data.';
        SnackBarHelper.show(context, msg, isError: true);
      }
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colorBg,
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Warga' : 'Tambah Warga'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        // Tombol kembali kustom di kiri AppBar
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: _handleBackNavigation,
        ),
      ),
      body: _loadingData
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _sectionTitle('Informasi Akun'),
                      const SizedBox(height: 12),
                      _field(_nameCtrl, 'Nama Lengkap *', Icons.person_rounded,
                          required: true),
                      const SizedBox(height: 12),
                      _field(_emailCtrl, 'Email *', Icons.email_rounded,
                          keyboardType: TextInputType.emailAddress,
                          required: true,
                          validator: (v) => v != null && !v.contains('@')
                              ? 'Email tidak valid'
                              : null),
                      if (!isEdit) ...[
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _passCtrl,
                          obscureText: _obscurePass,
                          decoration: InputDecoration(
                            labelText: 'Password *',
                            prefixIcon:
                                const Icon(Icons.lock_rounded, size: 20),
                            suffixIcon: IconButton(
                              icon: Icon(
                                  _obscurePass
                                      ? Icons.visibility_off_rounded
                                      : Icons.visibility_rounded,
                                  size: 20),
                              onPressed: () =>
                                  setState(() => _obscurePass = !_obscurePass),
                            ),
                          ),
                          validator: (v) =>
                              !isEdit && (v == null || v.length < 8)
                                  ? 'Password min. 8 karakter'
                                  : null,
                        ),
                      ],
                      const SizedBox(height: 24),
                      _sectionTitle('Data Pribadi'),
                      const SizedBox(height: 12),
                      _field(_nikCtrl, 'NIK (akan dienkripsi)',
                          Icons.badge_rounded,
                          keyboardType: TextInputType.number,
                          validator: (v) =>
                              v != null && v.isNotEmpty && v.length != 16
                                  ? 'NIK harus 16 digit'
                                  : null),
                      const SizedBox(height: 12),
                      _field(_phoneCtrl, 'Nomor HP', Icons.phone_rounded,
                          keyboardType: TextInputType.phone),
                      const SizedBox(height: 24),
                      _sectionTitle('Alamat'),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _addressCtrl,
                        maxLines: 3,
                        decoration: const InputDecoration(
                            labelText: 'Alamat',
                            prefixIcon: Padding(
                                padding: EdgeInsets.only(bottom: 40),
                                child: Icon(Icons.home_rounded, size: 20))),
                      ),
                      const SizedBox(height: 12),
                      _field(_rtRwCtrl, 'RT/RW (contoh: RT 01/RW 05)',
                          Icons.location_on_rounded),
                      const SizedBox(height: 32),
                      ElevatedButton(
                        onPressed: _loading ? null : _submit,
                        child: _loading
                            ? const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                    SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2)),
                                    SizedBox(width: 12),
                                    Text('Menyimpan...'),
                                  ])
                            : Text(
                                isEdit ? 'Simpan Perubahan' : 'Tambah Warga'),
                      ),
                      const SizedBox(height: 60),
                    ]),
              ),
            ),
    );
  }

  Widget _sectionTitle(String t) => Text(t,
      style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: context.colorTextPrimary));

  Widget _field(TextEditingController ctrl, String label, IconData icon,
      {TextInputType keyboardType = TextInputType.text,
      bool required = false,
      String? Function(String?)? validator}) {
    return TextFormField(
      controller: ctrl,
      keyboardType: keyboardType,
      decoration:
          InputDecoration(labelText: label, prefixIcon: Icon(icon, size: 20)),
      validator: validator ??
          (required
              ? (v) => v == null || v.isEmpty ? '$label wajib diisi' : null
              : null),
    );
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _nikCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    _rtRwCtrl.dispose();
    super.dispose();
  }
}
