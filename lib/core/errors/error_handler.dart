import 'dart:async';
import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zim_herbs_repo/core/errors/failure.dart';

class ErrorHandler {
  /// Transforms any thrown error/exception into a user-friendly [Failure].
  static Failure handle(Object error, [StackTrace? stackTrace]) {
    if (error is Failure) {
      return error;
    }

    if (error is AuthException) {
      return _handleAuthException(error, stackTrace);
    }

    if (error is PostgrestException) {
      return _handlePostgrestException(error, stackTrace);
    }

    if (error is StorageException) {
      return _handleStorageException(error, stackTrace);
    }

    if (error is FunctionException) {
      return _handleFunctionException(error, stackTrace);
    }

    if (error is SocketException) {
      return Failure(
        title: 'No Internet Connection',
        message:
            'Unable to reach the server. Please check your Wi-Fi or mobile data connection and try again.',
        type: FailureType.noInternet,
        originalError: error,
        stackTrace: stackTrace,
      );
    }

    if (error is TimeoutException) {
      return Failure(
        title: 'Connection Timed Out',
        message:
            'The request took too long to complete. Please check your internet connection and try again.',
        type: FailureType.timeout,
        originalError: error,
        stackTrace: stackTrace,
      );
    }

    if (error is HttpException) {
      final msg = error.message.toLowerCase();
      if (_isServerPattern(msg)) {
        return Failure(
          title: 'Server Unavailable',
          message:
              'The server is currently unreachable or undergoing maintenance. Please try again shortly.',
          type: FailureType.serverUnavailable,
          originalError: error,
          stackTrace: stackTrace,
        );
      }
      if (_isNetworkPattern(msg)) {
        return Failure(
          title: 'No Internet Connection',
          message:
              'Unable to connect to the server. Please check your network connection.',
          type: FailureType.noInternet,
          originalError: error,
          stackTrace: stackTrace,
        );
      }
      return Failure(
        title: 'Communication Error',
        message:
            'A network communication error occurred. Please try again in a few moments.',
        type: FailureType.serverUnavailable,
        originalError: error,
        stackTrace: stackTrace,
      );
    }

    if (error is FormatException) {
      return Failure(
        title: 'Invalid Data Format',
        message:
            'The data entered or received was in an invalid format. Please check your input and try again.',
        type: FailureType.validation,
        originalError: error,
        stackTrace: stackTrace,
      );
    }

    // Inspect general exception messages (e.g. ClientException from http package)
    final errorStr = error.toString();
    return _handleStringPatterns(errorStr, error, stackTrace);
  }

