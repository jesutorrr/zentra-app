import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../application/auth_provider.dart';
import '../application/habit_provider.dart';
import '../application/user_provider.dart';
import '../application/pomodoro_provider.dart';
import '../infrastructure/local_storage_repository.dart';
import 'theme.dart';
import 'widgets/emoji_selector.dart';
import 'today_screen.dart';
import 'utils/page_transitions.dart';

/// Authentication screen (Login/Register)
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _isLogin = false; // Start with register for new users
  bool _wantsNewAccount = false; // User explicitly wants to create new account
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isSubmitting = false; // Prevent double submit
  
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  String _selectedEmoji = '😊';

  @override
  void initState() {
    super.initState();
    // Check if user has account and clear any stale errors
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = context.read<AuthProvider>();
      authProvider.clearError(); // Clear any previous error
      if (authProvider.hasAccount) {
        setState(() => _isLogin = true);
      }
    });
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Consumer<AuthProvider>(
                builder: (context, authProvider, child) {
                  // If has account and user hasn't explicitly requested new account, show login
                  if (authProvider.hasAccount && !_isLogin && !_wantsNewAccount) {
                    _isLogin = true;
                  }

                  return Form(
                    key: _formKey,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Extra top padding for notch/Dynamic Island
                        const SizedBox(height: 20),
                        
                        // Logo/Avatar - animated
                        Center(
                          child: Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              gradient: AppTheme.cardGradient(colorScheme, isDark),
                              shape: BoxShape.circle,
                              border: AppTheme.cardGradientBorder(colorScheme, isDark),
                            ),
                            child: Center(
                              child: Text(
                                _isLogin ? '👋' : _selectedEmoji,
                                style: const TextStyle(fontSize: 48),
                              ),
                            ),
                          ),
                        )
                            .animate()
                            .fadeIn(duration: 400.ms)
                            .scale(begin: const Offset(0.8, 0.8), curve: Curves.easeOutBack),
                        const SizedBox(height: 32),

                        // Title - animated
                        Text(
                          _isLogin ? '¡Bienvenido de nuevo!' : '¡Crea tu cuenta!',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                          textAlign: TextAlign.center,
                        )
                            .animate()
                            .fadeIn(delay: 100.ms, duration: 400.ms)
                            .slideY(begin: 0.2, end: 0, curve: Curves.easeOut),
                        const SizedBox(height: 8),
                        Text(
                          _isLogin
                              ? 'Inicia sesión para continuar'
                              : 'Registrate para comenzar tu viaje',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                          textAlign: TextAlign.center,
                        )
                            .animate()
                            .fadeIn(delay: 200.ms, duration: 400.ms),
                        const SizedBox(height: 32),

                        // Error message - with shake animation
                        if (authProvider.error != null)
                          Container(
                            padding: const EdgeInsets.all(12),
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: colorScheme.errorContainer,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.error_outline,
                                  color: colorScheme.onErrorContainer,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    authProvider.error!,
                                    style: TextStyle(
                                      color: colorScheme.onErrorContainer,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(
                                    Icons.close,
                                    size: 18,
                                    color: colorScheme.onErrorContainer,
                                  ),
                                  onPressed: authProvider.clearError,
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                ),
                              ],
                            ),
                          )
                              .animate()
                              .fadeIn(duration: 200.ms)
                              .shakeX(hz: 4, amount: 4, duration: 400.ms),

                        // Register-only fields
                        if (!_isLogin) ...[
                          // Avatar selector
                          LabeledEmojiSelector(
                            label: 'Elige tu avatar',
                            selectedEmoji: _selectedEmoji,
                            onEmojiSelected: (emoji) {
                              setState(() => _selectedEmoji = emoji);
                            },
                          ),
                          const SizedBox(height: 24),

                          // Username field
                          TextFormField(
                            controller: _usernameController,
                            decoration: InputDecoration(
                              labelText: 'Nombre de usuario',
                              hintText: 'Tu nombre',
                              prefixIcon: const Icon(Icons.person_outline),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            textCapitalization: TextCapitalization.words,
                            textInputAction: TextInputAction.next,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Ingresa tu nombre';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Email field
                        TextFormField(
                          controller: _emailController,
                          decoration: InputDecoration(
                            labelText: 'Correo electrónico',
                            hintText: 'tu@email.com',
                            prefixIcon: const Icon(Icons.email_outlined),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Ingresa tu correo';
                            }
                            if (!value.contains('@')) {
                              return 'Ingresa un correo válido';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Password field
                        TextFormField(
                          controller: _passwordController,
                          decoration: InputDecoration(
                            labelText: 'Contraseña',
                            hintText: '••••••••',
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                              ),
                              onPressed: () {
                                setState(() => _obscurePassword = !_obscurePassword);
                              },
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          obscureText: _obscurePassword,
                          textInputAction: _isLogin
                              ? TextInputAction.done
                              : TextInputAction.next,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Ingresa tu contraseña';
                            }
                            if (!_isLogin && value.length < 6) {
                              return 'Mínimo 6 caracteres';
                            }
                            return null;
                          },
                          onFieldSubmitted: _isLogin ? (_) => _submit() : null,
                        ),

                        // Confirm password (register only)
                        if (!_isLogin) ...[
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _confirmPasswordController,
                            decoration: InputDecoration(
                              labelText: 'Confirmar contraseña',
                              hintText: '••••••••',
                              prefixIcon: const Icon(Icons.lock_outline),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscureConfirmPassword
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                ),
                                onPressed: () {
                                  setState(() =>
                                      _obscureConfirmPassword = !_obscureConfirmPassword,);
                                },
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            obscureText: _obscureConfirmPassword,
                            textInputAction: TextInputAction.done,
                            validator: (value) {
                              if (value != _passwordController.text) {
                                return 'Las contraseñas no coinciden';
                              }
                              return null;
                            },
                            onFieldSubmitted: (_) => _submit(),
                          ),
                        ],

                        const SizedBox(height: 24),

                        // Submit button
                        FilledButton(
                          onPressed: authProvider.state == AuthState.loading
                              ? null
                              : _submit,
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: authProvider.state == AuthState.loading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  _isLogin ? 'Iniciar Sesión' : 'Crear Cuenta',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),

                        // Import backup button - ALWAYS visible
                        // In register view OR in login view as alternative
                        const SizedBox(height: 16),
                        OutlinedButton.icon(
                          onPressed: _importBackup,
                          icon: const Icon(Icons.upload_file_outlined),
                          label: Text(_isLogin 
                              ? 'Restaurar otro usuario desde backup' 
                              : 'Restaurar desde backup',),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),

                        // Toggle login/register (only if no account OR user wants new account)
                        if (!authProvider.hasAccount || _wantsNewAccount) ...[
                          const SizedBox(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _isLogin
                                    ? '¿No tienes cuenta? '
                                    : '¿Ya tienes cuenta? ',
                                style: theme.textTheme.bodyMedium,
                              ),
                              TextButton(
                                onPressed: () {
                                  setState(() {
                                    _isLogin = !_isLogin;
                                    if (_isLogin) _wantsNewAccount = false;
                                  });
                                  authProvider.clearError();
                                },
                                child: Text(
                                  _isLogin ? 'Regístrate' : 'Inicia sesión',
                                  style: const TextStyle(fontWeight: FontWeight.w600),
                                ),
                              ),
                            ],
                          ),
                        ],

                        // Option to create new user (if user has account but wants to create another)
                        if (authProvider.hasAccount && _isLogin && !_wantsNewAccount) ...[
                          const SizedBox(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '¿Quieres otra cuenta? ',
                                style: theme.textTheme.bodyMedium,
                              ),
                              TextButton(
                                onPressed: () {
                                  setState(() {
                                    _isLogin = false;
                                    _wantsNewAccount = true;
                                  });
                                  authProvider.clearError();
                                },
                                child: const Text(
                                  'Crear nuevo usuario',
                                  style: TextStyle(fontWeight: FontWeight.w600),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    // Prevent double submit
    if (_isSubmitting) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    
    HapticFeedback.mediumImpact();
    final authProvider = context.read<AuthProvider>();

    bool success = false;
    try {
      if (_isLogin) {
        success = await authProvider.login(
          email: _emailController.text,
          password: _passwordController.text,
        );
      } else {
        success = await authProvider.register(
          username: _usernameController.text,
          email: _emailController.text,
          password: _passwordController.text,
          avatarEmoji: _selectedEmoji,
        );
      }
      
      // Navigate to home on success
      if (success && mounted) {
        // Load user data
        final userId = authProvider.currentUser?.id;
        if (userId != null) {
          final repository = context.read<LocalStorageRepository>();
          final habitProvider = context.read<HabitProvider>();
          final userProvider = context.read<UserProvider>();
          final pomodoroProvider = context.read<PomodoroProvider>();
          
          repository.setCurrentUser(userId);
          await habitProvider.loadHabits();
          await userProvider.loadProfile();
          await pomodoroProvider.setCurrentUser(userId);
        }
        
        if (!mounted) return;
        
        // Elegant transition to home
        Navigator.of(context).pushAndRemoveUntil(
          PageTransitions.scaleUp(const TodayScreen()),
          (route) => false,
        );
      }
    } finally {
      if (mounted && !success) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _importBackup() async {
    HapticFeedback.lightImpact();
    final authProvider = context.read<AuthProvider>();
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    
    final success = await authProvider.importBackup();
    
    if (success == true && mounted) {
      // Load user data before navigating
      final userId = authProvider.currentUser?.id;
      
      final repository = context.read<LocalStorageRepository>();
      final habitProvider = context.read<HabitProvider>();
      final userProvider = context.read<UserProvider>();
      final pomodoroProvider = context.read<PomodoroProvider>();
      
      repository.setCurrentUser(userId);
      await habitProvider.setCurrentUser(userId);
      await userProvider.loadProfile(userId: userId);
      await pomodoroProvider.setCurrentUser(userId);
      
      if (mounted) {
        scaffoldMessenger.showSnackBar(
          const SnackBar(
            content: Text('¡Backup restaurado exitosamente!'),
            backgroundColor: AppTheme.successGreen,
          ),
        );
        
        // Navigate to TodayScreen replacing the current route
        navigator.pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const TodayScreen()),
          (route) => false,
        );
      }
    }
  }
}
