module CatmanBinReader

import DataStructures: OrderedDict
export CatmanReader, numchans, channames, numgroups
export channame, channames, chanunit, chanunits, chanrate, chanrates
export numsamples, numgroupsamples, chancomment
export cmgroup, cmgrouptimes, cmgroupnames, cmgroupunits
export samplingrate
aux_read_string(io, ::Type{T}) where {T} = strip(String(read(io, read(io,T))))

include("channel.jl")
include("header.jl")
include("reader.jl")


end
