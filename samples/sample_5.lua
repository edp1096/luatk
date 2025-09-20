local tk = require("luatk")
local app = tk.new()
app:title("Pie Chart Example")
app:geometry(600, 500)

local canvas = app:canvas { width = 500, height = 450, bg = "white" }
canvas:pack { padx = 10, pady = 10 }

-- Pie chart data
local pie_data = { 30, 25, 20, 15, 10 }
local pie_labels = { "Category A", "Category B", "Category C", "Category D", "Category E" }
local pie_colors = { "red", "blue", "green", "orange", "purple" }

-- Chart settings
local center_x = 200
local center_y = 200
local radius = 120

-- Calculate total for percentage calculation
local total = 0
for _, value in ipairs(pie_data) do
    total = total + value
end

-- Draw pie chart
local start_angle = 0
for i, value in ipairs(pie_data) do
    local angle = (value / total) * 360
    local end_angle = start_angle + angle

    -- Approximate sectors with triangles
    local steps = math.max(8, math.floor(angle / 5))
    for step = 0, steps - 1 do
        local a1 = math.rad(start_angle + step * angle / steps)
        local a2 = math.rad(start_angle + (step + 1) * angle / steps)

        local x1 = center_x + radius * math.cos(a1)
        local y1 = center_y + radius * math.sin(a1)
        local x2 = center_x + radius * math.cos(a2)
        local y2 = center_y + radius * math.sin(a2)

        canvas:create_polygon(center_x, center_y, x1, y1, x2, y2, { fill = pie_colors[i], outline = pie_colors[i], width = 1 })
    end

    -- Draw labels outside the pie
    local label_angle = math.rad(start_angle + angle / 2)
    local label_x = center_x + (radius + 30) * math.cos(label_angle)
    local label_y = center_y + (radius + 30) * math.sin(label_angle)

    -- Label text with percentage
    local percentage = math.floor((value / total) * 100 + 0.5)
    local label_text = pie_labels[i] .. "\n" .. percentage .. "%"
    canvas:create_text(label_x, label_y, label_text, { anchor = "center", font = "Arial 10" })

    -- Draw line from pie to label
    local line_start_x = center_x + radius * math.cos(label_angle)
    local line_start_y = center_y + radius * math.sin(label_angle)
    local line_end_x = center_x + (radius + 20) * math.cos(label_angle)
    local line_end_y = center_y + (radius + 20) * math.sin(label_angle)
    canvas:create_line(line_start_x, line_start_y, line_end_x, line_end_y, { width = 1, fill = "gray" })

    start_angle = end_angle
end

-- Draw title
canvas:create_text(center_x, 50, "Sales by Category", { font = "Arial 16 bold", anchor = "center" })

-- Draw legend
local legend_x = 400
local legend_y = 120
canvas:create_text(legend_x, legend_y - 20, "Legend:", { font = "Arial 12 bold", anchor = "w" })

for i, label in ipairs(pie_labels) do
    local y = legend_y + (i - 1) * 25

    -- Color box
    canvas:create_rectangle(legend_x, y - 8, legend_x + 15, y + 8, { fill = pie_colors[i], outline = "black" })

    -- Label text
    local percentage = math.floor((pie_data[i] / total) * 100 + 0.5)
    canvas:create_text(legend_x + 20, y, label .. " (" .. percentage .. "%)", { anchor = "w", font = "Arial 10" })
end

-- Draw border around pie chart
canvas:create_oval(center_x - radius - 5, center_y - radius - 5,
    center_x + radius + 5, center_y + radius + 5, { outline = "black", width = 2 })

app:mainloop()
