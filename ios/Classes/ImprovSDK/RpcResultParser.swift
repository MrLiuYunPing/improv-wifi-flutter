import Foundation

final class RpcResultParser {
    private var buffer: [UInt8] = []

    func reset() {
        buffer.removeAll()
    }

    func append(_ chunk: Data) -> [[String]] {
        guard !chunk.isEmpty else { return [] }

        buffer.append(contentsOf: chunk)
        var packets: [[String]] = []

        while buffer.count >= 3 {
            let payloadLength = Int(buffer[1])
            let packetLength = payloadLength + 3
            guard buffer.count >= packetLength else {
                break
            }

            let packet = Array(buffer.prefix(packetLength))
            buffer.removeFirst(packetLength)

            if let decoded = decodePacket(packet) {
                packets.append(decoded)
            }
        }

        return packets
    }

    private func decodePacket(_ packet: [UInt8]) -> [String]? {
        guard packet.count >= 3 else { return nil }

        let payloadLength = Int(packet[1])
        guard packet.count == payloadLength + 3 else { return nil }

        let body = Array(packet.dropLast())
        let expectedChecksum = calculateChecksum(body)
        let actualChecksum = packet[packet.count - 1]
        guard expectedChecksum == actualChecksum else { return nil }

        var strings: [String] = []
        var currentIndex = 2
        let payloadEnd = packet.count - 1

        while currentIndex < payloadEnd {
            let stringLength = Int(packet[currentIndex])
            currentIndex += 1

            guard currentIndex + stringLength <= payloadEnd else { return nil }
            let data = Data(packet[currentIndex..<(currentIndex + stringLength)])
            currentIndex += stringLength

            guard let string = String(data: data, encoding: .utf8) else { return nil }
            strings.append(string)
        }

        return strings
    }

    private func calculateChecksum(_ data: [UInt8]) -> UInt8 {
        var checksum: UInt8 = 0
        for byte in data {
            checksum = (checksum &+ byte) & 255
        }
        return checksum
    }
}
