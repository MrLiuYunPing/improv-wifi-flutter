import 'package:flutter_test/flutter_test.dart';

void main() {
  test('builds fragmented packet fixtures consistent with checksum rules', () {
    final packet = _buildPacket(['wifi', 'http://device.local']);

    expect(packet.length, greaterThan(3));
    expect(packet[1], packet.length - 3);

    final checksum = packet
        .sublist(0, packet.length - 1)
        .fold<int>(0, (sum, byte) => (sum + byte) & 0xFF);
    expect(packet.last, checksum);
  });
}

List<int> _buildPacket(List<String> values) {
  final payload = <int>[];
  for (final value in values) {
    final encoded = value.codeUnits;
    payload.add(encoded.length);
    payload.addAll(encoded);
  }

  final packet = <int>[1, payload.length, ...payload];
  final checksum = packet.fold<int>(0, (sum, byte) => (sum + byte) & 0xFF);
  packet.add(checksum);
  return packet;
}
