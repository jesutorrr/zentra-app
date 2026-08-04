import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/session_controller.dart';
import '../domain/auth_models.dart';
import '../domain/cloud_auth_gateway.dart';
import 'design_tokens.dart';
import 'motion_policy.dart';
import 'utils/backup_passphrase_dialog.dart';
import 'widgets/responsive_layout.dart';

enum _AccessMode {
  choices,
  backup,
}

/// Local-first entry to Zentra.
///
/// A cloud identity is intentionally not presented as an available action
/// until a real provider is connected end to end.
class ClassicAuthScreen extends ConsumerStatefulWidget {
  const ClassicAuthScreen({super.key});

  @override
  ConsumerState<ClassicAuthScreen> createState() => _ClassicAuthScreenState();
}

class _ClassicAuthScreenState extends ConsumerState<ClassicAuthScreen> {
  final _scrollController = ScrollController();

  _AccessMode _mode = _AccessMode.choices;
  BackupData? _selectedBackup;
  bool _isWorking = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(sessionControllerProvider.notifier).clearError();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          const _AccessBackground(),
          SafeArea(
            child: ResponsiveLayoutBuilder(
              builder: (context, layout) {
                final textIsLarge =
                    MediaQuery.textScalerOf(context).scale(16) > 22;
                final useTwoPane =
                    layout.width >= 700 && !layout.isShort && !textIsLarge;
                final verticalPadding = layout.verticalPagePadding;
                final availableHeight = (layout.height - (verticalPadding * 2))
                    .clamp(0.0, double.infinity);

                return SingleChildScrollView(
                  key: const ValueKey('auth-scroll-view'),
                  controller: _scrollController,
                  padding: EdgeInsets.symmetric(
                    horizontal: layout.horizontalPagePadding,
                    vertical: verticalPadding,
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: availableHeight),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1120),
                        child: useTwoPane
                            ? Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  const Expanded(child: _AccessBrandPanel()),
                                  SizedBox(width: context.spacing.xl),
                                  Flexible(
                                    child: Align(
                                      alignment: Alignment.center,
                                      child: ConstrainedBox(
                                        constraints:
                                            const BoxConstraints(maxWidth: 500),
                                        child: _buildEntryPanel(
                                          context,
                                          colorScheme,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            : ResponsiveContentFrame(
                                maxWidth: 560,
                                alignment: Alignment.center,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    if (_mode == _AccessMode.choices) ...[
                                      const _CompactAccessIntro(),
                                      SizedBox(height: context.spacing.lg),
                                    ],
                                    _buildEntryPanel(context, colorScheme),
                                  ],
                                ),
                              ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEntryPanel(
    BuildContext context,
    ColorScheme colorScheme,
  ) {
    final session =
        ref.watch(sessionControllerProvider).valueOrNull ?? SessionState();
    final motion = context.motionPolicy;

    return Container(
      key: const ValueKey('auth-form-panel'),
      width: double.infinity,
      padding: EdgeInsets.all(context.spacing.lg),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(context.radii.extraLarge),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.72),
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.07),
            blurRadius: 36,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (session.error != null) ...[
            _ErrorBanner(
              message: session.error!,
              onClose: ref.read(sessionControllerProvider.notifier).clearError,
            ),
            SizedBox(height: context.spacing.md),
          ],
          AnimatedSwitcher(
            duration: motion.duration(const Duration(milliseconds: 220)),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            child: switch (_mode) {
              _AccessMode.choices => _buildChoices(),
              _AccessMode.backup => _buildBackup(),
            },
          ),
        ],
      ),
    );
  }

  Widget _buildChoices() {
    final cloudAuthGateway = ref.watch(cloudAuthGatewayProvider);
    final availableCloudProviders =
        cloudAuthGateway?.availableProviders ?? const <CloudAuthProvider>{};
    final showGoogle =
        availableCloudProviders.contains(CloudAuthProvider.google);
    final showApple =
        availableCloudProviders.contains(CloudAuthProvider.apple) &&
            !kIsWeb &&
            defaultTargetPlatform == TargetPlatform.iOS;
    final cloudAuthAvailable = showGoogle || showApple;
    final cloudAuthStartupError = ref.watch(cloudAuthStartupErrorProvider);

    return Column(
      key: const ValueKey('auth-choices'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _EntryHeading(
          eyebrow: 'ELIGE CÓMO EMPEZAR',
          title: 'Tu espacio comienza aquí.',
          description:
              'Puedes usar todas las funciones sin crear una cuenta en línea.',
        ),
        SizedBox(height: context.spacing.lg),
        _AccessPathCard(
          key: const ValueKey('auth-local-path'),
          icon: Icons.shield_outlined,
          title: 'Usar en este dispositivo',
          subtitle: 'Sin cuenta. Todas las funciones.',
          isPrimary: true,
          onTap: _isWorking ? null : _continueLocally,
        ),
        SizedBox(height: context.spacing.sm),
        _AccessPathCard(
          key: const ValueKey('auth-backup-path'),
          icon: Icons.inventory_2_outlined,
          title: 'Restaurar un respaldo',
          subtitle: 'Recupera hábitos, sesiones y progreso.',
          accent: context.zentraPalette.warmPeach,
          onTap: _isWorking ? null : () => _showMode(_AccessMode.backup),
        ),
        SizedBox(height: context.spacing.md),
        if (cloudAuthAvailable)
          _CloudAuthCard(
            isWorking: _isWorking,
            showGoogle: showGoogle,
            showApple: showApple,
            onGoogle: () => _signInWithCloud(CloudAuthProvider.google),
            onApple: () => _signInWithCloud(CloudAuthProvider.apple),
          )
        else
          _GoogleFutureCard(configurationError: cloudAuthStartupError),
        SizedBox(height: context.spacing.md),
        const _PrivacyNote(),
      ],
    );
  }

  Widget _buildBackup() {
    return Column(
      key: const ValueKey('auth-backup'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _BackToChoices(onPressed: _isWorking ? null : _showChoices),
        SizedBox(height: context.spacing.sm),
        const _EntryHeading(
          eyebrow: 'RECUPERACIÓN LOCAL',
          title: 'Recupera lo que ya construiste.',
          description:
              'Elige un respaldo de Zentra. Revisarás su contenido antes de restaurarlo.',
        ),
        SizedBox(height: context.spacing.lg),
        if (_selectedBackup == null)
          _AccessPathCard(
            key: const ValueKey('auth-select-backup'),
            icon: Icons.folder_open_outlined,
            title: 'Elegir respaldo',
            subtitle: 'Archivo .json creado por Zentra.',
            accent: context.zentraPalette.warmPeach,
            onTap: _isWorking ? null : _selectBackup,
          )
        else
          _BackupPreview(
            backup: _selectedBackup!,
            isWorking: _isWorking,
            onChooseAnother: _selectBackup,
            onRestore: _confirmRestore,
          ),
        SizedBox(height: context.spacing.md),
        const _RestoreSafetyNote(),
      ],
    );
  }

  void _showMode(_AccessMode mode) {
    ref.read(sessionControllerProvider.notifier).clearError();
    setState(() => _mode = mode);
    _resetCompactScroll();
  }

  void _showChoices() {
    ref.read(sessionControllerProvider.notifier).clearError();
    setState(() {
      _mode = _AccessMode.choices;
      _selectedBackup = null;
    });
    _resetCompactScroll();
  }

  void _resetCompactScroll() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || MediaQuery.sizeOf(context).width >= 700) return;
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        0,
        duration:
            context.motionPolicy.duration(const Duration(milliseconds: 260)),
        curve: Curves.easeOutCubic,
      );
    });
  }

  Future<void> _continueLocally() async {
    if (_isWorking) return;
    setState(() => _isWorking = true);
    await ref.read(sessionControllerProvider.notifier).continueLocally();
    if (mounted) setState(() => _isWorking = false);
  }

  Future<void> _signInWithCloud(CloudAuthProvider provider) async {
    if (_isWorking) return;
    setState(() => _isWorking = true);
    await ref
        .read(sessionControllerProvider.notifier)
        .signInWithCloud(provider);
    if (mounted) setState(() => _isWorking = false);
  }

  Future<void> _selectBackup() async {
    if (_isWorking) return;
    final passphrase = await showBackupPassphraseDialog(
      context,
      purpose: BackupPassphrasePurpose.import,
    );
    if (passphrase == null || !mounted) return;
    setState(() => _isWorking = true);
    final backup = await ref
        .read(sessionControllerProvider.notifier)
        .selectBackup(passphrase: passphrase);
    if (!mounted) return;
    setState(() {
      _isWorking = false;
      if (backup != null) _selectedBackup = backup;
    });
  }

  Future<void> _confirmRestore() async {
    final backup = _selectedBackup;
    if (backup == null || _isWorking) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('¿Restaurar este respaldo?'),
          content: const Text(
            'Zentra importará estos datos y abrirá el espacio recuperado.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Restaurar'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;
    setState(() => _isWorking = true);
    await ref.read(sessionControllerProvider.notifier).restoreBackup(backup);
    if (mounted) setState(() => _isWorking = false);
  }
}

