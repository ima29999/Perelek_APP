import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart'; // 🌟 Wajib untuk mendeteksi kIsWeb
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/api/api_client.dart';
import '../../core/constants/app_constants.dart'; // 🌟 Digunakan sebagai fallback jika diperlukan
import '../../core/theme/app_theme.dart';
import '../../core/utils/app_cache.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/snackbar_helper.dart';
import '../../core/widgets/common_widgets.dart';

class ExpensesPage extends StatefulWidget {
  const ExpensesPage({super.key});
  @override
  State<ExpensesPage> createState() => _ExpensesPageState();
}

class _ExpensesPageState extends State<ExpensesPage> {
  List<dynamic> _expenses = [];
  bool _loading = true;
  String? _error;
  String _search = '';
  int _page = 1;
  bool _hasMore = true;
  double _total = 0;
  final _searchCtrl = TextEditingController();

  static const _cats = [
    'Keamanan',
    'Infrastruktur',
    'Kebersihan',
    'Kegiatan',
    'Operasional',
    'Administrasi',
    'Lainnya'
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool reset = true, bool forceRefresh = false}) async {
    const cacheKey = 'expenses_admin';
    final useCache = reset && _search.isEmpty;

    if (useCache && !forceRefresh) {
      final cached = AppCache.instance.get<Map<String, dynamic>>(cacheKey);
      if (cached != null) {
        setState(() {
          _expenses = cached['items'] as List;
          _total = cached['total'] as double;
          _loading = false;
        });
        _sortExpenses();
      } else {
        setState(() {
          _loading = true;
          _page = 1;
          _expenses = [];
          _error = null;
        });
      }
    } else if (reset) {
      setState(() {
        _loading = true;
        _page = 1;
        _expenses = [];
        _error = null;
      });
    }
    try {
      final params = <String, dynamic>{'page': _page, 'per_page': 20};
      if (_search.isNotEmpty) params['search'] = _search;
      final res = await ApiClient().get('/admin/expenses', params: params);
      if (res.data['success'] == true) {
        final data = res.data['data'];
        final items = reset
            ? (data['data'] as List? ?? [])
            : [..._expenses, ...(data['data'] as List? ?? [])];
        final total =
            double.tryParse(res.data['summary']?['total']?.toString() ?? '') ??
                0.0;

        if (useCache) {
          AppCache.instance.set(cacheKey, {'items': items, 'total': total});
        }
        if (!mounted) return;
        setState(() {
          _expenses = items;
          _hasMore = _page < (data['last_page'] ?? 1);
          _total = total;
          _loading = false;
        });
        _sortExpenses();
      }
    } catch (e) {
      if (!mounted) return;
      if (!useCache ||
          AppCache.instance.get<Map<String, dynamic>>(cacheKey) == null) {
        setState(() {
          _error = 'Gagal memuat';
          _loading = false;
        });
      }
    }
  }

  void _sortExpenses() {
    if (_expenses.isNotEmpty) {
      setState(() {
        _expenses.sort((a, b) {
          final dateStrA = a['date']?.toString() ?? '';
          final dateStrB = b['date']?.toString() ?? '';
          final dateA =
              DateTime.tryParse(dateStrA)?.toLocal() ?? DateTime(2000);
          final dateB =
              DateTime.tryParse(dateStrB)?.toLocal() ?? DateTime(2000);

          // 1. Urutkan berdasarkan tanggal terbaru terlebih dahulu
          final dateCompare = dateB.compareTo(dateA);
          if (dateCompare != 0) {
            return dateCompare;
          }

          // 2. Jika tanggal sama, urutkan berdasarkan ID terbesar/terbaru agar data baru berada di atas
          final idA = int.tryParse(a['id']?.toString() ?? '') ?? 0;
          final idB = int.tryParse(b['id']?.toString() ?? '') ?? 0;
          return idB.compareTo(idA);
        });
      });
    }
  }

  String _formatDisplayDate(String? rawDate) {
    if (rawDate == null || rawDate.isEmpty) return '-';
    final parsed = DateTime.tryParse(rawDate)?.toLocal();
    if (parsed == null) return rawDate;

    final day = parsed.day.toString().padLeft(2, '0');
    final month = parsed.month.toString().padLeft(2, '0');
    final year = parsed.year;

    return "$day-$month-$year";
  }

  void _handleBackNavigation() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/admin/dashboard');
    }
  }

  // 🌟 HELPER URL: Memprioritaskan directUrl (image_url) yang dikirim oleh API Laravel
  String _getImageUrl(String? path, {String? directUrl}) {
    if (directUrl != null && directUrl.isNotEmpty) {
      if (directUrl.startsWith('http://') || directUrl.startsWith('https://')) {
        return directUrl;
      }
    }

    if (path == null || path.isEmpty) return '';
    var cleanPath = path.trim();
    if (cleanPath.startsWith('http://') || cleanPath.startsWith('https://')) {
      return cleanPath;
    }

    if (cleanPath.startsWith('/')) {
      cleanPath = cleanPath.substring(1);
    }

    var baseUrl = AppConstants.baseUrl;
    if (baseUrl.endsWith('/api/')) {
      baseUrl = baseUrl.substring(0, baseUrl.length - 4);
    } else if (baseUrl.endsWith('/api')) {
      baseUrl = baseUrl.substring(0, baseUrl.length - 4);
    }
    if (baseUrl.endsWith('/')) {
      baseUrl = baseUrl.substring(0, baseUrl.length - 1);
    }

    if (!cleanPath.startsWith('storage/')) {
      cleanPath = 'storage/$cleanPath';
    }

    return Uri.parse('$baseUrl/$cleanPath').toString();
  }

  // 🌟 POPUP DETAIL: Tampilan Gambar Menggunakan image_url Bawaan & Fix Close Tombol X
  void _showExpenseDetail(Map<String, dynamic> e) {
    final imgPath = e['image'];
    final directUrl = e['image_url']; // 🌟 Membaca properti image_url dari API
    final fullImageUrl = _getImageUrl(imgPath, directUrl: directUrl);
    final hasImage = fullImageUrl.isNotEmpty;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext dialogContext) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Dialog
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Detail Pengeluaran',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      constraints: const BoxConstraints(),
                      padding: EdgeInsets.zero,
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () {
                        Navigator.pop(dialogContext);
                      },
                    ),
                  ],
                ),
              ),

              // Konten Detail Teks
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${e['title']}',
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      CurrencyFormatter.format(e['nominal']),
                      style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: AppColors.error),
                    ),
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 10),

                    _detailRow(
                        Icons.category_rounded, 'Kategori', '${e['category']}'),
                    const SizedBox(height: 12),
                    _detailRow(Icons.calendar_today_rounded, 'Tanggal',
                        _formatDisplayDate(e['date'])),
                    const SizedBox(height: 12),
                    _detailRow(Icons.person_rounded, 'Dicatat Oleh',
                        '${e['creator']?['name'] ?? '-'}'),
                    const SizedBox(height: 12),
                    _detailRow(
                        Icons.notes_rounded,
                        'Keterangan',
                        e['description'] != null &&
                                (e['description'] as String).isNotEmpty
                            ? '${e['description']}'
                            : '-'),

                    const SizedBox(height: 20),
                    const Divider(),
                    const SizedBox(height: 10),

                    const Text(
                      'Bukti Pengeluaran:',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textSecond),
                    ),
                    const SizedBox(height: 10),

                    // Rendering Gambar Bukti Nota
                    if (hasImage)
                      Container(
                        height: 250,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border),
                          color: AppColors.surface,
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            fullImageUrl,
                            fit: BoxFit.contain,
                            loadingBuilder: (context, child, progress) {
                              if (progress == null) return child;
                              return const Center(
                                  child: CircularProgressIndicator());
                            },
                            errorBuilder: (_, __, ___) => Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: const [
                                  Icon(Icons.broken_image_rounded,
                                      size: 36, color: AppColors.textHint),
                                  SizedBox(height: 8),
                                  Text('Gagal memuat gambar',
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: AppColors.textHint)),
                                ],
                              ),
                            ),
                          ),
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.image_not_supported_rounded,
                                color: AppColors.textHint, size: 20),
                            SizedBox(width: 8),
                            Text('Tidak ada bukti gambar di-upload',
                                style: TextStyle(
                                    color: AppColors.textHint, fontSize: 12)),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppColors.primary.withOpacity(0.7)),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.textSecond)),
              const SizedBox(height: 2),
              Text(value,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: _handleBackNavigation,
        ),
        title: const Text('Pengeluaran'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
              icon: const Icon(Icons.add_rounded), onPressed: () => _showForm())
        ],
        bottom: PreferredSize(
            preferredSize: const Size.fromHeight(56),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: TextField(
                controller: _searchCtrl,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                    hintText: 'Cari pengeluaran...',
                    hintStyle: TextStyle(
                        color: Colors.white.withOpacity(0.6), fontSize: 14),
                    prefixIcon: Icon(Icons.search_rounded,
                        color: Colors.white.withOpacity(0.7), size: 20),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.15),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10)),
                onChanged: (v) {
                  _search = v;
                  if (v.length >= 2 || v.isEmpty) _load();
                },
              ),
            )),
      ),
      body: Column(children: [
        Container(
          color: AppColors.error.withOpacity(0.06),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Row(children: [
            Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.arrow_upward_rounded,
                    size: 20, color: AppColors.error)),
            const SizedBox(width: 12),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Total Pengeluaran',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecond)),
              Text(CurrencyFormatter.format(_total),
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.error)),
            ]),
          ]),
        ),
        Expanded(
            child: _loading
                ? const ShimmerList()
                : _error != null
                    ? ErrorState(message: _error!, onRetry: _load)
                    : _expenses.isEmpty
                        ? EmptyState(
                            icon: Icons.account_balance_wallet_outlined,
                            title: 'Belum ada pengeluaran',
                            action: ElevatedButton.icon(
                                onPressed: _showForm,
                                icon: const Icon(Icons.add_rounded, size: 18),
                                label: const Text('Catat Pengeluaran'),
                                style: ElevatedButton.styleFrom(
                                    minimumSize: const Size(200, 44))))
                        : RefreshIndicator(
                            onRefresh: _load,
                            color: AppColors.primary,
                            child: ListView.builder(
                                padding:
                                    const EdgeInsets.fromLTRB(16, 16, 16, 80),
                                itemCount:
                                    _expenses.length + (_hasMore ? 1 : 0),
                                itemBuilder: (_, i) {
                                  if (i == _expenses.length)
                                    return Padding(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 16),
                                        child: Center(
                                            child: OutlinedButton(
                                                onPressed: () {
                                                  _page++;
                                                  _load(reset: false);
                                                },
                                                child:
                                                    const Text('Muat Lebih'))));
                                  return _card(_expenses[i]);
                                }))),
      ]),
    );
  }

  Widget _card(Map<String, dynamic> e) {
    final imgPath = e['image'];
    final Math_Url = e['image_url'];
    final fullCardImageUrl = _getImageUrl(imgPath, directUrl: Math_Url);
    final hasImage = fullCardImageUrl.isNotEmpty;

    return InkWell(
      onTap: () => _showExpenseDetail(e),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border)),
        child: Row(children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 44,
              height: 44,
              color: AppColors.error.withOpacity(0.08),
              child: hasImage
                  ? Image.network(
                      fullCardImageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.arrow_upward_rounded,
                        size: 22,
                        color: AppColors.error,
                      ),
                    )
                  : const Icon(Icons.arrow_upward_rounded,
                      size: 22, color: AppColors.error),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text('${e['title']}',
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600)),
                Text('${e['category']} • ${_formatDisplayDate(e['date'])}',
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textSecond)),
                if (e['description'] != null &&
                    (e['description'] as String).isNotEmpty)
                  Text('${e['description']}',
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.textHint),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
              ])),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(
              CurrencyFormatter.format(e['nominal']),
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.error,
              ),
            ),
            const SizedBox(height: 8),
            Row(mainAxisSize: MainAxisSize.min, children: [
              InkWell(
                  onTap: () => _showForm(expense: e),
                  child: const Icon(Icons.edit_rounded,
                      size: 16, color: AppColors.textSecond)),
              const SizedBox(width: 12),
              InkWell(
                  onTap: () => _delete(e['id']),
                  child: const Icon(Icons.delete_rounded,
                      size: 16, color: AppColors.error)),
            ]),
          ]),
        ]),
      ),
    );
  }

  Future<void> _delete(int id) async {
    final ok = await showConfirmDialog(context,
        title: 'Hapus Pengeluaran',
        message: 'Data ini akan dihapus.',
        isDangerous: true);
    if (!ok) return;
    try {
      await ApiClient().delete('/admin/expenses/$id');
      SnackBarHelper.show(context, 'Dihapus.', isSuccess: true);
      _load(forceRefresh: true);
    } catch (_) {
      SnackBarHelper.show(context, 'Gagal.', isError: true);
    }
  }

  void _showForm({Map<String, dynamic>? expense}) {
    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => _FormSheet(
            expense: expense,
            categories: _cats,
            onSaved: () => _load(forceRefresh: true)));
  }
}

