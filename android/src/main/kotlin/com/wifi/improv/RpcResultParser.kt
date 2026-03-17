package com.wifi.improv

internal class RpcResultParser {
    private val buffer = mutableListOf<Byte>()

    fun reset() {
        buffer.clear()
    }

    fun append(chunk: ByteArray): List<List<String>> {
        if (chunk.isEmpty()) {
            return emptyList()
        }

        buffer.addAll(chunk.toList())
        val packets = mutableListOf<List<String>>()

        while (buffer.size >= 3) {
            val payloadLength = buffer[1].toUByte().toInt()
            val packetLength = payloadLength + 3
            if (buffer.size < packetLength) {
                break
            }

            val packet = ByteArray(packetLength) { index -> buffer[index] }
            repeat(packetLength) {
                buffer.removeAt(0)
            }

            decodePacket(packet)?.let(packets::add)
        }

        return packets
    }

    private fun decodePacket(packet: ByteArray): List<String>? {
        if (packet.size < 3) {
            return null
        }

        val payloadLength = packet[1].toUByte().toInt()
        if (packet.size != payloadLength + 3) {
            return null
        }

        val expectedChecksum = calculateChecksum(packet.copyOf(packet.size - 1))
        val actualChecksum = packet.last().toUByte()
        if (expectedChecksum != actualChecksum) {
            return null
        }

        val strings = mutableListOf<String>()
        var currentIndex = 2
        val payloadEnd = packet.size - 1

        while (currentIndex < payloadEnd) {
            val stringLength = packet[currentIndex].toUByte().toInt()
            currentIndex++
            if (currentIndex + stringLength > payloadEnd) {
                return null
            }

            val string = try {
                packet.decodeToString(
                    startIndex = currentIndex,
                    endIndex = currentIndex + stringLength,
                    throwOnInvalidSequence = true
                )
            } catch (_: Exception) {
                return null
            }

            currentIndex += stringLength
            strings += string
        }

        return strings
    }

    private fun calculateChecksum(data: ByteArray): UByte {
        var checksum = 0.toUByte()
        for (byte in data) {
            checksum = (checksum + byte.toUByte()).toUByte()
        }
        return checksum
    }
}
