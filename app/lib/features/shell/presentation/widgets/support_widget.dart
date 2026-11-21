import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/state/app_state.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';

class SupportWidget extends ConsumerStatefulWidget {
  final Size? bodySize;

  const SupportWidget({super.key, this.bodySize});

  @override
  ConsumerState<SupportWidget> createState() => _SupportWidgetState();
}

class _SupportWidgetState extends ConsumerState<SupportWidget> {
  static const double _buttonSize = 48.0;
  static const double _edgeMargin = 12.0;
  static const double _verticalPadding = 8.0;

  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  double? _left;
  double? _top;
  bool _isDragging = false;

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    ref.read(appStateProvider.notifier).sendSupportMessage(text);
    _textController.clear();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final strings = context.strings;
    final appState = ref.watch(appStateProvider);

    if (!appState.showFloatingSupport && !appState.isSupportOpen) {
      return const SizedBox.shrink();
    }

    final size = widget.bodySize ?? MediaQuery.sizeOf(context);
    final bodyWidth = size.width;
    final bodyHeight = size.height;
    final isRtl = Directionality.of(context) == TextDirection.rtl;

    final maxLeft = math.max(
      _edgeMargin,
      bodyWidth - _buttonSize - _edgeMargin,
    );
    final maxTop = math.max(
      _verticalPadding,
      bodyHeight - _buttonSize - _verticalPadding,
    );

    // Initialize default bottom-end position once layout bounds are known.
    final currentLeft = (_left ?? (isRtl ? _edgeMargin : maxLeft)).clamp(
      _edgeMargin,
      maxLeft,
    );
    final currentTop = (_top ?? (bodyHeight - _buttonSize - 16.0)).clamp(
      _verticalPadding,
      maxTop,
    );

    // Smart popup dimensions & coordinates clamped 100% inside the internal app area.
    final popupWidth = math.min(288.0, math.max(220.0, bodyWidth - 24.0));
    final popupHeight = math.min(320.0, math.max(180.0, bodyHeight - 24.0));
    final maxPopupLeft = math.max(
      _edgeMargin,
      bodyWidth - popupWidth - _edgeMargin,
    );
    final maxPopupTop = math.max(
      _verticalPadding,
      bodyHeight - popupHeight - _verticalPadding,
    );

    final bool buttonInLeftHalf =
        (currentLeft + _buttonSize / 2) < (bodyWidth / 2);
    final double popupLeft =
        (buttonInLeftHalf
                ? currentLeft
                : (currentLeft + _buttonSize - popupWidth))
            .clamp(_edgeMargin, maxPopupLeft);

    final double spaceAbove = currentTop - _verticalPadding;
    final double spaceBelow =
        bodyHeight - (currentTop + _buttonSize) - _verticalPadding;
    final bool openUpward =
        (currentTop + _buttonSize / 2) > (bodyHeight / 2) ||
        (spaceAbove >= popupHeight + _verticalPadding &&
            spaceAbove >= spaceBelow);

    final double rawPopupTop = openUpward
        ? (currentTop - _verticalPadding - popupHeight)
        : (currentTop + _buttonSize + _verticalPadding);
    final double popupTop = rawPopupTop.clamp(_verticalPadding, maxPopupTop);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // ── Smart Bounded Support Chat Popup Window ────────────────────────
        if (appState.isSupportOpen)
          Positioned(
            left: popupLeft,
            top: popupTop,
            width: popupWidth,
            height: popupHeight,
            child: _buildChatPopup(colors, strings, appState),
          ),

