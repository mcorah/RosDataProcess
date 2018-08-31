#####################
# Timing and retiming
#####################

function normalize_start(x::TimeSeries, y...)
  mutate_time(x->normalize_start(x, y...), x)
end
normalize_start(time, start = time[1]) = map(x -> x - start, time)

# intersect general time series
function intersect_intervals(series; num_samples = 100)
  lower = maximum(get_time(x)[1] for x in series if length(get_time(x)) > 0)
  upper = minimum(get_time(x)[end] for x in series if length(get_time(x)) > 0)

  linspace(lower, upper, num_samples)
end

# intersect regular time series (such as produced using published iterations or
# with a auto-generated linear index)
function intersect_regular(series::AbstractArray{<:AbstractArray})
  sort(reduce(intersect, series[1], series[2:end]))
end

# Interpolate a deconstructed time series at a single point
# ts: sorted timestamps for data
# return tuple of value and time for lower bound on time
#
# This is a special internal version that also takes and returns a lower bound
# for efficient linear indexing
function interpolate_(sample_time::Real, ts, data, lower_bound = 0)
  if sample_time <= ts[1]
    return (slicedim(data, 1, 1), 0)
  elseif sample_time >= ts[end]
    return (slicedim(data, 1, length(ts)), length(ts))
  end

  for ii = lower_bound+1:length(ts)
    if sample_time < ts[ii]
      dl = slicedim(data, 1, ii-1)
      tl = ts[ii-1]

      du = slicedim(data, 1, ii)
      tu = ts[ii]

      value = dl + (du - dl) * (sample_time - tu) / (tu - tl)

      return (value, ii - 1)
    end
  end

  # Control flow should not be able to get here
  throw(ArgumentError("Interpolate escaped bounds"))
end

interpolate(sample_time::Real, ts, data) = interpolate_(sample_time, ts,
                                                        data)[1]
# Interpolate a deconstructed time series at a series of points
# sample_times should be sorted
function interpolate(sample_times::AbstractArray{<:Real,1}, ts, data)
  assert_sorted(sample_times)

  output_dimension = (length(sample_times), size(data)[2:end]...)
  ret = similar(data, output_dimension)
  lower_bound = 0

  for ii = 1:size(ret, 1)
    (ret[ii,:], lower_bound) = interpolate_(sample_times[ii], ts, data,
                                          lower_bound)
  end

  ret
end

# Interpolate a TimeSeries at one or more points
interpolate(sample_time::Real, x::TimeSeries) =
  interpolate(sample_time, get_time(x), get_data(x))
function interpolate(sample_times::AbstractArray, x::TimeSeries)
  data = interpolate(sample_times, get_time(x), get_data(x))

  TimeSeries(sample_times, data)
end

# Access a time series at an exact time
#
# This is a special internal version that also takes and returns a lower bound
# for efficient linear indexing
function get_at_time_(time::Real, x::TimeSeries, lower_bound = 1)
  for ii = lower_bound:size(x, 1)
    if get_time(x)[ii] == time
      return (slicedim(get_data(x), 1, ii), ii)
    end
  end

  error("Attempt to get at invalid time: Try interpolate instead?")
end

# Access a time series at a given time or array of times
get_at_time(time::Real, x::TimeSeries) = get_at_time_(time, x)[1]
function get_at_time(times::AbstractArray{<:Real,1}, x::TimeSeries)
  assert_sorted(times)

  output_dimension = (length(times), size(x)[2:end]...)
  ret = similar(get_data(x), output_dimension)
  lower_bound = 1

  for ii = 1:size(ret, 1)
    (ret[ii,:], lower_bound) = get_at_time_(times[ii], x, lower_bound)
  end

  TimeSeries(times, ret)
end

# Intersect intervals (and resample) for a set of time series and return a
# concatenated time series
function intersect_interpolate(series::AbstractArray{<:TimeSeries}; x...)
  # compute the interval
  interval = intersect_intervals(series; x...)

  cat_dim = ndims(series[1]) + 1

  # interpolate and concatenate data
  cat(cat_dim, map(x->interpolate(interval, x), series)...)
end

# Exactly intersect intervals  for a set of time series and return a
# concatenated time series
function intersect_series(series::AbstractArray{<:TimeSeries})
  time = intersect_regular(map(get_time, series))

  cat_dim = ndims(series[1]) + 1

  cat(cat_dim, map(x->get_at_time(time, x), series)...)
end

##############################
# More general data processing
##############################

# Compute standard error in a given dimension.
# Default dimension is two as samples are typically in the second dimension for
# TimeSeries.
function standard_error(x, dim = 2)
  std(x, dim) ./ sqrt(size(x, dim))
end
