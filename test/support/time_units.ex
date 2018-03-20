defmodule TimeUnits do
  def milliseconds do
    1000
  end

  def milliseconds_as_micro do
    1000 * milliseconds()
  end

  def seconds do
    60 * milliseconds()
  end

  def seconds_as_micro do
    60 * milliseconds_as_micro()
  end

  def minutes do
    60 * seconds()
  end

  def minutes_as_micro do
    60 * seconds_as_micro()
  end

end

