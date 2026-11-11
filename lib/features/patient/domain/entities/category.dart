import '../../../../core/localization/translations.dart';
import 'category_subcategory.dart';

class Category {
  final int id;
  final String nameAr;

  /// The English name the backend also sends (null when it does not).
  final String? nameEn;
  final String slug;
  final String? image;
  final List<CategorySubcategory> subcategories;

  /// The name in the language the app is showing.
  String get name => localizedName(nameAr, nameEn);

  const Category({
    required this.id,
    required this.nameAr,
    this.nameEn,
    required this.slug,
    this.image,
    this.subcategories = const [],
  });
}
