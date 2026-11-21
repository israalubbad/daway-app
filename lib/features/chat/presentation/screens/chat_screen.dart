import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/di/dependency_injection.dart';
import '../../../../core/helpers/image_source_picker.dart';
import '../../../../core/theming/app_colors.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/profile_load_error.dart';
import '../cubit/chat_cubit.dart';
import '../cubit/chat_state.dart';
import '../widgets/chat_widgets.dart';

import '../../../../core/localization/translations.dart';
/// Arguments to open a chat: the [inquiryIds] of a conversation (newest

/// first), or — patient only — the [pharmacyId] (and [medicineId] to be able
/// to start one).
class ChatArgs {
  final List<int> inquiryIds;
  final int? pharmacyId;
  final int? medicineId;
  final String title;
  final String? subtitle;

  const ChatArgs({
    this.inquiryIds = const [],
    this.pharmacyId,
    this.medicineId,
    required this.title,
    this.subtitle,
  });

  factory ChatArgs.fromMap(Map<String, dynamic> map) => ChatArgs(
        inquiryIds: [for (final id in (map['inquiryIds'] as List?) ?? const []) id as int],
        pharmacyId: map['pharmacyId'] as int?,
        medicineId: map['medicineId'] as int?,
        title: map['title'] as String,
        subtitle: map['subtitle'] as String?,
      );
}

/// The inquiry thread between a patient and a pharmacy — the same screen for
/// both sides. Mine on the right in the main colour ("أنت: 9:41 م" under it),
/// the other side on the left in the light one.
class ChatScreen extends StatelessWidget {
  final ChatArgs args;

  const ChatScreen({super.key, required this.args});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<ChatCubit>(param1: args),
      child: _ChatView(args: args),
    );
  }
}

class _ChatView extends StatefulWidget {
  final ChatArgs args;

  const _ChatView({required this.args});

  @override
  State<_ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends State<_ChatView> {
  late final TextEditingController _controller;
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _scrollController = ScrollController();
    context.read<ChatCubit>().startPolling();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToEnd() {
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

  Future<void> _sendText(BuildContext context) async {
    final text = _controller.text;
    if (text.trim().isEmpty) return;
    final error = await context.read<ChatCubit>().send(text: text);
    if (!context.mounted) return;
    if (error != null) {
      AppSnackbar.show(context, error);
      return;
    }
    _controller.clear();
    _scrollToEnd();
  }

  Future<void> _sendImage(BuildContext context) async {
    final cubit = context.read<ChatCubit>();
    final file = await pickImageFromSourceSheet(context);
    if (file == null || !context.mounted) return;
    final error = await cubit.send(imagePath: file.path);
    if (!context.mounted) return;
    if (error != null) {
      AppSnackbar.show(context, error);
      return;
    }
    _scrollToEnd();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ChatHeader(title: widget.args.title, subtitle: widget.args.subtitle),
            Divider(height: 1, color: AppColors.cardBorder),
            Expanded(
              child: BlocConsumer<ChatCubit, ChatState>(
                listenWhen: (previous, current) =>
                    current is ChatLoaded &&
                    (previous is! ChatLoaded ||
                        previous.messages.length != current.messages.length),
                listener: (context, state) => _scrollToEnd(),
                builder: (context, state) {
                  return switch (state) {
                    ChatLoading() => const Center(child: CircularProgressIndicator()),
                    ChatLoadFailure(:final message) => ProfileLoadError(
                        message: message,
                        onRetry: () => context.read<ChatCubit>().load(),
                      ),
                    ChatLoaded(:final messages, :final canSend) when messages.isEmpty =>
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 24.w),
                        child: Center(
                          child: Text(
                            canSend
                                ? 'اكتب رسالتك للبدء بالمحادثة.'.tr
                                : 'لا توجد رسائل مع {0} بعد.\nافتح صفحة دواء واضغط «اسأل الصيدلية» لبدء المراسلة.'.trArgs([widget.args.title]),
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 14.sp, color: AppColors.grey, height: 1.6),
                          ),
                        ),
                      ),
                    ChatLoaded(:final messages) => ChatMessagesList(
                        messages: messages,
                        controller: _scrollController,
                      ),
                  };
                },
              ),
            ),
            BlocBuilder<ChatCubit, ChatState>(
              builder: (context, state) {
                if (state is! ChatLoaded || !state.canSend) return const SizedBox.shrink();
                return Padding(
                  padding: EdgeInsets.fromLTRB(24.w, 8.h, 24.w, 16.h),
                  child: Row(
                    children: [
                      // First = right edge: the 336x56 message box with the
                      // send arrow inside it, then the "+" (image) button.
                      SizedBox(
                        width: 336.w,
                        height: 56.h,
                        child: AppTextField(
                          controller: _controller,
                          hintText: 'اكتب رسالة'.tr,
                          maxLines: 1,
                          fillColor: Colors.white,
                          textInputAction: TextInputAction.send,
                          onSubmitted: (_) => _sendText(context),
                          icon: ChatSendIcon(
                            isLoading: state.isSending,
                            onTap: () => _sendText(context),
                          ),
                        ),
                      ),
                      SizedBox(width: 8.w),
                      _AttachButton(onTap: state.isSending ? null : () => _sendImage(context)),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}


class _AttachButton extends StatelessWidget {
  final VoidCallback? onTap;

  const _AttachButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48.w,
        height: 48.w,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.permissionIconBg,
          border: Border.all(color: AppColors.iconBlueBorder),
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: Icon(Icons.add, color: AppColors.mainTeal, size: 24.sp),
      ),
    );
  }
}
