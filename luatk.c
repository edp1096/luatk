// luatk.c - Core implementation for Lua-Tk binding
#include <lauxlib.h>
#include <lua.h>
#include <lualib.h>
#include <stdlib.h>
#include <string.h>
#include <tcl.h>
#include <tk.h>

#if defined(_WIN32) && (defined(_MSC_VER) || defined(__MINGW64__))
#define EXPORT __declspec(dllexport)
#else
#define EXPORT
#endif

#define LUATK_APP_META "LuaTk.App"
#define LUATK_WIDGET_META "LuaTk.Widget"

// Forward declarations
typedef struct LuaTkApp LuaTkApp;
typedef struct LuaTkWidget LuaTkWidget;

// Application structure
struct LuaTkApp {
    Tcl_Interp *interp;
    Tk_Window mainwin;
    int widget_counter;
    lua_State *L;
};

// Widget structure
struct LuaTkWidget {
    LuaTkApp *app;
    Tk_Window tkwin;
    char *widget_path;
    char *widget_type;
    int callback_ref;  // Reference to Lua callback function
    int self_ref;      // Reference to widget itself for passing to callbacks
};

// Helper function to get app from Lua stack
static LuaTkApp *luatk_checkapp(lua_State *L, int index) {
    return (LuaTkApp *)luaL_checkudata(L, index, LUATK_APP_META);
}

// Helper function to get widget from Lua stack
static LuaTkWidget *luatk_checkwidget(lua_State *L, int index) {
    return (LuaTkWidget *)luaL_checkudata(L, index, LUATK_WIDGET_META);
}

// Generate unique widget path
static char *generate_widget_path(LuaTkApp *app, const char *type) {
    char *path = malloc(64);
    snprintf(path, 64, ".luatk_%s_%d", type, app->widget_counter++);
    return path;
}

// Callback command handler
static int callback_command(ClientData clientData, Tcl_Interp *interp, int objc, Tcl_Obj *const objv[]) {
    (void)interp;
    (void)objc;
    (void)objv;  // Silence warnings

    LuaTkWidget *widget = (LuaTkWidget *)clientData;
    lua_State *L = widget->app->L;

    if (widget->callback_ref != LUA_NOREF) {
        lua_rawgeti(L, LUA_REGISTRYINDEX, widget->callback_ref);  // Push callback function

        if (lua_isfunction(L, -1)) {
            // Push widget as first parameter
            lua_rawgeti(L, LUA_REGISTRYINDEX, widget->self_ref);

            // Call function with widget as parameter
            if (lua_pcall(L, 1, 0, 0) != LUA_OK) {
                printf("Callback error: %s\n", lua_tostring(L, -1));
                lua_pop(L, 1);
            }
        } else {
            printf("Callback is not a function!\n");
            lua_pop(L, 1);
        }
    }
    return TCL_OK;
}

// Parse options table and build Tk configuration string
static void parse_options(lua_State *L, int table_index, char *config_buf, size_t buf_size, LuaTkWidget *widget) {
    config_buf[0] = '\0';

    if (!lua_istable(L, table_index)) {
        return;
    }

    lua_pushnil(L);
    while (lua_next(L, table_index) != 0) {
        if (lua_isstring(L, -2)) {
            const char *key = lua_tostring(L, -2);

            // Handle command callback
            if (widget && strcmp(key, "command") == 0 && lua_isfunction(L, -1)) {
                // Duplicate the function before storing it
                lua_pushvalue(L, -1);                                   // Copy function to top of stack
                widget->callback_ref = luaL_ref(L, LUA_REGISTRYINDEX);  // Store copy (pops copy)

                // Create unique Tcl command name
                char cmd_name[64];
                snprintf(cmd_name, sizeof(cmd_name), "luatk_callback_%p", widget);

                // Register Tcl command
                Tcl_CreateObjCommand(widget->app->interp, cmd_name, callback_command, widget, NULL);

                // Add to config string
                char cmd_option[128];
                snprintf(cmd_option, sizeof(cmd_option), " -command %s", cmd_name);
                strncat(config_buf, cmd_option, buf_size - strlen(config_buf) - 1);

                // Original function still on stack - will be popped by lua_pop(L, 1) below
            }
            // Handle different option types
            else if (lua_isstring(L, -1)) {
                const char *value = lua_tostring(L, -1);
                strncat(config_buf, " -", buf_size - strlen(config_buf) - 1);
                strncat(config_buf, key, buf_size - strlen(config_buf) - 1);
                strncat(config_buf, " {", buf_size - strlen(config_buf) - 1);
                strncat(config_buf, value, buf_size - strlen(config_buf) - 1);
                strncat(config_buf, "}", buf_size - strlen(config_buf) - 1);
            } else if (lua_isnumber(L, -1)) {
                double value = lua_tonumber(L, -1);
                char num_str[32];
                snprintf(num_str, sizeof(num_str), " -%s %.0f", key, value);
                strncat(config_buf, num_str, buf_size - strlen(config_buf) - 1);
            } else if (lua_isboolean(L, -1)) {
                int value = lua_toboolean(L, -1);
                char bool_str[32];
                snprintf(bool_str, sizeof(bool_str), " -%s %s", key, value ? "1" : "0");
                strncat(config_buf, bool_str, buf_size - strlen(config_buf) - 1);
            }
        }
        lua_pop(L, 1);  // Pop value, keep key for next iteration
    }
}

