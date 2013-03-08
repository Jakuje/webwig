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
	EVENT_GET_INPUT_RESPONSE,
	EVENT_CALLBACK,

	EVENT_SET_POSITION_DEBUG
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

int acc_class = 0;

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

/**
 * @param value (char *) user response to GetInput (button or text)
 */
static PDL_bool GetInputResponseJS(PDL_JSParameters *params)
{
    if (PDL_GetNumJSParams(params) != 1) {
        syslog(LOG_INFO, "**** wrong number of parameters for GetInputResponse");
        PDL_JSException(params, "wrong number of parameters for GetInputResponse");
        return PDL_FALSE;
    }

    const char *value = PDL_GetJSParamString(params, 0);

    SDL_Event event;
    event.user.type = SDL_USEREVENT;
    event.user.code = EVENT_GET_INPUT_RESPONSE;
    event.user.data1 = strdup(value);
    
    syslog(LOG_WARNING, "*** sending GetInputResponse event");
    SDL_PushEvent(&event);
    
    return PDL_TRUE;
}


static PDL_bool CallbackFunctionJS(PDL_JSParameters *params){
	if (PDL_GetNumJSParams(params) != 2) {
        syslog(LOG_INFO, "**** wrong number of parameters for CallbackFunction");
        PDL_JSException(params, "wrong number of parameters for CallbackFunction");
        return PDL_FALSE;
    }

    const char *e = PDL_GetJSParamString(params, 0);
    int *id = new int;
    *id = PDL_GetJSParamInt(params, 1);

    SDL_Event event;
    event.user.type = SDL_USEREVENT;
    event.user.code = EVENT_CALLBACK;
    event.user.data1 = strdup(e);
    event.user.data2 = id;
    
    syslog(LOG_WARNING, "*** sending CallbackFunction event");
    SDL_PushEvent(&event);
    
    return PDL_TRUE;
}

