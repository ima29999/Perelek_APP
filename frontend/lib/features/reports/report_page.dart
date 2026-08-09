import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/api/api_client.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/app_cache.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/widgets/common_widgets.dart';
import '../auth/auth_provider.dart';
import 'package:go_router/go_router.dart';

class ReportPage extends StatefulWidget {
  const ReportPage({super.key});
  @override
  State<ReportPage> createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _financial;
  Map<String, dynamic>? _transparency;
  List<dynamic> _arrears = [];
  String _year = DateTime.now().year.toString();

  @override
  void initState() {
    super.initState();
    final isAdmin = context.read<AuthProvider>().isAdmin; //[cite: 6]
    _tabCtrl = TabController(length: isAdmin ? 3 : 2, vsync: this); //[cite: 6]
    _load(); //[cite: 6]
  }

  // Fungsi navigasi kembali berdasarkan role
  // Fungsi navigasi kembali berdasarkan role yang kompetibel dengan GoRouter
  void _handleBackNavigation() {
    final isAdmin = context.read<AuthProvider>().isAdmin;
    if (isAdmin) {
      context.go('/admin/dashboard'); // Menggunakan GoRouter
    } else {
      context.go('/warga/dashboard'); // Menggunakan GoRouter
    }
  }

  Future<void> _load({bool forceRefresh = false}) async {
    //[cite: 6]
    final isAdmin = context.read<AuthProvider>().isAdmin; //[cite: 6]
    final cacheKey =
        'reports_${isAdmin ? 'admin' : 'warga'}_$_year'; //[cite: 6]

    final cached =
        AppCache.instance.get<Map<String, dynamic>>(cacheKey); //[cite: 6]
    if (cached != null && !forceRefresh) {
      //[cite: 6]
      setState(() {
        //[cite: 6]
        _transparency = cached['transparency']; //[cite: 6]
        _financial = cached['financial']; //[cite: 6]
        _arrears = cached['arrears'] as List<dynamic>? ?? []; //[cite: 6]
        _loading = false; //[cite: 6]
      }); //[cite: 6]
    } else {
      //[cite: 6]
      setState(() {
        //[cite: 6]
        _loading = true; //[cite: 6]
        _error = null; //[cite: 6]
      }); //[cite: 6]
    } //[cite: 6]
    try {
      //[cite: 6]
      final futures = <Future>[
        //[cite: 6]
        ApiClient().get(
            //[cite: 6]
            isAdmin
                ? '/admin/reports/transparency'
                : '/reports/transparency', //[cite: 6]
            params: {'year': _year}), //[cite: 6]
        if (isAdmin) //[cite: 6]
          ApiClient().get('/admin/reports/financial', //[cite: 6]
              params: {
                'from': '$_year-01-01',
                'to': '$_year-12-31'
              }), //[cite: 6]
        if (isAdmin) ApiClient().get('/admin/reports/arrears'), //[cite: 6]
      ]; //[cite: 6]

      final results = await Future.wait(futures); //[cite: 6]
      final transparency = results[0].data['data']; //[cite: 6]
      final financial = isAdmin && results.length > 1
          ? results[1].data['data']
          : null; //[cite: 6]
      final arrears = //[cite: 6]
          isAdmin && results.length > 2
              ? (results[2].data['data'] as List?) ?? []
              : <dynamic>[]; //[cite: 6]

      AppCache.instance.set(cacheKey, {
        //[cite: 6]
        'transparency': transparency, //[cite: 6]
        'financial': financial, //[cite: 6]
        'arrears': arrears, //[cite: 6]
      }); //[cite: 6]

      if (!mounted) return; //[cite: 6]
      setState(() {
        //[cite: 6]
        _transparency = transparency; //[cite: 6]
        _financial = financial; //[cite: 6]
        _arrears = arrears; //[cite: 6]
        _loading = false; //[cite: 6]
      }); //[cite: 6]
    } catch (e) {
      //[cite: 6]
      if (!mounted) return; //[cite: 6]
      if (cached == null) {
        //[cite: 6]
        setState(() {
          //[cite: 6]
          _error = 'Gagal memuat laporan'; //[cite: 6]
          _loading = false; //[cite: 6]
        }); //[cite: 6]
      } //[cite: 6]
    } //[cite: 6]
  } //[cite: 6]

