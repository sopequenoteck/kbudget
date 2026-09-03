import 'package:flutter_test/flutter_test.dart';
import 'package:k_budget/src/data/remote/dtos/auth_dtos.dart';

void main() {
  group('AuthResponse', () {
    test('should_mapMustResetCredentialsTrue_when_presentInJson', () {
      final response = AuthResponse.fromJson({
        'token': 'access',
        'refreshToken': 'refresh',
        'email': 'test@test.com',
        'name': 'Test',
        'mustResetCredentials': true,
      });

      expect(response.mustResetCredentials, isTrue);
    });

    test('should_defaultMustResetCredentialsFalse_when_absentFromJson', () {
      final response = AuthResponse.fromJson({
        'token': 'access',
        'refreshToken': 'refresh',
        'email': 'test@test.com',
      });

      expect(response.mustResetCredentials, isFalse);
    });
  });

  group('FirstLoginResetRequest', () {
    test('should_serializeAllFields_when_toJsonCalled', () {
      const request = FirstLoginResetRequest(
        email: 'test@test.com',
        password: 'a-very-long-password',
        displayName: 'Test User',
      );

      final json = request.toJson();

      expect(json['email'], 'test@test.com');
      expect(json['password'], 'a-very-long-password');
      expect(json['displayName'], 'Test User');
    });
  });
}