class _FormSheet extends StatefulWidget {
  final Map<String, dynamic>? expense;
  final List<String> categories;
  final VoidCallback onSaved;
  const _FormSheet(
      {this.expense, required this.categories, required this.onSaved});
  @override
  State<_FormSheet> createState() => _FormSheetState();
}

class _FormSheetState extends State<_FormSheet> {
  final _titleCtrl = TextEditingController();
  final _nomCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _dateCtrl = TextEditingController();
  String _cat = 'Operasional';
  bool _saving = false;
  bool get isEdit => widget.expense != null;

  File? _imageFile;
  Uint8List? _webImageBytes;
  String? _webImageName;

  final _picker = ImagePicker();
  String? _currentImageUrl;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _dateCtrl.text =
        "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

    if (isEdit) {
      final e = widget.expense!;
      _titleCtrl.text = e['title'] ?? '';

      final nominalDouble =
          double.tryParse(e['nominal']?.toString() ?? '') ?? 0.0;
      _nomCtrl.text = nominalDouble > 0 ? nominalDouble.toInt().toString() : '';

      _descCtrl.text = e['description'] ?? '';

      final rawDate = e['date'] ?? '';
      if (rawDate.isNotEmpty) {
        final parsed = DateTime.tryParse(rawDate);
        if (parsed != null) {
          _dateCtrl.text =
              "${parsed.year}-${parsed.month.toString().padLeft(2, '0')}-${parsed.day.toString().padLeft(2, '0')}";
        } else {
          _dateCtrl.text = rawDate;
        }
      }

      _cat = e['category'] ?? 'Operasional';

      final imgPath = e['image'];
      final directUrl = e['image_url'];
      if (directUrl != null && directUrl.toString().isNotEmpty) {
        _currentImageUrl = directUrl.toString();
      } else if (imgPath != null && imgPath.toString().isNotEmpty) {
        final baseUrl = AppConstants.baseUrl.replaceAll('/api', '');
        final cleanPath = imgPath.toString().startsWith('/')
            ? imgPath.toString().substring(1)
            : imgPath.toString();
        _currentImageUrl = cleanPath.startsWith('storage/')
            ? '$baseUrl/$cleanPath'
            : '$baseUrl/storage/$cleanPath';
      }
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 80,
      );

