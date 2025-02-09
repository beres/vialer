import '../../../data/models/user/user.dart';
import '../use_case.dart';
import 'get_stored_user.dart';

/// Returns the locally stored user. Will throw if called before user is
/// logged in.
class GetLoggedInUserUseCase extends UseCase {
  final _getStoredUser = GetStoredUserUseCase();

  User call() => _getStoredUser()!;
}
