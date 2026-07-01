import 'package:flutter/services.dart';

class PatternAssetLoader {
  PatternAssetLoader({Iterable<String> initialAssets = const []}) {
    for (final asset in initialAssets) {
      register(asset);
    }
  }

  final Set<String> _cache = {};
  final Set<String> _failed = {};

  bool register(String assetPath) {
    if (assetPath.trim().isEmpty) {
      return false;
    }
    _cache.add(assetPath);
    return true;
  }

  bool isCached(String assetPath) => _cache.contains(assetPath);

  bool hasFailed(String assetPath) => _failed.contains(assetPath);

  Future<bool> preload(String assetPath, {AssetBundle? bundle}) async {
    if (_cache.contains(assetPath)) {
      return true;
    }
    if (!register(assetPath)) {
      _failed.add(assetPath);
      return false;
    }
    try {
      await (bundle ?? rootBundle).load(assetPath);
      return true;
    } catch (_) {
      _cache.remove(assetPath);
      _failed.add(assetPath);
      return false;
    }
  }

  List<String> get cachedAssets => _cache.toList(growable: false)..sort();

  List<String> get failedAssets => _failed.toList(growable: false)..sort();
}
