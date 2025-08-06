module Transform

push!(LOAD_PATH, "./")
using Poly
using Flags
using LinearAlgebra

export kiss_n, ambo, quinto, hollow, gyro, propellor, dual, chamfer, inset


function kiss_n(p::Polyhedron, n::Int=0, apex_dist::Float64=0.1)::Polyhedron
    flag = Flag()

    normals!(p)
    centers!(p)

    f_ = convert(Int, "f___")

    for (nface, face) in enumerate(p.faces)
        v1 = face[end]
        fname = convert(Int4, f_, nface)

        for v2 in face
            iv2 = convert(Int4, v2)
            add_vertex(flag, iv2, p.vertexes[v2])

            if length(face) == n || n == 0
                add_vertex(flag, fname, p.centers[nface] + p.normals[nface] * apex_dist)
                add_face_vect(flag, [convert(Int4, v1), iv2, fname])
            else
                add_face(flag, convert(Int4, nface), convert(Int4, v1), iv2)
            end
            v1 = v2
        end
    end

    return create_poly(flag, "k", p)
end

function ambo(p::Polyhedron)::Polyhedron
    flag = Flag()

    dual_ = convert(Int, "dual")
    orig_ = convert(Int, "orig")

    for (iface, face) in enumerate(p.faces)
        v1 = face[end-1]
        v2 = face[end]

        f_orig = Vector{Int4}()

        for v3 in face
            m12 = i4_min(v1, v2)
            m23 = i4_min(v2, v3)

            if v1 < v2
                add_vertex(flag, m12, (p.vertexes[v1] + p.vertexes[v2]) / 2)
            end
            push!(f_orig, m12)

            add_face(flag, convert(Int4, orig_, iface), m12, m23)
            add_face(flag, convert(Int4, dual_, v2), m23, m12)

            v1, v2 = v2, v3
        end
        add_face_vect(flag, f_orig)
    end
    return create_poly(flag, "a", p)
end

function quinto(p::Polyhedron)::Polyhedron
    flag = Flag()
    centers = centers!(p)

    for (nface, face) in enumerate(p.faces)
        centroid = centers[nface]
        v1 = face[end-1]
        v2 = face[end]

        vi4 = Vector{Int4}(undef, 0)

        for v3 in face
            t12 = i4_min(v1, v2)
            ti12 = i4_min3(nface, v1, v2)
            t23 = i4_min(v2, v3)
            ti23 = i4_min3(nface, v2, v3)
            iv2 = convert(Int4, v2)

            midpt = (p.vertexes[v1] + p.vertexes[v2]) / 2
            innerpt = (midpt + centroid) / 2

            add_vertex(flag, t12, midpt)
            add_vertex(flag, ti12, innerpt)

            add_vertex(flag, iv2, p.vertexes[v2])

            add_face_vect(flag, [ti12, t12, iv2, t23, ti23])

            push!(vi4, ti12)

            v1, v2 = v2, v3
        end
        add_face_vect(flag, vi4)
    end
    return create_poly(flag, "q", p)
end


function hollow(p::Polyhedron, inset_dist::Float64=0.2, thickness::Float64=0.1)::Polyhedron
    flag = Flag()
    set_vertexes(flag, p.vertexes)

    avgnormals = avg_normals(p)
    centers = centers!(p)

    fin_ = convert(Int, "fin")
    fdwn_ = convert(Int, "fdwn")
    v_ = convert(Int, "v")

    for (i, face) in enumerate(p.faces)
        v1 = face[end]

        for v2 in face
            tw = tween(p.vertexes[v2], centers[i], inset_dist)

            add_vertex(flag, convert(Int4, fin_, i, v_, v2), tw)
            add_vertex(flag, convert(Int4, fdwn_, i, v_, v2), tw - (avgnormals[i] * thickness))

            add_face_vect(flag, [convert(Int4, v1), convert(Int4, v2), convert(Int4, fin_, i, v_, v2), convert(Int4, fin_, i, v_, v1)])
            add_face_vect(flag, [convert(Int4, fin_, i, v_, v1), convert(Int4, fin_, i, v_, v2), convert(Int4, fdwn_, i, v_, v2), convert(Int4, fdwn_, i, v_, v1)])

            v1 = v2
        end
    end

    return create_poly(flag, "h", p)
end