// Application methods
static int luatk_app_new(lua_State *L) {
    LuaTkApp *app = (LuaTkApp *)lua_newuserdata(L, sizeof(LuaTkApp));
    luaL_getmetatable(L, LUATK_APP_META);
    lua_setmetatable(L, -2);

    // Initialize Tcl/Tk
    app->interp = Tcl_CreateInterp();
    if (Tcl_Init(app->interp) != TCL_OK) {
        lua_pushnil(L);
        lua_pushstring(L, "Failed to initialize Tcl");
        return 2;
    }

    if (Tk_Init(app->interp) != TCL_OK) {
        lua_pushnil(L);
        lua_pushstring(L, "Failed to initialize Tk");
        return 2;
    }

    app->mainwin = Tk_MainWindow(app->interp);
    app->widget_counter = 1;
    app->L = L;

    return 1;
}

static int luatk_app_mainloop(lua_State *L) {
    luatk_checkapp(L, 1);
    Tk_MainLoop();
    return 0;
}

static int luatk_app_destroy(lua_State *L) {
    LuaTkApp *app = luatk_checkapp(L, 1);
    if (app->interp) {
        Tcl_DeleteInterp(app->interp);
        app->interp = NULL;
    }
    return 0;
}

static int luatk_app_title(lua_State *L) {
    LuaTkApp *app = luatk_checkapp(L, 1);
    const char *title = luaL_checkstring(L, 2);

    char cmd[512];
    snprintf(cmd, sizeof(cmd), "wm title . {%s}", title);
    Tcl_Eval(app->interp, cmd);

    return 0;
}

static int luatk_app_geometry(lua_State *L) {
    LuaTkApp *app = luatk_checkapp(L, 1);
    int width = luaL_checkinteger(L, 2);
    int height = luaL_checkinteger(L, 3);

    char cmd[128];
    snprintf(cmd, sizeof(cmd), "wm geometry . %dx%d", width, height);
    Tcl_Eval(app->interp, cmd);

    return 0;
}

// Widget creation methods
static int luatk_create_widget(lua_State *L, const char *widget_type) {
    LuaTkApp *app = luatk_checkapp(L, 1);

    LuaTkWidget *widget = (LuaTkWidget *)lua_newuserdata(L, sizeof(LuaTkWidget));
    luaL_getmetatable(L, LUATK_WIDGET_META);
    lua_setmetatable(L, -2);

    widget->app = app;
    widget->widget_path = generate_widget_path(app, widget_type);
    widget->widget_type = strdup(widget_type);
    widget->callback_ref = LUA_NOREF;
    widget->self_ref = LUA_NOREF;

    // Store reference to widget itself for callbacks
    lua_pushvalue(L, -1);                               // Duplicate widget userdata on stack
    widget->self_ref = luaL_ref(L, LUA_REGISTRYINDEX);  // Store reference and pop

    // Build Tk command
    char cmd[2048];
    char options[1024];

    parse_options(L, 2, options, sizeof(options), widget);
    snprintf(cmd, sizeof(cmd), "%s %s%s", widget_type, widget->widget_path, options);

    if (Tcl_Eval(app->interp, cmd) != TCL_OK) {
        if (widget->self_ref != LUA_NOREF) {
            luaL_unref(L, LUA_REGISTRYINDEX, widget->self_ref);
        }
        free(widget->widget_path);
        free(widget->widget_type);
        lua_pushnil(L);
        lua_pushstring(L, Tcl_GetStringResult(app->interp));
        return 2;
    }

    // Get the Tk window
    widget->tkwin = Tk_NameToWindow(app->interp, widget->widget_path, app->mainwin);

    return 1;
}

