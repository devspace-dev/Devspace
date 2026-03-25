import 'package:firebase_core/firebase_core.dart';
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
import 'services/mongo_service.dart';
import 'services/auth_service.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ── IMPORTANT ──────────────────────────────────────────────────────────
  // REPLACE with your actual MongoDB URI from Atlas!
  // Example: mongodb+srv://user:pass@cluster.mongodb.net/devspace
  // ───────────────────────────────────────────────────────────────────────
  const String mongoUri = 'mongodb+srv://admin:admin123@cluster0.abcde.mongodb.net/devspace?retryWrites=true&w=majority';
  
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint('Firebase initialization skipped: $e');
  }

  try {
    await MongoService.instance.init(mongoUri);
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

  @override
  Widget build(BuildContext context) {
    if (_showSplash) {
      return SplashScreen(onDone: () => setState(() => _showSplash = false));
    }

    // Gate on MongoDB auth state
    return StreamBuilder<UserModel?>(
      stream: AuthService.instance.authStateChanges,
      initialData: AuthService.instance.currentUser,
      builder: (context, snap) {
        final user = snap.data ?? AuthService.instance.currentUser;

        if (user == null) {
          return LoginScreen(onSuccess: () {});
        }

        // Initialize notifications (optional if using FCM)
        if (_notificationsInitializedForUid != user.id) {
          _notificationsInitializedForUid = user.id;
          NotificationService.instance.init(user.id);
        }
        
        return const DevSpaceApp();
      },
    );
  }
}
