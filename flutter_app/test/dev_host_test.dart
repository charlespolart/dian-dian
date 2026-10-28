import 'package:flutter_test/flutter_test.dart';

import 'package:dian_dian/services/dev_host.dart';

void main() {
  // The debug build reaches the Mac that runs `make run`: Android through
  // adb reverse (so its own localhost), an iPhone through the Mac's Bonjour
  // name passed by the Makefile; without the define, localhost as before.
  test('Android keeps localhost whatever the define: adb reverse tunnels the port', () {
    expect(devApiHost(android: true, define: 'Charless-Laptop.local'), 'localhost');
  });

  test('iOS uses the Bonjour name from the define', () {
    expect(devApiHost(android: false, define: 'Charless-Laptop.local'), 'Charless-Laptop.local');
  });

  test('without a define the host is localhost (the simulator, a plain flutter run)', () {
    expect(apiHostDefine, 'localhost');
    expect(devApiHost(android: false), 'localhost');
  });
}
