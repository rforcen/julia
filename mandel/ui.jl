# ui for mandelbrot fractals

push!(LOAD_PATH, "./")

using Gtk4, Gtk4.GdkPixbufLib
using Images, FileIO, Colors
using Printf
using Mandelbrot
include("key_codes.jl")

const mandel_w = 512 * 2 # fractal size
const mandel_h = 512 * 2
const mandel_iters = 200 # fractal iterations
const speed_move = 100 # fractal move speed

const save_sizes = [256, 512, 1024, 2048, 4096, 8192, 16384]

# controls contained in UI
mutable struct UI
    mandel::Mandel
    
    win::GtkApplicationWindow
    click_gesture::GtkGestureClick
    key_controller::GtkEventControllerKey
    pic::GtkPicture
    list_box::GtkListBox
    toolbar::GtkBox
    sb::GtkLabel
    scrolled_window::GtkScrolledWindow
    btn_reset::GtkButton
    btn_save::GtkButton
    cb_saved_sizes::GtkComboBoxText
    spin_iters::GtkSpinButton

    UI() = new()
end

# global ui object that contains all controls
const ui = Ref{UI}(UI())[]

# mandel adapted for gtk4
function uint32_to_pixbuf()
    itmp = reshape(reinterpret(UInt8, ui.mandel.image), 4, ui.mandel.h, ui.mandel.w) # argb · h · w

    data = Array{GdkPixbufLib.RGB}(undef, ui.mandel.h, ui.mandel.w)

    for i in 1:ui.mandel.h, j in 1:ui.mandel.w
        data[i, j] = GdkPixbufLib.RGB(itmp[1, i, j], itmp[2, i, j], itmp[3, i, j])
    end

    GdkPixbuf(data)
end

function recalculate_mandel(x, y)
    w, h = FloatType(ui.mandel.w), FloatType(ui.mandel.h)
    dist = FloatType(w / 2)
    rx = dist / w
    ry = dist / h
    ratio = abs(ui.mandel.range)

    ui.mandel.center += Complex(ratio * (w / 2 - x) / w, ratio * (h / 2 - y) / h)
    ui.mandel.range = Complex(ui.mandel.range.re * rx, ui.mandel.range.im * ry)

    update(ui.mandel)
end

function create_thumbnail_item()
    img = GtkImage(uint32_to_pixbuf())
    img.width_request, img.height_request = 200, 200

    item_box = GtkBox(:h, 10)
    push!(item_box, img)

    return item_box
end

function add_to_list_box()
    item_widget = create_thumbnail_item()
    row = GtkListBoxRow()
    row.child = item_widget
    # add to name mandel params as string
    row.name = "mandel,$(ui.mandel.iters),$(ui.mandel.center),$(ui.mandel.range)"
    pushfirst!(ui.list_box, row) # add to top
end

function update_sb()
    ui.sb.label = @sprintf("lap: %s | %d threads | center: (%.2e, %.2e) | range: (%.2e, %.2e) | iters: %d | scale %.2e", ui.mandel.lap, ui.mandel.nthreads, ui.mandel.center.re, ui.mandel.center.im, ui.mandel.range.re, ui.mandel.range.im, ui.mandel.iters, abs(ui.mandel.range))
    #Gtk4.justify(ui.sb, Gtk4.Justification_LEFT)
    ui.sb.justify = 1 # Gtk4.Justification_LEFT
end

function disp_mandel(add_tn::Bool=true)
    gen_image_mt!(ui.mandel)
    Gtk4.pixbuf(ui.pic, uint32_to_pixbuf())
    update_sb()
    if add_tn
        add_to_list_box()
    end
end

