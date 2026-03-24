import 'package:hive_flutter/hive_flutter.dart';

class HiveService {
  Future<void> init() async {
    await Hive.initFlutter();
  }

  Future<Box<T>> openBox<T>(String boxName) async {
    return await Hive.openBox<T>(boxName);
  }

  Future<void> closeBox(String boxName) async {
    await Hive.box(boxName).close();
  }

  Future<void> clearAllData() async {
    // Instead of deleting individual boxes, we delete everything 
    // to ensure no stale data remains for a different user.
    await Hive.deleteFromDisk();
    // After deleting from disk, Hive needs to be re-initialized if we want to use it again
    // but usually this happens on a fresh app launch after logout.
    // A safer way for single-session logout is to clear the individual boxes if they are open.
  }
}
