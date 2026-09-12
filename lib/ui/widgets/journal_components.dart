import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../domain/together/recap_service.dart';
import 'editorial_background.dart';

class JournalPage extends StatelessWidget {
  const JournalPage({super.key, required this.slivers, this.onRefresh});
  final List<Widget> slivers;
  final Future<void> Function()? onRefresh;

  @override
  Widget build(BuildContext context) {
    Widget scroll = CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      slivers: [
        const SliverToBoxAdapter(child: SizedBox(height: 20)),
        ...slivers,
        const SliverToBoxAdapter(child: SizedBox(height: 28)),
      ],
    );
    if (onRefresh != null) {
      scroll = RefreshIndicator(onRefresh: onRefresh!, child: scroll);
    }
    return EditorialBackground(
      child: SafeArea(
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: scroll,
          ),
        ),
      ),
    );
  }
}

class JournalBlock extends StatelessWidget {
  const JournalBlock({super.key, required this.child, this.bottom = 24});
  final Widget child;
  final double bottom;
  @override
  Widget build(BuildContext context) => SliverPadding(
    padding: EdgeInsets.fromLTRB(20, 0, 20, bottom),
    sliver: SliverToBoxAdapter(child: child),
  );
}

class JournalHeader extends StatelessWidget {
  const JournalHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.eyebrow,
    this.action,
  });
  final String title;
  final String subtitle;
  final String? eyebrow;
  final Widget? action;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final compactHeadline =
          constraints.maxWidth < 500 &&
          MediaQuery.textScalerOf(context).scale(14) > 20;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (eyebrow != null || action != null) ...[
            Row(
              children: [
                Expanded(
                  child: eyebrow == null
                      ? const SizedBox.shrink()
                      : Text(
                          eyebrow!,
                          style: AppTheme.sans(
                            size: 12,
                            weight: FontWeight.w700,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                ),
                if (action != null) ...[const SizedBox(width: 8), action!],
              ],
            ),
            const SizedBox(height: 8),
          ],
          Text(
            title,
            style: AppTheme.serif(
              size: compactHeadline ? 24 : 32,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: AppTheme.sans(
              size: 14,
              height: 1.5,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      );
    },
  );
}

class WeekPresenceStrip extends StatelessWidget {
  const WeekPresenceStrip({super.key, required this.days});
  final List<WeekDayMark> days;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    return Semantics(
      label: 'Hari aktif tujuh hari terakhir',
      child: Row(
        children: [
          for (final day in days)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: Column(
                  children: [
                    Text(
                      day.shortLabel,
                      style: AppTheme.sans(
                        size: 10,
                        weight: FontWeight.w700,
                        color: day.active ? c.secondary : c.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      height: 10,
                      decoration: BoxDecoration(
                        color: day.active
                            ? c.secondary
                            : c.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class JournalSection extends StatelessWidget {
  const JournalSection({
    super.key,
    required this.title,
    this.action,
    this.onAction,
  });
  final String title;
  final String? action;
  final VoidCallback? onAction;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final largeText = MediaQuery.textScalerOf(context).scale(14) > 20;
      final titleWidget = Text(title, style: AppTheme.serif(size: 22));
      final actionWidget = action == null
          ? null
          : TextButton(
              onPressed: onAction,
              child: Text(action!, style: const TextStyle(fontSize: 12)),
            );
      if (largeText && constraints.maxWidth < 500) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [titleWidget, ?actionWidget],
        );
      }
      return Row(
        children: [
          Expanded(child: titleWidget),
          ?actionWidget,
        ],
      );
    },
  );
}

class JournalNotice extends StatelessWidget {
  const JournalNotice({
    super.key,
    required this.title,
    required this.message,
    this.action,
    this.onAction,
    this.icon = Icons.auto_stories_outlined,
    this.error = false,
  });
  final String title;
  final String message;
  final String? action;
  final VoidCallback? onAction;
  final IconData icon;
  final bool error;
  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: error
            ? c.errorContainer
            : c.surfaceContainerHighest.withValues(alpha: .6),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            error ? Icons.error_outline : icon,
            size: 30,
            color: error ? c.onErrorContainer : c.primary,
          ),
          const SizedBox(height: 14),
          Text(
            title,
            style: AppTheme.serif(
              size: 22,
              color: error ? c.onErrorContainer : c.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: TextStyle(
              height: 1.5,
              color: error ? c.onErrorContainer : c.onSurfaceVariant,
            ),
          ),
          if (action != null) ...[
            const SizedBox(height: 14),
            OutlinedButton(onPressed: onAction, child: Text(action!)),
          ],
        ],
      ),
    );
  }
}

class JournalLoading extends StatelessWidget {
  const JournalLoading({super.key});
  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Memuat catatan',
    child: Column(
      children: List.generate(
        3,
        (i) => Container(
          height: i == 0 ? 22 : 68,
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    ),
  );
}

void journalMessage(BuildContext context, String message) {
  ScaffoldMessenger.of(context).hideCurrentSnackBar();
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}

Future<bool> confirmJournalAction(
  BuildContext context, {
  required String title,
  required String message,
  required String confirm,
}) async =>
    await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(confirm),
          ),
        ],
      ),
    ) ??
    false;
