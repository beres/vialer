import '../../../data/repositories/remote_logging/logging.dart';
import '../../../dependency_locator.dart';
import '../use_case.dart';
import '../user/get_stored_user.dart';
import 'get_logging_token.dart';

class EnableRemoteLoggingUseCase extends UseCase {
  final _loggingRepository = dependencyLocator<LoggingRepository>();

  final _getUser = GetStoredUserUseCase();
  final _getLoggingToken = GetLoggingTokenUseCase();

  Future<void> call() async {
    final user = _getUser();
    final token = _getLoggingToken();

    final loggingIdentifier = user?.loggingIdentifier ?? '';

    if (_loggingRepository.isNativelyLoggingToRemote) {
      await _loggingRepository.disableNativeConsoleLogging();
    }

    await _loggingRepository.enableNativeRemoteLogging(
      userIdentifier: loggingIdentifier,
      token: token,
    );

    if (_loggingRepository.isLoggingToRemote) {
      await _loggingRepository.disableRemoteLogging();
    }

    return _loggingRepository.enableRemoteLogging(
      userIdentifier: loggingIdentifier,
      token: token,
    );
  }
}
