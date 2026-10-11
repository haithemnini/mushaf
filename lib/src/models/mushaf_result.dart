/// Simple success/failure without app-specific networking types.
sealed class MushafResult<T> {
  const MushafResult();

  R when<R>({
    required R Function(T data) success,
    required R Function(String message) failure,
  });

  R? maybeWhen<R>({
    R Function(T data)? success,
    R Function(String message)? failure,
    R Function()? orElse,
  });
}

final class MushafSuccess<T> extends MushafResult<T> {
  const MushafSuccess(this.data);
  final T data;

  @override
  R when<R>({
    required R Function(T data) success,
    required R Function(String message) failure,
  }) =>
      success(data);

  @override
  R? maybeWhen<R>({
    R Function(T data)? success,
    R Function(String message)? failure,
    R Function()? orElse,
  }) {
    if (success != null) return success(data);
    return orElse?.call();
  }
}

final class MushafFailure<T> extends MushafResult<T> {
  const MushafFailure(this.message);
  final String message;

  @override
  R when<R>({
    required R Function(T data) success,
    required R Function(String message) failure,
  }) =>
      failure(message);

  @override
  R? maybeWhen<R>({
    R Function(T data)? success,
    R Function(String message)? failure,
    R Function()? orElse,
  }) {
    if (failure != null) return failure(message);
    return orElse?.call();
  }
}