  static Failure _handleAuthException(
      AuthException error, StackTrace? stackTrace) {
    final rawMessage = error.message.toLowerCase();
    final statusCode = int.tryParse(error.statusCode ?? '');

    // 1. Check for network patterns in auth message first
    if (_isNetworkPattern(rawMessage)) {
      return Failure(
        title: 'No Internet Connection',
        message:
            'Unable to reach authentication services. Please check your internet connection and try again.',
        type: FailureType.noInternet,
        originalError: error,
        stackTrace: stackTrace,
      );
    }

    // 2. Server down, 5xx status or server failure keywords
    if ((statusCode != null && statusCode >= 500) ||
        _isServerPattern(rawMessage)) {
      return Failure(
        title: 'Server Unavailable',
        message:
            'The authentication server is temporarily down or unavailable. Please try again shortly.',
        type: FailureType.serverUnavailable,
        originalError: error,
        stackTrace: stackTrace,
      );
    }

    // 3. Rate limiting (429)
    if (statusCode == 429 ||
        rawMessage.contains('rate limit') ||
        rawMessage.contains('too many requests') ||
        rawMessage.contains('over_email_send_rate_limit')) {
      return Failure(
        title: 'Too Many Attempts',
        message:
            'Too many requests were made in a short time. Please wait a few moments before trying again.',
        type: FailureType.tooManyRequests,
        originalError: error,
        stackTrace: stackTrace,
      );
    }

    // 4. Invalid credentials
    if (rawMessage.contains('invalid login credentials') ||
        rawMessage.contains('invalid_grant') ||
        rawMessage.contains('invalid credentials') ||
        rawMessage.contains('wrong password') ||
        rawMessage.contains('invalid username or password')) {
      return Failure(
        title: 'Incorrect Credentials',
        message:
            'The email or password you entered is incorrect. Please check your credentials and try again.',
        type: FailureType.invalidCredentials,
        originalError: error,
        stackTrace: stackTrace,
      );
    }

    // 5. User already exists
    if (rawMessage.contains('user already registered') ||
        rawMessage.contains('user_already_exists') ||
        rawMessage.contains('already in use') ||
        rawMessage.contains('email already registered') ||
        rawMessage.contains('user with this email already exists')) {
      return Failure(
        title: 'Account Already Exists',
        message:
            'An account with this email address already exists. Please switch to Sign In.',
        type: FailureType.userAlreadyExists,
        originalError: error,
        stackTrace: stackTrace,
      );
    }

    // 6. User not found
    if (rawMessage.contains('user not found') ||
        rawMessage.contains('user_not_found') ||
        rawMessage.contains('no user found')) {
      return Failure(
        title: 'Account Not Found',
        message:
            'No account was found with this email address. Please verify your email or register for a new account.',
        type: FailureType.userNotFound,
        originalError: error,
        stackTrace: stackTrace,
      );
    }

    // 7. Email not confirmed
    if (rawMessage.contains('email not confirmed') ||
        rawMessage.contains('email_not_confirmed') ||
        rawMessage.contains('not confirmed')) {
      return Failure(
        title: 'Email Not Verified',
        message:
            'Please check your email and click the confirmation link before signing in.',
        type: FailureType.emailNotConfirmed,
        originalError: error,
        stackTrace: stackTrace,
      );
    }

    // 8. Weak password
    if (rawMessage.contains('password should be at least') ||
        rawMessage.contains('weak_password') ||
        rawMessage.contains('password is too weak') ||
        rawMessage.contains('password should')) {
      return Failure(
        title: 'Weak Password',
        message:
            'Password must be at least 6 characters long. For security, please include letters and numbers.',
        type: FailureType.weakPassword,
        originalError: error,
        stackTrace: stackTrace,
      );
    }

    // 9. Invalid email format
    if (rawMessage.contains('invalid format') ||
        rawMessage.contains('valid email') ||
        rawMessage.contains('unable to validate email')) {
      return Failure(
        title: 'Invalid Email Address',
        message:
            'The email address entered is not valid. Please enter a valid email address (e.g. name@example.com).',
        type: FailureType.validation,
        originalError: error,
        stackTrace: stackTrace,
      );
    }

    // Cleaned generic fallback
    final cleanMessage = _cleanRawMessage(error.message);
    return Failure(
      title: 'Authentication Error',
      message: cleanMessage.isNotEmpty
          ? cleanMessage
          : 'Unable to authenticate. Please check your credentials and try again.',
      type: FailureType.unknown,
      originalError: error,
      stackTrace: stackTrace,
    );
  }

  static Failure _handlePostgrestException(
      PostgrestException error, StackTrace? stackTrace) {
    final code = error.code ?? '';
    final rawMessage = error.message.toLowerCase();
    final details = error.details?.toString().toLowerCase() ?? '';
    final combined = '$rawMessage $details';

    // 1. Network / connectivity issue during Postgrest operation
    if (_isNetworkPattern(combined)) {
      return Failure(
        title: 'No Internet Connection',
        message:
            'Unable to connect to the database. Please check your network connection and try again.',
        type: FailureType.noInternet,
        originalError: error,
        stackTrace: stackTrace,
      );
    }

    // 2. Server down, 5xx status codes, or database crash/restart
    // PostgreSQL error classes:
    // 08*** = Connection Exception
    // 53*** = Insufficient Resources (e.g. out of memory, too many connections)
    // 54*** = Program Limit Exceeded
    // 57*** = Operator Intervention (admin shutdown, query cancelled)
    // 58*** = System Error
    // XX*** = Internal PostgreSQL Error
    // PGRST0*** = Internal PostgREST Server Errors
    if (code.startsWith('08') ||
        code.startsWith('53') ||
        code.startsWith('54') ||
        code.startsWith('57') ||
        code.startsWith('58') ||
        code.startsWith('XX') ||
        code == '500' ||
        code == '502' ||
        code == '503' ||
        code == '504' ||
        code.startsWith('PGRST0') ||
        _isServerPattern(combined)) {
      return Failure(
        title: 'Server Temporarily Unavailable',
        message:
            'The database server is temporarily unavailable or undergoing maintenance. Please try again shortly.',
        type: FailureType.serverUnavailable,
        originalError: error,
        stackTrace: stackTrace,
      );
    }

    // 3. Permission denied / RLS policy / JWT expired
    if (code == '42501' ||
        code == 'PGRST301' ||
        combined.contains('permission denied') ||
        combined.contains('row-level security') ||
        combined.contains('jwt expired')) {
      return Failure(
        title: 'Access Denied',
        message:
            'You do not have permission to view or perform this action. If your session expired, please sign in again.',
        type: FailureType.accessDenied,
        originalError: error,
        stackTrace: stackTrace,
      );
    }

    // 4. Missing database relation/table (schema mismatch)
    if (code == '42P01' ||
        (combined.contains('relation') && combined.contains('does not exist'))) {
      return Failure(
        title: 'Service Error',
        message:
            'The requested service is currently updating. Please try again in a few moments.',
        type: FailureType.serverUnavailable,
        originalError: error,
        stackTrace: stackTrace,
      );
    }

    // 5. Unique constraint violation (e.g. duplicate email/key)
    if (code == '23505' || combined.contains('unique constraint')) {
      return Failure(
        title: 'Duplicate Entry',
        message:
            'A record with this information already exists in the system.',
        type: FailureType.userAlreadyExists,
        originalError: error,
        stackTrace: stackTrace,
      );
    }

    // 6. Record not found
    if (code == 'PGRST116' || combined.contains('not found')) {
      return Failure(
        title: 'Not Found',
        message: 'The requested record could not be found.',
        type: FailureType.notFound,
        originalError: error,
        stackTrace: stackTrace,
      );
    }

    // Fallback: sanitized clean message
    final clean = _cleanRawMessage(error.message);
    return Failure(
      title: 'Database Error',
      message: clean.isNotEmpty
          ? clean
          : 'A database error occurred while processing your request.',
      type: FailureType.unknown,
      originalError: error,
      stackTrace: stackTrace,
    );
  }

