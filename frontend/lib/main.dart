// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'providers/auth_provider.dart';
import 'providers/poulailler_provider.dart';
import 'providers/cycle_provider.dart';
import 'providers/pret_provider.dart';
import 'providers/rapport_provider.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/home_screen.dart';
import 'screens/poulaillers/poulailler_list_screen.dart';
import 'screens/poulaillers/poulailler_create_screen.dart';
import 'screens/poulaillers/poulailler_detail_screen.dart';
import 'screens/poulaillers/poulailler_edit_screen.dart';
import 'screens/poulaillers/poulailler_migration_screen.dart';
import 'screens/cycles/cycle_list_screen.dart';
import 'screens/cycles/cycle_create_screen.dart';
import 'screens/cycles/cycle_detail_screen.dart';
import 'screens/cycles/cycle_edit_screen.dart';
import 'screens/cycles/cycle_report_form_screen.dart';
import 'screens/cycles/cycle_report_history_screen.dart';
import 'screens/cycles/cycle_performance_report_screen.dart';
import 'screens/stock/stock_dashboard_screen.dart';
import 'screens/stock/stock_mouvement_screen.dart';
import 'screens/stock/stock_history_screen.dart';
import 'screens/finances/finance_hub_screen.dart';
import 'screens/finances/finance_depense_screen.dart';
import 'screens/finances/finance_vente_screen.dart';
import 'screens/finances/finance_loan_dashboard_screen.dart';
import 'screens/finances/finance_loan_list_screen.dart';
import 'screens/finances/finance_loan_create_screen.dart';
import 'screens/finances/finance_loan_detail_screen.dart';
import 'screens/finances/finance_echeance_create_screen.dart';
import 'screens/finances/finance_remboursement_create_screen.dart';
import 'screens/finances/pret_list_screen.dart';
import 'screens/rapports/rapport_list_screen.dart';
import 'screens/notifications_screen.dart';
import 'screens/profile_settings_screen.dart';
import 'core/theme/app_theme.dart';
import 'models/poulailler.dart';
import 'models/pret.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('fr_FR', null);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => PoulaillerProvider()),
        ChangeNotifierProvider(create: (_) => CycleProvider()),
        ChangeNotifierProvider(create: (_) => PretProvider()),
        ChangeNotifierProvider(create: (_) => RapportProvider()),
      ],
      child: MaterialApp(
        title: 'AviPro',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('fr', 'FR'),
        ],
        initialRoute: '/splash',  // Au lieu de '/home'
        routes: {
          '/login': (context) => const LoginScreen(),
          '/register': (context) => const RegisterScreen(),
          '/onboarding': (context) => const OnboardingScreen(),
          '/home': (context) => const HomeScreen(),
          '/poulaillers': (context) => const PoulaillerListScreen(),
          '/poulailler/create': (context) => const PoulaillerCreateScreen(),
          '/poulailler/edit': (context) => PoulaillerEditScreen(
            poulailler: ModalRoute.of(context)!.settings.arguments as Poulailler,
          ),
          '/cycles': (context) => const CycleListScreen(),
          '/cycle/create': (context) => const CycleCreateScreen(),
          '/cycle/report/form': (context) => CycleReportFormScreen(
            cycleData: ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>,
          ),
          '/stock': (context) => const StockDashboardScreen(),
          '/stock/mouvement': (context) => const StockMouvementScreen(),
          '/stock/history': (context) => const StockHistoryScreen(),
          '/finance': (context) => const FinanceHubScreen(),
          '/finance/vente': (context) => FinanceVenteScreen(),
          '/finance/depense': (context) => FinanceDepenseScreen(),
          '/finance/loans': (context) => const FinanceLoanDashboardScreen(),
          '/finance/loan/list': (context) => const FinanceLoanListScreen(),
          '/finance/pret/create': (context) => const FinanceLoanCreateScreen(),
          '/finance/pret': (context) => FinanceLoanDetailScreen(
            pret: ModalRoute.of(context)!.settings.arguments as Pret,
          ),
          '/finance/echeance/create': (context) => FinanceEcheanceCreateScreen(
            pret: ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>,
          ),
          '/finance/remboursement/create': (context) => FinanceRemboursementCreateScreen(
            pret: ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>,
          ),
          '/notifications': (context) => const NotificationsScreen(),
          '/poulailler/migration': (context) => PoulaillerMigrationScreen(
            source: ModalRoute.of(context)!.settings.arguments as Poulailler,
          ),
          '/cycle/history': (context) => CycleReportHistoryScreen(
            cycle: ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>,
          ),
          '/cycle/edit': (context) => CycleEditScreen(
            cycleData: ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>,
          ),
          '/settings': (context) => const ProfileSettingsScreen(),
          '/prets': (context) => const PretListScreen(),
          '/rapports': (context) => const RapportListScreen(),

          '/splash': (context) => SplashScreen(),  // sans const
        },
        onGenerateRoute: (settings) {
          if (settings.name?.startsWith('/cycle/report/') ?? false) {
            final cycle = settings.arguments as Map<String, dynamic>;
            return MaterialPageRoute(
              builder: (context) => CyclePerformanceReportScreen(cycle: cycle),
            );
          }

          if (settings.name?.startsWith('/poulailler/') ?? false) {
            final id = settings.name!.split('/').last;
            return MaterialPageRoute(
              builder: (context) {
                final provider = Provider.of<PoulaillerProvider>(context, listen: false);
                final poulailler = provider.getPoulailler(id);
                if (poulailler != null) {
                  return PoulaillerDetailScreen(poulailler: poulailler);
                }
                return const PoulaillerListScreen();
              },
            );
          }

          if (settings.name?.startsWith('/cycle/') ?? false) {
            final cycle = settings.arguments as Map<String, dynamic>;
            return MaterialPageRoute(
              builder: (context) => CycleDetailScreen(cycleData: cycle),
            );
          }

          return null;
        },
      ),
    );
  }
}