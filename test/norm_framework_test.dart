import 'package:flutter_test/flutter_test.dart';
import 'package:hexaiq_app/features/norm/domain/ability_level.dart';
import 'package:hexaiq_app/features/norm/domain/iq_scale_converter.dart';
import 'package:hexaiq_app/features/norm/domain/norm_profile.dart';
import 'package:hexaiq_app/features/norm/domain/percentile_converter.dart';

void main() {
  test('NormProfile keeps default IQ scale and resolves AgeGroup', () {
    const profile = NormProfile.defaultProfile;
    final middle = NormProfile.forAgeGroup(AgeGroup.middle);

    expect(profile.meanIQ, 100);
    expect(profile.sdIQ, 15);
    expect(profile.meanTheta, 0);
    expect(profile.sdTheta, 1);
    expect(profile.resolvedAgeGroup, AgeGroup.elementary56);
    expect(middle.ageGroup, AgeGroup.middle.code);
    expect(AgeGroup.parse('초등 5-6'), AgeGroup.elementary56);
    expect(AgeGroup.parse('middle'), AgeGroup.middle);
    expect(AgeGroup.parse('고등'), AgeGroup.high);
    expect(AgeGroup.parse('adult'), AgeGroup.adult);
  });

  test('IQScaleConverter maps theta to clamped estimated IQ', () {
    const converter = IQScaleConverter();

    expect(converter.scaledScore(theta: 0), 0);
    expect(converter.estimatedIQ(theta: 0), 100);
    expect(converter.estimatedIQ(theta: 0.6), 109);
    expect(converter.estimatedIQ(theta: 1), 115);
    expect(converter.estimatedIQ(theta: -100), IQScaleConverter.minIQ);
    expect(converter.estimatedIQ(theta: 100), IQScaleConverter.maxIQ);
    expect(converter.estimatedIQ(theta: double.nan), 100);
  });

  test(
    'PercentileConverter approximates normal percentile and clamps range',
    () {
      const converter = PercentileConverter();

      expect(converter.percentile(theta: 0), 50);
      expect(converter.percentile(theta: 1), inInclusiveRange(83, 85));
      expect(converter.percentile(theta: -1), inInclusiveRange(15, 17));
      expect(converter.percentile(theta: -100), 1);
      expect(converter.percentile(theta: 100), 99);
      expect(converter.percentile(theta: double.infinity), 50);
    },
  );

  test('AbilityLevel resolves IQ bands', () {
    expect(AbilityLevel.fromIQ(65), AbilityLevel.veryLow);
    expect(AbilityLevel.fromIQ(75), AbilityLevel.low);
    expect(AbilityLevel.fromIQ(85), AbilityLevel.belowAverage);
    expect(AbilityLevel.fromIQ(100), AbilityLevel.average);
    expect(AbilityLevel.fromIQ(115), AbilityLevel.aboveAverage);
    expect(AbilityLevel.fromIQ(125), AbilityLevel.superior);
    expect(AbilityLevel.fromIQ(135), AbilityLevel.verySuperior);
  });
}
