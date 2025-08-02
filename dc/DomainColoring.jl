# DomainColoring

module DomainColoring

using Base.Threads
using Images, FileIO
using Colors

export presets, DC, gen_image!, gen_image_parallel!, write_image, write_png, rand_expr, is_valid, check

const presets = ["acos((1+im)*log(sin(z^3-1)/z))", "(1+im)*log(sin(z^3-1)/z)", "(1+im)*sin(z)",
    "z + z^2/sin(z^4-1)", "log(sin(z))", "cos(z)/(sin(z^4-1))", "z^6-1",
    "(z^2-1) * (z-2-im)^2 / (z^2+2*im)", "sin(z)*(1+2im)", "sin(1/z)", "sin(z)*sin(1/z)",
    "1/sin(1/sin(z))", "z", "(z^2+1)/(z^2-1)", "(z^2+1)/z", "(z+3)*(z+1)^2",
    "(z/2)^2*(z+1-2im)*(z+2+2im)/z^3", "(z^2)-0.75-(0.2im)"]

struct DC
    w::Int
    h::Int
    size::Int
    expression::String
    image::Vector{UInt32}
    z_comp::Function


    function DC(w::Int, h::Int, expression::String)
        return new(w, h, w * h, expression, Vector{UInt32}(undef, w * h), eval(Expr(:(->), :z, Meta.parse(expression))))
    end
end

function gen_pixel!(dc_::DC, index_::Int) :: Bool
    function pow3(x::Float64)::Float64
        return x * x * x
    end

    limit = π

    rmi, rma, imi, ima = -limit, limit, -limit, limit

    x, y = index_ % dc_.w, index_ / dc_.w

    # map pixel to complex plane
    z = complex(rmi + (rma - rmi) * x / dc_.w, imi + (ima - imi) * y / dc_.h)

    # execute
    result = complex(0, 0)
    try
        @fastmath result = invokelatest(dc_.z_comp, z)
    catch e
        return false
    end

    # convert result to color
    hue, m = angle(result), abs(result)
    hue = mod(mod(hue, 2π) + 2π, 2π) / 2π

    ranges, rangee = 0.0, 1.0
    while m > rangee
        ranges = rangee
        rangee *= ℯ
    end

    k = (m - ranges) / (rangee - ranges)
    kk = k < 0.5 ? k * 2 : 1 - (k - 0.5) * 2

    sat = 0.4 + (1 - pow3(1 - kk)) * 0.6
    val = 0.6 + (1 - pow3(1 - (1 - kk))) * 0.4

    dc_.image[index_+1] = hsv_2_rgb(hue, sat, val)
    return true
end

function pre_evaluate(dc_::DC)
    try
        invokelatest(dc_.z_comp, complex(0, 0))
    catch e
        return false
    end
    return true
end

function gen_image!(dc_::DC)
    if pre_evaluate(dc_)
        for index in 0:dc_.size-1
            gen_pixel!(dc_, index)
        end
    end
end

function is_valid(dc_::DC)::Bool # check if all colors are the same -> false
    return !all(==(first(dc_.image)), dc_.image)
end

function check(dc_::DC)::Bool
    n = 200
    i_fault = 0
    for i in 0:n
        index = rand(0:dc_.size-1)
        if !gen_pixel!(dc_, index)
            i_fault += 1
        end
    end
    return i_fault < n
end

function gen_image_parallel!(dc_::DC)
    if pre_evaluate(dc_)
        @threads for index in 0:dc_.size-1
            gen_pixel!(dc_, index)
        end
    end
end

function write_image(dc_::DC, name::String)
    open(name, "w") do io
        write(io, dc_.image)
    end
