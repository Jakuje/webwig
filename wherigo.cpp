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



int Wherigo::setup(){
	fd.open( filename.c_str(), ios::in | ios::binary);
	if( ! fd.is_open() ){
		my_error("Error opening GWC file!!");
		return EXIT_FAILURE;
	}

	if( ! scanHead() ){
		my_error("Wrong file - problem with GWC head");
		return EXIT_FAILURE;
	}

	files = scanOffsets();
	if( files == 0 ){
		my_error("Wrong file - problem with offsets and ids");
		return EXIT_FAILURE;
	}

	if( ! scanHeader() ){
		my_error("Wrong file - problem with GWC header");
		return EXIT_FAILURE;
	}

	return EXIT_SUCCESS;
  
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
			return false;
		}
		i++;
	}
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
	
	int len = fd.readLong(); // header length
	
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

	string completionCode = fd.readASCIIZ();
	
	return true;
}

bool Wherigo::createBytecode(string *tmpname){
	fd.seekg( offsets[0] );
	int len = fd.readLong();
	char *lua = new char [len];
	fd.read(lua, len);
	
	ofstream f( tmpname->c_str(), ios_base::out | ios_base::binary);
	f.write(lua, len);
	f.close();
	delete lua;
  
	return true;
}

bool Wherigo::createFiles(){
	ostringstream str;
	string path = string(tmpdir).append("/");
	for(int i = 1;i < files; i++){
		fd.seekg( offsets[i] );
		if( fd.readByte() == 0 ){
			continue;
		}
		str.str("");
		str << ids[i];
		int type = fd.readLong();
		int len = fd.readLong();
		char *data = new char [len];
		fd.read(data, len);
		
		string filename = string(path).append(str.str());
		ofstream f( filename.c_str(), ios_base::out | ios_base::binary);
		f.write(data, len);
		f.close();
		delete data;
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
	string *file_bytecode = new string(tmpdir);
	file_bytecode->append("/wg.lua");
	this->createBytecode(file_bytecode);
	this->createFiles( );
	return EXIT_SUCCESS;
}