class _AccessBackground extends StatelessWidget {
  const _AccessBackground();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final palette = context.zentraPalette;

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.surface,
            palette.calmMint.withValues(alpha: 0.42),
            palette.specialSurface,
          ],
        ),
      ),
      child: Stack(
        children: [
          _ColorBubble(
            alignment: const Alignment(-1.15, -0.9),
            size: 190,
            color: palette.water,
          ),
          _ColorBubble(
            alignment: const Alignment(1.12, -0.72),
            size: 150,
            color: palette.sleep,
          ),
          _ColorBubble(
            alignment: const Alignment(1.18, 0.42),
            size: 220,
            color: palette.movement,
          ),
        ],
      ),
    );
  }
}

class _ColorBubble extends StatelessWidget {
  final Alignment alignment;
  final double size;
  final Color color;

  const _ColorBubble({
    required this.alignment,
    required this.size,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withValues(alpha: 0.055),
          border: Border.all(color: color.withValues(alpha: 0.1)),
        ),
      ),
    );
  }
}

class _CompactAccessIntro extends StatelessWidget {
  const _CompactAccessIntro();

  @override
  Widget build(BuildContext context) {
    return const _AccessBrandContent(compact: true);
  }
}

class _AccessBrandPanel extends StatelessWidget {
  const _AccessBrandPanel();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final palette = context.zentraPalette;

