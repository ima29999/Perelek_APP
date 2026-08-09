import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart'; // 🌟 Mendukung context.canPop() dan context.pop()
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../core/api/api_client.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/app_cache.dart';
import '../../core/utils/snackbar_helper.dart';
import '../../core/widgets/common_widgets.dart';
import '../auth/auth_provider.dart';

class EventsPage extends StatefulWidget {
  const EventsPage({super.key});
  @override
  State<EventsPage> createState() => _EventsPageState();
}

class _EventsPageState extends State<EventsPage> {
  List<dynamic> _events = [];
  bool _loading = true;
  String? _error;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  CalendarFormat _calFormat = CalendarFormat.month;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool forceRefresh = false}) async {
    final cacheKey = 'events_${_focusedDay.year}';
    final cached = AppCache.instance.get<List<dynamic>>(cacheKey);
    if (cached != null && !forceRefresh) {
      setState(() {
        _events = cached;
        _loading = false;
      });
    } else {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final res = await ApiClient()
          .get('/events', params: {'year': _focusedDay.year.toString()});
      if (res.data['success'] == true) {
        final list = (res.data['data'] as List?) ?? [];
        AppCache.instance.set(cacheKey, list);
        if (!mounted) return;
        setState(() {
          _events = list;
          _loading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      if (cached == null) {
        setState(() {
          _error = 'Gagal memuat kegiatan';
          _loading = false;
        });
      }
    }
  }

  List<dynamic> _eventsForDay(DateTime day) => _events.where((e) {
        try {
          final start = DateTime.parse(e['start_date']);
          return start.year == day.year &&
              start.month == day.month &&
              start.day == day.day;
        } catch (_) {
          return false;
        }
      }).toList();

  List<dynamic> get _selectedEvents {
    if (_selectedDay == null) return [];
    return _eventsForDay(_selectedDay!);
  }

  Color _parseColor(String? hex) {
    if (hex == null) return AppColors.primary;
    try {
      return Color(int.parse('0xFF${hex.replaceAll('#', '')}'));
    } catch (_) {
      return AppColors.primary;
    }
  }

  // Fungsi navigasi kembali berdasarkan role yang kompetibel dengan GoRouter
  void _handleBackNavigation() {
    final isAdmin = context.read<AuthProvider>().isAdmin;
    if (isAdmin) {
      context.go('/admin/dashboard'); // Menggunakan GoRouter
    } else {
      context.go('/warga/dashboard'); // Menggunakan GoRouter
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = context.read<AuthProvider>().isAdmin;
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
                // 🌟 PERBAIKAN: Mengganti 'constraints' dengan 'visualDensity' agar tidak error dan ukuran tetap pas
                IconButton(
                  icon:
                      const Icon(Icons.arrow_back_rounded, color: Colors.white),
                  onPressed: _handleBackNavigation,
                  style: IconButton.styleFrom(
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text('Kalender Kegiatan',
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Colors.white)),
                ),
                if (isAdmin)
                  IconButton(
                    icon: const Icon(Icons.add_rounded, color: Colors.white),
                    style: IconButton.styleFrom(
                        backgroundColor: Colors.white.withOpacity(0.18)),
                    onPressed: () => _showAddEventSheet(context),
                  ),
              ]),
              const SizedBox(height: 8),
              Text('Pantau dan ikuti seluruh agenda kegiatan mendatang',
                  style: TextStyle(
                      fontSize: 12.5, color: Colors.white.withOpacity(0.85))),
            ]),
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
        else ...[
          SliverToBoxAdapter(
            child: Column(
              children: [
                Container(
                  color: context.colorSurface,
                  child: TableCalendar(
                    firstDay: DateTime(2020),
                    lastDay: DateTime(2030),
                    focusedDay: _focusedDay,
                    calendarFormat: _calFormat,
                    selectedDayPredicate: (d) => isSameDay(_selectedDay, d),
                    onDaySelected: (selected, focused) => setState(() {
                      _selectedDay = selected;
                      _focusedDay = focused;
                    }),
                    onPageChanged: (focused) {
                      _focusedDay = focused;
                      _load();
                    },
                    onFormatChanged: (fmt) => setState(() => _calFormat = fmt),
                    eventLoader: _eventsForDay,
                    daysOfWeekStyle: DaysOfWeekStyle(
                      weekdayStyle: TextStyle(color: context.colorTextSecond),
                      weekendStyle: TextStyle(color: context.colorTextSecond),
                    ),
                    calendarStyle: CalendarStyle(
                      markerDecoration: const BoxDecoration(
                          color: AppColors.primary, shape: BoxShape.circle),
                      selectedDecoration: const BoxDecoration(
                          color: AppColors.primary, shape: BoxShape.circle),
                      todayDecoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.3),
                          shape: BoxShape.circle),
                      defaultTextStyle:
                          TextStyle(color: context.colorTextPrimary),
                      weekendTextStyle: const TextStyle(color: AppColors.error),
                      outsideTextStyle: TextStyle(color: context.colorTextHint),
                      outsideDaysVisible: false,
                    ),
                    headerStyle: HeaderStyle(
                      formatButtonVisible: true,
                      titleCentered: true,
                      titleTextStyle: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: context.colorTextPrimary),
                      formatButtonDecoration: const BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.all(Radius.circular(8))),
                      formatButtonTextStyle:
                          const TextStyle(color: Colors.white, fontSize: 12),
                      leftChevronIcon: Icon(Icons.chevron_left_rounded,
                          color: context.colorTextPrimary),
                      rightChevronIcon: Icon(Icons.chevron_right_rounded,
                          color: context.colorTextPrimary),
                    ),
                    locale: 'id_ID',
                  ),
                ),
                Divider(height: 1, color: context.colorBorder),
              ],
            ),
          ),
          _selectedDay != null && _selectedEvents.isEmpty
              ? const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: EmptyState(
                        icon: Icons.event_available_rounded,
                        title: 'Tidak ada kegiatan',
                        subtitle: 'Pilih hari lain atau tambah kegiatan baru'),
                  ),
                )
              : SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (_, i) {
                        final e = _selectedDay != null
                            ? _selectedEvents[i]
                            : _events[i];
                        return _eventCard(e, isAdmin: isAdmin);
                      },
                      childCount: _selectedDay != null
                          ? _selectedEvents.length
                          : _events.length,
                    ),
                  ),
                ),
        ],
      ]),
    );
  }

  Widget _eventCard(Map<String, dynamic> e, {required bool isAdmin}) {
    final color = _parseColor(e['color'] as String?);
    DateTime? startDate;
    try {
      startDate = DateTime.parse(e['start_date']);
    } catch (_) {}

    return IntrinsicHeight(
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: context.colorSurface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: context.colorBorder),
          boxShadow: [
            BoxShadow(
                color:
                    Colors.black.withOpacity(context.isDarkMode ? 0.18 : 0.03),
                blurRadius: 8,
                offset: const Offset(0, 2))
          ],
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: 6,
            height: double.infinity,
            decoration: BoxDecoration(
                color: color,
                borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(14),
                    bottomLeft: Radius.circular(14))),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Expanded(
                          child: Text('${e['title']}',
                              style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: context.colorTextPrimary))),
                      if (isAdmin)
                        PopupMenuButton<String>(
                          icon: Icon(Icons.more_vert_rounded,
                              size: 18, color: context.colorTextHint),
                          onSelected: (v) {
                            if (v == 'delete')
                              _deleteEvent(e['id']);
                            else
                              _showAddEventSheet(context, event: e);
                          },
                          itemBuilder: (_) => [
                            const PopupMenuItem(
                                value: 'edit',
                                child: Row(children: [
                                  Icon(Icons.edit_rounded, size: 16),
                                  SizedBox(width: 8),
                                  Text('Edit')
                                ])),
                            const PopupMenuItem(
                                value: 'delete',
                                child: Row(children: [
                                  Icon(Icons.delete_rounded,
                                      size: 16, color: AppColors.error),
                                  SizedBox(width: 8),
                                  Text('Hapus',
                                      style: TextStyle(color: AppColors.error))
                                ])),
                          ],
                        ),
                    ]),
                    const SizedBox(height: 6),
                    if (e['description'] != null &&
                        (e['description'] as String).isNotEmpty)
                      Text('${e['description']}',
                          style: TextStyle(
                              fontSize: 12, color: context.colorTextSecond),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 8),
                    Wrap(spacing: 12, runSpacing: 4, children: [
                      if (e['location'] != null)
                        Row(mainAxisSize: MainAxisSize.min, children: [
                          Icon(Icons.location_on_rounded,
                              size: 13, color: context.colorTextSecond),
                          const SizedBox(width: 4),
                          Text('${e['location']}',
                              style: TextStyle(
                                  fontSize: 11, color: context.colorTextSecond))
                        ]),
                      if (startDate != null)
                        Row(mainAxisSize: MainAxisSize.min, children: [
                          Icon(Icons.access_time_rounded,
                              size: 13, color: context.colorTextSecond),
                          const SizedBox(width: 4),
                          Text(
                              '${startDate.day}/${startDate.month}/${startDate.year} ${startDate.hour.toString().padLeft(2, '0')}:${startDate.minute.toString().padLeft(2, '0')}',
                              style: TextStyle(
                                  fontSize: 11, color: context.colorTextSecond))
                        ]),
                    ]),
                  ]),
            ),
          ),
        ]),
      ),
    );
  }

  Future<void> _deleteEvent(int id) async {
    final ok = await showConfirmDialog(context,
        title: 'Hapus Kegiatan',
        message: 'Kegiatan ini akan dihapus permanen.',
        isDangerous: true);
    if (!ok) return;
    try {
      await ApiClient().delete('/admin/events/$id');
      SnackBarHelper.show(context, 'Kegiatan dihapus.', isSuccess: true);
      _load(forceRefresh: true);
    } catch (_) {
      SnackBarHelper.show(context, 'Gagal menghapus.', isError: true);
    }
  }

  void _showAddEventSheet(BuildContext context, {Map<String, dynamic>? event}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EventFormSheet(
          event: event, onSaved: () => _load(forceRefresh: true)),
    );
  }
}