  static Failure _handleStorageException(
      StorageException error, StackTrace? stackTrace) {
    final rawMessage = error.message.toLowerCase();
    final statusCode = int.tryParse(error.statusCode ?? '');

    if (_isNetworkPattern(rawMessage)) {
      return Failure(
        title: 'No Internet Connection',
        message:
            'Unable to reach file storage. Please check your internet connection.',
        type: FailureType.noInternet,
        originalError: error,
        stackTrace: stackTrace,
      );
    }

    if ((statusCode != null && statusCode >= 500) ||
        _isServerPattern(rawMessage)) {
      return Failure(
        title: 'Storage Server Unavailable',
        message:
            'The storage service is temporarily down or busy. Please try uploading again in a moment.',
        type: FailureType.serverUnavailable,
        originalError: error,
        stackTrace: stackTrace,
      );
    }

    if (statusCode == 403 || statusCode == 401 || rawMessage.contains('unauthorized')) {
      return Failure(
        title: 'Storage Access Denied',
        message: 'You do not have permission to upload or delete this file.',
        type: FailureType.accessDenied,
        originalError: error,
        stackTrace: stackTrace,
      );
    }

    return Failure(
      title: 'File Storage Error',
      message: _cleanRawMessage(error.message),
      type: FailureType.unknown,
      originalError: error,
      stackTrace: stackTrace,
    );
  }

  static Failure _handleFunctionException(
      FunctionException error, StackTrace? stackTrace) {
    final detailsStr = error.details?.toString() ?? '';
    final combinedStr = '$detailsStr ${error.toString()}'.toLowerCase();
    final status = error.status;

    if (_isNetworkPattern(combinedStr)) {
      return Failure(
        title: 'No Internet Connection',
        message: 'Unable to reach the server. Please check your network connection.',
        type: FailureType.noInternet,
        originalError: error,
        stackTrace: stackTrace,
      );
    }

    if (status >= 500 || _isServerPattern(combinedStr)) {
      return Failure(
        title: 'Server Error',
        message:
            'The cloud service encountered an unexpected error. Please try again shortly.',
        type: FailureType.serverUnavailable,
        originalError: error,
        stackTrace: stackTrace,
      );
    }

    return Failure(
      title: 'Service Error',
      message: detailsStr.isNotEmpty
          ? _cleanRawMessage(detailsStr)
          : 'A service error occurred. Please try again later.',
      type: FailureType.unknown,
      originalError: error,
      stackTrace: stackTrace,
    );
  }

  static Failure _handleStringPatterns(
      String errorStr, Object originalError, StackTrace? stackTrace) {
    final lower = errorStr.toLowerCase();

    // Network / Socket / Offline issues
    if (_isNetworkPattern(lower)) {
      return Failure(
        title: 'No Internet Connection',
        message:
            'Cannot connect to the server. Please check your internet connection and try again.',
        type: FailureType.noInternet,
        originalError: originalError,
        stackTrace: stackTrace,
      );
    }

    // Server down / 502 / 503 / 504 / 500
    if (_isServerPattern(lower)) {
      return Failure(
        title: 'Server Unavailable',
        message:
            'The server is currently unreachable or encountering technical difficulties. Please try again in a few moments.',
        type: FailureType.serverUnavailable,
        originalError: originalError,
        stackTrace: stackTrace,
      );
    }

    // Timeout
    if (lower.contains('timed out') || lower.contains('timeout')) {
      return Failure(
        title: 'Connection Timed Out',
        message:
            'The server took too long to respond. Please check your network connection and try again.',
        type: FailureType.timeout,
        originalError: originalError,
        stackTrace: stackTrace,
      );
    }

    // Invalid credentials string
    if (lower.contains('invalid login credentials') ||
        lower.contains('invalid credentials') ||
        lower.contains('incorrect password') ||
        lower.contains('wrong password')) {
      return Failure(
        title: 'Incorrect Credentials',
        message:
            'The email or password you entered is incorrect. Please check your details and try again.',
        type: FailureType.invalidCredentials,
        originalError: originalError,
        stackTrace: stackTrace,
      );
    }

    // Access denied / Unauthorized
    if (lower.contains('access denied') ||
        lower.contains('permission denied') ||
        lower.contains('unauthorized')) {
      return Failure(
        title: 'Access Denied',
        message: 'You do not have permission to access this resource.',
        type: FailureType.accessDenied,
        originalError: originalError,
        stackTrace: stackTrace,
      );
    }

    // Cleaned generic fallback
    final clean = _cleanRawMessage(errorStr);
    return Failure(
      title: 'Error',
      message: clean.isNotEmpty
          ? clean
          : 'An unexpected error occurred. Please try again.',
      type: FailureType.unknown,
      originalError: originalError,
      stackTrace: stackTrace,
    );
  }

