
# noaa aux reader
# usage:
# 1. define NOAA_DATA environment variable to the directory containing the NOAA data
# export NOAA_DATA to the directory containing the NOAA data
# export NOAA_DATA=/media/asd/data/code/noaadata/

# 2. julia work.jl

module noaa

using TarIterators
using CodecZlib
using StaticArrays

export NOAA_DATA_PATH, DAILY_PATH,
    read_countries, read_states, read_elements, read_stations, read_inventory,
    read_countries_map, read_states_map, read_elements_map, read_stations_map,
    read_all_aux, read_all_aux_map, test_read_all,
    min_max_avg_values, id, year, month, element, elevation, Station,
    NOAA_DB, db




const FilePrefix = "ghcnd-"
const space = UInt8(' ')

function __init__()
    global NOAA_DATA_PATH = haskey(ENV, "NOAA_DATA") ? ENV["NOAA_DATA"] : "./"
    global DAILY_PATH = NOAA_DATA_PATH * "ghcnd_all.tar.gz"

    db.countries, db.states, db.elements, stations = read_all_aux_map()
    db.stations = Dict([k => convert(Station, k, v) for (k, v) in stations])
end
# 
struct PosLen
    pos::Int
    len::Int
end

const COUNTRY_FS = [PosLen(0, 2), PosLen(3, 80)]
const STATES_FS = [PosLen(0, 2), PosLen(3, 80)]
const ELEMENTS_FS = [PosLen(0, 4), PosLen(5, 100)]
const STATIONS_FS = [PosLen(0, 11), PosLen(12, 8), PosLen(21, 9), PosLen(31, 6),
    PosLen(38, 2), PosLen(41, 30), PosLen(72, 3), PosLen(76, 3), PosLen(80, 5)]
const INVENTORY_FS = [PosLen(0, 11), PosLen(12, 8), PosLen(21, 9), PosLen(31, 4),
    PosLen(36, 4), PosLen(41, 4)]

# Stations 
struct Station
    id::String
    latitude::Float64
    longitude::Float64
    elevation::Float64
    state::String
    name::String
    gsn_flag::String
    hcn_crn_flag::String
    wmo_id::String
end

# NOAA DB and db instance
mutable struct NOAA_DB
    countries::Dict{String,Vector{String}}
    states::Dict{String,Vector{String}}
    elements::Dict{String,Vector{String}}
    stations::Dict{String,Station}
    inventory::Dict{String,Vector{String}}

    NOAA_DB() = new(Dict{String,Vector{String}}(), Dict{String,Vector{String}}(), Dict{String,Vector{String}}(), Dict{String,Station}(), Dict{String,Vector{String}}())
end

const db = Ref{NOAA_DB}(NOAA_DB())[]


function read_aux(filename::String, ps::Vector{PosLen})
    return [
        [String(strip(l[p.pos+1:min(p.pos + p.len, length(l))])) for p in ps]
        for l in readlines(filename)
    ]
end

function read_aux_map(filename::String, ps::Vector{PosLen})
    return Dict(
        [l[p.pos+1:min(p.pos + p.len, length(l))] for p in ps][1] => [String(strip(l[p.pos+1:min(p.pos + p.len, length(l))])) for p in ps][2:end]
        for l in readlines(filename)
    )
end

function to_map(data::Vector{Vector{String}})
    return Dict(d[1] => d[2:end] for d in data)
end

read_countries() = read_aux(NOAA_DATA_PATH * "$(FilePrefix)countries.txt", COUNTRY_FS)
read_states() = read_aux(NOAA_DATA_PATH * "$(FilePrefix)states.txt", STATES_FS)
read_elements() = read_aux(NOAA_DATA_PATH * "$(FilePrefix)elements.txt", ELEMENTS_FS)
read_stations() = read_aux(NOAA_DATA_PATH * "$(FilePrefix)stations.txt", STATIONS_FS)
read_inventory() = read_aux(NOAA_DATA_PATH * "$(FilePrefix)inventory.txt", INVENTORY_FS)