class _EventFormSheet extends StatefulWidget {
  final Map<String, dynamic>? event;
  final VoidCallback onSaved;
  const _EventFormSheet({this.event, required this.onSaved});
  @override
  State<_EventFormSheet> createState() => _EventFormSheetState();
}

class _EventFormSheetState extends State<_EventFormSheet> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _locCtrl = TextEditingController();
  final _dateCtrl = TextEditingController();
  bool _saving = false;
  String _color = '#3B82F6';

  bool get isEdit => widget.event != null;

  @override
  void initState() {
    super.initState();
    if (isEdit) {
      final e = widget.event!;
      _titleCtrl.text = e['title'] ?? '';
      _descCtrl.text = e['description'] ?? '';
      _locCtrl.text = e['location'] ?? '';
      _dateCtrl.text = (e['start_date'] as String? ?? '').substring(0, 16);
      _color = e['color'] ?? '#3B82F6';
    }
  }

  Future<void> _save() async {
    if (_titleCtrl.text.isEmpty || _dateCtrl.text.isEmpty) return;
    setState(() => _saving = true);
    try {
      final data = {
        'title': _titleCtrl.text,
        'description': _descCtrl.text,
        'location': _locCtrl.text,
        'start_date': _dateCtrl.text,
        'color': _color,
      };
      isEdit
          ? await ApiClient()
              .put('/admin/events/${widget.event!['id']}', data: data)
          : await ApiClient().post('/admin/events', data: data);
      if (mounted) {
        Navigator.pop(context);
        widget.onSaved();
      }
    } catch (e) {
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
            Text(isEdit ? 'Edit Kegiatan' : 'Tambah Kegiatan',
                style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: context.colorTextPrimary)),
            const SizedBox(height: 16),
            TextField(
                controller: _titleCtrl,
                decoration: const InputDecoration(
                    labelText: 'Judul Kegiatan *',
                    prefixIcon: Icon(Icons.event_rounded, size: 20))),
            const SizedBox(height: 10),
            TextField(
                controller: _descCtrl,
                maxLines: 2,
                decoration: const InputDecoration(
                    labelText: 'Deskripsi',
                    prefixIcon: Padding(
                        padding: EdgeInsets.only(bottom: 20),
                        child: Icon(Icons.notes_rounded, size: 20)))),
            const SizedBox(height: 10),
            TextField(
                controller: _locCtrl,
                decoration: const InputDecoration(
                    labelText: 'Lokasi',
                    prefixIcon: Icon(Icons.location_on_rounded, size: 20))),
            const SizedBox(height: 10),
            TextField(
              controller: _dateCtrl,
              readOnly: true,
              decoration: const InputDecoration(
                  labelText: 'Tanggal & Waktu *',
                  prefixIcon: Icon(Icons.calendar_today_rounded, size: 20),
                  suffixIcon: Icon(Icons.arrow_drop_down)),
              onTap: () async {
                final d = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2030));
                if (d == null) return;
                final t = await showTimePicker(
                    context: context, initialTime: TimeOfDay.now());
                if (t == null) return;
                setState(() => _dateCtrl.text =
                    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')} ${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}:00');
              },
            ),
            const SizedBox(height: 16),
            Row(children: [
              Text('Warna:',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: context.colorTextPrimary)),
              const SizedBox(width: 12),
              ...[
                '#3B82F6',
                '#10B981',
                '#F59E0B',
                '#EF4444',
                '#8B5CF6',
                '#EC4899'
              ].map((c) {
                final color = Color(int.parse('0xFF${c.replaceAll('#', '')}'));
                return GestureDetector(
                  onTap: () => setState(() => _color = c),
                  child: Container(
                    width: 28,
                    height: 28,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(
                            color:
                                _color == c ? Colors.white : Colors.transparent,
                            width: 2),
                        boxShadow: _color == c
                            ? [
                                BoxShadow(
                                    color: color.withOpacity(0.5),
                                    blurRadius: 6)
                              ]
                            : null),
                  ),
                );
              }),
            ]),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : Text(isEdit ? 'Simpan' : 'Tambah Kegiatan'),
            ),
          ]),
    );
  }
}
