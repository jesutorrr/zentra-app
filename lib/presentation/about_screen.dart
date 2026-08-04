import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io';
import '../core/constants.dart';
import 'design_tokens.dart';
import 'widgets/ambient_background.dart';
import 'widgets/responsive_layout.dart';

/// Pantalla "Sobre la app" - Historia, feedback y más
class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  String _version = '';
  String _buildNumber = '';
  int _logoTapCount = 0;
  bool _easterEggFound = false;

  @override
  void initState() {
    super.initState();
    _loadPackageInfo();
  }

  Future<void> _loadPackageInfo() async {
    final info = await PackageInfo.fromPlatform();
    if (!mounted) return;
    setState(() {
      _version = info.version;
      _buildNumber = info.buildNumber;
    });
  }

  void _onLogoTap() {
    _logoTapCount++;
    if (_logoTapCount >= 7 && !_easterEggFound) {
      setState(() => _easterEggFound = true);
      HapticFeedback.heavyImpact();
      _showEasterEgg();
    } else if (_logoTapCount < 7) {
      HapticFeedback.lightImpact();
    }
  }

  void _showEasterEgg() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Secreto encontrado'),
        content: const Text(
          'Zentra empezó como una herramienta personal. '
          'Siete toques después, sigue siendo simple a propósito.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  Future<void> _sendFeedback() async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: 'unbobosaurio@gmail.com',
      queryParameters: {
        'subject': 'Comentarios - Zentra v$_version',
        'body': '\n\n---\nEscribe tu feedback arriba de esta línea\n---',
      },
    );

    try {
      await launchUrl(emailUri, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'No se pudo abrir el correo. ¿Tienes una app de correo instalada?',
            ),
          ),
        );
      }
    }
  }

  Future<void> _reportBug() async {
    // Obtener info del dispositivo
    String deviceInfo = '';
    try {
      if (Platform.isIOS) {
        final iosInfo = await DeviceInfoPlugin().iosInfo;
        deviceInfo = '''
Dispositivo: ${iosInfo.model}
iOS: ${iosInfo.systemVersion}
''';
      } else if (Platform.isAndroid) {
        final androidInfo = await DeviceInfoPlugin().androidInfo;
        deviceInfo = '''
Dispositivo: ${androidInfo.model}
Android: ${androidInfo.version.release}
''';
      }
    } catch (e) {
      deviceInfo = 'No se pudo obtener info del dispositivo';
    }

    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: 'unbobosaurio@gmail.com',
      queryParameters: {
        'subject': 'Reporte de error - Zentra v$_version',
        'body': '''
Describe el bug:


Pasos para reproducirlo:
1. 
2. 
3. 

¿Qué esperabas que pasara?


---
Info técnica (no borrar):
App: Zentra v$_version (build $_buildNumber)
$deviceInfo---
''',
      },
    );

    try {
      await launchUrl(emailUri, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'No se pudo abrir el correo. ¿Tienes una app de correo instalada?',
            ),
          ),
        );
      }
    }
  }

  Future<void> _openPrivacyPolicy() async {
    try {
      final launched = await launchUrl(
        Uri.parse(kPrivacyPolicyUrl),
        mode: LaunchMode.externalApplication,
      );
      if (!launched) {
        throw const FormatException('Privacy policy URL could not be opened');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudo abrir la política de privacidad.'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Zentra'),
      ),
      body: ResponsiveContentFrame(
        child: ZentraAmbientBackground(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                GestureDetector(
                  onTap: _onLogoTap,
                  child: Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          colorScheme.primary,
                          context.zentraPalette.water,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: colorScheme.primary.withValues(alpha: 0.3),
                          blurRadius: 24,
                          spreadRadius: -4,
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Text(
                        'Z',
                        style: TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'v$_version',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 24),
                _StoryCard(isDark: isDark, colorScheme: colorScheme),
                const SizedBox(height: 20),
                _ActionButton(
                  icon: Icons.chat_bubble_outline_rounded,
                  label: 'Enviar feedback',
                  color: colorScheme.primary,
                  onTap: _sendFeedback,
                ),
                const SizedBox(height: 10),
                _ActionButton(
                  icon: Icons.bug_report_outlined,
                  label: 'Reportar un bug',
                  color: context.zentraPalette.movement,
                  onTap: _reportBug,
                ),
                const SizedBox(height: 10),
                _ActionButton(
                  icon: Icons.privacy_tip_outlined,
                  label: 'Política de privacidad',
                  color: context.zentraPalette.sleep,
                  onTap: _openPrivacyPolicy,
                ),
                const SizedBox(height: 28),
                Text(
                  'Gratis. Sin anuncios. Sin suscripciones.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Card con la historia personal
class _StoryCard extends StatelessWidget {
  final bool isDark;
  final ColorScheme colorScheme;

  const _StoryCard({required this.isDark, required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark
            ? colorScheme.surface.withValues(alpha: 0.5)
            : colorScheme.primaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colorScheme.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Por qué existe',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          Text(
            'Tengo TDAH y necesitaba una forma clara de registrar hábitos, '
            'enfoque y notas sin convertir el día en un tablero de métricas.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  height: 1.5,
                  color: colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 12),
          Text(
            'Zentra es gratis y seguirá enfocada en eso.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: colorScheme.primary,
                ),
          ),
        ],
      ),
    );
  }
}

/// Botón de acción estilizado
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark
                ? color.withValues(alpha: 0.15)
                : color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: color.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
