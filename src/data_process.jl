#####################
# Timing and retiming
#####################

function normalize_start(x::TimeSeries, y...)
  mutate_time(x->normalize_start(x, y...), x)
end
normalize_start(time, start = time[1]) = map(x -> x - start, time)

# intersect general time series
const default_num_samples = 100
function intersect_intervals(series; num_samples = default_num_samples)
  lower = maximum(get_time(x)[1] for x in series if length(get_time(x)) > 0)
  upper = minimum(get_time(x)[end] for x in series if length(get_time(x)) > 0)

  range(lower, stop=upper, length=num_samples)
end

# intersect regular time series (such as produced using published iterations or
# with a auto-generated linear index)
function intersect_regular(series::AbstractArray{<:AbstractArray})
  sort(reduce(intersect, series[2:end], init=series[1]))
end

# Interpolate a deconstructed time series at a single point
# ts: sorted timestamps for data
# return tuple of value and time for lower bound on time
#
# This is a special internal version that also takes and returns a lower bound
# for efficient linear indexing
function interpolate_(sample_time::Real, ts, data, lower_bound = 0)
  if sample_time <= ts[1]
    return (data[1,:], 0)
  elseif sample_time >= ts[end]
    return (data[length(ts),:], length(ts))
  end

  for ii = lower_bound+1:length(ts)
    if sample_time < ts[ii]
      dl = data[ii-1,:]
      tl = ts[ii-1]

      du = data[ii,:]
      tu = ts[ii]

      value = dl + (du - dl) * (sample_time - tl) / (tu - tl)

      return (value, ii - 1)
    end
  end

  # Control flow should not be able to get here
  throw(ArgumentError("Interpolate escaped bounds"))
end

function interpolate_(sample_time::Real, series::TimeSeries, x...)
  interpolate_(sample_time, get_time(series), get_data(series), x...)
end

interpolate(sample_time::Real, x...) = interpolate_(sample_time, x...)[1]

# hack to get type of array to allocate after division
function division_output_type(x::Type)
  types = Base.return_types(/, Tuple{x, Float64})
  promote_type(types...)
end

# Interpolate a deconstructed time series at a series of points
# sample_times should be sorted
function interpolate(sample_times::AbstractArray{<:Real,1}, ts, data)
  assert_sorted(sample_times)

  output_dimension = (length(sample_times), size(data)[2:end]...)
  output_element_type = division_output_type(eltype(data))

  ret = similar(data, output_element_type, output_dimension)
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
      return (get_data(x)[ii,:], ii)
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

  cat_dim = maximum(ndims, series) + 1

  # interpolate and concatenate data
  cat(dims=cat_dim, map(x->interpolate(interval, x), series)...)
end

# Exactly intersect intervals  for a set of time series and return a
# concatenated time series
function intersect_series(series::AbstractArray{<:TimeSeries})
  time = intersect_regular(map(get_time, series))

  cat_dim = maximum(ndims, series) + 1

  cat(dims=cat_dim, map(x->get_at_time(time, x), series)...)
end

# Returns a view into x at given indices
function select_indices(inds, x::TimeSeries)
  TimeSeries(selectdim(get_time(x), 1, inds), selectdim(get_data(x), 1, inds))
end

# Returns a view into x for times where f is true
function select_times(f, x::TimeSeries)
  inds = [ind for (ind, t) in enumerate(get_time(x)) if f(t)]
  select_indices(inds, x)
end

##########
# Calculus
##########

# The following code relates to numeric integration and differentiation of time
# series data

# differentiation algorithms
struct Windowed end; struct Discrete end

# default algorithm
function differentiate(x::TimeSeries, method=Windowed(); kws...)
  differentiate(x, method=method; kws...)
end

# concrete implementations

# Compute the derivative over a window. Interpolate for smoothness
function differentiate_windowed(x::TimeSeries, lower_time, upper_time,
                                lower_lb = 0, upper_lb = 0)
  lower_time = max(lower_time, get_time(x)[1])
  upper_time = min(upper_time, get_time(x)[end])

  (lower_value, lower_lb) = interpolate_(lower_time, x, lower_lb)
  (upper_value, upper_lb) = interpolate_(upper_time, x, upper_lb)

  derivative = (upper_value - lower_value) / (upper_time - lower_time)

  (derivative, lower_lb, upper_lb)
end

# Differentiate the TimeSeries using a fixed time window
# I could potentially implement this instead by interpolating arrays rather than
# value. That would be slightly slower but also cleaner.
function differentiate(x::TimeSeries, method::Windowed;
                       time=get_time(x), window=1/(length(time)-1))
  assert_sorted(time)

  output_dimension = (length(time), size(x)[2:end]...)
  ret = similar(x, output_dimension)

  lower_lb = 0
  upper_lb = 0

  hw = window / 2

  for (ii, t) = enumerate(time)
    (ret[ii,:], lower_lb, upper_lb) = differentiate_windowed(x, t-hw, t+hw,
                                                             lower_lb, upper_lb)
  end

  ret
end

############
# Statistics
############

# Compute standard error in a given dimension.
# Default dimension is two as samples are typically in the second dimension for
# TimeSeries.
function standard_error(x, dim = 2)
  std(x, dims=dim) ./ sqrt(size(x, dim))
end