        // ── Draggable & Magnetic Edge-Snapping Floating Button ─────────────
        if (appState.showFloatingSupport)
          AnimatedPositioned(
            duration: _isDragging
                ? Duration.zero
                : const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            left: currentLeft,
            top: currentTop,
            child: GestureDetector(
              onPanStart: (_) {
                setState(() {
                  _left ??= currentLeft;
                  _top ??= currentTop;
                  _isDragging = true;
                });
              },
              onPanUpdate: (details) {
                setState(() {
                  _left = ((_left ?? currentLeft) + details.delta.dx).clamp(
                    _edgeMargin,
                    maxLeft,
                  );
                  _top = ((_top ?? currentTop) + details.delta.dy).clamp(
                    _verticalPadding,
                    maxTop,
                  );
                });
              },
              onPanEnd: (_) {
                setState(() {
                  _isDragging = false;
                  final centerX = (_left ?? currentLeft) + (_buttonSize / 2);
                  _left = centerX < (bodyWidth / 2) ? _edgeMargin : maxLeft;
                });
              },
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Material(
                    color: colors.pr,
                    shape: const CircleBorder(),
                    elevation: 6,
                    shadowColor: Colors.black38,
                    child: InkWell(
                      onTap: () {
                        if (!_isDragging) {
                          ref.read(appStateProvider.notifier).toggleSupport();
                        }
                      },
                      customBorder: const CircleBorder(),
                      child: SizedBox(
                        width: _buttonSize,
                        height: _buttonSize,
                        child: Center(
                          child: FaIcon(
                            FontAwesomeIcons.headset,
                            size: 20,
                            color: colors.prt,
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Online green dot
                  PositionedDirectional(
                    top: 0,
                    end: 0,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: colors.ok,
                        shape: BoxShape.circle,
                        border: Border.all(color: colors.sf, width: 2),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildChatPopup(
    AppColors colors,
    AppStrings strings,
    AppState appState,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: colors.sf,
        borderRadius: AppRadius.rCard,
        border: Border.all(color: colors.bd),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.14),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          // Chat Header
          Container(
            padding: const EdgeInsetsDirectional.symmetric(
              horizontal: AppSpacing.md,
              vertical: 10,
            ),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: colors.bd)),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppRadius.card),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: colors.ok,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      strings.supT,
                      style: TextStyle(
                        fontFamily: 'Vazirmatn',
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: colors.tx,
                      ),
                    ),
                  ],
                ),
                InkWell(
                  onTap: () =>
                      ref.read(appStateProvider.notifier).toggleSupport(false),
                  borderRadius: AppRadius.rFull,
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      Icons.close_rounded,
                      size: 16,
                      color: colors.mu,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Chat Messages
          Expanded(
            child: appState.supportMessages.isEmpty
                ? Center(
                    child: Text(
                      strings.supT,
                      style: TextStyle(
                        fontFamily: 'Vazirmatn',
                        fontSize: 12,
                        color: colors.mu,
                      ),
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(AppSpacing.md),
                    itemCount: appState.supportMessages.length,
                    itemBuilder: (ctx, index) {
                      final msg = appState.supportMessages[index];
                      return Align(
                        alignment: msg.isUser
                            ? AlignmentDirectional.centerEnd
                            : AlignmentDirectional.centerStart,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                            vertical: AppSpacing.sm,
                          ),
                          constraints: const BoxConstraints(maxWidth: 220),
                          decoration: BoxDecoration(
                            color: msg.isUser ? colors.pr : colors.bg,
                            borderRadius: AppRadius.rMd,
                            border: msg.isUser
                                ? null
                                : Border.all(color: colors.bd),
                          ),
                          child: Text(
                            strings.tr(msg.text),
                            style: TextStyle(
                              fontFamily: 'Vazirmatn',
                              fontSize: 12,
                              height: 1.5,
                              color: msg.isUser ? colors.prt : colors.tx,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),

          // Input Row
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: colors.bd)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textController,
                    onSubmitted: (_) => _sendMessage(),
                    style: TextStyle(
                      fontFamily: 'Vazirmatn',
                      fontSize: 12,
                      color: colors.tx,
                    ),
                    decoration: InputDecoration(
                      isDense: true,
                      hintText: strings.supPh,
                      hintStyle: TextStyle(
                        fontFamily: 'Vazirmatn',
                        fontSize: 12,
                        color: colors.mu,
                      ),
                      filled: true,
                      fillColor: colors.bg,
                      contentPadding: const EdgeInsetsDirectional.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.sm,
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
                const SizedBox(width: AppSpacing.xs),
                InkWell(
                  onTap: _sendMessage,
                  borderRadius: AppRadius.rLg,
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: colors.pr,
                      borderRadius: AppRadius.rLg,
                    ),
                    child: Center(
                      child: FaIcon(
                        FontAwesomeIcons.paperPlane,
                        size: 14,
                        color: colors.prt,
                      ),
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
