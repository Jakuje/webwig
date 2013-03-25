#ifndef _WHERIGOLIB_SAVE_HPP_
#define _WHERIGOLIB_SAVE_HPP_
#include "filewriter.h"
#include "filereader.h"
#include "lua_common.h"

namespace WherigoLib {
	namespace Save {

		extern bool sync();

		extern bool restore();
	}
}

#endif

