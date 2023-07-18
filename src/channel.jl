struct CatmanChannelInfo
    "Channel index"
    num::Int16
    "Number of samples in the channel"
    length::Int32
    "Channel name"
    name::String
    "Channel data unit"
    unit::String
    "Channel comment"
    comment::String
    "Channel format"
    format::Int16
    dw::Int16
    time::Float64
    nhdrbytes::Int32
    ext_header::Dict{String,Any}
    lmode::Int8
    scale::Int8
    npoi::Int8
    formula::String
    sensor_info::String
    precision::Int
end

"""
`CatmanChannelInfo(io)`

Reads and stores Catman channel info.
"""
function CatmanChannelInfo(io)

    num = read(io, Int16)
    len = read(io, Int32)
    name = aux_read_string(io, Int16)
    unit = aux_read_string(io, Int16)
    comment = aux_read_string(io, Int16)
    format = read(io, Int16)
    dw = read(io, Int16)
    t = read(io, Float64)
    nhdrbytes = read(io, Int32)
    ext_header = read_catman_ext_header(io, nhdrbytes)
    eform = ext_header["ExportFormat"]
    #return ext_header
    precDict = Dict(0=>8, 1=>4, 2=>2)
    if eform ∉ keys(precDict)
        eform = 0
    end
    
    precision = precDict[eform]
    
    lmode = read(io, UInt8)
    scale = read(io, UInt8)
    npoi = read(io, UInt8)
    for i in 1:npoi
        read(io, Float64)
    end
    read(io, Int16)
    formula = aux_read_string(io, Int16)
    sensor_info = aux_read_string(io, Int32)
    return CatmanChannelInfo(num, len, name, unit, comment, format, dw, t, nhdrbytes,
                             ext_header, lmode, scale, npoi, formula, sensor_info,
                             precision)
end

                             
    
    
                  
    
function read_catman_ext_header(io, nhdrbytes=-1)
    
    pos0 = position(io)
    h = Dict{String,Any}()
    h["T0"] = read(io, Float64)
    h["dt"] = read(io, Float64)
    h["SensorType"] = read(io, Int16)
    h["SupplyVoltage"] = read(io, Int16)

    h["FiltChar"] = read(io, Int16)
    h["FiltFreq"] = read(io, Int16)
    h["TareVal"] = read(io, Float32)
    h["ZeroVal"] = read(io, Float32)
    h["MeasRange"] = read(io, Float32)
    h["InChar"] = [read(io, Float32) for i in 1:4]

    h["SerNo"] = String(read(io, 32))
    h["PhysUnit"] = String(read(io, 8))
    h["NativeUnit"] = String(read(io, 8))

    h["Slot"] = read(io, Int16)
    h["SubSlot"] = read(io, Int16)
    h["AmpType"] = read(io, Int16)
    h["APType"] = read(io, Int16)
    h["kFactor"] = read(io, Float32)
    h["bFactor"] = read(io, Float32)

    h["MeasSig"] = read(io, Int16)
    h["AmpInput"] = read(io, Int16)
    h["HPFilt"] = read(io, Int16)
    h["OLImportInfo"] = read(io, Int8)
    h["ScaleType"] = read(io, Int8)
    
    h["SoftwareTareVal"] = read(io, Float32)
    h["WriteProtected"] = read(io, Int8)
    read(io, 3)

    h["NominalRange"] = read(io, Float32)
    h["CLCFactor"] = read(io, Float32)
    h["ExportFormat"] = read(io, Int8)
    read(io, 7)
    
    posN = position(io)
    if nhdrbytes >= 0 && (posN-pos0) != nhdrbytes
        @warn """
                Number of bytes read in the extended header of the channel $chan
                doesn't match its declared length.

                This probably means that the hardcoded format definition is no longer
                valid and must be revised.

                Leaving the extended header as is and resetting the read position
                of  the binary reader.
            """
        h["ExportFormat"] = 0
        
        seek(io, pos0 + nhdrbytes)
    end
    return h
end

function read_catman_channel_data(io, chan)

    N = chan.length
        
    if chan.precision == 8
        data = read!(io, zeros(Float64, N))
    elseif chan.precision == 4
        data = read!(io, zeros(Float32, N))
    elseif chan.precision == 2
        minval = read(io, Float64)
        maxval = read(io, Float32)
        data = ( (maxval - minval) / 32767 ) .* read!(io, zeros(UInt16, N)) .+ minval
    end

    rate = 1000 / chan.ext_header["dt"]

    return rate, data
end

    
