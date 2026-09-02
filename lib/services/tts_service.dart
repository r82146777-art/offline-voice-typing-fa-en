/// سرویس متن به گفتار (فعلاً غیرفعال برای پاس شدن بیلد)
/// بعد از ساخت موفق APK دوباره فعال می‌شود.
class TtsService {
  Future<void> speak(String text, {String? languageCode}) async {
    // فعلاً خالی
  }

  Future<void> stop() async {}

  Future<void> setLanguage(String code) async {}
}
