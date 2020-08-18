import 'dart:async';

import 'package:meta/meta.dart';

import '../../../dependency_locator.dart';
import '../../use_case.dart';
import '../../repositories/auth.dart';

class LoginUseCase extends FutureUseCase<bool> {
  final _authRepository = dependencyLocator<AuthRepository>();

  @override
  Future<bool> call({
    @required String email,
    @required String password,
  }) =>
      _authRepository.authenticate(email, password);
}
