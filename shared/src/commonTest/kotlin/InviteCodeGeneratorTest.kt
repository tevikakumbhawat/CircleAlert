import utils.InviteCodeGenerator
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertTrue

class InviteCodeGeneratorTest {

    @Test
    fun testGenerateCodeHasValidLength() {
        val code = InviteCodeGenerator.generate()
        assertEquals(InviteCodeGenerator.CODE_LENGTH, code.length)
    }

    @Test
    fun testGenerateCodeIsValid() {
        for (i in 1..50) {
            val code = InviteCodeGenerator.generate()
            assertTrue(InviteCodeGenerator.isValid(code), "Generated code $code should be valid")
        }
    }

    @Test
    fun testNormalizeTrimsAndUppercases() {
        val raw = " ab-c4-9 "
        val normalized = InviteCodeGenerator.normalize(raw)
        assertEquals("ABC49", normalized)
    }

    @Test
    fun testValidationRejectsInvalidCharacters() {
        // '0' and '1' are excluded to prevent ambiguity
        assertFalse(InviteCodeGenerator.isValid("0ABCDE"))
        assertFalse(InviteCodeGenerator.isValid("1ABCDE"))
        assertFalse(InviteCodeGenerator.isValid("!@#$%^"))
        assertFalse(InviteCodeGenerator.isValid("SHORT"))
        assertFalse(InviteCodeGenerator.isValid("TOOLONGCODE"))
    }
}
