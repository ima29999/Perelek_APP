import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/api/api_client.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/app_cache.dart';
import '../../core/widgets/common_widgets.dart';

class WargaListPage extends StatefulWidget {
  const WargaListPage({super.key});
  @override
  State<WargaListPage> createState() => _WargaListPageState();
}

class _WargaListPageState extends State<WargaListPage> {
  List<dynamic> _warga = [];
  bool _loading = true;
  String? _error;
  String _search = '';
  bool? _activeFilter;
  int _page = 1;
  bool _hasMore = true;
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  // Fungsi untuk menangani navigasi back sesuai dengan role pengguna
  void _handleBackNavigation() {
    if (context.canPop()) {
      context.pop(); // Kembali ke halaman sebelum ini secara otomatis
    } else {
      context.go(
          '/admin/dashboard'); // Antrean fallback jika tidak ada history halaman
    }
  }

  Future<void> _load({bool reset = true, bool forceRefresh = false}) async {
    const cacheKey = 'warga_list';
    final useCache = reset && _search.isEmpty && _activeFilter == null;

    if (useCache && !forceRefresh) {
      final cached = AppCache.instance.get<List<dynamic>>(cacheKey);
      if (cached != null) {
        setState(() {
          _warga = cached;
          _loading = false;
        });
      } else {
        setState(() {
          _loading = true;
          _page = 1;
          _warga = [];
          _error = null;
        });
      }
    } else if (reset) {
      setState(() {
        _loading = true;
        _page = 1;
        _warga = [];
        _error = null;
      });
    }
    try {
      final params = <String, dynamic>{'page': _page, 'per_page': 20};
      if (_search.isNotEmpty) params['search'] = _search;
      if (_activeFilter != null) params['is_active'] = _activeFilter! ? 1 : 0;
      final res = await ApiClient().get('/admin/users', params: params);
      if (res.data['success'] == true) {
        final data = res.data['data'];
        final items = (data['data'] as List?) ?? [];
        final newList = reset ? items : [..._warga, ...items];
        if (useCache) AppCache.instance.set(cacheKey, newList);
        if (!mounted) return;
        setState(() {
          _warga = newList;
          _hasMore = _page < (data['last_page'] ?? 1);
          _loading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      if (!useCache || AppCache.instance.get<List<dynamic>>(cacheKey) == null) {
        setState(() {
          _error = 'Gagal memuat daftar warga';
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colorBg,
      body: CustomScrollView(slivers: [
        SliverToBoxAdapter(
          child: Container(
            padding: EdgeInsets.fromLTRB(
                20, MediaQuery.of(context).padding.top + 16, 20, 22),
            decoration: BoxDecoration(
              gradient: context.headerGradient,
              borderRadius:
                  const BorderRadius.vertical(bottom: Radius.circular(28)),
            ),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                IconButton(
                  icon:
                      const Icon(Icons.arrow_back_rounded, color: Colors.white),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  // Menggunakan fungsi deteksi role di sini
                  onPressed: _handleBackNavigation,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text('Kelola Warga',
                      style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Colors.white)),
                ),
                IconButton(
                  icon:
                      const Icon(Icons.person_add_rounded, color: Colors.white),
                  style: IconButton.styleFrom(
                      backgroundColor: Colors.white.withOpacity(0.18)),
                  onPressed: () => context.go('/admin/warga/add'),
                ),
              ]),
              const SizedBox(height: 4),
              Row(children: [
                const SizedBox(width: 36),
                Expanded(
                  child: Text('Kelola data dan akun seluruh warga RT',
                      style: TextStyle(
                          fontSize: 12.5,
                          color: Colors.white.withOpacity(0.85))),
                ),
                Image.asset('assets/images/orang-komunitas.png',
                    width: 46,
                    height: 46,
                    errorBuilder: (_, __, ___) => const Icon(
                        Icons.groups_rounded,
                        color: Colors.white,
                        size: 36)),
              ]),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.16),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white.withOpacity(0.25)),
                ),
                child: TextField(
                  controller: _searchCtrl,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Cari nama, email, alamat...',
                    hintStyle: TextStyle(
                        color: Colors.white.withOpacity(0.7), fontSize: 14),
                    prefixIcon: Icon(Icons.search_rounded,
                        color: Colors.white.withOpacity(0.85), size: 20),
                    border: InputBorder.none,
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 4, vertical: 14),
                  ),
                  onChanged: (v) {
                    _search = v;
                    if (v.length >= 2 || v.isEmpty) _load();
                  },
                ),
              ),
            ]),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: SizedBox(
              height: 42,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _pill('Semua', Icons.apps_rounded, null),
                  const SizedBox(width: 10),
                  _pill('Aktif', Icons.check_circle_rounded, true),
                  const SizedBox(width: 10),
                  _pill('Nonaktif', Icons.cancel_rounded, false),
                ],
              ),
            ),
          ),
        ),
        if (_loading)
          const SliverToBoxAdapter(
              child: Padding(padding: EdgeInsets.all(16), child: ShimmerList()))
        else if (_error != null)
          SliverToBoxAdapter(
              child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: ErrorState(message: _error!, onRetry: _load)))
        else if (_warga.isEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: EmptyState(
                  icon: Icons.people_rounded,
                  title: 'Belum ada warga',
                  action: ElevatedButton.icon(
                      onPressed: () => context.go('/admin/warga/add'),
                      icon: const Icon(Icons.person_add_rounded, size: 18),
                      label: const Text('Tambah Warga'),
                      style: ElevatedButton.styleFrom(
                          minimumSize: const Size(180, 44)))),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 80),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (_, i) {
                  if (i == _warga.length)
                    return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Center(
                            child: OutlinedButton(
                                onPressed: () {
                                  _page++;
                                  _load(reset: false);
                                },
                                child: const Text('Muat Lebih'))));
                  return _wargaCard(_warga[i]);
                },
                childCount: _warga.length + (_hasMore ? 1 : 0),
              ),
            ),
          ),
      ]),
    );
  }

  Widget _pill(String label, IconData icon, bool? value) {
    final s = _activeFilter == value;
    return CategoryPill(
      label: label,
      icon: icon,
      selected: s,
      onTap: () {
        setState(() => _activeFilter = value);
        _load();
      },
    );
  }

  Widget _wargaCard(Map<String, dynamic> w) {
    final isActive = w['is_active'] == true;
    final canPay = w['can_pay'] != false;
    return InkWell(
      onTap: () => context.go('/admin/warga/${w['id']}'),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: context.colorSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: context.colorBorder),
          boxShadow: [
            BoxShadow(
                color:
                    Colors.black.withOpacity(context.isDarkMode ? 0.18 : 0.03),
                blurRadius: 8,
                offset: const Offset(0, 2))
          ],
        ),
        child: Row(children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: AppColors.primary.withOpacity(0.12),
            backgroundImage: w['profile_photo'] != null
                ? NetworkImage(w['profile_photo'])
                : null,
            child: w['profile_photo'] == null
                ? Text('${(w['name'] as String? ?? 'U')[0].toUpperCase()}',
                    style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 18))
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Row(children: [
                  Expanded(
                      child: Text('${w['name']}',
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: context.colorTextPrimary))),
                  if (!canPay) ...[
                    Tooltip(
                      message: 'Tombol Bayar dinonaktifkan',
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        margin: const EdgeInsets.only(left: 6),
                        decoration: BoxDecoration(
                            color: AppColors.warning.withOpacity(0.15),
                            shape: BoxShape.circle),
                        child: const Icon(Icons.lock_outline_rounded,
                            size: 12, color: AppColors.warning),
                      ),
                    ),
                  ],
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                        color: isActive
                            ? AppColors.confirmatedBg
                            : AppColors.rejectedBg,
                        borderRadius: BorderRadius.circular(20)),
                    child: Text(isActive ? 'Aktif' : 'Nonaktif',
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: isActive
                                ? AppColors.confirmatedText
                                : AppColors.rejectedText)),
                  ),
                ]),
                const SizedBox(height: 4),
                Text('${w['rt_rw'] ?? '-'} • ${w['address'] ?? '-'}',
                    style:
                        TextStyle(fontSize: 11, color: context.colorTextSecond),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ])),
          Icon(Icons.chevron_right_rounded,
              color: context.colorTextHint, size: 20),
        ]),
      ),
    );
  }
}
