import 'package:ailearning/src/authentication/presentation/screens/login_screen.dart';
import 'package:ailearning/src/common/app_theme.dart';
import 'package:ailearning/src/common/global_snackbar.dart';
import 'package:ailearning/src/common/user_role_service.dart';
import 'package:ailearning/src/homescreen/student/screens/home_screen.dart';
import 'package:ailearning/src/homescreen/teacher/screens/home_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

Future<void> _loadEnv() async {
  try {
    await dotenv.load(fileName: '.env');
  } catch (_) {
    // Missing or invalid .env is non-fatal; ChatService skips AI when key absent.
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _loadEnv();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      // designSize: const Size(430, 932),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        final globalManager = GlobalScaffoldManager();
        return MaterialApp(
          title: 'AI Learning',
          theme: AppTheme.theme,
          navigatorKey: globalManager.navigatorKey,
          scaffoldMessengerKey: globalManager.scaffoldMessengerKey,
          home: const AuthWrapper(),
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  final UserRoleService _userRoleService = UserRoleService();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasData) {
          return FutureBuilder<bool>(
            future: _userRoleService.isTeacher(),
            builder: (context, roleSnapshot) {
              if (roleSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }
              // Navigate to teacher home if teacher, otherwise student home
              if (roleSnapshot.data == true) {
                return const TeacherHomeScreen();
              }
              return const HomeScreen();
            },
          );
        }
        return const LoginScreen();
      },
    );
  }
}