static int luatk_app_button(lua_State *L) {
    return luatk_create_widget(L, "button");
}

static int luatk_app_label(lua_State *L) {
    return luatk_create_widget(L, "label");
}

static int luatk_app_entry(lua_State *L) {
    return luatk_create_widget(L, "entry");
}

static int luatk_app_text(lua_State *L) {
    return luatk_create_widget(L, "text");
}

static int luatk_app_frame(lua_State *L) {
    return luatk_create_widget(L, "frame");
}

static int luatk_app_canvas(lua_State *L) {
    return luatk_create_widget(L, "canvas");
}

static int luatk_app_listbox(lua_State *L) {
    return luatk_create_widget(L, "listbox");
}

static int luatk_app_scale(lua_State *L) {
    return luatk_create_widget(L, "scale");
}

static int luatk_app_scrollbar(lua_State *L) {
    return luatk_create_widget(L, "scrollbar");
}

static int luatk_app_checkbutton(lua_State *L) {
    return luatk_create_widget(L, "checkbutton");
}

static int luatk_app_radiobutton(lua_State *L) {
    return luatk_create_widget(L, "radiobutton");
}

static int luatk_app_menubutton(lua_State *L) {
    return luatk_create_widget(L, "menubutton");
}

static int luatk_app_menu(lua_State *L) {
    return luatk_create_widget(L, "menu");
}

static int luatk_app_spinbox(lua_State *L) {
    return luatk_create_widget(L, "spinbox");
}

static int luatk_app_panedwindow(lua_State *L) {
    return luatk_create_widget(L, "panedwindow");
}

static int luatk_app_labelframe(lua_State *L) {
    return luatk_create_widget(L, "labelframe");
}

// Ttk widgets
static int luatk_app_ttk_button(lua_State *L) {
    return luatk_create_widget(L, "ttk::button");
}

static int luatk_app_ttk_label(lua_State *L) {
    return luatk_create_widget(L, "ttk::label");
}

static int luatk_app_ttk_entry(lua_State *L) {
    return luatk_create_widget(L, "ttk::entry");
}

static int luatk_app_ttk_frame(lua_State *L) {
    return luatk_create_widget(L, "ttk::frame");
}

static int luatk_app_ttk_notebook(lua_State *L) {
    return luatk_create_widget(L, "ttk::notebook");
}

static int luatk_app_ttk_progressbar(lua_State *L) {
    return luatk_create_widget(L, "ttk::progressbar");
}

static int luatk_app_ttk_treeview(lua_State *L) {
    return luatk_create_widget(L, "ttk::treeview");
}

static int luatk_app_ttk_separator(lua_State *L) {
    return luatk_create_widget(L, "ttk::separator");
}

static int luatk_app_ttk_sizegrip(lua_State *L) {
    return luatk_create_widget(L, "ttk::sizegrip");
}

// Widget methods
static int luatk_widget_pack(lua_State *L) {
    LuaTkWidget *widget = luatk_checkwidget(L, 1);

    char cmd[1024];
    char options[512];

    parse_options(L, 2, options, sizeof(options), NULL);
    snprintf(cmd, sizeof(cmd), "pack %s%s", widget->widget_path, options);

    Tcl_Eval(widget->app->interp, cmd);
    return 0;
}

static int luatk_widget_grid(lua_State *L) {
    LuaTkWidget *widget = luatk_checkwidget(L, 1);

    char cmd[1024];
    char options[512];

    parse_options(L, 2, options, sizeof(options), NULL);
    snprintf(cmd, sizeof(cmd), "grid %s%s", widget->widget_path, options);

    Tcl_Eval(widget->app->interp, cmd);
    return 0;
}

