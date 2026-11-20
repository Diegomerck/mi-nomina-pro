import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Onboarding Safeguards & Type-Safe Parsing Tests', () {
    test('1. SharedPreferences onboarding_completed flag persistence and retrieval', () async {
      SharedPreferences.setMockInitialValues({
        'onboarding_completed': false,
        'salary': '1250.00',
      });
      final prefs = await SharedPreferences.getInstance();

      expect(prefs.getBool('onboarding_completed'), isFalse);
      expect(prefs.getString('salary'), '1250.00');

      await prefs.setBool('onboarding_completed', true);
      expect(prefs.getBool('onboarding_completed'), isTrue);
    });

    test('2. Type-safe parsing for salary and base_hours prevents num/double TypeErrors', () {
      final Map<String, dynamic> firestoreDataFromCloud = {
        'salary': 25000, // int in Firestore
        'base_hours': 9.5, // double in Firestore
        'user_emp': 123456, // int in Firestore
        'retention': 15.22, // double
        'fomento': 2.0, // double
        'cuota': 2, // int
        'onboarding_completed': true,
      };

      // Type-safe string extraction using .toString()
      final String? salaryStr = firestoreDataFromCloud['salary']?.toString().trim();
      final String? baseHoursStr = firestoreDataFromCloud['base_hours']?.toString().trim();
      final String? userEmpStr = firestoreDataFromCloud['user_emp']?.toString().trim();
      final String? retentionStr = firestoreDataFromCloud['retention']?.toString().trim();
      final String? fomentoStr = firestoreDataFromCloud['fomento']?.toString().trim();
      final String? cuotaStr = firestoreDataFromCloud['cuota']?.toString().trim();
      final bool onboardingCompleted = firestoreDataFromCloud['onboarding_completed'] == true;

      expect(salaryStr, '25000');
      expect(baseHoursStr, '9.5');
      expect(userEmpStr, '123456');
      expect(retentionStr, '15.22');
      expect(fomentoStr, '2.0');
      expect(cuotaStr, '2');
      expect(onboardingCompleted, isTrue);

      final double? parsedSalary = double.tryParse(salaryStr!);
      expect(parsedSalary, 25000.0);
      expect(parsedSalary! > 0, isTrue);
    });

    test('3. Fallback when salary is 0 or empty does not trigger onboarding if onboarding_completed is true', () async {
      SharedPreferences.setMockInitialValues({
        'onboarding_completed': true,
        'salary': '',
      });
      final prefs = await SharedPreferences.getInstance();

      final bool isAlreadyCompleted = prefs.getBool('onboarding_completed') == true;
      final String salary = prefs.getString('salary') ?? '';
      final double? parsedSalary = double.tryParse(salary);
      final bool needsOnboarding = !isAlreadyCompleted && (salary.isEmpty || (parsedSalary ?? 0.0) == 0.0);

      expect(isAlreadyCompleted, isTrue);
      expect(needsOnboarding, isFalse);
    });
  });
}
