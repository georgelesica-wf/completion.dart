library test_dump_render_tree;

import 'dart:io';
import 'package:unittest/unittest.dart';
import 'package:bot/bot_test.dart';

void main() {
  final browserTests = ['test/harness_browser.html'];

  group('DumpRenderTree', () {
    browserTests.forEach((file) {
      test(file, () {
        _runDrt(file);
      });
    });
  });
}

void _runDrt(String htmlFile) {
  final allPassedRegExp = new RegExp('All \\d+ tests passed');

  final future = Process.run('DumpRenderTree', [htmlFile])
      .then((ProcessResult pr) {
        expect(pr.exitCode, 0, reason: 'DumpRenderTree should return exit code 0 - success');

        if(!allPassedRegExp.hasMatch(pr.stdout)) {
          print(pr.stdout);
          fail('Could not find success value in stdout: ${allPassedRegExp.pattern}');
        }
    });

  expect(future, finishes);
}
