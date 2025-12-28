import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'services/auth_service.dart';
import 'services/game_service.dart';
import 'services/friend_service.dart';
import 'services/leaderboard_service.dart';
import 'services/matchmaking_service.dart';
import 'services/match_history_service.dart';
import 'services/notification_service.dart';
import 'services/achievement_service.dart';
import 'screens/auth/auth_screen.dart';
import 'screens/home/home_screen.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MasterCheckersApp());
}

class MasterCheckersApp extends StatelessWidget {
  const MasterCheckersApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => GameService()),
        ChangeNotifierProvider(create: (_) => FriendService()),
        ChangeNotifierProvider(create: (_) => LeaderboardService()),
        ChangeNotifierProvider(create: (_) => MatchmakingService()),
        ChangeNotifierProvider(create: (_) => NotificationService()),
        ChangeNotifierProxyProvider<NotificationService, AchievementService>(
          create: (context) => AchievementService(context.read<NotificationService>()),
          update: (context, notificationService, previous) =>
              previous ?? AchievementService(notificationService),
        ),
        ChangeNotifierProxyProvider<AchievementService, MatchHistoryService>(
          create: (context) => MatchHistoryService(context.read<AchievementService>()),
          update: (context, achievementService, previous) =>
              previous ?? MatchHistoryService(achievementService),
        ),
      ],
      child: MaterialApp(
        title: 'Master Checkers AI',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: const AuthWrapper(),
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthService>(
      builder: (context, auth, _) {
        if (auth.isLoading) {
          return const Scaffold(
            backgroundColor: Color(0xFF312E2B),
            body: Center(child: CircularProgressIndicator(color: Color(0xFF81B64C))),
          );
        }
        return auth.currentUser != null ? const HomeScreen() : const AuthScreen();
      },
    );
  }
}
