defmodule ArtemisWeb.FuelCalculatorLiveTest do
  use ExUnit.Case, async: true
  import Phoenix.LiveViewTest
  import Phoenix.ConnTest

  # Simple endpoint and router setup for testing
  @endpoint ArtemisWeb.Endpoint

  describe "FuelCalculatorLive" do
    setup do
      conn =
        Phoenix.ConnTest.build_conn()
        |> Plug.Conn.put_private(:phoenix_endpoint, ArtemisWeb.Endpoint)

      {:ok, conn: conn}
    end

    test "renders the main page", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/")

      assert html =~ "Artemis • Interplanetary Fuel Calculator"
      assert html =~ "Spacecraft Configuration"
      assert html =~ "Flight Path Builder"
      assert html =~ "Equipment Mass"
    end

    test "displays default mass in form", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/")

      assert html =~ "28801"
    end

    test "shows empty state when no flight path is set", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/")

      assert html =~ "No flight steps added yet"
      assert html =~ "Add a step above to start planning"
    end

    test "validates mass input correctly", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")

      # Test valid mass
      view
      |> form("#mass-form", calculator: %{mass: "50000"})
      |> render_change()

      refute has_element?(view, ".text-red-400")

      # Test invalid mass (negative)
      view
      |> form("#mass-form", calculator: %{mass: "-1000"})
      |> render_change()

      assert has_element?(view, ".text-red-400", "Mass must be a positive number")

      # Test invalid mass (not a number)
      view
      |> form("#mass-form", calculator: %{mass: "not-a-number"})
      |> render_change()

      assert has_element?(view, ".text-red-400", "Mass must be a valid number")
    end

    test "reproduces step addition with detailed assertions", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")

      view
      |> element("button", "+ Add Step")
      |> render_click()

      # Assert first step is correct
      assert has_element?(view, "*", "Launch from Earth")
      assert has_element?(view, "*", "Step 1")

      view
      |> element("form[phx-change='update_step_form']")
      |> render_change(%{step: %{action: "land"}})

      view
      |> element("form[phx-change='update_step_form']")
      |> render_change(%{step: %{planet: "moon"}})

      view
      |> element("button", "+ Add Step")
      |> render_click()

      # Assert both steps are present and correct
      assert has_element?(view, "*", "Launch from Earth")
      assert has_element?(view, "*", "Step 1")

      assert has_element?(view, "*", "Land on the Moon")
      assert has_element?(view, "*", "Step 2")
    end

    test "adds flight path steps correctly", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")

      # Add a launch step
      view
      |> element("button", "+ Add Step")
      |> render_click()

      assert has_element?(view, "*", "Launch from Earth")
      assert has_element?(view, "*", "Step 1")

      # Add another step
      view
      |> element("form[phx-change='update_step_form']")
      |> render_change(%{step: %{action: "land"}})

      view
      |> element("form[phx-change='update_step_form']")
      |> render_change(%{step: %{planet: "moon"}})

      view
      |> element("button", "+ Add Step")
      |> render_click()

      assert has_element?(view, "*", "Land on the Moon")
      assert has_element?(view, "*", "Step 2")
    end

    test "loads Apollo 11 example mission correctly", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")

      view
      |> element("button[phx-value-example='apollo11']")
      |> render_click()

      # Check mass is set
      assert has_element?(view, "input[value='28801']")

      # Check flight path
      assert has_element?(view, "*", "Launch from Earth")
      assert has_element?(view, "*", "Land on the Moon")
      assert has_element?(view, "*", "Step 4")

      # Check fuel calculation
      assert has_element?(view, "*", "51,898")
    end

    test "loads Mars example mission correctly", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")

      view
      |> element("button[phx-value-example='mars']")
      |> render_click()

      # Check mass is set
      assert has_element?(view, "input[value='14606']")

      # Check flight path includes Mars
      assert has_element?(view, "*", "Land on Mars")
      assert has_element?(view, "*", "Launch from Mars")

      # Check fuel calculation
      assert has_element?(view, "*", "33,388")
    end

    test "loads passenger ship example mission correctly", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")

      view
      |> element("button[phx-value-example='passenger_ship']")
      |> render_click()

      # Check mass is set
      assert has_element?(view, "input[value='75432']")

      # Check it has 6 steps
      assert has_element?(view, "*", "Step 6")

      # Check fuel calculation
      assert has_element?(view, "*", "212,161")
    end

    test "removes individual flight path steps correctly", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")

      # Add multiple steps first
      view
      |> element("button", "+ Add Step")
      |> render_click()

      # Change to land on moon for second step
      view
      |> element("form[phx-change='update_step_form']")
      |> render_change(%{step: %{action: "land", planet: "moon"}})

      view
      |> element("button", "+ Add Step")
      |> render_click()

      # Change to launch from moon for third step
      view
      |> element("form[phx-change='update_step_form']")
      |> render_change(%{step: %{action: "launch", planet: "moon"}})

      view
      |> element("button", "+ Add Step")
      |> render_click()

      # Verify we have 3 steps
      assert has_element?(view, "*", "Step 1")
      assert has_element?(view, "*", "Step 2")
      assert has_element?(view, "*", "Step 3")

      # Remove the middle step (index 1, which is step 2)
      view
      |> element("button[phx-click='remove_step'][phx-value-index='1']")
      |> render_click()

      # Verify we now have 2 steps and step numbers are updated
      assert has_element?(view, "*", "Step 1")
      assert has_element?(view, "*", "Step 2")
      refute has_element?(view, "*", "Step 3")

      # Verify the remaining steps are correct
      assert has_element?(view, "*", "Launch from Earth")
      assert has_element?(view, "*", "Launch from the Moon")
    end

    test "clears all flight path steps", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")

      # Add multiple steps first
      view
      |> element("button", "+ Add Step")
      |> render_click()

      view
      |> element("form[phx-change='update_step_form']")
      |> render_change(%{step: %{action: "land", planet: "moon"}})

      view
      |> element("button", "+ Add Step")
      |> render_click()

      # Verify we have steps
      assert has_element?(view, "*", "Step 1")
      assert has_element?(view, "*", "Step 2")

      # Clear all button should be visible
      assert has_element?(view, "button", "Clear All")

      # Click clear all
      view
      |> element("button[phx-click='clear_path']")
      |> render_click()

      # Verify all steps are removed
      refute has_element?(view, "*", "Step 1")
      refute has_element?(view, "*", "Step 2")

      # Verify empty state is shown
      assert has_element?(view, "*", "No flight steps added yet")

      # Verify fuel is reset to 0
      assert has_element?(view, "*", "0")

      # Clear All button should no longer be visible
      refute has_element?(view, "button", "Clear All")
    end

    test "displays Mars step text correctly", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")

      # Change to Mars and add a step to ensure Mars planet_display_name is covered
      view
      |> element("form[phx-change='update_step_form']")
      |> render_change(%{step: %{planet: "mars"}})

      view
      |> element("button", "+ Add Step")
      |> render_click()

      # Verify Mars step text is displayed correctly
      assert has_element?(view, "*", "Launch from Mars")
    end
  end
end