  void _showLaporDialog() {
    //[cite: 6]
    final auth = context.read<AuthProvider>(); //[cite: 6]
    final user = auth.user; //[cite: 6]
    final titleCtrl = TextEditingController(); //[cite: 6]
    final descCtrl = TextEditingController(); //[cite: 6]
    bool submitting = false; //[cite: 6]

    showModalBottomSheet(
      //[cite: 6]
      context: context, //[cite: 6]
      isScrollControlled: true, //[cite: 6]
      backgroundColor: Colors.transparent, //[cite: 6]
      builder: (ctx) {
        //[cite: 6]
        return StatefulBuilder(builder: (ctx, setModalState) {
          //[cite: 6]
          return Container(
            //[cite: 6]
            padding: EdgeInsets.only(
              //[cite: 6]
              left: 20, //[cite: 6]
              right: 20, //[cite: 6]
              top: 20, //[cite: 6]
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 80, //[cite: 6]
            ), //[cite: 6]
            decoration: BoxDecoration(
              //[cite: 6]
              color: ctx.colorSurface, //[cite: 6]
              borderRadius: //[cite: 6]
                  const BorderRadius.vertical(
                      top: Radius.circular(24)), //[cite: 6]
            ), //[cite: 6]
            child: Column(
              //[cite: 6]
              mainAxisSize: MainAxisSize.min, //[cite: 6]
              crossAxisAlignment: CrossAxisAlignment.start, //[cite: 6]
              children: [
                //[cite: 6]
                Center(
                  //[cite: 6]
                  child: Container(
                    //[cite: 6]
                    width: 40, //[cite: 6]
                    height: 4, //[cite: 6]
                    decoration: BoxDecoration(
                      //[cite: 6]
                      color: ctx.colorBorder, //[cite: 6]
                      borderRadius: BorderRadius.circular(2), //[cite: 6]
                    ), //[cite: 6]
                  ), //[cite: 6]
                ), //[cite: 6]
                const SizedBox(height: 16), //[cite: 6]
                Row(children: [
                  //[cite: 6]
                  Container(
                    //[cite: 6]
                    width: 40, //[cite: 6]
                    height: 40, //[cite: 6]
                    decoration: BoxDecoration(
                      //[cite: 6]
                      color: AppColors.warning.withOpacity(0.12), //[cite: 6]
                      borderRadius: BorderRadius.circular(12), //[cite: 6]
                    ), //[cite: 6]
                    child: const Icon(Icons.flag_rounded, //[cite: 6]
                        color: AppColors.warning,
                        size: 22), //[cite: 6]
                  ), //[cite: 6]
                  const SizedBox(width: 12), //[cite: 6]
                  Expanded(
                    //[cite: 6]
                    child: Column(
                        //[cite: 6]
                        crossAxisAlignment:
                            CrossAxisAlignment.start, //[cite: 6]
                        children: [
                          //[cite: 6]
                          Text('Kirim Laporan ke Admin', //[cite: 6]
                              style: TextStyle(
                                  //[cite: 6]
                                  fontSize: 16, //[cite: 6]
                                  fontWeight: FontWeight.w700, //[cite: 6]
                                  color: ctx.colorTextPrimary)), //[cite: 6]
                          Text(
                              'Laporan Anda akan langsung diterima admin', //[cite: 6]
                              style: TextStyle(
                                  //[cite: 6]
                                  fontSize: 11,
                                  color: ctx.colorTextSecond)), //[cite: 6]
                        ]), //[cite: 6]
                  ), //[cite: 6]
                ]), //[cite: 6]
                const SizedBox(height: 20), //[cite: 6]
                Container(
                  //[cite: 6]
                  padding: const EdgeInsets.all(12), //[cite: 6]
                  decoration: BoxDecoration(
                    //[cite: 6]
                    color: AppColors.primary.withOpacity(0.07), //[cite: 6]
                    borderRadius: BorderRadius.circular(12), //[cite: 6]
                    border: //[cite: 6]
                        Border.all(
                            color: AppColors.primary
                                .withOpacity(0.15)), //[cite: 6]
                  ), //[cite: 6]
                  child: Row(children: [
                    //[cite: 6]
                    const Icon(Icons.person_rounded, //[cite: 6]
                        size: 16,
                        color: AppColors.primary), //[cite: 6]
                    const SizedBox(width: 8), //[cite: 6]
                    Expanded(
                      //[cite: 6]
                      child: Column(
                          //[cite: 6]
                          crossAxisAlignment:
                              CrossAxisAlignment.start, //[cite: 6]
                          children: [
                            //[cite: 6]
                            Text(
                              //[cite: 6]
                              user?['name'] ??
                                  'Nama tidak tersedia', //[cite: 6]
                              style: const TextStyle(
                                  //[cite: 6]
                                  fontSize: 13, //[cite: 6]
                                  fontWeight: FontWeight.w600, //[cite: 6]
                                  color: AppColors.primary), //[cite: 6]
                            ), //[cite: 6]
                            Text(
                              //[cite: 6]
                              user?['email'] ?? '', //[cite: 6]
                              style: TextStyle(
                                  //[cite: 6]
                                  fontSize: 11,
                                  color: ctx.colorTextSecond), //[cite: 6]
                            ), //[cite: 6]
                          ]), //[cite: 6]
                    ), //[cite: 6]
                    Text(
                      //[cite: 6]
                      _formatNow(), //[cite: 6]
                      style: TextStyle(
                          fontSize: 11, color: ctx.colorTextHint), //[cite: 6]
                    ), //[cite: 6]
                  ]), //[cite: 6]
                ), //[cite: 6]
                const SizedBox(height: 16), //[cite: 6]
                Text('Judul Laporan', //[cite: 6]
                    style: TextStyle(
                        //[cite: 6]
                        fontSize: 13, //[cite: 6]
                        fontWeight: FontWeight.w600, //[cite: 6]
                        color: ctx.colorTextPrimary)), //[cite: 6]
                const SizedBox(height: 8), //[cite: 6]
                TextField(
                  //[cite: 6]
                  controller: titleCtrl, //[cite: 6]
                  maxLength: 100, //[cite: 6]
                  style: TextStyle(
                      fontSize: 14, color: ctx.colorTextPrimary), //[cite: 6]
                  decoration: InputDecoration(
                    //[cite: 6]
                    hintText: 'Contoh: Lampu jalan mati di Blok A', //[cite: 6]
                    hintStyle: //[cite: 6]
                        TextStyle(
                            fontSize: 13, color: ctx.colorTextHint), //[cite: 6]
                    filled: true, //[cite: 6]
                    fillColor: ctx.colorBg, //[cite: 6]
                    counterStyle: //[cite: 6]
                        TextStyle(
                            fontSize: 10, color: ctx.colorTextHint), //[cite: 6]
                    contentPadding: const EdgeInsets.symmetric(
                        //[cite: 6]
                        horizontal: 14,
                        vertical: 12), //[cite: 6]
                    border: OutlineInputBorder(
                      //[cite: 6]
                      borderRadius: BorderRadius.circular(12), //[cite: 6]
                      borderSide:
                          BorderSide(color: ctx.colorBorder), //[cite: 6]
                    ), //[cite: 6]
                    enabledBorder: OutlineInputBorder(
                      //[cite: 6]
                      borderRadius: BorderRadius.circular(12), //[cite: 6]
                      borderSide:
                          BorderSide(color: ctx.colorBorder), //[cite: 6]
                    ), //[cite: 6]
                    focusedBorder: OutlineInputBorder(
                      //[cite: 6]
                      borderRadius: BorderRadius.circular(12), //[cite: 6]
                      borderSide: const BorderSide(
                          //[cite: 6]
                          color: AppColors.primary,
                          width: 1.5), //[cite: 6]
                    ), //[cite: 6]
                  ), //[cite: 6]
                ), //[cite: 6]
                const SizedBox(height: 12), //[cite: 6]
                Text('Deskripsi', //[cite: 6]
                    style: TextStyle(
                        //[cite: 6]
                        fontSize: 13, //[cite: 6]
                        fontWeight: FontWeight.w600, //[cite: 6]
                        color: ctx.colorTextPrimary)), //[cite: 6]
                const SizedBox(height: 8), //[cite: 6]
                TextField(
                  //[cite: 6]
                  controller: descCtrl, //[cite: 6]
                  maxLines: 4, //[cite: 6]
                  maxLength: 500, //[cite: 6]
                  style: TextStyle(
                      fontSize: 14, color: ctx.colorTextPrimary), //[cite: 6]
                  decoration: InputDecoration(
                    //[cite: 6]
                    hintText: //[cite: 6]
                        'Jelaskan secara detail permasalahan yang ingin dilaporkan...', //[cite: 6]
                    hintStyle: //[cite: 6]
                        TextStyle(
                            fontSize: 13, color: ctx.colorTextHint), //[cite: 6]
                    filled: true, //[cite: 6]
                    fillColor: ctx.colorBg, //[cite: 6]
                    alignLabelWithHint: true, //[cite: 6]
                    counterStyle: //[cite: 6]
                        TextStyle(
                            fontSize: 10, color: ctx.colorTextHint), //[cite: 6]
                    contentPadding: const EdgeInsets.symmetric(
                        //[cite: 6]
                        horizontal: 14,
                        vertical: 12), //[cite: 6]
                    border: OutlineInputBorder(
                      //[cite: 6]
                      borderRadius: BorderRadius.circular(12), //[cite: 6]
                      borderSide:
                          BorderSide(color: ctx.colorBorder), //[cite: 6]
                    ), //[cite: 6]
                    enabledBorder: OutlineInputBorder(
                      //[cite: 6]
                      borderRadius: BorderRadius.circular(12), //[cite: 6]
                      borderSide:
                          BorderSide(color: ctx.colorBorder), //[cite: 6]
                    ), //[cite: 6]
                    focusedBorder: OutlineInputBorder(
                      //[cite: 6]
                      borderRadius: BorderRadius.circular(12), //[cite: 6]
                      borderSide: const BorderSide(
                          //[cite: 6]
                          color: AppColors.primary,
                          width: 1.5), //[cite: 6]
                    ), //[cite: 6]
                  ), //[cite: 6]
                ), //[cite: 6]
                const SizedBox(height: 20), //[cite: 6]
                SizedBox(
                  //[cite: 6]
                  width: double.infinity, //[cite: 6]
                  height: 50, //[cite: 6]
                  child: ElevatedButton(
                    //[cite: 6]
                    onPressed: submitting //[cite: 6]
                        ? null //[cite: 6]
                        : () async {
                            //[cite: 6]
                            final title = titleCtrl.text.trim(); //[cite: 6]
                            final desc = descCtrl.text.trim(); //[cite: 6]
                            if (title.isEmpty) {
                              //[cite: 6]
                              ScaffoldMessenger.of(context).showSnackBar(
                                //[cite: 6]
                                const SnackBar(
                                    //[cite: 6]
                                    content: Text(//[cite: 6]
                                        'Judul laporan tidak boleh kosong'), //[cite: 6]
                                    backgroundColor:
                                        AppColors.error), //[cite: 6]
                              ); //[cite: 6]
                              return; //[cite: 6]
                            } //[cite: 6]
                            if (desc.isEmpty) {
                              //[cite: 6]
                              ScaffoldMessenger.of(context).showSnackBar(
                                //[cite: 6]
                                const SnackBar(
                                    //[cite: 6]
                                    content: //[cite: 6]
                                        Text(
                                            'Deskripsi tidak boleh kosong'), //[cite: 6]
                                    backgroundColor:
                                        AppColors.error), //[cite: 6]
                              ); //[cite: 6]
                              return; //[cite: 6]
                            } //[cite: 6]
                            setModalState(() => submitting = true); //[cite: 6]
                            try {
                              //[cite: 6]
                              await ApiClient().post('/reports/submit', data: {
                                //[cite: 6]
                                'title': title, //[cite: 6]
                                'description': desc, //[cite: 6]
                              }); //[cite: 6]
                              if (context.mounted)
                                Navigator.pop(ctx); //[cite: 6]
                              if (context.mounted) {
                                //[cite: 6]
                                ScaffoldMessenger.of(context).showSnackBar(
                                  //[cite: 6]
                                  const SnackBar(
                                    //[cite: 6]
                                    content: Text(//[cite: 6]
                                        '✅ Laporan berhasil dikirim ke admin'), //[cite: 6]
                                    backgroundColor:
                                        AppColors.success, //[cite: 6]
                                  ), //[cite: 6]
                                ); //[cite: 6]
                              } //[cite: 6]
                            } catch (e) {
                              //[cite: 6]
                              setModalState(
                                  () => submitting = false); //[cite: 6]
                              if (context.mounted) {
                                //[cite: 6]
                                ScaffoldMessenger.of(context).showSnackBar(
                                  //[cite: 6]
                                  const SnackBar(
                                      //[cite: 6]
                                      content: Text(
                                          'Gagal mengirim laporan'), //[cite: 6]
                                      backgroundColor:
                                          AppColors.error), //[cite: 6]
                                ); //[cite: 6]
                              } //[cite: 6]
                            } //[cite: 6]
                          }, //[cite: 6]
                    style: ElevatedButton.styleFrom(
                      //[cite: 6]
                      backgroundColor: AppColors.warning, //[cite: 6]
                      foregroundColor: Colors.white, //[cite: 6]
                      shape: RoundedRectangleBorder(
                          //[cite: 6]
                          borderRadius: BorderRadius.circular(14)), //[cite: 6]
                      elevation: 0, //[cite: 6]
                    ), //[cite: 6]
                    child: submitting //[cite: 6]
                        ? const SizedBox(
                            //[cite: 6]
                            width: 20, //[cite: 6]
                            height: 20, //[cite: 6]
                            child: CircularProgressIndicator(
                                //[cite: 6]
                                strokeWidth: 2,
                                color: Colors.white)) //[cite: 6]
                        : const Text('Kirim Laporan', //[cite: 6]
                            style: TextStyle(
                                //[cite: 6]
                                fontSize: 15,
                                fontWeight: FontWeight.w700)), //[cite: 6]
                  ), //[cite: 6]
                ), //[cite: 6]
              ], //[cite: 6]
            ), //[cite: 6]
          ); //[cite: 6]
        }); //[cite: 6]
      }, //[cite: 6]
    ); //[cite: 6]
  } //[cite: 6]

