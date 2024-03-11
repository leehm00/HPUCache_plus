#
#  Makefile
#  YCSB-cpp
#
#  Copyright (c) 2020 Youngjae Lee <ls4154.lee@gmail.com>.
#  Copyright (c) 2014 Jinglei Ren <jinglei@ren.systems>.
#


#---------------------build config-------------------------

DEBUG_BUILD ?= 0
EXTRA_CXXFLAGS ?=
EXTRA_LDFLAGS ?=

BIND_REDIS ?= 1

#----------------------------------------------------------

ifeq ($(DEBUG_BUILD), 1)
	CXXFLAGS += -g
else
	CXXFLAGS += -O2
	CPPFLAGS += -DNDEBUG
endif




ifeq ($(BIND_REDIS), 1)
	SOURCES += $(wildcard redis/*.cc)
	# CXXFLAGS += -static
	LDFLAGS += ./redis/hiredis-cluster/lib/libhiredis_static.a
	LDFLAGS += ./redis/hiredis-cluster/lib/libhiredis_cluster.a
endif 

CXXFLAGS += -std=c++11 -Wall -pthread $(EXTRA_CXXFLAGS) -I./
LDFLAGS += $(EXTRA_LDFLAGS) -lpthread
SOURCES += $(wildcard core/*.cc)
OBJECTS += $(SOURCES:.cc=.o)
DEPS += $(SOURCES:.cc=.d)
EXEC = ycsb

all: $(EXEC)

$(EXEC): $(OBJECTS)
	$(CXX) $(CXXFLAGS) $^ $(LDFLAGS) -o $@

sample: ./redis/sample.cpp
	$(CXX) -o $@ $^ ./redis/hiredis-cluster/lib/libhiredis_cluster.a  -Wall -std=c++11 -g -lhiredis


.cc.o:
	$(CXX) $(CXXFLAGS) $(CPPFLAGS) -c -o $@ $<

%.d : %.cc
	$(CXX) $(CXXFLAGS) $(CPPFLAGS) -MM -MT '$(<:.cc=.o)' -o $@ $<

ifneq ($(MAKECMDGOALS),clean)
-include $(DEPS)
endif

clean:
	find . -name "*.[od]" -delete
	$(RM) $(EXEC)
	$(RM) sample

.PHONY: clean
