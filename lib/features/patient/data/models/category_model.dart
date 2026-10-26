import '../../domain/entities/category.dart';
import '../../domain/entities/category_subcategory.dart';
import '../../../../core/helpers/json_reader.dart';

class SubcategoryModel {
  final int id;
  final String nameAr;
  final String slug;
  final String groupKey;

  const SubcategoryModel({
    required this.id,
    required this.nameAr,
    required this.slug,
    required this.groupKey,
  });

  factory SubcategoryModel.fromJson(Map<String, dynamic> json) {
    return SubcategoryModel(
      id: jsonInt(json['id']) ?? (throw const FormatException('Record has no id')),
      nameAr: jsonString(json['name_ar']) ?? '',
      slug: jsonString(json['slug']) ?? '',
      groupKey: jsonString(json['group_key']) ?? '',
    );
  }

  CategorySubcategory toEntity() =>
      CategorySubcategory(id: id, nameAr: nameAr, slug: slug, groupKey: groupKey);
}

class CategoryModel {
  final int id;
  final String nameAr;
  final String slug;
  final String? image;
  final List<SubcategoryModel> subcategories;

  const CategoryModel({
    required this.id,
    required this.nameAr,
    required this.slug,
    this.image,
    this.subcategories = const [],
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    final rawSubcategories = json['subcategories'];
    return CategoryModel(
      id: jsonInt(json['id']) ?? (throw const FormatException('Record has no id')),
      nameAr: jsonString(json['name_ar']) ?? '',
      slug: jsonString(json['slug']) ?? '',
      image: jsonString(json['image']),
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
        slug: slug,
        image: image,
        subcategories: subcategories.map((subcategory) => subcategory.toEntity()).toList(),
      );
}
