-- sample_2.lua - Comprehensive demo with callbacks
local tk = require("luatk")

-- Helper function for safe widget creation
local function safe_create(widget_func, options, name)
    local widget, err = widget_func(options or {})
    if not widget then
        print("Failed to create " .. name .. ":", err)
        return nil
    end
    return widget
end

-- Create application
local app, err = tk.new()
if not app then
    print("Failed to create app:", err)
    return
end

-- Set window properties
app:title("LuaTk Demo Application with Callbacks")
app:geometry(700, 500)

-- Global status label for updates
local status_label = nil

-- Helper function to update status
local function update_status(message)
    if status_label then
        status_label:configure { text = "Status: " .. message }
    end
    print("Status: " .. message)
end

-- Create main frame
local main_frame = safe_create(function(opts) return app:frame(opts) end, {
    bg = "lightgray"
}, "main frame")
if not main_frame then return end

main_frame:pack { fill = "both", expand = true, padx = 10, pady = 10 }

-- Create title label
local title_label = safe_create(function(opts) return app:label(opts) end, {
    text = "Welcome to LuaTk with Callbacks!",
    font = "Arial 16 bold",
    fg = "blue"
}, "title label")
if not title_label then return end

title_label:pack { pady = 10 }

-- Create button frame for layout
local button_frame = safe_create(function(opts) return app:frame(opts) end, {
    bg = "lightgray"
}, "button frame")
if not button_frame then return end

button_frame:pack { fill = "x", pady = 10 }

-- Create buttons with callbacks
local button_click_count = 0
local button1 = safe_create(function(opts) return app:button(opts) end, {
    text = "Click Counter",
    bg = "lightblue",
    fg = "darkblue",
    width = 15,
    command = function()
        button_click_count = button_click_count + 1
        update_status("Button clicked " .. button_click_count .. " times")
        if title_label then
            title_label:configure { text = "Button clicked " .. button_click_count .. " times!" }
        end
    end
}, "button1")
if button1 then
    button1:pack { side = "left", padx = 5 }
end

local button2 = safe_create(function(opts) return app:ttk_button(opts) end, {
    text = "TTK Style",
    width = 15,
    command = function()
        update_status("TTK button clicked!")
        if title_label then
            title_label:configure { text = "TTK Button Works!", fg = "green" }
        end
    end
}, "ttk button")
if button2 then
    button2:pack { side = "left", padx = 5 }
end

-- Reset button
local reset_button = safe_create(function(opts) return app:button(opts) end, {
    text = "Reset",
    bg = "orange",
    command = function()
        button_click_count = 0
        update_status("Reset clicked - counter cleared")
        if title_label then
            title_label:configure { text = "Welcome to LuaTk with Callbacks!", fg = "blue" }
        end
    end
}, "reset button")
if reset_button then
    reset_button:pack { side = "left", padx = 5 }
end

-- Create checkbutton frame
local check_frame = safe_create(function(opts) return app:frame(opts) end, {
    bg = "lightgray"
}, "check frame")
if check_frame then
    check_frame:pack { fill = "x", pady = 10 }

    local check1 = safe_create(function(opts) return app:checkbutton(opts) end, {
        text = "Enable Feature A",
        bg = "lightgray",
        command = function()
            update_status("Feature A toggled")
        end
    }, "checkbutton 1")
    if check1 then
        check1:pack { side = "left", padx = 10 }
    end

    local check2 = safe_create(function(opts) return app:checkbutton(opts) end, {
        text = "Enable Feature B",
        bg = "lightgray",
        command = function()
            update_status("Feature B toggled")
        end
    }, "checkbutton 2")
    if check2 then
        check2:pack { side = "left", padx = 10 }
    end
end

-- Create radio button frame
local radio_frame = safe_create(function(opts) return app:frame(opts) end, {
    bg = "lightgray"
}, "radio frame")
if radio_frame then
    radio_frame:pack { fill = "x", pady = 10 }

    local radio1 = safe_create(function(opts) return app:radiobutton(opts) end, {
        text = "Option A",
        value = "A",
        bg = "lightgray",
        command = function()
            update_status("Selected Option A")
        end
    }, "radiobutton 1")
    if radio1 then
        radio1:pack { side = "left", padx = 10 }
    end

    local radio2 = safe_create(function(opts) return app:radiobutton(opts) end, {
        text = "Option B",
        value = "B",
        bg = "lightgray",
        command = function()
            update_status("Selected Option B")
        end
    }, "radiobutton 2")
    if radio2 then
        radio2:pack { side = "left", padx = 10 }
    end
