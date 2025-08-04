push!(LOAD_PATH, "./")
using Waterman
using Dates

function test_gen_poly(rad::Float64)
    print("Generating poly with radius $rad: ")
    faces, coords = watermanPoly(rad)
    print("coords: $(length(coords)), faces: $(length(faces)), ")
    # println("coords: $(coords)")  
    # println("faces: $(faces)")

    errs = false
    for face in faces
        for ix in face
            if ix > length(coords) + 1
                errs = true
                break
            end
            c = coords[ix]
        end
    end
    if errs
        println("Error: Index out of bounds")
    else
        println("ok")
    end
end

function test_gen_mesh(rad::Float64)
    print("Generating mesh with radius $rad: ")
    t0 = now()

    faces, coords = watermanMesh(rad)
    
    print("coords: $(length(coords)), faces: $(length(faces)), ")
    # println("coords: $(coords)")  
    # println("faces: $(faces)")

    errs = false
    

    for face in faces
        for ix in face
            if ix > length(coords) + 1
                errs = true
                println("Error: Index out of bounds: $ix")
                break
            end
            c = coords[ix]
        end
    end
    if errs
        println("Error: Index out of bounds: $ix")
    else
        println("ok, lap: $(now() - t0)")
    end
end

for r in 15.0:100.0:8000.0
    test_gen_poly(r)
    test_gen_mesh(r)
end
