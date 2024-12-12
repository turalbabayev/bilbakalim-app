import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io';

Future<String?> fetchDeviceID() async {
  final deviceInfo = DeviceInfoPlugin();
  try {
    if (Platform.isAndroid) {
      final androidInfo = await deviceInfo.androidInfo;
      print(androidInfo.id);
      return androidInfo.id; // Android cihazlar için benzersiz ID
    } else if (Platform.isIOS) {
      final iosInfo = await deviceInfo.iosInfo;
      return iosInfo.identifierForVendor; // iOS cihazlar için benzersiz ID
    }
  } catch (e) {
    throw "Cihaz kimliği alınırken hata oluştu : $e";
  }

  return null; // Diğer platformlar için
}
