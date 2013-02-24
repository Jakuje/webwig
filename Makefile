DESKTOP=1
PRE=0
PIXI=1
DEBUG=1

ifeq (1,$(DEBUG))
DEVICEOPTS=-g
else
DEVICEOPTS=
endif

PDL=-lpdl -lSDL
LIBS= 
INC="-I%PalmPDK%\include" "-I%PalmPDK%\include\SDL" 
LDFLAGS="-L%PalmPDK%\device\lib" $(PDL) $(LIBS) -Wl,--allow-shlib-undefined
RM = -rd /S /Q
COPY = copy
PACKAGE = package

ifeq (1, $(DESKTOP))
DEVICEOPTS += -DDESKTOP
PDL=
INC=
PACKAGE = 
LDFLAGS=$(LIBS) -Wl,--allow-shlib-undefined
RM = rm -rf
COPY = cp -r 
else ifeq (1,$(PRE))
DEVICEOPTS += -mcpu=cortex-a8 -mfpu=neon -mfloat-abi=softfp
else ifeq (1,$(PIXI))
DEVICEOPTS += -mcpu=arm1136jf-s -mfpu=vfp -mfloat-abi=softfp
$(error Must set either PRE or PIXI variable to 1 to build)
endif

CFLAGS=$(INC) $(DEVICEOPTS) -pedantic -Wall

ifeq (0, DESKTOP)
CPP=arm-none-linux-gnueabi-g++
else
CPP=g++
endif

CPPFLAGS=$(CFLAGS)
              
PLUGIN=wig
LIB="lua/liblua.a"

all: $(PLUGIN) $(PACKAGE)

#.cpp.o::
#	$(CPP) $(CPPFLAGS) -c $<

#.c.o::
#	$(CC) $(CFLAGS) -c $<

liblua.a: lua/lua.c
	make -C lua a
	$(COPY) $(LIB) liblua.a

$(PLUGIN): $(PLUGIN).cpp lua_common.o liblua.a lua_common.h \
 lua/lua.h lua/luaconf.h lua/lauxlib.h lua/lua.h lua/lualib.h \
 wherigo.o filereader.h
	$(CPP) $(CPPFLAGS) $(LDFLAGS) -o $@ $^ $(PDL) $(LIBS)

package: $(PLUGIN) appinfo.json logo.png
	$(RM) STAGING
	mkdir STAGING
	$(COPY) $(PLUGIN) STAGING
#	$(COPY) $(LIB) STAGING
	$(COPY) appinfo.json STAGING
	$(COPY) framework_config.js STAGING
	$(COPY) Wig.js STAGING
	$(COPY) wherigo_plugin_appinfo.json STAGING
	$(COPY) depends.js STAGING
	$(COPY) index.html STAGING
	$(COPY) logo.png STAGING
	mkdir STAGING\images
	$(COPY) images STAGING/images
	mkdir STAGING\enyo
	$(COPY) enyo STAGING\enyo
#sources
	$(COPY) wig.cpp STAGING
	$(COPY) wherigo.cpp STAGING
	$(COPY) wherigo.lua STAGING
	echo filemode.755=$(PLUGIN) > STAGING\package.properties
	palm-package STAGING
	palm-install com.dta3team.app.wherigo_1.0.0_all.ipk
#	palm-run STAGING

clean:
	$(RM) STAGING
	$(RM) $(PLUGIN)
	$(RM) liblua.a
	$(RM) *.o
	$(RM) $(LIB)

depend:
	@$(CC) $(CFLAGS) -MM lua_common.c *.cpp

lua_common.o: lua_common.c lua/lua.hpp lua/lua.h lua/luaconf.h lua/lauxlib.h lua/lualib.h
	$(CPP) $(CPPFLAGS) -c -o $@ $<
	
#main : $(PLUGIN).cpp lua_common.h lua/lua.h lua/lualib.h
#	$(CPP) $(CPPFLAGS) -c -o $@ $^ $(LIBS)

wherigo.o: wherigo.cpp wherigo.h
	$(CPP) $(CPPFLAGS) -c -o $@ $<

