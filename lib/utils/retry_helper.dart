import 'dart:async';

/// A utility class for retrying failed async operations with exponential backoff.
///
/// Example usage:
/// ```dart
/// final result = await RetryHelper.retry(
///   () => fetchDataFromApi(),
///   maxRetries: 3,
///   initialDelay: Duration(seconds: 1),
/// );
/// ```
class RetryHelper {
  /// Retries the given [operation] with exponential backoff.
  ///
  /// Parameters:
  /// - [operation]: The async operation to retry.
  /// - [maxRetries]: Maximum number of retry attempts (default: 3).
  /// - [initialDelay]: Initial delay before the first retry (default: 1 second).
  ///   Each subsequent retry doubles the delay.
  /// - [retryIf]: Optional condition to determine if retry should occur.
  ///   If not provided, all exceptions trigger a retry.
  ///
  /// Returns the result of [operation] if successful.
  /// Throws the last exception if all retries are exhausted.
  static Future<T> retry<T>(
    Future<T> Function() operation, {
    int maxRetries = 3,
    Duration initialDelay = const Duration(seconds: 1),
    bool Function(Exception)? retryIf,
  }) async {
    int attempt = 0;
    Duration currentDelay = initialDelay;

    while (true) {
      try {
        return await operation();
      } on Exception catch (e) {
        attempt++;

        // Check if we should retry based on the condition
        final shouldRetry = retryIf?.call(e) ?? true;

        if (attempt >= maxRetries || !shouldRetry) {
          // Max retries reached or condition says don't retry
          rethrow;
        }

        // Wait with exponential backoff before retrying
        await Future.delayed(currentDelay);

        // Double the delay for the next attempt (exponential backoff)
        currentDelay *= 2;
      }
    }
  }

  /// Retries the given [operation] with exponential backoff and a callback
  /// for each retry attempt.
  ///
  /// Parameters:
  /// - [operation]: The async operation to retry.
  /// - [maxRetries]: Maximum number of retry attempts (default: 3).
  /// - [initialDelay]: Initial delay before the first retry (default: 1 second).
  /// - [onRetry]: Callback invoked before each retry with the attempt number
  ///   and the exception that caused the retry.
  /// - [retryIf]: Optional condition to determine if retry should occur.
  ///
  /// Returns the result of [operation] if successful.
  /// Throws the last exception if all retries are exhausted.
  static Future<T> retryWithCallback<T>(
    Future<T> Function() operation, {
    int maxRetries = 3,
    Duration initialDelay = const Duration(seconds: 1),
    void Function(int attempt, Exception error)? onRetry,
    bool Function(Exception)? retryIf,
  }) async {
    int attempt = 0;
    Duration currentDelay = initialDelay;

    while (true) {
      try {
        return await operation();
      } on Exception catch (e) {
        attempt++;

        // Check if we should retry based on the condition
        final shouldRetry = retryIf?.call(e) ?? true;

        if (attempt >= maxRetries || !shouldRetry) {
          // Max retries reached or condition says don't retry
          rethrow;
        }

        // Invoke the retry callback
        onRetry?.call(attempt, e);

        // Wait with exponential backoff before retrying
        await Future.delayed(currentDelay);

        // Double the delay for the next attempt (exponential backoff)
        currentDelay *= 2;
      }
    }
  }
}

/// Exception thrown when all retry attempts have been exhausted.
class MaxRetriesExceededException implements Exception {
  final int attempts;
  final Exception lastException;

  MaxRetriesExceededException({
    required this.attempts,
    required this.lastException,
  });

  @override
  String toString() {
    return 'MaxRetriesExceededException: Failed after $attempts attempts. '
        'Last error: $lastException';
  }
}
