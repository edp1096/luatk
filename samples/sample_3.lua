local tk = require("luatk")
local app = tk.new()
app:title("Graph with Axis Labels")
app:geometry(600, 400)

local canvas = app:canvas { width = 500, height = 350, bg = "white" }
canvas:pack { padx = 10, pady = 10 }

-- Graph area settings
local margin_left = 80
local margin_bottom = 50
local margin_top = 30
local margin_right = 30
local graph_width = 500 - margin_left - margin_right
local graph_height = 350 - margin_top - margin_bottom

-- Draw axes
canvas:create_line(margin_left, 350 - margin_bottom, 500 - margin_right, 350 - margin_bottom, { width = 2 }) -- X-axis
canvas:create_line(margin_left, margin_top, margin_left, 350 - margin_bottom, { width = 2 })         -- Y-axis

-- X-axis values (time, dates, etc.)
local x_labels = { "Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul" }
for i, label in ipairs(x_labels) do
    local x = margin_left + (i - 1) * (graph_width / (#x_labels - 1))

    -- Tick marks
    canvas:create_line(x, 350 - margin_bottom, x, 350 - margin_bottom + 5, { width = 1 })

    -- Label text
    canvas:create_text(x, 350 - margin_bottom + 15, label, { anchor = "n" })
end

-- Y-axis values (numbers)
local y_max = 100
local y_step = 20
for y = 0, y_max, y_step do
    local y_pos = (350 - margin_bottom) - (y / y_max) * graph_height

    -- Tick marks
    canvas:create_line(margin_left - 5, y_pos, margin_left, y_pos, { width = 1 })

    -- Label text
    canvas:create_text(margin_left - 10, y_pos, tostring(y), { anchor = "e" })
end

-- Data plot
local data = { 20, 45, 70, 55, 85, 60, 95 }
for i = 1, #data - 1 do
    local x1 = margin_left + (i - 1) * (graph_width / (#data - 1))
    local y1 = (350 - margin_bottom) - (data[i] / y_max) * graph_height
    local x2 = margin_left + i * (graph_width / (#data - 1))
    local y2 = (350 - margin_bottom) - (data[i + 1] / y_max) * graph_height

    canvas:create_line(x1, y1, x2, y2, { width = 3, fill = "blue" })
    canvas:create_oval(x1 - 3, y1 - 3, x1 + 3, y1 + 3, { fill = "red", outline = "darkred" })
end

-- Last point
local last_x = margin_left + (#data - 1) * (graph_width / (#data - 1))
local last_y = (350 - margin_bottom) - (data[#data] / y_max) * graph_height
canvas:create_oval(last_x - 3, last_y - 3, last_x + 3, last_y + 3, { fill = "red", outline = "darkred" })

-- Axis titles
canvas:create_text(250, 340, "Month", { font = "Arial 12 bold" })          -- X-axis title
canvas:create_text(20, 175, "Value", { font = "Arial 12 bold", angle = 90 }) -- Y-axis title (rotated)

app:mainloop()
