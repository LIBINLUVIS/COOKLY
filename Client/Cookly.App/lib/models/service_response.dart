/// Mirrors the backend's `ServiceResponseDto<T>` envelope. The API always
/// responds with HTTP 200, even for business-logic failures, so callers
/// must check [success] rather than the HTTP status code.
class ServiceResponse<T> {
  const ServiceResponse({
    required this.success,
    required this.message,
    required this.messageKey,
    required this.data,
  });

  factory ServiceResponse.fromJson(
    Map<String, dynamic> json,
    T? Function(Object? json) fromData,
  ) {
    return ServiceResponse<T>(
      success: json['success'] as bool? ?? false,
      message: json['message'] as String?,
      messageKey: json['messageKey'] as String?,
      data: fromData(json['data']),
    );
  }

  final bool success;
  final String? message;
  final String? messageKey;
  final T? data;
}