read_countries_map() = read_aux_map(NOAA_DATA_PATH * "$(FilePrefix)countries.txt", COUNTRY_FS)
read_states_map() = read_aux_map(NOAA_DATA_PATH * "$(FilePrefix)states.txt", STATES_FS)
read_elements_map() = read_aux_map(NOAA_DATA_PATH * "$(FilePrefix)elements.txt", ELEMENTS_FS)
read_stations_map() = read_aux_map(NOAA_DATA_PATH * "$(FilePrefix)stations.txt", STATIONS_FS)
# inventory has duplicated keys

read_all_aux() = read_countries(), read_states(), read_elements(), read_stations(), read_inventory()
read_all_aux_map() = read_countries_map(), read_states_map(), read_elements_map(), read_stations_map()

function test_read_all()
    @time "read_all_aux" countries, states, elements, stations, inventory = read_all_aux()
    println("Countries: $(length(countries))")
    println("States   : $(length(states))")
    println("Elements : $(length(elements))")
    println("Stations : $(length(stations))")
    println("Inventory: $(length(inventory))")

    @time "read_all_aux_map" countries_map, states_map, elements_map, stations_map = read_all_aux_map()
    println("Countries: $(length(countries_map))")
    println("States   : $(length(states_map))")
    println("Elements : $(length(elements_map))")
    println("Stations : $(length(stations_map))")

    @time "to map conversion" countries_map, states_map, elements_map, stations_map = to_map(countries), to_map(states), to_map(elements), to_map(stations)
    println("Countries: $(length(countries_map))")
    println("States   : $(length(states_map))")
    println("Elements : $(length(elements_map))")
    println("Stations : $(length(stations_map))")


    for (k, d) in countries_map
        println("$(k): $(d)")
        break
    end
    for (k, d) in states_map
        println("$(k): $(d)")
        break
    end
    for (k, d) in elements_map
        println("$(k): $(d)")
        break
    end
    for (k, d) in stations_map
        println("$(k): $(d)")
        break
    end
end

# daily support
const Character = UInt8

export DailyTarFileIterator, ItemsRaw, DailyRaw, Item, Daily, id, year, month, element

struct ItemsRaw
    value::SVector{5,Character}
    mflag::Character
    qflag::Character
    sflag::Character
end

struct DailyRaw
    id::SVector{11,Character}
    year::SVector{4,Character}
    month::SVector{2,Character}
    element::SVector{4,Character}
    items::SVector{31,ItemsRaw}
    lf::Character
end

struct Item
    value::Int32
    mflag::Char
    qflag::Char
    sflag::Char
end

struct Daily
    id::String
    year::UInt16
    month::UInt8
    element::String
    items::Vector{Item}
    lf::Character
end

# raw converters
function svec2Int(svec::SVector{5,UInt8})::Int32
    val::Int32 = 0
    is_negative = false

    # Trim leading spaces and handle sign
    idx = 1
    while idx <= 5 && svec[idx] == UInt8(' ')
        idx += 1
    end

    if idx <= 5 && svec[idx] == UInt8('-')
        is_negative = true
        idx += 1
    elseif idx <= 5 && svec[idx] == UInt8('+') # Robustness: handle explicit '+'
        idx += 1
    end

    # Parse digits
    while idx <= 5
        byte = svec[idx]
        if UInt8('0') <= byte <= UInt8('9')
            val = val * 10 + (byte - UInt8('0'))
        elseif byte == UInt8(' ') # Allow trailing spaces after digits
            break # Stop if we hit a space after digits
        else
            # For robustness, you might throw an ArgumentError here for invalid chars
            # throw(ArgumentError("Invalid character for integer parsing: $(Char(byte))"))
            break # Stop on non-digit/non-space char
        end
        idx += 1
    end

    return is_negative ? -val : val
end

Base.convert(::Type{Item}, item_raw::ItemsRaw) = Item(svec2Int(item_raw.value), item_raw.mflag, item_raw.qflag, item_raw.sflag)
Base.convert(::Type{Daily}, daily_raw::DailyRaw) = Daily(String(daily_raw.id), parse(UInt16, String(daily_raw.year)), parse(UInt8, String(daily_raw.month)), String(daily_raw.element), convert(Vector{Item}, daily_raw.items), daily_raw.lf)
Base.convert(::Type{Vector{Daily}}, daily_raw::Vector{DailyRaw}) = [convert(Daily, daily_raw[i]) for i in 1:length(daily_raw)]

