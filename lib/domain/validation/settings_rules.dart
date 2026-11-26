import '../../core/constants/sodium_constants.dart';
import 'input_rules.dart';

const String _dailyLimitLabel = 'Target natrium';
const String dailyLimitRangeMessage = '$_dailyLimitLabel harus $minDailyLimitMg sampai $maxDailyLimitMg mg.';

int? parseDailyLimit(String? input) => parseInteger(input);

String? validateDailyLimit(String? value) {
  final error = validatePositiveNumber(value, label: _dailyLimitLabel, parse: parseDailyLimit);
  if (error != null) return error;
  return isValidDailyLimit(parseDailyLimit(value)!) ? null : dailyLimitRangeMessage;
}

bool isValidDailyLimit(int limitMg) => limitMg >= minDailyLimitMg && limitMg <= maxDailyLimitMg;
