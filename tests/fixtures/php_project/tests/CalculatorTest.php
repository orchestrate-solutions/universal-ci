<?php

namespace Example\Tests;

use PHPUnit\Framework\TestCase;
use Example\Calculator;

class CalculatorTest extends TestCase
{
    public function testAdd()
    {
        $this->assertEquals(8, Calculator::add(5, 3));
        $this->assertEquals(0, Calculator::add(0, 0));
        $this->assertEquals(-5, Calculator::add(-2, -3));
    }

    public function testMultiply()
    {
        $this->assertEquals(15, Calculator::multiply(5, 3));
        $this->assertEquals(0, Calculator::multiply(5, 0));
    }
}
