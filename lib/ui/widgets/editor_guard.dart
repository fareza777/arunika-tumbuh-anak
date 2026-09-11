import 'package:flutter/material.dart';

/// Protects drafts from the system back button and the editor's close button.
/// Sheet callers also disable barrier and drag dismissal.
class EditorGuard extends StatefulWidget {
  const EditorGuard({
    super.key,
    required this.isDirty,
    required this.isBusy,
    required this.child,
  });

  final bool Function() isDirty;
  final bool Function() isBusy;
  final Widget child;

  @override
  State<EditorGuard> createState() => EditorGuardState();
}

class EditorGuardState extends State<EditorGuard> {
  bool _asking = false;

  Future<void> requestClose() async {
    if (widget.isBusy() || _asking) return;
    if (!widget.isDirty()) {
      closeAfterSave();
      return;
    }
    _asking = true;
    final discard = await confirmEditorAction(
      context,
      title: 'Buang perubahan?',
      message: 'Perubahan yang belum disimpan akan hilang.',
      confirmLabel: 'Buang perubahan',
      cancelLabel: 'Lanjut mengisi',
      destructive: true,
    );
    _asking = false;
    if (discard && mounted) closeAfterSave();
  }

  void closeAfterSave({bool saved = false}) {
    if (mounted) Navigator.of(context).pop(saved ? true : null);
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !widget.isDirty() && !widget.isBusy(),
    onPopInvokedWithResult: (didPop, _) {
      if (!didPop) requestClose();
    },
    child: widget.child,
  );
}

Future<bool> confirmEditorAction(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  String cancelLabel = 'Batal',
  bool destructive = false,
}) async {
  final colors = Theme.of(context).colorScheme;
  return await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          scrollable: true,
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(cancelLabel),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                minimumSize: const Size(48, 48),
                backgroundColor: destructive ? colors.error : null,
                foregroundColor: destructive ? colors.onError : null,
              ),
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(confirmLabel),
            ),
          ],
        ),
      ) ??
      false;
}

/// Keeps the header and save action visible while the form scrolls above the
/// keyboard. The content may grow with the device's text-size preference.
class EditorSheetFrame extends StatelessWidget {
  const EditorSheetFrame({
    super.key,
    required this.title,
    required this.onClose,
    required this.child,
    required this.saveButton,
  });

  final String title;
  final VoidCallback? onClose;
  final Widget child;
  final Widget saveButton;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(title, style: theme.textTheme.headlineMedium),
                  ),
                  IconButton(
                    onPressed: onClose,
                    tooltip: 'Tutup',
                    constraints: const BoxConstraints(
                      minWidth: 48,
                      minHeight: 48,
                    ),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                child: child,
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
              child: saveButton,
            ),
          ],
        ),
      ),
    );
  }
}

class EditorError extends StatelessWidget {
  const EditorError({super.key, required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      liveRegion: true,
      child: Material(
        color: colors.errorContainer,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline_rounded, color: colors.onErrorContainer),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colors.onErrorContainer,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
