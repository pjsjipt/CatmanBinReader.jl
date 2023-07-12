struct CatmanHeader
    file_id::Int16
    data_offset::Int32
    comment::String
    nchans::Int16
    maxlen::Int32
    chans::Vector{CatmanChannelInfo}
end


function read_catman_header(io)

    # Get file type id
    file_id = read(io, Int16)
    # Get byte offset at which data starts
    data_offset = read(io, Int32)
    # read comment
    comment = aux_read_string(io, Int16)

    # Just read stuff ...
    for i in 1:32
        n1 = read(io, Int16)
        read(io, n1)
    end

    # Read the total number of channels
    num_chans = read(io, Int16)

    # Read maximum channel length. 0 for unlimited
    max_length = read(io, Int32)

    # Just more stuff
    for i in 1:num_chans
        read(io, Int32)
    end

    # Reduced factor
    red_fac = read(io, Int32)
    # Read channel header
    chan_header = [CatmanChannelInfo(io) for i in 1:num_chans]
    
    return CatmanHeader(file_id, data_offset, comment,
                        num_chans, max_length,
                        chan_header)

end
