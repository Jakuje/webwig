#include <map>
#include <string>
#include <cstdio>
#include <syslog.h>

#include <glob.h>
#include <sys/stat.h>

#include "wherigo.h"

/**
 * Includes for PDK for webOS app
 */

#ifndef DESKTOP

#include "SDL.h"
#include "PDL.h"

#endif /* DESKTOP */

#include "lua_common.h"

using namespace std;

enum EVENT_CODES {EVENT_GET_CARTRIDGES, EVENT_OPEN_CARTRIDGE, EVENT_CLOSE_CARTRIDGE};

lua_State *L;

#define EXIT(n) do { fprintf(stderr, "Early exit at %s:%d\n", __FILE__, __LINE__); exit(n); } while (0)

// http://stackoverflow.com/questions/7724448/simple-json-string-escape-for-c
std::string escapeJsonString(const std::string& input) {
    std::ostringstream ss;
    //for (auto iter = input.cbegin(); iter != input.cend(); iter++) {
    //C++98/03:
    for (std::string::const_iterator iter = input.begin(); iter != input.end(); iter++) {
        switch (*iter) {
            case '\\': ss << "\\\\"; break;
            case '"': ss << "\\\""; break;
            case '/': ss << "\\/"; break;
            case '\b': ss << "\\b"; break;
            case '\f': ss << "\\f"; break;
            case '\n': ss << "\\n"; break;
            case '\r': ss << "\\r"; break;
            case '\t': ss << "\\t"; break;
            default: ss << *iter; break;
        }
    }
    return ss.str();
}

#ifndef DESKTOP
/**
 * @param filename (string) Filename to open and start
 */
static PDL_bool openCartridgeJS(PDL_JSParameters *params)
{
    if (PDL_GetNumJSParams(params) != 1) {
        syslog(LOG_INFO, "**** wrong number of parameters for getMetadata");
        PDL_JSException(params, "wrong number of parameters for getMetadata");
        return PDL_FALSE;
    }

    /* parameters are directory, pattern */
    const char *filename = PDL_GetJSParamString(params, 0);

    /* since we don't process this in the method thread, instead post a
     * SDL event that will be received in the main thread and used to 
     * launch the code. */
    SDL_Event event;
    event.user.type = SDL_USEREVENT;
    event.user.code = EVENT_OPEN_CARTRIDGE;
    event.user.data1 = strdup(filename);
    
    syslog(LOG_WARNING, "*** sending openCartridge event");
    SDL_PushEvent(&event);
    
    return PDL_TRUE;
}

/**
 * @param save (int) Save cartridge or not
 */
static PDL_bool closeCartridgeJS(PDL_JSParameters *params)
{
    if (PDL_GetNumJSParams(params) != 1) {
        syslog(LOG_INFO, "**** wrong number of parameters for getMetadata");
        PDL_JSException(params, "wrong number of parameters for getMetadata");
        return PDL_FALSE;
    }

    /* parameters are directory, pattern */
    int *save = new int;
    *save = PDL_GetJSParamInt(params, 0);

    /* since we don't process this in the method thread, instead post a
     * SDL event that will be received in the main thread and used to 
     * launch the code. */
    SDL_Event event;
    event.user.type = SDL_USEREVENT;
    event.user.code = EVENT_CLOSE_CARTRIDGE;
    event.user.data1 = save;
    
    syslog(LOG_WARNING, "*** sending closeCartridge event");
    SDL_PushEvent(&event);
    
    return PDL_TRUE;
}


/**
 * @param refresh (int) Return saved (0) or scan dir for new packages (1)
 */
static PDL_bool getCartridgesJS(PDL_JSParameters *params)
{
    if (PDL_GetNumJSParams(params) != 1) {
        syslog(LOG_INFO, "**** wrong number of parameters for getCartridges");
        PDL_JSException(params, "wrong number of parameters for getCartridges");
        return PDL_FALSE;
    }

    /* parameters are directory, pattern */
    int *refresh = new int;
    *refresh = PDL_GetJSParamInt(params, 0);

    /* since we don't process this in the method thread, instead post a
     * SDL event that will be received in the main thread and used to 
     * launch the code. */
    SDL_Event event;
    event.user.type = SDL_USEREVENT;
    event.user.code = EVENT_GET_CARTRIDGES;
    event.user.data1 = refresh;
    
    syslog(LOG_WARNING, "*** sending getCartridges event");
    SDL_PushEvent(&event);
    
    return PDL_TRUE;
}
#endif

