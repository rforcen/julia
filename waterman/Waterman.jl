# waterman poly mesh

module Waterman


export watermanMesh, watermanPoly, Point3d, cross, normalize, areas

const LIB_PATH = "./cpp/libwaterman.so"

# Point3d struct
struct Point3d
    x::Cdouble
    y::Cdouble
    z::Cdouble
end

import Base: -
function -(a::Point3d, b::Point3d)
    return Point3d(a.x - b.x, a.y - b.y, a.z - b.z)
end
import Base: +
function +(a::Point3d, b::Point3d)
    return Point3d(a.x + b.x, a.y + b.y, a.z + b.z)
end

function cross(a::Point3d, b::Point3d)
    return Point3d(a.y * b.z - a.z * b.y, a.z * b.x - a.x * b.z, a.x * b.y - a.y * b.x)
end

function dist(a::Point3d)
    return sqrt(a.x^2 + a.y^2 + a.z^2)
end
function normalize(a::Point3d)
    d = dist(a)
    return d != 0 ? Point3d(a.x / d, a.y / d, a.z / d) : a
end

function dot(a::Point3d, b::Point3d)
    return a.x * b.x + a.y * b.y + a.z * b.z
end

function normals(faces::Vector{Vector{Cint}}, vertexes::Vector{Point3d})::Vector{Point3d}
    normals = Vector{Point3d}(undef, length(faces))
    for (f, face) in enumerate(faces)
        normals[f] = normalize(cross(vertexes[face[2]] - vertexes[face[1]], vertexes[face[3]] - vertexes[face[1]]))
    end
    return normals
end

function areas(faces::Vector{Vector{Cint}}, vertexes::Vector{Point3d}, normals::Vector{Point3d})::Vector{Float64}
    areas = Vector{Float64}(undef, length(faces))
    for (f, face) in enumerate(faces)
        vsum = Point3d(0, 0, 0)
        fl = length(face)
        v1 = vertexes[face[fl-2+1]]
        v2 = vertexes[face[fl-1+1]]

        for v in face
            vsum += cross(v1, v2)
            v1, v2 = v2, vertexes[v]
        end
        areas[f] = abs(dot(normals[f], vsum)) / 2
    end
    return areas
end

function colors(faces::Vector{Vector{Cint}}, areas::Vector{Float64})::Vector{Point3d}
    function sigfigs(f::Float64, nsigs::Int)::Int
        mantissa = f / 10.0^(floor(log10(f)))
        return Int(floor(mantissa * 10.0^(nsigs - 1.0)))
    end

    colors = Vector{Point3d}(undef, length(faces))
    color_dict = Dict{Int,Point3d}()
    for (f, a) in enumerate(areas)
        sf = sigfigs(a, 3)
        if !(sf in keys(color_dict))
            color_dict[sf] = Point3d(rand(), rand(), rand())
        end
        colors[f] = color_dict[sf]
    end
    return colors
end
#######################

# void watermanPoly(double radius, int *_nfaces, int *_nvertexes, int **_faces, double **_vertexes) 
# void freeCH(int *_faces, double *_vertexes)

# Mesh *watermanMesh(double radius) 
# void freeMesh(Mesh *mesh)

const FNAME_WATERMAN_POLY = :watermanPoly
const FNAME_FREE_CH = :freeCH
const FNAME_WATERMAN_MESH = :watermanMesh
const FNAME_FREE_MESH = :freeMesh

struct Mesh # matches C struct Mesh
    n_faces::Cint
    n_vertexes::Cint # number of double items : 3 * n_Point3d vertexes
    faces::Ptr{Cint}
    vertexes::Ptr{Point3d}
end

function parse_faces(flat_faces::Vector{Cint})
    faces_vector = Vector{Vector{Cint}}()

    i = 1

    while i <= length(flat_faces)
        face_length = flat_faces[i]
        end_index = i + face_length
        current_face = flat_faces[i+1:end_index] .+ 1 # add 1 as julia array start on 1
        push!(faces_vector, current_face)

        i = end_index + 1
    end

    return faces_vector
end

function watermanMesh(radius::Float64)
    mesh_ref = ccall((FNAME_WATERMAN_MESH, LIB_PATH),
        Ptr{Mesh},
        (Cdouble,),
        Cdouble(radius)
    )

    mesh = unsafe_load(mesh_ref)

    coords = copy(unsafe_wrap(Vector{Point3d}, mesh.vertexes, (mesh.n_vertexes ÷ 3,), own=false))
    _faces = copy(unsafe_wrap(Vector{Cint}, mesh.faces, (mesh.n_faces,), own=false))

    faces = parse_faces(_faces)

    # release memory
    ccall((FNAME_FREE_MESH, LIB_PATH), Cvoid, (Ptr{Mesh},), mesh_ref)

    return faces, coords
end

function watermanPoly(radius::Float64)
    nfaces_ref = Ref{Cint}(0)
    nvertexes_ref = Ref{Cint}(0)
    faces_ref = Ref{Ptr{Cint}}(C_NULL)
    vertexes_ref = Ref{Ptr{Point3d}}(C_NULL)

    ccall((FNAME_WATERMAN_POLY, LIB_PATH),
        Cvoid,
        (Cdouble, Ptr{Cint}, Ptr{Cint}, Ptr{Ptr{Cint}}, Ptr{Ptr{Point3d}}),
        Cdouble(radius),
        nfaces_ref,
        nvertexes_ref,
        faces_ref,
        vertexes_ref)


    coords = copy(unsafe_wrap(Vector{Point3d}, vertexes_ref[], (nvertexes_ref[] ÷ 3,), own=false))
    _faces = copy(unsafe_wrap(Vector{Cint}, faces_ref[], (nfaces_ref[],), own=false))

    faces = parse_faces(_faces)

    # release memory
    ccall((FNAME_FREE_CH, LIB_PATH), Cvoid, (Ptr{Cint}, Ptr{Point3d}), faces_ref[], vertexes_ref[])

    return (faces, coords)
end

end # module Waterman