  /// Comprehensive check for network / socket / connectivity error patterns
  static bool _isNetworkPattern(String text) {
    final lower = text.toLowerCase();
    return lower.contains('failed host lookup') ||
        lower.contains('network is unreachable') ||
        lower.contains('connection refused') ||
        lower.contains('connection reset') ||
        lower.contains('connection closed') ||
        lower.contains('connection aborted') ||
        lower.contains('socketexception') ||
        lower.contains('clientexception') ||
        lower.contains('failed to fetch') ||
        lower.contains('xmlhttprequest') ||
        lower.contains('network request failed') ||
        lower.contains('networkerror') ||
        lower.contains('no address associated with hostname') ||
        lower.contains('handshakeexception') ||
        lower.contains('tls error') ||
        lower.contains('certificate verify failed') ||
        lower.contains('software caused connection abort') ||
        lower.contains('offline') ||
        lower.contains('errno = 111') ||
        lower.contains('errno = 110') ||
        lower.contains('operation timed out') ||
        lower.contains('timed out');
  }

  /// Comprehensive check for server, proxy, and 5xx error patterns
  static bool _isServerPattern(String text) {
    final lower = text.toLowerCase();
    return lower.contains('500 internal server error') ||
        lower.contains('502 bad gateway') ||
        lower.contains('503 service unavailable') ||
        lower.contains('504 gateway timeout') ||
        lower.contains('internal server error') ||
        lower.contains('bad gateway') ||
        lower.contains('service unavailable') ||
        lower.contains('gateway timeout') ||
        lower.contains('server error') ||
        lower.contains('database error') ||
        lower.contains('unexpected_failure') ||
        lower.contains('unexpected failure') ||
        lower.contains('status code: 500') ||
        lower.contains('status code: 502') ||
        lower.contains('status code: 503') ||
        lower.contains('status code: 504') ||
        lower.contains('500:') ||
        lower.contains('502:') ||
        lower.contains('503:') ||
        lower.contains('504:');
  }

  /// Cleans technical prefixes, HTML tags, and exception wrappers
  static String _cleanRawMessage(String raw) {
    // 1. Strip HTML tags (e.g. from reverse proxy 502/503 HTML error responses)
    var cleaned = raw.replaceAll(RegExp(r'<[^>]*>'), ' ').trim();

    // 2. Remove common Dart exception prefixes
    cleaned = cleaned
        .replaceAll(RegExp(r'^Exception:\s*', caseSensitive: false), '')
        .replaceAll(RegExp(r'^ClientException:\s*', caseSensitive: false), '')
        .replaceAll(RegExp(r'^AuthException:\s*', caseSensitive: false), '')
        .replaceAll(RegExp(r'^PostgrestException:\s*', caseSensitive: false), '')
        .replaceAll(RegExp(r'^StorageException:\s*', caseSensitive: false), '')
        .replaceAll(RegExp(r'^HttpException:\s*', caseSensitive: false), '')
        .trim();

    // 3. Clean consecutive whitespace
    cleaned = cleaned.replaceAll(RegExp(r'\s+'), ' ').trim();

    // 4. If it mentions technical network patterns, normalize to friendly text
    if (_isNetworkPattern(cleaned.toLowerCase())) {
      return 'Unable to connect to the server. Please verify your internet connection.';
    }

    // 5. If it contains technical server failure patterns, normalize to friendly text
    if (_isServerPattern(cleaned.toLowerCase())) {
      return 'The server encountered an error while processing your request. Please try again shortly.';
    }

    // 6. If it's a technical Postgrest relation missing error, sanitize it
    if (cleaned.contains('relation') && cleaned.contains('does not exist')) {
      return 'The requested database resource is currently unavailable. Please try again later.';
    }

    return cleaned;
  }
}
