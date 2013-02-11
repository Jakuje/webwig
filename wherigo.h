/* ========================================================================== */
/*                                                                            */
/*   Wherigo.h                                                                */
/*   (c) 2012 Jakuje                                                          */
/*                                                                            */
/*   Description                                                              */
/*                                                                            */
/* ========================================================================== */
#include <string>
#include "filereader.h"

const string DATA_DIR = "/media/internal/appdata/com.dta3team.app.wherigo/";
const string CONF_DIR = DATA_DIR;
const string CONFIG_FILE = "database.json";

using namespace std;

void my_error(string message);

class Wherigo {
public:
	string filename;
	fileReader fd;
	char *tmpdir;

	int *ids; 
	long *offsets;
	int files;

	double lat;
	double lon;
	double alt;

	int splashID;
	int iconID;

	string type;
	string player;

	string cartridgeName;
	string cartridgeGUID;
	string cartridgeDescription;
	string startingLocationDescription;
	string version;
	string author;
	string company;
	string recomandedDevice;


	Wherigo( string filename ){
		this->filename = filename;
		this->ids = NULL;
		this->offsets = NULL;
		this->tmpdir = NULL;
	}

	~Wherigo(){
		if( ids != NULL ){
			delete ids;
		}
		if( offsets != NULL ){
			delete offsets;
		}
		fd.close();
		if( tmpdir != NULL ){
			remove(tmpdir);
			delete tmpdir;
		}
	}

	int setup();

	bool scanHead ();

	int scanOffsets ();

	bool scanHeader ();

	char *getTmp(){ return tmpdir; }

	bool createBytecode(string *tmpname);

	bool createIcons();
	
	bool createFileById(int id, string path);
	
	bool createFile(int i, string path);
	
	bool createFiles();

	int createTmp();

};