    return Container(
      key: const ValueKey('auth-brand-panel'),
      constraints: const BoxConstraints(minHeight: 560),
      padding: EdgeInsets.all(context.spacing.xxl),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            palette.calmMint.withValues(alpha: 0.9),
            colorScheme.surfaceContainerLowest.withValues(alpha: 0.93),
            palette.specialSurface,
          ],
        ),
        borderRadius: BorderRadius.circular(context.radii.extraLarge),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.64),
        ),
      ),
      child: const _AccessBrandContent(compact: false),
    );
  }
}

class _AccessBrandContent extends StatelessWidget {
  final bool compact;

  const _AccessBrandContent({required this.compact});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _BrandMark(size: compact ? 52 : 68),
        SizedBox(height: compact ? context.spacing.md : context.spacing.xl),
        Text(
          'PRIVADO POR DISEÑO',
          style: theme.textTheme.labelLarge?.copyWith(
            color: colorScheme.primary,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.4,
          ),
        ),
        SizedBox(height: context.spacing.xs),
        Text(
          'Empieza a tu manera.',
          style: (compact
                  ? theme.textTheme.headlineLarge
                  : theme.textTheme.displaySmall)
              ?.copyWith(
            fontWeight: FontWeight.w800,
            height: 1.05,
            letterSpacing: -1.2,
          ),
        ),
        SizedBox(height: context.spacing.sm),
        Text(
          'Zentra funciona completa sin cuenta. Tú decides si tus datos salen de este dispositivo.',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: colorScheme.onSurfaceVariant,
            height: 1.45,
          ),
        ),
        SizedBox(height: compact ? context.spacing.md : context.spacing.xl),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _TrustChip(
              icon: Icons.cloud_off_outlined,
              label: 'Sin nube obligatoria',
            ),
            SizedBox(height: context.spacing.xs),
            const _TrustChip(
              icon: Icons.inventory_2_outlined,
              label: 'Respaldo exportable',
            ),
            SizedBox(height: context.spacing.xs),
            const _TrustChip(
              icon: Icons.auto_awesome_outlined,
              label: 'Sin perder funciones',
            ),
          ],
        ),
      ],
    );
  }
}

class _BrandMark extends StatelessWidget {
  final double size;

  const _BrandMark({required this.size});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final palette = context.zentraPalette;
    final logoBase = theme.brightness == Brightness.dark
        ? Color.alphaBlend(
            colorScheme.shadow.withValues(alpha: 0.46),
            palette.brandTeal,
          )
        : palette.brandTeal;

    return Semantics(
      image: true,
      label: 'Zentra',
      child: Container(
        width: size,
        height: size,
        padding: EdgeInsets.all(size * 0.16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              logoBase,
              Color.alphaBlend(
                palette.warmPeach.withValues(alpha: 0.16),
                logoBase,
              ),
            ],
          ),
          borderRadius: BorderRadius.circular(size * 0.3),
          border: Border.all(
            color: colorScheme.onPrimary.withValues(alpha: 0.28),
          ),
          boxShadow: [
            BoxShadow(
              color: palette.brandTeal.withValues(alpha: 0.18),
              blurRadius: size * 0.3,
              offset: Offset(0, size * 0.1),
            ),
          ],
        ),
        child: Image.asset(
          'assets/images/zentra_logo_mark.png',
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) => Icon(
            Icons.spa_outlined,
            color: colorScheme.primary,
          ),
        ),
      ),
    );
  }
}

