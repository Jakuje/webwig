#include "Engine.hpp"
#include "WherigoLib.hpp"
#include <syslog.h>


namespace Engine
{

/** Accuracy class for image in UI */
int gps_accuracy = -1;
int gps_state = 0;
double gps_heading = 0;



/** Call user interface connector to show message */
void MessageBox(const char *text, std::string media,
	const char *button1, const char *button2, const char *callback){

#ifndef DESKTOP
    PDL_Err err;
    const char *c = (strcmp(callback,"1") == 0 ? "1" : "0");
    const char *params[5];
    params[0] = text;
    params[1] = media.c_str();
    params[2] = button1;
    params[3] = button2;
    params[4] = c;
    err = PDL_CallJS("MessageBox", params, 5);
    if (err) {
        syslog(LOG_ERR, "*** PDL_CallJS failed, %s", PDL_GetError());
        //SDL_Delay(5);
    }
#else
	/*if( callback ){
		luaL_dostring(L, "Wherigo._MessageBoxResponse(\"ok\")");
	}*/
#endif

}

void Dialog(const char *text, std::string media){

#ifndef DESKTOP
    PDL_Err err;
    const char *params[2];
    params[0] = text;
    params[1] = media.c_str();
    err = PDL_CallJS("Dialog", params, 2);
    if (err) {
        syslog(LOG_ERR, "*** PDL_CallJS failed, %s", PDL_GetError());
        //SDL_Delay(5);
    }
#endif

}

void ClosePrompt(){

#ifndef DESKTOP
    PDL_Err err;
    err = PDL_CallJS("ClosePrompt", NULL, 0);
    if (err) {
        syslog(LOG_ERR, "*** PDL_CallJS failed, %s", PDL_GetError());
        //SDL_Delay(5);
    }
#endif

}

void RequestSync(){
	SDL_Event event;
	SDL_UserEvent userevent;

	userevent.type = SDL_USEREVENT;
	userevent.code = EVENT_SYNC;
	userevent.data1 = NULL;
	userevent.data2 = NULL;

	event.type = SDL_USEREVENT;
	event.user = userevent;

	SDL_PushEvent(&event);
	
}

/** Play audio in user interface */
void PlayAudio(string media) {
#ifndef DESKTOP
    PDL_Err err;
    const char *params = media.c_str();
    err = PDL_CallJS("playAudio", (const char **)&params, 1);
    if (err) {
        syslog(LOG_ERR, "*** PDL_CallJS failed, %s", PDL_GetError());
        //SDL_Delay(5);
    }
#endif
}

void stopSound(){
#ifndef DESKTOP
    PDL_Err err;
    err = PDL_CallJS("stopSound", NULL, 0);
    if (err) {
        syslog(LOG_ERR, "*** PDL_CallJS failed, %s", PDL_GetError());
        //SDL_Delay(5);
    }
#endif
}

void Alert(){
#ifndef DESKTOP
    PDL_Err err;
    err = PDL_CallJS("Alert", NULL, 0);
    if (err) {
        syslog(LOG_ERR, "*** PDL_CallJS failed, %s", PDL_GetError());
        //SDL_Delay(5);
    }
#endif
}

/** Show status text (deprecated) */
void ShowStatusText(const char *text) {
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

void GetInput(const char *type, const char *text, const char* choices, string media) {
#ifndef DESKTOP
    PDL_Err err;
    const char *params[4];
    params[0] = type;
    params[1] = text;
    params[2] = choices;
    params[3] = media.c_str();
    err = PDL_CallJS("GetInput", params, 4);
    if (err) {
        syslog(LOG_ERR, "*** PDL_CallJS failed, %s", PDL_GetError());
        //SDL_Delay(5);
    }
#endif

}

/** Open cartridge */
int openCartridge(char *filename){
	if(WherigoLib::openCartridge(filename)){
		return 1;
	}
	return 0;
}

/** Close cartridge */
void closeCartridge(int * save){
	WherigoLib::closeCartridge(save);
#ifndef DESKTOP
	PDL_EnableLocationTracking(PDL_FALSE);
#endif
}

/** Callback after timer expires */
Uint32 addTimerEvent(Uint32 interval, void *param){
	SDL_Event event;
	SDL_UserEvent userevent;

	/*int *ObjId = new int;
	ObjId = (int *) param;*/
	
	userevent.type = SDL_USEREVENT;
	userevent.code = EVENT_TIMER;
	userevent.data1 = param;
	userevent.data2 = NULL;

	event.type = SDL_USEREVENT;
	event.user = userevent;

	SDL_PushEvent(&event);
	// cancel timer
	return 0;
}

/** Process saved show_screen action */
void ShowScreen(){
	if( WherigoLib::show_screen ){
#ifndef DESKTOP
		PDL_Err err;
		const char *params[2];
		params[0] = WherigoLib::show_screen;
		params[1] = WherigoLib::show_detail;
		err = PDL_CallJS("showScreen", params, 2);
		if (err) {
			syslog(LOG_ERR, "*** PDL_CallJS failed, %s", PDL_GetError());
			//SDL_Delay(5);
		}
#endif
		free(WherigoLib::show_screen);
		free(WherigoLib::show_detail);
		WherigoLib::show_screen = NULL;
		WherigoLib::show_detail = NULL;
	}
	return;
}

void showMapResponse(string str){
#ifndef DESKTOP
	PDL_Err err;
	const char *data = str.c_str();
	err = PDL_CallJS("showMapResponse", (const char **)&data, 1);
	if (err) {
		syslog(LOG_ERR, "*** PDL_CallJS failed, %s", PDL_GetError());
		//SDL_Delay(5);
	}
#endif
}

/** Get current configuration and send update to UI */
void updateState(){
	stringstream *buffer = new stringstream(stringstream::in | stringstream::out);
	
	/*cerr << "Getting state" << endl;
	status = luaL_dostring(L, "return Wherigo._getUI()");
	report(L, status);*/
	
	*buffer << "{\"type\": \"ok\", \"data\": \n"
		<< "{"
			<< WherigoLib::getUI()
			<< ", \"gps\": {"
				<< "\"acc\": " << gps_accuracy
				<< ", \"state\": " << gps_state
				//<< ", \"fix\": \"" << gps_fix << "\""
				<< ", \"heading\": " << gps_heading
				<< "}"
			<< "}"
		<< "}";

	
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
		ShowScreen();
	} else 
#endif
		cerr << buffer->str() << endl;
	
    delete buffer;
    
}

#ifndef DESKTOP
/**
 * @param filename (string) Filename to open and start
 */
PDL_bool openCartridgeJS(PDL_JSParameters *params)
{
    if (PDL_GetNumJSParams(params) != 3) {
        syslog(LOG_INFO, "**** wrong number of parameters for getMetadata");
        PDL_JSException(params, "wrong number of parameters for getMetadata");
        return PDL_FALSE;
    }

    /* parameters are directory, pattern */
    const char *filename = PDL_GetJSParamString(params, 0);
    int *flags = new int;
    *flags = PDL_GetJSParamInt(params, 1);
    *flags = *flags | ( PDL_GetJSParamInt(params, 2) << 4);

    /* since we don't process this in the method thread, instead post a
     * SDL event that will be received in the main thread and used to 
     * launch the code. */
    SDL_Event event;
    event.user.type = SDL_USEREVENT;
    event.user.code = EVENT_OPEN_CARTRIDGE;
    event.user.data1 = strdup(filename);
    event.user.data2 = flags;
    
    syslog(LOG_WARNING, "*** sending openCartridge event");
    SDL_PushEvent(&event);
    
    return PDL_TRUE;
}

/**
 * @param save (int) Save cartridge or not
 */
PDL_bool closeCartridgeJS(PDL_JSParameters *params)
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
PDL_bool getCartridgesJS(PDL_JSParameters *params)
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
PDL_bool MessageBoxResponseJS(PDL_JSParameters *params)
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
PDL_bool GetInputResponseJS(PDL_JSParameters *params)
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


PDL_bool CallbackFunctionJS(PDL_JSParameters *params){
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

PDL_bool setPositionJS(PDL_JSParameters *params){
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
    
    //syslog(LOG_WARNING, "*** sending setPosition event");
    SDL_PushEvent(&event);
    
    return PDL_TRUE;
}

PDL_bool movePositionJS(PDL_JSParameters *params){
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
    event.user.code = EVENT_MOVE_POSITION_DEBUG;
    event.user.data1 = lat;
    event.user.data2 = lon;
    
    //syslog(LOG_WARNING, "*** sending movePosition event");
    SDL_PushEvent(&event);
    
    return PDL_TRUE;
}

PDL_bool switchGPSJS(PDL_JSParameters *params){
	if (PDL_GetNumJSParams(params) != 1) {
        syslog(LOG_INFO, "**** wrong number of parameters for setPosition");
        PDL_JSException(params, "wrong number of parameters for setPosition");
        return PDL_FALSE;
    }

    int *newState = new int;
    *newState = PDL_GetJSParamInt(params, 0);
    
    SDL_Event event;
    event.user.type = SDL_USEREVENT;
    event.user.code = EVENT_SWITCH_GPS;
    event.user.data1 = newState;
    event.user.data2 = NULL;
    
    SDL_PushEvent(&event);
    
    return PDL_TRUE;
}

PDL_bool saveJS(PDL_JSParameters *params){
	if (PDL_GetNumJSParams(params) != 0) {
        syslog(LOG_INFO, "**** wrong number of parameters for setPosition");
        PDL_JSException(params, "wrong number of parameters for setPosition");
        return PDL_FALSE;
    }

    SDL_Event event;
    event.user.type = SDL_USEREVENT;
    event.user.code = EVENT_SYNC;
    event.user.data1 = NULL;
    event.user.data2 = NULL;
    
    SDL_PushEvent(&event);
    
    return PDL_TRUE;
}

PDL_bool showMapJS(PDL_JSParameters *params){
	if (PDL_GetNumJSParams(params) != 1) {
        syslog(LOG_INFO, "**** wrong number of parameters for setPosition");
        PDL_JSException(params, "wrong number of parameters for setPosition");
        return PDL_FALSE;
    }
	int *zone_id = new int;
	*zone_id = PDL_GetJSParamInt(params, 0);

    SDL_Event event;
    event.user.type = SDL_USEREVENT;
    event.user.code = EVENT_SHOW_MAP;
    event.user.data1 = zone_id;
    event.user.data2 = NULL;
    
    syslog(LOG_WARNING, "*** sending showMap event");
    SDL_PushEvent(&event);
    
    return PDL_TRUE;
}

#endif

void setup(int argc, char **argv)
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
        return;
#ifndef DESKTOP
    }
    
