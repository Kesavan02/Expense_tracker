// ignore_for_file: avoid_print

import 'dart:io';

void main(List<String> args) async {
  String? package;
  String? target;

  for (final arg in args) {
    if (arg.startsWith('--package=')) {
      package = arg.split('=')[1];
    } else if (arg.startsWith('--target=')) {
      target = arg.split('=')[1];
    }
  }

  if (package == null || package.isEmpty) {
    print('Please provide a package name: --package=<name>');
    exit(1);
  }
  if (target == null || target.isEmpty) {
    print('Please provide a target: --target=<name> or --target=all');
    exit(1);
  }

  final List<Directory> targetDirs = [];
  final root = Directory.current;

  void searchDirs(Directory currentDir) {
    for (final entity in currentDir.listSync()) {
      if (entity is Directory) {
        final folderName = entity.path.split(Platform.pathSeparator).last;
        // Ignore hidden, build, and platform directories
        if (folderName.startsWith('.') ||
            folderName == 'build' ||
            folderName == 'windows' ||
            folderName == 'macos' ||
            folderName == 'linux' ||
            folderName == 'ios' ||
            folderName == 'android') {
          continue;
        }

        final pubspec =
            File('${entity.path}${Platform.pathSeparator}pubspec.yaml');
        if (pubspec.existsSync()) {
          final content = pubspec.readAsStringSync();
          final nameMatch =
              RegExp(r'^name:\s*(.+)$', multiLine: true).firstMatch(content);
          if (nameMatch != null) {
            // Clean quotes if any
            final pkgName = nameMatch
                .group(1)!
                .replaceAll('"', '')
                .replaceAll("'", '')
                .trim();
            // Get relative path for flexible targeting (e.g. "core/data")
            final relativePath = entity.path
                .replaceFirst(root.path + Platform.pathSeparator, '')
                .replaceAll(r'\', '/');

            if (target == 'all' ||
                target == pkgName ||
                target == folderName ||
                target == relativePath) {
              if (!targetDirs.any((d) => d.path == entity.path)) {
                targetDirs.add(entity);
              }
            }
          }
        } else {
          searchDirs(entity);
        }
      }
    }
  }

  searchDirs(root);

  if (targetDirs.isEmpty) {
    print('No targets found for "$target".');
    exit(1);
  }

  for (final dir in targetDirs) {
    print('\nAdding package "$package" to ${dir.path}...');
    final result = await Process.run(
      'flutter',
      ['pub', 'add', package],
      workingDirectory: dir.path,
      runInShell: true,
    );
    if (result.exitCode != 0) {
      print('Error adding to ${dir.path}:');
      print(result.stderr);
    } else {
      print('Successfully added to ${dir.path}.');
      print(result.stdout);
    }
  }
}
