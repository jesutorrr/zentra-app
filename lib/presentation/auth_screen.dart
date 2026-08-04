import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/session_controller.dart';
import '../domain/auth_models.dart';
import 'design_tokens.dart';
import 'motion_policy.dart';
import 'utils/backup_passphrase_dialog.dart';

export 'auth_screen_classic.dart' show ClassicAuthScreen;

enum _AccessChoice {
  local,
  backup,
}

enum _AccessView {
  choices,
  backup,
}

/// Salvia local-first entry with two fully local paths.
class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _scrollController = ScrollController();

  _AccessChoice _choice = _AccessChoice.local;
  _AccessView _view = _AccessView.choices;
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
    final palette = context.zentraPalette;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Colors.black : palette.functionalSurface,
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (!isDark)
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFF0F7F3),
                    Color(0xFFF8F6F0),
                  ],
                  stops: [0, 0.42],
                ),
              ),
            ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final horizontalPadding =
                    constraints.maxWidth >= 700 ? 40.0 : 24.0;
                final verticalPadding =
                    constraints.maxHeight < 700 ? 18.0 : 28.0;
                final anchorFooter =
                    MediaQuery.textScalerOf(context).scale(16) <= 20;
                final minHeight =
                    (constraints.maxHeight - (verticalPadding * 2))
                        .clamp(0.0, double.infinity);

                return SingleChildScrollView(
                  key: const ValueKey('auth-scroll-view'),
                  controller: _scrollController,
                  padding: EdgeInsets.symmetric(
                    horizontal: horizontalPadding,
                    vertical: verticalPadding,
                  ),
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: _view == _AccessView.choices ? 900 : 620,
                        minHeight: minHeight,
                      ),
                      child: Builder(
                        builder: (context) {
                          final panel = Container(
                            key: const ValueKey('auth-form-panel'),
                            child: _view == _AccessView.choices
                                ? _buildChoices()
                                : _buildBackup(anchorFooter: anchorFooter),
                          );
                          return anchorFooter
                              ? IntrinsicHeight(child: panel)
                              : panel;
                        },
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

  Widget _buildChoices() {
    final session =
        ref.watch(sessionControllerProvider).valueOrNull ?? SessionState();
    final scaler = MediaQuery.textScalerOf(context);
    final expanded =
        MediaQuery.sizeOf(context).width >= 700 && scaler.scale(16) <= 20;

    return Column(
      key: const ValueKey('auth-choices'),
      mainAxisAlignment:
          expanded ? MainAxisAlignment.center : MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SalviaBrandHeading(centered: expanded),
        if (session.error != null) ...[
          const SizedBox(height: 16),
          _ErrorBanner(
            message: session.error!,
            onClose: ref.read(sessionControllerProvider.notifier).clearError,
          ),
        ],
        SizedBox(height: expanded ? 30 : 24),
        _AccessBento(
          expanded: expanded,
          selected: _choice,
          enabled: !_isWorking,
          onSelected: (choice) => setState(() => _choice = choice),
        ),
        const SizedBox(height: 16),
        _PrimaryAction(
          key: const ValueKey('auth-continue'),
          label: 'Continuar',
          isWorking: _isWorking,
          onPressed: _isWorking ? null : _continueChoice,
        ),
        const SizedBox(height: 18),
        const _PrivacyNote(),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildBackup({required bool anchorFooter}) {
    final session =
        ref.watch(sessionControllerProvider).valueOrNull ?? SessionState();

    return Column(
      key: const ValueKey('auth-backup'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: IconButton(
            key: const ValueKey('auth-back-to-choices'),
            tooltip: 'Formas de empezar',
            onPressed: _isWorking ? null : _showChoices,
            icon: const Icon(Icons.arrow_back_rounded),
          ),
        ),
        const SizedBox(height: 10),
        const _SalviaHeading(
          eyebrow: 'RESPALDO LOCAL',
          title: 'Restaura tu espacio.',
          description: 'Revisarás el contenido antes de importarlo.',
        ),
        if (session.error != null) ...[
          const SizedBox(height: 16),
          _ErrorBanner(
            message: session.error!,
            onClose: ref.read(sessionControllerProvider.notifier).clearError,
          ),
        ],
        const SizedBox(height: 26),
        if (_selectedBackup == null)
          _SelectBackupCard(
            onPressed: _isWorking ? null : _selectBackup,
          )
        else
          _BackupPreview(
            backup: _selectedBackup!,
            enabled: !_isWorking,
            onChooseAnother: _selectBackup,
          ),
        if (anchorFooter) const Spacer() else const SizedBox(height: 48),
        const SizedBox(height: 28),
        const _RestoreSafetyNote(),
        const SizedBox(height: 16),
        _PrimaryAction(
          key: const ValueKey('auth-restore-action'),
          label: _selectedBackup == null ? 'Elegir respaldo' : 'Restaurar',
          isWorking: _isWorking,
          onPressed: _isWorking
              ? null
              : _selectedBackup == null
                  ? _selectBackup
                  : _confirmRestore,
        ),
      ],
    );
  }

  void _continueChoice() {
    if (_choice == _AccessChoice.backup) {
      ref.read(sessionControllerProvider.notifier).clearError();
      setState(() => _view = _AccessView.backup);
      _resetScroll();
      return;
    }
    _continueLocally();
  }

  void _showChoices() {
    ref.read(sessionControllerProvider.notifier).clearError();
    setState(() {
      _view = _AccessView.choices;
      _selectedBackup = null;
    });
    _resetScroll();
  }

  void _resetScroll() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        0,
        duration:
            context.motionPolicy.duration(const Duration(milliseconds: 220)),
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

class _SalviaHeading extends StatelessWidget {
  final String eyebrow;
  final String title;
  final String? description;

  const _SalviaHeading({
    required this.eyebrow,
    required this.title,
    this.description,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = context.zentraPalette;
    final width = MediaQuery.sizeOf(context).width;
    final useSingleLineTitle =
        width < 700 && MediaQuery.textScalerOf(context).scale(16) <= 20;
    final titleText = Text(
      title,
      style: theme.textTheme.displaySmall?.copyWith(
        color: palette.ink,
        fontSize: width >= 700 ? 38 : 32,
        fontWeight: FontWeight.w400,
        height: 1.06,
        letterSpacing: -1.4,
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          eyebrow,
          style: theme.textTheme.labelLarge?.copyWith(
            color: palette.brandTeal,
            fontWeight: FontWeight.w600,
            letterSpacing: 3,
          ),
        ),
        const SizedBox(height: 10),
        if (useSingleLineTitle)
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: titleText,
          )
        else
          titleText,
        if (description != null) ...[
          const SizedBox(height: 10),
          Text(
            description!,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: palette.inkSecondary,
              height: 1.4,
            ),
          ),
        ],
      ],
    );
  }
}

