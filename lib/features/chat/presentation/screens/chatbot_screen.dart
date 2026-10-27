import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/di/dependency_injection.dart';
import '../../../../core/theming/app_colors.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../cubit/chatbot_cubit.dart';
import '../cubit/chatbot_state.dart';
import '../widgets/chat_widgets.dart';

/// The patient's conversation with the assistant — same look as the pharmacy
/// inquiry chat, without pictures.
class ChatbotScreen extends StatelessWidget {
  const ChatbotScreen({super.key});

  static Route<void> route() => MaterialPageRoute<void>(builder: (_) => const ChatbotScreen());

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<ChatbotCubit>(),
      child: const _ChatbotView(),
    );
  }
}

class _ChatbotView extends StatefulWidget {
  const _ChatbotView();

  @override
  State<_ChatbotView> createState() => _ChatbotViewState();
}

class _ChatbotViewState extends State<_ChatbotView> {
  late final TextEditingController _controller;
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _scrollController = ScrollController();
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

  Future<void> _send(BuildContext context) async {
    final text = _controller.text;
    if (text.trim().isEmpty) return;
    _controller.clear();
    final error = await context.read<ChatbotCubit>().send(text);
    if (!context.mounted || error == null) return;
    AppSnackbar.show(context, error);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const ChatHeader(
              title: 'المساعد الذكي',
              subtitle: 'اسأل عن أي دواء وسأدلّك على الصيدليات المتوفر فيها',
            ),
            Divider(height: 1, color: AppColors.cardBorder),
            Expanded(
              child: BlocConsumer<ChatbotCubit, ChatbotState>(
                listenWhen: (previous, current) =>
                    previous.messages.length != current.messages.length,
                listener: (context, state) => _scrollToEnd(),
                builder: (context, state) => ChatMessagesList(
                  messages: state.messages,
                  controller: _scrollController,
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(24.w, 8.h, 24.w, 16.h),
              child: SizedBox(
                height: 56.h,
                child: BlocSelector<ChatbotCubit, ChatbotState, bool>(
                  selector: (state) => state.isSending,
                  builder: (context, isSending) => AppTextField(
                    controller: _controller,
                    hintText: 'اكتب رسالة',
                    maxLines: 1,
                    fillColor: Colors.white,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _send(context),
                    icon: ChatSendIcon(isLoading: isSending, onTap: () => _send(context)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