	PDL_RegisterJSHandler("getCartridges", getCartridgesJS);
    PDL_RegisterJSHandler("openCartridge", openCartridgeJS);
    PDL_RegisterJSHandler("closeCartridge", closeCartridgeJS);
    PDL_RegisterJSHandler("MessageBoxResponse", MessageBoxResponseJS);
    PDL_RegisterJSHandler("GetInputResponse", GetInputResponseJS);
    PDL_RegisterJSHandler("CallbackFunction", CallbackFunctionJS);
    PDL_RegisterJSHandler("setPosition", setPositionJS);
    PDL_RegisterJSHandler("movePosition", movePositionJS);
    PDL_RegisterJSHandler("switchGPS", switchGPSJS);
    PDL_RegisterJSHandler("save", saveJS);
    PDL_RegisterJSHandler("showMap", showMapJS);
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

#ifndef DESKTOP
void UpdateGPS(PDL_Location *location){
	/*PDL_Location location;
	PDL_Err err = PDL_GetLocation(&location);
	if( err == PDL_NOERROR ){*/
		double acc = location->horizontalAccuracy;
		//int old_class = acc_class;
		bool update_all = false;
		
		if( location->latitude > -1 && location->longitude > -1 ){
			update_all = WherigoLib::updateLocation(&location->latitude, &location->longitude,
				&location->altitude, &location->horizontalAccuracy);
			/*my_error("GPS updated successfully");
			my_error(ss.str());*/
		} else {
			//cerr << "No fix yet ... ignoring " << endl;
		}
		
		// only horizontal is what I need
		
		gps_accuracy = (int) acc;
		gps_state = 1;
		gps_heading = location->heading;
		
		if( update_all ){
			// try again or what?
		}
		updateState();
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

bool OutputMetadata(stringstream *buf, const char *cartridge, bool first = true){
	string filename( DATA_DIR );
	filename.append(cartridge);
	Wherigo *w = new Wherigo(filename);
	if( w->setup() == false ){
		delete w;
		return false;		
	}
	//w->createIcons();
	
	ifstream ifile(w->getSaveFilename().c_str());
	string is_saved = "false";
	if (ifile) {
	  is_saved = "true";
	}
	
	if (!first) {
		*buf << ",\n";
	}
	string *icon = w->getFilePathById(w->iconID);
	string *splash = w->getFilePathById(w->splashID);
	*buf << "{\n"
		<< "\"filename\": \"" << WherigoLib::escapeJsonString(string(cartridge)) << "\""
		<< ",\"icon\": \"" << *icon << "\""
		<< ",\"splash\": \"" << *splash << "\""
		<< ",\"type\": \"" << w->type << "\""
		<< ",\"name\": \"" << WherigoLib::escapeJsonString(w->cartridgeName) << "\""
		<< ",\"guid\": \"" << w->cartridgeGUID << "\""
		<< ",\"description\": \"" << WherigoLib::escapeJsonString(w->cartridgeDescription) << "\""
		<< ",\"startingLocationDescription\": \"" << WherigoLib::escapeJsonString(w->startingLocationDescription) << "\""
		<< ",\"latitude\": " << w->lat
		<< ",\"longitude\": " << w->lon
		<< ",\"version\": \"" << w->version << "\""
		<< ",\"author\": \"" << WherigoLib::escapeJsonString(w->author) << "\""
		<< ",\"company\": \"" << WherigoLib::escapeJsonString(w->company) << "\""
		<< ",\"saved\": " << is_saved << ""
		<< "\n}";
	delete icon;
	delete splash;
	delete w;
	return true;
}

void OutputCartridges(stringstream *buf, int *refresh){
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

void OutputCartridgesToJS(int *refresh)
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

bool openCartridgeToJS(char *filename, int* load_game){
	stringstream *buffer = new stringstream(stringstream::in | stringstream::out);
	int status = 0;
	if( openCartridge(filename) ){
		*buffer << "{\"type\": \"ok\", \"data\": {\n"
				//<< "\"cartDir\": \"" << WherigoLib::WherigoOpen->cartDir << "\","
				<< WherigoLib::getStaticData()
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
			return false;
		}
	} else 
#endif
		cerr << buffer->str() << endl;

	if( status == 1 ){
		return false;
	}
	
	WherigoLib::OnStartEvent(load_game);
	
    delete buffer;

	updateState();
	return true;
}

void setPosition(double *lat, double * lon){
	
#ifndef DESKTOP
	// disable autoupdate
	PDL_EnableLocationTracking(PDL_FALSE);
#endif
	gps_accuracy = -1;
	gps_state = 0;
	gps_heading = 0;
	double alt = 115;
	WherigoLib::updateLocation(lat, lon, &alt, &alt);
	updateState();
}

void movePosition(double *lat, double * lon){
	
	gps_accuracy = -1;
	gps_heading = 0;
	WherigoLib::moveLocation(lat, lon);
	updateState();
}

void switchGPS(int *newState){
	
#ifndef DESKTOP
	if( *newState == 1 ){
		PDL_EnableLocationTracking(PDL_TRUE);
	} else {
		PDL_EnableLocationTracking(PDL_FALSE);
	}
#endif
	gps_accuracy = -1;
	gps_state = *newState;
	gps_heading = 90;
	//double alt = 115;
	updateState();
}



void loop(){

#ifndef DESKTOP
	SDL_Event event;
    if (SDL_WaitEvent(&event)) {
        if (event.type == SDL_QUIT)
            exit(0);
        else if (event.type == SDL_USEREVENT) {
            //syslog(LOG_WARNING, "*** processing * event code = %d", event.user.code);
            switch( event.user.code ){
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
					int *flags = (int *)event.user.data2;
					int load_game = (*flags & 0x01);
					int start_gps = (*flags >> 4 & 0x01);
					openCartridgeToJS(filename, &load_game);
					if( start_gps ){
						switchGPS(&start_gps);
					}
					delete filename;
					delete flags;
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
					WherigoLib::MessageBoxResponse(value);
					delete value;
					}
					break;
				case EVENT_GET_INPUT_RESPONSE: {
					char *value = (char *)event.user.data1;
					WherigoLib::GetInputResponse(value);
					delete value;
					}
					break;
				case EVENT_CALLBACK: {
					char *e = (char *)event.user.data1;
					int *id = (int *)event.user.data2;
					WherigoLib::CallbackFunction(e, id);
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
				case EVENT_MOVE_POSITION_DEBUG: {
					double *lat = (double *)event.user.data1;
					double *lon = (double *)event.user.data2;
					movePosition(lat, lon);
					delete lat;
					delete lon;
					}
					break;
				case EVENT_SWITCH_GPS: {
					int *newState = (int *)event.user.data1;
					switchGPS(newState);
					delete newState;
					}
					break;
				case EVENT_TIMER: {
					int *ObjId = (int *)event.user.data1;
					WherigoLib::timerTick(ObjId);
					}
					break;
				case EVENT_SYNC:
					WherigoLib::sync();
					break;
				case EVENT_SHOW_MAP: {
					int *zone_id = (int*) event.user.data1;
					WherigoLib::showMap(zone_id);
					delete zone_id;
					}
					break;
			}
        }
    }
#endif
}

}


