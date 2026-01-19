package com.example;

import static org.junit.Assert.assertEquals;
import org.junit.Test;

public class MainTest {
    @Test
    public void testAdd() {
        assertEquals(8, Main.add(5, 3));
        assertEquals(0, Main.add(0, 0));
        assertEquals(-5, Main.add(-2, -3));
    }
}
