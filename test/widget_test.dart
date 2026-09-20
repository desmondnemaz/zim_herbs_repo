import 'package:flutter_test/flutter_test.dart';
import 'package:zim_herbs_repo/core/utils/enums.dart';
import 'package:zim_herbs_repo/features/repository/herbs/domain/entities/herb.dart';
import 'package:zim_herbs_repo/features/repository/conditions/domain/entities/condition.dart';
import 'package:zim_herbs_repo/features/repository/remedies/domain/entities/remedy.dart';

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

  test('Remedy entity creation test', () {
    const remedy = Remedy(
      id: '1',
      conditionId: 'cond-1',
      name: 'Moringa Remedy',
      methodOfUse: 'Boil leaves and drink as tea',
      preparation: 'Steep for 10 minutes',
      remedyHerbs: [
        RemedyHerb(
          id: 'rh-1',
          remedyId: '1',
          herbId: 'h-1',
          herbName: 'Moringa',
        ),
        RemedyHerb(
          id: 'rh-2',
          remedyId: '1',
          herbId: 'h-2',
          herbName: 'Aloe vera',
        ),
      ],
    );

    expect(remedy.id, '1');
    expect(remedy.conditionId, 'cond-1');
    expect(remedy.displayName, 'Moringa + Aloe vera');
    expect(remedy.remedyHerbs.length, 2);
    expect(remedy.remedyHerbs.first.remedyId, '1');
  });
}