static int luatk_widget_place(lua_State *L) {
    LuaTkWidget *widget = luatk_checkwidget(L, 1);

    char cmd[1024];
    char options[512];

    parse_options(L, 2, options, sizeof(options), NULL);
    snprintf(cmd, sizeof(cmd), "place %s%s", widget->widget_path, options);

    Tcl_Eval(widget->app->interp, cmd);
    return 0;
}

static int luatk_widget_configure(lua_State *L) {
    LuaTkWidget *widget = luatk_checkwidget(L, 1);

    char cmd[2048];
    char options[1024];

    parse_options(L, 2, options, sizeof(options), NULL);
    snprintf(cmd, sizeof(cmd), "%s configure%s", widget->widget_path, options);

    Tcl_Eval(widget->app->interp, cmd);
    return 0;
}

// Canvas drawing methods
static int luatk_widget_create_line(lua_State *L) {
    LuaTkWidget *widget = luatk_checkwidget(L, 1);
    int x1 = (int)luaL_checknumber(L, 2);  // luaL_checknumber 사용 후 int로 캐스팅
    int y1 = (int)luaL_checknumber(L, 3);
    int x2 = (int)luaL_checknumber(L, 4);
    int y2 = (int)luaL_checknumber(L, 5);

    char options[512];
    parse_options(L, 6, options, sizeof(options), NULL);

    char cmd[1024];
    snprintf(cmd, sizeof(cmd), "%s create line %d %d %d %d%s",
             widget->widget_path, x1, y1, x2, y2, options);

    if (Tcl_Eval(widget->app->interp, cmd) != TCL_OK) {
        printf("Canvas line error: %s\n", Tcl_GetStringResult(widget->app->interp));
    }

    return 0;
}

static int luatk_widget_create_oval(lua_State *L) {
    LuaTkWidget *widget = luatk_checkwidget(L, 1);
    int x1 = (int)luaL_checknumber(L, 2);
    int y1 = (int)luaL_checknumber(L, 3);
    int x2 = (int)luaL_checknumber(L, 4);
    int y2 = (int)luaL_checknumber(L, 5);

    char options[512];
    parse_options(L, 6, options, sizeof(options), NULL);

    char cmd[1024];
    snprintf(cmd, sizeof(cmd), "%s create oval %d %d %d %d%s",
             widget->widget_path, x1, y1, x2, y2, options);

    if (Tcl_Eval(widget->app->interp, cmd) != TCL_OK) {
        printf("Canvas oval error: %s\n", Tcl_GetStringResult(widget->app->interp));
    }

    return 0;
}

static int luatk_widget_create_rectangle(lua_State *L) {
    LuaTkWidget *widget = luatk_checkwidget(L, 1);
    int x1 = luaL_checknumber(L, 2);
    int y1 = luaL_checknumber(L, 3);
    int x2 = luaL_checknumber(L, 4);
    int y2 = luaL_checknumber(L, 5);

    char options[512];
    parse_options(L, 6, options, sizeof(options), NULL);

    char cmd[1024];
    snprintf(cmd, sizeof(cmd), "%s create rectangle %d %d %d %d%s",
             widget->widget_path, x1, y1, x2, y2, options);

    if (Tcl_Eval(widget->app->interp, cmd) != TCL_OK) {
        printf("Canvas rectangle error: %s\n", Tcl_GetStringResult(widget->app->interp));
    }

    return 0;
}

static int luatk_widget_create_polygon(lua_State *L) {
    LuaTkWidget *widget = luatk_checkwidget(L, 1);

    // Receives coordinates of points (variable arguments)
    int argc = lua_gettop(L);
    char coords[1024] = "";

    for (int i = 2; i < argc; i += 2) {
        if (i + 1 <= argc) {
            int x = (int)luaL_checknumber(L, i);
            int y = (int)luaL_checknumber(L, i + 1);
            char coord[32];
            snprintf(coord, sizeof(coord), "%d %d ", x, y);
            strcat(coords, coord);
        }
    }

    char options[512];
    parse_options(L, argc, options, sizeof(options), NULL);

    char cmd[1024];
    snprintf(cmd, sizeof(cmd), "%s create polygon %s%s",
             widget->widget_path, coords, options);

    if (Tcl_Eval(widget->app->interp, cmd) != TCL_OK) {
        printf("Canvas polygon error: %s\n", Tcl_GetStringResult(widget->app->interp));
    }

    return 0;
}

