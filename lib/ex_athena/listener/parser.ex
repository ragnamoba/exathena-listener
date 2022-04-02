defmodule ExAthena.Listener.Parser do
  @moduledoc false

  # alias ExAthena.Listener.Packet

  def parse(router, packet_id, body) do
    case router.__route__(packet_id) do
      {:ok, %{schema: schema}} ->
        parse_struct(schema, packet_id, body)

      _ ->
        {:error, :parse_error}
    end
  end

  defp parse_struct(schema, _, _), do: {:ok, struct!(schema)}
end
