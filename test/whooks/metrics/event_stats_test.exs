defmodule Whooks.Metrics.EventStatsTest do
  use Whooks.DataCase, async: true

  alias Whooks.Metrics.EventStats

  describe "timeseries/1" do
    test "returns time series data with default parameters" do
      assert {:ok, events} = EventStats.timeseries()
      assert is_list(events)
    end

    test "handles string intervals" do
      for interval <- ["minute", "hour", "day"] do
        assert {:ok, events} = EventStats.timeseries(interval: interval)
        assert is_list(events)
      end
    end
  end
end
