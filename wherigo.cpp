/* ========================================================================== */
/*                                                                            */
/*   Wherigo.cpp                                                              */
/*   (c) 2012 Jakuje                                                          */
/*                                                                            */
/*   Description                                                              */
/*                                                                            */
/* ========================================================================== */

#include "wherigo.h"
#include <syslog.h>

void my_error(string message){
	//fprintf(stderr, "%s", message);
	cerr << message << endl;
	syslog(LOG_WARNING, message.c_str());
}



bool Wherigo::setup(){
	fd.open( filename.c_str(), ios::in | ios::binary);
	if( ! fd.is_open() ){
		my_error("Error opening GWC file!!");
		return false;
	}

	if( ! scanHead() ){
		my_error("Wrong file - problem with GWC head");
		return false;
	}

	files = scanOffsets();
	if( files == 0 ){
		my_error("Wrong file - problem with offsets and ids");
		return false;
	}

	if( ! scanHeader() ){
		my_error("Wrong file - problem with GWC header");
		return false;
	}

	return true;
  
}

/**
 * Scan newly opened file (without offset) for head
 * inspiration in specs at WherUGo: 
 * http://code.google.com/p/wherugo/wiki/GWC
 */ 
bool Wherigo::scanHead (){
	unsigned char CART_ID[] = { 0x02, 0x0a, 0x43, 0x41, 0x52, 0x54, 0x00 };
						// 02 0a CART 00
	int size = sizeof(CART_ID);
	char *data = new char [size];
	fd.read(data, size);
	int i = 0;
	while(i < size ){
		if( CART_ID[i] != data[i] ){
			stringstream t;
			t << i << ": " << CART_ID[i] << "_" << data[i];
			my_error( t.str() );
			delete [] data;
			return false;
		}
		i++;
	}
	delete [] data;
	return true;   
}

/**
 * Scan file for offsets for every bytecode
 */ 
int Wherigo::scanOffsets (){
	files = fd.readUShort();
	
	ids = new int[files];
	offsets = new long[files];
	
	for(int i = 0;i < files; i++){
		ids[i] = fd.readUShort();
		offsets[i] = fd.readLong();
	}
	return files;
}

/**
 * Scan file for offsets for every bytecode
 * for now throw data away 
 */ 
bool Wherigo::scanHeader (){
	
	/*int len = */fd.readLong(); // header length
	
	lat = fd.readDouble(); // latitude
	lon = fd.readDouble(); // longitude

	// altitude (by https://github.com/wijnen/python-wherigo/blob/master/wherigo.py)
	alt = fd.readDouble(); 
	/*fd.readLong();
	fd.readLong();*/
	fd.readLong();
	fd.readLong();// unknown values

	splashID = fd.readShort();
	iconID = fd.readShort();
	
	type = fd.readASCIIZ();
	player = fd.readASCIIZ();
	
	fd.readLong();
	fd.readLong();// unknown values
	
	cartridgeName = fd.readASCIIZ();
	cartridgeGUID = fd.readASCIIZ();
	cartridgeDescription = fd.readASCIIZ();
	startingLocationDescription = fd.readASCIIZ();
	version = fd.readASCIIZ();
	author = fd.readASCIIZ();
	company = fd.readASCIIZ();
	recomandedDevice = fd.readASCIIZ();
	
	fd.readLong(); // unknown

	completionCode = fd.readASCIIZ();
	
	return true;
}

bool Wherigo::createBytecode(string tmpname){
	fd.seekg( offsets[0] );
	int len = fd.readLong();
	char *lua = new char [len];
	fd.read(lua, len);
	
	ofstream f( tmpname.c_str(), ios_base::out | ios_base::binary);
	f.write(lua, len);
	f.close();
	delete [] lua;
  
	return true;
}

bool Wherigo::createIcons(){
	bool ok = this->createFileById(this->iconID, string(DATA_DIR).append(this->cartridgeGUID).append("_icon.png"));
	ok = this->createFileById(this->splashID, string(DATA_DIR).append(this->cartridgeGUID).append("_splash.png")) && ok;
	return ok;
}

/**
 * Creates file by global ID
 */
bool Wherigo::createFileById(int id, string path){
	for(int i = 1;i < files; i++){
		if( ids[i] == id ){
			this->createFile(i, path);
			return true;
		}
	}
	return false;
}

/**
 * Creates file by internal index
 */
bool Wherigo::createFile(int i, string path){
	if( i < files ){
		fd.seekg( offsets[i] );
		if( fd.readByte() == 0 ){
			return false;
		}
		/*int type = */fd.readLong(); // will use to export to lua
		int len = fd.readLong();
		char *data = new char [len];
		fd.read(data, len);
		
		ofstream f( path.c_str(), ios_base::out | ios_base::binary);
		f.write(data, len);
		f.close();
		delete [] data;
		return true;
	} else {
		return false;
	}
}

bool Wherigo::createFiles(){
	ostringstream str;
	string path = string(tmpdir).append("/");
	for(int i = 1;i < files; i++){
		str.str("");
		str << ids[i];
		this->createFile(i, string(path).append(str.str()));
	}
	return true;
}

int Wherigo::createTmp(){
	tmpdir = strdup("/tmp/wig.lua.XXXXXX");
	tmpdir = mkdtemp(tmpdir);
	if( tmpdir == NULL ){
		my_error("Failed to init tmp dir");
		return EXIT_FAILURE;
	}
	string file_bytecode = string(tmpdir);
	file_bytecode.append("/wg.lua");
	this->createBytecode(file_bytecode);
	this->createFiles( );
	return EXIT_SUCCESS;
}