      if (pickedFile != null) {
        if (kIsWeb) {
          final bytes = await pickedFile.readAsBytes();
          setState(() {
            _webImageBytes = bytes;
            _webImageName = pickedFile.name;
          });
        } else {
          setState(() {
            _imageFile = File(pickedFile.path);
          });
        }
      }
    } catch (e) {
      if (mounted) {
        SnackBarHelper.show(context, 'Gagal mengambil gambar: $e',
            isError: true);
      }
    }
  }

  Future<double?> _getSaldo() async {
    final dashboard =
        AppCache.instance.get<Map<String, dynamic>>('admin_dashboard');
    final cachedSaldo =
        double.tryParse(dashboard?['stats']?['saldo']?.toString() ?? '');
    if (cachedSaldo != null) return cachedSaldo;

    try {
      final res = await ApiClient().get('/admin/dashboard', params: {
        'fresh': 1,
      });
      if (res.data['success'] == true) {
        final data = res.data['data'] as Map<String, dynamic>?;
        if (data != null) {
          AppCache.instance.set('admin_dashboard', data);
          return double.tryParse(data['stats']?['saldo']?.toString() ?? '');
        }
      }
    } catch (_) {
      return null;
    }
    return null;
  }

  Future<void> _save() async {
    if (_titleCtrl.text.isEmpty || _nomCtrl.text.isEmpty) return;
    setState(() => _saving = true);
    try {
      final cleanNominal = _nomCtrl.text.replaceAll(RegExp(r'[^0-9]'), '');
      final nominalValue = double.tryParse(cleanNominal) ?? 0.0;
      final oldNominal = isEdit
          ? double.tryParse(widget.expense?['nominal']?.toString() ?? '') ?? 0.0
          : 0.0;
      final requiredAmount =
          isEdit ? (nominalValue - oldNominal) : nominalValue;

      if (requiredAmount > 0) {
        final availableSaldo = await _getSaldo();
        if (availableSaldo == null) {
          if (mounted) {
            SnackBarHelper.show(
                context, 'Tidak dapat memverifikasi saldo, coba lagi.',
                isError: true);
            setState(() => _saving = false);
          }
          return;
        }
        if (requiredAmount > availableSaldo) {
          if (mounted) {
            SnackBarHelper.show(context, 'Saldo Anda tidak cukup',
                isError: true);
            setState(() => _saving = false);
          }
          return;
        }
      }

      String finalDate = _dateCtrl.text.trim();
      if (finalDate.contains(' ')) {
        finalDate = finalDate.split(' ').first;
      }
      if (finalDate.contains('T')) {
        finalDate = finalDate.split('T').first;
      }

      final Map<String, dynamic> fields = {
        'title': _titleCtrl.text,
        'category': _cat,
        'nominal': cleanNominal,
        'description': _descCtrl.text,
        'date': finalDate,
      };

      if (kIsWeb && _webImageBytes != null) {
        fields['image'] = MultipartFile.fromBytes(
          _webImageBytes!,
          filename: _webImageName ?? 'upload_bukti.jpg',
        );
      } else if (!kIsWeb && _imageFile != null) {
        String fileName = _imageFile!.path.split('/').last;
        fields['image'] = await MultipartFile.fromFile(
          _imageFile!.path,
          filename: fileName,
        );
      }

      if (isEdit) {
        fields['_method'] = 'PUT';
      }

      final formData = FormData.fromMap(fields);

      isEdit
          ? await ApiClient()
              .upload('/admin/expenses/${widget.expense!['id']}', formData)
          : await ApiClient().upload('/admin/expenses', formData);

      if (mounted) {
        Navigator.pop(context);
        widget.onSaved();
      }
    } on DioException catch (de) {
      String errorMsg = 'Gagal menyimpan data.';
      if (de.response?.data != null && de.response?.data['message'] != null) {
        errorMsg = de.response?.data['message'];
        if (de.response?.data['errors'] != null) {
          errorMsg += ": ${de.response?.data['errors'].toString()}";
        }
      }
      if (mounted) SnackBarHelper.show(context, errorMsg, isError: true);
    } catch (e) {
      if (mounted)
        SnackBarHelper.show(context, 'Terjadi kesalahan sistem.',
            isError: true);
    }
    if (mounted) setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          16, 16, 16, MediaQuery.of(context).viewInsets.bottom + 80),
      decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
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
                          color: AppColors.border,
                          borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 16),
              Text(isEdit ? 'Edit Pengeluaran' : 'Catat Pengeluaran',
                  style: const TextStyle(
                      fontSize: 17, fontWeight: FontWeight.w700)),
              const SizedBox(height: 16),
              TextField(
                  controller: _titleCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Judul *',
                      prefixIcon: Icon(Icons.title_rounded, size: 20))),
              const SizedBox(height: 10),
              TextField(
                  controller: _nomCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                      labelText: 'Nominal (Rp) *',
                      prefixIcon: Icon(Icons.attach_money_rounded, size: 20))),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: _cat,
                decoration: const InputDecoration(
                    labelText: 'Kategori',
                    prefixIcon: Icon(Icons.category_rounded, size: 20)),
                items: widget.categories
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) => setState(() => _cat = v!),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _dateCtrl,
                readOnly: true,
                decoration: const InputDecoration(
                    labelText: 'Tanggal *',
                    prefixIcon: Icon(Icons.calendar_today_rounded, size: 20),
                    suffixIcon: Icon(Icons.arrow_drop_down)),
                onTap: () async {
                  final now = DateTime.now();
                  final d = await showDatePicker(
                      context: context,
                      initialDate: now,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030));
                  if (d != null) {
                    setState(() {
                      final monthStr = d.month.toString().padLeft(2, '0');
                      final dayStr = d.day.toString().padLeft(2, '0');
                      _dateCtrl.text = '${d.year}-$monthStr-$dayStr';
                    });
                  }
                },
              ),
              const SizedBox(height: 10),
              TextField(
                  controller: _descCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(
                      labelText: 'Keterangan (opsional)',
                      prefixIcon: Padding(
                          padding: EdgeInsets.only(bottom: 20),
                          child: Icon(Icons.notes_rounded, size: 20)))),
              const SizedBox(height: 16),
              const Text('Bukti Pengeluaran (Foto Nota/Struk)',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecond)),
              const SizedBox(height: 8),
              Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      showModalBottomSheet(
                        context: context,
                        builder: (_) => SafeArea(
                          child: Wrap(
                            children: [
                              ListTile(
                                leading:
                                    const Icon(Icons.photo_library_rounded),
                                title: const Text('Ambil dari Galeri'),
                                onTap: () {
                                  Navigator.pop(context);
                                  _pickImage(ImageSource.gallery);
                                },
                              ),
                              if (!kIsWeb)
                                ListTile(
                                  leading: const Icon(Icons.camera_alt_rounded),
                                  title: const Text('Ambil dari Kamera'),
                                  onTap: () {
                                    Navigator.pop(context);
                                    _pickImage(ImageSource.camera);
                                  },
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: kIsWeb && _webImageBytes != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(11),
                              child: Image.memory(_webImageBytes!,
                                  fit: BoxFit.cover))
                          : !kIsWeb && _imageFile != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(11),
                                  child: Image.file(_imageFile!,
                                      fit: BoxFit.cover))
                              : _currentImageUrl != null
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(11),
                                      child: Image.network(_currentImageUrl!,
                                          fit: BoxFit.cover))
                                  : const Icon(Icons.add_a_photo_rounded,
                                      color: AppColors.textHint),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      (_webImageBytes != null || _imageFile != null)
                          ? 'Gambar bukti terpilih.'
                          : _currentImageUrl != null
                              ? 'Menggunakan bukti gambar lama (Klik kotak jika ingin mengganti).'
                              : 'Belum ada gambar bukti dipilih.',
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.textHint),
                    ),
                  )
                ],
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : Text(isEdit ? 'Simpan' : 'Catat'),
              ),
            ]),
      ),
    );
  }
}
