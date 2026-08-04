import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

import '../application/habit_controller.dart';
import '../application/habit_state.dart';
import '../application/session_controller.dart';
import '../domain/models.dart';
import 'design_tokens.dart';
import 'habit_form_screen.dart';
import 'theme.dart';
import 'utils/dialogs.dart';
import 'utils/page_transitions.dart';

export 'habits_list_screen_classic.dart' show ClassicHabitsListScreen;

enum _HabitCardAction {
  edit,
  toggleArchive,
  delete,
}

/// Salvia's calm, category-first habit library.
///
/// The previous management surface remains available as
/// [ClassicHabitsListScreen]. Both screens use the same repositories and
/// mutations, so switching the presentation does not fork user data.
class HabitsListScreen extends ConsumerStatefulWidget {
  const HabitsListScreen({super.key});

  @override
  ConsumerState<HabitsListScreen> createState() => _HabitsListScreenState();
}

class _HabitsListScreenState extends ConsumerState<HabitsListScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final Set<String> _mutatingHabitIds = <String>{};
  final Set<String> _confirmingDeleteIds = <String>{};

  Category? _selectedCategory;
  String _query = '';
  bool _searchIsOpen = false;

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ownerId = ref.watch(activeOwnerIdProvider);
    final workspace = ownerId == null
        ? const AsyncValue<HabitState>.loading()
        : ref.watch(habitControllerProvider(ownerId));
    final mediaQuery = MediaQuery.of(context);
    final scaledBody = mediaQuery.textScaler.scale(16);
    final pinsPrimaryAction = scaledBody <= 24 && mediaQuery.size.height >= 620;

    return Scaffold(
      key: const ValueKey('habits-screen'),
      backgroundColor: Colors.transparent,
      resizeToAvoidBottomInset: true,
      bottomNavigationBar:
          pinsPrimaryAction && mediaQuery.viewInsets.bottom == 0
              ? _SalviaCreateBar(
                  onPressed: () => _navigateToForm(context),
                )
              : null,
      body: SizedBox.expand(
        child: _SalviaBackground(
          key: const ValueKey('habits-salvia-background'),
          child: SafeArea(
            bottom: !pinsPrimaryAction,
            child: workspace.when(
              loading: () => _SalviaPage(
                child: _SalviaLoadingState(
                  includesCreateAction: !pinsPrimaryAction,
                  onCreateHabit: () => _navigateToForm(context),
                ),
              ),
              error: (_, __) => _SalviaPage(
                child: _SalviaErrorState(
                  onRetry: ownerId == null
                      ? null
                      : () => _retry(habitControllerProvider(ownerId)),
                ),
              ),
              data: (state) {
                if (state.error != null && state.habits.isEmpty) {
                  return _SalviaPage(
                    child: _SalviaErrorState(
                      onRetry: ownerId == null
                          ? null
                          : () => _retry(habitControllerProvider(ownerId)),
                    ),
                  );
                }
                if (state.habits.isEmpty) {
                  return _SalviaPage(
                    child: _SalviaEmptyState(
                      includesCreateAction: !pinsPrimaryAction,
                      onCreateHabit: () => _navigateToForm(context),
                    ),
                  );
                }

                final activeHabits = _matchingHabits(state.activeHabits);
                final pausedHabits = _matchingHabits(state.archivedHabits);
                final hasResults =
                    activeHabits.isNotEmpty || pausedHabits.isNotEmpty;
                return _SalviaPage(
                  child: CustomScrollView(
                    key: const ValueKey('habits-single-column-layout'),
                    physics: const BouncingScrollPhysics(),
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    slivers: [
                      SliverToBoxAdapter(
                        child: _SalviaHeader(
                          state: state,
                          searchController: _searchController,
                          searchFocusNode: _searchFocusNode,
                          searchIsOpen: _searchIsOpen,
                          selectedCategory: _selectedCategory,
                          onBack: () => Navigator.of(context).maybePop(),
                          onSearchToggle: _toggleSearch,
                          onQueryChanged: (value) {
                            setState(() => _query = value);
                          },
                          onCategoryChanged: (category) {
                            setState(() => _selectedCategory = category);
                          },
                        ),
                      ),
                      if (!hasResults)
                        SliverFillRemaining(
                          hasScrollBody: false,
                          child: _SalviaEmptyResults(
                            hasQuery: _query.trim().isNotEmpty,
                            hasCategory: _selectedCategory != null,
                            onClear: _clearResults,
                          ),
                        )
                      else ...[
                        SliverPadding(
                          padding: const EdgeInsets.only(top: 16),
                          sliver: SliverList.separated(
                            itemCount: activeHabits.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              final habit = activeHabits[index];
                              return _SalviaHabitCard(
                                habit: habit,
                                state: state,
                                isBusy: _isHabitBusy(habit.id),
                                onTap: () => _navigateToForm(
                                  context,
                                  habitId: habit.id,
                                ),
                                onEdit: () => _navigateToForm(
                                  context,
                                  habitId: habit.id,
                                ),
                                onToggleArchive: () => _toggleArchive(
                                  habitControllerProvider(ownerId!),
                                  habit,
                                ),
                                onDelete: () => _confirmDelete(
                                  habitControllerProvider(ownerId!),
                                  habit,
                                ),
                              );
                            },
                          ),
                        ),
                        if (pausedHabits.isNotEmpty) ...[
                          const SliverToBoxAdapter(
                            child: Padding(
                              padding: EdgeInsets.only(top: 22, bottom: 10),
                              child: _SalviaSectionLabel('En pausa'),
                            ),
                          ),
                          SliverList.separated(
                            itemCount: pausedHabits.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              final habit = pausedHabits[index];
                              return _SalviaPausedHabitCard(
                                habit: habit,
                                state: state,
                                isBusy: _isHabitBusy(habit.id),
                                onTap: () => _navigateToForm(
                                  context,
                                  habitId: habit.id,
                                ),
                                onRestore: () => _toggleArchive(
                                  habitControllerProvider(ownerId!),
                                  habit,
                                ),
                                onDelete: () => _confirmDelete(
                                  habitControllerProvider(ownerId!),
                                  habit,
                                ),
                              );
                            },
                          ),
                        ],
                        SliverToBoxAdapter(
                          child: SizedBox(
                            height: pinsPrimaryAction ? 28 : 18,
                          ),
                        ),
                        if (!pinsPrimaryAction)
                          SliverToBoxAdapter(
                            child: _SalviaCreateButton(
                              onPressed: () => _navigateToForm(context),
                            ),
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
    );
  }

  List<Habit> _matchingHabits(List<Habit> source) {
    final normalizedQuery = _normalizeForSearch(_query.trim());
    return source.where((habit) {
      final categoryMatches =
          _selectedCategory == null || habit.category == _selectedCategory;
      if (!categoryMatches) return false;
      if (normalizedQuery.isEmpty) return true;
      return _normalizeForSearch(habit.title).contains(normalizedQuery) ||
          _normalizeForSearch(habit.category.label).contains(normalizedQuery);
    }).toList();
  }

  void _toggleSearch() {
    setState(() => _searchIsOpen = !_searchIsOpen);
    if (_searchIsOpen) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _searchFocusNode.requestFocus();
      });
      return;
    }
    _clearSearch();
  }

  void _clearSearch() {
    _searchController.clear();
    _searchFocusNode.unfocus();
    setState(() {
      _query = '';
      _searchIsOpen = false;
    });
  }

  void _clearResults() {
    _searchController.clear();
    _searchFocusNode.unfocus();
    setState(() {
      _query = '';
      _searchIsOpen = false;
      _selectedCategory = null;
    });
  }

  Future<void> _retry(
    AsyncNotifierFamilyProvider<HabitController, HabitState, String> provider,
  ) async {
    ref.read(provider.notifier).clearError();
    await ref.read(provider.notifier).reload();
  }

  Future<void> _navigateToForm(
    BuildContext context, {
    String? habitId,
  }) async {
    await Navigator.of(context).push(
      PageTransitions.slideFromRight(
        HabitFormScreen(habitId: habitId),
      ),
    );
  }

  Future<bool> _runMutation(
    AsyncNotifierFamilyProvider<HabitController, HabitState, String> provider,
    Habit habit,
    Future<void> Function() action,
  ) async {
    if (_mutatingHabitIds.contains(habit.id)) return false;
    setState(() => _mutatingHabitIds.add(habit.id));
    try {
      ref.read(provider.notifier).clearError();
      await action();
      if (!mounted) return false;
      if (ref.read(provider).valueOrNull?.error != null) {
        showErrorSnackbar(context, 'No pudimos guardar el cambio.');
        return false;
      }
      return true;
    } catch (_) {
      if (mounted) {
        showErrorSnackbar(context, 'No pudimos guardar el cambio.');
      }
      return false;
    } finally {
      if (mounted) {
        setState(() => _mutatingHabitIds.remove(habit.id));
      }
    }
  }

  bool _isHabitBusy(String habitId) {
    return _mutatingHabitIds.contains(habitId) ||
        _confirmingDeleteIds.contains(habitId);
  }

  Future<void> _toggleArchive(
    AsyncNotifierFamilyProvider<HabitController, HabitState, String> provider,
    Habit habit,
  ) async {
    final succeeded = await _runMutation(
      provider,
      habit,
      () => ref.read(provider.notifier).toggleArchive(habit.id),
    );
    if (!mounted || !succeeded) return;

    showSuccessSnackbar(
      context,
      habit.isArchived ? 'Hábito reactivado' : 'Hábito puesto en pausa',
      icon: habit.isArchived
          ? Icons.play_circle_outline_rounded
          : Icons.pause_circle_outline_rounded,
    );
  }

  Future<void> _confirmDelete(
    AsyncNotifierFamilyProvider<HabitController, HabitState, String> provider,
    Habit habit,
  ) async {
    if (_isHabitBusy(habit.id)) return;
    setState(() => _confirmingDeleteIds.add(habit.id));
    bool? confirmed;
    try {
      confirmed = await showConfirmDialog(
        context: context,
        title: 'Eliminar hábito',
        message:
            '¿Eliminar "${habit.title}"? Esta acción no se puede deshacer.',
        confirmText: 'Eliminar',
        cancelText: 'Cancelar',
        icon: Icons.delete_forever_rounded,
        isDangerous: true,
      );
    } finally {
      if (mounted) {
        setState(() => _confirmingDeleteIds.remove(habit.id));
      }
    }
    if (confirmed != true || !mounted) return;

    final succeeded = await _runMutation(
      provider,
      habit,
      () => ref.read(provider.notifier).deleteHabit(habit.id),
    );
    if (!mounted || !succeeded) return;
    showSuccessSnackbar(context, 'Hábito eliminado');
  }
}

class _SalviaBackground extends StatelessWidget {
  const _SalviaBackground({
    required this.child,
    super.key,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final palette = context.zentraPalette;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: isDark ? Colors.black : null,
        gradient: isDark
            ? null
            : LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                stops: const [0, 0.42, 1],
                colors: [
                  palette.backgroundTop,
                  const Color(0xFFF8F6F0),
                  const Color(0xFFF8F6F0),
                ],
              ),
      ),
      child: child,
    );
  }
}

class _SalviaPage extends StatelessWidget {
  const _SalviaPage({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final horizontalPadding = width < 360 ? 16.0 : 24.0;
    return LayoutBuilder(
      builder: (context, constraints) => Center(
        child: SizedBox(
          width: constraints.maxWidth.clamp(0, 720),
          height: constraints.maxHeight,
          child: Padding(
            padding:
                EdgeInsets.fromLTRB(horizontalPadding, 8, horizontalPadding, 0),
            child: child,
          ),
        ),
      ),
    );
  }
}

class _SalviaHeader extends StatelessWidget {
  const _SalviaHeader({
    required this.state,
    required this.searchController,
    required this.searchFocusNode,
    required this.searchIsOpen,
    required this.selectedCategory,
    required this.onBack,
    required this.onSearchToggle,
    required this.onQueryChanged,
    required this.onCategoryChanged,
  });

  final HabitState state;
  final TextEditingController searchController;
  final FocusNode searchFocusNode;
  final bool searchIsOpen;
  final Category? selectedCategory;
  final VoidCallback onBack;
  final VoidCallback onSearchToggle;
  final ValueChanged<String> onQueryChanged;
  final ValueChanged<Category?> onCategoryChanged;

  @override
  Widget build(BuildContext context) {
    final palette = context.zentraPalette;
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;
    final activeCount = state.activeHabits.length;
    final pausedCount = state.archivedHabits.length;
    final countLabel = [
      '$activeCount ${activeCount == 1 ? 'activo' : 'activos'}',
      if (pausedCount > 0)
        '$pausedCount ${pausedCount == 1 ? 'en pausa' : 'en pausa'}',
    ].join(' · ');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 48,
          child: Row(
            children: [
              IconButton(
                key: const ValueKey('habits-back'),
                tooltip: 'Volver',
                constraints: const BoxConstraints.tightFor(
                  width: 48,
                  height: 48,
                ),
                onPressed: onBack,
                icon: const Icon(Icons.arrow_back_rounded),
              ),
              Expanded(
                child: Semantics(
                  header: true,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      'MIS HÁBITOS',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        color: palette.brandTeal,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 3.2,
                      ),
                    ),
                  ),
                ),
              ),
              IconButton(
                key: const ValueKey('habits-search-toggle'),
                tooltip: searchIsOpen ? 'Cerrar búsqueda' : 'Buscar hábitos',
                constraints: const BoxConstraints.tightFor(
                  width: 48,
                  height: 48,
                ),
                onPressed: onSearchToggle,
                icon: Icon(
                  searchIsOpen ? Icons.close_rounded : Icons.search_rounded,
                  color: palette.inkMuted,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 16,
          runSpacing: 6,
          crossAxisAlignment: WrapCrossAlignment.end,
          alignment: WrapAlignment.spaceBetween,
          children: [
            Text(
              'Tus hábitos',
              style: TextStyle(
                fontFamily: 'Inter',
                color: palette.ink,
                fontSize: 32,
                height: 1.12,
                fontWeight: FontWeight.w400,
                letterSpacing: -0.8,
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 3),
              child: Semantics(
                label: '$activeCount hábitos activos, '
                    '$pausedCount hábitos en pausa',
                child: Text(
                  countLabel,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    color: isDark ? palette.inkSecondary : palette.inkTertiary,
                    fontSize: 13,
                    height: 1.3,
                    fontWeight: FontWeight.w400,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ),
          ],
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          child: searchIsOpen
              ? Padding(
                  padding: const EdgeInsets.only(top: 14),
                  child: TextField(
                    key: const ValueKey('habits-search'),
                    controller: searchController,
                    focusNode: searchFocusNode,
                    onChanged: onQueryChanged,
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      hintText: 'Buscar hábitos',
                      prefixIcon: const Icon(Icons.search_rounded),
                      filled: true,
                      fillColor: palette.surfaceCard,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: BorderSide(
                          color: palette.brandTeal,
                          width: 1.25,
                        ),
                      ),
                    ),
                  ),
                )
              : const SizedBox.shrink(),
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 42,
          child: ListView(
            key: const ValueKey('habits-category-filters'),
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            children: [
              _SalviaCategoryChip(
                key: const ValueKey('habits-category-all'),
                label: 'Todas',
                isSelected: selectedCategory == null,
                onTap: () => onCategoryChanged(null),
              ),
              for (final category in Category.values) ...[
                const SizedBox(width: 7),
                _SalviaCategoryChip(
                  key: ValueKey('habits-category-${category.name}'),
                  label: _compactCategoryLabel(category),
                  dotColor: AppTheme.getSalviaCategoryColor(
                    category,
                    brightness,
                  ),
                  isSelected: selectedCategory == category,
                  onTap: () => onCategoryChanged(category),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _SalviaCategoryChip extends StatelessWidget {
  const _SalviaCategoryChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    super.key,
    this.dotColor,
  });

  final String label;
  final Color? dotColor;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.zentraPalette;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final foreground = isSelected
        ? (isDark ? const Color(0xFF00201B) : const Color(0xFFF8F6F0))
        : (isDark ? palette.inkSecondary : palette.inkTertiary);
    return Semantics(
      button: true,
      selected: isSelected,
      label: 'Filtrar por $label',
      child: Material(
        color: isSelected ? palette.brandTeal : palette.surfaceCard,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 40),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isSelected ? 16 : 14,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!isSelected && dotColor != null) ...[
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: dotColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 7),
                  ],
                  Text(
                    label,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      color: foreground,
                      fontSize: 14,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w400,
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

class _SalviaHabitCard extends StatelessWidget {
  const _SalviaHabitCard({
    required this.habit,
    required this.state,
    required this.isBusy,
    required this.onTap,
    required this.onEdit,
    required this.onToggleArchive,
    required this.onDelete,
  });

  final Habit habit;
  final HabitState state;
  final bool isBusy;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final Future<void> Function() onToggleArchive;
  final Future<void> Function() onDelete;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final palette = context.zentraPalette;
    final categoryColor =
        AppTheme.getSalviaCategoryColor(habit.category, brightness);
    final streak = state.getHabitStreak(habit.id, DateTime.now());
    final isNew = streak == 0;

    return Slidable(
      key: ValueKey('habit-row-${habit.id}'),
      enabled: !isBusy,
      startActionPane: ActionPane(
        motion: const BehindMotion(),
        extentRatio: 0.28,
        children: [
          SlidableAction(
            onPressed: (_) => onEdit(),
            backgroundColor: AppTheme.getCategoryTint(
              habit.category,
              brightness,
            ),
            foregroundColor: categoryColor,
            icon: Icons.edit_rounded,
            label: 'Editar',
            borderRadius: const BorderRadius.horizontal(
              left: Radius.circular(20),
            ),
          ),
        ],
      ),
      endActionPane: ActionPane(
        motion: const BehindMotion(),
        extentRatio: 0.52,
        children: [
          SlidableAction(
            onPressed: (_) => onToggleArchive(),
            backgroundColor: palette.tealTint,
            foregroundColor: palette.brandTeal,
            icon: Icons.pause_circle_outline_rounded,
            label: 'Pausar',
          ),
          SlidableAction(
            onPressed: (_) => onDelete(),
            backgroundColor: Theme.of(context).colorScheme.error,
            foregroundColor: Theme.of(context).colorScheme.onError,
            icon: Icons.delete_outline_rounded,
            label: 'Eliminar',
            borderRadius: const BorderRadius.horizontal(
              right: Radius.circular(20),
            ),
          ),
        ],
      ),
      child: _SalviaCardSurface(
        child: Row(
          children: [
            _SalviaCategorySquircle(category: habit.category),
            const SizedBox(width: 14),
            Expanded(
              child: Semantics(
                button: true,
                label: 'Editar ${habit.title}',
                onTap: onTap,
                child: InkWell(
                  onTap: onTap,
                  excludeFromSemantics: true,
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          habit.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            color: palette.ink,
                            fontSize: 16,
                            height: 1.2,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 3),
                        _SalviaHabitMetadata(
                          habit: habit,
                          streak: streak,
                          isPaused: false,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 4),
            if (isNew)
              _SalviaNewBadge(key: ValueKey('habit-new-${habit.id}'))
            else
              _SalviaActionsMenu(
                habit: habit,
                isBusy: isBusy,
                onSelected: (action) async {
                  switch (action) {
                    case _HabitCardAction.edit:
                      onEdit();
                      return;
                    case _HabitCardAction.toggleArchive:
                      await onToggleArchive();
                      return;
                    case _HabitCardAction.delete:
                      await onDelete();
                      return;
                  }
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _SalviaPausedHabitCard extends StatelessWidget {
  const _SalviaPausedHabitCard({
    required this.habit,
    required this.state,
    required this.isBusy,
    required this.onTap,
    required this.onRestore,
    required this.onDelete,
  });

  final Habit habit;
  final HabitState state;
  final bool isBusy;
  final VoidCallback onTap;
  final Future<void> Function() onRestore;
  final Future<void> Function() onDelete;

  @override
  Widget build(BuildContext context) {
    final palette = context.zentraPalette;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final streak = state.getHabitStreak(habit.id, DateTime.now());
    return Slidable(
      key: ValueKey('habit-row-${habit.id}'),
      enabled: !isBusy,
      startActionPane: ActionPane(
        motion: const BehindMotion(),
        extentRatio: 0.28,
        children: [
          SlidableAction(
            onPressed: (_) => onTap(),
            backgroundColor: AppTheme.getCategoryTint(
              habit.category,
              Theme.of(context).brightness,
            ),
            foregroundColor: AppTheme.getSalviaCategoryColor(
              habit.category,
              Theme.of(context).brightness,
            ),
            icon: Icons.edit_rounded,
            label: 'Editar',
            borderRadius: const BorderRadius.horizontal(
              left: Radius.circular(20),
            ),
          ),
        ],
      ),
      endActionPane: ActionPane(
        motion: const BehindMotion(),
        extentRatio: 0.52,
        children: [
          SlidableAction(
            onPressed: (_) => onRestore(),
            backgroundColor: palette.tealTint,
            foregroundColor: palette.brandTeal,
            icon: Icons.play_circle_outline_rounded,
            label: 'Reactivar',
          ),
          SlidableAction(
            onPressed: (_) => onDelete(),
            backgroundColor: Theme.of(context).colorScheme.error,
            foregroundColor: Theme.of(context).colorScheme.onError,
            icon: Icons.delete_outline_rounded,
            label: 'Eliminar',
            borderRadius: const BorderRadius.horizontal(
              right: Radius.circular(20),
            ),
          ),
        ],
      ),
      child: _SalviaCardSurface(
        paused: true,
        child: Row(
          children: [
            _SalviaCategorySquircle(
              category: habit.category,
              paused: true,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Semantics(
                button: true,
                label: 'Editar hábito en pausa ${habit.title}',
                onTap: onTap,
                child: InkWell(
                  onTap: onTap,
                  excludeFromSemantics: true,
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          habit.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            color: isDark
                                ? palette.inkTertiary
                                : palette.inkSecondary,
                            fontSize: 16,
                            height: 1.2,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 3),
                        _SalviaHabitMetadata(
                          habit: habit,
                          streak: streak,
                          isPaused: true,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 4),
            Semantics(
              key: ValueKey('habit-restore-${habit.id}'),
              button: true,
              enabled: !isBusy,
              label: 'Reactivar ${habit.title}',
              onTap: isBusy ? null : onRestore,
              child: ExcludeSemantics(
                child: IconButton(
                  tooltip: 'Reactivar ${habit.title}',
                  constraints: const BoxConstraints.tightFor(
                    width: 48,
                    height: 48,
                  ),
                  onPressed: isBusy ? null : onRestore,
                  icon: Icon(
                    Icons.play_circle_outline_rounded,
                    color: palette.brandTeal,
                    size: 25,
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

class _SalviaCardSurface extends StatelessWidget {
  const _SalviaCardSurface({
    required this.child,
    this.paused = false,
  });

  final Widget child;
  final bool paused;

  @override
  Widget build(BuildContext context) {
    final palette = context.zentraPalette;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = paused
        ? (isDark
            ? const Color(0xFF0B0F0E)
            : palette.surfaceCard.withValues(alpha: 0.62))
        : palette.surfaceCard;
    return Material(
      color: surface,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        constraints: const BoxConstraints(minHeight: 72),
        padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: isDark
              ? const []
              : const [
                  BoxShadow(
                    color: Color(0x0D1B2523),
                    blurRadius: 16,
                    offset: Offset(0, 4),
                  ),
                ],
        ),
        child: child,
      ),
    );
  }
}

class _SalviaCategorySquircle extends StatelessWidget {
  const _SalviaCategorySquircle({
    required this.category,
    this.paused = false,
  });

  final Category category;
  final bool paused;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final categoryColor = AppTheme.getSalviaCategoryColor(category, brightness);
    return Opacity(
      opacity: paused ? 0.72 : 1,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppTheme.getCategoryTint(category, brightness),
          borderRadius: BorderRadius.circular(13),
        ),
        alignment: Alignment.center,
        child: Icon(
          AppTheme.getCategoryIcon(category),
          color: categoryColor,
          size: 21,
        ),
      ),
    );
  }
}

class _SalviaHabitMetadata extends StatelessWidget {
  const _SalviaHabitMetadata({
    required this.habit,
    required this.streak,
    required this.isPaused,
  });

  final Habit habit;
  final int streak;
  final bool isPaused;

  @override
  Widget build(BuildContext context) {
    final palette = context.zentraPalette;
    final frequency = _salviaFrequencyLabel(context, habit);
    if (isPaused) {
      return Text(
        streak > 0 ? 'Tu racha de $streak te espera' : 'Lista para volver',
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontFamily: 'Inter',
          color: palette.inkDisabled,
          fontSize: 13,
          height: 1.2,
          fontWeight: FontWeight.w400,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      );
    }

    return Text.rich(
      TextSpan(
        children: [
          TextSpan(text: frequency),
          if (streak > 0) ...[
            const TextSpan(text: ' · '),
            WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: Icon(
                Icons.local_fire_department_rounded,
                size: 14,
                color: AppTheme.getSalviaCategoryColor(
                  Category.movimiento,
                  Theme.of(context).brightness,
                ),
              ),
            ),
            TextSpan(text: ' $streak'),
          ] else
            const TextSpan(text: ' · empieza hoy'),
        ],
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontFamily: 'Inter',
        color: palette.inkMuted,
        fontSize: 13,
        height: 1.2,
        fontWeight: FontWeight.w400,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    );
  }
}

class _SalviaNewBadge extends StatelessWidget {
  const _SalviaNewBadge({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = context.zentraPalette;
    return Semantics(
      label: 'Hábito nuevo',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: palette.tealTint,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          'NUEVO',
          style: TextStyle(
            fontFamily: 'Inter',
            color: palette.brandTeal,
            fontSize: 10,
            height: 1,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
      ),
    );
  }
}

class _SalviaActionsMenu extends StatelessWidget {
  const _SalviaActionsMenu({
    required this.habit,
    required this.isBusy,
    required this.onSelected,
  });

  final Habit habit;
  final bool isBusy;
  final ValueChanged<_HabitCardAction> onSelected;

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (buttonContext) {
        final openMenu = isBusy ? null : () => _openMenu(buttonContext);
        return Semantics(
          key: ValueKey('habit-actions-${habit.id}'),
          button: true,
          enabled: !isBusy,
          label: 'Más acciones para ${habit.title}',
          onTap: openMenu,
          child: ExcludeSemantics(
            child: IconButton(
              tooltip: 'Más acciones para ${habit.title}',
              constraints: const BoxConstraints.tightFor(
                width: 48,
                height: 48,
              ),
              onPressed: openMenu,
              icon: Icon(
                Icons.more_horiz_rounded,
                color: context.zentraPalette.inkDisabled,
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _openMenu(BuildContext buttonContext) async {
    final buttonBox = buttonContext.findRenderObject()! as RenderBox;
    final overlay = Navigator.of(buttonContext).overlay!;
    final overlayBox = overlay.context.findRenderObject()! as RenderBox;
    final topLeft = buttonBox.localToGlobal(
      Offset.zero,
      ancestor: overlayBox,
    );
    final selected = await showMenu<_HabitCardAction>(
      context: buttonContext,
      position: RelativeRect.fromLTRB(
        topLeft.dx,
        topLeft.dy + buttonBox.size.height,
        overlayBox.size.width - topLeft.dx - buttonBox.size.width,
        overlayBox.size.height - topLeft.dy - buttonBox.size.height,
      ),
      items: [
        PopupMenuItem(
          key: ValueKey('habit-action-edit-${habit.id}'),
          value: _HabitCardAction.edit,
          child: const ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.edit_rounded),
            title: Text('Editar'),
          ),
        ),
        PopupMenuItem(
          key: ValueKey('habit-action-archive-${habit.id}'),
          value: _HabitCardAction.toggleArchive,
          child: const ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.pause_circle_outline_rounded),
            title: Text('Pausar'),
          ),
        ),
        PopupMenuItem(
          key: ValueKey('habit-action-delete-${habit.id}'),
          value: _HabitCardAction.delete,
          child: const ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.delete_outline_rounded),
            title: Text('Eliminar'),
          ),
        ),
      ],
    );
    if (selected != null) onSelected(selected);
  }
}

class _SalviaSectionLabel extends StatelessWidget {
  const _SalviaSectionLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      header: true,
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontFamily: 'Inter',
          color: context.zentraPalette.inkMuted,
          fontSize: 12,
          height: 1.2,
          fontWeight: FontWeight.w500,
          letterSpacing: 3.2,
        ),
      ),
    );
  }
}

class _SalviaCreateBar extends StatelessWidget {
  const _SalviaCreateBar({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return _SalviaBackground(
      child: SafeArea(
        top: false,
        minimum: const EdgeInsets.fromLTRB(24, 10, 24, 18),
        child: Align(
          alignment: Alignment.topCenter,
          heightFactor: 1,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 672),
            child: _SalviaCreateButton(onPressed: onPressed),
          ),
        ),
      ),
    );
  }
}

class _SalviaCreateButton extends StatelessWidget {
  const _SalviaCreateButton({
    required this.onPressed,
    super.key,
  });

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final palette = context.zentraPalette;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Semantics(
      button: true,
      label: 'Crear un nuevo hábito',
      child: SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          key: const ValueKey('habits-add'),
          onPressed: onPressed,
          style: FilledButton.styleFrom(
            minimumSize: const Size(double.infinity, 54),
            backgroundColor: palette.brandTeal,
            foregroundColor:
                isDark ? const Color(0xFF00201B) : const Color(0xFFF8F6F0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            textStyle: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
            elevation: 0,
            shadowColor: Colors.transparent,
          ),
          icon: const Icon(Icons.add_rounded, size: 22),
          label: const Text('Nuevo hábito'),
        ),
      ),
    );
  }
}

class _SalviaEmptyResults extends StatelessWidget {
  const _SalviaEmptyResults({
    required this.hasQuery,
    required this.hasCategory,
    required this.onClear,
  });

  final bool hasQuery;
  final bool hasCategory;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final palette = context.zentraPalette;
    return Center(
      child: Container(
        key: const ValueKey('habits-empty-results'),
        constraints: const BoxConstraints(maxWidth: 420),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search_off_rounded,
              color: palette.brandTeal,
              size: 40,
            ),
            const SizedBox(height: 14),
            Text(
              'No encontramos coincidencias',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Inter',
                color: palette.ink,
                fontSize: 20,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              hasQuery
                  ? 'Prueba con otro nombre o categoría.'
                  : hasCategory
                      ? 'Aún no hay hábitos en esta categoría.'
                      : 'Tu biblioteca está esperando.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Inter',
                color: palette.inkTertiary,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 14),
            TextButton(
              onPressed: onClear,
              child: const Text('Limpiar búsqueda'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SalviaEmptyState extends StatelessWidget {
  const _SalviaEmptyState({
    required this.includesCreateAction,
    required this.onCreateHabit,
  });

  final bool includesCreateAction;
  final VoidCallback onCreateHabit;

  @override
  Widget build(BuildContext context) {
    final palette = context.zentraPalette;
    return CustomScrollView(
      key: const ValueKey('habits-single-column-layout'),
      slivers: [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Column(
            children: [
              const _SalviaStaticTopline(),
              const Spacer(),
              Icon(Icons.spa_outlined, size: 54, color: palette.brandTeal),
              const SizedBox(height: 18),
              Text(
                'Tu espacio está listo',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Inter',
                  color: palette.ink,
                  fontSize: 24,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Crea un hábito pequeño y deja que la constancia haga el resto.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Inter',
                  color: palette.inkTertiary,
                  fontSize: 14,
                  height: 1.45,
                ),
              ),
              const Spacer(),
              if (includesCreateAction)
                _SalviaCreateButton(
                  key: const ValueKey('habits-empty-add'),
                  onPressed: onCreateHabit,
                ),
              const SizedBox(height: 18),
            ],
          ),
        ),
      ],
    );
  }
}

class _SalviaLoadingState extends StatelessWidget {
  const _SalviaLoadingState({
    required this.includesCreateAction,
    required this.onCreateHabit,
  });

  final bool includesCreateAction;
  final VoidCallback onCreateHabit;

  @override
  Widget build(BuildContext context) {
    final palette = context.zentraPalette;
    return ListView(
      key: const ValueKey('habits-loading-scroll'),
      physics: const BouncingScrollPhysics(),
      children: [
        const _SalviaStaticTopline(),
        const SizedBox(height: 36),
        Container(
          key: const ValueKey('habits-loading-static'),
          height: 34,
          width: 180,
          decoration: BoxDecoration(
            color: palette.progressTrack,
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        const SizedBox(height: 26),
        for (var index = 0; index < 4; index++) ...[
          Container(
            height: 72,
            decoration: BoxDecoration(
              color: palette.surfaceCard,
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          const SizedBox(height: 10),
        ],
        if (includesCreateAction) ...[
          const SizedBox(height: 18),
          _SalviaCreateButton(onPressed: onCreateHabit),
        ],
      ],
    );
  }
}

class _SalviaErrorState extends StatelessWidget {
  const _SalviaErrorState({required this.onRetry});

  final Future<void> Function()? onRetry;

  @override
  Widget build(BuildContext context) {
    final palette = context.zentraPalette;
    return CustomScrollView(
      slivers: [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Column(
            children: [
              const _SalviaStaticTopline(),
              const Spacer(),
              Icon(
                Icons.cloud_off_outlined,
                size: 48,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                'No pudimos cargar tus hábitos',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Inter',
                  color: palette.ink,
                  fontSize: 21,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Tus datos siguen a salvo. Intentemos otra vez.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Inter',
                  color: palette.inkTertiary,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Reintentar'),
              ),
              const Spacer(),
            ],
          ),
        ),
      ],
    );
  }
}

class _SalviaStaticTopline extends StatelessWidget {
  const _SalviaStaticTopline();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: Row(
        children: [
          const SizedBox(width: 48),
          Expanded(
            child: Center(
              child: Text(
                'MIS HÁBITOS',
                style: TextStyle(
                  fontFamily: 'Inter',
                  color: context.zentraPalette.brandTeal,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 3.2,
                ),
              ),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }
}

String _compactCategoryLabel(Category category) {
  return switch (category) {
    Category.movimiento => 'Movim.',
    Category.foco => 'Enfoque',
    _ => category.label,
  };
}

String _salviaFrequencyLabel(BuildContext context, Habit habit) {
  if (habit.isOneTime) {
    final scheduledDate = habit.scheduledDate;
    if (scheduledDate == null) return 'Una vez';
    return MaterialLocalizations.of(context).formatMediumDate(scheduledDate);
  }

  final frequency = habit.frequency;
  if (!frequency.isWeekly) return 'Cuando quieras';
  final days = frequency.daysOfWeek;
  if (days.length == 7) return 'Diario';
  if (days.length == 5 && days.every((day) => day >= 1 && day <= 5)) {
    return 'L–V';
  }
  if (days.length == 2 && days.contains(6) && days.contains(7)) {
    return 'S–D';
  }
  return days.map((day) => Weekday.fromValue(day).shortLabel).join(' · ');
}

String _normalizeForSearch(String value) {
  return value
      .toLowerCase()
      .replaceAll(RegExp('[áàäâ]'), 'a')
      .replaceAll(RegExp('[éèëê]'), 'e')
      .replaceAll(RegExp('[íìïî]'), 'i')
      .replaceAll(RegExp('[óòöô]'), 'o')
      .replaceAll(RegExp('[úùüû]'), 'u')
      .replaceAll('ñ', 'n');
}
