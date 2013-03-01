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

#include <SDL.h>

#ifndef DESKTOP

#include "PDL.h"

#endif /* DESKTOP */

#include "lua_common.h"

#include "LuaBridge.h"

using namespace std;

enum EVENT_CODES {
	EVENT_GET_CARTRIDGES,
	EVENT_OPEN_CARTRIDGE,
	EVENT_CLOSE_CARTRIDGE,
	EVENT_MESSAGE_BOX_RESPONSE,
	EVENT_UPDATE_GPS
	};

// Copy&Paste from wherigo.lua
enum SCREENS {
	MAINSCREEN 			= 0,
	INVENTORYSCREEN 	= 1,
	ITEMSCREEN 			= 2,
	LOCATIONSCREEN		= 3,
	TASKSCREEN			= 4,
	DETAILSCREEN 		= 10
};


lua_State *L;

Wherigo *WherigoOpen;

SDL_TimerID gpsTimer;

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

    int *save = new int;
    *save = PDL_GetJSParamInt(params, 0);

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

    int *refresh = new int;
    *refresh = PDL_GetJSParamInt(params, 0);

    SDL_Event event;
    event.user.type = SDL_USEREVENT;
    event.user.code = EVENT_GET_CARTRIDGES;
    event.user.data1 = refresh;
    
    syslog(LOG_WARNING, "*** sending getCartridges event");
    SDL_PushEvent(&event);
    
    return PDL_TRUE;
}

/**
 * @param value (char *) user response to MessageBox (button1 or button2)
 */
static PDL_bool MessageBoxResponseJS(PDL_JSParameters *params)
{
    if (PDL_GetNumJSParams(params) != 1) {
        syslog(LOG_INFO, "**** wrong number of parameters for MessageBoxResponse");
        PDL_JSException(params, "wrong number of parameters for MessageBoxResponse");
        return PDL_FALSE;
    }

    const char *value = PDL_GetJSParamString(params, 0);

    SDL_Event event;
    event.user.type = SDL_USEREVENT;
    event.user.code = EVENT_MESSAGE_BOX_RESPONSE;
    event.user.data1 = strdup(value);
    
    syslog(LOG_WARNING, "*** sending MessageBoxResponse event");
    SDL_PushEvent(&event);
    
    return PDL_TRUE;
}


#endif

static void openCartridgeToJS(char *filename);
static void OutputCartridgesToJS(int *refresh);

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

static void MessageBox(const char *text, const char *media,
		const char *button1, const char *button2, bool callback /*lua_State *L*/) {
	cerr << "MessageBox:" << text;
	if( button1 || button2 ){
		cerr << " >> Options: " << button1 << " | " << button2;
	}
	string m;
	if( media ){
		m = WherigoOpen->getFilePath(media);
		cerr << " >> Media id: " << m;
	}
	cerr << endl;
	syslog(LOG_WARNING, "*** MessageBox with message: %s", text);
	
#ifndef DESKTOP
    PDL_Err err;
    const char *c = (callback ? "1" : "0");
    const char *params[5];
    params[0] = text;
    params[1] = m.c_str();
    params[2] = button1;
    params[3] = button2;
    params[4] = c;
    err = PDL_CallJS("popupMessage", params, 5);
    if (err) {
        syslog(LOG_ERR, "*** PDL_CallJS failed, %s", PDL_GetError());
        //SDL_Delay(5);
    }
#else
	if( callback ){
		luaL_dostring(L, "Wherigo._MessageBoxResponse(\"ok\")");
	}
#endif
	return;
}
static void MessageBoxResponse(const char *value){
	lua_getfield(L, LUA_GLOBALSINDEX, "Wherigo");
	lua_getfield(L, -1, "_MessageBoxResponse");
	lua_remove(L, -2);
	lua_pushstring(L, value);
	lua_call(L, 1, 0);
}

static void PlayAudio(const char *media) {
	syslog(LOG_WARNING, "*** PlayAudio");

#ifndef DESKTOP
    PDL_Err err;
    const char *params = WherigoOpen->getFilePath(media).c_str();
    err = PDL_CallJS("playAudio", (const char **)&params, 1);
    if (err) {
        syslog(LOG_ERR, "*** PDL_CallJS failed, %s", PDL_GetError());
        //SDL_Delay(5);
    }
#endif
	return;
}

