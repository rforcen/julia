# mandelbrot fractals

module Mandelbrot

using Base.Threads
using Images, FileIO, Colors
using Dates, DoubleFloats

const fire_pallete_256 = UInt32[0, 0, 4, 12, 16, 24, 32, 36, 44, 48, 56, 64, 68, 76, 80, 88, 96,
    100, 108, 116, 120, 128, 132, 140, 148, 152, 160, 164, 172, 180, 184, 192, 200, 1224, 3272,
    4300, 6348, 7376, 9424, 10448, 12500, 14548, 15576, 17624, 18648, 20700, 21724, 23776, 25824,
    26848, 28900, 29924, 31976, 33000, 35048, 36076, 38124, 40176, 41200, 43248, 44276, 46324,
    47352, 49400, 51452, 313596, 837884, 1363196, 1887484, 2412796, 2937084, 3461372, 3986684,
    4510972, 5036284, 5560572, 6084860, 6610172, 7134460, 7659772, 8184060, 8708348, 9233660, 9757948,
    10283260, 10807548, 11331836, 11857148, 12381436, 12906748, 13431036, 13955324, 14480636,
    15004924, 15530236, 16054524, 16579836, 16317692, 16055548, 15793404, 15269116, 15006972,
    14744828, 14220540, 13958396, 13696252, 13171964, 12909820, 12647676, 12123388, 11861244,
    11599100, 11074812, 10812668, 10550524, 10288380, 9764092, 9501948, 9239804, 8715516, 8453372,
    8191228, 7666940, 7404796, 7142652, 6618364, 6356220, 6094076, 5569788, 5307644, 5045500, 4783356,
    4259068, 3996924, 3734780, 3210492, 2948348, 2686204, 2161916, 1899772, 1637628, 1113340, 851196,
    589052, 64764, 63740, 62716, 61692, 59644, 58620, 57596, 55548, 54524, 53500, 51452, 50428,
    49404, 47356, 46332, 45308, 43260, 42236, 41212, 40188, 38140, 37116, 36092, 34044, 33020,
    31996, 29948, 28924, 27900, 25852, 24828, 23804, 21756, 20732, 19708, 18684, 16636, 15612,
    14588, 12540, 11516, 10492, 8444, 7420, 6396, 4348, 3324, 2300, 252, 248, 244, 240, 236, 232,
    228, 224, 220, 216, 212, 208, 204, 200, 196, 192, 188, 184, 180, 176, 172, 168, 164, 160, 156,
    152, 148, 144, 140, 136, 132, 128, 124, 120, 116, 112, 108, 104, 100, 96, 92, 88, 84, 80, 76,
    72, 68, 64, 60, 56, 52, 48, 44, 40, 36, 32, 28, 24, 20, 16, 12, 8, 0, 0]

const bits_precision = 128
const FloatType = Float64

const default_center= Complex{FloatType}(0.5, 0.0)
const default_range= Complex{FloatType}(-2.0, 2.0)
 
export Mandel, FloatType, default_center, default_range, new_mandel, update, gen_image_st!, gen_image_mt!, write_png, toRGB

mutable struct Mandel{T <: Real}
    w::Int
    h::Int
    iters::Int
    size::Int

    center::Complex{T}
    range::Complex{T}
    cr::Complex{T}
    rir::T
    scale::T

    image::Vector{UInt32}
    lap::Millisecond
    nthreads::Int
end

function new_mandel(w::Int, h::Int, iters::Int, center::Complex{FloatType}=default_center, range::Complex{FloatType}=default_range)::Mandel
    m = Mandel{FloatType}(w, h, iters, w * h, center, range, Complex(range.re, range.re), range.im - range.re, 0.8 * w / h, fill(UInt32(0xff000000), w * h), Millisecond(0), Threads.nthreads())
    gen_image_mt!(m)
    return m
end

function update(m::Mandel)
    m.cr = Complex(m.range.re, m.range.re)
    m.rir = m.range.im - m.range.re
    m.scale = 0.8 * m.w / m.h
end

function do_scale(m::Mandel, iw::Int, jh::Int)::Complex{FloatType}
    c00 = m.cr + complex(m.rir * iw / m.w, m.rir * jh / m.h)
    return complex(c00.re * m.scale - m.center.re, c00.im * m.scale - m.center.im)
end

function gen_pixel(m::Mandel, index::Int)
    c0 = do_scale(m, index % m.w, index ÷ m.w)

    z = c0
    i = 0

    function dist(z::Complex{FloatType})::FloatType
        return z.re*z.re + z.im*z.im
    end

    while i < m.iters && dist(z) < 4.0
        z = z * z + c0
        i += 1
    end

    if i != m.iters
        m.image[index+1] |= fire_pallete_256[(i<<2)%length(fire_pallete_256)+1]
    end
end
function gen_image_st!(m::Mandel)
    t0 = Dates.now()
    for index in 0:m.size-1
        gen_pixel(m, index)
    end
    m.lap = Dates.now() - t0
end

function gen_image_mt!(m::Mandel)
    m.image = fill(UInt32(0xff000000), m.size)
    t0 = Dates.now()
    @threads for index in 0:m.size-1
        gen_pixel(m, index)
    end
    m.lap = Dates.now() - t0
end


function write_image(m::Mandel)
    m.image = fill(UInt32(0xff000000), m.size)
    open("image.bin", "w") do f
        write(f, m.image)
    end
end

function toRGB(m::Mandel)

    # Create RGB image
    img = Array{RGB{N0f8}}(undef, m.h, m.w)

    for i in 1:length(m.image)
        # Extract RGB components from UInt32 (assuming RGBA format: 0xAABBGGRR)
        pixel = m.image[i]
        r = UInt8((pixel >> 0) & 0xFF)
        g = UInt8((pixel >> 8) & 0xFF)
        b = UInt8((pixel >> 16) & 0xFF)
        # a = UInt8((pixel >> 24) & 0xFF)  # Alpha channel if needed

        # Convert to image coordinates
        row = (i - 1) ÷ m.w + 1
        col = (i - 1) % m.w + 1

        img[row, col] = RGB{N0f8}(r / 255, g / 255, b / 255)
    end

    return img
end

function write_png(m::Mandel, name::String)
    Images.save(name, toRGB(m))
end

    using Profile
    function test_mandel()
        w = 1024
        h = 1024
        iters = 200
    
        center = Complex(0.5, 0.0)
        range = Complex(-2.0, 2.0)
    
        println("mandelbrot fractal generator, with $(Threads.nthreads()) threads, size: $(w)x$(h)=$(w*h), iters: $(iters)")
    
        mandel = new_mandel(w, h, iters, center, range)
    
        print("single threaded:")
        @time gen_image_st!(mandel)
        print("multi  threaded:")
        @time gen_image_mt!(mandel)
    
        write_png(mandel, "mandel.png")
    end
    
#    test_mandel()
#    @profile test_mandel()
#    Profile.print()
end
