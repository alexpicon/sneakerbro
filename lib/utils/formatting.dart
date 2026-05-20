// Display formatting helpers. Deliberately hand-rolled instead of pulling in
// the intl package - this app only needs a couple of formats and keeping the
// dependency list short suits an archived project.

const List<String> _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

/// Groups the digits of a whole number with commas: 12345 -> "12,345".
String groupDigits(int value) {
  final negative = value < 0;
  final digits = value.abs().toString();
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(',');
    buffer.write(digits[i]);
  }
  return '${negative ? '-' : ''}$buffer';
}

/// Formats a money amount: 1234.5 -> "$1,234.50".
String money(num value) {
  final negative = value < 0;
  final fixed = value.abs().toStringAsFixed(2);
  final parts = fixed.split('.');
  final whole = groupDigits(int.parse(parts[0]));
  return '${negative ? '-' : ''}\$$whole.${parts[1]}';
}

/// A signed money amount, handy for value gains/losses: "+$120.00" / "-$30.00".
String signedMoney(num value) {
  if (value > 0) return '+${money(value)}';
  return money(value);
}

/// A money amount with no cents, for big headline figures: 1234.5 -> "$1,235".
String moneyWhole(num value) {
  final negative = value < 0;
  return '${negative ? '-' : ''}\$${groupDigits(value.abs().round())}';
}

/// A signed whole-dollar amount: "+$1,235" / "-$30".
String signedMoneyWhole(num value) {
  if (value > 0) return '+${moneyWhole(value)}';
  return moneyWhole(value);
}

/// "Mar 12, 2021", or a fallback when there is no date.
String longDate(DateTime? date, {String fallback = 'No date'}) {
  if (date == null) return fallback;
  return '${_months[date.month - 1]} ${date.day}, ${date.year}';
}

/// "Mar 2021", used where the day does not matter.
String monthYear(DateTime? date, {String fallback = '-'}) {
  if (date == null) return fallback;
  return '${_months[date.month - 1]} ${date.year}';
}
