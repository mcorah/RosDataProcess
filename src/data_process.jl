#####################
# Timing and retiming
#####################

function normalize_start(x::TimeSeries, y...)
  mutate_time(x->normalize_start(x, y...), x)
end
normalize_start(time, start = time[1]) = map(x -> x - start, time)

function intersect_intervals(series, num_samples = 100)
  lower = maximum(get_time(x)[1] for x in series if length(get_time(x)) > 0)
  upper = minimum(get_time(x)[end] for x in series if length(get_time(x)) > 0)

  linspace(lower, upper, num_samples)
end

# ts: sorted timestamps for data
# return tuple of value and time for lower bound on time
function interpolate(sample_time::Real, ts, data, lower_bound = 0)
  if sample_time <= ts[1]
    return (data[1], 0)
  elseif sample_time >= ts[end]
    return (data[end], length(ts))
  end

  for ii = lower_bound+1:length(ts)
    if sample_time < ts[ii]
      dl = data[ii-1]
      tl = ts[ii-1]

      du = data[ii]
      tu = ts[ii]

      value = dl + (du - dl) * (sample_time - tu) / (tu - tl)

      return (value, ii - 1)
    end
  end

  # Control flow should not be able to get here
  throw(ArgumentError("Interpolate escaped bounds"))
end

# sample_times should be sorted
function interpolate{T<:Real}(sample_times::AbstractArray{T,1}, ts, data)
  if issorted(sample_times)
    ret = zeros(sample_times)
    lower_bound = 0

    for ii = eachindex(ret)
      (ret[ii], lower_bound) = interpolate(sample_times[ii], ts, data,
                                                   lower_bound)
    end

    return ret
  else
    throw(ArgumentError("sample times should be sorted"))
  end
end

function interpolate(sample_times, x::TimeSeries)
  data = interpolate(sample_times, get_time(x), get_data(x))

  TimeSeries(sample_times, data)
end


function intersect_interpolate{T <: TimeSeries}(series::AbstractArray{T}, x...)
  # compute the interval
  interval = intersect_intervals(series, x...)

  cat_dim = ndims(series[1]) + 1

  # interpolate and concatenate data
  cat(cat_dim, map(x->interpolate(interval, x), series)...)
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
