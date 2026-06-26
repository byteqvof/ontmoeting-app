import 'package:flutter/material.dart';

import '../../app/theme/toch_theme.dart';
import '../services/safety_report_reason.dart';

class SafetyReportDraft {
  const SafetyReportDraft({required this.reason, required this.details});

  final SafetyReportReason reason;
  final String details;
}

Future<SafetyReportDraft?> showSafetyReportDialog(
  BuildContext context, {
  required String title,
  required String body,
  required String confirmLabel,
}) async {
  final controller = TextEditingController();
  var selectedReason = SafetyReportReason.inappropriateBehavior;

  final result = await showModalBottomSheet<SafetyReportDraft>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      return StatefulBuilder(
        builder: (context, setSheetState) {
          final colors = context.toch;
          final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

          return Padding(
            padding: EdgeInsets.only(bottom: bottomInset),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: colors.card,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
                boxShadow: [
                  BoxShadow(
                    color: colors.ink.withValues(alpha: .18),
                    blurRadius: 44,
                    offset: const Offset(0, -14),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 26),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: colors.line,
                            borderRadius: BorderRadius.circular(99),
                          ),
                          child: const SizedBox(width: 40, height: 5),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleLarge
                            ?.copyWith(
                              color: colors.ink,
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        body,
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(
                              color: colors.ink3,
                              fontWeight: FontWeight.w700,
                              height: 1.35,
                            ),
                      ),
                      const SizedBox(height: 16),
                      for (final reason in SafetyReportReason.values)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _ReasonRow(
                            reason: reason,
                            selected: selectedReason == reason,
                            onTap: () {
                              setSheetState(() {
                                selectedReason = reason;
                              });
                            },
                          ),
                        ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: controller,
                        maxLength: 500,
                        minLines: 2,
                        maxLines: 4,
                        decoration: const InputDecoration(
                          labelText: 'Extra informatie',
                          hintText: 'Wat moeten we weten?',
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: FilledButton.icon(
                          onPressed: () {
                            Navigator.of(sheetContext).pop(
                              SafetyReportDraft(
                                reason: selectedReason,
                                details: controller.text.trim(),
                              ),
                            );
                          },
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFFF8E6E1),
                            foregroundColor: const Color(0xFFC0492F),
                            shape: const StadiumBorder(),
                            textStyle: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          icon: const Icon(Icons.flag_outlined),
                          label: Text(confirmLabel),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      );
    },
  );
  controller.dispose();
  return result;
}

class _ReasonRow extends StatelessWidget {
  const _ReasonRow({
    required this.reason,
    required this.selected,
    required this.onTap,
  });

  final SafetyReportReason reason;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.toch;

    return Material(
      color: selected ? colors.green100 : colors.surface2,
      borderRadius: BorderRadius.circular(TochRadius.md),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(TochRadius.md),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(TochRadius.md),
            border: Border.all(
              color: selected ? colors.green : colors.line,
              width: selected ? 2 : 1.5,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    reason.label,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: colors.ink,
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                ),
                Icon(
                  selected
                      ? Icons.check_circle_rounded
                      : Icons.chevron_right_rounded,
                  color: selected ? colors.green : colors.ink4,
                  size: 19,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
