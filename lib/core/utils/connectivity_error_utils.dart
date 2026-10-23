import 'package:camion/core/api/local_status_codes.dart';

bool isConnectivityErrorStatus(int? statusCode) {
  return statusCode == LocalStatusCodes.connectionError ||
      statusCode == LocalStatusCodes.connectionTimeout ||
      statusCode == LocalStatusCodes.sendTimeout ||
      statusCode == LocalStatusCodes.receiveTimeout;
}

bool isBackendUnavailableStatus(int? statusCode) {
  return statusCode == 500 || statusCode == 502 || statusCode == 503;
}
