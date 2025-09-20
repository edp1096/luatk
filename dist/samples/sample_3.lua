local tk = require("luatk")
local app = tk.new()

local entry = app:entry{width = 20}
entry:pack{}

-- Initialize
entry:insert("0", "Hello World")

-- Read value by button
local button = app:button{
    text = "Get Text",
    command = function()
        local text = entry:get()
        print("Entry contains:", text)
    end
}
button:pack{}

-- Remove text from begin to end
local clear_button = app:button{
    text = "Clear",
    command = function()
        entry:delete("0", "end")
    end
}
clear_button:pack{}

app:mainloop()