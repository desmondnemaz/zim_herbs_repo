// ignore_for_file: avoid_print

import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zim_herbs_repo/core/config/supabase_config.dart';
import 'package:zim_herbs_repo/features/repository/herbs/data/datasources/herb_remote_datasource.dart';
import 'package:zim_herbs_repo/features/repository/remedies/data/datasources/remedy_remote_datasource.dart';
import 'package:zim_herbs_repo/features/repository/conditions/data/datasources/condition_remote_datasource.dart';

void main() {
  test('Live fetch herbs test from Supabase', () async {
    final client = SupabaseClient(
      SupabaseConfig.supabaseUrl,
      SupabaseConfig.supabaseAnonKey,
    );

    final dataSource = HerbRemoteDataSource(client);

    try {
      final count = await dataSource.getHerbsCount();
      print('>>> Total herbs in database: $count');

      final herbs = await dataSource.getAllHerbs();
      print('>>> Successfully fetched ${herbs.length} herbs!');
      for (final herb in herbs.take(5)) {
        print(' - Herb: ${herb.nameEn} (remedies count: ${herb.remedies.length})');
        for (final remedy in herb.remedies) {
          print('    * Remedy: ${remedy.name} (isApproved: ${remedy.isApproved})');
        }
      }
      expect(count, greaterThanOrEqualTo(0));
    } catch (e, stack) {
      print('>>> Fetch failed with error: $e\n$stack');
      rethrow;
    }
  });

  test('Live fetch remedies test from Supabase', () async {
    final client = SupabaseClient(
      SupabaseConfig.supabaseUrl,
      SupabaseConfig.supabaseAnonKey,
    );

    final remedyDataSource = RemedyRemoteDataSource(client);

    try {
      final remedyCount = await remedyDataSource.getRemediesCount();
      print('>>> Total remedies in database: $remedyCount');

      final remedies = await remedyDataSource.getAllRemedies();
      print('>>> Successfully fetched ${remedies.length} remedies!');
      for (final remedy in remedies.take(5)) {
        print(' - Remedy: ${remedy.name} (Herbs: ${remedy.remedyHerbs.length}, Condition: ${remedy.condition?.name})');
      }
      expect(remedyCount, greaterThanOrEqualTo(0));
    } catch (e, stack) {
      print('>>> Fetch remedies failed with error: $e\n$stack');
      rethrow;
    }
  });

  test('Live fetch conditions and body parts test from Supabase', () async {
    final client = SupabaseClient(
      SupabaseConfig.supabaseUrl,
      SupabaseConfig.supabaseAnonKey,
    );

    final conditionDataSource = ConditionRemoteDataSource(client);

    try {
      final conditionCount = await conditionDataSource.getConditionsCount();
      print('>>> Total conditions in database: $conditionCount');

      final conditions = await conditionDataSource.getAllConditions();
      print('>>> Successfully fetched ${conditions.length} conditions!');
      for (final condition in conditions.take(5)) {
        print(
          ' - Condition: ${condition.name} (Body parts: ${condition.bodyParts.map((b) => b.nameEn).join(', ')})',
        );
      }

      final bodyParts = await conditionDataSource.getAllBodyParts();
      print('>>> Successfully fetched ${bodyParts.length} body parts!');
      for (final bp in bodyParts.take(5)) {
        print(' - Body Part: ${bp.nameEn} (Code: ${bp.code})');
      }

      expect(conditionCount, greaterThanOrEqualTo(0));
      expect(bodyParts.length, greaterThanOrEqualTo(0));
    } catch (e, stack) {
      print('>>> Fetch conditions/body parts failed with error: $e\n$stack');
      rethrow;
    }
  });
}
