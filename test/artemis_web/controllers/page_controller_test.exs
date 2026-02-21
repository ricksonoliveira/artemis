defmodule ArtemisWeb.PageControllerTest do
  use ArtemisWeb.ConnCase

  test "GET /about (old Phoenix landing page)", %{conn: conn} do
    conn = get(conn, ~p"/about")
    assert html_response(conn, 200) =~ "Peace of mind from prototype to production"
  end
end
