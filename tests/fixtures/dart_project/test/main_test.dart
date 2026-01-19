import 'package:test/test.dart';

import '../bin/main.dart';

void main() {
  test('add returns sum of two numbers', () {
    expect(add(5, 3), equals(8));
    expect(add(0, 0), equals(0));
    expect(add(-2, -3), equals(-5));
  });
}
