import '../../../../core/widgets/network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/helpers/smart_date_formatter.dart';
import '../../../../core/theming/app_colors.dart';
import '../../../../core/widgets/app_back_button.dart';
import '../../domain/entities/chat_message.dart';

// Pieces of the conversation UI shared by the pharmacy inquiry chat and the
// assistant (chatbot) chat, so both look the same.

class ChatHeader extends StatelessWidget {
  final String title;
  final String? subtitle;

  const ChatHeader({super.key, required this.title, this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(24.w, 16.h, 24.w, 16.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppBackButton(onTap: () => Navigator.of(context).maybePop()),
          SizedBox(height: 12.h),
          Text(
            title,
            textAlign: TextAlign.right,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 16.sp, color: AppColors.textDark),
          ),
          if (subtitle != null && subtitle!.isNotEmpty) ...[
            SizedBox(height: 2.h),
            Text(
              subtitle!,
              textAlign: TextAlign.right,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12.sp, color: AppColors.grey),
            ),
          ],
        ],
      ),
    );
  }
}

class ChatMessagesList extends StatelessWidget {
  final List<ChatMessage> messages;
  final ScrollController controller;

  /// Something to show under a message's bubble (the assistant's results). A
  /// message with no text and extras shows the extras alone.
  final Widget? Function(ChatMessage message)? extrasFor;

  const ChatMessagesList({
    super.key,
    required this.messages,
    required this.controller,
    this.extrasFor,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: controller,
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[index];
        final previous = index == 0 ? null : messages[index - 1];
        final newDay = previous == null || !_sameDay(previous.createdAt, message.createdAt);
        final extras = extrasFor?.call(message);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (newDay) _DayChip(date: message.createdAt),
            if (message.text.isNotEmpty || extras == null) ChatBubble(message: message),
            if (extras != null) ...[extras, SizedBox(height: 16.h)],
          ],
        );
      },
    );
  }

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

class _DayChip extends StatelessWidget {
  final DateTime date;

  const _DayChip({required this.date});

  String get _label {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(date.year, date.month, date.day);
    final diff = today.difference(day).inDays;
    if (diff == 0) return 'اليوم';
    if (diff == 1) return 'أمس';
    return '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: EdgeInsets.only(bottom: 16.h),
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AppColors.cardBorder),
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: Text(_label, style: TextStyle(fontSize: 12.sp, color: AppColors.textDark)),
      ),
    );
  }
}

class ChatBubble extends StatelessWidget {
  final ChatMessage message;

  const ChatBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final mine = message.isMine;
    final textColor = mine ? Colors.white : AppColors.textDark;
    final time = formatClockTime(message.createdAt);
    final imageOnly = message.imageUrl != null &&
        (message.text.isEmpty || message.text.trim() == message.imageUrl);

    return Padding(
      padding: EdgeInsets.only(bottom: 16.h),
      child: Column(
        // Start = right edge under RTL: mine on the right, theirs on the left.
        crossAxisAlignment: mine ? CrossAxisAlignment.start : CrossAxisAlignment.end,
        children: [
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 280.w),
            child: Container(
              // A picture on its own has no bubble: just the image.
              padding: imageOnly
                  ? EdgeInsets.zero
                  : EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
              decoration: imageOnly
                  ? null
                  : BoxDecoration(
                      color: mine ? AppColors.mainTeal : AppColors.permissionIconBg,
                      border: mine ? null : Border.all(color: AppColors.iconBlueBorder),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (message.imageUrl != null)
                    Padding(
                      padding: EdgeInsets.only(
                        bottom: (message.text.isEmpty || message.imageUrl == message.text.trim())
                            ? 0
                            : 8.h,
                      ),
                      child: GestureDetector(
                        onTap: () => _openImage(context, message.imageUrl!),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(6.r),
                          child: networkImage(
                            message.imageUrl!,
                            fit: BoxFit.cover,
                            width: imageOnly ? 240.w : null,
                            loadingBuilder: (context, child, progress) => progress == null
                                ? child
                                : SizedBox(
                                    height: 160.h,
                                    child: const Center(child: CircularProgressIndicator()),
                                  ),
                            errorBuilder: (context, error, stackTrace) => Padding(
                              padding: EdgeInsets.all(12.w),
                              child: Icon(
                                Icons.broken_image_outlined,
                                color: textColor,
                                size: 32.sp,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  if (message.text.isNotEmpty && message.imageUrl != message.text.trim())
                    Text(
                      message.text,
                      textAlign: TextAlign.right,
                      style: TextStyle(fontSize: 14.sp, color: textColor, height: 1.4),
                    ),
                ],
              ),
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            mine ? 'أنت: $time' : time,
            style: TextStyle(fontSize: 11.sp, color: AppColors.grey),
          ),
        ],
      ),
    );
  }
}

/// Full-screen, pinch-to-zoom view of a picture from the chat.
void _openImage(BuildContext context, String url) {
  Navigator.of(context).push(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        body: Center(
          child: InteractiveViewer(
            minScale: 1,
            maxScale: 5,
            child: networkImage(
              url,
              fit: BoxFit.contain,
              loadingBuilder: (context, child, progress) => progress == null
                  ? child
                  : const Center(child: CircularProgressIndicator(color: Colors.white)),
              errorBuilder: (context, error, stackTrace) =>
                  const Icon(Icons.broken_image_outlined, color: Colors.white, size: 48),
            ),
          ),
        ),
      ),
    ),
  );
}

class ChatSendIcon extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onTap;

  const ChatSendIcon({super.key, required this.isLoading, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: isLoading ? null : onTap,
      icon: isLoading
          ? SizedBox(
              width: 18.w,
              height: 18.w,
              child: const CircularProgressIndicator(strokeWidth: 2),
            )
          // Icons.send mirrors itself under RTL, so the arrow points left.
          : Icon(Icons.send, color: AppColors.mainTeal, size: 22.sp),
    );
  }
}
