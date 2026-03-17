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
    fun append_dropsInvalidChecksumPacket() {
        val parser = RpcResultParser()
        val packet = buildPacket("bad").also { bytes ->
            bytes[bytes.lastIndex] = (bytes.last() + 1).toByte()
        }

        assertTrue(parser.append(packet).isEmpty())
    }

    private fun buildPacket(vararg values: String): ByteArray {
        val payload = mutableListOf<Byte>()
        values.forEach { value ->
            val encoded = value.encodeToByteArray()
            payload += encoded.size.toByte()
            payload += encoded.toList()
        }

        val packet = mutableListOf<Byte>()
        packet += 0x01
        packet += payload.size.toByte()
        packet += payload

        val checksum = packet.fold(0) { acc, byte ->
            (acc + byte.toUByte().toInt()) and 0xFF
        }.toByte()
        packet += checksum

        return packet.toByteArray()
    }
}
