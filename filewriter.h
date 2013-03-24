/* ========================================================================== */
/*                                                                            */
/*   FileWriter.h                                                             */
/*   (c) 2013 Jakuje                                                          */
/*                                                                            */
/*   Description                                                              */
/*                                                                            */
/* ========================================================================== */
#include <string>
#include <iostream>
#include <fstream>
#include <sstream>

using namespace std;

class fileWriter: public ofstream {
	short spom;
	unsigned short uspom;

	public:
		ostream& writeByte(char pom){
			return this->write( &pom, 1 );
		}

		ostream& writeShort(short pom){
			return this->write( (char*)&pom, 2 );
		}

		ostream& writeUShort(unsigned short pom){
			return this->write( (char*)&pom, 2 );
		}

		ostream& writeLong(long pom){
			return this->write( (char*)&pom, 4 );
		}

		ostream& writeDouble( double pom){
			return this->write( (char*)&pom, 8);
		}
		/** Write N characters from pom to stream */
		ostream& writeASCII( const char* pom, size_t n){
			return this->write( pom, n );
		}
		/** Same as witeASCII, but appends 0 as end */
		ostream& writeASCIIZ( const char* pom, size_t n){
			this->writeASCII(pom, n);
			return this->write( "\0", 1); // zero-terminated
		}
		

};

