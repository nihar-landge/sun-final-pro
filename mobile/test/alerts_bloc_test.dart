import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:feedback_app/core/network/api_client.dart';
import 'package:feedback_app/features/alerts/data/datasources/notification_remote_data_source.dart';
import 'package:feedback_app/features/alerts/presentation/bloc/alerts_bloc.dart';

/// Regression: AlertsBloc has no repository layer, so its data source throws
/// ServerException/NetworkException directly. Those must be mapped to
/// AlertsFailure rather than escaping the bloc (which left the UI stuck on
/// the loading state and crashed callers).
void main() {
  test('server error surfaces as AlertsFailure with the backend message',
      () async {
    final api = ApiClient(
      client: MockClient((_) async => http.Response(
            '{"success":false,"message":"inbox exploded"}',
            500,
            headers: {'content-type': 'application/json'},
          )),
    );
    final bloc =
        AlertsBloc(remoteDataSource: NotificationRemoteDataSource(api));

    final failureFuture = bloc.stream
        .firstWhere((state) => state is AlertsFailure)
        .then((state) => state as AlertsFailure);
    bloc.add(const AlertsRefreshed());

    expect((await failureFuture).message, 'inbox exploded');
    await bloc.close();
  });

  test('network error surfaces as AlertsFailure with a friendly message',
      () async {
    final api = ApiClient(
      client: MockClient((_) async => throw http.ClientException('no route')),
    );
    final bloc =
        AlertsBloc(remoteDataSource: NotificationRemoteDataSource(api));

    final failureFuture = bloc.stream
        .firstWhere((state) => state is AlertsFailure)
        .then((state) => state as AlertsFailure);
    bloc.add(const AlertsRefreshed());

    expect((await failureFuture).message,
        'Could not reach the server. Check your connection.');
    await bloc.close();
  });
}
