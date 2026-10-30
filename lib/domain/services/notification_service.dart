abstract class NotificationService {
  Future<bool> requestPermission();

  Future<void> showSodiumAlert({required String title, required String body});
}
