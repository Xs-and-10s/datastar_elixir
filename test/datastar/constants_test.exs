defmodule Datastar.ConstantsTest do
  use ExUnit.Case
  alias Datastar.Constants

  describe "event types" do
    test "returns correct event type constants" do
      assert Constants.event_type_patch_elements() == "datastar-patch-elements"
      assert Constants.event_type_patch_signals() == "datastar-patch-signals"
      assert Constants.event_type_execute_script() == "datastar-execute-script"
      assert Constants.event_type_remove_elements() == "datastar-remove-elements"
    end
  end

  describe "patch modes" do
    test "validates patch modes" do
      assert Constants.valid_patch_mode?(:outer)
      assert Constants.valid_patch_mode?(:inner)
      assert Constants.valid_patch_mode?(:append)
      refute Constants.valid_patch_mode?(:invalid)
    end

    test "parses patch mode strings" do
      assert {:ok, :outer} = Constants.parse_patch_mode("outer")
      assert {:ok, :inner} = Constants.parse_patch_mode("inner")
      assert {:error, _} = Constants.parse_patch_mode("invalid")
    end

    test "accepts patch mode atoms" do
      assert {:ok, :outer} = Constants.parse_patch_mode(:outer)
    end
  end

  describe "default values" do
    test "returns correct defaults" do
      assert Constants.default_sse_retry_duration() == 1000
      assert Constants.default_element_patch_mode() == :outer
      assert Constants.default_elements_use_view_transitions() == false
      assert Constants.default_patch_signals_only_if_missing() == false
    end
  end
end
