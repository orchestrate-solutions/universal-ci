import kotlin.test.Test
import kotlin.test.assertEquals

class MainTest {
    @Test
    fun testAdd() {
        assertEquals(8, add(5, 3))
        assertEquals(0, add(0, 0))
        assertEquals(-5, add(-2, -3))
    }
}
