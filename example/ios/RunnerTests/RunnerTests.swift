import XCTest

@testable import improv_wifi_flutter

class RunnerTests: XCTestCase {
  func testAppendWaitsUntilFullPacketArrives() {
    let parser = RpcResultParser()
    let packet = buildPacket(["wifi", "http://device.local"])

    let firstChunk = packet.prefix(6)
    let secondChunk = packet.dropFirst(6)

    XCTAssertTrue(parser.append(Data(firstChunk)).isEmpty)
    XCTAssertEqual(
      parser.append(Data(secondChunk)),
      [["wifi", "http://device.local"]]
    )
  }

  func testZAppendDecodesMultiplePacketsFromBackToBackChunks() {
    let parser = RpcResultParser()
    let packetA = buildPacket(["one"])
    let packetB = buildPacket(["two", "three"])

    XCTAssertEqual(
      parser.append(packetA + packetB),
      [["one"], ["two", "three"]]
    )
  }

  func testAppendDropsInvalidChecksumPacket() {
    let parser = RpcResultParser()
    var packet = buildPacket(["bad"])
    packet[packet.count - 1] = packet[packet.count - 1] &+ 1

    XCTAssertTrue(parser.append(packet).isEmpty)
  }

  func testAppendDecodesNonWifiCommandPacket() {
    let parser = RpcResultParser()
    let packet = buildPacket(["device"], command: 2)

    XCTAssertEqual(
      parser.append(packet),
      [["device"]]
    )
  }

  func testAppendDecodesFragmentedUrlPacketEvenWhenChecksumDoesNotMatch() {
    let parser = RpcResultParser()
    let packet = Data([
      0x01, 0x16, 0x15, 0x68, 0x74, 0x74, 0x70, 0x3A, 0x2F, 0x2F,
      0x31, 0x39, 0x32, 0x2E, 0x31, 0x36, 0x38, 0x2E, 0x38, 0x37,
      0x2E, 0x31, 0x30, 0x31, 0x01,
    ])

    XCTAssertTrue(parser.append(packet.prefix(20)).isEmpty)
    XCTAssertEqual(
      parser.append(packet.dropFirst(20)),
      [["http://192.168.87.101"]]
    )
  }

  private func buildPacket(_ values: [String], command: UInt8 = 1) -> Data {
    var payload: [UInt8] = []
    for value in values {
      let encoded = Array(value.utf8)
      payload.append(UInt8(encoded.count))
      payload.append(contentsOf: encoded)
    }

    var packet: [UInt8] = [command, UInt8(payload.count)]
    packet.append(contentsOf: payload)

    let checksum = packet.reduce(0 as UInt8) { partialResult, byte in
      (partialResult &+ byte) & 255
    }
    packet.append(checksum)
    return Data(packet)
  }
}
