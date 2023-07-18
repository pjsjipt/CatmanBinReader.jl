
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
    groups::Vector{Vector{Int}}
end

function CatmanReader(io::IO)
    header = read_catman_header(io)
    seek(io, 0)
    seek(io, header.data_offset)
    data = [read_catman_channel_data(io, chan) for chan in header.chans]
    groups = get_catman_groups(header)
    return CatmanReader(header, data, groups)
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

Base.getindex(cat::CatmanReader, i) = cat.data[i]
numchans(cat::CatmanReader) = cat.header.nchans
channames(cat::CatmanReader) = [ch.name for ch in cat.header.chans]
numgroups(cat::CatmanReader) = length(cat.groups)
    
function get_catman_groups(header)

    chan_group = OrderedDict{Int,Vector{Int}}()
    for (i,chan) in enumerate(header.chans)
        if chan.length ∈ keys(chan_group)
            push!(chan_group[chan.length], i)
        else
            chan_group[chan.length] = [i]
        end
    end
    groups = Vector{Int}[]
    for (k,idxs) in chan_group
        push!(groups, idxs)
    end
    
    return groups
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

function cmgroup(cat::CatmanReader, igrp=1, ::Type{T}=Float64) where {T}
    grp = cat.groups[igrp]
    nchans = length(grp)
    Nt = length(cat.data[grp[1]][2])
    
    X = zeros(T, Nt, nchans)

    
    for (i,ichan) in enumerate(grp)
        X[:,i] .= T.(cat.data[ichan][2])
    end
    return X
    
end

function cmgroupnames(cat::CatmanReader, igrp=1)
    return [strip(cat.header.chans[i].name) for i in cat.groups[igrp]]
end

function cmgroupunits(cat::CatmanReader, igrp=1)
    return [strip(cat.header.chans[i].unit) for i in cat.groups[igrp]]
end

function samplingrate(cat::CatmanReader, igrp=1)
    return cat.data[cat.groups[igrp][end]][1]
end    

function cmgrouptimes(cat::CatmanReader, igrp=1;
                         name=r"([T|t]ime)|([Z|z]eit)", unit="s")

    grp = cat.groups[igrp]

    itime = get_catman_group_time(grp, cat.header.chans; name=name, unit=unit)

    return cat.data[itime][2]

end

    
