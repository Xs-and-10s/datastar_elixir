defmodule Datastar.Constants do
  @moduledoc """
  Constants used throughout the Datastar SDK.
  """

  # Event types
  @event_type_patch_elements "datastar-patch-elements"
  @event_type_patch_signals "datastar-patch-signals"
  @event_type_execute_script "datastar-execute-script"
  @event_type_remove_elements "datastar-remove-elements"

  # Dataline literals
  @selector_dataline "selector "
  @mode_dataline "mode "
  @elements_dataline "elements "
  @use_view_transition_dataline "useViewTransition "
  @signals_dataline "signals "
  @only_if_missing_dataline "onlyIfMissing "
  @script_dataline "script "

  # Default values
  @default_sse_retry_duration 1000
  @default_elements_use_view_transitions false
  @default_patch_signals_only_if_missing false
  @default_element_patch_mode :outer

  # Element patch modes
  @element_patch_modes ~w(outer inner remove replace prepend append before after)a

  def event_type_patch_elements, do: @event_type_patch_elements
  def event_type_patch_signals, do: @event_type_patch_signals
  def event_type_execute_script, do: @event_type_execute_script
  def event_type_remove_elements, do: @event_type_remove_elements

  def selector_dataline, do: @selector_dataline
  def mode_dataline, do: @mode_dataline
  def elements_dataline, do: @elements_dataline
  def use_view_transition_dataline, do: @use_view_transition_dataline
  def signals_dataline, do: @signals_dataline
  def only_if_missing_dataline, do: @only_if_missing_dataline
  def script_dataline, do: @script_dataline

  def default_sse_retry_duration, do: @default_sse_retry_duration
  def default_elements_use_view_transitions, do: @default_elements_use_view_transitions
  def default_patch_signals_only_if_missing, do: @default_patch_signals_only_if_missing
  def default_element_patch_mode, do: @default_element_patch_mode

  def element_patch_modes, do: @element_patch_modes

  @doc """
  Validates that a patch mode is valid.
  """
  def valid_patch_mode?(mode) when mode in @element_patch_modes, do: true
  def valid_patch_mode?(_), do: false

  @doc """
  Converts a string to a patch mode atom.
  """
  def parse_patch_mode(mode) when is_atom(mode), do: {:ok, mode}
  def parse_patch_mode(mode) when is_binary(mode) do
    atom_mode = String.to_existing_atom(mode)
    if valid_patch_mode?(atom_mode) do
      {:ok, atom_mode}
    else
      {:error, "Invalid patch mode: #{mode}"}
    end
  rescue
    ArgumentError -> {:error, "Invalid patch mode: #{mode}"}
  end
end
