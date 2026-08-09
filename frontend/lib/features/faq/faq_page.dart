import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/api/api_client.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/snackbar_helper.dart';
import '../../core/widgets/common_widgets.dart';
import '../auth/auth_provider.dart';

class FaqPage extends StatefulWidget {
  const FaqPage({super.key});
  @override
  State<FaqPage> createState() => _FaqPageState();
}

class _FaqPageState extends State<FaqPage> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  List<dynamic> _faqs = [];
  List<dynamic> _guides = [];
  bool _loading = true;
  String? _error;
  String _search = '';
  String? _categoryFilter;
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait(
          [ApiClient().get('/faqs'), ApiClient().get('/guidance')]);
      setState(() {
        _faqs = (results[0].data['data'] as List?) ?? [];
        _guides = (results[1].data['data'] as List?) ?? [];
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Gagal memuat data';
        _loading = false;
      });
    }
  }

  List<dynamic> get _filteredFaqs => _faqs.where((f) {
        final matchSearch = _search.isEmpty ||
            (f['question'] as String? ?? '')
                .toLowerCase()
                .contains(_search.toLowerCase()) ||
            (f['answer'] as String? ?? '')
                .toLowerCase()
                .contains(_search.toLowerCase());
        final matchCat =
            _categoryFilter == null || f['category'] == _categoryFilter;
        return matchSearch && matchCat;
      }).toList();

  List<String> get _categories {
    final cats =
        _faqs.map((f) => f['category'] as String? ?? 'Umum').toSet().toList();
    cats.sort();
    return cats;
  }

  bool get isAdmin => context.read<AuthProvider>().isAdmin;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colorBg,
      body: Column(children: [
        Container(
          padding: EdgeInsets.fromLTRB(
              12, MediaQuery.of(context).padding.top + 16, 20, 0),
          decoration: BoxDecoration(
            gradient: context.headerGradient,
            borderRadius:
                const BorderRadius.vertical(bottom: Radius.circular(28)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded,
                      color: Colors.white, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text('FAQ & Panduan',
                      style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Colors.white)),
                ),
                if (isAdmin)
                  IconButton(
                    icon: const Icon(Icons.add_rounded, color: Colors.white),
                    style: IconButton.styleFrom(
                        backgroundColor: Colors.white.withOpacity(0.18)),
                    onPressed: () => _showFaqForm(context),
                  ),
              ]),
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.only(left: 44),
                child: Text('Punya pertanyaan? Cari jawabannya di sini',
                    style: TextStyle(
                        fontSize: 12.5, color: Colors.white.withOpacity(0.85))),
              ),
              const SizedBox(height: 16),
              TabBar(
                controller: _tabCtrl,
                indicatorColor: Colors.white,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white.withOpacity(0.6),
                indicatorWeight: 3,
                tabs: const [Tab(text: 'FAQ'), Tab(text: 'Panduan')],
              ),
            ],
          ),
        ),
        Expanded(
          child: _loading
              ? const ShimmerList()
              : _error != null
                  ? ErrorState(message: _error!, onRetry: _loadAll)
                  : TabBarView(
                      controller: _tabCtrl, children: [_faqTab(), _guideTab()]),
        ),
      ]),
    );
  }

  Widget _faqTab() {
    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
        child: TextField(
          controller: _searchCtrl,
          onChanged: (v) => setState(() => _search = v),
          decoration: InputDecoration(
            hintText: 'Cari pertanyaan...',
            prefixIcon: const Icon(Icons.search_rounded, size: 20),
            suffixIcon: _search.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear_rounded, size: 20),
                    onPressed: () {
                      _searchCtrl.clear();
                      setState(() => _search = '');
                    })
                : null,
          ),
        ),
      ),
      if (_categories.length > 1)
        Padding(
          padding: const EdgeInsets.only(top: 12),
          child: SizedBox(
            height: 42,
            child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                children: [
                  _catChip('Semua', null, Icons.apps_rounded),
                  const SizedBox(width: 10),
                  ..._categories.map((c) => Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: _catChip(c, c, Icons.label_rounded))),
                ]),
          ),
        ),
      const SizedBox(height: 12),
      Expanded(
          child: _filteredFaqs.isEmpty
              ? const EmptyState(
                  icon: Icons.quiz_rounded,
                  title: 'Tidak ada FAQ',
                  subtitle: 'Coba kata kunci lain')
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  itemCount: _filteredFaqs.length,
                  itemBuilder: (_, i) => _faqCard(_filteredFaqs[i]),
                )),
    ]);
  }

  Widget _catChip(String label, String? value, IconData icon) {
    final selected = _categoryFilter == value;
    return CategoryPill(
      label: label,
      icon: icon,
      selected: selected,
      onTap: () => setState(() => _categoryFilter = value),
    );
  }

  Widget _faqCard(Map<String, dynamic> faq) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
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
          ]),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          iconColor: context.colorTextSecond,
          collapsedIconColor: context.colorTextSecond,
          title: Row(children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                  color: AppColors.primary
                      .withOpacity(context.isDarkMode ? 0.2 : 0.1),
                  borderRadius: BorderRadius.circular(10)),
              child: const Center(
                  child: Text('Q',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary))),
            ),
            const SizedBox(width: 12),
            Expanded(
                child: Text('${faq['question']}',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: context.colorTextPrimary))),
          ]),
          children: [
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                    color: AppColors.accent
                        .withOpacity(context.isDarkMode ? 0.2 : 0.1),
                    borderRadius: BorderRadius.circular(10)),
                child: const Center(
                    child: Text('A',
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: AppColors.accent))),
              ),
              const SizedBox(width: 12),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text('${faq['answer']}',
                        style: TextStyle(
                            fontSize: 13,
                            color: context.colorTextSecond,
                            height: 1.6)),
                    if (isAdmin) ...[
                      const SizedBox(height: 12),
                      Row(children: [
                        OutlinedButton.icon(
                          onPressed: () => _showFaqForm(context, faq: faq),
                          icon: const Icon(Icons.edit_rounded, size: 14),
                          label: const Text('Edit'),
                          style: OutlinedButton.styleFrom(
                              minimumSize: const Size(80, 32),
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 12)),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton.icon(
                          onPressed: () => _deleteFaq(faq['id']),
                          icon: const Icon(Icons.delete_rounded,
                              size: 14, color: AppColors.error),
                          label: const Text('Hapus',
                              style: TextStyle(color: AppColors.error)),
                          style: OutlinedButton.styleFrom(
                              minimumSize: const Size(80, 32),
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 12),
                              side: const BorderSide(color: AppColors.error)),
                        ),
                      ]),
                    ],
                  ])),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _guideTab() {
    if (_guides.isEmpty)
      return const EmptyState(
          icon: Icons.menu_book_rounded, title: 'Belum ada panduan');
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _guides.length,
      itemBuilder: (_, i) {
        final g = _guides[i];
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
              color: context.colorSurface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: context.colorBorder)),
          child: Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              tilePadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              iconColor: context.colorTextSecond,
              collapsedIconColor: context.colorTextSecond,
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                    color: AppColors.primary
                        .withOpacity(context.isDarkMode ? 0.2 : 0.1),
                    borderRadius: BorderRadius.circular(12)),
                child: Center(
                    child: Text('${(i + 1)}',
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary))),
              ),
              title: Text('${g['title']}',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: context.colorTextPrimary)),
              subtitle: Text('${g['category'] ?? ''}',
                  style:
                      TextStyle(fontSize: 11, color: context.colorTextSecond)),
              children: [
                Text('${g['content']}',
                    style: TextStyle(
                        fontSize: 13,
                        color: context.colorTextSecond,
                        height: 1.7)),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _deleteFaq(int id) async {
    final ok = await showConfirmDialog(context,
        title: 'Hapus FAQ',
        message: 'FAQ ini akan dihapus.',
        isDangerous: true);
    if (!ok) return;
    try {
      await ApiClient().delete('/admin/faqs/$id');
      SnackBarHelper.show(context, 'FAQ dihapus.', isSuccess: true);
      _loadAll();
    } catch (_) {
      SnackBarHelper.show(context, 'Gagal menghapus.', isError: true);
    }
  }

  void _showFaqForm(BuildContext context, {Map<String, dynamic>? faq}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _FaqFormSheet(faq: faq, onSaved: _loadAll),
    );
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }
}

