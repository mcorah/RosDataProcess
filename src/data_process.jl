##################
# time series data
##################

# There is an accepted time series package called TimeSeries.jl.
# However, that doesn't handle real/float-valued times well.
# Otherwise, I might consider using the DataFrames package.

immutable TimeSeries
  index::AbstractArray
  data::AbstractArray
  TimeSeries(index, data) = new(index, data)
end

TimeSeries(data) = new(collect(1:size(data,1)), data)

get_index(x::TimeSeries) = x.index
get_data(x::TimeSeries) = x.data

mutate_data(f, x::TimeSeries) = TimeSeries(x.index, f(x.data))
mutate_index(f, x::TimeSeries) = TimeSeries(f(x.index), x.data)
map_data(f, x::TimeSeries) = mutate_data(x->map(f, x), x)
map_index(f, x::TimeSeries) = mutate_index(x->map(f, x), x)

function normalize_start(x::TimeSeries, y...)
  mutate_index(x->normalize_start(x, y...), x)
end
normalize_start(index, start = index[1]) = map(x -> x - start, index)

to_sec(x::PyObject) = x[:to_sec]()
to_sec(x::AbstractArray) = map(to_sec, x)
to_sec(x::TimeSeries) = map_index(to_sec, x)

# ts: sorted timestamps for data
# return tuple of value and index for lower bound on time
function interpolate_at_time(sample_time, ts, data, lower_bound = 0)
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
function interpolate(sample_times, ts, data)
  if issorted(sample_times)
    ret = zeros(sample_times)
    lower_bound = 0

    for ii = eachindex(ret)
      (ret[ii], lower_bound) = interpolate_at_time(sample_times[ii], ts, data,
                                                   lower_bound)
    end

    return ret
  else
    throw(ArgumentError("sample times should be sorted"))
  end
end
