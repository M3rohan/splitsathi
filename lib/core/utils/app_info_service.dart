import 'package:package_info_plus/package_info_plus.dart';

class AppInfoService {
  PackageInfo? _cachedInfo;

  Future<PackageInfo> getPackageInfo() async {
    _cachedInfo ??= await PackageInfo.fromPlatform();
    return _cachedInfo!;
  }

  Future<String> getVersionString() async {
    final info = await getPackageInfo();
    return '${info.version} (${info.buildNumber})';
  }
}
