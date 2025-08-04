using GLFW
push!(LOAD_PATH, "./")
using Waterman
using Dates
include("gl.jl")


# global app struct
mutable struct App
    mouse_x::Float32
    mouse_y::Float32
    first_mouse::Bool
    is_mouse_dragging::Bool
    zoom::Float32
    radius::Float64

    window::GLFW.Window   
    lap::Millisecond

    App(mouse_x::Float32, mouse_y::Float32, first_mouse::Bool, is_mouse_dragging::Bool, zoom::Float32, radius::Float64) = new(mouse_x, mouse_y, first_mouse, is_mouse_dragging, zoom, radius)
end

const app = Ref{App}(App(0.0f0, 0.0f0, true, false, -4.0f0, 15.0))[]

function gen_mesh(rad :: Float64)
    app.radius = rad
    t0 = now()

    faces, vertexes = watermanMesh(rad)

    normals = Waterman.normals(faces, vertexes)
    areas = Waterman.areas(faces, vertexes, normals)
    colors = Waterman.colors(faces, areas)
    
    app.lap = now() - t0
    return faces, vertexes, normals, colors
end

function ui(win_width=1024, win_height=1024, win_title="Waterman")
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
        if action == GLFW.PRESS
            # println("Key pressed: $(key)")
            if key == GLFW.KEY_ESCAPE
                GLFW.SetWindowShouldClose(window, true)
                return
            elseif key == GLFW.KEY_UP   
                app.radius += 1
                
            elseif key == GLFW.KEY_DOWN
                app.radius -= 1
                if app.radius < 2
                    app.radius = 2
                end
            elseif key == GLFW.KEY_LEFT
                app.radius += 10
            elseif key == GLFW.KEY_RIGHT
                app.radius -= 10
                if app.radius < 2
                    app.radius = 2
                end
            elseif key == GLFW.KEY_PAGE_UP  
                app.radius += 100
            elseif key == GLFW.KEY_PAGE_DOWN
                app.radius -= 100
                if app.radius < 2
                    app.radius = 2000
                end
            elseif key == GLFW.KEY_SPACE
                app.radius = round(rand(2:20000))
            end

            # generate waterman mesh
            faces, vertexes, normals, colors = gen_mesh(app.radius)
            GLFW.SetWindowTitle(window, "Waterman, rad:$(app.radius), lap:$(app.lap), vertexes:$(length(vertexes)), faces:$(length(faces)), colors:$(length(unique(colors)))")

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
    faces, vertexes, normals, colors = gen_mesh(app.radius)

    # scene_init()
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
        
        for (iface, face) in enumerate(faces)
            glBegin(GL_POLYGON)
            
            glNormal3d(normals[iface].x, normals[iface].y, normals[iface].z)
            glColor3d(colors[iface].x, colors[iface].y, colors[iface].z)

            for ix in face
                glVertex3d(vertexes[ix].x, vertexes[ix].y, vertexes[ix].z)
            end
            glEnd()
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

ui(1200, 1200, "Waterman")