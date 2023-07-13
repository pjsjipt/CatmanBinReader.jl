
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

struct CatmanReader{D}
    header::CatmanHeader
    data::D
end

function CatmanReader(io::IO)
    header = read_catman_header(io)
    seek(io, 0)
    seek(io, header.data_offset)
    data = [read_catman_channel_data(io, chan) for chan in header.chans]

    return CatmanReader(header, data)
end
   
CatmanReader(fname::AbstractString) = open(fname, "r") do io
    CatmanReader(io)
end

CatmanReader(bytes::AbstractVector{UInt8}) = CatmanReader(IOBuffer(bytes))

function Base.show(io::IO, cat::CatmanReader)
    println(io, "Catman .bin file, with $(cat.header.nchans) channels):")
    println(io, "$(cat.header.comment)")
    for (i,ch) in enumerate(cat.header.chans)
        dt = ch.ext_header["dt"]
        rate = 1000/dt
        println(io, "Channel $i (unit=$(ch.unit), rate=$rate Hz): $(ch.name)")
    end
    
end

    
function get_catman_groups(cat::CatmanReader{D}) where {D}
    header = cat.header

    chan_group = Dict{Int,Vector{Int}}()

    found_time_chan = false
    for (i,chan) in enumerate(header.chans)
        if chan.length ∈ keys(chan_group)
            push!(chan_group[chan.length], i)
        else
            chan_group[chan.length] = [i]
        end
    end
    return chan_group
end

function get_catman_group_time(grp, chans; name=r"([T|t]ime)|([Z|z]eit)", unit="s")

    if name == ""
        # Search the first channel in group that has unit $unit
        for i in grp
            if strip(chans[i].unit) == unit
                return i
            end
        end
        error("No channel with unit $unit found!")
    else
        # Let's search by name
        for i in grp
            if occursin(name, chans[i].name)
                return i
            end
        end
        error("No channel with name $name found!")
    end
    
    
end

function get_catman_group(grp::AbstractVector{<:Integer}, idx_time, cat::CatmanReader, ::Type{T}=Float64) where {T}

    nchans = length(grp)
    t = cat.data[idx_time][2]
    Nt = length(t)
    X = zeros(T, Nt, nchans)

    names = [strip(ch.name) for ch in cat.header.chans[grp]]
    units = [strip(ch.unit) for ch in cat.header.chans[grp]]
    
    for (i,ichan) in enumerate(grp)
        X[:,i] .= T.(cat.data[ichan][2])
    end

    return t, X, names, units
    
end

function splitgroups(cat::CatmanReader, ::Type{T}=Float64;
                     name=r"([T|t]ime)|([Z|z]eit)", unit="s") where {T}
    grps = get_catman_groups(cat)

    idx_time = Dict{Int,Int}()

    for (len,gr) in grps
        idx_time[len] = get_catman_group_time(gr, cat.header.chans;
                                              name=name, unit=unit)
    end
    return [get_catman_group(grps[len], idx_time[len], cat, T)
            for len in keys(grps)]
end

    
