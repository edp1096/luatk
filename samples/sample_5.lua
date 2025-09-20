local tk = require("luatk")
local app = tk.new()
app:title("Bar Chart")
app:geometry(600, 400)

local canvas = app:canvas{width = 500, height = 350, bg = "white"}
canvas:pack{padx = 10, pady = 10}

-- Graph settings
local margin_left = 80
local margin_bottom = 50
local margin_top = 30
local margin_right = 30
local graph_width = 500 - margin_left - margin_right
local graph_height = 350 - margin_top - margin_bottom

-- Draw axes
canvas:create_line(margin_left, 350-margin_bottom, 500-margin_right, 350-margin_bottom, {width = 2})
canvas:create_line(margin_left, margin_top, margin_left, 350-margin_bottom, {width = 2})

-- Data for bar chart
local data = {20, 45, 70, 55, 85, 60, 95}
local labels = {"Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul"}
local colors = {"red", "blue", "green", "orange", "purple", "brown", "pink"}

local bar_width = graph_width / #data * 0.8
local bar_spacing = graph_width / #data

for i, value in ipairs(data) do
    local x = margin_left + (i-1) * bar_spacing + bar_spacing * 0.1
    local y = 350 - margin_bottom
    local height = (value / 100) * graph_height
    
    -- Draw bar
    canvas:create_rectangle(x, y - height, x + bar_width, y, {fill = colors[i], outline = "black"})
    
    -- Value label on top of bar
    canvas:create_text(x + bar_width/2, y - height - 5, tostring(value), {anchor = "s"})
    
    -- X-axis label
    canvas:create_text(x + bar_width/2, y + 15, labels[i], {anchor = "n"})
end

app:mainloop()