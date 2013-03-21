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
#include "PDL.h"


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

		EVENT_SET_POSITION_DEBUG
		};
	
	extern void MessageBox(const char *text, string media,
		const char *button1, const char *button2, const char *callback);
	
	extern void PlayAudio(string media);	
	extern void ShowStatusText(const char *text);
	extern void GetInput(const char *type, const char *text, const char* choices, string media);	
	
	extern int openCartridge(char *filename);
	extern void closeCartridge(int * save);
	
	extern Uint32 addTimerEvent(Uint32 interval, void *param);
	
	extern void updateState();
	
	extern void setPosition(double *lat, double * lon);
	extern bool openCartridgeToJS(char *filename);
	extern void OutputCartridgesToJS(int *refresh);
	
	extern void setup(int argc, char **argv);
	extern void loop();
}


#endif
