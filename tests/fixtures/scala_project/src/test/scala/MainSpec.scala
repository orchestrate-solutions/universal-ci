package com.example

import org.scalatest.flatspec.AnyFlatSpec
import org.scalatest.matchers.should.Matchers

class MainSpec extends AnyFlatSpec with Matchers {
  "add" should "return the sum of two numbers" in {
    Main.add(5, 3) shouldEqual 8
    Main.add(0, 0) shouldEqual 0
    Main.add(-2, -3) shouldEqual -5
  }
}
