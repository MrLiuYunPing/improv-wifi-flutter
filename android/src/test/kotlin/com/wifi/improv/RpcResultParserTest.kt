package com.wifi.improv

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertTrue

internal class RpcResultParserTest {
    @Test
    fun append_waitsUntilFullPacketArrives() {
        val parser = RpcResultParser()
        val packet = buildPacket("wifi", "http://device.local")

        val firstChunk = packet.copyOfRange(0, 6)
        val secondChunk = packet.copyOfRange(6, packet.size)

        assertTrue(parser.append(firstChunk).isEmpty())
        assertEquals(
            listOf(listOf("wifi", "http://device.local")),
            parser.append(secondChunk)
        )
    }

    @Test
    fun append_decodesMultiplePacketsFromBackToBackChunks() {
        val parser = RpcResultParser()
        val packetA = buildPacket("one")
        val packetB = buildPacket("two", "three")

        val results = parser.append(packetA + packetB)

        assertEquals(
            listOf(listOf("one"), listOf("two", "three")),
            results
        )
    }

    @Test
    fun append_decodesPayloadEvenWhenChecksumDoesNotMatch() {
        val parser = RpcResultParser()
        val packet = buildPacket("bad").also { bytes ->
            bytes[bytes.lastIndex] = (bytes.last() + 1).toByte()
        }

        assertEquals(
            listOf(listOf("bad")),
            parser.append(packet)
        )
    }

    @Test
    fun append_decodesNonWifiCommandPacket() {
        val parser = RpcResultParser()
        val packet = buildPacket("device", command = 0x02)

        assertEquals(
            listOf(listOf("device")),
            parser.append(packet)
        )
    }

    @Test
    fun append_decodesFragmentedUrlPacketEvenWhenChecksumDoesNotMatch() {
        val parser = RpcResultParser()
        val packet = byteArrayOf(
            0x01, 0x16, 0x15, 0x68, 0x74, 0x74, 0x70, 0x3A, 0x2F, 0x2F,
            0x31, 0x39, 0x32, 0x2E, 0x31, 0x36, 0x38, 0x2E, 0x38, 0x37,
            0x2E, 0x31, 0x30, 0x31, 0x01
        )

        assertTrue(parser.append(packet.copyOfRange(0, 20)).isEmpty())
        assertEquals(
            listOf(listOf("http://192.168.87.101")),
            parser.append(packet.copyOfRange(20, packet.size))
        )
    }

    private fun buildPacket(vararg values: String, command: Byte = 0x01): ByteArray {
        val payload = mutableListOf<Byte>()
        values.forEach { value ->
            val encoded = value.encodeToByteArray()
            payload += encoded.size.toByte()
            payload += encoded.toList()
        }

        val packet = mutableListOf<Byte>()
        packet += command
        packet += payload.size.toByte()
        packet += payload

        val checksum = packet.fold(0) { acc, byte ->
            (acc + byte.toUByte().toInt()) and 0xFF
        }.toByte()
        packet += checksum

        return packet.toByteArray()
    }
}