class _FaqFormSheet extends StatefulWidget {
  final Map<String, dynamic>? faq;
  final VoidCallback onSaved;
  const _FaqFormSheet({this.faq, required this.onSaved});
  @override
  State<_FaqFormSheet> createState() => _FaqFormSheetState();
}

class _FaqFormSheetState extends State<_FaqFormSheet> {
  final _qCtrl = TextEditingController();
  final _aCtrl = TextEditingController();
  final _cCtrl = TextEditingController();
  bool _saving = false;
  bool get isEdit => widget.faq != null;

  @override
  void initState() {
    super.initState();
    if (isEdit) {
      _qCtrl.text = widget.faq!['question'] ?? '';
      _aCtrl.text = widget.faq!['answer'] ?? '';
      _cCtrl.text = widget.faq!['category'] ?? '';
    }
  }

  Future<void> _save() async {
    if (_qCtrl.text.isEmpty || _aCtrl.text.isEmpty) return;
    setState(() => _saving = true);
    try {
      final data = {
        'question': _qCtrl.text,
        'answer': _aCtrl.text,
        'category': _cCtrl.text,
        'is_active': true
      };
      isEdit
          ? await ApiClient()
              .put('/admin/faqs/${widget.faq!['id']}', data: data)
          : await ApiClient().post('/admin/faqs', data: data);
      if (mounted) {
        Navigator.pop(context);
        widget.onSaved();
      }
    } catch (_) {
      if (mounted)
        SnackBarHelper.show(context, 'Gagal menyimpan.', isError: true);
    }
    if (mounted) setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 80),
      decoration: BoxDecoration(
          color: context.colorSurface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
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
                        borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 16),
            Text(isEdit ? 'Edit FAQ' : 'Tambah FAQ',
                style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: context.colorTextPrimary)),
            const SizedBox(height: 16),
            TextField(
                controller: _qCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                    labelText: 'Pertanyaan *',
                    prefixIcon: Padding(
                        padding: EdgeInsets.only(bottom: 40),
                        child: Icon(Icons.help_outline_rounded, size: 20)))),
            const SizedBox(height: 10),
            TextField(
                controller: _aCtrl,
                maxLines: 4,
                decoration: const InputDecoration(
                    labelText: 'Jawaban *',
                    prefixIcon: Padding(
                        padding: EdgeInsets.only(bottom: 60),
                        child: Icon(Icons.question_answer_rounded, size: 20)))),
            const SizedBox(height: 10),
            TextField(
                controller: _cCtrl,
                decoration: const InputDecoration(
                    labelText: 'Kategori (opsional)',
                    prefixIcon: Icon(Icons.label_rounded, size: 20))),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : Text(isEdit ? 'Simpan' : 'Tambah FAQ'),
            ),
          ]),
    );
  }
}