static int openCartridge(char *filename);
static void OutputCartridgesToJS(int *refresh);

void CommandLineTests(){
	// OutputCartridges
	int *refresh = new int;
	*refresh = 1;
	OutputCartridgesToJS(refresh);
	delete refresh;
	
	openCartridge("minimal.gwc");
}

static void setup()
{

#ifndef DESKTOP
    openlog("com.dta3team.app.wherigo", 0, LOG_USER);
    
    int result = SDL_Init(SDL_INIT_VIDEO);
    if ( result != 0 ) {
        printf("Could not init SDL: %s\n", SDL_GetError());
        exit(1);
    }
	atexit(SDL_Quit);
    
    PDL_Init(0);
    atexit(PDL_Quit);

	if (!PDL_IsPlugin()) {
#endif
		cerr << "call from cmd" << endl;
        CommandLineTests();
        exit(0);
#ifndef DESKTOP
    }
    
	PDL_RegisterJSHandler("getCartridges", getCartridgesJS);
    PDL_RegisterJSHandler("openCartridge", openCartridgeJS);
    PDL_RegisterJSHandler("closeCartridge", closeCartridgeJS);
    PDL_JSRegistrationComplete();
    
    // Workaround for old webos devices:
    // https://github.com/enyojs/enyo-1.0/blob/master/framework/source/palm/controls/Hybrid.js#L49
    const char *params[1];
	params[0] = "ready";
	PDL_CallJS("__PDL_PluginStatusChange__", params, 1);

	// call a "ready" callback to let JavaScript know that we're initialized
    PDL_CallJS("ready", NULL, 0);
    syslog(LOG_INFO, "**** Registered");
#endif	
}

bool gKeyboardVisible = false;

static bool OutputMetadata(stringstream *buf, const char *cartridge, bool first = true){
	string filename( DATA_DIR );
	filename.append(cartridge);
	Wherigo *w = new Wherigo(filename);
	if( w->setup() == EXIT_FAILURE ){
		delete w;
		return false;		
	}
	w->createIcons();
	
	if (!first) {
		*buf << ",\n";
	}
	
	*buf << "{\n"
		<< "\"filename\": \"" << escapeJsonString(string(cartridge)) << "\""
		<< ",\"iconID\": \"" << w->iconID << "\""
		<< ",\"splashID\": \"" << w->splashID << "\""
		<< ",\"type\": \"" << w->type << "\""
		<< ",\"name\": \"" << escapeJsonString(w->cartridgeName) << "\""
		<< ",\"guid\": \"" << w->cartridgeGUID << "\""
		<< ",\"description\": \"" << escapeJsonString(w->cartridgeDescription) << "\""
		<< ",\"startingLocationDescription\": \"" << escapeJsonString(w->startingLocationDescription) << "\""
		<< ",\"version\": \"" << w->version << "\""
		<< ",\"author\": \"" << escapeJsonString(w->author) << "\""
		<< ",\"company\": \"" << escapeJsonString(w->company) << "\""
		<< "\n}";
	delete w;
	return true;
}

