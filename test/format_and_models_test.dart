import 'package:aebello/api/models.dart';
import 'package:aebello/format.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('money formats cents as dollars', () {
    expect(money(399), r'$3.99');
    expect(money(2549), r'$25.49');
    expect(money(819000, 'NGN'), '₦8,190');
  });

  test('bytes picks GB or MB', () {
    expect(bytes(5 << 30), '5 GB');
    expect(bytes(1610612736), '1.5 GB');
    expect(bytes(500 << 20), '500 MB');
  });

  test('Esim parses the API shape and splits the activation code', () {
    final e = Esim.fromJson({
      'id': 'e1',
      'planName': 'Nigeria 5GB 30Days',
      'countryCode': 'NG',
      'iccid': '894310',
      'activationCode': r'LPA:1$rsp-eu.redteamobile.com$43DE23C6',
      'qrCodeUrl': 'https://p.qrsim.net/x.png',
      'status': 'active',
      'totalBytes': 5 << 30,
      'usedBytes': 2 << 30,
      'expiresAt': '2026-10-24T20:00:00Z',
      'syncedAt': '2026-09-27T20:00:00Z',
      'createdAt': '2026-09-24T20:00:00Z',
    });
    expect(e.usable, isTrue);
    expect(e.leftBytes, 3 << 30);
    expect(e.manualCodes.smdp, 'rsp-eu.redteamobile.com');
    expect(e.manualCodes.matchingId, '43DE23C6');
  });
}