end
function write_png(dc_::DC, name::String)
    function toRGB()

        # Create RGB image
        img = Array{RGB{N0f8}}(undef, dc_.h, dc_.w)

        for i in 1:length(dc_.image)
            # Extract RGB components from UInt32 (assuming RGBA format: 0xAABBGGRR)
            pixel = dc_.image[i]
            r = UInt8((pixel >> 0) & 0xFF)
            g = UInt8((pixel >> 8) & 0xFF)
            b = UInt8((pixel >> 16) & 0xFF)
            # a = UInt8((pixel >> 24) & 0xFF)  # Alpha channel if needed

            # Convert to image coordinates
            row = (i - 1) ÷ dc_.w + 1
            col = (i - 1) % dc_.w + 1

            img[row, col] = RGB{N0f8}(r / 255, g / 255, b / 255)
        end

        return img
    end
    Images.save(name, toRGB())
end


function hsv_2_rgb(h::Float64, s::Float64, v::Float64)::UInt32
    r, g, b = 0.0, 0.0, 0.0

    try

        if s == 0
            r, g, b = v, v, v
        else
            h = h == 1 ? 0.0 : h

            z = floor(h * 6.0)
            i, f = Int(z), h * 6.0 - z
            p, q, t = v * (1.0 - s), v * (1.0 - s * f), v * (1.0 - s * (1.0 - f))

            if i == 0
                r, g, b = v, t, p
            elseif i == 1
                r, g, b = q, v, p
            elseif i == 2
                r, g, b = p, v, t
            elseif i == 3
                r, g, b = p, q, v
            elseif i == 4
                r, g, b = t, p, v
            elseif i == 5
                r, g, b = v, p, q
            end

        end

        return 0xff000000 | trunc(UInt32, r * 255) << 16 | trunc(UInt32, g * 255) << 8 | trunc(UInt32, b * 255)
    catch e
        return 0xff000000
    end
end


const UNARY_OPS = [:(sin), :(cos), :(tan), :(log), :(exp), :(acos), :(asin), :(atan)]
const BINARY_OPS = [:+, :-, :*, :/, :^]

"""
    rand_expr(depth)

Recursively generates a random expression tree up to a given depth.
The leaves of the tree are either the variable `z` or a random complex constant.
"""
function rand_expr(depth::Int)
    function random_complex_constant()
        real_part = rand(-10:10)
        imag_part = rand(-10:10)

        choice = rand()
        if choice < 0.3
            return real_part
        elseif choice < 0.6
            return Expr(:call, :*, imag_part, :im)
        else
            return Expr(:call, :+, real_part, Expr(:call, :*, imag_part, :im))
        end
    end

    if depth <= 0
        if rand() < 0.2
            return random_complex_constant()
        else
            return :(z)
        end
    end

    if rand() < 0.5
        op = rand(UNARY_OPS)
        arg = rand_expr(depth - 1)
        return Expr(:call, op, arg)
    else
        op = rand(BINARY_OPS)
        arg1 = rand_expr(depth - 1)
        arg2 = rand_expr(depth - 1)
        return Expr(:call, op, arg1, arg2)
    end
end


function test_presets()

    for p in presets
        print(p, " : ")

        f_expr = eval(Expr(:(->), :z, Meta.parse(p)))

        result = 1 + im

        @time begin
            for i in 0:10_000_000
                z = i + im
                result = invokelatest(f_expr, z)
            end
        end
        println(result)
    end
end

function test_dc()
    w = 1024 * 2
    h = 1024 * 2

    println("DomainColoring generator, with $(Threads.nthreads()) threads, size: $(w)x$(h)=$(w*h)")

    for p in presets
        println("single threaded:")
        dc_ = DC(w, h, p)
        @time gen_image(dc_)
        println("multi threaded:")
        @time gen_image_parallel(dc_, 16)
        write_image(dc_, "image.bin")
        run(`disp_img.py`)
    end
end

function test_expr_rand()
    w = 1024
    h = 1024
    for i in 0:5
        expr = rand_expr(8)
        println(expr, "\n")
        dc = DC(w, h, string(expr))
        gen_image_parallel(dc, 16)
        write_image(dc, "image.bin")
        run(`disp_img.py`)
    end
end

end
