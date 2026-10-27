import 'package:daway_app/features/pharmacy/data/models/rating_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('reads the star count from stars_rating, the name the patient side sends', () {
    final rating = RatingModel.fromJson({
      'id': 1,
      'stars_rating': 5,
      'comment': 'ممتازة',
      'created_at': '2026-10-28T10:00:00Z',
      'patient': {'name': 'إسراء'},
    });

    expect(rating.stars, 5);
    expect(rating.patientName, 'إسراء');
  });

  test('still reads stars', () {
    final rating = RatingModel.fromJson({'stars': 4, 'created_at': '2026-10-28T10:00:00Z'});

    expect(rating.stars, 4);
  });

  test('a record with no star count is refused', () {
    expect(
      () => RatingModel.fromJson({'created_at': '2026-10-28T10:00:00Z'}),
      throwsA(anything),
    );
  });
}
