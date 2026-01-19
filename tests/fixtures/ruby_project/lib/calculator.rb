module Calculator
  def self.add(a, b)
    a + b
  end

  def self.multiply(a, b)
    a * b
  end
end

if __FILE__ == $0
  puts "Hello from Ruby!"
  puts "5 + 3 = #{Calculator.add(5, 3)}"
  puts "5 * 3 = #{Calculator.multiply(5, 3)}"
end
