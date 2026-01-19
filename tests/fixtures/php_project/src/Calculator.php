<?php

namespace Example;

class Calculator
{
    public static function add(int $a, int $b): int
    {
        return $a + $b;
    }

    public static function multiply(int $a, int $b): int
    {
        return $a * $b;
    }
}

// For command line execution
if ($argv[0] === __FILE__) {
    echo "Hello from PHP!\n";
    echo "5 + 3 = " . Calculator::add(5, 3) . "\n";
    echo "5 * 3 = " . Calculator::multiply(5, 3) . "\n";
}
