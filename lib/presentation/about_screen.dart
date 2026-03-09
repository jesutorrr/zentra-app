import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io';
import 'support_screen.dart';

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
        title: const Text('¡Encontraste el secreto!'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Gracias por ser curioso/a.\n\n'
              'Esta app fue hecha con mucho café y algo de caos creativo.\n\n'
              '¡Sigue construyendo buenos hábitos!',
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16),
            Text('¡Éxito!', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('¡Genial!'),
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
        'subject': 'Feedback - Zentra v$_version',
        'body': '\n\n---\nEscribe tu feedback arriba de esta línea\n---',
      },
    );

    try {
      await launchUrl(emailUri, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo abrir el correo. ¿Tienes una app de correo instalada?')),
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
        'subject': 'Bug Report - Zentra v$_version',
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
          const SnackBar(content: Text('No se pudo abrir el correo. ¿Tienes una app de correo instalada?')),
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Logo con easter egg
            GestureDetector(
              onTap: _onLogoTap,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      colorScheme.primary,
                      colorScheme.primary.withValues(alpha: 0.7),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.primary.withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Center(
                  child: Text(
                    'Z',
                    style: TextStyle(
                      fontSize: 52,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Versión debajo del logo
            Text(
              'v$_version',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Historia
            _StoryCard(isDark: isDark, colorScheme: colorScheme),
            
            const SizedBox(height: 24),
            
            // Botones de acción
            _ActionButton(
              icon: Icons.favorite_rounded,
              label: 'Apoyar el desarrollo',
              subtitle: 'Ayuda a mantener la app gratis',
              color: Colors.pink,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SupportScreen()),
                );
              },
            ),
            const SizedBox(height: 12),
            _ActionButton(
              icon: Icons.chat_bubble_outline_rounded,
              label: 'Enviar feedback',
              subtitle: 'Cuéntame qué te gustaría mejorar',
              color: colorScheme.primary,
              onTap: _sendFeedback,
            ),
            const SizedBox(height: 12),
            _ActionButton(
              icon: Icons.bug_report_outlined,
              label: 'Reportar un bug',
              subtitle: 'Ayúdame a mejorar la app',
              color: Colors.orange,
              onTap: _reportBug,
            ),
            
            const SizedBox(height: 32),
            
            // Links sociales (opcional)
            Text(
              'Hecho con 💚 para personas que quieren mejorar',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.5),
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 48),
          ],
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
            'Hola, soy el creador 👋',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text.rich(
            TextSpan(
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                height: 1.6,
                color: colorScheme.onSurface.withValues(alpha: 0.8),
              ),
              children: [
                const TextSpan(
                  text: 'Tengo TDAH y las rutinas diarias siempre han sido un reto para mí: '
                      '¿tomé agua? ¿ya me tomé el medicamento? ¿o lo hice dos veces?\n\n'
                      'Y por eso Zentra es ',
                ),
                TextSpan(
                  text: 'TOTALMENTE GRATIS',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                ),
                const TextSpan(
                  text: ' y siempre lo será.\n\n'
                      'Si quieres apoyar el proyecto, increíble. Si no, úsala sin problema.',
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Be Kind como firma centrada
          Center(
            child: Text(
              'Be Kind 💚',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.primary,
                letterSpacing: 0.5,
              ),
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
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.subtitle,
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
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
