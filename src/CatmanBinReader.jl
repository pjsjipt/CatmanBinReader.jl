module CatmanBinReader

export read_catman_file, CatmanReader, splitgroups
aux_read_string(io, ::Type{T}) where {T} = strip(String(read(io, read(io,T))))

include("channel.jl")
include("header.jl")
include("reader.jl")




end