static void ShowStatusText(const char *text) {
	syslog(LOG_WARNING, "*** ShowStatusText");

#ifndef DESKTOP
    PDL_Err err;
    err = PDL_CallJS("ShowStatusText", (const char **)&text, 1);
    if (err) {
        syslog(LOG_ERR, "*** PDL_CallJS failed, %s", PDL_GetError());
        //SDL_Delay(5);
    }
#endif
	return;
}


static void ShowScreen(int screen, int detail) {
	syslog(LOG_WARNING, "*** ShowScreen %d %d", screen, detail);
	
#ifndef DESKTOP
    PDL_Err err;
    const char *params[2];
    /*params[0] = screen;
    params[1] = detail;*/
    err = PDL_CallJS("showScreen", params, 1);
    if (err) {
        syslog(LOG_ERR, "*** PDL_CallJS failed, %s", PDL_GetError());
        //SDL_Delay(5);
    }
#endif
	return;
}

static void GetInput(const char *type, const char *text) {
	syslog(LOG_WARNING, "*** GetInput");

#ifndef DESKTOP
    PDL_Err err;
    const char *params[2];
    params[0] = type;
    porams[1] = text;
    err = PDL_CallJS("GetInput", params, 2);
    if (err) {
        syslog(LOG_ERR, "*** PDL_CallJS failed, %s", PDL_GetError());
        //SDL_Delay(5);
    }
#endif
	return;
}




static void exit_lua(){
	if( L != NULL ){
		lua_close(L);
		L = NULL;
	}
}

lua_State * openLua(Wherigo *w){
	// new Lua state
	if( L != NULL ){
		exit_lua();
	}
	
	int status;
	L = lua_open();  /* create state */
	if (L == NULL) {
		l_message("", "cannot create state: not enough memory");
		return NULL;
	}
	luaL_openlibs(L);

	atexit( exit_lua );
	//my_error("*** MAIN LUA");

	// messageBox as CFunction
	//lua_register(L, "messageBox", messageBox);
	
	// Env and other variables
	string device("WebOS");
	string dir("./");
	string version("2.11");
	string slash("/");
	
	luabridge::getGlobalNamespace(L)
		.beginNamespace("Env")
			.addVariable("CartFilename", &w->filename, true)
			.addVariable("Device", &w->recomandedDevice, false)
			.addVariable("Platform", &device, false)
			.addVariable("CartFolder", &dir, false)
			.addVariable("SyncFolder", &dir, false)
			.addVariable("PathSep", &slash, false)
			.addVariable("DeviceId", &device, false)
			.addVariable("Version", &version, false)
			.addVariable("LogFolfer", &dir)
			.addVariable("_CompletionCode", &w->completionCode)
			.addVariable("_Player", &w->player)
			.addVariable("_IconId", &w->iconID)
			.addVariable("_SplashId", &w->splashID)
			//.addVariable("Downloaded", &0, false)
		.endNamespace();
		
	luabridge::getGlobalNamespace(L)
		.beginNamespace("WIGInternal")
			.addFunction("MessageBox", MessageBox)
			.addFunction("PlayAudio", PlayAudio)
			.addFunction("ShowScreen", ShowScreen)
			.addFunction("GetInput", GetInput)
			.addFunction("ShowStatusText", ShowStatusText)
			
		.endNamespace();
			
	// library in Lua
	status = luaL_dofile(L, "wherigo.lua");
	report(L, status);
	if( status != 0 ){
		cerr << "Failed to load wherigo library" << endl;
		return NULL;
	}
	return L;
}

