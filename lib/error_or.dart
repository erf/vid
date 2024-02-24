class ErrorOr<T> {
  final T? value;
  final String? error;

  const ErrorOr(this.value, this.error);

  const ErrorOr.value(T value) : this(value, null);

  const ErrorOr.error(String error) : this(null, error);

  bool get hasValue => value != null;

  bool get hasError => error != null;
}
