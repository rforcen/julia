# generate waterman polyhedra

using LinearAlgebra

function waterman(radius::Float64)

    coords = Vector{Float64}()

    a = b = c = 0.0  # center

    s = radius
    radius2 = radius * radius
    xra, xrb = ceil(a - s), floor(a + s)

    for x in xra:xrb
        R = radius2 - (x - a) * (x - a)
        if R < 0
            continue
        end

        s = sqrt(R)
        yra, yrb = ceil(b - s), floor(b + s)

        for y in yra:yrb
            Ry = R - (y - b) * (y - b)
            if Ry < 0
                continue
            end            # case Ry < 0

            if Ry == 0 && c == floor(c)  # case Ry=0
                if mod(x + y + c, 2) != 0
                    continue
                else
                    zra, zrb = c, c
                end
            else  # case Ry > 0
                s = sqrt(Ry)
                zra, zrb = ceil(c - s), floor(c + s)
            end

            for z in zra:zrb
                if x * x + y * y + z * z <= radius2
                    push!(coords, x)
                    push!(coords, y)
                    push!(coords, z)
                end
            end
        end
    end

    return coords ./ norm(coords) # normalized
end

println(waterman(15.5))