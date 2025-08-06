# flag transformation support

module Flags

push!(LOAD_PATH, "./")
using Poly
using StaticArrays

export Flag, VertexIndex, Int4
export i4_min, i4_min3
export set_vertexes, add_vertex, add_face, add_face_vect, reindex_vertexes, process_m_map, process_fcs, check, to_poly, create_poly, new_face_map

const Int4 = SVector{4,Int}
const VertexMap = Dict{Int4,Vertex}

mutable struct VertexIndex
    index::Int
    vertex::Vertex
end

function i4_min(i1::Int, i2::Int)::Int4
    return i1 < i2 ? convert(Int4, i1, i2) : convert(Int4, i2, i1)
end

function i4_min3(i::Int, v1::Int, v2::Int)::Int4
    return v1 < v2 ? convert(Int4, i, v1, v2) : convert(Int4, i, v2, v1)
end

#### Flag processing
mutable struct Flag
    vertexes::Vertexes
    faces::Faces

    fcs::Vector{Vector{Int4}}
    faceindex::Int
    valid::Bool

    facemap::Dict{Int4,VertexIndex}  # [Int4] VertexIndex
    m_map::Dict{Int4,Dict{Int4,Int4}} # [Int4] [Int4] Int4

    function Flag()
        return new([], [], [], 0, false, Dict{Int4,VertexIndex}(), Dict{Int4,Dict{Int4,Int4}}())
    end
end

function set_vertexes(f::Flag, vs::Vertexes)
    for (i, v) in enumerate(vs)
        add_vertex(f, convert(Int4, i), v)
    end
end

function add_vertex(f::Flag, ix::Int4, vtx::Vertex)
    f.facemap[ix] = VertexIndex(f.faceindex, vtx)
    f.faceindex += 1
end

function add_face(f::Flag, i0::Int4, i1::Int4, i2::Int4)
    if !haskey(f.m_map, i0) # init?
        f.m_map[i0] = Dict{Int4,Int4}()
    end

    f.m_map[i0][i1] = i2
end

function add_face_vect(f::Flag, v::Vector{Int4})
    push!(f.fcs, v)
end

function reindex_vertexes(f::Flag)
    f.vertexes = [v.vertex for (k, v) in f.facemap]
    for (i, (k, v)) in enumerate(f.facemap)
        v.index = i
    end
end

function process_m_map(f::Flag)::Bool
    max_iters = 100
    f.valid = true

    if !isempty(f.m_map)

        for (i, face) in f.m_map
            v0 = first(values(face)) # starting point
            v = v0

            # traverse m0
            face_tmp = Int[]

            for cnt in 0:max_iters
                push!(face_tmp, f.facemap[v].index)
                v = f.m_map[i][v]

                if v == v0 # found, closed loop
                    break
                end
            end
            if v != v0 # couldn't close loop -> invalid
                f.valid = false
                f.faces = Faces[]
                @warn "dead loop"
                return f.valid
            end
            push!(f.faces, face_tmp)
        end
    end
    return f.valid
end

function process_fcs(f::Flag)
    append!(f.faces, [[f.facemap[vix].index for vix in fc] for fc in f.fcs])
end

function check(f::Flag)
    for face in f.faces
        if length(face) < 3
            f.valid = false
            return
        end
        for iv in face
            if iv > length(f.vertexes)
                f.valid = false
                return
            end
        end
    end
end

function to_poly(f::Flag)::Bool
    reindex_vertexes(f) # and sort for lower_bound search
    if process_m_map(f)
        process_fcs(f)
        unique_faces!(f) # remove dupes preserving face order
        check(f)
    end
    return f.valid
end

function create_poly(f::Flag, tr::String, p::Polyhedron)::Polyhedron
    if !to_poly(f)
        return p
    end
    return optimize!(scale_unit(Polyhedron(tr * p.name, f.vertexes, f.faces)))
end

function unique_faces!(f::Flag) # remove dupes from f.faces in sorted comparison
    f.faces = unique!(face -> sort(collect(face)), f.faces)
end

function new_face_map(p::Polyhedron)::Dict{Int4,Int4}
    face_map = Dict{Int4,Int4}()
    for (i, face) in enumerate(p.faces)
        v1 = face[end]
        for v2 in face
            face_map[convert(Int4, v1, v2)] = convert(Int4, i)
            v1 = v2
        end
    end
    return face_map
end

##########################

## converters
Base.convert(::Type{Int}, s::String) = begin # int from string
    soi = sizeof(Int)
    return reinterpret(Int, Vector{UInt8}(length(s) < soi ? rpad(s, soi, '_') : s[1:min(end, soi)]))[1]
end

Base.convert(::Type{Int4}, i1::Int=-1, i2::Int=-1, i3::Int=-1, i4::Int=-1) = begin # int4 from 4 ints (-1 fill)
    return SA[i1, i2, i3, i4]
end


##########################

# test section
function test_index()
    println("-"^20)
    d = VertexMap()
    key = convert(Int4, convert(Int, "asda"), 1, 1, 1)
    value = SA_F64[10, 10, 10]

    key = convert(Int4, 1, 1, 1)
    key = convert(Int4, 1, 1)
    key = convert(Int4, 1)
    key = convert(Int4)


    println(haskey(d, key))
    d[key] = value
    println(haskey(d, key))
    println(d)
    println(d[key])
end

function test_su32()
    println("-"^20)
    s = "asdasd"
    while length(s) > 0
        println(convert(Int, s))
        s = s[2:end]
    end
end

function test_flags(p::Polyhedron)
    f = Flag()
    set_vertexes(f, p.vertexes)
    for (i, face) in enumerate(p.faces)
        add_face(f, convert(Int4, face[1]), convert(Int4, face[2]), convert(Int4, face[3]))
        add_face_vect(f, convert(Vector{Int4}, face))
        for v in face
            add_vertex(f, convert(Int4, v), p.vertexes[v])
        end
    end

    process_fcs(f)
    unique_faces!(f)
    check(f)

    f.faces = Vector{Face}(undef, 0)
    push!(f.faces, [4, 2, 3])
    push!(f.faces, [1, 2, 2])
    push!(f.faces, [3, 2, 1])
    for i in 1:3
        push!(f.faces, [1, 2, 3])
    end
    println(f.faces)
    unique_faces!(f)
    println(f.faces)
    return

    to_poly(f)

    println(f)
end


end