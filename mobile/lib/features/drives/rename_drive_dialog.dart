import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:radar_alert/app.dart';
import 'package:radar_alert/core/theme/app_theme.dart';
import 'package:radar_alert/data/api/radar_api_client.dart';

/// Shows a dialog to rename a drive. Returns the new name on success
/// (empty string means the name was cleared), or null if cancelled/failed.
Future<String?> showRenameDriveDialog(
  BuildContext context,
  WidgetRef ref, {
  required String driveId,
  String? currentName,
}) {
  final textController = TextEditingController(text: currentName ?? '');
  return showDialog<String>(
    context: context,
    builder: (dialogContext) {
      var saving = false;
      String? error;
      return StatefulBuilder(
        builder: (context, setState) {
          Future<void> save() async {
            setState(() {
              saving = true;
              error = null;
            });
            try {
              final name = textController.text.trim();
              await ref.read(drivesControllerProvider).rename(driveId, name);
              if (dialogContext.mounted) {
                Navigator.of(dialogContext).pop(name);
              }
            } on ApiException catch (e) {
              setState(() {
                saving = false;
                error = e.message;
              });
            } catch (e) {
              setState(() {
                saving = false;
                error = 'Kaydedilemedi.';
              });
            }
          }

          return AlertDialog(
            backgroundColor: AppColors.surface,
            title: const Text('Sürüşü adlandır'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: textController,
                  autofocus: true,
                  maxLength: 120,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => saving ? null : save(),
                  decoration: InputDecoration(
                    hintText: 'Örn. Eve dönüş',
                    errorText: error,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: saving ? null : () => Navigator.of(dialogContext).pop(),
                child: const Text('İptal'),
              ),
              FilledButton(
                onPressed: saving ? null : save,
                child: saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.white,
                        ),
                      )
                    : const Text('Kaydet'),
              ),
            ],
          );
        },
      );
    },
  );
}
