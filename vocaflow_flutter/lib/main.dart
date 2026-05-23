// LingoPro — Flutter App Entry Point
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import 'core/constants/app_constants.dart';
import 'providers/auth_provider.dart';
import 'providers/word_provider.dart';
import 'providers/learn_provider.dart';
import 'providers/stats_provider.dart';
import 'providers/favorite_provider.dart';

import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/main_shell.dart';
import 'screens/learn_screen.dart';
import 'screens/select_topic_screen.dart';
import 'screens/choose_mode_screen.dart';
import 'screens/result_screen.dart';
import 'screens/favorites_screen.dart';
import 'screens/leaderboard_screen.dart';
import 'screens/practice/flashcard_screen.dart';
import 'screens/practice/typing_screen.dart';
import 'screens/practice/listening_screen.dart';
import 'screens/practice/reverse_recall_screen.dart';
import 'screens/practice/fill_blank_screen.dart';
import 'screens/practice/mixed_challenge_screen.dart';
import 'screens/practice/review_history_screen.dart';
import 'screens/practice/speech_practice_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Force portrait mode for mobile
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Status bar style
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));

  runApp(const LingoProApp());
}

class LingoProApp extends StatelessWidget {
  const LingoProApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => WordProvider()),
        ChangeNotifierProvider(create: (_) => LearnProvider()),
        ChangeNotifierProvider(create: (_) => StatsProvider()),
        ChangeNotifierProvider(create: (_) => FavoriteProvider()),
      ],
      child: MaterialApp(
        title: 'LingoPro',
        debugShowCheckedModeBanner: false,

        // ── Theme ─────────────────────────────────────────────────────
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: AppColors.primary,
            brightness: Brightness.light,
          ),
          scaffoldBackgroundColor: AppColors.background,
          textTheme: GoogleFonts.interTextTheme(
            Theme.of(context).textTheme,
          ),
          appBarTheme: const AppBarTheme(
            backgroundColor: AppColors.background,
            elevation: 0,
            centerTitle: true,
            iconTheme: IconThemeData(color: AppColors.textPrimary),
          ),
          cardTheme: CardThemeData(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
          ),
        ),

        // ── Routes ────────────────────────────────────────────────────
        initialRoute: '/',
        routes: {
          '/':              (_) => const SplashScreen(),
          '/login':         (_) => const LoginScreen(),
          '/home':          (_) => const MainShell(),
          '/learn':         (_) => const LearnScreen(),
          '/select-topic':  (_) => const SelectTopicScreen(),
          '/choose-mode':   (_) => const ChooseModeScreen(),
          '/result':        (_) => const ResultScreen(),
          '/favorites':     (_) => const FavoritesScreen(),
          '/leaderboard':   (_) => const LeaderboardScreen(),
          '/review/history': (_) => const ReviewHistoryScreen(),

          // Practice modes
          '/practice/flashcard':  (_) => const FlashcardScreen(),
          '/practice/typing':     (_) => const TypingScreen(),
          '/practice/listening':  (_) => const ListeningScreen(),
          '/practice/reverse':    (_) => const ReverseRecallScreen(),
          '/practice/fill-blank': (_) => const FillBlankScreen(),
          '/practice/mixed':      (_) => const MixedChallengeScreen(),
          '/practice/speech':     (_) => const SpeechPracticeScreen(),
        },

        // ── Page transitions ──────────────────────────────────────────
        onGenerateRoute: (settings) {
          return PageRouteBuilder(
            settings: settings,
            pageBuilder: (_, __, ___) => const SplashScreen(),
            transitionsBuilder: (_, animation, __, child) {
              return FadeTransition(opacity: animation, child: child);
            },
            transitionDuration: const Duration(milliseconds: 250),
          );
        },
      ),
    );
  }
}
