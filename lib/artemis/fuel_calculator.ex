defmodule Artemis.FuelCalculator do
  @moduledoc """
  Calculates the fuel required for an interplanetary space mission.

  The calculator accounts for the recursive nature of fuel requirements:
  carrying fuel adds mass, which requires additional fuel, and so on.

  ## Formulas

  - **Launch**: `floor(mass × gravity × 0.042 − 33)`
  - **Landing**: `floor(mass × gravity × 0.033 − 42)`

  ## Planet Gravities

  - Earth: 9.807 m/s²
  - Moon: 1.62 m/s²
  - Mars: 3.711 m/s²
  """

  @type action :: :launch | :land
  @type planet :: :earth | :moon | :mars
  @type step :: {action(), planet()}

  @gravities %{
    earth: 9.807,
    moon: 1.62,
    mars: 3.711
  }

  @doc """
  Returns the gravity value for a given planet.

  ## Examples

      iex> Artemis.FuelCalculator.gravity(:earth)
      9.807

      iex> Artemis.FuelCalculator.gravity(:mars)
      3.711
  """
  @spec gravity(planet()) :: float()
  def gravity(planet) when is_map_key(@gravities, planet) do
    Map.fetch!(@gravities, planet)
  end

  @doc """
  Returns the list of supported planets.
  """
  @spec planets() :: [planet()]
  def planets, do: [:earth, :moon, :mars]

  @doc """
  Calculates the base fuel for a single action (before recursive fuel-for-fuel).

  Returns 0 if the calculated value is zero or negative.

  ## Examples

      iex> Artemis.FuelCalculator.base_fuel(:launch, 28801, 9.807)
      11858
  """
  @spec base_fuel(action(), number(), float()) :: non_neg_integer()
  def base_fuel(:launch, mass, gravity) do
    result = floor(mass * gravity * 0.042 - 33)
    max(result, 0)
  end

  def base_fuel(:land, mass, gravity) do
    result = floor(mass * gravity * 0.033 - 42)
    max(result, 0)
  end

  @doc """
  Calculates the total fuel for a single step, including the recursive
  fuel-for-fuel requirement.

  Each unit of fuel has mass that itself requires fuel to carry, calculated
  using the same formula. This recurses until the additional fuel needed is
  zero or negative.

  ## Examples

      iex> Artemis.FuelCalculator.fuel_for_step(:launch, 28801, 9.807)
      13447
  """
  @spec fuel_for_step(action(), number(), float()) :: non_neg_integer()
  def fuel_for_step(action, mass, gravity) do
    fuel = base_fuel(action, mass, gravity)
    if fuel <= 0, do: 0, else: fuel + fuel_for_fuel(action, fuel, gravity)
  end

  defp fuel_for_fuel(action, fuel_mass, gravity) do
    additional = base_fuel(action, fuel_mass, gravity)
    if additional <= 0, do: 0, else: additional + fuel_for_fuel(action, additional, gravity)
  end

  @doc """
  Calculates the total fuel required for an entire mission.

  The flight path is processed in **reverse order**. Each step's fuel
  requirement is based on the equipment mass plus the fuel needed for
  all subsequent steps (which must be carried through earlier steps).

  ## Parameters

  - `mass` - the equipment mass in kg (positive number)
  - `flight_path` - list of `{action, planet}` tuples in chronological order

  ## Examples

      iex> path = [{:launch, :earth}, {:land, :moon}, {:launch, :moon}, {:land, :earth}]
      iex> Artemis.FuelCalculator.total_fuel(28801, path)
      51898

      iex> path = [{:launch, :earth}, {:land, :mars}, {:launch, :mars}, {:land, :earth}]
      iex> Artemis.FuelCalculator.total_fuel(14606, path)
      33388
  """
  @spec total_fuel(number(), [step()]) :: non_neg_integer()
  def total_fuel(mass, flight_path) when is_number(mass) and mass > 0 and is_list(flight_path) do
    flight_path
    |> Enum.reverse()
    |> Enum.reduce(0, fn {action, planet}, accumulated_fuel ->
      gravity = gravity(planet)
      step_fuel = fuel_for_step(action, mass + accumulated_fuel, gravity)
      accumulated_fuel + step_fuel
    end)
  end

  def total_fuel(_mass, []), do: 0
end
