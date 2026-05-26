import 'dart:io';

void main() {
  var file = File('lib/data/local/db_seed.dart');
  var content = file.readAsStringSync();
  print('Product count: ' + 'id:'.allMatches(content).length.toString());
}
