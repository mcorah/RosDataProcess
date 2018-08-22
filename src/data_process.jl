##################
# time series data
##################

using Iterators

# There is an accepted time series package called TimeSeries.jl.
# However, that doesn't handle real/float-valued times well.
# Otherwise, I might consider using the DataFrames package.

type TimeSeries{I, D, N} <: AbstractArray{D, N}
  index::AbstractArray{I, 1}
  data::AbstractArray{D, N}

  function TimeSeries(index, data)

    if size(index, 1) != size(data, 1)
      error("first dimension of index and data do not match")
    end

    new(index, data)
  end
end

TimeSeries{I,D,N}(index::AbstractArray{I, 1}, data::AbstractArray{D,N}) =
  TimeSeries{I, D, N}(index, data)
TimeSeries(data) = TimeSeries(collect(1:size(data,1)), data)

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

# Operators

# Do progressively more broad equality checks for comparisons of indices. It is
# possible that the first two can be combined.
indices_match(a, b) = a === b || a == b || all(a .== b)
indices_match(a::TimeSeries, b::TimeSeries) = indices_match(get_index(a),
                                                            get_index(b))

# Processing

function intersect_intervals(series, num_samples = 100)
  lower = maximum(get_index(x)[1] for x in series if length(get_index(x)) > 0)
  upper = minimum(get_index(x)[end] for x in series if length(get_index(x)) > 0)

  linspace(lower, upper, num_samples)
end

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

function interpolate(sample_times, x::TimeSeries)
  data = interpolate(sample_times, get_index(x), get_data(x))

  TimeSeries(sample_times, data)
end

function intersect_interpolate(series, x...)
  interval = intersect_intervals(series, x...)

  map(series) do x
    interpolate(interval, x)
  end
end
