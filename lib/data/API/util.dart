import 'dart:async';

import 'package:chopper/chopper.dart' as chopper;
import 'package:chopper/chopper.dart';
import 'package:dartx/dartx.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import '../../dependency_locator.dart';
import '../../domain/usecases/user/get_stored_user.dart';
import '../models/event/event_bus.dart';
import '../models/user/user.dart';
import '../models/voipgrid/rate_limit_reached_event.dart';
import 'authentication/unauthorized_api_response.dart';

class AuthorizationInterceptor implements chopper.RequestInterceptor {
  const AuthorizationInterceptor({
    this.forcedLegacyAuthPaths = const [],
    this.user,
    this.onlyModernAuth = false,
  });

  /// Paths that force the use of the legacy
  /// `Token <email>:<token>` method of authorization.
  ///
  /// Any path that does not have a `v2` as a segment in it, will automatically
  /// use the legacy method of authorization and doesn't need to be set here.
  ///
  /// This only needs to be set if a `v2` API uses the legacy auth method, then
  /// you can provide it here.
  ///
  /// Any call that contains one of these paths will use the legacy
  /// way of authentication.
  final List<String> forcedLegacyAuthPaths;

  /// The user can be passed in directly rather than inferred, this is used
  /// to support creation within an isolate.
  final User? user;

  /// When set to `true` will never use legacy auth regardless of the URL
  /// structure.
  ///
  /// This should be set when it is known that no legacy auth is ever used
  /// on any URLs for the service and the service does not use the standard
  /// `v2` url scheme.
  final bool onlyModernAuth;

  @override
  FutureOr<chopper.Request> onRequest(chopper.Request request) {
    final user = this.user ?? GetStoredUserUseCase()();

    if (user != null) {
      bool useLegacyAuth;

      if (!onlyModernAuth) {
        if (forcedLegacyAuthPaths.any(request.url.toString().contains)) {
          useLegacyAuth = true;
        } else {
          final pathSegments =
              request.uri.pathSegments.where((s) => s.isNotBlank);

          useLegacyAuth = !pathSegments.any((s) => s == 'v2');
        }
      } else {
        useLegacyAuth = false;
      }

      return request.copyWith(
        headers: Map.of(request.headers)
          ..addAll({
            'Authorization': useLegacyAuth
                ? 'Token ${user.email}:${user.token}'
                : 'Bearer ${user.token}',
          }),
      );
    } else {
      return request;
    }
  }
}

/// We want to log out any users if they encounter as 401 response as this
/// suggests that we do not have a valid token, this will fire the appropriate
/// event so action can be taken.
class UnauthorizedResponseInterceptor implements chopper.ResponseInterceptor {
  UnauthorizedResponseInterceptor({
    this.unauthorizedStatusCodes = const [401],
  });

  final List<int> unauthorizedStatusCodes;
  final _eventBus = dependencyLocator<EventBus>();

  @override
  FutureOr<chopper.Response<dynamic>> onResponse(Response<dynamic> response) {
    final statusCode = response.statusCode;

    if (_isUnauthorized(statusCode)) {
      _eventBus.broadcast(
        UnauthorizedApiResponseEvent(
          url: response.base.request?.url.toString() ?? '',
          statusCode: statusCode,
        ),
      );
    }

    return response;
  }

  bool _isUnauthorized(int statusCode) =>
      unauthorizedStatusCodes.contains(statusCode);
}

class RateLimitReachedInterceptor implements chopper.ResponseInterceptor {
  final _eventBus = dependencyLocator<EventBus>();

  @override
  FutureOr<chopper.Response<dynamic>> onResponse(Response<dynamic> response) {
    final statusCode = response.statusCode;

    if (_isRateLimited(statusCode)) {
      _eventBus.broadcast(
        RateLimitReachedEvent(
          url: response.base.request?.url.toString() ?? '',
          hitLimitAt: DateTime.now(),
        ),
      );
    }

    return response;
  }

  bool _isRateLimited(int statusCode) => statusCode == 429;
}

class SubmitUnexpectedFailedRequestsToSentry
    implements chopper.ResponseInterceptor {
  @override
  FutureOr<chopper.Response<dynamic>> onResponse(Response<dynamic> response) {
    final statusCode = response.statusCode;

    if (!statusCode.shouldSubmitStatusCodeToSentry) return response;

    final url = response.base.request?.url.path ?? '';
    final body = response.bodyString;

    if (Sentry.isEnabled) {
      Sentry.captureMessage(
        '$url responded with [$statusCode]',
        level: SentryLevel.error,
        params: [url, statusCode, body],
      );
    }

    return response;
  }
}

extension on int {
  bool get shouldSubmitStatusCodeToSentry {
    if (this < 400) return false;

    return ![404, 429].contains(this);
  }
}

class JsonConverter extends chopper.JsonConverter {
  @override
  FutureOr<chopper.Response<dynamic>> decodeJson<BodyType, InnerType>(
    chopper.Response<dynamic> response,
  ) async {
    if (response.body == '') {
      return response.copyWith<Map<String, dynamic>>(
        body: {},
      );
    }

    return super.decodeJson<BodyType, InnerType>(response);
  }
}

Iterable<chopper.ResponseInterceptor> get globalInterceptors => [
      SubmitUnexpectedFailedRequestsToSentry(),
    ];
