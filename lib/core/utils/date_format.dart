const List<String> _dayNames = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];
const List<String> _monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];

String formatDateId(DateTime date) {
  return '${_dayNames[date.weekday - 1]}, ${date.day} ${_monthNames[date.month - 1]} ${date.year}';
}

String formatTimeId(DateTime time) {
  String two(int value) => value.toString().padLeft(2, '0');
  return '${two(time.hour)}.${two(time.minute)}.${two(time.second)}';
}
