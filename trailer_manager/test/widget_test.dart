import 'package:flutter_test/flutter_test.dart';

import 'package:trailer_manager/core/constants/app_constants.dart';

void main() {
  test('app constants expose the configured app identity', () {
    expect(AppConstants.appName, 'Trailer Manager');
    expect(AppConstants.supportedImageExtensions, contains('.jpg'));
  });
}
