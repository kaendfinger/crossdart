library crossdart;

import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:crossdart/src/config.dart';
import 'package:crossdart/src/parsed_data.dart';
import 'package:crossdart/src/parser.dart';
import 'package:crossdart/src/package.dart';
import 'package:crossdart/src/entity.dart';

import 'package:crossdart/src/installer/installer.dart';
import 'package:crossdart/src/html_generator.dart';

void install(String packageName) {
  assert(config != null);
  new Installer(packageName).install();
}

ParsedData parse(Package package) {
  var handledFiles = new Set();


  return package.files.map((f) => f.path).fold(new ParsedData(), (memo, file) {
    var parsedData = parseFile(file, package);

    print(parsedData.files.keys.toList());
    while (parsedData.files.keys.toSet().difference(handledFiles).isNotEmpty) {
      var unhandledFiles = parsedData.files.keys.toSet().difference(handledFiles);
      unhandledFiles.forEach((file) {
        handledFiles.add(file);
        var package = packages.firstWhere((p) => p.doesContainFile(file));
        print("Contains package $package");
        parsedData = parsedData.merge(parseFile(file, package));
      });
    }

    return memo.merge(parsedData);
  });

}

void generateHtml(Package package, ParsedData parsedData) {
  new HtmlGenerator(package, parsedData).generate();
}