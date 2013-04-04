/* ========================================================================== */
/*                                                                            */
/*   Engine.hpp                                                               */
/*   (c) 2013 Jakuje                                                          */
/*                                                                            */
/*   Description                                                              */
/*                                                                            */
/* ========================================================================== */
#ifndef ENGINE_H
#define ENGINE_H

#include <string>
#include <glob.h>
#include <sys/stat.h>
#include <SDL.h>

#ifndef DESKTOP
#include "PDL.h"
#endif


using namespace std;

namespace Engine
{
	/*static PDL_bool CallbackFunctionJS(PDL_JSParameters *params);
	static PDL_bool GetInputResponseJS(PDL_JSParameters *params);
	static PDL_bool MessageBoxResponseJS(PDL_JSParameters *params);
	static void OutputCartridges(stringstream *buf, int *refresh);
	static bool OutputMetadata(stringstream *buf, const char *cartridge, bool first);
	static void ShowScreen();
	static void UpdateGPS(PDL_Location *location);
	static PDL_bool closeCartridgeJS(PDL_JSParameters *params);
	static PDL_bool getCartridgesJS(PDL_JSParameters *params);
	static PDL_bool openCartridgeJS(PDL_JSParameters *params);
	static PDL_bool setPositionJS(PDL_JSParameters *params);*/
	
	enum EVENT_CODES {
		EVENT_GET_CARTRIDGES,
		EVENT_OPEN_CARTRIDGE,
		EVENT_CLOSE_CARTRIDGE,
		EVENT_MESSAGE_BOX_RESPONSE,
		EVENT_GET_INPUT_RESPONSE,
		EVENT_CALLBACK,
		EVENT_TIMER,
		EVENT_SYNC,
		EVENT_SWITCH_GPS,
		EVENT_SHOW_MAP,

		EVENT_SET_POSITION_DEBUG,
		EVENT_MOVE_POSITION_DEBUG
		};
	
	extern void MessageBox(const char *text, string media,
		const char *button1, const char *button2, const char *callback);
	extern void Dialog(const char *text, string media);
	
	extern void RequestSync();
	
	extern void PlayAudio(string media);	
	extern void stopSound();
	extern void Alert();
	extern void ShowStatusText(const char *text);
	extern void GetInput(const char *type, const char *text, const char* choices, string media);	
	
	extern void ClosePrompt();
	
	extern int openCartridge(char *filename);
	extern void closeCartridge(int * save);
	
	extern Uint32 addTimerEvent(Uint32 interval, void *param);
	
	extern void updateState();
	
	extern void setPosition(double *lat, double * lon);
	extern bool openCartridgeToJS(char *filename, int *load_game);
	extern void OutputCartridgesToJS(int *refresh);
	extern void showMapResponse(string data);
	
	extern void setup(int argc, char **argv);
	extern void loop();
}


#endif