class _SalviaBrandHeading extends StatelessWidget {
  final bool centered;

  const _SalviaBrandHeading({required this.centered});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = context.zentraPalette;
    final isDark = theme.brightness == Brightness.dark;
    final titleSize = centered ? 42.0 : 32.0;
    final keepTitleOnOneLine =
        !centered && MediaQuery.textScalerOf(context).scale(16) <= 20;
    final title = Text(
      'Elige cómo empezar.',
      textAlign: centered ? TextAlign.center : TextAlign.start,
      style: theme.textTheme.displaySmall?.copyWith(
        color: palette.ink,
        fontSize: titleSize,
        fontWeight: FontWeight.w400,
        height: 1.06,
        letterSpacing: -1.5,
      ),
    );

    return Column(
      crossAxisAlignment:
          centered ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment:
              centered ? MainAxisAlignment.center : MainAxisAlignment.start,
          children: [
            Semantics(
              image: true,
              label: 'Logotipo de Zentra',
              child: ExcludeSemantics(
                child: Container(
                  key: const ValueKey('auth-brand-logo'),
                  width: 50,
                  height: 50,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: palette.brandTeal,
                    borderRadius: BorderRadius.circular(17),
                    boxShadow: isDark
                        ? const []
                        : [
                            BoxShadow(
                              color: palette.ink.withValues(alpha: 0.06),
                              blurRadius: 16,
                              offset: const Offset(0, 7),
                            ),
                          ],
                  ),
                  child: Image.asset(
                    'assets/images/zentra_logo_mark.png',
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.high,
                    errorBuilder: (context, error, stackTrace) => const Icon(
                      Icons.spa_outlined,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Flexible(
              child: Text(
                'PRIVADO POR DISEÑO',
                textAlign: centered ? TextAlign.center : TextAlign.start,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: palette.brandTeal,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 3,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        if (keepTitleOnOneLine)
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: title,
          )
        else
          title,
      ],
    );
  }
}

class _AccessBento extends StatelessWidget {
  final bool expanded;
  final _AccessChoice selected;
  final bool enabled;
  final ValueChanged<_AccessChoice> onSelected;

  const _AccessBento({
    required this.expanded,
    required this.selected,
    required this.enabled,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = context.zentraPalette;
    final isDark = theme.brightness == Brightness.dark;
    final scaler = MediaQuery.textScalerOf(context);
    final stackChoices = scaler.scale(16) > 20;
    final cards = [
      _ChoiceCard(
        key: const ValueKey('auth-local-path'),
        choice: _AccessChoice.local,
        selected: selected == _AccessChoice.local,
        enabled: enabled,
        icon: Icons.shield_outlined,
        title: 'Usar en este dispositivo',
        badge: 'RECOMENDADO',
        onSelected: onSelected,
      ),
      _ChoiceCard(
        key: const ValueKey('auth-backup-path'),
        choice: _AccessChoice.backup,
        selected: selected == _AccessChoice.backup,
        enabled: enabled,
        icon: Icons.inventory_2_outlined,
        title: 'Restaurar respaldo',
        onSelected: onSelected,
      ),
    ];

    late final Widget content;
    if (expanded) {
      content = IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: cards.first),
            const SizedBox(width: 12),
            Expanded(child: cards.last),
          ],
        ),
      );
    } else {
      final choices = stackChoices
          ? Column(
              children: [
                cards.first,
                const SizedBox(height: 12),
                cards.last,
              ],
            )
          : IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: cards.first),
                  const SizedBox(width: 12),
                  Expanded(child: cards.last),
                ],
              ),
            );
      content = choices;
    }

    return Container(
      key: const ValueKey('auth-bento-surface'),
      padding: EdgeInsets.all(expanded ? 14 : 10),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF080D0C)
            : palette.surfaceCard.withValues(alpha: 0.76),
        borderRadius: BorderRadius.circular(expanded ? 28 : 24),
        border: Border.all(
          color: isDark
              ? palette.checkBorder.withValues(alpha: 0.72)
              : palette.checkBorder.withValues(alpha: 0.62),
        ),
        boxShadow: isDark
            ? const []
            : [
                BoxShadow(
                  color: palette.ink.withValues(alpha: 0.055),
                  blurRadius: 30,
                  offset: const Offset(0, 14),
                ),
              ],
      ),
      child: content,
    );
  }
}

