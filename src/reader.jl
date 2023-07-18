
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
    "Header information of a Catman `.bin` file."
    header::CatmanHeader
    "Data inthe file"
    data::D
    "Division in groups of the data"
    groups::Vector{Vector{Int}}
end

"""
 * `CatmanReader(io::IO)`
 * `CatmanReader(fname::AbstractString)`
 * `CatmanReader(bytes::AbstractVector{UInt8})`

Loads a Catman `.bin` file. It first reads the header ([`CatmanHeader`](@ref)) and then the data. The data is analyzed and split into groups. Each group corresponds to data acquired at the same sampling rate. The group is defined for channels having the same data length.

"""
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

"Returns data corresponding to channel `i`"
Base.getindex(cat::CatmanReader, i) = cat.data[i][2]

Base.length(cat::CatmanReader) = numchans(cat)

Base.length(cat::CatmanReader, i) = length(cat.data[i][2])

"Returns the number of channels in the data"
numchans(cat::CatmanReader) = cat.header.nchans


"Return the `i`-th channel name"
channame(cat::CatmanReader, i) = cat.header.chans[i].name

"Returns the names of each channel"
channames(cat::CatmanReader) = [ch.name for ch in cat.header.chans]

"Returns the units of each channel"
chanunits(cat::CatmanReader) = [ch.unit for ch in cat.header.chans]

"Returns the units of channel `i`"
chanunit(cat::CatmanReader, i) = cat.header.chans[i].unit

"Returns the comment of channel `i`"
chancomment(cat::CatmanReader, i) = cat.header.chans[i].comment

"Return the `i`-th channel sampling rate"
chanrate(cat::CatmanReader, i) = cat.data[i][1]

"Return the sampling rates of each channel"
chanrates(cat::CatmanReader) = [d[1] for d in cat.data]

"Return the number of samples of channel `i`"
numsamples(cat::CatmanReader, i) = length(cat.data[i][2])

"Return the number of samples of each channel channel"
numsamples(cat::CatmanReader) = [length(d[2]) for d in cat.data]

"Returns the number of samples of group `i`"
numgroupsamples(cat::CatmanReader, i=1) = length(cat.data[cat.groups[i][1]][2])




"Returns the number of groups in the data"
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

"""
`cmgroup(cat::CatmanReader, igrp=1, ::Type{T}=Float64)`

Returns a group of data from a `.bin` Catman file. The data consists of
a matrix where each column corresponds to a channel. The following methods
help reading data a channel information:

 * [`samplingrate`](@ref) returns the sampling rate
 * [`cmgrouptimes`](@ref) returns the sample times
 * [`cmgroupnames`](@ref) returns the channels names
 * [`cmgroupunits`](@ref) return channels units

"""
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

"""
`cmgroupsnames(cat, igrp)`

Returns the names of the channels that make up group `igrp`.

"""
function cmgroupnames(cat::CatmanReader, igrp=1)
    return [strip(cat.header.chans[i].name) for i in cat.groups[igrp]]
end

"""
`cmgroupunits(cat, igrp)`

Returns the units of the channels that make up group `igrp`.
"""
function cmgroupunits(cat::CatmanReader, igrp=1)
    return [strip(cat.header.chans[i].unit) for i in cat.groups[igrp]]
end

"""
`samplingrate(cat, igrp)`

Returns the sampling rate of group `igrp`.
"""
function samplingrate(cat::CatmanReader, igrp=1)
    return cat.data[cat.groups[igrp][end]][1]
end    

"""
cmgrouptimes(cat, igrp=1; name=r"([T|t]ime)|([Z|z]eit)", unit="s")`

Returns the sampling times of group `igrp`. The channel containing timing information is searched using key word arguments `name` and `unit`. If `name` is given, the channels' names are searched until a matching name is found. `name` can be a string or a regex or any object that can be used with method `occursin`.

If a name is not provided (`name=""` for example) the units of each channel can be searched. The first channel with matching unit (default is `s` for second) is considered to be the timing channel of the group.

"""
function cmgrouptimes(cat::CatmanReader, igrp=1;
                         name=r"([T|t]ime)|([Z|z]eit)", unit="s")

    grp = cat.groups[igrp]

    itime = get_catman_group_time(grp, cat.header.chans; name=name, unit=unit)

    return cat.data[itime][2]

end

    
