# ui dc DomainColoring

push!(LOAD_PATH, "./")

using Gtk4, Gtk4.GdkPixbufLib
using Images, FileIO, Colors
using Printf, Dates, Base.Threads

using DomainColoring
include("key_codes.jl")

const dc_w = 512 * 2 # dc size
const dc_h = 512 * 2
const tn_size = 200 # thumbnail size
const formulas_file = "formulas.txt"
const save_sizes = [256, 512, 1024, 2048, 4096, 8192, 16384]

# controls contained in UI
mutable struct UI
    dc::DC

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
    btn_load_formulas::GtkButton
    spin_complexity::GtkSpinButton
    cb_saved_sizes::GtkComboBoxText
    form_edit :: GtkEntry

    lap::Float64
    formulas::Vector{String}

    UI() = new()
end

function new_UI()
    ui = UI()
    ui.formulas = String[]
    return ui
end



# global ui object that contains all controls
const ui = Ref{UI}(new_UI())[]

function save_formulas()
    unique!(ui.formulas)
    open(formulas_file, "a") do io
        for f in ui.formulas
            println(io, f)
        end
    end
end

function load_formulas()
    open(formulas_file, "r") do io
        ui.formulas = [line for line in eachline(io)]
    end
    unique!(ui.formulas)

    for f in ui.formulas
        ui.dc = DC(tn_size, tn_size, f)

        gen_image_parallel!(ui.dc)
        if is_valid(ui.dc)
            add_to_list_box()
        end
    end
end

# dc adapted for gtk4
function uint32_to_pixbuf()
    itmp = reshape(reinterpret(UInt8, ui.dc.image), 4, ui.dc.h, ui.dc.w) # argb · h · w

    data = Array{GdkPixbufLib.RGB}(undef, ui.dc.h, ui.dc.w)

    for i in 1:ui.dc.h, j in 1:ui.dc.w
        data[i, j] = GdkPixbufLib.RGB(itmp[1, i, j], itmp[2, i, j], itmp[3, i, j])
    end

    GdkPixbuf(data)
end


function create_thumbnail_item()
    img = GtkImage(uint32_to_pixbuf())
    img.width_request, img.height_request = tn_size, tn_size

    item_box = GtkBox(:h, 10)
    push!(item_box, img)

    return item_box
end

function add_to_list_box()
    if is_valid(ui.dc)
        item_widget = create_thumbnail_item()
        row = GtkListBoxRow()
        row.child = item_widget
        # add to name dc params as string
        row.name = "dc,$(ui.dc.expression)"
        pushfirst!(ui.list_box, row) # add to top
    end
end

function update_sb()
    valid = is_valid(ui.dc)
    ui.sb.label = @sprintf("%s lap: %.2f ms | %d threads", valid ? "" : "[*]", ui.lap * 1000, Threads.nthreads())
    if valid
        push!(ui.formulas, ui.dc.expression)
        ui.form_edit.text = ui.dc.expression
    end
end

function disp_dc(add_tn::Bool=true)
    if check(ui.dc)
        ui.lap = @elapsed gen_image_parallel!(ui.dc)
        Gtk4.pixbuf(ui.pic, uint32_to_pixbuf())
        update_sb()
        if add_tn
            add_to_list_box()
        end
    end
end

