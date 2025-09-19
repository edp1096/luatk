Simply Tk support for Lua 5.4


## Usage

See files in [samples](samples) or [dist](dist) folder.
```lua
local tk = require("luatk")

local app = tk.new()
app:title("My App")
app:geometry(400, 300)

local button = app:button{
    text = "Click Me!",
    command = function(widget)
        print("Button clicked!")
        widget:configure{text = "Clicked!"}
    end
}
button:pack{padx = 10, pady = 10}

app:mainloop()
```


## Build and run sample

* Prequisites
    * Lua 5.4
    * Tcl/Tk
    * [MinGW](https://github.com/brechtsanders/winlibs_mingw)

* Windows
    ```powershell
    build.cmd
    cd dist
    .\run-sample1.ps1
    ```

* Linux - Not tested.
    ```sh
    sudo apt install tcl-dev tk-dev lua5.4-dev
    make dist
    cd dist && ./run-sample1.sh
    ```


## Windows Lua, TclTk binaries from

* [Lua](https://github.com/edp1096/my-lua-set/blob/main/install_lua.ps1)
* [TclTk](https://github.com/edp1096/tcltk)