  String _formatNow() {
    //[cite: 6]
    final now = DateTime.now(); //[cite: 6]
    return '${now.day.toString().padLeft(2, '0')}/' //[cite: 6]
        '${now.month.toString().padLeft(2, '0')}/' //[cite: 6]
        '${now.year} ' //[cite: 6]
        '${now.hour.toString().padLeft(2, '0')}:' //[cite: 6]
        '${now.minute.toString().padLeft(2, '0')}'; //[cite: 6]
  } //[cite: 6]

  @override
  Widget build(BuildContext context) {
    final isAdmin = context.read<AuthProvider>().isAdmin; //[cite: 6]
    final tabs = isAdmin //[cite: 6]
        ? const [
            //[cite: 6]
            Tab(text: 'Transparansi'), //[cite: 6]
            Tab(text: 'Keuangan'), //[cite: 6]
            Tab(text: 'Tunggakan') //[cite: 6]
          ] //[cite: 6]
        : const [
            Tab(text: 'Transparansi'),
          ]; //[cite: 6]

    return Scaffold(
      backgroundColor: context.colorBg, //[cite: 6]
      body: Column(
        //[cite: 6]
        children: [
          //[cite: 6]
          // Header
          Container(
            //[cite: 6]
            padding: EdgeInsets.fromLTRB(
                //[cite: 6]
                20,
                MediaQuery.of(context).padding.top + 16,
                20,
                12), //[cite: 6]
            decoration: BoxDecoration(
              //[cite: 6]
              gradient: context.headerGradient, //[cite: 6]
              borderRadius: //[cite: 6]
                  const BorderRadius.vertical(
                      bottom: Radius.circular(28)), //[cite: 6]
            ), //[cite: 6]
            child: Column(
              //[cite: 6]
              crossAxisAlignment: CrossAxisAlignment.start, //[cite: 6]
              children: [
                //[cite: 6]
                Row(
                  //[cite: 6]
                  children: [
                    // TOMBOL KEMBALI (DENGAN DETEKSI ROLE)
                    IconButton(
                      icon: const Icon(Icons.arrow_back_rounded,
                          color: Colors.white),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: _handleBackNavigation,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      //[cite: 6]
                      child: const Text(
                        //[cite: 6]
                        'Laporan Keuangan', //[cite: 6]
                        style: TextStyle(
                            //[cite: 6]
                            fontSize: 20, //[cite: 6]
                            fontWeight: FontWeight.w800, //[cite: 6]
                            color: Colors.white), //[cite: 6]
                      ), //[cite: 6]
                    ), //[cite: 6]
                    if (!isAdmin) ...[
                      //[cite: 6]
                      GestureDetector(
                        //[cite: 6]
                        onTap: _showLaporDialog, //[cite: 6]
                        child: Container(
                          //[cite: 6]
                          padding: const EdgeInsets.symmetric(
                              //[cite: 6]
                              horizontal: 12,
                              vertical: 7), //[cite: 6]
                          decoration: BoxDecoration(
                            //[cite: 6]
                            color: AppColors.warning, //[cite: 6]
                            borderRadius: BorderRadius.circular(20), //[cite: 6]
                            boxShadow: [
                              //[cite: 6]
                              BoxShadow(
                                  //[cite: 6]
                                  color: AppColors.warning
                                      .withOpacity(0.35), //[cite: 6]
                                  blurRadius: 8, //[cite: 6]
                                  offset: const Offset(0, 3)), //[cite: 6]
                            ], //[cite: 6]
                          ), //[cite: 6]
                          child: Row(
                            //[cite: 6]
                            mainAxisSize: MainAxisSize.min, //[cite: 6]
                            children: const [
                              //[cite: 6]
                              Icon(Icons.flag_rounded, //[cite: 6]
                                  color: Colors.white,
                                  size: 15), //[cite: 6]
                              SizedBox(width: 5), //[cite: 6]
                              Text('Lapor', //[cite: 6]
                                  style: TextStyle(
                                      //[cite: 6]
                                      fontSize: 13, //[cite: 6]
                                      fontWeight: FontWeight.w700, //[cite: 6]
                                      color: Colors.white)), //[cite: 6]
                            ], //[cite: 6]
                          ), //[cite: 6]
                        ), //[cite: 6]
                      ), //[cite: 6]
                      const SizedBox(width: 8), //[cite: 6]
                    ], //[cite: 6]
                    PopupMenuButton<String>(
                      //[cite: 6]
                      onSelected: (y) {
                        //[cite: 6]
                        setState(() => _year = y); //[cite: 6]
                        _load(); //[cite: 6]
                      }, //[cite: 6]
                      itemBuilder: (_) => [
                        '2026',
                        '2025',
                        '2024',
                        '2023'
                      ] //[cite: 6]
                          .map((y) => PopupMenuItem(
                              value: y, child: Text(y))) //[cite: 6]
                          .toList(), //[cite: 6]
                      child: Container(
                        //[cite: 6]
                        padding: const EdgeInsets.all(8), //[cite: 6]
                        decoration: BoxDecoration(
                          //[cite: 6]
                          color: Colors.white.withOpacity(0.18), //[cite: 6]
                          shape: BoxShape.circle, //[cite: 6]
                        ), //[cite: 6]
                        child: const Icon(
                          //[cite: 6]
                          Icons.calendar_today_rounded, //[cite: 6]
                          color: Colors.white, //[cite: 6]
                          size: 18, //[cite: 6]
                        ), //[cite: 6]
                      ), //[cite: 6]
                    ), //[cite: 6]
                  ], //[cite: 6]
                ), //[cite: 6]
                const SizedBox(height: 4), //[cite: 6]
                Text(
                  //[cite: 6]
                  'Pantau transparansi dan rincian keuangan kas', //[cite: 6]
                  style: TextStyle(
                      //[cite: 6]
                      fontSize: 12.5,
                      color: Colors.white.withOpacity(0.85)), //[cite: 6]
                ), //[cite: 6]
                const SizedBox(height: 16), //[cite: 6]
                TabBar(
                  //[cite: 6]
                  controller: _tabCtrl, //[cite: 6]
                  indicatorColor: Colors.white, //[cite: 6]
                  labelColor: Colors.white, //[cite: 6]
                  unselectedLabelColor:
                      Colors.white.withOpacity(0.6), //[cite: 6]
                  indicatorWeight: 3, //[cite: 6]
                  dividerColor: Colors.transparent, //[cite: 6]
                  tabs: tabs, //[cite: 6]
                ), //[cite: 6]
              ], //[cite: 6]
            ), //[cite: 6]
          ), //[cite: 6]
          Expanded(
            //[cite: 6]
            child: _loading //[cite: 6]
                ? const ShimmerList() //[cite: 6]
                : _error != null //[cite: 6]
                    ? ErrorState(message: _error!, onRetry: _load) //[cite: 6]
                    : TabBarView(
                        //[cite: 6]
                        controller: _tabCtrl, //[cite: 6]
                        children: [
                          //[cite: 6]
                          _transparencyTab(), //[cite: 6]
                          if (isAdmin)
                            _financialTab()
                          else
                            _personalTab(), //[cite: 6]
                          if (isAdmin) _arrearsTab(), //[cite: 6]
                        ], //[cite: 6]
                      ), //[cite: 6]
          ), //[cite: 6]
        ], //[cite: 6]
      ), //[cite: 6]
    ); //[cite: 6]
  } //[cite: 6]