static bool runTests(char * filter){
	glob_t matches;
	int status;
	string pattern = string("tests/").append(filter).append("*");
	
	WherigoOpen = new Wherigo("testname.gwc");
	
	if (0 == glob(pattern.c_str(), GLOB_BRACE, NULL, &matches)) {
		for (size_t i = 0; i < matches.gl_pathc; ++i) {
			string name = string(matches.gl_pathv[i]);
			struct stat details;
			if (0 != stat(name.c_str(), &details)) {
				// if we can't get file details, go to next one
				continue;
			}

			// output a file entry for regular files
			if (S_ISREG(details.st_mode)) {
				L = openLua(WherigoOpen);
				if( L == NULL ){
					cerr << "Can't create lua state" << endl;
					return false;
				}
				// output comma separators before all but the first filename
				status = luaL_dofile(L, name.c_str());
				report(L, status);
				cerr << "Test " << name << ": " << (status == 0
#ifdef DESKTOP
					? "\033[1;32mOK\e[m"
					: "\033[1;31mERROR\e[m") << endl;
#else
					? "OK"
					: "ERROR") << endl;
#endif
			}
		}
	}
	delete WherigoOpen;
	globfree(&matches);
	
	return true;
}

static void updateStateToJS(){
	int status;
	stringstream *buffer = new stringstream(stringstream::in | stringstream::out);
	
	cerr << "Getting state" << endl;
	status = luaL_dostring(L, "return Wherigo._getUI()");
	report(L, status);
	
	if( status == 0 ){
		string result;
		int type = lua_type(L, 1);
		if( type == LUA_TSTRING ){
			result = lua_tostring(L,1);
			cerr << result;
		}
		/*if( type == LUA_TTABLE ){
			lua_pushnil(L);
			stackdump_g(L);
			while(lua_next(L, 1) != 0){
				printf("%s - %s\n", 
					  lua_typename(L, lua_type(L, -2)),
					  lua_typename(L, lua_type(L, -1)));
				lua_pop(L, 1);
			}
		}*/
		*buffer << "{\"type\": \"ok\", \"data\": \n"
			<< result
				/*<< "{\"locations\": [{\"name\": \"Somewhere\"}],"
				<< "\"youSee\": [],"
				<< "\"inventory\": [{\"name\": \"Something\"}, {\"name\": \"Pen\"}],"
				<< "\"tasks\": [{\"name\": \"To do something\"}]}"*/
			<< "}";
	} else {
		my_error("Problem getting UI informations");
	}
	
	
	
#ifndef DESKTOP
	string str = buffer->str();	
	const char *data = str.c_str();
	
	syslog(LOG_WARNING, "*** Updating State");
    PDL_Err err;
    err = PDL_CallJS("updateState", (const char **)&data, 1);
    if (err) {
        syslog(LOG_ERR, "*** PDL_CallJS failed, %s", PDL_GetError());
        //SDL_Delay(5);
        return;
    }
#endif
    delete buffer;
    
}


void CommandLineTests(int argc, char **argv){
	// OutputCartridges
	int *refresh = new int;
	*refresh = 1;
	OutputCartridgesToJS(refresh);
	delete refresh;
	
	char *file;
	if( argc > 1 && strcmp(argv[1], "test") == 0){
		if( argc == 3 ){
			runTests(argv[2]);
		} else {
			runTests("*.lua");
		}
		return;
	} else {
		if( argc > 1 ){
			file = argv[1];
		} else {
			file = (char *) "minimal.gwc";
		}
		
		openCartridgeToJS(file);
		//updateStateToJS();
	}
}

