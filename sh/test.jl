################# test
module test

push!(LOAD_PATH, "./")
using SHCodes
using Coords
using sh
using Dates
using Profile
using ColorMap

function test_codes()
    println(rand_code())

    rc = rand(1:length(shcodes))
    println(shcodes[rc])
    f=to_floatv(rc)
    println(f)
    i=to_intv(rc)

    println(i)
    i=convert(Vector{Int}, f)
    println(i)

end

function test_sh()
    calc_mesh(SH(16, 7, 123)) # warm up

    sh = SH(256*4, 7, 123)
    for i in 0:4
        println(calc_coord(sh, Float32(rand()), Float32(rand())))
    end
    println(calc_location(sh, 0, 0))
    
    t0 = now()
    calc_mesh(sh)
    println(now() - t0)

    println(sh.mesh[1])
    println(sh.mesh[end])
end

function prof()
    sh_ = SH(16, 9, rand(1:length(sh_codes))) # warm up JIT
    sh_ = SH(256*4, 9, rand(1:length(sh_codes))) # warm up JIT
    @profile calc_mesh(sh_)	
    Profile.print()
end

function test_slowest()
    c=findfirst(==(88888888), sh_codes)
    for cm in 1:max_color_map # test all color_maps
        sh = SH(16, cm, rand(1:length(sh_codes))) # warm up JIT
    end
    sh = SH(256*4, 9, c)
    t0=now()
    calc_mesh(sh)
    println(now() - t0)
end
# prof()


end

test.test_slowest()