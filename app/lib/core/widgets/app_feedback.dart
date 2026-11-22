import 'package:flutter/material.dart';
import 'app_toast.dart';

/// Design system feedback helper for displaying elegant, localized SnackBars/Toasts.
/// Delegates to [AppToast] for unified capsule floating notifications across the app.
class AppFeedback {
  AppFeedback._();

  static void showError(BuildContext context, String message) {
    AppToast.showError(context, message);
  }

  static void showSuccess(BuildContext context, String message) {
    AppToast.showSuccess(context, message);
  }

  static void showWarning(BuildContext context, String message) {
    AppToast.showWarning(context, message);
  }

  static void showInfo(BuildContext context, String message) {
    AppToast.showInfo(context, message);
  }
}
