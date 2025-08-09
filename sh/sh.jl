#!/home/asd/.juliaup/bin/julia
# Shperical Harmonics

module sh

export SH, calc_mesh, calc_location, scale_coords, generate_faces, calc_coord, write_obj

push!(LOAD_PATH, "./")
using SHCodes
using ColorMap
using Coords
using LinearAlgebra
using Base.Threads
using StaticArrays

const pi2 = 2.0f0 * pi
const Coord = Coords.Coord

mutable struct Location 
   coord::Coord
   normal::Coord
   color::Coord
   uv::Coord
end

mutable struct SH
    mesh    ::Vector{Location}
    faces   ::Vector{Vector{Int}}
    res     ::Int
    color_map ::Int
    size    ::Int
    code    ::Int
    m       ::SVector{8, Int}
    du      ::Float32
    dv      ::Float32
    du10    ::Float32
    dv10    ::Float32
    dx      ::Float32
    max_val ::Float32
    single_thread ::Bool

    function SH(res::Int, color_map::Int, code::Int)
		sh_=new()
		sh_.mesh = Vector{Location}(undef, res*res)
		sh_.faces = Vector{Vector{Int}}()
		sh_.res = res
		sh_.color_map = color_map
		sh_.size = res*res
		sh_.code = code
		sh_.m = SVector{8, Int}(to_intv(code))
		sh_.du = 2π/Float32(res)
		sh_.dv = Float32(π)/Float32(res)
		sh_.du10 = sh_.du/10.0f0
		sh_.dv10 = sh_.dv/10.0f0
		sh_.dx = 1.0f0/Float32(res)
		sh_.max_val = -1.0f0
		sh_.single_thread = false
        return sh_
    end
end

@fastmath function calc_coord(sh::SH, theta::Float32, phi::Float32) :: Coord
    sin_phi = sin(phi)
    @inbounds m_svector = sh.m

    @inbounds begin
        r = sin(m_svector[1] * phi)^m_svector[2]
        r += cos(m_svector[3] * phi)^m_svector[4]
        r += sin(m_svector[5] * theta)^m_svector[6]
        r += cos(m_svector[7] * theta)^m_svector[8]
    end

    Coord(r * sin_phi * cos(theta), 
          r * cos(phi), 
          r * sin_phi * sin(theta))
end

function calc_location(sh::SH, i::Int, j::Int) :: Location
	u = sh.du * i
	v = sh.dv * j

	idx = i * sh.dx
	jdx = j * sh.dx

	coord = calc_coord(sh, u, v)
	crd_up = calc_coord(sh, u + sh.du10, v)
	crd_right = calc_coord(sh, u, v + sh.dv10)

	sh.max_val = max(sh.max_val, max(abs(coord.x), abs(coord.y), abs(coord.z))) #  semaphored?

	Location(
		coord,
		Coords.normal(coord, crd_up, crd_right),
		color_map(u, 0.0f0, pi2, sh.color_map),
		Coord(idx, jdx, 0.0f0)
	)
end

function scale_coords(sh::SH)
	if sh.max_val != 0.0f0
		for i in 1:length(sh.mesh)
			sh.mesh[i].coord = sh.mesh[i].coord / sh.max_val
		end
	end
end

function generate_faces(sh::SH)
	n = sh.res
	sh.faces = Vector{Vector{Int}}()
	for i in 0:n-2
		for j in 0:n-2
			push!(sh.faces, [i * n + j, (i + 1) * n + j, (i + 1) * n + j + 1, i * n + j + 1] .+ 1)
		end
		push!(sh.faces, [i * n + (n - 1), (i + 1) * n + (n - 1), (i + 1) * n, i * n] .+ 1)
	end
end

function calc_mesh(sh::SH)
	@threads for i in 1:sh.size
		sh.mesh[i] = calc_location(sh, i % sh.res, div(i, sh.res))
	end	

    scale_coords(sh)
	generate_faces(sh)
end

function write_obj(sh::SH)
    open("$(sh.code).obj", "w") do f
		println(f,"# Spherical Harmonics, code:$(sh.code), res:$(sh.res), color_map:$(sh.color_map)")
        for loc in sh.mesh
            println(f, "v $(loc.coord.x) $(loc.coord.y) $(loc.coord.z) $(loc.color.x) $(loc.color.y) $(loc.color.z)")
			# println(f, "vn $(loc.normal.x) $(loc.normal.y) $(loc.normal.z)")
        end
       
        for face in sh.faces
			println(f, "f $(face[1]) $(face[2]) $(face[3]) $(face[4])")
        end
    end
end

function __init__()
    sh_ = SH(8, 9, rand(1:length(sh_codes))) # warm up JIT
    calc_mesh(sh_)	
end


end
