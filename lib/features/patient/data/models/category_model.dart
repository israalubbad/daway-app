import '../../domain/entities/category.dart';
import '../../domain/entities/category_subcategory.dart';

class SubcategoryModel {
  final int id;
  final String nameAr;

  /// The English name the backend may send as `name_en`.
  final String? nameEn;
  final String slug;
  final String groupKey;

  const SubcategoryModel({
    required this.id,
    required this.nameAr,
    this.nameEn,
    required this.slug,
    required this.groupKey,
  });

  factory SubcategoryModel.fromJson(Map<String, dynamic> json) {
    return SubcategoryModel(
      id: json['id'] as int,
      nameAr: json['name_ar'] as String? ?? '',
      nameEn: json['name_en'] as String?,
      slug: json['slug'] as String? ?? '',
      groupKey: json['group_key'] as String? ?? '',
    );
  }

  CategorySubcategory toEntity() => CategorySubcategory(
        id: id,
        nameAr: nameAr,
        nameEn: nameEn,
        slug: slug,
        groupKey: groupKey,
      );
}

class CategoryModel {
  final int id;
  final String nameAr;

  /// The English name the backend sends as `name_en`.
  final String? nameEn;
  final String slug;
  final String? image;
  final List<SubcategoryModel> subcategories;

  const CategoryModel({
    required this.id,
    required this.nameAr,
    this.nameEn,
    required this.slug,
    this.image,
    this.subcategories = const [],
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    final rawSubcategories = json['subcategories'];
    return CategoryModel(
      id: json['id'] as int,
      nameAr: json['name_ar'] as String? ?? '',
      nameEn: json['name_en'] as String?,
      slug: json['slug'] as String? ?? '',
      image: json['image'] as String?,
      subcategories: rawSubcategories is List
          ? rawSubcategories
              .map((json) => SubcategoryModel.fromJson(json as Map<String, dynamic>))
              .toList()
          : const [],
    );
  }

  Category toEntity() => Category(
        id: id,
        nameAr: nameAr,
        nameEn: nameEn,
        slug: slug,
        image: image,
        subcategories: subcategories.map((subcategory) => subcategory.toEntity()).toList(),
      );
}
