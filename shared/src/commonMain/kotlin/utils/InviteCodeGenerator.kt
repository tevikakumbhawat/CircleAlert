package utils

import kotlin.random.Random

object InviteCodeGenerator {
    // Exclude confusing characters: 0/O, 1/I, etc.
    private const val ALPHABET = "23456789ABCDEFGHJKLMNPQRSTUVWXYZ"
    const val CODE_LENGTH = 6

    fun generate(): String {
        return (1..CODE_LENGTH)
            .map { ALPHABET[Random.nextInt(ALPHABET.length)] }
            .joinToString("")
    }

    fun normalize(code: String): String {
        return code.trim().uppercase().replace("-", "").replace(" ", "")
    }

    fun isValid(code: String): Boolean {
        val normalized = normalize(code)
        if (normalized.length != CODE_LENGTH) return false
        return normalized.all { it in ALPHABET }
    }
}