function gyro(p::Polyhedron)::Polyhedron
    cntr_ = convert(Int, "cntr")

    flag = Flag()
    set_vertexes(flag, p.vertexes)

    centers = centers!(p)

    for (i, face) in enumerate(p.faces)
        v1 = face[end-1]
        v2 = face[end]

        add_vertex(flag, convert(Int4, cntr_, i), normalize(centers[i]))

        for v3 in face
            add_vertex(flag, convert(Int4, v1, v2), one_third(p.vertexes[v1], p.vertexes[v2])) # new v in face

            # 5 new faces
            add_face_vect(flag, [convert(Int4, cntr_, i), convert(Int4, v1, v2), convert(Int4, v2, v1), convert(Int4, v2), convert(Int4, v2, v3)])

            # shift over one
            v1, v2 = v2, v3
        end
    end

    return create_poly(flag, "g", p)
end

function propellor(p::Polyhedron)::Polyhedron
    flag = Flag()
    set_vertexes(flag, p.vertexes)

    for (i, face) in enumerate(p.faces)
        v1 = face[end-1]
        v2 = face[end]

        for v3 in face
            add_vertex(flag, convert(Int4, v1, v2), one_third(p.vertexes[v1], p.vertexes[v2])) # new v in face, 1/3rd along edge

            add_face(flag, convert(Int4, i), convert(Int4, v1, v2), convert(Int4, v2, v3))
            add_face_vect(flag, [convert(Int4, v1, v2), convert(Int4, v2, v1), convert(Int4, v2), convert(Int4, v2, v3)])

            v1, v2 = v2, v3
        end
    end

    return create_poly(flag, "p", p)
end

function dual(p::Polyhedron)::Polyhedron
    flag = Flag()
    face_map = new_face_map(p)
    centers = centers!(p)

    for (i, face) in enumerate(p.faces)
        v1 = face[end]
        add_vertex(flag, convert(Int4, i), centers[i])

        for v2 in face
            add_face(flag, convert(Int4, v1), face_map[convert(Int4, v2, v1)], convert(Int4, i))
            v1 = v2
        end
    end

    return create_poly(flag, "d", p)
end

function chamfer(p::Polyhedron, dist::Float64=0.1)::Polyhedron
    orig_ = convert(Int, "orig")
    hex_ = convert(Int, "hex")

    flag = Flag()
    normals = normals!(p)

    for (i, face) in enumerate(p.faces)
		v1 = face[end]
		v1new = convert(Int4, i, v1)

		for v2 in face
			add_vertex(flag, convert(Int4, v2), p.vertexes[v2] * (1 + dist))
			# Add a new vertex, moved parallel to normal.
			v2new = convert(Int4, i, v2)

			add_vertex(flag, v2new, p.vertexes[v2] + normals[i] * (dist * 1.5))

			# Four new flags:
			# One whose face corresponds to the original face:
			add_face(flag, convert(Int4, orig_, i), v1new, v2new)

			# And three for the edges of the new hexagon:			
			facename = i4_min3(hex_, v1, v2)
			add_face(flag, facename, convert(Int4, v2), v2new)
			add_face(flag, facename, v2new, v1new)
			add_face(flag, facename, v1new, convert(Int4, v1))

			v1, v1new = v2, v2new
		end
	end
	return create_poly(flag, "c", p)
end

function inset(p::Polyhedron, n::Int=0, inset_dist::Float64=0.3, popout_dist::Float64=-0.1)::Polyhedron
	f_ = convert(Int, "f")
	ex_ = convert(Int, "ex")

	flag = Flag()
	set_vertexes(flag, p.vertexes)
	normals = normals!(p)
	centers = centers!(p)

	found_any = false
	for (i, face) in enumerate(p.faces)
		v1 = face[end]
		for v2 in face
			if length(face) == n || n == 0
				found_any = true

				add_vertex(flag, convert(Int4, f_, i, v2), tween(p.vertexes[v2], centers[i], inset_dist) + (normals[i] * popout_dist))
				add_face_vect(flag, [convert(Int4, v1), convert(Int4, v2), convert(Int4, f_, i, v2), convert(Int4, f_, i, v1)])
				# new inset, extruded face
				add_face(flag, convert(Int4, ex_, i), convert(Int4, f_, i, v1), convert(Int4, f_, i, v2))
			else
				add_face(flag, convert(Int4, i), convert(Int4, v1), convert(Int4, v2)) # same old flag, if non-n
			end

			v1 = v2
		end
	end
	if !found_any
		println("no $(n) components where found")
	end

	return create_poly(flag, "n", p)
end

### test
using Dates
function test()
    p = cube
    t0 = now()
    for i in 1:2
        p = inset(p)
    end
    println("$(p.name), faces:$(length(p.faces)), vertexes:$(length(p.vertexes))")
    println("lap: $(now() - t0)")
end

# test()
end
