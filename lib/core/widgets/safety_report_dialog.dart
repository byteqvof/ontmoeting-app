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

  final result = await showDialog<SafetyReportDraft>(
    context: context,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text(title),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(body),
                  const SizedBox(height: TochSpacing.md),
                  DropdownButtonFormField<SafetyReportReason>(
                    initialValue: selectedReason,
                    decoration: const InputDecoration(labelText: 'Categorie'),
                    items: SafetyReportReason.values
                        .map(
                          (reason) => DropdownMenuItem(
                            value: reason,
                            child: Text(reason.label),
                          ),
                        )
                        .toList(),
                    onChanged: (reason) {
                      if (reason == null) {
                        return;
                      }
                      setDialogState(() {
                        selectedReason = reason;
                      });
                    },
                  ),
                  const SizedBox(height: TochSpacing.md),
                  TextField(
                    controller: controller,
                    maxLength: 500,
                    minLines: 2,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      hintText: 'Wat moeten we weten?',
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Annuleer'),
              ),
              FilledButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop(
                    SafetyReportDraft(
                      reason: selectedReason,
                      details: controller.text.trim(),
                    ),
                  );
                },
                child: Text(confirmLabel),
              ),
            ],
          );
        },
      );
    },
  );
  controller.dispose();
  return result;
}