end

-- Create menu button with callback
local menu_frame = safe_create(function(opts) return app:frame(opts) end, {
    bg = "lightgray"
}, "menu frame")
if menu_frame then
    menu_frame:pack { fill = "x", pady = 10 }

    local menubutton = safe_create(function(opts) return app:menubutton(opts) end, {
        text = "Menu Options",
        relief = "raised",
        bg = "lightcyan",
        command = function()
            update_status("Menu button clicked")
        end
    }, "menubutton")
    if menubutton then
        menubutton:pack { side = "left", padx = 10 }
    end
end

-- Create action buttons frame
local action_frame = safe_create(function(opts) return app:frame(opts) end, {
    bg = "white",
    relief = "solid",
    bd = 2
}, "action frame")
if action_frame then
    action_frame:pack { fill = "x", pady = 10, padx = 10 }

    local action_label = safe_create(function(opts) return app:label(opts) end, {
        text = "Quick Actions:",
        bg = "white",
        font = "Arial 12 bold"
    }, "action label")
    if action_label then
        action_label:pack { side = "left", padx = 5 }
    end

    local colors = { "red", "green", "blue", "yellow", "purple" }
    local color_index = 1

    local color_button = safe_create(function(opts) return app:button(opts) end, {
        text = "Change Color",
        bg = colors[color_index],
        command = function(color_button)
            color_index = color_index + 1
            if color_index > #colors then color_index = 1 end
            local new_color = colors[color_index]
            if color_button then
                color_button:configure { bg = new_color }
            end
            update_status("Changed color to " .. new_color)
        end
    }, "color button")
    if color_button then
        color_button:pack { side = "left", padx = 5 }
    end

    local info_button = safe_create(function(opts) return app:button(opts) end, {
        text = "Show Info",
        bg = "lightsteelblue",
        command = function()
            update_status("LuaTk Demo - All callbacks working!")
            if title_label then
                title_label:configure { text = "Callbacks are working perfectly!", fg = "purple" }
            end
        end
    }, "info button")
    if info_button then
        info_button:pack { side = "left", padx = 5 }
    end
end

-- Create exit button frame
local exit_frame = safe_create(function(opts) return app:frame(opts) end, {
    bg = "lightgray"
}, "exit frame")
if exit_frame then
    exit_frame:pack { side = "bottom", fill = "x", pady = 5 }

    local exit_button = safe_create(function(opts) return app:button(opts) end, {
        text = "Exit Application",
        bg = "lightcoral",
        fg = "darkred",
        font = "Arial 10 bold",
        command = function()
            update_status("Exiting application...")
            print("Exit button clicked - goodbye!")
            os.exit(0)
        end
    }, "exit button")
    if exit_button then
        exit_button:pack { side = "right", padx = 10 }
    end
end

-- Status bar (create this last so we can reference it)
local status_frame = safe_create(function(opts) return app:frame(opts) end, {
    bg = "lightgray",
    relief = "sunken",
    bd = 1
}, "status frame")
if status_frame then
    status_frame:pack { side = "bottom", fill = "x" }

    status_label = safe_create(function(opts) return app:label(opts) end, {
        text = "Ready - Click buttons to see callbacks in action!",
        bg = "lightgray",
        anchor = "w"
    }, "status label")
    if status_label then
        status_label:pack { side = "left", fill = "x", expand = true, padx = 5 }
    end
end

-- Create a text area for demonstration
local text_frame = safe_create(function(opts) return app:frame(opts) end, {
    bg = "lightgray"
}, "text frame")
if text_frame then
    text_frame:pack { fill = "both", expand = true, pady = 10 }

    local text_widget = safe_create(function(opts) return app:text(opts) end, {
        width = 60,
        height = 8,
        bg = "white",
        wrap = "word"
    }, "text widget")
    if text_widget then
        text_widget:pack { fill = "both", expand = true }
    end
end

print("LuaTk Demo: All widgets with callbacks created successfully!")
print("This demonstrates:")
print("  - Button callbacks with state management")
print("  - Checkbutton and radiobutton callbacks")
print("  - Dynamic widget configuration")
print("  - Status updates via callbacks")
print("  - Interactive color changing")
print("Try clicking various buttons to see the callbacks in action!")

-- Start the main event loop
app:mainloop()
