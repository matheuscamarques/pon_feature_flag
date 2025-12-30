defmodule PonFeatureFlagTest do
  use ExUnit.Case
  doctest PonFeatureFlag

  test "greets the world" do
    assert PonFeatureFlag.hello() == :world
  end
end
