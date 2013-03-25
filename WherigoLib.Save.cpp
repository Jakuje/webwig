#include "WherigoLib.Save.hpp"
#include "WherigoLib.hpp"

namespace WherigoLib {
	namespace Save {

/** GWS header */
unsigned char GWS_SIG[] = { 0x02, 0x0a, 0x53, 0x59, 0x4e, 0x43, 0x00 };

using namespace std;

/** Lua_Writer called by lua_dump for functions */
int writeLuaDump(lua_State *L, const void * p, size_t sz, void * ud){
	fileWriter *sf = (fileWriter *) ud;
	sf->writeLong(sz);
	sf->writeASCII( (const char *)p, sz);
	return 0;
}

/** Table must be on index of L environment */
void serialize_table(fileWriter *sf, int index, bool functions = false){
	int i;
	size_t size;
	const char *name;
	bool skip;
	sf->writeByte(0x05); // start of table
	lua_pushnil(L);														// [-0, +1, -]
	while (lua_next(L, index-1) != 0) {									// [-1, +(2|0), e]
		skip = false;
		if( ! functions && lua_isfunction(L, -1) ){
			lua_pop(L, 1);
			continue; // for the start, exclude all functions; @todo include events function or exclude my functions
		}
		for(i = -2; i <= -1; i++){
			if( skip ){
				break; // key was excludes, so don't include value
			}
			switch( lua_type(L, i) ){
				case LUA_TBOOLEAN:
					sf->writeByte(0x01);
					sf->writeByte( lua_toboolean(L, i) );
					break;
				case LUA_TNUMBER:
					sf->writeByte(0x02);
					sf->writeDouble( lua_tonumber(L, i) );
					break;
				case LUA_TSTRING:
					name = lua_tostring(L, i);
					// look in 
					if( i == -2 && (name[0] == '_' || strcmp(name, "Cartridge") == 0 
						|| strcmp(name, "Resources") == 0 || string(name).compare(0, 4, "AllZ") == 0) ){
						skip = true;
						break;
					}
					size = lua_objlen(L, i);
					sf->writeByte(0x03);
					sf->writeLong(size);
					sf->writeASCII(name, size);
					break;
				case LUA_TFUNCTION: // i should be -1
					sf->writeByte(0x04);
					// length is written "inside" writeLuaDump
					lua_dump(L, (lua_Writer)writeLuaDump, sf);
					break;
				case LUA_TTABLE: // i should be -1 => table as ke is useless
					lua_getfield(L, i, "ObjIndex");						// [-0, +1, e]
					if( !lua_isnoneornil(L, -1) ){
						sf->writeByte(0x07);
						sf->writeUShort( lua_tointeger(L, -1) );
						lua_pop(L, 1);									// [-1, +0, e]
						break;
					}
					lua_pop(L, 1);										// [-1, +0, e]
					lua_getfield(L, i, "_classname");					// [-0, +1, e]
					if( ! lua_isnoneornil(L, -1) ){
						sf->writeByte(0x08); // Object
						name = lua_tostring(L, -1);
						size = lua_objlen(L, -1);
						sf->writeLong(size);
						sf->writeASCII(name, size);
					}
					lua_pop(L, 1);										// [-1, +0, e]
					serialize_table(sf, i);
					break;
				default:
					sf->writeASCIIZ("UNKNOWN", 7);
					cerr << "Unknown data to serialize" << lua_typename(L, lua_type(L, -2)) << endl;
			}
		}
		lua_pop(L, 1);								// [-1, +0, -]
	}
	sf->writeByte(0x06);
	
}

/** Save Game */
bool sync(){
	WherigoOpen->log("ZCartridge:Sync");
	
	string save_filename = WherigoOpen->getSaveFilename();
	fileWriter sf;
	sf.open(save_filename.c_str() , ios::out | ios::binary);
	
	sf.writeASCII( (char *) &GWS_SIG, 7 );
	long header_length = WherigoOpen->cartridgeName.length()+1 + 8 +
		WherigoOpen->player.length()+1 + WherigoOpen->recomandedDevice.length()+1 +
		5+1 + 8 + 17+1 + 8 + 8 + 8;
	sf.writeLong(header_length);
	sf.writeASCIIZ( WherigoOpen->cartridgeName.c_str(), WherigoOpen->cartridgeName.length() );
	sf.writeLong( 0 ); // date of creation 8 byte ???
	sf.writeLong( 0 );
	sf.writeASCIIZ( WherigoOpen->player.c_str(), WherigoOpen->player.length() );
	sf.writeASCIIZ( WherigoOpen->recomandedDevice.c_str(), WherigoOpen->recomandedDevice.length() );
	sf.writeASCIIZ( "WebOS", 5 ); // device ID
	sf.writeLong( 0 ); // date of save 8 byte
	sf.writeLong( 0 );
	sf.writeASCIIZ( "UI initiated sync", 17 ); // Name of save
	sf.writeDouble( WherigoLib::latitude );
	sf.writeDouble( WherigoLib::longitude );
	sf.writeDouble( WherigoLib::altitude );
	
	lua_getfield(L, LUA_GLOBALSINDEX, "cartridge");						// [-0, +1, e]
	lua_getfield(L, -1, "AllZObjects");									// [-0, +1, e]
	lua_remove(L, -2);													// [-1, +0, -]
	size_t size;
	const char *name;
	
	size = lua_objlen(L, -1);
	sf.writeLong( size + 1 ); // num of zobjects + 1
	
	// write types of AllZObjects
	lua_pushnil(L);														// [-0, +1, -]
	bool first = true;
	while (lua_next(L, -2) != 0) {										// [-1, +(2|0), e]
		if( first ) { // do not write cartridge object?
			lua_pop(L,1);
			first = false;
			continue;
		}
		/*printf("%s - %s\n",
			lua_typename(L, lua_type(L, -2)),
			lua_typename(L, lua_type(L, -1)));*/
		lua_getfield(L, -1, "_classname");			// [-0, +1, e]
		
		name = lua_tostring(L, -1);
		size = lua_objlen(L, -1);
		sf.writeLong( size );
		sf.writeASCII( name, size );
		lua_pop(L, 2);								// [-2, +0, -]
	}
	
	// dump Player object
	sf.writeLong(10);
	sf.writeASCII("ZCharacter", 10);
	lua_getfield(L, LUA_GLOBALSINDEX, "Wherigo");	// [-0, +1, e]
	lua_getfield(L, -1, "Player");					// [-0, +1, e]
	lua_remove(L, -2);								// [-1, +0, -]
	
	serialize_table(&sf, -1, false);
	lua_pop(L, 1);									// [-1, +0, -]
	
	// dump cartridge object
	/*sf.writeLong(10);
	sf.writeASCII("ZCartridge", 10);
	lua_getfield(L, LUA_GLOBALSINDEX, "cartridge");	// [-0, +1, e]
	
	serialize_table(&sf, -1, false);
	lua_pop(L, 1);									// [-1, +0, -]
	*/
	
	// write details of AllZObjects
	lua_pushnil(L);
	while (lua_next(L, -2) != 0) {					// [-1, +(2|0), e]
		lua_getfield(L, -1, "_classname");			// [-0, +1, e]
		
		name = lua_tostring(L, -1);
		size = lua_objlen(L, -1);
		sf.writeLong( size );
		sf.writeASCII( name, size );
		lua_pop(L, 1);								// [-1, +0, -]

		serialize_table(&sf, -1);
		
		lua_pop(L, 1);								// [-1, +0, -]
	}
	lua_pop(L, 1);									// [-1, +0, -]
	
	stackdump_g(L); // check if is empty at the end
	
	sf.close();
	return true;
}

bool read_table(fileReader *fd, int index){
	// @todo some Pushdown automaton (zasobnikovy automat)
	return true;
}

bool restore(){
	string save_filename = WherigoOpen->getSaveFilename();
	fileReader fd;
	fd.open(save_filename.c_str() , ios::in | ios::binary);
	if( ! fd.good() ){
		cerr << "savefile doesn't exists" << endl;
		return false;
	}
	
	// check header
	int size = sizeof(GWS_SIG);
	char *data = new char [size];
	fd.read(data, size);
	int i = 0;
	while(i < size ){
		if( GWS_SIG[i] != data[i] ){
			stringstream t;
			t << i << ": " << GWS_SIG[i] << "_" << data[i];
			my_error( t.str() );
			delete [] data;
			fd.close();
			cerr << "restore failed" << endl;
			return false;
		}
		i++;
	}
	delete [] data;
	
	string pom;
	int header_length = fd.readLong();
	fd.readASCIIZ( &pom );
	if( pom.compare(WherigoOpen->cartridgeName) != 0 ){
		fd.close();
		cerr << "Savegame is made for other cartridge name. Got " << pom
			<< ", expected " << WherigoOpen->cartridgeName << endl;
		return false;
	}
	fd.readLong();
	fd.readLong(); // date of creation???
	fd.readASCIIZ( &pom );
	if( pom.compare(WherigoOpen->player) != 0 ){
		fd.close();
		cerr << "Savegame is made for other player then cartridge. Got " << pom
			<< ", expected " << WherigoOpen->player << endl;
		return false;
	}
	fd.readASCIIZ( &pom );
	if( pom.compare(WherigoOpen->recomandedDevice) != 0 ){
		fd.close();
		cerr << "Savegame does have different recomandedDevice" << endl;
		return false;
	}
	fd.readASCIIZ( &pom );
	// device doesn't matter
	fd.readLong();
	fd.readLong(); // date of save
	string message;
	fd.readASCIIZ( &message );
	fd.readDouble(); // lon
	fd.readDouble(); // lat
	fd.readDouble(); // alt
	
	int num_objects = fd.readLong();
	string objects[num_objects];
	
	int len;
	objects[0] = "ZCartridge";
	for(int i = 1; i < (num_objects-1); i++){
		len = fd.readLong();
		fd.readASCII(&objects[i], len);
	}
	
	len = fd.readLong();
	fd.readASCII(&pom, len);
	if( pom.compare("ZCharacter") != 0 ){
		fd.close();
		cerr << "Unexpected object at input. Expected ZCharacter, got " << pom << endl;
		return false;
	}
	
	// read Player data
	lua_getfield(L, LUA_GLOBALSINDEX, "Wherigo");	// [-0, +1, e]
	lua_getfield(L, -1, "Player");					// [-0, +1, e]
	lua_remove(L, -2);								// [-1, +0, -]
	if( ! read_table(&fd, -1) ){
		fd.close();
		return false;
	}
	
	lua_getfield(L, LUA_GLOBALSINDEX, "cartridge");						// [-0, +1, e]
	lua_getfield(L, -1, "AllZObjects");									// [-0, +1, e]
	lua_remove(L, -2);													// [-1, +0, -]
	
	const char *name;
	lua_pushnil(L);
	for(int i = 0; i < num_objects-1; i++){
		if( lua_next(L, -2) != 0) {										// [-1, +(2|0), e]
			lua_pop(L, 3);
			return false;
		}
		lua_getfield(L, -1, "_classname");								// [-0, +1, e]
		name = lua_tostring(L, -1);
		
		len = fd.readLong();
		fd.readASCII(&pom, len);
		if( pom.compare(name) != 0 ){
			lua_pop(L, 3);
			fd.close();
			cerr << "Unexpected object at input. Expected " << name << ", got " << pom << endl;
			return false;
		}
		lua_pop(L, 1);
		read_table(&fd, -1);
		lua_pop(L, 1);
	}
	return true;
}

}
}

