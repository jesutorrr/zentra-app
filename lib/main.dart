import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'infrastructure/local_storage_repository.dart';
import 'infrastructure/notification_service.dart';
import 'infrastructure/quick_actions_service.dart';
import 'application/habit_provider.dart';
import 'application/user_provider.dart';
import 'application/auth_provider.dart';
import 'application/pomodoro_provider.dart';
import 'application/theme_provider.dart';
import 'presentation/theme.dart';
import 'presentation/today_screen.dart';
import 'presentation/auth_screen.dart';
import 'presentation/splash_screen.dart';
import 'presentation/habit_form_screen.dart';
import 'presentation/pomodoro_screen.dart';
import 'presentation/progress_screen.dart';
import 'presentation/onboarding_screen.dart';

void main() async {
  // Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();

  // GoogleFonts will try to fetch fonts at runtime if available
  // Falls back to system fonts if offline

  // Initialize date formatting for Spanish locale
  await initializeDateFormatting('es', null);

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Initialize repository
  final repository = await LocalStorageRepository.create();
  
  // Initialize notification service
  final notificationService = NotificationService();
  await notificationService.initialize();
  
  // Initialize theme provider
  final themeProvider = ThemeProvider();
  await themeProvider.loadTheme();
  
  // Initialize Quick Actions service
  final quickActionsService = QuickActionsService();
  quickActionsService.initialize();

  runApp(ZentraApp(
    repository: repository, 
    themeProvider: themeProvider,
    quickActionsService: quickActionsService,
  ),);
}

class ZentraApp extends StatelessWidget {
  final LocalStorageRepository repository;
  final ThemeProvider themeProvider;
  final QuickActionsService quickActionsService;

  const ZentraApp({
    required this.repository,
    required this.themeProvider,
    required this.quickActionsService,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Repository provider (shared)
        Provider<LocalStorageRepository>.value(value: repository),
        // Theme provider
        ChangeNotifierProvider<ThemeProvider>.value(value: themeProvider),
        // Auth provider
        ChangeNotifierProvider(
          create: (context) => AuthProvider()..initialize(),
        ),
        // Habit provider with repository
        ChangeNotifierProvider(
          create: (context) => HabitProvider(repository),
        ),
        // User provider
        ChangeNotifierProvider(
          create: (context) => UserProvider(),
        ),
        // Pomodoro provider
        ChangeNotifierProvider(
          create: (context) => PomodoroProvider(),
        ),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'Zentra',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.flutterThemeMode,
            home: AuthWrapper(quickActionsService: quickActionsService),
          );
        },
      ),
    );
  }
}

/// Wrapper that shows auth screen or main app based on auth state
class AuthWrapper extends StatefulWidget {
  final QuickActionsService quickActionsService;
  