static void OutputCartridges(stringstream *buf, int *refresh){
	string filename( DATA_DIR );
	filename.append( CONFIG_FILE );
	ifstream file(filename.c_str(), ifstream::in | ifstream::binary);
	
	if( (*refresh == 1) || (!file.is_open()) ){
		// obnov ...
		glob_t matches;
		string pattern = string(DATA_DIR).append("*.gwc");
		size_t offset = DATA_DIR.length();
		*buf << "{\"type\": \"ok\", \"data\": [\n";
		if (0 == glob(pattern.c_str(), GLOB_BRACE, NULL, &matches)) {
			bool first = true;
			for (size_t i = 0; i < matches.gl_pathc; ++i) {
				string name = string(matches.gl_pathv[i]);
				struct stat details;
				if (0 != stat(name.c_str(), &details)) {
					// if we can't get file details, go to next one
					continue;
				}

				// output a file entry for regular files
				if (S_ISREG(details.st_mode)) {
					// output comma separators before all but the first filename
					if( OutputMetadata(buf, (name.substr(offset).c_str()), first) == false){
						continue;
					}
					first = false;
					
				}
			}
		}
	    *buf << "]}";
		
		globfree(&matches);
	    
		file.close();
		ofstream f(filename.c_str());
		f << buf->str();
		f.close();
		return;
	}
	
	*buf << file.rdbuf();
	file.close();
	return;
}


static void OutputCartridgesToJS(int *refresh)
{
    stringstream *buffer = new stringstream(stringstream::in | stringstream::out);
	OutputCartridges(buffer, refresh);
	
	string str = buffer->str();	
	const char * data = str.c_str();
	
#ifndef DESKTOP
    // send data back to the JavaScript side
    syslog(LOG_WARNING, "*** returning results");
    PDL_Err err;
    err = PDL_CallJS("getCartridgesResult", (const char **)&data, 1);
    if (err) {
        syslog(LOG_ERR, "*** PDL_CallJS failed, %s", PDL_GetError());
        //SDL_Delay(5);
    }
#endif
    
    // now that we're done, free our working memory
    delete buffer;
}
/**
 * Lua function
 * @param string Message to show
 */
static int messageBox(lua_State *L) {
	const char *text = lua_tostring(L, 1);  /* get argument */
	cerr << "Message:" << text << endl;
	syslog(LOG_WARNING, "*** MessageBox with message: %s", text);
	
#ifndef DESKTOP
    PDL_Err err;
    err = PDL_CallJS("popupMessage", (const char **)&text, 1);
    if (err) {
        syslog(LOG_ERR, "*** PDL_CallJS failed, %s", PDL_GetError());
        //SDL_Delay(5);
    }
#endif
	
	return 0;  /* number of results */
}

struct Smain {
  int argc;
  char **argv;
  int status;
};

int pmain (lua_State *L) {
	string *file = (string*) lua_touserdata(L, 1);
	lua_gc(L, LUA_GCSTOP, 0);  /* stop collector during initialization */
	luaL_openlibs(L);  /* open libraries */
	lua_gc(L, LUA_GCRESTART, 0);
	
	int status = handle_luainit (L);
	if (status != 0) return 0;

	status = luaL_loadfile(L, file->c_str());
	if (status == 0)
		status = docall(L, 0, 0);
	return report(L, status);
}

static void exit_lua(){
    lua_close(L);
}

// http://cc.byexamples.com/2008/11/19/lua-stack-dump-for-c/
void stackdump_g(lua_State* l)
{
    int i;
    int top = lua_gettop(l);
 
    printf("total in stack %d\n",top);
 
    for (i = 1; i <= top; i++)
    {  /* repeat for each level */
        int t = lua_type(l, i);
        switch (t) {
            case LUA_TSTRING:  /* strings */
                printf("string: '%s'\n", lua_tostring(l, i));
                break;
            case LUA_TBOOLEAN:  /* booleans */
                printf("boolean %s\n",lua_toboolean(l, i) ? "true" : "false");
                break;
            case LUA_TNUMBER:  /* numbers */
                printf("number: %g\n", lua_tonumber(l, i));
                break;
            default:  /* other values */
                printf("%s\n", lua_typename(l, t));
                break;
        }
        printf("  ");  /* put a separator */
    }
    printf("\n");  /* end the listing */
}

