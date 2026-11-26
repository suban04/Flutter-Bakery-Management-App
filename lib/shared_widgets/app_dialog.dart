import 'package:flutter/material.dart';
import 'package:jantabackery/core/constants/app_colors.dart';

class AppDialog {
  static Future<bool> confirmDelete(
      BuildContext context, {
        required String title,
        required String message,
        String confirmText = 'Delete',
      }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(confirmText),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  static Future<T?> showFormDialog<T>(
      BuildContext context, {
        required String title,
        required Widget content,
        required List<Widget> actions,
      }) {
    return showDialog<T>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        content: SingleChildScrollView(child: content),
        actions: actions,
      ),
    );
  }
}