defmodule Musicman do
end

defmodule Musicman.API do
  use Maru.Router

  params do
    requires :text
  end

  get "/music" do

    [method | values] = String.split(params.text, " ")
    text conn, handle(method, values)

  end

  def make_request(method, params \\ []) do
    body = %{jsonrpc: "2.0", id: 1, method: "core.playback.#{method}", params: params}

    case HTTPoison.post('http://musicbox.local/mopidy/rpc', Poison.encode!(body)) do
      {:ok, response} ->
        Poison.decode!(response.body)["result"]
      {:error, _} ->
        ":wat:"
    end
  end

  def handle("pause", _) do
    make_request("pause")
    "Paused :awthanks:"
  end

  def handle("play", _) do
    make_request("resume")
    handle("track", [])
  end

  def handle("skip", _) do
    make_request("next")
    "Done :awthanks:"
  end

  def handle("volume", []) do
    volume = make_request("get_volume")
    "#{volume}%"
  end

  def handle("volume", [num | _]) do
    {num, _} = Integer.parse(num)
    make_request("set_volume", [num])

    "Done :awthanks:"
  end

  def handle("track", _) do
    track = make_request("get_current_track")
    state = make_request("get_state")

    << _ :: binary-size(1), state :: binary>> = state

    case track do
      nil -> "Nothing playing"
      %{"name" => name, "artists" => artists} ->
        artist =
          artists
          |> Enum.map(fn artist -> artist["name"] end)
          |> Enum.join(", ")
        "P#{state} #{name} - #{artist}"
    end
  end

  def handle(_, _), do: ":wat:"

end