class _ChoiceCard extends StatelessWidget {
  final _AccessChoice choice;
  final bool selected;
  final bool enabled;
  final IconData icon;
  final String title;
  final String? badge;
  final ValueChanged<_AccessChoice> onSelected;

  const _ChoiceCard({
    required this.choice,
    required this.selected,
    required this.enabled,
    required this.icon,
    required this.title,
    required this.onSelected,
    this.badge,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = context.zentraPalette;
    final isDark = theme.brightness == Brightness.dark;
    final accent =
        choice == _AccessChoice.local ? palette.brandTeal : palette.warmPeach;

    return Semantics(
      button: true,
      selected: selected,
      enabled: enabled,
      label: '$title${badge == null ? '' : '. $badge'}',
      child: Material(
        color: isDark ? palette.surfaceCard : palette.surfaceCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: selected ? palette.brandTeal : palette.checkBorder,
            width: selected ? 2 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: enabled ? () => onSelected(choice) : null,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: isDark ? 0.14 : 0.12),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Icon(icon, color: accent),
                ),
                const SizedBox(height: 18),
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: palette.ink,
                    fontWeight: FontWeight.w600,
                    height: 1.16,
                  ),
                ),
                if (badge != null) ...[
                  const SizedBox(height: 14),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: palette.tealTint,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 220),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 4,
                        ),
                        child: Text(
                          badge!,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: palette.brandTeal,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PrivacyNote extends StatelessWidget {
  const _PrivacyNote();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = context.zentraPalette;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(Icons.shield_outlined, size: 18, color: palette.brandTeal),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            'Tus datos permanecen locales hasta que tú decidas.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: palette.inkSecondary,
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }
}

