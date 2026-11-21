import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../core/localization/translations.dart';
import '../../../../../core/theming/app_colors.dart';
import '../../../../chat/domain/entities/chat_message.dart';
import '../../../../chat/presentation/widgets/chat_widgets.dart' show ChatBubble;
import '../../../../../core/widgets/header_icon_button.dart';
import 'onboarding_phone_frame.dart';

/// "تواصل مباشرة مع عملائك": a conversation drawn with the chat's own widgets,
/// whose messages come in one after the other — a message, the reply, another
/// message, another reply — each rising and fading in.
class PharmacyChatArtwork extends StatefulWidget {
  const PharmacyChatArtwork({super.key});

  @override
  State<PharmacyChatArtwork> createState() => _PharmacyChatArtworkState();
}

class _PharmacyChatArtworkState extends State<PharmacyChatArtwork>
    with SingleTickerProviderStateMixin {
  /// Who says what, in order: a customer asks about a medicine and the
  /// pharmacy (the blue bubbles, "mine" for the pharmacist using the app)
  /// answers.
  static const _lines = [
    (mine: false, text: 'هل بانادول متوفر عندكم؟'),
    (mine: true, text: 'أهلاً فيك، أكيد متوفر'),
    (mine: false, text: 'بكم الشريط؟'),
    (mine: true, text: 'الشريط بـ 12 شيكل'),
  ];

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 4800),
  );

  @override
  void initState() {
    super.initState();
    _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// How far message [index] has come in, 0 to 1: each enters in its own
  /// quarter of the animation. A page not on show draws them all in place.
  double _progress(int index) {
    final start = 0.04 + index * 0.24;
    final raw = ((_controller.value - start) / 0.16).clamp(0.0, 1.0);
    return Curves.easeOutCubic.transform(raw);
  }

  @override
  Widget build(BuildContext context) {
    final sentAt = DateTime(2026, 1, 1, 21, 41);
    return OnboardingPhoneFrame(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _HeaderMock(),
            Center(child: _DayChip()),
            SizedBox(height: 16.h),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var i = 0; i < _lines.length; i++)
                    Opacity(
                      opacity: _progress(i),
                      child: Transform.translate(
                        offset: Offset(0, 18.h * (1 - _progress(i))),
                        child: Transform.scale(
                          scale: 0.9 + 0.1 * _progress(i),
                          alignment: _lines[i].mine
                              ? AlignmentDirectional.centerStart
                              : AlignmentDirectional.centerEnd,
                          child: ChatBubble(
                            message: ChatMessage(
                              id: i,
                              senderUserId: _lines[i].mine ? 1 : 2,
                              text: _lines[i].text.tr,
                              isRead: true,
                              createdAt: sentAt,
                              isMine: _lines[i].mine,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The conversation's top bar as the design draws it for this picture: the
/// back chip at the start, and beside it who is talking and that they are on.
class _HeaderMock extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(24.w, 24.h, 24.w, 16.h),
      child: Row(
        children: [
          HeaderIconButton(assetName: 'assets/icons/back_icon.svg', iconSize: 18, onTap: () {}),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'صيدلية النور'.tr,
                  style: TextStyle(fontSize: 16.sp, color: AppColors.textDark),
                ),
                SizedBox(height: 2.h),
                Text('نشط الان'.tr, style: TextStyle(fontSize: 12.sp, color: AppColors.grey)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DayChip extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Text('اليوم'.tr, style: TextStyle(fontSize: 12.sp, color: AppColors.textDark)),
    );
  }
}
