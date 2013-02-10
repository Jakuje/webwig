/* ========================================================================== */
/*                                                                            */
/*   FileReader.h                                                             */
/*   (c) 2012 Jakuje                                                          */
/*                                                                            */
/*   Description                                                              */
/*                                                                            */
/* ========================================================================== */
#include <string>
#include <iostream>
#include <fstream>
#include <sstream>

using namespace std;

class fileReader: public ifstream {
	short spom;
	unsigned short uspom;

	public:
		int readByte(){
			char pom;
			this->read( &pom, 1 );
			return (int) pom;
		}

		int readShort(){
			this->read( (char*)&spom, 2 );
			return (int) spom;
		}

		int readUShort(){
			this->read( (char*)&uspom, 2 );
			return (int) uspom;
		}

		long readLong(){
			long pom;
			this->read( (char*)&pom, 4 );
			return pom;
		}

		double readDouble(){
			double pom;
			this->read((char*)&pom, 8);
			return pom;
		}

		string readASCIIZ(){
			string pom;
			std::getline( *this, pom, '\0' );
			return pom;
		}

};