class _TrustChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _TrustChip({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: context.spacing.sm,
        vertical: context.spacing.xs,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(context.radii.pill),
        border: Border.all(
          color: colorScheme.primary.withValues(alpha: 0.16),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: colorScheme.primary),
          SizedBox(width: context.spacing.xs),
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EntryHeading extends StatelessWidget {
  final String eyebrow;
  final String title;
  final String description;

  const _EntryHeading({
    required this.eyebrow,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          eyebrow,
          style: theme.textTheme.labelLarge?.copyWith(
            color: colorScheme.primary,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.1,
          ),
        ),
        SizedBox(height: context.spacing.xs),
        Text(
          title,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
            height: 1.12,
          ),
        ),
        SizedBox(height: context.spacing.xs),
        Text(
          description,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}

class _AccessPathCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final bool isPrimary;
  final Color? accent;

  const _AccessPathCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.isPrimary = false,
    this.accent,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final effectiveAccent = accent ?? colorScheme.primary;

    return Semantics(
      button: true,
      enabled: onTap != null,
      label: '$title. $subtitle',
      child: Material(
        color: isPrimary
            ? Color.alphaBlend(
                effectiveAccent.withValues(alpha: 0.1),
                colorScheme.surfaceContainerLowest,
              )
            : colorScheme.surfaceContainerLowest,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(context.radii.large),
          side: BorderSide(
            color: effectiveAccent.withValues(alpha: isPrimary ? 0.58 : 0.28),
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 76),
            child: Padding(
              padding: EdgeInsets.all(context.spacing.md),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: effectiveAccent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(context.radii.medium),
                    ),
                    child: Icon(icon, color: effectiveAccent),
                  ),
                  SizedBox(width: context.spacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          title,
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                        ),
                        SizedBox(height: context.spacing.xxs),
                        Text(
                          subtitle,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: context.spacing.sm),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 17,
                    color: effectiveAccent,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GoogleFutureCard extends StatelessWidget {
  final String? configurationError;

  const _GoogleFutureCard({this.configurationError});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Semantics(
      key: const ValueKey('auth-google-future'),
      label:
          'Cuenta en línea no disponible en esta compilación. El modo local sigue funcionando.',
      child: Container(
        padding: EdgeInsets.all(context.spacing.sm),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerLow.withValues(alpha: 0.76),
          borderRadius: BorderRadius.circular(context.radii.medium),
          border: Border.all(
            color: colorScheme.outlineVariant,
            style: BorderStyle.solid,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(context.radii.small),
                  ),
                  child: Text(
                    'G',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                SizedBox(width: context.spacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Vincular con Google',
                        style: theme.textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: context.spacing.xxs),
                      Text(
                        configurationError ??
                            'Podrás hacerlo después sin perder tu historial.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: context.spacing.xs),
            Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: context.spacing.xs,
                  vertical: context.spacing.xxs,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(context.radii.pill),
                ),
                child: Text(
                  configurationError == null
                      ? 'PRÓXIMAMENTE'
                      : 'NO CONFIGURADO',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CloudAuthCard extends StatelessWidget {
  final bool isWorking;
  final bool showGoogle;
  final bool showApple;
  final VoidCallback onGoogle;
  final VoidCallback onApple;

  const _CloudAuthCard({
    required this.isWorking,
    required this.showGoogle,
    required this.showApple,
    required this.onGoogle,
    required this.onApple,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Semantics(
      key: const ValueKey('auth-cloud-options'),
      container: true,
      label: 'Acceso seguro con una cuenta en línea',
      child: Container(
        padding: EdgeInsets.all(context.spacing.sm),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerLow.withValues(alpha: 0.76),
          borderRadius: BorderRadius.circular(context.radii.medium),
          border: Border.all(color: colorScheme.outlineVariant),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Tu cuenta, cuando tú decidas',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            SizedBox(height: context.spacing.xxs),
            Text(
              'Autenticarte no mueve todavía tu espacio local. Primero podrás revisar la migración.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
            ),
            SizedBox(height: context.spacing.sm),
            if (showGoogle)
              OutlinedButton(
                key: const ValueKey('auth-google-action'),
                onPressed: isWorking ? null : onGoogle,
                child: const Text('Continuar con Google'),
              ),
            if (showApple) ...[
              if (showGoogle) SizedBox(height: context.spacing.xs),
              OutlinedButton.icon(
                key: const ValueKey('auth-apple-action'),
                onPressed: isWorking ? null : onApple,
                icon: const Icon(Icons.apple_rounded),
                label: const Text('Continuar con Apple'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PrivacyNote extends StatelessWidget {
  const _PrivacyNote();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.shield_outlined,
          size: 18,
          color: colorScheme.primary,
        ),
        SizedBox(width: context.spacing.xs),
        Expanded(
          child: Text(
            'Tus datos permanecen locales hasta que tú decidas vincularlos.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  height: 1.4,
                ),
          ),
        ),
      ],
    );
  }
}

class _BackToChoices extends StatelessWidget {
  final VoidCallback? onPressed;

  const _BackToChoices({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: TextButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.arrow_back_rounded),
        label: const Text('Formas de empezar'),
      ),
    );
  }
}

class _BackupPreview extends StatelessWidget {
  final BackupData backup;
  final bool isWorking;
  final VoidCallback onChooseAnother;
  final VoidCallback onRestore;

  const _BackupPreview({
    required this.backup,
    required this.isWorking,
    required this.onChooseAnother,
    required this.onRestore,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final profileName = backup.profile['name'] as String?;
    final date = backup.exportedAt.toLocal();
    final formattedDate = '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/${date.year}';
    final noteCount =
        (backup.noteSnapshot['notes'] as List<dynamic>? ?? const []).length;

    return Container(
      key: const ValueKey('auth-backup-preview'),
      padding: EdgeInsets.all(context.spacing.md),
      decoration: BoxDecoration(
        color: context.zentraPalette.warmPeach.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(context.radii.large),
        border: Border.all(
          color: context.zentraPalette.warmPeach.withValues(alpha: 0.42),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(context.radii.medium),
                ),
                child: Icon(
                  Icons.inventory_2_outlined,
                  color: context.zentraPalette.warmPeach,
                ),
              ),
              SizedBox(width: context.spacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profileName ?? backup.user.username,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: context.spacing.xxs),
                    Text(
                      'Respaldo del $formattedDate',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: context.spacing.md),
          Wrap(
            spacing: context.spacing.xs,
            runSpacing: context.spacing.xs,
            children: [
              _BackupMetric(
                value: backup.habits.length,
                label: 'hábitos',
              ),
              _BackupMetric(
                value: backup.logs.length,
                label: 'registros',
              ),
              _BackupMetric(
                value: backup.pomodoroActivities.length,
                label: 'actividades',
              ),
              if (noteCount > 0)
                _BackupMetric(
                  value: noteCount,
                  label: 'notas',
                ),
            ],
          ),
          SizedBox(height: context.spacing.md),
          FilledButton(
            onPressed: isWorking ? null : onRestore,
            child: _ActionLabel(
              isWorking: isWorking,
              label: 'Restaurar este respaldo',
            ),
          ),
          TextButton(
            onPressed: isWorking ? null : onChooseAnother,
            child: const Text('Elegir otro archivo'),
          ),
        ],
      ),
    );
  }
}

class _BackupMetric extends StatelessWidget {
  final int value;
  final String label;

  const _BackupMetric({
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: context.spacing.sm,
        vertical: context.spacing.xs,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(context.radii.pill),
      ),
      child: Text(
        '$value $label',
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}

class _RestoreSafetyNote extends StatelessWidget {
  const _RestoreSafetyNote();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: EdgeInsets.all(context.spacing.sm),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(context.radii.medium),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.verified_user_outlined,
            color: colorScheme.primary,
          ),
          SizedBox(width: context.spacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Nada se reemplaza sin confirmar.',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                SizedBox(height: context.spacing.xxs),
                Text(
                  'Primero validamos el archivo y te mostramos su contenido.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionLabel extends StatelessWidget {
  final bool isWorking;
  final String label;

  const _ActionLabel({
    required this.isWorking,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    if (!isWorking) return Text(label);
    return const SizedBox.square(
      dimension: 20,
      child: CircularProgressIndicator(strokeWidth: 2),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback onClose;

  const _ErrorBanner({
    required this.message,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: EdgeInsets.all(context.spacing.sm),
      decoration: BoxDecoration(
        color: colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(context.radii.medium),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.error_outline,
            color: colorScheme.onErrorContainer,
          ),
          SizedBox(width: context.spacing.sm),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: colorScheme.onErrorContainer),
            ),
          ),
          IconButton(
            tooltip: 'Cerrar mensaje de error',
            visualDensity: VisualDensity.compact,
            onPressed: onClose,
            icon: Icon(
              Icons.close,
              color: colorScheme.onErrorContainer,
            ),
          ),
        ],
      ),
    );
  }
}
