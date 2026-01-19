require_relative '../lib/calculator'

RSpec.describe Calculator do
  describe '.add' do
    it 'adds two positive numbers' do
      expect(Calculator.add(5, 3)).to eq(8)
    end

    it 'adds zero' do
      expect(Calculator.add(0, 0)).to eq(0)
    end

    it 'adds negative numbers' do
      expect(Calculator.add(-2, -3)).to eq(-5)
    end
  end

  describe '.multiply' do
    it 'multiplies two numbers' do
      expect(Calculator.multiply(5, 3)).to eq(15)
    end

    it 'multiplies by zero' do
      expect(Calculator.multiply(5, 0)).to eq(0)
    end
  end
end