static void setup(int argc, char **argv)
{

#ifndef DESKTOP
    openlog("com.dta3team.app.wherigo", 0, LOG_USER);
#endif
    
    int result = SDL_Init(SDL_INIT_TIMER);
    if ( result != 0 ) {
        printf("Could not init SDL: %s\n", SDL_GetError());
        exit(1);
    }
	atexit(SDL_Quit);
    
#ifndef DESKTOP
    PDL_Init(0);
    atexit(PDL_Quit);
    
    PDL_Err error = PDL_EnableLocationTracking(PDL_TRUE);
    if( error != PDL_NOERROR ){
		my_error("Could not init PDL Location Tracking: %s\n", SDL_GetError());
        exit(1);
	}

	if (!PDL_IsPlugin()) {
#endif
		cerr << "call from cmd" << endl;
        CommandLineTests(argc, argv);
        exit(0);
#ifndef DESKTOP
    }
    
	PDL_RegisterJSHandler("getCartridges", getCartridgesJS);
    PDL_RegisterJSHandler("openCartridge", openCartridgeJS);
    PDL_RegisterJSHandler("closeCartridge", closeCartridgeJS);
    PDL_RegisterJSHandler("MessageBoxResponse", MessageBoxResponseJS);
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
	if( w->setup() == false ){
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
#ifndef DESKTOP
	const char * data = str.c_str();
	
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

Uint32 createUpdateEvent(Uint32 interval, void *param){
	SDL_Event event;
    SDL_UserEvent userevent;

    userevent.type = SDL_USEREVENT;
    userevent.code = EVENT_UPDATE_GPS;
    userevent.data1 = NULL;
    userevent.data2 = NULL;

    event.type = SDL_USEREVENT;
    event.user = userevent;

    SDL_PushEvent(&event);
    return(interval);
}

static int openCartridge(char *filename){
	WherigoOpen = new Wherigo( string(DATA_DIR).append(filename) );
	if( ! WherigoOpen->setup() ){
		delete WherigoOpen;
		WherigoOpen = NULL;
		return 0;
	}
	//WherigoOpen->createFiles(); // create dir and files
	
	int status;
	L = openLua(WherigoOpen);
	
	// do bytecode from cartridge
	string bytecode = WherigoOpen->getCartDir();
	bytecode.append("wig.luac");
	
	//status = lua_cpcall(L, &pmain, &bytecode);
	status = luaL_dofile(L, bytecode.c_str());
	report(L, status);
	// create global Lua variable
	lua_setglobal(L, "cartridge"); // by http://wherigobuilder.wikispaces.com/Globals
	
	//stackdump_g(L);
	
	gpsTimer = SDL_AddTimer( (Uint32)5000, createUpdateEvent, NULL );
	
	my_error("Everything ok");
	return 1;
} 

static int closeCartridge(char *filename){
	// @todo
	SDL_RemoveTimer(gpsTimer);
}

static void openCartridgeToJS(char *filename){
	stringstream *buffer = new stringstream(stringstream::in | stringstream::out);
	int status = 0;
	if( openCartridge(filename) ){
		*buffer << "{\"type\": \"ok\", \"data\": {\n"
				//<< "\"tmpdir\": \"" << WherigoOpen->getTmp() << "\","
			<< "}}";
	} else {
		*buffer << "{\"type\": \"error\", \"message\": \"Unable to load cartidge file\"}";
		status = 1;
	}
	
#ifndef DESKTOP
	string str = buffer->str();	
	const char * data = str.c_str();
	
    // send data back to the JavaScript side
    syslog(LOG_WARNING, "*** returning results");
    PDL_Err err;
    err = PDL_CallJS("openCartridgeResult", (const char **)&data, 1);
    if (err) {
        syslog(LOG_ERR, "*** PDL_CallJS failed, %s", PDL_GetError());
        //SDL_Delay(5);
        return;
    }
	if( status == 1 ){
		return;
	}
#endif
	
	// move to starting coordinates and call update position
	cerr << "Updating position" << endl;
	buffer->str("");
	*buffer << "cartridge._update( Wherigo.ZonePoint("
		<< WherigoOpen->lat << ", " << WherigoOpen->lon << ", "
		<< WherigoOpen->alt << "), 1000 )";
	status = luaL_dostring(L, buffer->str().c_str());
	report(L, status);
	
	
	// run onStart event
	status = luaL_dostring(L, "cartridge.OnStart() ");
	report(L, status);
	
    delete buffer;

	updateStateToJS();
}

#ifndef DESKTOP
void UpdateGPS(){
	PDL_Location location;
	PDL_Err status = PDL_GetLocation(location);
	if( status == PDL_NOERROR ){
		if( location.latitude > -1 && location.longitude > -1 )
			stringstream ss;
			ss << "cartridge._update(Wherigo.ZonePoint("
				<< location.latitude << ", " << location.longitude << "), 0)";
			int status lual_dostring(L, ss.c_str());
			report(status);
			my_error("GPS updated successfully");
		}
	} else {
		my_error("Get Location failed: Error = ", PDL_GetError)
	}
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
				case EVENT_UPDATE_GPS:
					UpdateGPS();
					break;
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
				case EVENT_MESSAGE_BOX_RESPONSE: {
					char *value = (char *)event.user.data1;
					MessageBoxResponse(value);
					delete value;
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
  setup(argc, argv);
  my_error("*** MAIN Setup");
 
  

  // alive UI
  while (1) {
    loop();
  }
}
