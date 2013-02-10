extern "C" {
#include "lua/lua.h"
#include "lua/lualib.h"
#include "lua/lauxlib.h"

//int pmain (lua_State *L);

void l_message (const char *pname, const char *msg);

void *luaL_testudata (lua_State *L, int ud, const char *tname);

int handle_luainit (lua_State *L);

int docall (lua_State *L, int narg, int clear);

int report (lua_State *L, int status);
}
