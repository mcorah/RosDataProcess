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

# I would like to be able to swap out the array type for "data," but I don't
# know how to do so while also inferring the parameters of the AbstractArray
# that I inherit from
type TimeSeries{D, N, AT <: AbstractVector} <: AbstractArray{D,N}

  time::AT
  data::Array{D,N}

  function TimeSeries(time, data)
    if size(time, 1) != size(data, 1)
      error("first dimension of time and data do not match")
    end

    new(time, data)
  end
end

TimeSeries{D,N,AT}(time::AT, data::Array{D,N}) = TimeSeries{D,N,AT}(time, data)
TimeSeries(data) = TimeSeries(collect(1:size(data,1)), data)

#######################################
# Internal type queries for convenience
#######################################
time_type{D,N,AT}(::Type{TimeSeries{D,N,AT}}) = AT
data_type{D,N,AT}(::Type{TimeSeries{D,N,AT}}) = Array{D,N}

time_eltype{D,N,AT}(::Type{TimeSeries{D,N,AT}}) = eltype(AT)

######################
# TimeSeries interface
######################

# Note: "_data" methods can be deprecated given the array interface although
# some may still be usefull or necessary for odd jobs.

# A good example of when get_data would be useful is when it makes sense to
# discard the time array for the underlying data array. This can happen when the
# "data" encodes a range or an abstract notion of time such as an iteration
# number. While "iterations" may have been published in real time and been used
# to construct a time array, they may also be used as the time component of new
# TimeSeries objects. In such cases, it generally makes sense to use an
# appropriate Array for the time data rather than defining the TimeSeries in
# terms of another TimeSeries.

get_time(x::TimeSeries) = x.time
get_data(x::TimeSeries) = x.data

mutate_time(f, x::TimeSeries) = TimeSeries(f(x.time), x.data)
mutate_data(f, x::TimeSeries) = TimeSeries(x.time, f(x.data))
map_time(f, x::TimeSeries) = mutate_time(x->map(f, x), x)
map_data(f, x::TimeSeries) = mutate_data(x->map(f, x), x)

# Do progressively more broad equality checks for comparisons of indices. It is
# possible that the first two can be combined.
indices_match(a, b) = a === b || a == b || all(a .== b)
indices_match(a::TimeSeries, b::TimeSeries) = indices_match(get_time(a),
                                                            get_time(b))
#################
# Array interface
#################

# See documentation at:
# https://docs.julialang.org/en/latest/manual/interfaces/#man-interface-array-1

import Base.size, Base.linearindexing, Base.getindex, Base.setindex!,
Base.similar

# This deviates somewhat from the documentation but also fits the actual
# definitions in the code so these seem to be the right way to define everything
size(x::TimeSeries) = size(get_data(x))
linearindexing{T <: TimeSeries}(::Type{T}) = linearindexing(data_type(T))
getindex(x::TimeSeries, I...) = getindex(get_data(x), I...)
setindex!(x::TimeSeries, v, I...) = setindex!(get_data(x), v, I...)

# "similar" will produce a new TimeSeries rather than an Array so that we can
# keep the time data around. The data is in turn defined recursively according
# to its type with another call to similar.
function similar{S, N}(x::TimeSeries, ::Type{S}, dims::Dims{N})
  if size(x, 1) != dims[1]
    error("similar not defined for varying first dimension of a TimeSeries")
  end

  TimeSeries(get_time(x), similar(get_data(x), S, dims))
end
