module CatmanBinReader

export read_catman_file
aux_read_string(io, ::Type{T}) where {T} = strip(String(read(io, read(io,T))))

include("channel.jl")
include("header.jl")



function read_catman_file(fname)

    open(fname, "r") do io
        # read header
        hdr = read_catman_header(io)
        nchans = hdr.nchans
        seek(io, 0)
        seek(io, hdr.data_offset)
        data = [read_catman_channel_data(io, chan) for chan in hdr.chans]
        return data        
    end
end

end
