import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_badge.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_modal.dart';
import '../stylist_provider.dart';

class StylistChatSheet extends ConsumerStatefulWidget {
  const StylistChatSheet({super.key});

  @override
  ConsumerState<StylistChatSheet> createState() => _StylistChatSheetState();
}

class _StylistChatSheetState extends ConsumerState<StylistChatSheet> {
  final _inputCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  @override
  void dispose() {
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _send() {
    final text = _inputCtrl.text.trim();
    if (text.isEmpty) return;

    ref.read(stylistProvider.notifier).sendMessage(text);
    _inputCtrl.clear();

    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent + 80,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final strings = context.strings;
    final stylistState = ref.watch(stylistProvider);
    final messages = stylistState.chatMessages;

    return AppBottomSheetShell(
      title: strings.styChatFullTitle,
      maxHeightFactor: 0.90,
      scrollable: false,
      contentPadding: EdgeInsetsDirectional.zero,
      titleLeading: Container(
        width: 32,
        height: 32,
        decoration: const BoxDecoration(
          color: Color(0xFF2B7A78),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Text(
            strings.tr('رامین').substring(0, 1),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ),
      ),
      headerActions: [
        AppBadge(
          size: AppBadgeSize.sm,
          child: Text(
            strings.freeQuotaText(stylistState.dailyFreeChatsLeft, 10),
            style: TextStyle(fontSize: 9, color: colors.mu),
          ),
        ),
      ],
      child: Column(
        children: [
          // Messages list
          Expanded(
            child: ListView.builder(
              controller: _scrollCtrl,
              padding: const EdgeInsetsDirectional.all(AppSpacing.md),
              itemCount: messages.length,
              itemBuilder: (_, i) {
                final m = messages[i];
                return Align(
                  alignment: m.isUser
                      ? AlignmentDirectional.centerStart
                      : AlignmentDirectional.centerEnd,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsetsDirectional.all(AppSpacing.md),
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.78,
                    ),
                    decoration: BoxDecoration(
                      color: m.isUser ? colors.pr : colors.bg,
                      borderRadius: AppRadius.rCard,
                      border: Border.all(
                        color: m.isUser ? colors.pr : colors.bd,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          strings.tr(m.text),
                          style: TextStyle(
                            fontFamily: AppTypography.fontFamily,
                            fontSize: 12,
                            color: m.isUser ? colors.prt : colors.tx,
                            height: 1.45,
                          ),
                        ),
                        if (m.outfitAttachment != null) ...[
                          const SizedBox(height: AppSpacing.sm),
                          AppCard(
                            padding: const EdgeInsetsDirectional.all(
                              AppSpacing.sm,
                            ),
                            borderRadius: AppRadius.rLg,
                            child: Row(
                              children: [
                                Icon(Icons.checkroom_rounded,
                                    size: 16, color: colors.pr),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    strings.tr(m.outfitAttachment!.title),
                                    style: AppTypography.caption(
                                      color: colors.tx,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Input Bar
          Container(
            padding: const EdgeInsetsDirectional.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: colors.sf,
              border: Border(top: BorderSide(color: colors.bd)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 40,
                    child: TextField(
                      controller: _inputCtrl,
                      onSubmitted: (_) => _send(),
                      style: TextStyle(
                        fontFamily: AppTypography.fontFamily,
                        fontSize: 12,
                        color: colors.tx,
                      ),
                      decoration: InputDecoration(
                        isDense: true,
                        hintText: strings.styAskHint,
                        hintStyle: TextStyle(
                          fontFamily: AppTypography.fontFamily,
                          fontSize: 12,
                          color: colors.mu,
                        ),
                        filled: true,
                        fillColor: colors.bg,
                        contentPadding: const EdgeInsetsDirectional.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: 10,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: AppRadius.rLg,
                          borderSide: BorderSide(color: colors.bd),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: AppRadius.rLg,
                          borderSide: BorderSide(color: colors.bd),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: AppRadius.rLg,
                          borderSide: BorderSide(color: colors.pr, width: 1.5),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                InkWell(
                  onTap: _send,
                  borderRadius: AppRadius.rLg,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: colors.pr,
                      borderRadius: AppRadius.rLg,
                    ),
                    child: Icon(
                      Icons.send_rounded,
                      size: 16,
                      color: colors.prt,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
