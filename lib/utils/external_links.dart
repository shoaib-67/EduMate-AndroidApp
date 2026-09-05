import 'package:url_launcher/url_launcher.dart';

const greenEarthUrl = 'https://shoaib-67.github.io/GREEN-EARTH/';

Future<bool> openGreenEarthWebsite() async {
  return openExternalUrl(greenEarthUrl);
}

Future<bool> openExternalUrl(String url) async {
  final uri = Uri.parse(url);
  try {
    if (await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      return true;
    }
    return await launchUrl(uri, mode: LaunchMode.platformDefault);
  } catch (_) {
    return false;
  }
}
