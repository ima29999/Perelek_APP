import 'package:go_router/go_router.dart';
import '../../features/auth/auth_provider.dart';
import '../../features/auth/login_page.dart';
import '../../features/dashboard_admin/dashboard_admin_page.dart';
import '../../features/dashboard_warga/dashboard_warga_page.dart';
import '../../features/invoices/invoices_page.dart';
import '../../features/payments/payments_page.dart';
import '../../features/payments/submit_payment_page.dart';
import '../../features/payments/payment_detail_page.dart';
import '../../features/profile/profile_page.dart';
import '../../features/warga_admin/warga_list_page.dart';
import '../../features/warga_admin/warga_form_page.dart';
import '../../features/warga_admin/warga_detail_page.dart';
import '../../features/reports/report_page.dart';
import '../../features/events/events_page.dart';
import '../../features/expenses/expenses_page.dart';
import '../../features/faq/faq_page.dart';
import '../../features/notifications/notifications_page.dart';
// Widget Showcase (Fluid Splash) ada di lib/fluid_splash/homepage.dart
import '../../fluid_splash/homepage.dart';
import '../shells/admin_shell.dart';
import '../shells/warga_shell.dart';

class AppRouter {
  final AuthProvider auth;
  AppRouter(this.auth);

  late final GoRouter config = GoRouter(
    // Fluid Splash selalu jadi halaman pertama yang dibuka
    initialLocation: '/fluid_splash',
    refreshListenable: auth,
    redirect: (context, state) {
      final loggedIn = auth.isLoggedIn;
      final onLogin = state.matchedLocation == '/login';
      final onSplash = state.matchedLocation == '/fluid_splash';

      if (!loggedIn && !onLogin && !onSplash) return '/fluid_splash';

      if (loggedIn && (onLogin || onSplash)) {
        return auth.isAdmin ? '/admin/dashboard' : '/warga/dashboard';
      }
      return null;
    },
    routes: [
      // ── Fluid Splash: halaman pembuka ───────────────────────────
      GoRoute(
        path: '/fluid_splash',
        builder: (context, __) => Showcase(
          title: 'Fluid Splash',
          onFinish: () => context.go('/login'),
        ),
      ),

      GoRoute(path: '/login', builder: (_, __) => const LoginPage()),

      // ── Notifications (accessible authenticated users) ─────────
      GoRoute(
          path: '/notifications',
          builder: (_, __) => const NotificationsPage()),

      // ── Admin Shell ──────────────────────────────────────────────
      ShellRoute(
        builder: (context, state, child) => AdminShell(child: child),
        routes: [
          GoRoute(
              path: '/admin/dashboard',
              builder: (_, __) => const DashboardAdminPage()),
          GoRoute(
              path: '/admin/warga', builder: (_, __) => const WargaListPage()),
          GoRoute(
              path: '/admin/warga/add',
              builder: (_, __) => const WargaFormPage()),
          GoRoute(
              path: '/admin/warga/:id',
              builder: (_, s) =>
                  WargaDetailPage(userId: int.parse(s.pathParameters['id']!))),
          GoRoute(
              path: '/admin/warga/:id/edit',
              builder: (_, s) =>
                  WargaFormPage(userId: int.parse(s.pathParameters['id']!))),
          GoRoute(
              path: '/admin/payments',
              builder: (_, __) => const PaymentsAdminPage()),
          GoRoute(
              path: '/admin/payments/:id',
              builder: (_, s) => PaymentDetailPage(
                  paymentId: int.parse(s.pathParameters['id']!))),
          GoRoute(
              path: '/admin/expenses',
              builder: (_, __) => const ExpensesPage()),
          GoRoute(
              path: '/admin/reports', builder: (_, __) => const ReportPage()),
          GoRoute(
              path: '/admin/events', builder: (_, __) => const EventsPage()),
          GoRoute(path: '/admin/faq', builder: (_, __) => const FaqPage()),
          GoRoute(
              path: '/admin/profile', builder: (_, __) => const ProfilePage()),
          GoRoute(
              path: '/admin/invoices',
              builder: (_, __) => const InvoicesPage()),
        ],
      ),

      // ── Warga Shell ──────────────────────────────────────────────
      ShellRoute(
        builder: (context, state, child) => WargaShell(child: child),
        routes: [
          GoRoute(
              path: '/warga/dashboard',
              builder: (_, __) => const DashboardWargaPage()),
          GoRoute(
              path: '/warga/invoices',
              builder: (_, __) => const InvoicesPage()),
          GoRoute(
              path: '/warga/payments',
              builder: (_, __) => const PaymentsWargaPage()),
          GoRoute(
              path: '/warga/payments/submit/:invoiceId',
              builder: (_, s) => SubmitPaymentPage(
                  invoiceId: int.parse(s.pathParameters['invoiceId']!))),
          GoRoute(
              path: '/warga/payments/:id',
              builder: (_, s) => PaymentDetailPage(
                  paymentId: int.parse(s.pathParameters['id']!))),
          GoRoute(
              path: '/warga/events', builder: (_, __) => const EventsPage()),
          GoRoute(path: '/warga/faq', builder: (_, __) => const FaqPage()),
          GoRoute(
              path: '/warga/reports', builder: (_, __) => const ReportPage()),
          GoRoute(
              path: '/warga/profile', builder: (_, __) => const ProfilePage()),
        ],
      ),
    ],
  );
}
