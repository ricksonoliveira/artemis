defmodule ArtemisWeb.FuelCalculatorLive do
  use ArtemisWeb, :live_view

  alias Artemis.FuelCalculator

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:form, to_form(%{"mass" => "28801"}, as: :calculator))
      |> assign(:mass, 28801)
      |> assign(:flight_path, [])
      |> assign(:total_fuel, 0)
      |> assign(:errors, %{})
      |> assign(:step_action, :launch)
      |> assign(:step_planet, :earth)

    {:ok, socket}
  end

  @impl true
  def handle_event("validate_mass", %{"calculator" => %{"mass" => mass_str}}, socket) do
    case parse_mass(mass_str) do
      {:ok, mass} ->
        socket =
          socket
          |> assign(:mass, mass)
          |> assign(:form, to_form(%{"mass" => mass_str}, as: :calculator))
          |> assign(:errors, Map.delete(socket.assigns.errors, :mass))
          |> calculate_total_fuel()

        {:noreply, socket}

      {:error, error} ->
        socket =
          socket
          |> assign(:form, to_form(%{"mass" => mass_str}, as: :calculator))
          |> assign(:errors, Map.put(socket.assigns.errors, :mass, error))

        {:noreply, socket}
    end
  end

  @impl true
  def handle_event("add_step", _params, socket) do
    %{step_action: action, step_planet: planet, flight_path: path} = socket.assigns

    new_step = {action, planet}
    updated_path = path ++ [new_step]

    socket =
      socket
      |> assign(:flight_path, updated_path)
      |> calculate_total_fuel()

    {:noreply, socket}
  end

  @impl true
  def handle_event("remove_step", %{"index" => index_str}, socket) do
    index = String.to_integer(index_str)
    updated_path = List.delete_at(socket.assigns.flight_path, index)

    socket =
      socket
      |> assign(:flight_path, updated_path)
      |> calculate_total_fuel()

    {:noreply, socket}
  end

  @impl true
  def handle_event("update_step_form", %{"step" => step_params}, socket) do
    socket =
      socket
      |> maybe_update_step_action(step_params)
      |> maybe_update_step_planet(step_params)

    {:noreply, socket}
  end

  @impl true
  def handle_event("clear_path", _params, socket) do
    socket =
      socket
      |> assign(:flight_path, [])
      |> assign(:total_fuel, 0)

    {:noreply, socket}
  end

  @impl true
  def handle_event("load_example", %{"example" => example}, socket) do
    {mass, path} = get_example_mission(example)

    socket =
      socket
      |> assign(:mass, mass)
      |> assign(:form, to_form(%{"mass" => Integer.to_string(mass)}, as: :calculator))
      |> assign(:flight_path, path)
      |> assign(:errors, %{})
      |> calculate_total_fuel()

    {:noreply, socket}
  end

  defp maybe_update_step_action(socket, %{"action" => action_str}) do
    action = String.to_existing_atom(action_str)
    assign(socket, :step_action, action)
  end

  defp maybe_update_step_planet(socket, %{"planet" => planet_str}) do
    planet = String.to_existing_atom(planet_str)
    assign(socket, :step_planet, planet)
  end

  # Private functions

  defp parse_mass(mass_str) do
    case Integer.parse(mass_str) do
      {mass, ""} when mass > 0 ->
        {:ok, mass}

      {_mass, ""} ->
        {:error, "Mass must be a positive number"}

      _ ->
        {:error, "Mass must be a valid number"}
    end
  end

  defp calculate_total_fuel(socket) do
    %{mass: mass, flight_path: path} = socket.assigns

    total_fuel =
      if mass > 0 and path != [] do
        FuelCalculator.total_fuel(mass, path)
      else
        0
      end

    assign(socket, :total_fuel, total_fuel)
  end

  defp get_example_mission("apollo11") do
    mass = 28801
    path = [{:launch, :earth}, {:land, :moon}, {:launch, :moon}, {:land, :earth}]
    {mass, path}
  end

  defp get_example_mission("mars") do
    mass = 14606
    path = [{:launch, :earth}, {:land, :mars}, {:launch, :mars}, {:land, :earth}]
    {mass, path}
  end

  defp get_example_mission("passenger_ship") do
    mass = 75432

    path = [
      {:launch, :earth},
      {:land, :moon},
      {:launch, :moon},
      {:land, :mars},
      {:launch, :mars},
      {:land, :earth}
    ]

    {mass, path}
  end

  defp format_number(number) when is_integer(number) do
    number
    |> Integer.to_string()
    |> String.reverse()
    |> String.replace(~r/.{3}(?=.)/, "\\0,")
    |> String.reverse()
  end

  defp step_display_text(:launch, :moon) do
    "Launch from the Moon"
  end

  defp step_display_text(:launch, planet) do
    "Launch from #{planet_display_name(planet)}"
  end

  defp step_display_text(:land, :moon) do
    "Land on the #{planet_display_name(:moon)}"
  end

  defp step_display_text(:land, planet) do
    "Land on #{planet_display_name(planet)}"
  end

  defp planet_display_name(:earth), do: "Earth"
  defp planet_display_name(:moon), do: "Moon"
  defp planet_display_name(:mars), do: "Mars"

  defp planet_emoji(:earth), do: "🌍"
  defp planet_emoji(:moon), do: "🌙"
  defp planet_emoji(:mars), do: "🔴"

  defp action_emoji(:launch), do: "🚀"
  defp action_emoji(:land), do: "🛬"
end
