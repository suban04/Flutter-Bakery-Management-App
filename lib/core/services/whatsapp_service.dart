import 'package:url_launcher/url_launcher.dart';

class WhatsAppService {
  static Future<void> sendMessage({
    required String phone,
    required String message,
  }) async {
    final cleanPhone = phone.replaceAll(RegExp(r'\D'), '');
    if (cleanPhone.isEmpty) return;

    final fullPhone = cleanPhone.length == 10 ? '91$cleanPhone' : cleanPhone;
    final url = Uri.parse(
      'https://wa.me/$fullPhone?text=${Uri.encodeComponent(message)}',
    );

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }
}