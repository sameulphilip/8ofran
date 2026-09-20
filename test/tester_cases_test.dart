import 'package:a3traf/core/constants/app_constants.dart';
import 'package:a3traf/core/firebase/seed_catalog.dart';
import 'package:a3traf/core/firebase/tester_catalog.dart';
import 'package:a3traf/core/utils/validators.dart';
import 'package:a3traf/features/auth/domain/app_user.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('only the admin login remains', () {
    expect(TesterCatalog.logins, [TesterCatalog.admin]);
    expect(TesterCatalog.admin.toUser().isAdmin, isTrue);
    expect(TesterCatalog.admin.email, AppConstants.adminEmail);
    expect(
      TesterCatalog.logins.any((item) => item.role != UserRole.admin),
      isFalse,
    );
  });

  test('disposable tester emails are not kept as logins', () {
    for (final tester in TesterCatalog.disposable) {
      expect(TesterCatalog.isDisposableEmail(tester.email), isTrue);
      expect(
        TesterCatalog.logins.any((item) => item.email == tester.email),
        isFalse,
      );
    }
  });

  test('mina works mornings and is off friday', () {
    final mina = seedPriests.firstWhere((item) => item.id == 'p_mina');
    expect(mina.firstSlotHour, 9);
    expect(mina.lastSlotHour, 12);
    expect(mina.worksOn(DateTime(2026, 3, 20)), isFalse);
    expect(mina.worksOn(DateTime(2026, 3, 21)), isTrue);
  });

  test('dawoud is hidden and kirollos has no account', () {
    final dawoud = seedPriests.firstWhere((item) => item.id == 'p_dawoud');
    final kirollos = seedPriests.firstWhere((item) => item.id == 'p_kirollos');
    expect(dawoud.isAvailable, isFalse);
    expect(kirollos.hasAccount, isFalse);
  });

  test('validators cover empty, email and password cases', () {
    expect(Validators.required(''), isNotNull);
    expect(Validators.email('not-mail'), isNotNull);
    expect(Validators.email('ok@ghofran.app'), isNull);
    expect(Validators.password('123'), isNotNull);
    expect(Validators.password(AppConstants.demoPassword), isNull);
    expect(Validators.confirmPassword('12345678', 'mismatch'), isNotNull);
  });
}
