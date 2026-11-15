import 'package:flutter/material.dart';
import '../../features/shell/presentation/widgets/main_header.dart';

class AppHeader extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback? onOpenDrawer;

  const AppHeader({
    super.key,
    this.onOpenDrawer,
  });

  @override
  Size get preferredSize => const Size.fromHeight(110);

  @override
  Widget build(BuildContext context) {
    return MainHeader(onOpenDrawer: onOpenDrawer);
  }
}