class _PrimaryAction extends StatelessWidget {
  final String label;
  final bool isWorking;
  final VoidCallback? onPressed;

  const _PrimaryAction({
    required this.label,
    required this.isWorking,
    required this.onPressed,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.zentraPalette;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 56),
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          elevation: 0,
          shadowColor: Colors.transparent,
          backgroundColor: palette.brandTeal,
          foregroundColor: isDark ? Colors.black : Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        child: AnimatedSwitcher(
          duration:
              context.motionPolicy.duration(const Duration(milliseconds: 160)),
          child: isWorking
              ? SizedBox(
                  key: const ValueKey('auth-working'),
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: isDark ? Colors.black : Colors.white,
                  ),
                )
              : Row(
                  key: const ValueKey('auth-ready'),
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text(
                        label,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Icon(Icons.arrow_forward_rounded),
                  ],
                ),
        ),
      ),
    );
  }
}

class _SelectBackupCard extends StatelessWidget {
  final VoidCallback? onPressed;

  const _SelectBackupCard({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = context.zentraPalette;

    return Semantics(
      key: const ValueKey('auth-select-backup'),
      button: true,
      enabled: onPressed != null,
      label: 'Elegir respaldo de Zentra',
      child: Material(
        color: palette.surfaceCard,
        borderRadius: BorderRadius.circular(20),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: palette.warmPeach.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Icon(
                    Icons.folder_open_outlined,
                    color: palette.warmPeach,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Elegir respaldo',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: palette.ink,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Archivo creado por Zentra.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: palette.inkSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: palette.warmPeach,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BackupPreview extends StatelessWidget {
  final BackupData backup;
  final bool enabled;
  final VoidCallback onChooseAnother;

  const _BackupPreview({
    required this.backup,
    required this.enabled,
    required this.onChooseAnother,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = context.zentraPalette;
    final date = backup.exportedAt.toLocal();
    final formattedDate = '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/${date.year}';
    final name = backup.profile['name'] as String? ?? backup.user.username;
    final noteCount =
        (backup.noteSnapshot['notes'] as List<dynamic>? ?? const []).length;

    return Container(
      key: const ValueKey('auth-backup-preview'),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: palette.surfaceCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: palette.warmPeach.withValues(alpha: 0.36),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: palette.warmPeach.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(
                  Icons.inventory_2_outlined,
                  color: palette.warmPeach,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: palette.ink,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Respaldo del $formattedDate',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: palette.inkSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _MetricChip(label: '${backup.habits.length} hábitos'),
              _MetricChip(label: '${backup.logs.length} registros'),
              _MetricChip(label: '$noteCount notas'),
            ],
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: enabled ? onChooseAnother : null,
            child: const Text('Elegir otro archivo'),
          ),
        ],
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  final String label;

  const _MetricChip({required this.label});

  @override
  Widget build(BuildContext context) {
    final palette = context.zentraPalette;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: palette.progressTrack,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: palette.inkSecondary,
              ),
        ),
      ),
    );
  }
}

class _RestoreSafetyNote extends StatelessWidget {
  const _RestoreSafetyNote();

  @override
  Widget build(BuildContext context) {
    final palette = context.zentraPalette;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.lock_outline_rounded, size: 18, color: palette.brandTeal),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            'El respaldo se procesa en este dispositivo.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: palette.inkSecondary,
                  height: 1.35,
                ),
          ),
        ),
      ],
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
    final palette = context.zentraPalette;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
      decoration: BoxDecoration(
        color: palette.warmPeach.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded, color: palette.warmPeach),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: palette.ink,
                  ),
            ),
          ),
          IconButton(
            tooltip: 'Cerrar mensaje',
            onPressed: onClose,
            icon: const Icon(Icons.close_rounded),
          ),
        ],
      ),
    );
  }
}
