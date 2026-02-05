defmodule Whooks.TimeParser do
  @minute 60
  @hour 3600
  @day 86400

  require Logger

  def parse_last_to_seconds(interval) do
    case Regex.run(~r/^(\d+)(m|h|d|mo|y|w)$/, interval) do
      [_, value, "m"] -> String.to_integer(value) * @minute
      [_, value, "h"] -> String.to_integer(value) * @hour
      [_, value, "d"] -> String.to_integer(value) * @day
      [_, value, "mo"] -> String.to_integer(value) * (@day * 30)
      [_, value, "y"] -> String.to_integer(value) * (@day * 365)
      [_, value, "w"] -> String.to_integer(value) * (@day * 7)
      _ -> @day
    end
  end

  def parse_last_to_date_time(interval) do
    DateTime.add(DateTime.utc_now(), -parse_last_to_seconds(interval), :second)
  end
end
