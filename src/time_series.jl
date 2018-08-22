##################
# time series data
##################

# The time series object and interface are intended to model possibly
# high-dimensional arrays where the first dimesion represents and remaining
# dimension represent a scalar, vector, etc. that evolves in time.

# As such, this package seeks to treat time-series data as representing arrays
# with ambient and often common time axes. Alternatively, time series could be
# thought of as modeling functions that map time to the space of the array
# cross-sections. In this sense, this package seeks to lift operations on arrays
# to operate on time series.

# There are other packages such as JuliaStats/TimeSeries or JuliaData/DataFrames
# that could be applicable to time-series data. However, none of these seem to
# be quite applicable due to inflexibility in representation of time and
# inflexibility with data dimension respectively

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

######################
# TimeSeries interface
######################

get_index(x::TimeSeries) = x.index
get_data(x::TimeSeries) = x.data

mutate_data(f, x::TimeSeries) = TimeSeries(x.index, f(x.data))
mutate_index(f, x::TimeSeries) = TimeSeries(f(x.index), x.data)
map_data(f, x::TimeSeries) = mutate_data(x->map(f, x), x)
map_index(f, x::TimeSeries) = mutate_index(x->map(f, x), x)

# Do progressively more broad equality checks for comparisons of indices. It is
# possible that the first two can be combined.
indices_match(a, b) = a === b || a == b || all(a .== b)
indices_match(a::TimeSeries, b::TimeSeries) = indices_match(get_index(a),
                                                            get_index(b))
#################
# Array interface
#################

