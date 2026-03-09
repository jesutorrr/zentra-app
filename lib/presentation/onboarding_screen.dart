import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import '../infrastructure/notification_service.dart';
import 'utils/feedback_utils.dart';

/// Pantalla de onboarding para nuevos usuarios
class OnboardingScreen extends StatefulWidget {
  final VoidCallback onComplete;
  
  const OnboardingScreen({required this.onComplete, super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _isCompleting = false; // Prevent double completion
  bool _notificationsGranted = false;
  bool _alarmsGranted = false;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    final notificationService = NotificationService();
    // Usamos la verificación del sistema para saber si realmente tenemos permiso,
    // no solo si el usuario dijo "sí" en la app previamente.
    final notifications = await notificationService.isSystemNotificationPermissionGranted();
    final alarms = await notificationService.canScheduleExactAlarms();
    
    if (mounted) {
      setState(() {
        _notificationsGranted = notifications;
        _alarmsGranted = alarms;
      });
    }
  }

  // Simplified onboarding: Welcome → Permissions → Ready
  final List<_OnboardingPage> _pages = [
    _OnboardingPage(
      icon: Icons.waving_hand_rounded,
      title: '¡Hola!',
      subtitle: 'Bienvenido a Zentra',
      description: 'Una app simple para construir mejores rutinas.\n\nSin complicaciones. Sin suscripciones.',
    ),
    _OnboardingPage(
      icon: Icons.notifications_rounded,
      title: 'Mantente al día',
      subtitle: 'Activa las notificaciones',
      description: 'Te enviaremos recordatorios para que no olvides tus hábitos y sesiones de enfoque.',
      isQuestion: true,
      questionType: 'permissions',
    ),
    _OnboardingPage(
      icon: Icons.rocket_launch_rounded,
      title: '¡Listo!',
      subtitle: 'Estás a punto de empezar',
      description: 'Recuerda: no se trata de ser perfecto.\nSe trata de ser un poco mejor cada día.\n\n¡Vamos a ello!',
    ),
  ];

  void _nextPage() {
    HapticFeedback.lightImpact();
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
      );
    } else {
      _completeOnboarding();
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
      );
    }
  }

  Future<void> _completeOnboarding() async {
    // Prevent double completion
    if (_isCompleting) return;
    _isCompleting = true;
    
    HapticFeedback.mediumImpact();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completed', true);
    widget.onComplete();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Premium page indicator
            Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: SmoothPageIndicator(
                  controller: _pageController,
                  count: _pages.length,
                  effect: ExpandingDotsEffect(
                    activeDotColor: colorScheme.primary,
                    dotColor: colorScheme.primary.withValues(alpha: 0.2),
                    dotHeight: 8,
                    dotWidth: 8,
                    expansionFactor: 4,
                    spacing: 8,
                  ),
                ),
              ),
            ),

            // Pages
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) => setState(() => _currentPage = index),
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _pages.length,
                itemBuilder: (context, index) {
                  final page = _pages[index];
                  return _buildPage(page, isDark, colorScheme);
                },
              ),
            ),

            // Navigation buttons
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  if (_currentPage > 0)
                    TextButton(
                      onPressed: _previousPage,
                      child: const Text('Atrás'),
                    )
                  else
                    const SizedBox(width: 80),
                  
                  const Spacer(),
                  
                  FilledButton(
                    onPressed: _canProceed() ? _nextPage : null,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      _currentPage == _pages.length - 1 ? '¡Empezar!' : 'Siguiente',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _canProceed() {
    // All pages can proceed (permissions page doesn't block)
    return true;
  }

  Widget _buildPage(_OnboardingPage page, bool isDark, ColorScheme colorScheme) {
    if (page.isQuestion && page.questionType == 'permissions') {
      return _buildPermissionsPage(page, isDark, colorScheme);
    }
    return _buildInfoPage(page, isDark, colorScheme);
  }

  Widget _buildInfoPage(_OnboardingPage page, bool isDark, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(page.icon, size: 80, color: colorScheme.primary)
              .animate()
              .scale(begin: const Offset(0.5, 0.5), duration: 500.ms, curve: Curves.elasticOut),
          const SizedBox(height: 32),
          Text(
            page.title,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.3),
          const SizedBox(height: 8),
          Text(
            page.subtitle,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: colorScheme.primary,
            ),
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 300.ms),
          const SizedBox(height: 24),
          Text(
            page.description,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.7),
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 400.ms),
        ],
      ),
    );
  }

  Widget _buildPermissionsPage(_OnboardingPage page, bool isDark, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(page.icon, size: 80, color: colorScheme.primary)
              .animate()
              .scale(begin: const Offset(0.5, 0.5), duration: 500.ms, curve: Curves.elasticOut),
          const SizedBox(height: 32),
          Text(
            page.title,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            page.subtitle,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: colorScheme.primary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            page.description,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Puedes continuar sin activarlas ahora y cambiarlas más tarde en Configuración.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.6),
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
          _PermissionButton(
            icon: Icons.notifications_active_rounded,
            title: 'Notificaciones',
            subtitle: 'Para no olvidar tus hábitos',
            isGranted: _notificationsGranted,
            onTap: () async {
              final notificationService = NotificationService();
              // Usar método específico para notificaciones
              final granted = await notificationService.requestNotificationPermission();
              // Actualizar estado basado en el resultado y verificación del sistema
              if (granted) {
                await notificationService.setNotificationsEnabled(true);
              }
              final isSystemGranted = await notificationService.isSystemNotificationPermissionGranted();
              
              if (mounted) {
                setState(() => _notificationsGranted = isSystemGranted);
                if (isSystemGranted) triggerHaptic(HapticType.success);
              }
            },
          ).animate().fadeIn(delay: 200.ms).slideX(begin: -0.2),
          
          if (Platform.isAndroid) ...[
            const SizedBox(height: 16),
            _PermissionButton(
              icon: Icons.alarm_on_rounded,
              title: 'Alarmas exactas',
              subtitle: 'Para que el Pomodoro sea preciso',
              isGranted: _alarmsGranted,
              onTap: () async {
                final notificationService = NotificationService();
                // Usar método específico para alarmas
                await notificationService.requestExactAlarmsPermission();
                
                // Verificar estado real después de la solicitud
                final isSystemGranted = await notificationService.canScheduleExactAlarms();
                
                if (mounted) {
                  setState(() => _alarmsGranted = isSystemGranted);
                  if (isSystemGranted) triggerHaptic(HapticType.success);
                }
              },
            ).animate().fadeIn(delay: 400.ms).slideX(begin: -0.2),
          ],
        ],
      ),
    );
  }
}

