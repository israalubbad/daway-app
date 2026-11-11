import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theming/app_text_styles.dart';
import '../../../../core/widgets/profile_load_error.dart';
import '../../../patient/presentation/widgets/patient_sub_screen_header.dart';
import '../cubit/pharmacy_ratings_cubit.dart';
import '../cubit/pharmacy_ratings_state.dart';
import '../widgets/rating_card.dart';

import '../../../../core/localization/translations.dart';

/// "التقييمات": what patients wrote about the pharmacy, newest first, straight
/// under the title.
class PharmacyRatingsScreen extends StatelessWidget {
  const PharmacyRatingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: BlocBuilder<PharmacyRatingsCubit, PharmacyRatingsState>(
          builder: (context, state) {
            return switch (state) {
              PharmacyRatingsLoading() => const Center(
                child: CircularProgressIndicator(),
              ),
              PharmacyRatingsLoadFailure(:final message) => ProfileLoadError(
                message: message,
                onRetry: () => context.read<PharmacyRatingsCubit>().load(),
              ),
              PharmacyRatingsLoaded() => _buildLoaded(state),
            };
          },
        ),
      ),
    );
  }

  Widget _buildLoaded(PharmacyRatingsLoaded state) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PatientSubScreenHeader(
            title: 'التقييمات'.tr,
            description: 'آراء عملائك في صيدليتك'.tr,
          ),
          SizedBox(height: 24.h),
          Expanded(
            child: state.ratings.isEmpty
                ? Center(
                    child: Text(
                      'لا توجد مراجعات بعد'.tr,
                      style: AppTextStyles.cardDescription,
                    ),
                  )
                : ListView.separated(
                    padding: EdgeInsets.only(bottom: 24.h),
                    itemCount: state.ratings.length,
                    separatorBuilder: (context, index) => SizedBox(height: 16.h),
                    itemBuilder: (context, index) =>
                        RatingCard(rating: state.ratings[index]),
                  ),
          ),
        ],
      ),
    );
  }
}