static int openCartridge(char *filename){
	Wherigo w( string(DATA_DIR).append(filename) );
	if( ! w.setup() ){
		return 0;
	}
	w.createTmp(); // create dir and files
	
	// new Lua state
	int status;
	L = lua_open();  /* create state */
	if (L == NULL) {
		l_message("", "cannot create state: not enough memory");
		return 0;
	}
	luaL_openlibs(L);

	atexit( exit_lua );
	my_error("*** MAIN LUA");

	// messageBox as CFunction
	lua_register(L, "messageBox", messageBox);
	// library, for now in Lua
	status = luaL_dofile(L, "wherigo.lua");
	report(L, status);
	
	// do bytecode from cartridge
	string bytecode = string( w.getTmp() );
	bytecode.append("/wg.lua");
	//status = lua_cpcall(L, &pmain, &bytecode);
	status = luaL_dofile(L, bytecode.c_str());
	report(L, status);
	// create global Lua variable
	lua_setglobal(L, "cartridge"); // by http://wherigobuilder.wikispaces.com/Globals
	
	// run onStart event
	status = !status && luaL_dostring(L, "cart.OnStart()");
	report(L, status);
	
	//stackdump_g(L);
	
	my_error("Everything ok");
	return 1;
} 

#ifndef DESKTOP
static void openCartridgeToJS(char *filename){
	stringstream *buffer = new stringstream(stringstream::in | stringstream::out);
	if( openCartridge(filename) ){
		*buffer << "{\"type\": \"ok\", \"data\": {\n"
				<< "\"locations\": [{\"name\": \"Somewhere\"}],"
				<< "\"youSee\": [],"
				<< "\"inventory\": [{\"name\": \"Something\"}, {\"name\": \"Pen\"}],"
				<< "\"tasks\": [{\"name\": \"To do something\"}],"
			<< "}}";
	} else {
		*buffer << "{\"type\": \"error\", \"message\": \"Unable to load cartidge file\"}";
	}
	
	string str = buffer->str();	
	const char * data = str.c_str();
	
    // send data back to the JavaScript side
    syslog(LOG_WARNING, "*** returning results");
    PDL_Err err;
    err = PDL_CallJS("openCartridgeResult", (const char **)&data, 1);
    if (err) {
        syslog(LOG_ERR, "*** PDL_CallJS failed, %s", PDL_GetError());
        //SDL_Delay(5);
    }
    
    // now that we're done, free our working memory
    delete buffer;
}
#endif

static void loop(){

#ifndef DESKTOP
	SDL_Event event;
    if (SDL_WaitEvent(&event)) {
        if (event.type == SDL_QUIT)
            exit(0);
        else if (event.type == SDL_MOUSEBUTTONDOWN) {
           if (PDL_GetPDKVersion() >= 300) {
                gKeyboardVisible = !gKeyboardVisible;
                PDL_SetKeyboardState(gKeyboardVisible ? PDL_TRUE : PDL_FALSE);
           }
        } else if (event.type == SDL_USEREVENT) {
            syslog(LOG_WARNING, "*** processing * event");
            switch( event.user.code ){
				/*case GET_METADATA:
					// extract our arguments
					char *cartridge = (char *)event.user.data1;
					
					// call our output function
					OutputMetadataToJS(cartridge);

					// free memory since this event is processed now
					free(cartridge);
					break;*/
				case EVENT_GET_CARTRIDGES: {
					int *refresh = (int *)event.user.data1;
					OutputCartridgesToJS(refresh);
					delete refresh;
					}
					break;
				case EVENT_OPEN_CARTRIDGE: {
					char *filename = (char *)event.user.data1;
					openCartridgeToJS(filename);
					delete filename;
					}
					break;
				case EVENT_CLOSE_CARTRIDGE: {
					int *save = (int *)event.user.data1;
					//openCartridgeToJS(filename);
					delete save;
					}
					break;
			}
        }
    }
#endif
}



class ZObject {

};

class Player: ZObject {

};

class ZCartridge: ZObject {
	
	/*bool lua_register(){
		Lunar<ZCartridge>::RegType ZCartridge::methods[] = {
			LUNAR_DECLARE_METHOD(ZCartridge, deposit),
	}*/

};

//const char ZCartridge::className[] = "ZCartrige";

int main (int argc, char **argv) {
	// SDL setup and graphics display
  setup();
  my_error("*** MAIN Setup");
 
  

  // alive UI
  while (1) {
    loop();
  }
}
