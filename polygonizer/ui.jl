using GLFW
include("gl.jl")
include("polygonizer.jl")

# global app struct
mutable struct App
    mouse_x::Float32
    mouse_y::Float32
    first_mouse::Bool
    is_mouse_dragging::Bool
    zoom::Float32

    window::GLFW.Window

    App(mouse_x::Float32, mouse_y::Float32, first_mouse::Bool, is_mouse_dragging::Bool, zoom::Float32) = new(mouse_x, mouse_y, first_mouse, is_mouse_dragging, zoom)
end

const app = Ref{App}(App(0.0f0, 0.0f0, true, false, -4.0f0))


function ui(win_width=1024, win_height=1024, win_title="Polygonizer", func=PRETZEL)
    # Initialize GLFW
    if !GLFW.Init()
        error("Failed to initialize GLFW")
    end

    app[].window = GLFW.CreateWindow(win_width, win_height, win_title)
    if app[].window === nothing
        GLFW.Terminate()
        error("Failed to create GLFW window")
    end

    GLFW.MakeContextCurrent(app[].window)

    # event handling
    GLFW.SetKeyCallback(app[].window, function (window::GLFW.Window, key::GLFW.Key, scancode::Cint, action::GLFW.Action, mods::Cint)
        if key == GLFW.KEY_ESCAPE && action == GLFW.PRESS
            GLFW.SetWindowShouldClose(window, true)
        elseif action == GLFW.PRESS
            println("Key pressed: $(key)")
        end
    end)
    GLFW.SetMouseButtonCallback(app[].window, function (window::GLFW.Window, button::GLFW.MouseButton, action::GLFW.Action, mods::Cint)
        if button == GLFW.MOUSE_BUTTON_LEFT
            if action == GLFW.PRESS
                app[].is_mouse_dragging = true
            elseif action == GLFW.RELEASE
                app[].is_mouse_dragging = false
                app[].first_mouse = true # Reset first mouse flag on release
            end
        end
    end)
    GLFW.SetCursorPosCallback(app[].window, function (window::GLFW.Window, xpos::Float64, ypos::Float64)
        if app[].is_mouse_dragging
            app[].mouse_x = xpos
            app[].mouse_y = ypos
        end
    end)
    GLFW.SetScrollCallback(app[].window, function (window::GLFW.Window, xoffset::Float64, yoffset::Float64)
        app[].zoom += yoffset
    end)

    # generate polygonized func
    vertexes, triangles = polygonize(3.5, 350, func)

    scene_init()

    while !GLFW.WindowShouldClose(app[].window)
        # Render loop:
        setGeo(GLFW.GetWindowSize(app[].window))

        glTranslatef(0.0f0, 0.0f0, app[].zoom)
        glRotatef(GLfloat(app[].mouse_x), 0.0f0, 1.0f0, 0.0f0)
        glRotatef(GLfloat(app[].mouse_y), 1.0f0, 0.0f0, 0.0f0)

        #draw_gl(vertex, triangle)
        glBegin(GL_TRIANGLES)
        for t in triangles
            function draw_p3d(v::Vertex)
                glColor3f(v.color.x, v.color.y, v.color.z)
                glNormal3f(v.norm.x, v.norm.y, v.norm.z)
                glVertex3f(v.pos.x, v.pos.y, v.pos.z)
            end
            for j in 1:3
                draw_p3d(vertexes[t.t[j]])
            end
        end
        glEnd()


        # Swap front and back buffers
        GLFW.SwapBuffers(app[].window)

        # Poll for and process events
        GLFW.PollEvents()
    end

    # --- Clean up ---
    GLFW.DestroyWindow(app[].window)
    GLFW.Terminate()
    println("GLFW terminated.")
end

ui(1200, 1200, "polygonizer", PRETZEL)