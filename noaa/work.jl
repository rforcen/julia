# daily observations tar.gz reader
push!(LOAD_PATH, ".")
using noaa
using Printf
using Plots

using DataFrames
using IntervalSets
using Statistics

function traverse_daily(filter_expr::Function, nrec_limit=-1, n_result_limit=100, progress_interval=1000)
    function progress_disp(index, n_found, dailyRawFile)
        if progress_interval != -1
            d = convert(Daily, dailyRawFile[1]) # show 1st item
            item = d.items[1]
            @printf("%6d: (%9d) %s, %4d, %2d, %s, (%5d, %c, %c, %c)\r", index, n_found, d.id, d.year, d.month, d.element, item.value, item.mflag, item.qflag, item.sflag)
        end
    end
    println("traverse_daily")

    yearMap = Dict{UInt16,Tuple{Int32,Int32,Float64}}()
    n_found = 0

    for (index, dailyRawFile) in enumerate(DailyTarFileIterator(DAILY_PATH))
        if (index % progress_interval == 0 || index == 1)
            progress_disp(index, n_found, dailyRawFile)
        end

        station = convert(Station, dailyRawFile)

        for dailyObs in dailyRawFile # filter raw file
            if filter_expr(dailyObs, station.elevation)
                n_found += 1
                valid, _min, _max, _avg = min_max_avg_values(dailyObs)
                if valid && haskey(yearMap, year(dailyObs))
                    yearMap[year(dailyObs)] = (min(_min, yearMap[year(dailyObs)][1]), max(_max, yearMap[year(dailyObs)][2]), _avg)
                else
                    yearMap[year(dailyObs)] = (_min, _max, _avg)
                end

                if n_found >= n_result_limit
                    break
                end
            end
        end

        if nrec_limit > 0 && index >= nrec_limit || n_found >= n_result_limit
            progress_disp(index, n_found, dailyRawFile)
            break
        end
    end
    if progress_interval != -1
        println("")
    end
    return yearMap
end

function test01()
    # yearmap : Year => (min, max)
    # @time yearMap = traverse_daily((dailyObs, elevation) -> begin elevation <1500 &&  element(dailyObs) == "TMAX" && year(dailyObs) >= 1900 end, -1, 10_000_000, 1000)
    expr = eval(Meta.parse("(dailyObs, elevation) -> begin elevation <1500 &&  element(dailyObs) == \"TMAX\" && year(dailyObs) >= 1900 end"))
    @time yearMap = traverse_daily(expr, -1, 10_000_000, 1000)

    # graph it
    # 1. sort
    sorted_keys = sort(collect(keys(yearMap)))

    # Extract the first and second elements of the tuples
    values_min = [yearMap[k][1] for k in sorted_keys]
    values_max = [yearMap[k][2] for k in sorted_keys]
    values_avg = [yearMap[k][3] for k in sorted_keys]

    # Convert UInt16 keys to a numeric type suitable for regression
    x_data = collect(Float64, sorted_keys) # Important for regression calculations
    y1_data = collect(Float64, values_min) / 10.0
    y2_data = collect(Float64, values_max) / 10.0
    y3_data = collect(Float64, values_avg) / 10.0

    # 3. Plot the data
    p = plot(x_data, y1_data,
        label="Min",
        line=(:solid, 1),
        marker=(:circle, 1),
        xlabel="Year",
        ylabel="temp (°C)",
        title="min/max TMAX 1900-2024",
        legend=:outertopright, # :none
        smooth=true,
        linecolor_smooth=:blue,
        label_smooth="Min trend"
    )

    plot!(p, x_data, y2_data,
        label="Max",
        line=(:solid, 1),
        marker=(:square, 1),
        color=:red,
        smooth=true,
        linecolor_smooth=:blue,
        label_smooth="Max trend"
    )

    plot!(p, x_data, y3_data,
        label="Avg",
        line=(:solid, 1),
        marker=(:square, 1),
        color=:green,
        smooth=true,
        linecolor_smooth=:blue,
        label_smooth="Avg trend"
    )
    display(p)
    println("Press Enter to continue...")
    readline()

end

function test02()
    st = collect(filter(v -> v.second.elevation > 3500, db.stations))
    st = [st.second for st in st]
    sort!(st, by=el -> el.elevation, rev=true)
    println("top ten higher stations")
    for s in st[1:10]
        @printf("%11s %-30s (%s) %10.1f %s %s %s\n", s.id, s.name, db.countries[s.id[1:2]][1], s.elevation, s.state, s.gsn_flag, s.hcn_crn_flag)
    end    
end

function test03()
    # stations dataframe
    stations = DataFrame(values(db.stations))

    # higher that 4k
    println("top ten higher stations")
    st4k = filter(:elevation => elev -> elev > 4000, stations)
    sort!(st4k, :elevation, rev=true)
    println(st4k[1:10, :])

    # european mainland
    st_eu = subset(stations, 
        :latitude => ByRow(lat -> lat in 36 .. 72), 
        :longitude => ByRow(lon -> lon in -10 .. 60))
    println(st_eu)
    println("top ten higher european stations")
    sort!(st_eu, :elevation, rev=true)
    println(st_eu[1:10, :])

    # add a new country colum based on id[1:2]
    st_eu.country = [db.countries[s.id[1:2]][1] for s in eachrow(st_eu)]
    st_eu = st_eu[:, [:id, :name, :country, :elevation, :latitude, :longitude, :gsn_flag, :hcn_crn_flag]]
    sort!(st_eu, :elevation, rev=true)
    println(st_eu[1:10, :])

    # group by elevation -> count
    elev_stat = combine(groupby(st_eu, :elevation), nrow => :Count) 
    sort!(elev_stat, :elevation, rev=true)
    
    println("top ten elevation counts")
    println(elev_stat[1:10, :])

    c60 = filter(:Count => count -> count > 60, elev_stat)
    tc = sum(c60.Count)
    c60.PercOfTot = (c60.Count ./ tc) .* 100
    sort!(c60, :Count, rev=true)
    println(c60[1:10, :])
end

test03()