class _PermissionButton extends StatefulWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isGranted;
  final Future<void> Function() onTap;

  const _PermissionButton({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isGranted,
    required this.onTap,
  });

  @override
  State<_PermissionButton> createState() => _PermissionButtonState();
}

class _PermissionButtonState extends State<_PermissionButton> {
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isGranted = widget.isGranted;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: (isGranted || _loading) ? null : () async {
          setState(() => _loading = true);
          await widget.onTap();
          if (mounted) setState(() => _loading = false);
        },
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isGranted 
                ? colorScheme.primary.withValues(alpha: 0.15)
                : (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03)),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isGranted 
                  ? colorScheme.primary
                  : (isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.1)),
              width: isGranted ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isGranted 
                      ? colorScheme.primary 
                      : colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isGranted ? Icons.check_rounded : widget.icon,
                  color: isGranted ? colorScheme.onPrimary : colorScheme.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isGranted ? colorScheme.primary : null,
                      ),
                    ),
                    Text(
                      widget.subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
              if (_loading)
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else if (!isGranted)
                Icon(Icons.arrow_forward_ios_rounded, color: colorScheme.onSurface.withValues(alpha: 0.3), size: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _OnboardingPage {
  final IconData icon;
  final String title;
  final String subtitle;
  final String description;
  final bool isQuestion;
  final String? questionType;

  _OnboardingPage({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.description,
    this.isQuestion = false,
    this.questionType,
  });
}