  Widget _transparencyTab() {
    //[cite: 6]
    if (_transparency == null) //[cite: 6]
      return const EmptyState(
          //[cite: 6]
          icon: Icons.bar_chart_rounded,
          title: 'Tidak ada data'); //[cite: 6]
    final t = _transparency!; //[cite: 6]
    final monthly = (t['monthly_data'] as List?) ?? []; //[cite: 6]
    final byCategory = (t['expense_by_category'] as List?) ?? []; //[cite: 6]

    return RefreshIndicator(
      //[cite: 6]
      onRefresh: _load, //[cite: 6]
      color: AppColors.primary, //[cite: 6]
      child: SingleChildScrollView(
        //[cite: 6]
        physics: const AlwaysScrollableScrollPhysics(), //[cite: 6]
        padding: const EdgeInsets.all(16), //[cite: 6]
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          //[cite: 6]
          Text('Ringkasan Tahun $_year', //[cite: 6]
              style: TextStyle(
                  //[cite: 6]
                  fontSize: 16, //[cite: 6]
                  fontWeight: FontWeight.w700, //[cite: 6]
                  color: context.colorTextPrimary)), //[cite: 6]
          const SizedBox(height: 12), //[cite: 6]
          Column(
            //[cite: 6]
            children: [
              //[cite: 6]
              _buildModernStatCard(
                //[cite: 6]
                label: 'Saldo Kas', //[cite: 6]
                value: double.tryParse(t['saldo']?.toString() ?? '') ??
                    0.0, //[cite: 6]
                imagePath: 'assets/images/wallet.png', //[cite: 6]
                color: AppColors.primary, //[cite: 6]
                sub: 'Sisa kas saat ini', //[cite: 6]
              ), //[cite: 6]
              const SizedBox(height: 10), //[cite: 6]
              Row(
                //[cite: 6]
                children: [
                  //[cite: 6]
                  Expanded(
                    //[cite: 6]
                    child: _buildModernStatCard(
                      //[cite: 6]
                      label: 'Total Pemasukan', //[cite: 6]
                      value: double.tryParse(//[cite: 6]
                              t['total_income']?.toString() ??
                                  '') ?? //[cite: 6]
                          0.0, //[cite: 6]
                      imagePath: 'assets/images/profit-naik.png', //[cite: 6]
                      color: AppColors.success, //[cite: 6]
                      sub: 'Tahun $_year', //[cite: 6]
                    ), //[cite: 6]
                  ), //[cite: 6]
                  const SizedBox(width: 10), //[cite: 6]
                  Expanded(
                    //[cite: 6]
                    child: _buildModernStatCard(
                      //[cite: 6]
                      label: 'Total Pengeluaran', //[cite: 6]
                      value: double.tryParse(//[cite: 6]
                              t['total_expense']?.toString() ??
                                  '') ?? //[cite: 6]
                          0.0, //[cite: 6]
                      imagePath: 'assets/images/budget.png', //[cite: 6]
                      color: AppColors.error, //[cite: 6]
                      sub: 'Tahun $_year', //[cite: 6]
                    ), //[cite: 6]
                  ), //[cite: 6]
                ], //[cite: 6]
              ), //[cite: 6]
            ], //[cite: 6]
          ), //[cite: 6]
          const SizedBox(height: 24), //[cite: 6]
          if (monthly.isNotEmpty) ...[
            //[cite: 6]
            Text('Tren Bulanan', //[cite: 6]
                style: TextStyle(
                    //[cite: 6]
                    fontSize: 15, //[cite: 6]
                    fontWeight: FontWeight.w700, //[cite: 6]
                    color: context.colorTextPrimary)), //[cite: 6]
            const SizedBox(height: 12), //[cite: 6]
            Container(
              //[cite: 6]
              padding: const EdgeInsets.all(16), //[cite: 6]
              decoration: BoxDecoration(
                  //[cite: 6]
                  color: context.colorSurface, //[cite: 6]
                  borderRadius: BorderRadius.circular(16), //[cite: 6]
                  border: Border.all(color: context.colorBorder), //[cite: 6]
                  boxShadow: [
                    //[cite: 6]
                    BoxShadow(
                        //[cite: 6]
                        color: Colors.black //[cite: 6]
                            .withOpacity(
                                context.isDarkMode ? 0.18 : 0.03), //[cite: 6]
                        blurRadius: 8, //[cite: 6]
                        offset: const Offset(0, 2)), //[cite: 6]
                  ]), //[cite: 6]
              child: SizedBox(
                //[cite: 6]
                height: 200, //[cite: 6]
                child: BarChart(BarChartData(
                  //[cite: 6]
                  gridData: FlGridData(
                      //[cite: 6]
                      show: true, //[cite: 6]
                      drawVerticalLine: false, //[cite: 6]
                      getDrawingHorizontalLine: (_) => //[cite: 6]
                          FlLine(
                              color: context.colorBorder,
                              strokeWidth: 1)), //[cite: 6]
                  titlesData: FlTitlesData(
                    //[cite: 6]
                    bottomTitles: AxisTitles(
                        //[cite: 6]
                        sideTitles: SideTitles(
                            //[cite: 6]
                            showTitles: true, //[cite: 6]
                            getTitlesWidget: (v, _) {
                              //[cite: 6]
                              final i = v.toInt(); //[cite: 6]
                              if (i < 0 || i >= monthly.length) //[cite: 6]
                                return const SizedBox(); //[cite: 6]
                              return Text(
                                  //[cite: 6]
                                  (monthly[i]['month'] as String) //[cite: 6]
                                      .substring(0, 3), //[cite: 6]
                                  style: TextStyle(
                                      //[cite: 6]
                                      fontSize: 9, //[cite: 6]
                                      color:
                                          context.colorTextHint)); //[cite: 6]
                            })), //[cite: 6]
                    leftTitles: AxisTitles(
                        //[cite: 6]
                        sideTitles: SideTitles(
                            //[cite: 6]
                            showTitles: true, //[cite: 6]
                            getTitlesWidget: (v, _) => Text(
                                //[cite: 6]
                                CurrencyFormatter.compact(v), //[cite: 6]
                                style: TextStyle(
                                    //[cite: 6]
                                    fontSize: 8, //[cite: 6]
                                    color:
                                        context.colorTextHint)))), //[cite: 6]
                    topTitles: const AxisTitles(
                        //[cite: 6]
                        sideTitles: SideTitles(showTitles: false)), //[cite: 6]
                    rightTitles: const AxisTitles(
                        //[cite: 6]
                        sideTitles: SideTitles(showTitles: false)), //[cite: 6]
                  ), //[cite: 6]
                  borderData: FlBorderData(show: false), //[cite: 6]
                  barGroups: List.generate(
                      //[cite: 6]
                      monthly.length, //[cite: 6]
                      (i) => BarChartGroupData(
                            //[cite: 6]
                            x: i, //[cite: 6]
                            barRods: [
                              //[cite: 6]
                              BarChartRodData(
                                //[cite: 6]
                                toY: double.tryParse(//[cite: 6]
                                        monthly[i]['income']
                                                ?.toString() ?? //[cite: 6]
                                            '') ?? //[cite: 6]
                                    0.0, //[cite: 6]
                                color: AppColors.success, //[cite: 6]
                                width: 8, //[cite: 6]
                                borderRadius:
                                    BorderRadius.circular(4), //[cite: 6]
                              ), //[cite: 6]
                              BarChartRodData(
                                //[cite: 6]
                                toY: double.tryParse(//[cite: 6]
                                        monthly[i]['expense']
                                                ?.toString() ?? //[cite: 6]
                                            '') ?? //[cite: 6]
                                    0.0, //[cite: 6]
                                color: AppColors.error, //[cite: 6]
                                width: 8, //[cite: 6]
                                borderRadius:
                                    BorderRadius.circular(4), //[cite: 6]
                              ), //[cite: 6]
                            ], //[cite: 6]
                          )), //[cite: 6]
                )), //[cite: 6]
              ), //[cite: 6]
            ), //[cite: 6]
            const SizedBox(height: 8), //[cite: 6]
            Row(children: [
              //[cite: 6]
              _legend(AppColors.success, 'Pemasukan'), //[cite: 6]
              const SizedBox(width: 16), //[cite: 6]
              _legend(AppColors.error, 'Pengeluaran'), //[cite: 6]
            ]), //[cite: 6]
          ], //[cite: 6]
          if (byCategory.isNotEmpty) ...[
            //[cite: 6]
            const SizedBox(height: 24), //[cite: 6]
            Text('Pengeluaran per Kategori', //[cite: 6]
                style: TextStyle(
                    //[cite: 6]
                    fontSize: 15, //[cite: 6]
                    fontWeight: FontWeight.w700, //[cite: 6]
                    color: context.colorTextPrimary)), //[cite: 6]
            const SizedBox(height: 12), //[cite: 6]
            ...byCategory.map((c) {
              //[cite: 6]
              final total = //[cite: 6]
                  double.tryParse(c['total']?.toString() ?? '') ??
                      0.0; //[cite: 6]
              final totalExp = //[cite: 6]
                  double.tryParse(c['total_expense']?.toString() ?? '') ??
                      1.0; //[cite: 6]
              final pct = total / (totalExp == 0 ? 1.0 : totalExp); //[cite: 6]
              return Container(
                //[cite: 6]
                margin: const EdgeInsets.only(bottom: 10), //[cite: 6]
                padding: const EdgeInsets.all(14), //[cite: 6]
                decoration: BoxDecoration(
                    //[cite: 6]
                    color: context.colorSurface, //[cite: 6]
                    borderRadius: BorderRadius.circular(14), //[cite: 6]
                    border: //[cite: 6]
                        Border.all(
                            color: AppColors.primary
                                .withOpacity(0.12)), //[cite: 6]
                    boxShadow: [
                      //[cite: 6]
                      BoxShadow(
                          //[cite: 6]
                          color:
                              AppColors.primary.withOpacity(0.04), //[cite: 6]
                          blurRadius: 8, //[cite: 6]
                          offset: const Offset(0, 2)), //[cite: 6]
                    ]), //[cite: 6]
                child: Column(
                    //[cite: 6]
                    crossAxisAlignment: CrossAxisAlignment.start, //[cite: 6]
                    children: [
                      //[cite: 6]
                      Row(
                          //[cite: 6]
                          mainAxisAlignment:
                              MainAxisAlignment.spaceBetween, //[cite: 6]
                          children: [
                            //[cite: 6]
                            Text('${c['category']}', //[cite: 6]
                                style: TextStyle(
                                    //[cite: 6]
                                    fontSize: 13, //[cite: 6]
                                    fontWeight: FontWeight.w600, //[cite: 6]
                                    color:
                                        context.colorTextPrimary)), //[cite: 6]
                            Text(CurrencyFormatter.format(total), //[cite: 6]
                                style: const TextStyle(
                                    //[cite: 6]
                                    fontSize: 13, //[cite: 6]
                                    fontWeight: FontWeight.w700, //[cite: 6]
                                    color: AppColors.primary)), //[cite: 6]
                          ]), //[cite: 6]
                      const SizedBox(height: 8), //[cite: 6]
                      ClipRRect(
                          //[cite: 6]
                          borderRadius: BorderRadius.circular(4), //[cite: 6]
                          child: LinearProgressIndicator(
                            //[cite: 6]
                            value: pct, //[cite: 6]
                            backgroundColor: context.colorBorder, //[cite: 6]
                            valueColor: //[cite: 6]
                                const AlwaysStoppedAnimation(
                                    AppColors.primary), //[cite: 6]
                            minHeight: 6, //[cite: 6]
                          )), //[cite: 6]
                      const SizedBox(height: 4), //[cite: 6]
                      Text(
                          //[cite: 6]
                          '${(pct * 100).toStringAsFixed(1)}% dari total pengeluaran', //[cite: 6]
                          style: TextStyle(
                              //[cite: 6]
                              fontSize: 11,
                              color: context.colorTextHint)), //[cite: 6]
                    ]), //[cite: 6]
              ); //[cite: 6]
            }), //[cite: 6]
          ], //[cite: 6]
        ]), //[cite: 6]
      ), //[cite: 6]
    ); //[cite: 6]
  } //[cite: 6]

  Widget _financialTab() {
    //[cite: 6]
    if (_financial == null) //[cite: 6]
      return const EmptyState(
          //[cite: 6]
          icon: Icons.bar_chart_rounded,
          title: 'Tidak ada data'); //[cite: 6]
    final f = _financial!; //[cite: 6]
    final summary = f['summary'] as Map? ?? {}; //[cite: 6]
    final payments = (f['payments'] as List?) ?? []; //[cite: 6]
    final expenses = (f['expenses'] as List?) ?? []; //[cite: 6]

    return SingleChildScrollView(
      //[cite: 6]
      padding: const EdgeInsets.all(16), //[cite: 6]
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        //[cite: 6]
        Container(
          //[cite: 6]
          padding: const EdgeInsets.all(16), //[cite: 6]
          decoration: BoxDecoration(
            //[cite: 6]
            gradient: AppGradients.promo, //[cite: 6]
            borderRadius: BorderRadius.circular(16), //[cite: 6]
            boxShadow: [
              //[cite: 6]
              BoxShadow(
                  //[cite: 6]
                  color: Colors.black.withOpacity(0.25), //[cite: 6]
                  blurRadius: 12, //[cite: 6]
                  offset: const Offset(0, 4)), //[cite: 6]
            ], //[cite: 6]
          ), //[cite: 6]
          child: //[cite: 6]
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            //[cite: 6]
            Text('Laporan Keuangan $_year', //[cite: 6]
                style: const TextStyle(
                    //[cite: 6]
                    fontSize: 14, //[cite: 6]
                    fontWeight: FontWeight.w700, //[cite: 6]
                    color: Colors.white)), //[cite: 6]
            const SizedBox(height: 16), //[cite: 6]
            Row(
              //[cite: 6]
              mainAxisAlignment: MainAxisAlignment.spaceBetween, //[cite: 6]
              children: [
                //[cite: 6]
                _summaryItem(
                  //[cite: 6]
                  'Pemasukan', //[cite: 6]
                  double.tryParse(summary['income']?.toString() ?? '') ??
                      0.0, //[cite: 6]
                  Colors.white, //[cite: 6]
                ), //[cite: 6]
                _summaryItem(
                  //[cite: 6]
                  'Pengeluaran', //[cite: 6]
                  double.tryParse(summary['expense']?.toString() ?? '') ??
                      0.0, //[cite: 6]
                  Colors.white, //[cite: 6]
                ), //[cite: 6]
                _summaryItem(
                  //[cite: 6]
                  'Saldo', //[cite: 6]
                  double.tryParse(summary['saldo']?.toString() ?? '') ??
                      0.0, //[cite: 6]
                  Colors.white, //[cite: 6]
                ), //[cite: 6]
              ], //[cite: 6]
            ), //[cite: 6]
          ]), //[cite: 6]
        ), //[cite: 6]
        const SizedBox(height: 24), //[cite: 6]
        if (payments.isNotEmpty) ...[
          //[cite: 6]
          Text('Rincian Pemasukan (${payments.length})', //[cite: 6]
              style: TextStyle(
                  //[cite: 6]
                  fontSize: 15, //[cite: 6]
                  fontWeight: FontWeight.w700, //[cite: 6]
                  color: context.colorTextPrimary)), //[cite: 6]
          const SizedBox(height: 12), //[cite: 6]
          ...payments.map((p) => _buildModernRowTile(
                //[cite: 6]
                title: '${p['user'] ?? '-'}', //[cite: 6]
                subtitle: //[cite: 6]
                    '${p['invoice'] ?? '-'} • ${p['payment_date'] ?? '-'}', //[cite: 6]
                amount: double.tryParse(p['amount']?.toString() ?? '') ??
                    0.0, //[cite: 6]
                isIncome: true, //[cite: 6]
              )), //[cite: 6]
        ], //[cite: 6]
        if (expenses.isNotEmpty) ...[
          //[cite: 6]
          const SizedBox(height: 16), //[cite: 6]
          Text('Rincian Pengeluaran (${expenses.length})', //[cite: 6]
              style: TextStyle(
                  //[cite: 6]
                  fontSize: 15, //[cite: 6]
                  fontWeight: FontWeight.w700, //[cite: 6]
                  color: context.colorTextPrimary)), //[cite: 6]
          const SizedBox(height: 12), //[cite: 6]
          ...expenses.map((e) => _buildModernRowTile(
                //[cite: 6]
                title: '${e['title'] ?? '-'}', //[cite: 6]
                subtitle:
                    '${e['category'] ?? '-'} • ${e['date'] ?? '-'}', //[cite: 6]
                amount: double.tryParse(e['nominal']?.toString() ?? '') ??
                    0.0, //[cite: 6]
                isIncome: false, //[cite: 6]
              )), //[cite: 6]
        ], //[cite: 6]
      ]), //[cite: 6]
    ); //[cite: 6]
  } //[cite: 6]

  Widget _personalTab() {
    //[cite: 6]
    return Center(
        //[cite: 6]
        child:
            Text('Riwayat pembayaran Anda ada di halaman Riwayat', //[cite: 6]
                style: TextStyle(color: context.colorTextSecond))); //[cite: 6]
  } //[cite: 6]

  Widget _arrearsTab() {
    //[cite: 6]
    if (_arrears.isEmpty) //[cite: 6]
      return const EmptyState(
          //[cite: 6]
          icon: Icons.check_circle_rounded, //[cite: 6]
          title: 'Tidak ada tunggakan', //[cite: 6]
          subtitle: 'Semua warga sudah melunasi tagihan'); //[cite: 6]

    return ListView.builder(
      //[cite: 6]
      padding: const EdgeInsets.all(16), //[cite: 6]
      itemCount: _arrears.length, //[cite: 6]
      itemBuilder: (_, i) {
        //[cite: 6]
        final a = _arrears[i]; //[cite: 6]
        final unpaid = (a['unpaid_warga'] as List?) ?? []; //[cite: 6]
        return Container(
          //[cite: 6]
          margin: const EdgeInsets.only(bottom: 16), //[cite: 6]
          decoration: BoxDecoration(
              //[cite: 6]
              color: context.colorSurface, //[cite: 6]
              borderRadius: BorderRadius.circular(16), //[cite: 6]
              border: Border.all(color: context.colorBorder), //[cite: 6]
              boxShadow: [
                //[cite: 6]
                BoxShadow(
                    //[cite: 6]
                    color: Colors.black //[cite: 6]
                        .withOpacity(
                            context.isDarkMode ? 0.18 : 0.02), //[cite: 6]
                    blurRadius: 8, //[cite: 6]
                    offset: const Offset(0, 2)), //[cite: 6]
              ]), //[cite: 6]
          child: //[cite: 6]
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            //[cite: 6]
            Padding(
              //[cite: 6]
              padding: const EdgeInsets.all(16), //[cite: 6]
              child: Column(
                  //[cite: 6]
                  crossAxisAlignment: CrossAxisAlignment.start, //[cite: 6]
                  children: [
                    //[cite: 6]
                    Text('${a['invoice_title']}', //[cite: 6]
                        style: TextStyle(
                            //[cite: 6]
                            fontSize: 14, //[cite: 6]
                            fontWeight: FontWeight.w700, //[cite: 6]
                            color: context.colorTextPrimary)), //[cite: 6]
                    if (a['period'] != null) //[cite: 6]
                      Text('Periode: ${a['period']}', //[cite: 6]
                          style: TextStyle(
                              //[cite: 6]
                              fontSize: 12,
                              color: context.colorTextSecond)), //[cite: 6]
                    const SizedBox(height: 12), //[cite: 6]
                    Row(children: [
                      //[cite: 6]
                      _stat(
                          '${a['paid_count'] ?? 0}',
                          'Lunas', //[cite: 6]
                          AppColors.success), //[cite: 6]
                      const SizedBox(width: 16), //[cite: 6]
                      _stat(
                          '${a['unpaid_count'] ?? 0}',
                          'Belum Bayar', //[cite: 6]
                          AppColors.error), //[cite: 6]
                    ]), //[cite: 6]
                  ]), //[cite: 6]
            ), //[cite: 6]
            if (unpaid.isNotEmpty) ...[
              //[cite: 6]
              Divider(height: 1, color: context.colorBorder), //[cite: 6]
              ExpansionTile(
                //[cite: 6]
                title: Text('${unpaid.length} warga belum bayar', //[cite: 6]
                    style: const TextStyle(
                        //[cite: 6]
                        fontSize: 13, //[cite: 6]
                        fontWeight: FontWeight.w600, //[cite: 6]
                        color: AppColors.error)), //[cite: 6]
                iconColor: AppColors.error, //[cite: 6]
                collapsedIconColor: AppColors.error, //[cite: 6]
                shape: const Border(), //[cite: 6]
                collapsedShape: const Border(), //[cite: 6]
                children: unpaid //[cite: 6]
                    .map((w) => ListTile(
                          //[cite: 6]
                          dense: true, //[cite: 6]
                          leading: CircleAvatar(
                              //[cite: 6]
                              radius: 16, //[cite: 6]
                              backgroundColor:
                                  AppColors.error.withOpacity(0.1), //[cite: 6]
                              child: Text(
                                  '${(w['name'] as String? ?? 'U')[0]}', //[cite: 6]
                                  style: const TextStyle(
                                      //[cite: 6]
                                      fontSize: 12, //[cite: 6]
                                      color: AppColors.error, //[cite: 6]
                                      fontWeight:
                                          FontWeight.w700))), //[cite: 6]
                          title: Text('${w['name']}', //[cite: 6]
                              style: TextStyle(
                                  //[cite: 6]
                                  fontSize: 13, //[cite: 6]
                                  color: context.colorTextPrimary)), //[cite: 6]
                          subtitle: Text('${w['rt_rw'] ?? '-'}', //[cite: 6]
                              style: TextStyle(
                                  //[cite: 6]
                                  fontSize: 11, //[cite: 6]
                                  color: context.colorTextSecond)), //[cite: 6]
                        )) //[cite: 6]
                    .toList(), //[cite: 6]
              ), //[cite: 6]
            ], //[cite: 6]
          ]), //[cite: 6]
        ); //[cite: 6]
      }, //[cite: 6]
    ); //[cite: 6]
  } //[cite: 6]

  Widget _buildModernStatCard({
    //[cite: 6]
    required String label, //[cite: 6]
    required double value, //[cite: 6]
    required String imagePath, //[cite: 6]
    required Color color, //[cite: 6]
    required String sub, //[cite: 6]
  }) {
    //[cite: 6]
    return Container(
      //[cite: 6]
      padding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 12), //[cite: 6]
      decoration: BoxDecoration(
        //[cite: 6]
        color: AppColors.surface, //[cite: 6]
        borderRadius: BorderRadius.circular(16), //[cite: 6]
        border: Border.all(color: color.withOpacity(0.12)), //[cite: 6]
        boxShadow: [
          //[cite: 6]
          BoxShadow(
              //[cite: 6]
              color: color.withOpacity(0.04), //[cite: 6]
              blurRadius: 10, //[cite: 6]
              offset: const Offset(0, 4)), //[cite: 6]
        ], //[cite: 6]
      ), //[cite: 6]
      child: Row(
        //[cite: 6]
        mainAxisAlignment: MainAxisAlignment.spaceBetween, //[cite: 6]
        children: [
          //[cite: 6]
          Expanded(
            //[cite: 6]
            child: Column(
              //[cite: 6]
              crossAxisAlignment: CrossAxisAlignment.start, //[cite: 6]
              mainAxisAlignment: MainAxisAlignment.center, //[cite: 6]
              children: [
                //[cite: 6]
                Text(
                  //[cite: 6]
                  label, //[cite: 6]
                  style: const TextStyle(
                      //[cite: 6]
                      fontSize: 12, //[cite: 6]
                      fontWeight: FontWeight.w600, //[cite: 6]
                      color: AppColors.textSecond), //[cite: 6]
                ), //[cite: 6]
                const SizedBox(height: 2), //[cite: 6]
                Text(
                  //[cite: 6]
                  CurrencyFormatter.format(value), //[cite: 6]
                  style: TextStyle(
                      //[cite: 6]
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: color), //[cite: 6]
                ), //[cite: 6]
                const SizedBox(height: 2), //[cite: 6]
                Text(
                  //[cite: 6]
                  sub, //[cite: 6]
                  style: //[cite: 6]
                      const TextStyle(
                          fontSize: 10, color: AppColors.textHint), //[cite: 6]
                ), //[cite: 6]
              ], //[cite: 6]
            ), //[cite: 6]
          ), //[cite: 6]
          Container(
            //[cite: 6]
            width: 48, //[cite: 6]
            height: 48, //[cite: 6]
            padding: const EdgeInsets.all(4), //[cite: 6]
            decoration: BoxDecoration(
              //[cite: 6]
              color: color.withOpacity(0.06), //[cite: 6]
              borderRadius: BorderRadius.circular(12), //[cite: 6]
            ), //[cite: 6]
            child: Image.asset(
              //[cite: 6]
              imagePath, //[cite: 6]
              fit: BoxFit.contain, //[cite: 6]
            ), //[cite: 6]
          ), //[cite: 6]
        ], //[cite: 6]
      ), //[cite: 6]
    ); //[cite: 6]
  } //[cite: 6]

  Widget _buildModernRowTile({
    //[cite: 6]
    required String title, //[cite: 6]
    required String subtitle, //[cite: 6]
    required double amount, //[cite: 6]
    required bool isIncome, //[cite: 6]
  }) {
    //[cite: 6]
    final color = isIncome ? AppColors.success : AppColors.error; //[cite: 6]
    final icon = //[cite: 6]
        isIncome
            ? Icons.arrow_downward_rounded
            : Icons.arrow_upward_rounded; //[cite: 6]

    return Container(
      //[cite: 6]
      margin: const EdgeInsets.only(bottom: 10), //[cite: 6]
      padding: const EdgeInsets.all(14), //[cite: 6]
      decoration: BoxDecoration(
        //[cite: 6]
        color: context.colorSurface, //[cite: 6]
        borderRadius: BorderRadius.circular(14), //[cite: 6]
        border: Border.all(color: context.colorBorder), //[cite: 6]
        boxShadow: [
          //[cite: 6]
          BoxShadow(
              //[cite: 6]
              color: Colors.black
                  .withOpacity(context.isDarkMode ? 0.18 : 0.02), //[cite: 6]
              blurRadius: 4, //[cite: 6]
              offset: const Offset(0, 1)), //[cite: 6]
        ], //[cite: 6]
      ), //[cite: 6]
      child: Row(children: [
        //[cite: 6]
        Container(
          //[cite: 6]
          width: 44, //[cite: 6]
          height: 44, //[cite: 6]
          decoration: BoxDecoration(
            //[cite: 6]
            color:
                color.withOpacity(context.isDarkMode ? 0.18 : 0.08), //[cite: 6]
            borderRadius: BorderRadius.circular(12), //[cite: 6]
          ), //[cite: 6]
          child: Icon(icon, size: 22, color: color), //[cite: 6]
        ), //[cite: 6]
        const SizedBox(width: 12), //[cite: 6]
        Expanded(
          //[cite: 6]
          child: Column(
            //[cite: 6]
            crossAxisAlignment: CrossAxisAlignment.start, //[cite: 6]
            children: [
              //[cite: 6]
              Text(title, //[cite: 6]
                  style: TextStyle(
                      //[cite: 6]
                      fontSize: 13, //[cite: 6]
                      fontWeight: FontWeight.w600, //[cite: 6]
                      color: context.colorTextPrimary)), //[cite: 6]
              Text(subtitle, //[cite: 6]
                  style: //[cite: 6]
                      TextStyle(
                          fontSize: 11,
                          color: context.colorTextSecond)), //[cite: 6]
            ], //[cite: 6]
          ), //[cite: 6]
        ), //[cite: 6]
        Text(
          //[cite: 6]
          CurrencyFormatter.format(amount), //[cite: 6]
          style: TextStyle(
              //[cite: 6]
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: color), //[cite: 6]
        ), //[cite: 6]
      ]), //[cite: 6]
    ); //[cite: 6]
  } //[cite: 6]

  Widget _summaryItem(String label, double value, Color color) {
    //[cite: 6]
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      //[cite: 6]
      Text(label, //[cite: 6]
          style: TextStyle(
              fontSize: 11, color: color.withOpacity(0.8))), //[cite: 6]
      const SizedBox(height: 2), //[cite: 6]
      Text(CurrencyFormatter.compact(value), //[cite: 6]
          style: TextStyle(
              //[cite: 6]
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: color)), //[cite: 6]
    ]); //[cite: 6]
  } //[cite: 6]

  Widget _stat(String value, String label, Color color) {
    //[cite: 6]
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      //[cite: 6]
      Text(value, //[cite: 6]
          style: TextStyle(
              //[cite: 6]
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: color)), //[cite: 6]
      Text(label, //[cite: 6]
          style: TextStyle(
              fontSize: 11, color: context.colorTextSecond)), //[cite: 6]
    ]); //[cite: 6]
  } //[cite: 6]

  Widget _legend(Color color, String label) => Row(children: [
        //[cite: 6]
        Container(
            //[cite: 6]
            width: 12, //[cite: 6]
            height: 3, //[cite: 6]
            decoration: BoxDecoration(
                //[cite: 6]
                color: color,
                borderRadius: BorderRadius.circular(2))), //[cite: 6]
        const SizedBox(width: 6), //[cite: 6]
        Text(label, //[cite: 6]
            style: TextStyle(
                fontSize: 12, color: context.colorTextSecond)), //[cite: 6]
      ]); //[cite: 6]

  @override
  void dispose() {
    //[cite: 6]
    _tabCtrl.dispose(); //[cite: 6]
    super.dispose(); //[cite: 6]
  } //[cite: 6]
}