static PDL_bool setPositionJS(PDL_JSParameters *params){
	if (PDL_GetNumJSParams(params) != 2) {
        syslog(LOG_INFO, "**** wrong number of parameters for setPosition");
        PDL_JSException(params, "wrong number of parameters for setPosition");
        return PDL_FALSE;
    }

    double *lat = new double;
    *lat = PDL_GetJSParamDouble(params, 0);
    double *lon = new double;
    *lon = PDL_GetJSParamDouble(params, 1);
    
    SDL_Event event;
    event.user.type = SDL_USEREVENT;
    event.user.code = EVENT_SET_POSITION_DEBUG;
    event.user.data1 = lat;
    event.user.data2 = lon;
    
    syslog(LOG_WARNING, "*** sending setPosition event");
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

static void updateStateToJS(){
	int status;
	stringstream *buffer = new stringstream(stringstream::in | stringstream::out);
	
	/*cerr << "Getting state" << endl;
	status = luaL_dostring(L, "return Wherigo._getUI()");
	report(L, status);*/
	
	lua_getfield(L, LUA_GLOBALSINDEX, "Wherigo");	// [-0, +1, e]
	lua_getfield(L, -1, "_getUI");					// [-0, +1, e]
	lua_remove(L, -2);								// [-1, +0, -]
	status = lua_pcall(L, 0, 1, 0);					// [-1, +1, -] [-(nargs + 1), +(nresults|1), -]
	
	if( status == 0 ){
		string result;
		int type = lua_type(L, 1);					// [-0, +0, -]
		if( type == LUA_TSTRING ){
			result = lua_tostring(L, 1);			// [-0, +0, m]
		}
		*buffer << "{\"type\": \"ok\", \"data\": \n"
			<< "{"
				<< result
				<< ", \"gps\": " << acc_class
				<< "}"
			<< "}";
		lua_remove(L, 1);							// [-1, +0, -]
	} else {
		report(L, status);							// [-1, +0, -]
		my_error("Problem getting UI informations");
	}
	
	
#ifndef DESKTOP
	if( PDL_IsPlugin() ){
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
	} else 
#endif
		cerr << buffer->str() << endl;
	
    delete buffer;
    
}

static void saveState(){
	// save ...
}

static void MessageBox(const char *text, const char *media,
		const char *button1, const char *button2, const char *callback /*lua_State *L*/) {
	cerr << "MessageBox:" << text;
	if( strcmp(button1, "") != 0 || strcmp(button2, "") != 0 ){
		cerr << " >> Options: " << button1 << " | " << button2;
	}
	string m;
	if( strcmp(media, "") != 0 ){
		m = WherigoOpen->getFilePathById(media);
		cerr << " >> Media (" << media << "): " << m;
	}
	cerr << endl;
	//syslog(LOG_WARNING, "*** MessageBox with message: %s", text);
	
#ifndef DESKTOP
    PDL_Err err;
    const char *c = (strcmp(callback,"1") == 0 ? "1" : "0");
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
	lua_getfield(L, LUA_GLOBALSINDEX, "Wherigo");	// [-0, +1, e]
	lua_getfield(L, -1, "_MessageBoxResponse");		// [-0, +1, e]
	lua_remove(L, -2);								// [-1, +0, -]
	lua_pushstring(L, value);						// [-0, +1, e]
	int status = lua_pcall(L, 1, 0, 0);				// [-2, +(0|1), -] [-(nargs + 1), +(nresults|1), -]
	report(L, status);								// [-(0|1), +0, -]
	updateStateToJS();
}

static void GetInputResponse(const char *value){
	lua_getfield(L, LUA_GLOBALSINDEX, "Wherigo");	// [-0, +1, e]
	lua_getfield(L, -1, "_GetInputResponse");		// [-0, +1, e]
	lua_remove(L, -2);								// [-1, +0, -]
	lua_pushstring(L, value);						// [-0, +1, e]
	int status = lua_pcall(L, 1, 0, 0);				// [-2, +(0|1), -] [-(nargs + 1), +(nresults|1), -]
	report(L, status);								// [-(0|1), +0, -]
	//my_error(string("GetInputResponse value:").append(value));
	updateStateToJS();
}

static void PlayAudio(const char *media) {
	syslog(LOG_WARNING, "*** PlayAudio");

#ifndef DESKTOP
    PDL_Err err;
    const char *params = WherigoOpen->getFilePathById(media).c_str();
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


static void ShowScreen(const char *screen, const char *detail) {
	syslog(LOG_WARNING, "*** ShowScreen %s %s", screen, detail);
	
#ifndef DESKTOP
	PDL_Err err;
    const char *params[2];
    params[0] = screen;
    params[1] = detail;
    err = PDL_CallJS("showScreen", params, 1);
    if (err) {
        syslog(LOG_ERR, "*** PDL_CallJS failed, %s", PDL_GetError());
        //SDL_Delay(5);
    }
#endif
	return;
}

static void GetInput(const char *type, const char *text, const char* choices, const char* media) {
	syslog(LOG_WARNING, "*** GetInput");
	
	string m;
	if( strcmp(media, "") != 0 ){
		m = WherigoOpen->getFilePathById(media);
	}

#ifndef DESKTOP
    PDL_Err err;
    const char *params[4];
    params[0] = type;
    params[1] = text;
    params[2] = choices;
    params[3] = m.c_str();
    err = PDL_CallJS("GetInput", params, 4);
    if (err) {
        syslog(LOG_ERR, "*** PDL_CallJS failed, %s", PDL_GetError());
        //SDL_Delay(5);
    }
#endif
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
		my_error("cannot create state: not enough memory");
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
			.addVariable("CartFolder", &w->cartDir, false)
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
			.addFunction("escapeJsonString", escapeJsonString)
			.addFunction("save", saveState)
		.endNamespace();
			
	// library in Lua
	status = luaL_dofile(L, "wherigo.lua");
	report(L, status);
	if( status != 0 ){
		my_error("Failed to load wherigo library");
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

static void CallbackFunction(const char *event, int * id){
	/*stringstream ss;
	ss << "Wherigo._callback(\""
		<< event << "\", " << *id << ")";
	int status = luaL_dostring(L, ss.str().c_str());
	report(L, status);*/
	
	lua_getfield(L, LUA_GLOBALSINDEX, "Wherigo");	// [-0, +1, e]
	lua_getfield(L, -1, "_callback");				// [-0, +1, e]
	lua_remove(L, -2);								// [-1, +0, -]
	lua_pushstring(L, event);						// [-0, +1, m]
	lua_pushinteger(L, *id);						// [-0, +1, m]
	int status = lua_pcall(L, 2, 0, 0);				// [-3, +(0|1), -] [-(nargs + 1), +(nresults|1), -]
	report(L, status);								// [-(0|1), +0, -]
	
	//SDL_Delay(5);
	// push updates to JS side
	updateStateToJS();

}

void setPosition(double *lat, double * lon){
	
#ifndef DESKTOP
	// disable autoupdate
	PDL_EnableLocationTracking(PDL_FALSE);
#endif
	
	bool update_all = false;
	stringstream ss;
	int status;
	
	ss << "return cartridge._update(Wherigo.ZonePoint("
		<< *lat << ", " << *lon << "), 0)";
	my_error(ss.str());
	status = luaL_dostring(L, ss.str().c_str());
	if( status == 0 ){
		update_all = lua_toboolean(L, 1);
		lua_pop(L, 1);
		cerr << "Update all: " << update_all << endl;
	} else {
		report(L, status);
	}
	
	//if( update_all ){
		updateStateToJS();
	//}
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
		
		/*int i = 11;
		CallbackFunction("OnClick", &i);*/
		
		double lon, lat;
		lat = 49.223878820512;
		lon = 16.529799699783;
		setPosition(&lat, &lon);
		
		//luaL_dostring(L, "debug.debug()");
		
		//setPosition(&lat, &lon);
		int status = luaL_dostring(L, "return Wherigo._getUI()");
		report(L, status);
		cerr << "Lua result: " << lua_tostring(L, 1) << endl;
		
		//updateStateToJS();
		
	}
}

static void setup(int argc, char **argv)
{

#ifndef DESKTOP
    openlog("com.dta3team.app.wherigo", 0, LOG_USER);
#endif
    
    int result = SDL_Init(SDL_INIT_VIDEO |SDL_INIT_TIMER);
    if ( result != 0 ) {
        printf("Could not init SDL: %s\n", SDL_GetError());
        exit(1);
    }
	atexit(SDL_Quit);
    
#ifndef DESKTOP
    PDL_Init(0);
    atexit(PDL_Quit);
    
    
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
    PDL_RegisterJSHandler("GetInputResponse", GetInputResponseJS);
    PDL_RegisterJSHandler("CallbackFunction", CallbackFunctionJS);
    PDL_RegisterJSHandler("setPosition", setPositionJS);
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
	//w->createIcons();
	
	if (!first) {
		*buf << ",\n";
	}
	
	*buf << "{\n"
		<< "\"filename\": \"" << escapeJsonString(string(cartridge)) << "\""
		<< ",\"icon\": \"" << w->getFilePathById(w->iconID) << "\""
		<< ",\"splash\": \"" << w->getFilePathById(w->splashID) << "\""
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

static int openCartridge(char *filename){
	WherigoOpen = new Wherigo( string(DATA_DIR).append(filename) );
	if( ! WherigoOpen->setup() ){
		delete WherigoOpen;
		WherigoOpen = NULL;
		return 0;
	}
	WherigoOpen->createFiles(); // files
	WherigoOpen->createBytecode();
	
	int status;
	L = openLua(WherigoOpen);
	if( L == NULL ){
		/*if( PDL_IsPlugin() ){
			// send error to UI
		}*/
		return 0;
	}
	
	// do bytecode from cartridge
	string bytecode = WherigoOpen->getCartDir();
	bytecode.append("wig.luac");
	
	//status = lua_cpcall(L, &pmain, &bytecode);
	status = luaL_dofile(L, bytecode.c_str());
	report(L, status);
	// create global Lua variable
	lua_setglobal(L, "cartridge"); // by http://wherigobuilder.wikispaces.com/Globals
	
	//stackdump_g(L);
	
#ifndef DESKTOP
	PDL_Err error = PDL_EnableLocationTracking(PDL_TRUE);
    if( error != PDL_NOERROR ){
		my_error("Could not init PDL Location Tracking: %s\n");
		my_error(SDL_GetError());
        exit(1);
	}
#endif

	
	return 1;
} 

static void closeCartridge(int *save){
	// @todo save
	
	//SDL_RemoveTimer(gpsTimer);
	
	delete WherigoOpen;
#ifndef DESKTOP
	PDL_EnableLocationTracking(PDL_FALSE);
#endif
    
	exit_lua();
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
	if( PDL_IsPlugin() ){
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
	} else 
#endif
		cerr << buffer->str() << endl;
	
	// move to starting coordinates and call update position
	cerr << "Updating position" << endl;
	buffer->str("");
	*buffer << "cartridge._update( Wherigo.ZonePoint("
		<< WherigoOpen->lat << ", " << WherigoOpen->lon << ", "
		<< WherigoOpen->alt << "), 1000 )";
	status = luaL_dostring(L, buffer->str().c_str());
	report(L, status);
	
	
	// run onStart event
	/*status = luaL_dostring(L, "cartridge.OnStart() ");
	report(L, status);*/
	lua_getfield(L, LUA_GLOBALSINDEX, "cartridge");	// [-0, +1, e]
	lua_getfield(L, -1, "OnStart");					// [-0, +1, e]
	lua_remove(L, -2);								// [-1, +0, -]
	status = lua_pcall(L, 0, 0, 0);					// [-1, +(0|1), -] [-(nargs + 1), +(nresults|1), -]
	report(L, status);								// [-(0|1), +0, -]
	
	
    delete buffer;

	updateStateToJS();
}

#ifndef DESKTOP
void UpdateGPS(PDL_Location *location){
	/*PDL_Location location;
	PDL_Err err = PDL_GetLocation(&location);
	if( err == PDL_NOERROR ){*/
		double acc = location->horizontalAccuracy;
		//int old_class = acc_class;
		bool update_all = false;
		stringstream ss;
		int status;
		
		if( location->latitude > -1 && location->longitude > -1 ){
			ss << "return cartridge._update(Wherigo.ZonePoint("
				<< location->latitude << ", " << location->longitude << "), 0)";
			status = luaL_dostring(L, ss.str().c_str());
			if( status == 0 ){
				update_all = lua_toboolean(L, 1);
				stackdump_g(L);
				lua_pop(L, 1);
			} else {
				report(L, status);
			}
			/*my_error("GPS updated successfully");
			my_error(ss.str());*/
			ss.str("");
		} else {
			//cerr << "No fix yet ... ignoring " << endl;
		}
		
		// only horizontal is what I need
		if( acc < 0 || acc > 1000 ){
			acc_class = 0;
		} else if( acc > 100 ){
			acc_class = 1;
		} else  if( acc > 50 ){
			acc_class = 2;
		} else if( acc > 20 ){
			acc_class = 3;
		} else {
			acc_class = 4;
		}
		
		if( update_all ){
			// try again??? 
		}
		updateStateToJS();
		/*} else if( old_class != acc_class ) {
			ss << "{\"type\": \"ok\", \"data\": {\n\"gps\": \""
				<< acc_class << "\"}\n}";
#ifndef DESKTOP
			if( PDL_IsPlugin() ){
				string str = ss.str();	
				const char * data = str.c_str();
				
				// send data back to the JavaScript side
				//syslog(LOG_WARNING, "*** update GPS State");
				PDL_Err err;
				err = PDL_CallJS("updateState", (const char **)&data, 1);
				if (err) {
					syslog(LOG_ERR, "*** PDL_CallJS failed, %s", PDL_GetError());
					return;
				}
				if( status == 1 ){
					return;
				}
			} else 
#endif
				cerr << ss.str() << endl;
		} else {
			//cerr << "No UI change, no gps change" << endl;
		}*/
	/*		
	} else {
		my_error("Get Location failed:");
		my_error(PDL_GetError());
	}*/
}

#endif

static void loop(){

#ifndef DESKTOP
	SDL_Event event;
    if (SDL_WaitEvent(&event)) {
        if (event.type == SDL_QUIT)
            exit(0);
        else if (event.type == SDL_USEREVENT) {
            //syslog(LOG_WARNING, "*** processing * event code = %d", event.user.code);
            switch( event.user.code ){
				/*case GET_METADATA:
					// extract our arguments
					char *cartridge = (char *)event.user.data1;
					
					// call our output function
					OutputMetadataToJS(cartridge);

					// free memory since this event is processed now
					free(cartridge);
					break;*/
				case PDL_GPS_UPDATE: {
					PDL_Location *loc = (PDL_Location *)event.user.data1;
					UpdateGPS(loc);
					//delete loc;
					}
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
					closeCartridge(save);
					delete save;
					}
					break;
				case EVENT_MESSAGE_BOX_RESPONSE: {
					char *value = (char *)event.user.data1;
					MessageBoxResponse(value);
					delete value;
					}
					break;
				case EVENT_GET_INPUT_RESPONSE: {
					char *value = (char *)event.user.data1;
					GetInputResponse(value);
					delete value;
					}
					break;
				case EVENT_CALLBACK: {
					char *e = (char *)event.user.data1;
					int *id = (int *)event.user.data2;
					CallbackFunction(e, id);
					delete e;
					delete id;
					}
					break;
				
				case EVENT_SET_POSITION_DEBUG: {
					double *lat = (double *)event.user.data1;
					double *lon = (double *)event.user.data2;
					setPosition(lat, lon);
					delete lat;
					delete lon;
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

  // alive UI
  while (1) {
    loop();
  }
}
