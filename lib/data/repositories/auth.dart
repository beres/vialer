import '../../domain/entities/brand.dart';
import '../../domain/entities/need_to_change_password.dart';

import '../../domain/repositories/auth.dart';
import '../../domain/repositories/storage.dart';

import 'services/voipgrid.dart';
import '../../domain/entities/system_user.dart';

class DataAuthRepository extends AuthRepository {
  final StorageRepository _storageRepository;
  final Brand _brand;

  DataAuthRepository(
    this._storageRepository,
    this._brand,
  ) {
    service = VoipgridService.create(
      baseUrl: _brand.baseUrl,
      authRepository: this,
    );
  }

  VoipgridService service;

  static const _emailKey = 'email';
  static const _passwordKey = 'password';
  static const _apiTokenKey = 'api_token';

  SystemUser _currentUser;

  @override
  Future<bool> authenticate(String email, String password) async {
    final tokenResponse = await service.getToken({
      _emailKey: email,
      _passwordKey: password,
    });

    final body = tokenResponse.body;

    if (body != null && body.containsKey(_apiTokenKey)) {
      final token = body[_apiTokenKey];

      // Set a temporary system user that the authorization interceptor will
      // use
      _currentUser = SystemUser(
        email: email,
        token: token,
      );

      final systemUserResponse = await service.getSystemUser();
      if (systemUserResponse.error
          .toString()
          .contains('You need to change your password in the portal')) {
        throw NeedToChangePassword();
      }

      _storageRepository.systemUser = SystemUser.fromJson(
        systemUserResponse.body,
      ).copyWith(
        token: token,
      );

      _currentUser = _storageRepository.systemUser;

      return true;
    } else {
      return false;
    }
  }

  @override
  Future<bool> isAuthenticated() async {
    return currentUser?.token != null;
  }

  @override
  SystemUser get currentUser {
    _currentUser ??= _storageRepository.systemUser;

    return _currentUser;
  }
}
