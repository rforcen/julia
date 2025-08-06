using GLFW
push!(LOAD_PATH, "./")
using Dates
using StaticArrays
include("gl.jl")

using Poly
using Transform


# global app struct
mutable struct App
    mouse_x::Float32
    mouse_y::Float32
    first_mouse::Bool
    is_mouse_dragging::Bool
    zoom::Float32

    window::GLFW.Window   
    lap::Millisecond

    App(mouse_x::Float32, mouse_y::Float32, first_mouse::Bool, is_mouse_dragging::Bool, zoom::Float32) = new(mouse_x, mouse_y, first_mouse, is_mouse_dragging, zoom)
end

const app = Ref{App}(App(0.0f0, 0.0f0, true, false, -4.0f0))[]

function gen_mesh_test() :: Polyhedron
    t0 = now()

    all_polys = plato_solids
    for j in johnson
        push!(all_polys, j)
    end

    p = new_polyhedron(rand(all_polys))
    optimize!(p)
    recalc!(p)
    
    app.lap = now() - t0
    return p
end

function gen_mesh(app::App, poly::Polyhedron) :: Polyhedron
    t0 = now()
   
    recalc!(p)
        
    app.lap = now() - t0
    return p
end

function ui(win_width=1024, win_height=1024, win_title="Polyhedronisme")
    # Initialize GLFW
    if !GLFW.Init()
        error("Failed to initialize GLFW")
    end

    app.window = GLFW.CreateWindow(win_width, win_height, win_title)
    if app.window === nothing
        GLFW.Terminate()
        error("Failed to create GLFW window")
    end

    GLFW.MakeContextCurrent(app.window)

    # event handling
    GLFW.SetKeyCallback(app.window, function (window::GLFW.Window, key::GLFW.Key, scancode::Cint, action::GLFW.Action, mods::Cint)
        keyPoly = Dict(
            GLFW.KEY_T => tetrahedron,
            GLFW.KEY_C => cube,
            GLFW.KEY_I => icosahedron,
            GLFW.KEY_O => octahedron,
            GLFW.KEY_D => dodecahedron,
            GLFW.KEY_J => johnson[rand(1:length(johnson))]
        )
        keyTrans = Dict(
            GLFW.KEY_K => kiss_n,
            GLFW.KEY_A => ambo,
            GLFW.KEY_Q => quinto,
            GLFW.KEY_H => hollow,
            GLFW.KEY_G => gyro,
            GLFW.KEY_P => propellor,
            GLFW.KEY_D => dual,
            GLFW.KEY_C => chamfer,
            GLFW.KEY_N => inset,
        )
        if action == GLFW.PRESS
            # println("Key pressed: $(key), mods: $(mods)")
            if key == GLFW.KEY_ESCAPE
                GLFW.SetWindowShouldClose(window, true)
                return
            elseif key == GLFW.KEY_SPACE
           
            elseif haskey(keyPoly, key) && mods == 1 # select polyhedron
                poly = keyPoly[key]     
            elseif haskey(keyTrans, key) && mods == 0 # transform polyhedron
                app.lap = now()

                poly = keyTrans[key](poly)
                
                app.lap = now() - app.lap
            end

            recalc!(poly)
            GLFW.SetWindowTitle(window, "Polyhedronisme, $(poly.name), lap : $(app.lap), faces : $(length(poly.faces)), vertexes : $(length(poly.vertexes)), colors : $(length(unique(poly.colors)))")
        end
    end)
    GLFW.SetMouseButtonCallback(app.window, function (window::GLFW.Window, button::GLFW.MouseButton, action::GLFW.Action, mods::Cint)
        if button == GLFW.MOUSE_BUTTON_LEFT
            if action == GLFW.PRESS
                app.is_mouse_dragging = true
            elseif action == GLFW.RELEASE
                app.is_mouse_dragging = false
                app.first_mouse = true # Reset first mouse flag on release
            end
        end
    end)
    GLFW.SetCursorPosCallback(app.window, function (window::GLFW.Window, xpos::Float64, ypos::Float64)
        if app.is_mouse_dragging
            app.mouse_x = xpos
            app.mouse_y = ypos
        end
    end)
    GLFW.SetScrollCallback(app.window, function (window::GLFW.Window, xoffset::Float64, yoffset::Float64)
        app.zoom += yoffset
    end)

    # generate waterman mesh
    poly = new_polyhedron(cube)

    #scene_init()
    glEnable(GL_DEPTH_TEST) # Enable depth testing for z-culling
	glDepthFunc(GL_LEQUAL) # Set the type of depth-test
	glShadeModel(GL_SMOOTH) # Enable smooth shading
	glHint(GL_PERSPECTIVE_CORRECTION_HINT, GL_NICEST) #  Nice perspective corrections

    while !GLFW.WindowShouldClose(app.window)
        # Render loop:
        setGeo(GLFW.GetWindowSize(app.window))

        glTranslatef(0.0f0, 0.0f0, app.zoom)
        glRotatef(GLfloat(app.mouse_x), 0.0f0, 1.0f0, 0.0f0)
        glRotatef(GLfloat(app.mouse_y), 1.0f0, 0.0f0, 0.0f0)

        # draw mesh
        for i in 1 : (length(poly.vertexes) < 300 ? 2 : 1)
            for (iface, face) in enumerate(poly.faces)
                glBegin([GL_POLYGON, GL_LINE_LOOP][i]) 

                color=[poly.colors[iface], SA_F64[1.0, 0.0, 0.0]][i]                               
                glColor3d(color.x, color.y, color.z)

                for ix in face
                    glVertex3d(poly.vertexes[ix].x, poly.vertexes[ix].y, poly.vertexes[ix].z)
                end

                glEnd()
            end      
        end

        # Swap front and back buffers
        GLFW.SwapBuffers(app.window)

        # Poll for and process events
        GLFW.PollEvents()
    end

    # --- Clean up ---
    GLFW.DestroyWindow(app.window)
    GLFW.Terminate()
end

ui(1200, 1200, "Polyhedronisme")