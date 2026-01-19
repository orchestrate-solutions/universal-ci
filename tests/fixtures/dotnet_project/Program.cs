using System;

class Program
{
    static int Add(int a, int b)
    {
        return a + b;
    }

    static void Main(string[] args)
    {
        Console.WriteLine("Hello from .NET!");
        Console.WriteLine($"Sum of 5 and 3: {Add(5, 3)}");
    }
}
