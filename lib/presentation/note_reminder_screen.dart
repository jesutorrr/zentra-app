import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/note_controller.dart';
import '../application/note_state.dart';
import '../application/session_controller.dart';
import '../domain/note_models.dart';
import 'design_tokens.dart';
import 'widgets/responsive_layout.dart';

enum _ReminderPreset {
  laterToday,
  tomorrow,
  weekend,
  custom,
  none,
}

class NoteReminderScreen extends ConsumerStatefulWidget {
  final String noteId;

  const NoteReminderScreen({
    required this.noteId,
    super.key,
  });

  @override
  ConsumerState<NoteReminderScreen> createState() => _NoteReminderScreenState();
}

class _NoteReminderScreenState extends ConsumerState<NoteReminderScreen> {
  _ReminderPreset _preset = _ReminderPreset.laterToday;
  NotePrivacyMode _privacyMode = NotePrivacyMode.hidden;
  DateTime _scheduledAt = DateTime.now().add(const Duration(hours: 3));
  Note? _note;
  bool _initialized = false;
  bool _saving = false;
  String? _error;
  String? _ownerId;

  void _initialize(String ownerId, NoteState state) {
    _initialized = true;
    _ownerId = ownerId;
    for (final note in state.notes) {
      if (note.id == widget.noteId) {
        _note = note;
        break;
      }
    }
    final reminder = state.getReminder(widget.noteId);
    if (reminder != null && reminder.status == NoteReminderStatus.scheduled) {
      _scheduledAt = reminder.scheduledAtUtc.toLocal();
      _privacyMode = reminder.privacyMode;
      _preset = _ReminderPreset.custom;
    } else {
      _scheduledAt = _dateFor(_ReminderPreset.laterToday);
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeOwnerId = ref.watch(activeOwnerIdProvider);
    final ownerId = _ownerId ?? activeOwnerId;
    final noteState =
        ownerId == null ? null : ref.watch(noteControllerProvider(ownerId));
    final loadedState = noteState?.valueOrNull;
    if (!_initialized && ownerId != null && loadedState != null) {
      _initialize(ownerId, loadedState);
    }
    if (!_initialized) {
      return const Scaffold(
        key: ValueKey('note-reminder-screen'),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      key: const ValueKey('note-reminder-screen'),
      appBar: AppBar(
        title: const Text('Recordatorio'),
        centerTitle: false,
      ),
      body: ResponsiveLayoutBuilder(
        builder: (context, layout) {
          final expanded = layout.isExpanded &&
              !layout.isShort &&
              MediaQuery.textScalerOf(context).scale(16) <= 23;
          return Padding(
            padding: EdgeInsets.fromLTRB(
              layout.horizontalPagePadding,
              layout.verticalPagePadding,
              layout.horizontalPagePadding,
              context.spacing.lg,
            ),
            child: ResponsiveContentFrame(
              maxWidth: expanded ? 1080 : 680,
              child: _note == null
                  ? _MissingNote(onClose: () => Navigator.of(context).pop())
                  : expanded
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(flex: 6, child: _buildForm(context)),
                            SizedBox(width: context.spacing.lg),
                            Expanded(
                              flex: 4,
                              child: Align(
                                alignment: Alignment.topCenter,
                                child: _buildPreview(context),
                              ),
                            ),
                          ],
                        )
                      : ListView(
                          physics: const BouncingScrollPhysics(),
                          children: [
                            _buildForm(context),
                            SizedBox(height: context.spacing.lg),
                            _buildPreview(context),
                          ],
                        ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildForm(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(context.radii.extraLarge),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: EdgeInsets.all(context.spacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: context.zentraPalette.calmMint,
                    borderRadius: BorderRadius.circular(context.radii.medium),
                  ),
                  child: Icon(
                    Icons.notifications_none_rounded,
                    color: context.zentraPalette.brandTeal,
                  ),
                ),
                SizedBox(width: context.spacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '¿Cuándo quieres volver?',
                        style: theme.textTheme.titleLarge,
                      ),
                      SizedBox(height: context.spacing.xxs),
                      Text(
                        'Elige un momento realista. Zentra traerá exactamente esta nota.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: context.spacing.lg),
            Text('Momento', style: theme.textTheme.labelLarge),
            SizedBox(height: context.spacing.xs),
            Wrap(
              spacing: context.spacing.xs,
              runSpacing: context.spacing.xs,
              children: [
                _PresetChoice(
                  key: const ValueKey('note-reminder-later-today'),
                  label: 'Más tarde hoy',
                  icon: Icons.wb_twilight_outlined,
                  selected: _preset == _ReminderPreset.laterToday,
                  onTap: () => _selectPreset(_ReminderPreset.laterToday),
                ),
                _PresetChoice(
                  key: const ValueKey('note-reminder-tomorrow'),
                  label: 'Mañana',
                  icon: Icons.wb_sunny_outlined,
                  selected: _preset == _ReminderPreset.tomorrow,
                  onTap: () => _selectPreset(_ReminderPreset.tomorrow),
                ),
                _PresetChoice(
                  key: const ValueKey('note-reminder-weekend'),
                  label: 'Este fin de semana',
                  icon: Icons.weekend_outlined,
                  selected: _preset == _ReminderPreset.weekend,
                  onTap: () => _selectPreset(_ReminderPreset.weekend),
                ),
                _PresetChoice(
                  key: const ValueKey('note-reminder-custom'),
                  label: 'Fecha y hora',
                  icon: Icons.event_outlined,
                  selected: _preset == _ReminderPreset.custom,
                  onTap: _pickCustomDateTime,
                ),
                _PresetChoice(
                  key: const ValueKey('note-reminder-none'),
                  label: 'Sin recordatorio',
                  icon: Icons.notifications_off_outlined,
                  selected: _preset == _ReminderPreset.none,
                  onTap: () => _selectPreset(_ReminderPreset.none),
                ),
              ],
            ),
            if (_preset != _ReminderPreset.none) ...[
              SizedBox(height: context.spacing.lg),
              _ScheduledMomentCard(
                value: _scheduledAt,
                onEdit: _pickCustomDateTime,
              ),
              SizedBox(height: context.spacing.lg),
              Text(
                'Privacidad en pantalla bloqueada',
                style: theme.textTheme.labelLarge,
              ),
              SizedBox(height: context.spacing.xs),
              _PrivacySelector(
                selected: _privacyMode,
                onSelected: (value) => setState(() => _privacyMode = value),
              ),
            ],
            if (_error != null) ...[
              SizedBox(height: context.spacing.md),
              Semantics(
                liveRegion: true,
                child: Text(
                  _error!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.error,
                  ),
                ),
              ),
            ],
            SizedBox(height: context.spacing.lg),
            FilledButton.icon(
              key: const ValueKey('note-reminder-save'),
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: colorScheme.onPrimary,
                      ),
                    )
                  : Icon(
                      _preset == _ReminderPreset.none
                          ? Icons.notifications_off_outlined
                          : Icons.notifications_active_outlined,
                    ),
              label: Text(
                _preset == _ReminderPreset.none
                    ? 'Quitar recordatorio'
                    : 'Guardar recordatorio',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreview(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final title = _previewTitle();
    final body = _previewBody();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Así te acompañará Zentra',
          style: theme.textTheme.titleMedium,
        ),
        SizedBox(height: context.spacing.xs),
        Text(
          _preset == _ReminderPreset.none
              ? 'No se programará ninguna notificación.'
              : 'Esta vista previa respeta la privacidad que elegiste.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        SizedBox(height: context.spacing.md),
        AnimatedOpacity(
          opacity: _preset == _ReminderPreset.none ? 0.46 : 1,
          duration: const Duration(milliseconds: 160),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(context.radii.large),
              border: Border.all(color: colorScheme.outlineVariant),
              boxShadow: [
                BoxShadow(
                  color: colorScheme.shadow.withValues(alpha: 0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Padding(
              padding: EdgeInsets.all(context.spacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: context.zentraPalette.brandTeal,
                          borderRadius:
                              BorderRadius.circular(context.radii.small),
                        ),
                        child: Icon(
                          Icons.spa_outlined,
                          color: colorScheme.onPrimary,
                        ),
                      ),
                      SizedBox(width: context.spacing.sm),
                      Expanded(
                        child: Text(
                          'Zentra',
                          style: theme.textTheme.titleSmall,
                        ),
                      ),
                      Text(
                        _preset == _ReminderPreset.none
                            ? 'sin programar'
                            : _relativeLabel(_scheduledAt),
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: context.spacing.md),
                  Text(title, style: theme.textTheme.titleSmall),
                  SizedBox(height: context.spacing.xxs),
                  Text(
                    body,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        SizedBox(height: context.spacing.sm),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.lock_outline_rounded,
              size: 18,
              color: colorScheme.onSurfaceVariant,
            ),
            SizedBox(width: context.spacing.xs),
            Expanded(
              child: Text(
                'Tus notas son locales por defecto. Puedes cambiar esta vista previa cuando quieras.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _selectPreset(_ReminderPreset value) {
    setState(() {
      _preset = value;
      if (value != _ReminderPreset.none && value != _ReminderPreset.custom) {
        _scheduledAt = _dateFor(value);
      }
      _error = null;
    });
  }

  DateTime _dateFor(_ReminderPreset preset) {
    final now = DateTime.now();
    switch (preset) {
      case _ReminderPreset.laterToday:
        final candidate = now.add(const Duration(hours: 3));
        if (candidate.day == now.day && candidate.hour < 22) {
          return candidate;
        }
        return DateTime(now.year, now.month, now.day + 1, 9);
      case _ReminderPreset.tomorrow:
        return DateTime(now.year, now.month, now.day + 1, 19);
      case _ReminderPreset.weekend:
        if (now.weekday == DateTime.saturday) {
          final today = DateTime(now.year, now.month, now.day, 10);
          if (today.isAfter(now)) return today;
          return DateTime(now.year, now.month, now.day + 1, 10);
        }
        if (now.weekday == DateTime.sunday) {
          final today = DateTime(now.year, now.month, now.day, 10);
          if (today.isAfter(now)) return today;
        }
        var daysUntilSaturday = DateTime.saturday - now.weekday;
        if (daysUntilSaturday <= 0) daysUntilSaturday += 7;
        return DateTime(
          now.year,
          now.month,
          now.day + daysUntilSaturday,
          10,
        );
      case _ReminderPreset.custom:
        return _scheduledAt;
      case _ReminderPreset.none:
        return now;
    }
  }

  Future<void> _pickCustomDateTime() async {
    final now = DateTime.now();
    final firstDate = DateTime(now.year, now.month, now.day);
    final date = await showDatePicker(
      context: context,
      initialDate: _scheduledAt.isBefore(firstDate) ? firstDate : _scheduledAt,
      firstDate: firstDate,
      lastDate: DateTime(now.year + 5, 12, 31),
      helpText: 'Elige cuándo volver',
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_scheduledAt),
      helpText: 'Elige la hora',
    );
    if (time == null || !mounted) return;
    final value = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
    if (!value.isAfter(DateTime.now())) {
      setState(() {
        _error = 'Elige un momento futuro.';
        _preset = _ReminderPreset.custom;
      });
      return;
    }
    setState(() {
      _scheduledAt = value;
      _preset = _ReminderPreset.custom;
      _error = null;
    });
  }

  Future<void> _save() async {
    if (_preset != _ReminderPreset.none &&
        !_scheduledAt.isAfter(DateTime.now())) {
      setState(() => _error = 'Elige un momento futuro.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    final ownerId = _ownerId;
    if (ownerId == null) {
      setState(() {
        _saving = false;
        _error = 'No pudimos identificar el espacio activo.';
      });
      return;
    }
    final controller = ref.read(noteControllerProvider(ownerId).notifier);
    try {
      if (_preset == _ReminderPreset.none) {
        await controller.cancelReminder(widget.noteId);
      } else {
        final scheduled = await controller.scheduleReminder(
          noteId: widget.noteId,
          scheduledAt: _scheduledAt,
          privacyMode: _privacyMode,
        );
        if (!scheduled) {
          if (mounted) {
            setState(() {
              _saving = false;
              _error = ref
                      .read(noteControllerProvider(ownerId))
                      .valueOrNull
                      ?.errorMessage ??
                  'No pudimos programar el recordatorio.';
            });
          }
          return;
        }
      }
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = _preset == _ReminderPreset.none
              ? 'No pudimos quitar el recordatorio.'
              : 'No pudimos programar el recordatorio.';
        });
      }
    }
  }

  String _previewTitle() {
    final noteTitle = _note!.title.trim();
    return switch (_privacyMode) {
      NotePrivacyMode.titleAndBody =>
        noteTitle.isEmpty ? 'Nota para repasar' : noteTitle,
      NotePrivacyMode.titleOnly =>
        noteTitle.isEmpty ? 'Nota para repasar' : noteTitle,
      NotePrivacyMode.hidden => 'Tienes una nota pendiente para repasar',
    };
  }

  String _previewBody() {
    final body = _note!.body.trim().replaceAll(RegExp(r'\s+'), ' ');
    return switch (_privacyMode) {
      NotePrivacyMode.titleAndBody =>
        body.isEmpty ? 'Es buen momento para volver a ella.' : body,
      NotePrivacyMode.titleOnly => 'Es buen momento para volver a esta nota.',
      NotePrivacyMode.hidden =>
        'Abre Zentra para verla sin mostrar su contenido en la pantalla bloqueada.',
    };
  }

  String _relativeLabel(DateTime date) {
    final difference = date.difference(DateTime.now());
    if (difference.isNegative) {
      final elapsed = difference.abs();
      if (elapsed.inMinutes < 60) {
        return 'hace ${elapsed.inMinutes.clamp(1, 59)} min';
      }
      if (elapsed.inHours < 24) {
        return 'hace ${elapsed.inHours} h';
      }
      return _shortSpanishDate(date);
    }
    if (difference.inMinutes < 60) {
      return 'en ${difference.inMinutes.clamp(1, 59)} min';
    }
    if (difference.inHours < 24) {
      return 'en ${difference.inHours} h';
    }
    return _shortSpanishDate(date);
  }
}

class _PresetChoice extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _PresetChoice({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Semantics(
      selected: selected,
      button: true,
      label: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(context.radii.pill),
        child: Container(
          constraints: const BoxConstraints(minHeight: 48),
          padding: EdgeInsets.symmetric(horizontal: context.spacing.sm),
          decoration: BoxDecoration(
            color: selected
                ? colorScheme.primaryContainer
                : colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(context.radii.pill),
            border: Border.all(
              color:
                  selected ? colorScheme.primary : colorScheme.outlineVariant,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 20),
              SizedBox(width: context.spacing.xs),
              Flexible(
                child: Text(
                  label,
                  maxLines: 2,
                  softWrap: true,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScheduledMomentCard extends StatelessWidget {
  final DateTime value;
  final VoidCallback onEdit;

  const _ScheduledMomentCard({
    required this.value,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Material(
      color: context.zentraPalette.specialSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(context.radii.large),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: InkWell(
        onTap: onEdit,
        borderRadius: BorderRadius.circular(context.radii.large),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 80),
          child: Padding(
            padding: EdgeInsets.all(context.spacing.md),
            child: Row(
              children: [
                Icon(
                  Icons.event_available_outlined,
                  color: context.zentraPalette.warmPeach,
                ),
                SizedBox(width: context.spacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _fullSpanishDate(value),
                        style: theme.textTheme.titleSmall,
                      ),
                      SizedBox(height: context.spacing.xxs),
                      Text(
                        TimeOfDay.fromDateTime(value).format(context),
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.edit_outlined),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

const _spanishWeekdays = <String>[
  'lunes',
  'martes',
  'miércoles',
  'jueves',
  'viernes',
  'sábado',
  'domingo',
];

const _spanishMonths = <String>[
  'enero',
  'febrero',
  'marzo',
  'abril',
  'mayo',
  'junio',
  'julio',
  'agosto',
  'septiembre',
  'octubre',
  'noviembre',
  'diciembre',
];

String _fullSpanishDate(DateTime value) {
  final weekday = _spanishWeekdays[value.weekday - 1];
  final label =
      '$weekday, ${value.day} de ${_spanishMonths[value.month - 1]} de ${value.year}';
  return '${label[0].toUpperCase()}${label.substring(1)}';
}

String _shortSpanishDate(DateTime value) {
  return '${value.day.toString().padLeft(2, '0')}/'
      '${value.month.toString().padLeft(2, '0')}/${value.year}';
}

class _PrivacySelector extends StatelessWidget {
  final NotePrivacyMode selected;
  final ValueChanged<NotePrivacyMode> onSelected;

  const _PrivacySelector({
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _PrivacyChoice(
          key: const ValueKey('note-privacy-hidden'),
          title: 'Contenido oculto',
          subtitle: 'La opción más privada para pantalla bloqueada.',
          selected: selected == NotePrivacyMode.hidden,
          onTap: () => onSelected(NotePrivacyMode.hidden),
        ),
        SizedBox(height: context.spacing.xs),
        _PrivacyChoice(
          key: const ValueKey('note-privacy-title'),
          title: 'Sólo título',
          subtitle: 'Muestra el nombre de la nota, no sus apuntes.',
          selected: selected == NotePrivacyMode.titleOnly,
          onTap: () => onSelected(NotePrivacyMode.titleOnly),
        ),
        SizedBox(height: context.spacing.xs),
        _PrivacyChoice(
          key: const ValueKey('note-privacy-body'),
          title: 'Título y fragmento',
          subtitle: 'Úsalo sólo si el contenido no es sensible.',
          selected: selected == NotePrivacyMode.titleAndBody,
          onTap: () => onSelected(NotePrivacyMode.titleAndBody),
        ),
      ],
    );
  }
}

class _PrivacyChoice extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  const _PrivacyChoice({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Semantics(
      selected: selected,
      button: true,
      label: '$title. $subtitle',
      child: Material(
        color: selected
            ? colorScheme.primaryContainer
            : colorScheme.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(context.radii.medium),
          side: BorderSide(
            color: selected ? colorScheme.primary : colorScheme.outlineVariant,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(context.radii.medium),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 68),
            child: Padding(
              padding: EdgeInsets.all(context.spacing.sm),
              child: Row(
                children: [
                  Icon(
                    selected
                        ? Icons.radio_button_checked_rounded
                        : Icons.radio_button_off_rounded,
                    color: selected
                        ? colorScheme.primary
                        : colorScheme.onSurfaceVariant,
                  ),
                  SizedBox(width: context.spacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(title, style: theme.textTheme.titleSmall),
                        SizedBox(height: context.spacing.xxs),
                        Text(
                          subtitle,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
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

class _MissingNote extends StatelessWidget {
  final VoidCallback onClose;

  const _MissingNote({required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.search_off_rounded, size: 48),
          SizedBox(height: context.spacing.md),
          Text(
            'Esta nota ya no está disponible',
            style: Theme.of(context).textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          SizedBox(height: context.spacing.lg),
          FilledButton(
            onPressed: onClose,
            child: const Text('Volver'),
          ),
        ],
      ),
    );
  }
}
