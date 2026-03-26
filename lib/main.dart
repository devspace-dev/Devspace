import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'app.dart';
import 'theme/app_theme.dart';
import 'theme/app_colors.dart';
import 'models/user_model.dart';
import 'providers/auth_provider.dart';
import 'providers/posts_provider.dart';
import 'providers/users_provider.dart';
import 'providers/aura_provider.dart';
import 'screens/profile_setup_screen.dart';
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
  String? _notificationsInitializedForUid;
  String? _profilePromptShownForUid;
  bool _showingProfilePrompt = false;

  void _maybePromptProfileCompletion(UserModel user) {
    if (user.profileCompleted ||
        _profilePromptShownForUid == user.id ||
        _showingProfilePrompt) {
      return;
    }

    _profilePromptShownForUid = user.id;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      _showingProfilePrompt = true;

      final openSetup = await showModalBottomSheet<bool>(
        context: context,
        backgroundColor: AppColors.bg2,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (sheetContext) {
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.border2,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Complete your profile',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: AppColors.text,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Good profiles make discovery, follows, and collaboration much better. Add your year, branch, stack, and what you are building.',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.text2,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(sheetContext, false),
                          child: const Text('Later'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(sheetContext, true),
                          child: const Text('Complete profile'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      );

      _showingProfilePrompt = false;

      if (!mounted || openSetup != true) return;

      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => const ProfileSetupScreen(
            mode: ProfileSetupMode.onboarding,
          ),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_showSplash) {
      return SplashScreen(onDone: () => setState(() => _showSplash = false));
    }

    // Gate on Supabase auth state
    return StreamBuilder<UserModel?>(
      stream: AuthService.instance.authStateChanges,
      initialData: AuthService.instance.currentUser,
      builder: (context, snap) {
        final user = snap.data ?? AuthService.instance.currentUser;

        if (user == null) {
          return LoginScreen(onSuccess: () {});
        }

        if (_notificationsInitializedForUid != user.id) {
          _notificationsInitializedForUid = user.id;
          NotificationService.instance.init(user.id);
        }

        _maybePromptProfileCompletion(user);
        
        return const DevSpaceApp();
      },
    );
  }
}
