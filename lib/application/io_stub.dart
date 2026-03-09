/// Stub for dart:io on web platform
class File {
  final String path;
  File(this.path);
  
  Future<String> readAsString() async => '';
  Future<void> writeAsString(String content) async {}
}

class Directory {
  final String path;
  Directory(this.path);
}
