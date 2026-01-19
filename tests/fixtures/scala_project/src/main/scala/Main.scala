package com.example

object Main {
  def main(args: Array[String]): Unit = {
    println("Hello from Scala!")
    println(s"Sum of 5 and 3: ${add(5, 3)}")
  }

  def add(a: Int, b: Int): Int = {
    a + b
  }
}
