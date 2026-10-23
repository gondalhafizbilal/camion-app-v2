part of 'currency_cubit.dart';

abstract class CurrencyState {}

class CurrencyInitial extends CurrencyState {}

class CurrencyLoading extends CurrencyState {}

class CurrencyLoaded extends CurrencyState {
  final List<Currency> currencies;
  final Currency? selected;
  CurrencyLoaded(this.currencies, this.selected);
}

class CurrencySelected extends CurrencyState {
  final Currency selected;
  CurrencySelected(this.selected);
}

class CurrencyError extends CurrencyState {
  final ApiErrorModel error;
  CurrencyError(this.error);
}
