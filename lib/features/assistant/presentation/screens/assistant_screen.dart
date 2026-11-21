import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/di/dependency_injection.dart';
import '../../../../core/helpers/price_formatter.dart';
import '../../../../core/routing/routes.dart';
import '../../../../core/theming/app_colors.dart';
import '../../../../core/widgets/app_back_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../domain/entities/assistant_reply.dart';
import '../cubit/assistant_cubit.dart';
import '../cubit/assistant_state.dart';

/// "المساعد الذكي": describe a medicine or a symptom, get back the medicine and
/// the pharmacies that stock it. Same look as the pharmacy chats: the patient's
/// messages on the right in the main colour, the assistant's on the left.
class AssistantScreen extends StatelessWidget {
  const AssistantScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<AssistantCubit>(),
      child: const _AssistantView(),
    );
  }
}

class _AssistantView extends StatefulWidget {
  const _AssistantView();

  @override
  State<_AssistantView> createState() => _AssistantViewState();
}

class _AssistantViewState extends State<_AssistantView> {
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

  void _send(BuildContext context) {
    final text = _controller.text;
    if (text.trim().isEmpty) return;
    context.read<AssistantCubit>().send(text);
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(24.w, 16.h, 24.w, 16.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppBackButton(onTap: () => Navigator.of(context).maybePop()),
                  SizedBox(height: 12.h),
                  Text(
                    'المساعد الذكي',
                    textAlign: TextAlign.right,
                    style: TextStyle(fontSize: 16.sp, color: AppColors.textDark),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    'اسأل عن دواء وأدلّك على أقرب صيدلية',
                    textAlign: TextAlign.right,
                    style: TextStyle(fontSize: 12.sp, color: AppColors.grey),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: AppColors.cardBorder),
            Expanded(
              child: BlocConsumer<AssistantCubit, AssistantState>(
                listenWhen: (previous, current) =>
                    previous.messages.length != current.messages.length ||
                    previous.isSending != current.isSending,
                listener: (context, state) => _scrollToEnd(),
                builder: (context, state) {
                  return ListView.builder(
                    controller: _scrollController,
                    padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
                    itemCount: state.messages.length + (state.isSending ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == state.messages.length) return const _TypingBubble();
                      return _MessageBubble(message: state.messages[index]);
                    },
                  );
                },
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(24.w, 8.h, 24.w, 16.h),
              child: BlocBuilder<AssistantCubit, AssistantState>(
                buildWhen: (previous, current) => previous.isSending != current.isSending,
                builder: (context, state) {
                  return SizedBox(
                    height: 56.h,
                    child: AppTextField(
                      controller: _controller,
                      hintText: 'اكتب اسم الدواء أو ما تشعر به',
                      maxLines: 1,
                      fillColor: Colors.white,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(context),
                      icon: IconButton(
                        onPressed: state.isSending ? null : () => _send(context),
                        // Icons.send mirrors itself under RTL, so it points left.
                        icon: Icon(Icons.send, color: AppColors.mainTeal, size: 22.sp),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final AssistantMessage message;

  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final mine = message.isUser;
    final textColor = mine
        ? Colors.white
        : (message.isError ? AppColors.logoutRed : AppColors.textDark);

    return Padding(
      padding: EdgeInsets.only(bottom: 16.h),
      child: Column(
        // Start = right edge under RTL: the patient on the right, the assistant on the left.
        crossAxisAlignment: mine ? CrossAxisAlignment.start : CrossAxisAlignment.end,
        children: [
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 300.w),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
              decoration: BoxDecoration(
                color: mine ? AppColors.mainTeal : AppColors.permissionIconBg,
                border: mine ? null : Border.all(color: AppColors.iconBlueBorder),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Text(
                message.text,
                textAlign: TextAlign.right,
                style: TextStyle(fontSize: 14.sp, color: textColor, height: 1.4),
              ),
            ),
          ),
          for (final medicine in message.medicines) ...[
            SizedBox(height: 8.h),
            _MedicineCard(medicine: medicine),
          ],
          for (final pharmacy in message.pharmacies) ...[
            SizedBox(height: 8.h),
            _PharmacyCard(pharmacy: pharmacy),
          ],
        ],
      ),
    );
  }
}

class _MedicineCard extends StatelessWidget {
  final AssistantMedicine medicine;

  const _MedicineCard({required this.medicine});

  @override
  Widget build(BuildContext context) {
    final id = medicine.id;
    final imageUrl = medicine.imageUrl;

    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: 300.w),
      child: Container(
        padding: EdgeInsets.all(8.w),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AppColors.cardBorder),
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: Row(
          children: [
            Container(
              width: 48.w,
              height: 48.w,
              decoration: BoxDecoration(
                color: AppColors.permissionIconBg,
                borderRadius: BorderRadius.circular(8.r),
              ),
              clipBehavior: Clip.antiAlias,
              child: (imageUrl != null)
                  ? Image.network(
                      imageUrl,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) =>
                          Icon(Icons.medication_outlined, color: AppColors.mainTeal, size: 22.sp),
                    )
                  : Icon(Icons.medication_outlined, color: AppColors.mainTeal, size: 22.sp),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Text(
                medicine.name,
                textAlign: TextAlign.right,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 14.sp, color: AppColors.textDark),
              ),
            ),
            if (id != null) ...[
              SizedBox(width: 8.w),
              TextButton(
                onPressed: () =>
                    Navigator.of(context).pushNamed(Routes.medicineDetailScreen, arguments: id),
                child: Text('عرض', style: TextStyle(color: AppColors.mainTeal)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PharmacyCard extends StatelessWidget {
  final AssistantPharmacy pharmacy;

  const _PharmacyCard({required this.pharmacy});

  @override
  Widget build(BuildContext context) {
    final details = [
      if (pharmacy.distanceKm != null) 'يبعد عنك ${pharmacy.distanceKm!.toStringAsFixed(1)} كيلو',
      if (pharmacy.price != null) '${formatPrice(pharmacy.price!)} \$',
    ].join('  •  ');

    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: 300.w),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AppColors.cardBorder),
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: Row(
          children: [
            Icon(Icons.local_pharmacy_outlined, color: AppColors.mainTeal, size: 22.sp),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    pharmacy.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 14.sp, color: AppColors.textDark),
                  ),
                  if (details.isNotEmpty) ...[
                    SizedBox(height: 2.h),
                    Text(
                      details,
                      style: TextStyle(fontSize: 12.sp, color: AppColors.grey),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TypingBubble extends StatelessWidget {
  const _TypingBubble();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: AlignmentDirectional.centerEnd,
      child: Container(
        margin: EdgeInsets.only(bottom: 16.h),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: AppColors.permissionIconBg,
          border: Border.all(color: AppColors.iconBlueBorder),
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: SizedBox(
          width: 18.w,
          height: 18.w,
          child: const CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }
}