function activate_app(app)

    ui.dc = DC(dc_w, dc_h, string(rand_expr(4)))
    if check(ui.dc)
        ui.lap = @elapsed gen_image_parallel!(ui.dc)
    end

    ui.win = GtkApplicationWindow(app, "domain coloring")

    # create controls
    ui.pic = GtkPicture(uint32_to_pixbuf()) #-- dc image
    ui.pic.width_request = dc_w
    ui.pic.height_request = dc_h

    ui.list_box = GtkListBox() #-- thumbnail dc list

    ui.toolbar = GtkBox(:h, 10) #---- tool bar

    ui.btn_reset = GtkButton("reset") #-- btn reset
    signal_connect(ui.btn_reset, "clicked") do widget
        ui.dc = DC(dc_w, dc_h, string(rand_expr(Int(ui.spin_complexity.value))))
        ui.list_box = GtkListBox() #-- empty thumbnail dc list
        ui.scrolled_window[] = ui.list_box
        disp_dc()
        ui.formulas = String[]
    end
    push!(ui.toolbar, ui.btn_reset)

    ui.btn_save = GtkButton("save") #-- btn save
    signal_connect(ui.btn_save, "clicked") do widget

        sz = save_sizes[ui.cb_saved_sizes.active+1]
        # println("saving $(sz) x $(sz): $(ui.dc.expression)")
        ui.dc = DC(sz, sz, ui.dc.expression)
        if check(ui.dc)
            gen_image_parallel!(ui.dc)
        end

        nf = 0 # find next index
        while isfile("dc$(nf).png")
            nf += 1
        end
        write_png(ui.dc, "dc$(nf).png")
    end
    ui.cb_saved_sizes = GtkComboBoxText() #-- cb saved resolutions
    for choice in save_sizes
        push!(ui.cb_saved_sizes, string(choice))
    end
    ui.cb_saved_sizes.active = 2

    ui.spin_complexity = GtkSpinButton(1:10) #-- complexity spin button
    ui.spin_complexity.value = 4
    signal_connect(ui.spin_complexity, "value-changed") do widget
        ui.dc = DC(dc_w, dc_h, string(rand_expr(Int(widget.value))))
        disp_dc(false)
    end

    ui.btn_load_formulas = GtkButton("load formulas") #-- btn load formulas
    signal_connect(ui.btn_load_formulas, "clicked") do widget
        load_formulas()
    end

    ui.form_edit = GtkEntry()
    ui.form_edit.text = ui.dc.expression
    ui.form_edit.width_request = 600
    signal_connect(ui.form_edit, "activate") do widget
        ui.dc = DC(dc_w, dc_h, ui.form_edit.text)
        disp_dc()
    end
    

    push!(ui.toolbar, ui.btn_save) #-- populate tb
    push!(ui.toolbar, GtkLabel("saved size: "))
    push!(ui.toolbar, ui.cb_saved_sizes)
    push!(ui.toolbar, GtkLabel("complexity: "))
    push!(ui.toolbar, ui.spin_complexity)
    push!(ui.toolbar, ui.btn_load_formulas)
    push!(ui.toolbar, ui.form_edit)

    ui.sb = GtkLabel("") #-- status bar


    update_sb()
    ui.click_gesture = GtkGestureClick(ui.pic) #-- click on pic

    ui.key_controller = GtkEventControllerKey() #-- key press
    push!(ui.win, ui.key_controller)

    add_to_list_box()

    ui.scrolled_window = GtkScrolledWindow() #-- scrollable list box with dc thumbnails
    ui.scrolled_window[] = ui.list_box

    ui.scrolled_window.width_request = 200
    ui.scrolled_window.height_request = dc_h ÷ 2

    signal_connect(ui.list_box, "row-selected") do widget, row
        items = split(row.name, ',') # ["dc", "expression"]
        if items[1] == "dc"
            ui.dc = DC(dc_w, dc_h, string(items[2]))
            disp_dc(false) # don't addd this thumbnail
        end
    end

    box_lb_img = GtkBox(:h, 10) #-- listbox + image
    push!(box_lb_img, ui.scrolled_window)
    push!(box_lb_img, ui.pic)

    vbox = GtkBox(:v, 10) #-- 3 hbox + sb

    push!(vbox, ui.toolbar)
    push!(vbox, box_lb_img)
    push!(vbox, ui.sb)

    push!(ui.win, vbox)

    #-- events
    signal_connect(ui.key_controller, "key-pressed") do controller, keyval, keycode, state
        # println("Key pressed: $(string(keyval, base=16)), keycode: $keycode, state: $state")

        # Handle specific keys      
        do_update = true

        if keyval == KEY_ESCAPE
            destroy(ui.win)
            return true
        elseif keyval == KEY_SPACE
            ui.dc = DC(dc_w, dc_h, string(rand_expr(Int(ui.spin_complexity.value))))
        else
            do_update = false
        end

        if do_update
            disp_dc(do_update)
        end

        return false  # Let event propagate if needed
    end

    signal_connect(ui.click_gesture, "pressed") do gesture, n_press, x, y
        ui.dc = DC(dc_w, dc_h, string(rand_expr(Int(ui.spin_complexity.value))))
        disp_dc()
        return false
    end

    show(ui.win)
end


# create & run app
app = GtkApplication("julia.gtk4.dc")
signal_connect(activate_app, app, :activate)
run(app)

# append formulas to formulas.txt
save_formulas()
