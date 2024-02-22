class ErrorOr<T> {
  final T? value;
  final String? error;

  ErrorOr(this.value, this.error);

  ErrorOr.value(T value) : this(value, null);

  ErrorOr.error(String error) : this(null, error);

  bool get hasValue => value != null;

  bool get hasError => error != null;
}
