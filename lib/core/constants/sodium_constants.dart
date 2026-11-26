const double dailySodiumLimitMg = 2000;
const double nearLimitThresholdMg = 1500;
const double maxSodiumPerEntryMg = 10000;

/// Status "Mendekati Batas" dimulai di atas 75% target harian (1500 dari 2000 mg).
const double nearLimitRatio = nearLimitThresholdMg / dailySodiumLimitMg;

/// Rentang target harian yang boleh diatur pengguna (fitur #16).
const int minDailyLimitMg = 1000;
const int maxDailyLimitMg = 3000;
