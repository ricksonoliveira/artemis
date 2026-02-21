defmodule Artemis.DataCase do
  @moduledoc """
  This module defines the setup for tests requiring
  data layer interactions.

  Database disabled for fuel calculator challenge.
  """

  use ExUnit.CaseTemplate

  using do
    quote do
      # No database imports needed for this challenge
    end
  end

  setup _tags do
    # No database setup needed
    :ok
  end

  def setup_sandbox(_tags) do
    # No database setup needed
    :ok
  end
end
