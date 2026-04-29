import 'package:flutter_test/flutter_test.dart';

import 'package:biznest_shop/main.dart';

void main() {
  test('shop app widget can be instantiated', () {
    expect(() => const BizNestShopApp(), returnsNormally);
  });
}
