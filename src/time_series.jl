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

struct TimeSeries{D, N, AT <: AbstractVector, AD <: AbstractArray} <: AbstractArray{D,N}

  time::AT
  data::AD

  # Here we enforce the constraint that AT <: AbstractArray{D,N}
  function TimeSeries(time::AT, data::AD) where {AT <: AbstractVector, AD <: AbstractArray}
    if size(time, 1) != size(data, 1)
      error("first dimension of time and data do not match")
    end

    assert_sorted(time)

    new{eltype(AD), ndims(AD), AT, AD}(time, data)
  end
end

TimeSeries(data) = TimeSeries(Base.OneTo(size(data,1)), data)

# Copy constructor
TimeSeries(x::TimeSeries) = TimeSeries(get_time(x), get_data(x))

#######################################
# Internal type queries for convenience
#######################################
time_type(::Type{TimeSeries{<:Any,<:Any,AT}}) where {AT} = AT
time_type(::T) where {T <: TimeSeries} = time_type(T)
data_type(::Type{TimeSeries{D,N,AT,AD}}) where {D,N,AT,AD} = AD
data_type(::T) where {T <: TimeSeries} = data_type(T)

time_eltype(::Type{TimeSeries{<:Any,<:Any,AT}}) where {AT} = eltype(AT)
time_eltype(::T) where {T <: TimeSeries} = time_eltype(T)

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
getindex(x::TimeSeries, i::Int) = getindex(get_data(x), i)
getindex(x::TimeSeries{<:Any,N}, I::Vararg{Int,N}) where {N} = getindex(get_data(x),I...)
setindex!(x::TimeSeries, v, I...) = setindex!(get_data(x), v, I...)

# "similar" will produce a new TimeSeries rather than an Array so that we can
# keep the time data around. The data is in turn defined recursively according
# to its type with another call to similar.
function similar(x::TimeSeries, ::Type{S}, dims::Dims{N}) where {S, N}
  if size(x, 1) != dims[1]
    error("similar not defined for varying first dimension of a TimeSeries")
  end

  TimeSeries(get_time(x), similar(get_data(x), S, dims))
end

##########
# Printing
##########

import Base.string, Base.print, Base.show
string(x::TimeSeries) = string("Time:\n", get_time(x), "\nData:\n", get_data(x))
print(io::IO, x::TimeSeries) = print(io, string(x))
show(io::IO, x::TimeSeries) = print(io, string(x))

#######
# Other
#######

function assert_sorted(x::AbstractArray, prefix = "")
  if !issorted(x)
    error(prefix * "sample times should be sorted")
  end
end
