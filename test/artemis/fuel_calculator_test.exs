defmodule Artemis.FuelCalculatorTest do
  use ExUnit.Case, async: true

  alias Artemis.FuelCalculator

  describe "gravity/1" do
    test "returns correct gravity for Earth" do
      assert FuelCalculator.gravity(:earth) == 9.807
    end

    test "returns correct gravity for Moon" do
      assert FuelCalculator.gravity(:moon) == 1.62
    end

    test "returns correct gravity for Mars" do
      assert FuelCalculator.gravity(:mars) == 3.711
    end
  end

  describe "planets/0" do
    test "returns list of supported planets" do
      assert FuelCalculator.planets() == [:earth, :moon, :mars]
    end
  end

  describe "base_fuel/3" do
    test "calculates launch fuel correctly" do
      # Apollo 11 CSM launch from Earth example
      # 28801 * 9.807 * 0.042 - 33 = 11829.95... -> floor = 11829
      assert FuelCalculator.base_fuel(:launch, 28801, 9.807) == 11829
    end

    test "calculates landing fuel correctly" do
      # Apollo 11 CSM landing on Earth example
      assert FuelCalculator.base_fuel(:land, 28801, 9.807) == 9278
    end

    test "returns 0 for negative fuel calculations" do
      assert FuelCalculator.base_fuel(:launch, 10, 1.0) == 0
      assert FuelCalculator.base_fuel(:land, 10, 1.0) == 0
    end

    test "returns 0 for zero or very small masses" do
      assert FuelCalculator.base_fuel(:launch, 0, 9.807) == 0
      assert FuelCalculator.base_fuel(:land, 0, 9.807) == 0
    end
  end

  describe "fuel_for_step/3" do
    test "calculates total fuel for Apollo 11 CSM landing on Earth" do
      # Expected result from manual calculation
      assert FuelCalculator.fuel_for_step(:land, 28801, 9.807) == 13447
    end

    test "handles recursive fuel calculation" do
      # Test with a simple case where we can verify the recursion
      mass = 1000
      gravity = 9.807

      base = FuelCalculator.base_fuel(:launch, mass, gravity)
      total = FuelCalculator.fuel_for_step(:launch, mass, gravity)

      # Total should be greater than base due to fuel-for-fuel
      assert total > base
    end

    test "returns 0 when base fuel is 0" do
      assert FuelCalculator.fuel_for_step(:launch, 10, 1.0) == 0
    end
  end

  describe "total_fuel/2" do
    test "calculates correct fuel for Apollo 11 mission" do
      path = [{:launch, :earth}, {:land, :moon}, {:launch, :moon}, {:land, :earth}]
      mass = 28801

      assert FuelCalculator.total_fuel(mass, path) == 51898
    end

    test "calculates correct fuel for Mars mission" do
      path = [{:launch, :earth}, {:land, :mars}, {:launch, :mars}, {:land, :earth}]
      mass = 14606

      assert FuelCalculator.total_fuel(mass, path) == 33388
    end

    test "calculates correct fuel for passenger ship mission" do
      path = [
        {:launch, :earth},
        {:land, :moon},
        {:launch, :moon},
        {:land, :mars},
        {:launch, :mars},
        {:land, :earth}
      ]

      mass = 75432

      assert FuelCalculator.total_fuel(mass, path) == 212_161
    end

    test "returns 0 for empty flight path" do
      assert FuelCalculator.total_fuel(1000, []) == 0
    end

    test "returns 0 for empty flight path with any mass" do
      # This should definitively cover the total_fuel(_mass, []) clause on line 129
      assert FuelCalculator.total_fuel(28801, []) == 0
      assert FuelCalculator.total_fuel(100_000, []) == 0
      assert FuelCalculator.total_fuel(1, []) == 0
    end

    test "returns 0 for empty flight path with invalid mass" do
      # This covers the second total_fuel clause: def total_fuel(_mass, []), do: 0
      # The first clause guard fails when mass <= 0, so second clause is called
      assert FuelCalculator.total_fuel(0, []) == 0
      assert FuelCalculator.total_fuel(-100, []) == 0
    end

    test "handles single step correctly" do
      path = [{:launch, :earth}]
      mass = 1000

      single_step_fuel = FuelCalculator.fuel_for_step(:launch, mass, 9.807)
      total_fuel = FuelCalculator.total_fuel(mass, path)

      assert total_fuel == single_step_fuel
    end

    test "processes steps in reverse order correctly" do
      # Two different paths that should give different results
      path1 = [{:launch, :earth}, {:land, :moon}]
      path2 = [{:land, :moon}, {:launch, :earth}]
      mass = 1000

      fuel1 = FuelCalculator.total_fuel(mass, path1)
      fuel2 = FuelCalculator.total_fuel(mass, path2)

      # Results should be different due to order dependency
      assert fuel1 != fuel2
    end

    test "handles different planet combinations" do
      # Test with all three planets
      path = [{:launch, :earth}, {:land, :mars}, {:launch, :mars}, {:land, :moon}]
      mass = 5000

      result = FuelCalculator.total_fuel(mass, path)
      assert is_integer(result)
      assert result > 0
    end
  end

  describe "edge cases and validation" do
    test "base_fuel works with different gravity values" do
      mass = 1000

      # Earth gravity
      earth_fuel = FuelCalculator.base_fuel(:launch, mass, 9.807)

      # Moon gravity (much lower)
      moon_fuel = FuelCalculator.base_fuel(:launch, mass, 1.62)

      # Earth should require more fuel due to higher gravity
      assert earth_fuel > moon_fuel
    end

    test "fuel calculations are deterministic" do
      path = [{:launch, :earth}, {:land, :mars}]
      mass = 10000

      result1 = FuelCalculator.total_fuel(mass, path)
      result2 = FuelCalculator.total_fuel(mass, path)

      assert result1 == result2
    end

    test "larger masses require proportionally more fuel" do
      path = [{:launch, :earth}]

      small_mass = 1000
      large_mass = 10000

      small_fuel = FuelCalculator.total_fuel(small_mass, path)
      large_fuel = FuelCalculator.total_fuel(large_mass, path)

      # Larger mass should require significantly more fuel
      # (though not necessarily 10x due to the recursive nature)
      assert large_fuel > small_fuel * 5
    end
  end
end
