-- sample_1.lua - Simple test with callbacks
local tk = require("luatk")

print("Loading LuaTk module... OK")

-- Create application
local app, err = tk.new()
if not app then
    print("Failed to create app:", err)
    return
end
print("Creating app... OK")

-- Set window properties
app:title("Simple Test with Callbacks")
app:geometry(400, 250)
print("Setting window properties... OK")

-- Try to create a simple frame
local frame, err = app:frame{bg = "lightblue"}
if not frame then
    print("Failed to create frame:", err)
    return
end
print("Creating frame... OK")

-- Try to pack it
frame:pack{fill = "both", expand = true, padx = 10, pady = 10}
print("Packing frame... OK")

-- Try to create a simple label
local label, err = app:label{
    text = "Hello World!\nClick the buttons below.",
    font = "Arial 12",
    justify = "center"
}
if not label then
    print("Failed to create label:", err)
    return
end
print("Creating label... OK")

label:pack{pady = 10}
print("Packing label... OK")

-- Create button frame
local button_frame = app:frame{bg = "lightblue"}
if button_frame then
    button_frame:pack{pady = 10}
    
    -- Create button with callback
    local click_count = 0
    local button1 = app:button{
        text = "Click Me!",
        bg = "lightgreen",
        width = 12,
        command = function()
            click_count = click_count + 1
            print("Button clicked! Count: " .. click_count)
            if label then
                label:configure{text = "Button clicked " .. click_count .. " times!"}
            end
        end
    }
    if button1 then
        button1:pack{side = "left", padx = 5}
    end
    
    -- Create exit button
    local exit_button = app:button{
        text = "Exit",
        bg = "lightcoral",
        width = 12,
        command = function()
            print("Exit button clicked - closing application")
            os.exit(0)
        end
    }
    if exit_button then
        exit_button:pack{side = "left", padx = 5}
    end
end

-- Create entry widget with callback
local entry_frame = app:frame{bg = "lightblue"}
if entry_frame then
    entry_frame:pack{fill = "x", padx = 10, pady = 5}
    
    local entry_label = app:label{text = "Enter text:"}
    if entry_label then
        entry_label:pack{side = "left"}
    end
    
    local text_entry = app:entry{width = 25, bg = "white"}
    if text_entry then
        text_entry:pack{side = "left", padx = 5}
    end
    
    local show_button = app:button{
        text = "Show",
        command = function()
            -- Note: In a real implementation, we'd need entry:get() method
            print("Show button clicked!")
            if label then
                label:configure{text = "Show button was clicked!"}
            end
        end
    }
    if show_button then
        show_button:pack{side = "left", padx = 5}
    end
end

print("All tests passed! Starting mainloop...")
print("Try clicking the buttons to see callbacks in action.")
print("Close the window to exit.")

-- Start the main event loop
app:mainloop()