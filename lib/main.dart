import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'app.dart';
import 'theme/app_theme.dart';
import 'models/user_model.dart';
import 'providers/auth_provider.dart';
import 'providers/posts_provider.dart';
import 'providers/users_provider.dart';
import 'providers/aura_provider.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'services/supabase_service.dart';
import 'services/auth_service.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // ── IMPORTANT ──────────────────────────────────────────────────────────
  // REPLACE with your actual Supabase credentials!
  // ───────────────────────────────────────────────────────────────────────
  const String supabaseUrl = 'https://hybvsgxqstnxamdkijsk.supabase.co';
  const String supabaseAnonKey = 'sb_publishable_PawpVpaKL2oGSMNT92IzkA_wjiORWQ4';

  try {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );
    await AuthService.instance.init();
  } catch (e) {
    debugPrint('Database initialization failed: $e');
  }

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));

  runApp(const DevSpaceRoot());
}

class DevSpaceRoot extends StatelessWidget {
  const DevSpaceRoot({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => PostsProvider()),
        ChangeNotifierProvider(create: (_) => UsersProvider()),
        ChangeNotifierProvider(create: (_) => AuraProvider()),
      ],
      child: MaterialApp(
        title: 'DevSpace',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark,
        home: const _Root(),
      ),
    );
  }
}

class _Root extends StatefulWidget {
  const _Root();
  @override
  State<_Root> createState() => _RootState();
}

class _RootState extends State<_Root> {
  bool _showSplash = true;

  @override
  Widget build(BuildContext context) {
    if (_showSplash) {
      return SplashScreen(onDone: () => setState(() => _showSplash = false));
    }

    // Gate on Supabase auth state
    return StreamBuilder<UserModel?>(
      stream: AuthService.instance.authStateChanges,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Color(0xFF09090B),
            body: Center(
              child: CircularProgressIndicator(color: Color(0xFF7C3AED)),
            ),
          );
        }

        final user = snap.data;

        if (user == null) {
          return LoginScreen(onSuccess: () {});
        }

        // Initialize notifications (optional if using FCM)
        NotificationService.instance.init(user.id);

        return const DevSpaceApp();
      },
    );
  }
}
