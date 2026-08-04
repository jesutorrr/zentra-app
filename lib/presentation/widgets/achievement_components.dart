import 'package:flutter/material.dart';

import '../../domain/user_profile.dart';
import '../design_tokens.dart';
import '../theme.dart';

IconData achievementIcon(String symbol) {
  return switch (symbol) {
    'seed' => Icons.spa_rounded,
    'focus' ||
    'lens' ||
    'target' ||
    'deep_focus' =>
      Icons.center_focus_strong_rounded,
    'path' || 'steps' => Icons.route_rounded,
    'check' => Icons.check_rounded,
    'milestone' || 'summit' => Icons.flag_rounded,
    'mountain' => Icons.landscape_rounded,
    'flame' => Icons.local_fire_department_rounded,
    'calendar' || 'year' => Icons.calendar_month_rounded,
    'waves' => Icons.waves_rounded,
    'moon' => Icons.dark_mode_rounded,
    'ritual' => Icons.self_improvement_rounded,
    'sun' => Icons.light_mode_rounded,
    'orbit' || 'season' => Icons.public_rounded,
    'three' => Icons.filter_3_rounded,
    'constellation' => Icons.auto_awesome_rounded,
    'shield' => Icons.shield_outlined,
    'clarity' => Icons.blur_on_rounded,
    'minute' || 'hourglass' => Icons.hourglass_bottom_rounded,
    'garden' => Icons.local_florist_rounded,
    'link' || 'bridge' => Icons.join_inner_rounded,
    'water' => Icons.water_drop_rounded,
    'movement' => Icons.directions_run_rounded,
    'prism' || 'spectrum' => Icons.palette_outlined,
    'balance' || 'mandala' => Icons.balance_rounded,
    'map' => Icons.map_outlined,
    'compass' => Icons.explore_outlined,
    'blueprint' => Icons.grid_view_rounded,
    'weekend' => Icons.weekend_outlined,
    _ => Icons.auto_awesome_rounded,
  };
}

Color achievementColor(AchievementGroup group, ColorScheme colors) {
  return switch (group) {
    AchievementGroup.beginnings => colors.primary,
    AchievementGroup.rhythm => AppTheme.successGreen,
    AchievementGroup.balance => colors.secondary,
    AchievementGroup.focus => AppTheme.accentOrange,
    AchievementGroup.exploration => colors.tertiary,
  };
}

Future<void> showAchievementCollection(
  BuildContext context, {
  required UserProfile profile,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    useSafeArea: true,
    builder: (context) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.88,
      minChildSize: 0.5,
      maxChildSize: 0.96,
      builder: (context, scrollController) => _AchievementCollection(
        profile: profile,
        scrollController: scrollController,
      ),
    ),
  );
}

class AchievementProgressTile extends StatelessWidget {
  final Achievement achievement;
  final UserProfile profile;
  final bool compact;

