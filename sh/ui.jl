#!/home/asd/.juliaup/bin/julia --threads=auto -O3

using GLFW
push!(LOAD_PATH, "./")
using Dates
using StaticArrays
using LinearAlgebra
include("gl.jl")

using sh
using SHCodes


# global app struct
mutable struct App
    mouse_x::Float32
    mouse_y::Float32
    first_mouse::Bool
    is_mouse_dragging::Bool
    zoom::Float32

    sh_::SH
    code::Int
    res::Int
    color_map::Int

    lap::Millisecond
    window::GLFW.Window

    App(mouse_x::Float32, mouse_y::Float32, first_mouse::Bool, is_mouse_dragging::Bool, zoom::Float32, code::Int, res::Int, color_map::Int) = new(mouse_x, mouse_y, first_mouse, is_mouse_dragging, zoom, SH(res, color_map, code), code, res, color_map, Millisecond(0))
end

const app = Ref{App}(App(0.0f0, 0.0f0, true, false, -4.0f0, rand(1:length(sh_codes)), 256, 9))[]

function update_sh()
    app.sh_ = SH(app.res, app.color_map, app.code)
    app.lap = now()
    calc_mesh(app.sh_)
    app.lap = now() - app.lap
    update_title()
end

function update_title()
    GLFW.SetWindowTitle(app.window, "Spherical Harmonics, $(app.code), res : $(app.res), color_map : $(app.color_map), lap : $(app.lap)")
end

function ui(win_width=1024, win_height=1024, win_title="Spherical Harmonics")
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
            # println("Key pressed: $(key), mods: $(mods)")
            if key == GLFW.KEY_ESCAPE
                GLFW.SetWindowShouldClose(window, true)
                return
            elseif key == GLFW.KEY_T
                app.code = findfirst(==(88888888), sh_codes)
            elseif key == GLFW.KEY_W
                write_obj(app.sh_)
            elseif key == GLFW.KEY_SPACE
                app.code = rand(1:length(sh_codes))
            elseif key == GLFW.KEY_UP
                app.res *= 2
            elseif key == GLFW.KEY_DOWN
                app.res /= 2
            elseif key == GLFW.KEY_RIGHT
                app.color_map += 1
            elseif key == GLFW.KEY_LEFT
                app.color_map -= 1
            end
            update_sh()
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

    update_sh()
    scene_init()

    while !GLFW.WindowShouldClose(app.window)
        # Render loop:
        setGeo(GLFW.GetWindowSize(app.window))

        glTranslatef(0.0f0, 0.0f0, app.zoom)
        glRotatef(app.mouse_x, 0.0f0, 1.0f0, 0.0f0)
        glRotatef(app.mouse_y, 1.0f0, 0.0f0, 0.0f0)

        # draw mesh

        for face in app.sh_.faces
            glBegin(GL_QUADS)

            for ix in face
                loc = app.sh_.mesh[ix]

                glColor3f(loc.color.x, loc.color.y, loc.color.z)
                glNormal3f(loc.normal.x, loc.normal.y, loc.normal.z)
                glVertex3f(loc.coord.x, loc.coord.y, loc.coord.z)
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

ui(2048, 2048, "Spherical Harmonics")