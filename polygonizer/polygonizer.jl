# polygonizer wrapper

using StaticArrays

# Julia struct mirroring Nim's Vertex, they CAN'T be mutable
struct Point3d
    x::Cfloat
    y::Cfloat
    z::Cfloat
end

struct Vertex
    pos::Point3d
    norm::Point3d
    uv::Point3d
    color::Point3d
end

# Julia struct mirroring Nim's Trig (assuming cint is int32)
struct Trig
    t :: SVector{3,Cuint}
end

const LIB_PATH = "./libpolygonizer.so"
# nim wrapper
const FNAME_NEW_POLYGONIZER_NIM = :new_polygonizer_nim
const FNAME_FREE_POLYGONIZER_NIM = :free_polygonizer_nim

# implicit functions
# Sphere, Blob, NordstarndWeird, DecoCube, Cassini, Orth, Orth3, 
# Pretzel, Tooth, Pilz, Bretzel , BarthDecic, Clebsch0, Clebsch,
# Chubs, Chair, Roman, TangleCube, Goursat, Sinxyz

const SPHERE = cglobal((:Sphere, LIB_PATH))
const NORDSTARNDWEIRD = cglobal((:NordstarndWeird, LIB_PATH))
const DECOCUBE = cglobal((:DecoCube, LIB_PATH))
const CASSINI = cglobal((:Cassini, LIB_PATH))
const ORTH = cglobal((:Orth, LIB_PATH))
const ORTH3 = cglobal((:Orth3, LIB_PATH))
const PRETZEL = cglobal((:Pretzel, LIB_PATH))
const TOOTH = cglobal((:Tooth, LIB_PATH))
const PILZ = cglobal((:Pilz, LIB_PATH))
const BRETZEL = cglobal((:Bretzel, LIB_PATH))
const BARTHDECIC = cglobal((:BarthDecic, LIB_PATH))
const CLEBSCH0 = cglobal((:Clebsch0, LIB_PATH))
const CLEBSCH = cglobal((:Clebsch, LIB_PATH))
const CHUBS = cglobal((:Chubs, LIB_PATH))
const CHAIR = cglobal((:Chair, LIB_PATH))
const ROMAN = cglobal((:Roman, LIB_PATH))
const TANGLECUBE = cglobal((:TangleCube, LIB_PATH))
const GOURSAT = cglobal((:Goursat, LIB_PATH))
const SINXYZ = cglobal((:Sinxyz, LIB_PATH))

const ImplicitFuncs = [SPHERE, NORDSTARNDWEIRD, DECOCUBE, CASSINI, ORTH, ORTH3, PRETZEL, TOOTH, PILZ, BRETZEL, BARTHDECIC, CLEBSCH0, CLEBSCH, CHUBS, CHAIR, ROMAN, TANGLECUBE, GOURSAT, SINXYZ]


function polygonize(bounds::Float64, idiv::Int64, func::Ptr{Cvoid})::Tuple{Array{Vertex,1},Array{Trig,1}}
    n_vertexes_ref, n_triangles_ref = Ref{Cint}(0), Ref{Cint}(0)
    p_vertexes_ptr_ref, p_triangles_ptr_ref = Ref{Ptr{Vertex}}(C_NULL), Ref{Ptr{Trig}}(C_NULL)

    ccall((FNAME_NEW_POLYGONIZER_NIM, LIB_PATH),
        Cvoid,
        (Cfloat, Cint, Ptr{Cvoid}, # Bounds, Idiv, Callback
            Ptr{Cint}, Ptr{Cint},     # n_vertexes, n_triangles (by reference)
            Ptr{Ptr{Vertex}},         # p_vertexes (pointer to pointer to Vertex)
            Ptr{Ptr{Trig}}),          # p_triangles (pointer to pointer to Trig)
        Cfloat(bounds),
        Cint(idiv),
        func,
        n_vertexes_ref,
        n_triangles_ref,
        p_vertexes_ptr_ref,
        p_triangles_ptr_ref)

    n_vertexes = n_vertexes_ref[]
    n_triangles = n_triangles_ref[]

    vertex_ptr = p_vertexes_ptr_ref[]
    triangle_ptr = p_triangles_ptr_ref[]

    if vertex_ptr != C_NULL && n_vertexes > 0
        vertex = copy(unsafe_wrap(Vector{Vertex}, vertex_ptr, (n_vertexes,), own=false)) # make a copy
    else
        vertex = []
    end

    if triangle_ptr != C_NULL && n_triangles > 0
        triangle = copy(unsafe_wrap(Vector{Trig}, triangle_ptr, (n_triangles,), own=false)) # make a copy
        triangle = [Trig(t.t .+ Cuint(1)) for t in triangle] # +1 as julia array start on 1
    else
        triangle = []
    end

    # free nim values as we've copied the data
    ccall((FNAME_FREE_POLYGONIZER_NIM, LIB_PATH), Cvoid, (Ptr{Vertex}, Ptr{Vertex}), vertex_ptr, triangle_ptr)

    return (vertex, triangle)
end

function flatten_vertex_data(vertices::Vector{Vertex}, triangles::Vector{Trig})::Vector{Float32}
    v = Vector{Float32}(undef, 0)
    function add_vertex(v::Vector{Float32}, vertex::Vertex)
        function add_p3d(v::Vector{Float32}, p::Point3d)
            push!(v, p.x)
            push!(v, p.y)
            push!(v, p.z)
        end
        add_p3d(v, vertex.pos)
        add_p3d(v, vertex.color)
    end

    for t in triangles
        # add pos, color components for each vertex of the triangle
        for j in 1:3
            add_vertex(v, vertices[t.t[j]])
        end
    end
    return v
end

function test()
    bounds = 2.0
    idiv = 150

    for fn in ImplicitFuncs
        vertex, triangle = polygonize(bounds, idiv, fn)
        println("vertexes: ", size(vertex), " triangles: ", size(triangle))
        println(triangle[1], vertex[triangle[1].t[1]], vertex[triangle[1].t[2]], vertex[triangle[1].t[3]])
    end
end