  const AchievementProgressTile({
    required this.achievement,
    required this.profile,
    this.compact = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isUnlocked = profile.unlockedAchievements.contains(achievement.id);
    final current = achievement.progress(profile).clamp(
          0,
          achievement.requirement,
        );
    final progress = achievement.progressFraction(profile);
    final accent = achievementColor(achievement.group, colors);
    final semanticState = isUnlocked
        ? 'Desbloqueado. Recompensa ${achievement.rewardXp} XP.'
        : '$current de ${achievement.requirement}. '
            'Recompensa ${achievement.rewardXp} XP.';

    return Semantics(
      container: true,
      label: '${achievement.title}. ${achievement.description}',
      value: semanticState,
      child: Container(
        padding:
            EdgeInsets.all(compact ? context.spacing.md : context.spacing.lg),
        decoration: BoxDecoration(
          color: isUnlocked
              ? accent.withValues(alpha: 0.1)
              : colors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(context.radii.medium),
          border: Border.all(
            color: isUnlocked
                ? accent.withValues(alpha: 0.32)
                : colors.outlineVariant.withValues(alpha: 0.55),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _AchievementMark(
                  achievement: achievement,
                  unlocked: isUnlocked,
                  size: compact ? 40 : 46,
                ),
                SizedBox(width: context.spacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        achievement.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: context.spacing.xxs),
                      Text(
                        achievement.description,
                        maxLines: compact ? 1 : 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: context.spacing.sm),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: context.spacing.sm,
                    vertical: context.spacing.xxs,
                  ),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(context.radii.pill),
                  ),
                  child: Text(
                    '+${achievement.rewardXp} XP',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: accent,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            if (!isUnlocked) ...[
              SizedBox(height: context.spacing.md),
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(context.radii.pill),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 7,
                        color: accent,
                        backgroundColor: accent.withValues(alpha: 0.12),
                      ),
                    ),
                  ),
                  SizedBox(width: context.spacing.sm),
                  Text(
                    '$current/${achievement.requirement}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colors.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _AchievementCollection extends StatelessWidget {
  final UserProfile profile;
  final ScrollController scrollController;

  const _AchievementCollection({
    required this.profile,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final unlocked = Achievements.getUnlocked(profile.unlockedAchievements);

    return CustomScrollView(
      key: const ValueKey('achievement-collection'),
      controller: scrollController,
      slivers: [
        SliverPadding(
          padding: EdgeInsets.fromLTRB(
            context.spacing.lg,
            context.spacing.sm,
            context.spacing.lg,
            context.spacing.xxl,
          ),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              Semantics(
                header: true,
                child: Text(
                  'Tu colección',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              SizedBox(height: context.spacing.xs),
              Text(
                '${unlocked.length} de ${Achievements.all.length} señales '
                'desbloqueadas. Cada una nace de progreso verificable.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
              SizedBox(height: context.spacing.xl),
              for (final group in AchievementGroup.values) ...[
                _GroupHeader(group: group, profile: profile),
                SizedBox(height: context.spacing.md),
                for (final achievement in Achievements.getByGroup(group)) ...[
                  AchievementProgressTile(
                    achievement: achievement,
                    profile: profile,
                  ),
                  SizedBox(height: context.spacing.sm),
                ],
                SizedBox(height: context.spacing.xl),
              ],
            ]),
          ),
        ),
      ],
    );
  }
}

class _GroupHeader extends StatelessWidget {
  final AchievementGroup group;
  final UserProfile profile;

  const _GroupHeader({required this.group, required this.profile});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = achievementColor(group, theme.colorScheme);
    final achievements = Achievements.getByGroup(group);
    final unlocked = achievements
        .where(
          (achievement) =>
              profile.unlockedAchievements.contains(achievement.id),
        )
        .length;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(context.radii.small),
          ),
          child: Icon(
            achievementIcon(achievements.first.symbol),
            color: color,
            size: 20,
          ),
        ),
        SizedBox(width: context.spacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                group.label,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                group.description,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        SizedBox(width: context.spacing.sm),
        Text(
          '$unlocked/${achievements.length}',
          style: theme.textTheme.labelMedium?.copyWith(
            color: color,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _AchievementMark extends StatelessWidget {
  final Achievement achievement;
  final bool unlocked;
  final double size;

  const _AchievementMark({
    required this.achievement,
    required this.unlocked,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final accent = achievementColor(achievement.group, colors);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: unlocked
            ? LinearGradient(
                colors: [
                  accent.withValues(alpha: 0.95),
                  accent.withValues(alpha: 0.65),
                ],
              )
            : null,
        color: unlocked ? null : colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(context.radii.small),
      ),
      child: Icon(
        unlocked ? achievementIcon(achievement.symbol) : Icons.lock_outline,
        size: size * 0.5,
        color: unlocked ? colors.onPrimary : colors.onSurfaceVariant,
      ),
    );
  }
}