static int luatk_widget_create_text(lua_State *L) {
    LuaTkWidget *widget = luatk_checkwidget(L, 1);
    int x = (int)luaL_checknumber(L, 2);
    int y = (int)luaL_checknumber(L, 3);
    const char *text = luaL_checkstring(L, 4);

    char options[512];
    parse_options(L, 5, options, sizeof(options), NULL);

    char cmd[1024];
    snprintf(cmd, sizeof(cmd), "%s create text %d %d -text {%s}%s",
             widget->widget_path, x, y, text, options);

    if (Tcl_Eval(widget->app->interp, cmd) != TCL_OK) {
        printf("Canvas text error: %s\n", Tcl_GetStringResult(widget->app->interp));
    }

    return 0;
}

static int luatk_widget_destroy(lua_State *L) {
    LuaTkWidget *widget = luatk_checkwidget(L, 1);

    char cmd[256];
    snprintf(cmd, sizeof(cmd), "destroy %s", widget->widget_path);
    Tcl_Eval(widget->app->interp, cmd);

    if (widget->callback_ref != LUA_NOREF) {
        luaL_unref(L, LUA_REGISTRYINDEX, widget->callback_ref);
    }
    if (widget->self_ref != LUA_NOREF) {
        luaL_unref(L, LUA_REGISTRYINDEX, widget->self_ref);
    }
    free(widget->widget_path);
    free(widget->widget_type);

    return 0;
}

// Metatable setup
static const luaL_Reg app_methods[] = {
    {"mainloop", luatk_app_mainloop},
    {"title", luatk_app_title},
    {"geometry", luatk_app_geometry},
    {"button", luatk_app_button},
    {"label", luatk_app_label},
    {"entry", luatk_app_entry},
    {"text", luatk_app_text},
    {"frame", luatk_app_frame},
    {"canvas", luatk_app_canvas},
    {"listbox", luatk_app_listbox},
    {"scale", luatk_app_scale},
    {"scrollbar", luatk_app_scrollbar},
    {"checkbutton", luatk_app_checkbutton},
    {"radiobutton", luatk_app_radiobutton},
    {"menubutton", luatk_app_menubutton},
    {"menu", luatk_app_menu},
    {"spinbox", luatk_app_spinbox},
    {"panedwindow", luatk_app_panedwindow},
    {"labelframe", luatk_app_labelframe},
    // Ttk widgets
    {"ttk_button", luatk_app_ttk_button},
    {"ttk_label", luatk_app_ttk_label},
    {"ttk_entry", luatk_app_ttk_entry},
    {"ttk_frame", luatk_app_ttk_frame},
    {"ttk_notebook", luatk_app_ttk_notebook},
    {"ttk_progressbar", luatk_app_ttk_progressbar},
    {"ttk_treeview", luatk_app_ttk_treeview},
    {"ttk_separator", luatk_app_ttk_separator},
    {"ttk_sizegrip", luatk_app_ttk_sizegrip},
    {"__gc", luatk_app_destroy},
    {NULL, NULL}};

static const luaL_Reg widget_methods[] = {
    {"pack", luatk_widget_pack},
    {"grid", luatk_widget_grid},
    {"place", luatk_widget_place},
    {"configure", luatk_widget_configure},
    {"destroy", luatk_widget_destroy},
    // Canvas methods
    {"create_line", luatk_widget_create_line},
    {"create_oval", luatk_widget_create_oval},
    {"create_rectangle", luatk_widget_create_rectangle},
    {"create_polygon", luatk_widget_create_polygon},
    {"create_text", luatk_widget_create_text},
    {"__gc", luatk_widget_destroy},
    {NULL, NULL}};

static const luaL_Reg luatk_functions[] = {
    {"new", luatk_app_new},
    {NULL, NULL}};

// Module initialization
EXPORT int luaopen_luatk(lua_State *L) {
    // Create app metatable
    luaL_newmetatable(L, LUATK_APP_META);
    lua_pushvalue(L, -1);
    lua_setfield(L, -2, "__index");
    luaL_setfuncs(L, app_methods, 0);

    // Create widget metatable
    luaL_newmetatable(L, LUATK_WIDGET_META);
    lua_pushvalue(L, -1);
    lua_setfield(L, -2, "__index");
    luaL_setfuncs(L, widget_methods, 0);

    // Create module table
    luaL_newlib(L, luatk_functions);

    return 1;
}