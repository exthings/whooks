defmodule Whooks.Metrics.Utils do
  @minute 60
  @hour 3600
  @day 86400

  def interval_to_duration(last) do
    case last do
      "1m" -> Duration.new!(second: 1)
      "1h" -> Duration.new!(minute: 1)
      "6h" -> Duration.new!(minute: 10)
      "12h" -> Duration.new!(minute: 30)
      "24h" -> Duration.new!(minute: 30)
      "48h" -> Duration.new!(minute: 30)
      "1d" -> Duration.new!(hour: 1)
      "1w" -> Duration.new!(hour: 1)
      "1mo" -> Duration.new!(day: 1)
      "1y" -> Duration.new!(month: 1)
      _ -> Duration.new!(hour: 1)
    end
  end

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
