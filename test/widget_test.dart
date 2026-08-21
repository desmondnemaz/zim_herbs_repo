import 'package:flutter_test/flutter_test.dart';
import 'package:zim_herbs_repo/core/utils/enums.dart';
import 'package:zim_herbs_repo/features/repository/herbs/domain/entities/herb.dart';
import 'package:zim_herbs_repo/features/repository/conditions/domain/entities/condition.dart';

void main() {
  test('Herb entity creation test', () {
    const herb = Herb(
      id: '1',
      nameEn: 'Moringa',
      nameSn: 'Mupfumoti',
      description: 'Medicinal herb',
    );

    expect(herb.nameEn, 'Moringa');
    expect(herb.displayName, 'Moringa');
    expect(herb.primaryImageUrl, isNull);
  });

  test('Condition entity creation test', () {
    const condition = Condition(
      id: '1',
      name: 'Hypertension',
      bodySystem: BodySystem.circulatory,
      description: 'High blood pressure',
    );

    expect(condition.name, 'Hypertension');
    expect(condition.displayName, 'Hypertension');
    expect(condition.bodySystem, BodySystem.circulatory);
  });
}