function activate_app(app)
    ui.mandel = new_mandel(mandel_w, mandel_h, mandel_iters)

    ui.win = GtkApplicationWindow(app, "mandelbrot fractals")

    # create controls
    ui.pic = GtkPicture(uint32_to_pixbuf()) #-- fractal image
    ui.pic.width_request = mandel_w
    ui.pic.height_request = mandel_h

    ui.list_box = GtkListBox() #-- thumbnail fractal list

    ui.toolbar = GtkBox(:h, 10) #---- tool bar

    ui.btn_reset = GtkButton("reset") #----- btn reset
    signal_connect(ui.btn_reset, "clicked") do widget
        ui.mandel = new_mandel(mandel_w, mandel_h, mandel_iters)
        ui.list_box = GtkListBox() #-- empty thumbnail fractal list
        ui.scrolled_window[] = ui.list_box
        disp_mandel()
    end
    push!(ui.toolbar, ui.btn_reset)

    ui.btn_save = GtkButton("save") # ----- btn save
    signal_connect(ui.btn_save, "clicked") do widget
        
        sz = save_sizes[ui.cb_saved_sizes.active+1]
        ui.mandel = new_mandel(sz, sz, ui.mandel.iters, ui.mandel.center, ui.mandel.range)
        nf=0
        while isfile("mandel$(nf).png")
            nf += 1
        end
        write_png(ui.mandel, "mandel$(nf).png")
    end
    ui.cb_saved_sizes = GtkComboBoxText() #-- cb saved resolutions
    for choice in save_sizes
        push!(ui.cb_saved_sizes, string(choice))
    end
    ui.cb_saved_sizes.active = 2

    
    push!(ui.toolbar, ui.btn_save) # populate tb
    push!(ui.toolbar, GtkLabel("saved size: "))
    push!(ui.toolbar, ui.cb_saved_sizes)

    # push!(ui.toolbar, GtkSeparator(:v))
    push!(ui.toolbar, GtkLabel("iters: "))
    ui.spin_iters = GtkSpinButton(50:50:5000)
    signal_connect(ui.spin_iters, "value-changed") do widget
        ui.mandel.iters = widget.value
        disp_mandel(false)
    end
    push!(ui.toolbar, ui.spin_iters)

    ui.sb = GtkLabel("") # ----- status bar

    update_sb()
    ui.click_gesture = GtkGestureClick(ui.pic) # click on pic

    ui.key_controller = GtkEventControllerKey() # key press
    push!(ui.win, ui.key_controller)

    add_to_list_box()

    ui.scrolled_window = GtkScrolledWindow() # scrollable list box with fractal thumbnails
    ui.scrolled_window[] = ui.list_box

    ui.scrolled_window.width_request = 200
    ui.scrolled_window.height_request = mandel_h ÷ 2

    signal_connect(ui.list_box, "row-selected") do widget, row
        items = split(row.name, ',') # ["mandel", "iters", "center", "range"]
        if items[1] == "mandel"
            ui.mandel.iters = parse(Int, items[2])
            ui.mandel.center = parse(Complex{FloatType}, items[3])
            ui.mandel.range = parse(Complex{FloatType}, items[4])
            update(ui.mandel)
            disp_mandel(false) # don't addd this thumbnail
        end
    end

    box_lb_img = GtkBox(:h, 10) # listbox + image
    push!(box_lb_img, ui.scrolled_window)
    push!(box_lb_img, ui.pic)

    vbox = GtkBox(:v, 10) # 3 hbox + sb

    push!(vbox, ui.toolbar)
    push!(vbox, box_lb_img)
    push!(vbox, ui.sb)

    push!(ui.win, vbox)

    # events
    signal_connect(ui.key_controller, "key-pressed") do controller, keyval, keycode, state
        # println("Key pressed: $(string(keyval, base=16)), keycode: $keycode, state: $state")

        # Handle specific keys      
        do_update = true

        if keyval == KEY_ESCAPE
            destroy(ui.win)
            return true
        elseif keyval == KEY_PLUS
            ui.mandel.iters += 50
        elseif keyval == KEY_MINUS
            ui.mandel.iters -= 50
            if ui.mandel.iters < 100
                ui.mandel.iters = 100
            end
        elseif keyval == KEY_UP
            ui.mandel.center -= Complex{FloatType}(0.0, abs(ui.mandel.range)/speed_move)
        elseif keyval == KEY_DOWN
            ui.mandel.center += Complex{FloatType}(0.0, abs(ui.mandel.range)/speed_move)
        elseif keyval == KEY_LEFT
            ui.mandel.center -= Complex{FloatType}(abs(ui.mandel.range)/speed_move, 0.0)
        elseif keyval == KEY_RIGHT
            ui.mandel.center += Complex{FloatType}(abs(ui.mandel.range)/speed_move, 0.0)
        elseif keyval == KEY_PAGE_DOWN
            ui.mandel.range *= 2.0
        elseif keyval == KEY_PAGE_UP
            ui.mandel.range /= 2.0
        elseif keyval == KEY_HOME
            ui.mandel = new_mandel(mandel_w, mandel_h, mandel_iters)
        else
            do_update = false
        end

        if do_update
            update(ui.mandel)
            disp_mandel(false)
        end

        return false  # Let event propagate if needed
    end

    signal_connect(ui.click_gesture, "pressed") do gesture, n_press, x, y
        recalculate_mandel(x, y)
        disp_mandel()
        return false
    end

    show(ui.win)
end

# create & run app
app = GtkApplication("julia.gtk4.mandelbrot")
signal_connect(activate_app, app, :activate)
run(app)
