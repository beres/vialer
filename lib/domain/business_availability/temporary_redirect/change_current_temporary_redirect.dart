import 'dart:async';

import '../../../../dependency_locator.dart';
import '../../metrics/metrics.dart';
import '../../use_case.dart';
import '../../user/get_logged_in_user.dart';
import '../business_availability_repository.dart';
import 'get_current_temporary_redirect.dart';
import 'temporary_redirect.dart';
import 'temporary_redirect_exception.dart';

class ChangeCurrentTemporaryRedirect extends UseCase
    with TemporaryRedirectEventBroadcaster {
  late final _getUser = GetLoggedInUserUseCase();
  late final _businessAvailability =
      dependencyLocator<BusinessAvailabilityRepository>();
  late final _metricsRepository = dependencyLocator<MetricsRepository>();

  Future<void> call({
    required TemporaryRedirect temporaryRedirect,
  }) async {
    try {
      await _businessAvailability.updateTemporaryRedirect(
        user: _getUser(),
        temporaryRedirect: temporaryRedirect,
      );
    } on NoTemporaryRedirectSetupException catch (e) {
      logger.info(
        'Unable to change current temporary redirect: $e',
      );
      return;
    }

    _metricsRepository.track('temporary-redirect-changed', {
      'ending-at': temporaryRedirect.endsAt.toIso8601String(),
      'id': temporaryRedirect.id,
    });

    unawaited(broadcast());
  }
}