function Base.convert(::Type{Vector{DailyRaw}}, s::String) # raw byte copy from String to DailyRaw vector
    nrecs = length(s) ÷ sizeof(DailyRaw) # number of records
    dailyRaw = Vector{DailyRaw}(undef, nrecs) # daily vector
    # copy to Daily_Raw Vector
    Base.unsafe_copyto!(pointer(dailyRaw), Ptr{DailyRaw}(Base.unsafe_convert(Ptr{UInt8}, s)), nrecs)
    return dailyRaw
end
Base.convert(::Type{Daily}, s::String) = convert(Daily, convert(Vector{DailyRaw}, s))

# station converters
Base.convert(::Type{Station}, k::String, s::Vector{String}) = Station(k, parse(Float64, s[1]), parse(Float64, s[2]), parse(Float64, s[3]), s[4], s[5], s[6], s[7], s[8])
Base.convert(::Type{Station}, s::DailyRaw) = db.stations[id(s)]
Base.convert(::Type{Station}, s::Vector{DailyRaw}) = db.stations[id(s[1])]


# format getters  from DailyRaw
id(daily_raw::DailyRaw) = String(daily_raw.id)
year(daily_raw::DailyRaw) = parse(UInt16, String(daily_raw.year))
month(daily_raw::DailyRaw) = parse(UInt8, String(daily_raw.month))
element(daily_raw::DailyRaw) = String(daily_raw.element)

# station getters from DailyRaw item -> dailyObservation
elevation(daily_raw::DailyRaw) = db.stations[id(daily_raw)].elevation
latitude(daily_raw::DailyRaw) = db.stations[id(daily_raw)].latitude
longitude(daily_raw::DailyRaw) = db.stations[id(daily_raw)].longitude

function min_max_avg_values(daily_raw::DailyRaw)::Tuple{Bool,Int32,Int32,Float64}
    min_val = Inf
    max_val = -Inf
    sum_val = 0.0
    count = 0
    for i in 1:31
        val = svec2Int(daily_raw.items[i].value)
        if val != -9999 && daily_raw.items[i].qflag == space
            if val < min_val
                min_val = val
            end
            if val > max_val
                max_val = val
            end
            sum_val += val
            count += 1
        end
    end
    valid = min_val != Inf && max_val != -Inf
    return valid, Int32(valid ? min_val : 0), Int32(valid ? max_val : 0), Float64(valid ? sum_val / count : 0)
end

# daily iterator
struct DailyTarFileIterator
    daily_path::String # Path to the .tar.gz file
end

function Base.iterate(iter::DailyTarFileIterator) # DailyRaw vector (faster), convert only required
    try
        gz_stream = GzipDecompressorStream(open(iter.daily_path, "r"))
        tar_iter = TarIterator(gz_stream, r".*[.]dly")
        tar_result = iterate(tar_iter)

        if isnothing(tar_result)
            close(gz_stream)
            return nothing
        end

        (tar_header, tar_io) = tar_result[1]
        tar_state = tar_result[2]

        daily_raw_data = convert(Vector{DailyRaw}, read(tar_io, String))

        return (daily_raw_data, (gz_stream, tar_iter, tar_state))
    catch e
        @error "Error initializing DailyTarFileIterator" exception = (e, catch_backtrace())
        return nothing
    end
end


function Base.iterate(iter::DailyTarFileIterator, state)
    gz_stream, tar_iter, tar_state = state

    tar_result = iterate(tar_iter, tar_state)

    if isnothing(tar_result)
        close(gz_stream)
        return nothing
    end

    (tar_header, tar_io) = tar_result[1]
    new_tar_state = tar_result[2]

    daily_raw_data = convert(Vector{DailyRaw}, read(tar_io, String))
    return (daily_raw_data, (gz_stream, tar_iter, new_tar_state))
end


end