  const AuthWrapper({required this.quickActionsService, super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> with WidgetsBindingObserver {
  String? _lastUserId;
  bool? _onboardingCompleted;
  bool _wasInBackground = false; // Track if app was in background

  @override
  void initState() {
    super.initState();
    // Setup Quick Actions callback
    widget.quickActionsService.onActionSelected = _handleQuickAction;
    // Setup notification tap callback
    NotificationService.onNotificationTap = _handleNotificationTap;
    // Check onboarding status
    _checkOnboardingStatus();
    // Listen to app lifecycle changes
    WidgetsBinding.instance.addObserver(this);
    // Check if app was launched from a notification
    _checkPendingNotification();
    // Check if app was launched from foreground service notification
    _checkForegroundServiceLaunch();
  }
  
  Future<void> _checkForegroundServiceLaunch() async {
    // Wait for app to be ready
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Check if app was launched from widget action - don't navigate to Pomodoro
      final prefs = await SharedPreferences.getInstance();
      final launchedFromWidget = prefs.getBool('launched_from_widget') ?? false;
      if (launchedFromWidget) {
        // Clear the flag and don't navigate to Pomodoro
        await prefs.remove('launched_from_widget');
        return;
      }
      
      // If foreground service is running, navigate to Pomodoro
      final isRunning = await FlutterForegroundTask.isRunningService;
      if (isRunning && mounted) {
        _navigateToPomodoro();
      }
    });
  }
  
  void _navigateToPomodoro() {
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const PomodoroScreen()),
      (route) => route.isFirst,
    );
  }
  
  void _checkPendingNotification() {
    // Check after a short delay to ensure navigation is ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 500), () {
        final payload = NotificationService.consumePendingNotificationPayload();
        if (payload != null) {
          _handleNotificationTap(payload);
        }
      });
    });
  }
  
  void _handleNotificationTap(String? payload) {
    if (payload == 'pomodoro') {
      // Navigate to Pomodoro screen, removing any existing routes until we reach home
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        
        // Pop all routes until we're at the root, then push Pomodoro
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const PomodoroScreen()),
          (route) => route.isFirst, // Keep only the first route (home)
        );
      });
    }
  }
  
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    final pomodoroProvider = context.read<PomodoroProvider>();
    
    if (state == AppLifecycleState.resumed) {
      // App came to foreground - recalculate timer and clean up notifications
      pomodoroProvider.onAppResumed();
      pomodoroProvider.setAppInForeground(true);
      pomodoroProvider.cleanupStaleNotifications();
      
      // If app was in background and pomodoro was recently active,
      // user likely tapped the notification - navigate to Pomodoro
      if (_wasInBackground) {
        final isRunning = await FlutterForegroundTask.isRunningService;
        // Navigate if service is running OR if pomodoro was recently active
        if ((isRunning || PomodoroProvider.wasRecentlyActive) && mounted) {
          _navigateToPomodoro();
          PomodoroProvider.wasRecentlyActive = false; // Reset flag after navigation
        }
      }
      _wasInBackground = false;
    } else if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      // App went to background
      pomodoroProvider.setAppInForeground(false);
      _wasInBackground = true;
    } else if (state == AppLifecycleState.detached) {
      // App is being terminated - cancel notifications if timer not running
      if (pomodoroProvider.state != PomodoroState.running) {
        pomodoroProvider.cleanupStaleNotifications();
      }
    }
  }

  Future<void> _checkOnboardingStatus() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _onboardingCompleted = prefs.getBool('onboarding_completed') ?? false;
    });
  }

  void _handleQuickAction(String action) {
    // Wait for context to be ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      
      switch (action) {
        case QuickActionsService.newHabitAction:
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const HabitFormScreen()),
          );
          break;
        case QuickActionsService.pomodoroAction:
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const PomodoroScreen()),
          );
          break;
        case QuickActionsService.progressAction:
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const ProgressScreen()),
          );
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        // Show splash screen while checking auth state or onboarding status
        if (authProvider.state == AuthState.initial ||
            authProvider.state == AuthState.loading ||
            _onboardingCompleted == null) {
          return const SplashScreen();
        }

        // Show main app if authenticated
        if (authProvider.isAuthenticated) {
          final currentUserId = authProvider.currentUser?.id;
          final needsReload = authProvider.needsDataReload;
          
          // Clear the flag immediately to prevent multiple reloads
          if (needsReload) {
            authProvider.clearNeedsDataReload();
          }
          
          // If user changed OR data needs reload (after import), reload all data
          if (_lastUserId != currentUserId || needsReload) {
            _lastUserId = currentUserId;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _loadUserData(context, currentUserId, isImporting: needsReload);
              // Check for pending quick action
              _checkPendingQuickAction();
            });
          }
          
          // Show onboarding for new users
          if (_onboardingCompleted == false) {
            return OnboardingScreen(
              onComplete: () {
                setState(() => _onboardingCompleted = true);
              },
            );
          }
          
          return const TodayScreen();
        }

        // Reset last user on logout
        if (_lastUserId != null) {
          _lastUserId = null;
        }
        // Show auth screen
        return const AuthScreen();
      },
    );
  }
  
  void _checkPendingQuickAction() {
    final pending = widget.quickActionsService.pendingAction;
    if (pending != null) {
      widget.quickActionsService.clearPendingAction();
      _handleQuickAction(pending);
    }
  }

  /// Load all user-specific data
  Future<void> _loadUserData(BuildContext context, String? userId, {bool isImporting = false}) async {
    final repository = context.read<LocalStorageRepository>();
    final habitProvider = context.read<HabitProvider>();
    final userProvider = context.read<UserProvider>();
    final pomodoroProvider = context.read<PomodoroProvider>();
    // Set current user in repository for user-specific storage
    repository.setCurrentUser(userId);

    // Reload all providers with user-specific data
    // Pass isImporting to prevent celebration dialogs during backup import
    await habitProvider.setCurrentUser(userId, isImporting: isImporting);
    await userProvider.loadProfile(userId: userId);
    await pomodoroProvider.setCurrentUser(userId);
    
    // Clean up any stale pomodoro notifications from previous sessions
    await pomodoroProvider.cleanupStaleNotifications();
  }
}
