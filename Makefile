CC := $(CROSS_COMPILE)gcc
CXX := $(CROSS_COMPILE)g++

ifdef RELEASE
RELEASE_FLAGS := -O3 -DNDEBUG
else
RELEASE_FLAGS := -ggdb -O0
endif

COMMON_FLAGS := -Wextra -Wno-cpp -D_GNU_SOURCE -Iinc/ $(RELEASE_FLAGS)
CFLAGS := -std=gnu99 $(COMMON_FLAGS) -fexceptions
CXXFLAGS := -std=gnu++11 $(COMMON_FLAGS)
LDFLAGS := -lrt

PREFIX ?= /usr/local

ifdef RELEASE
LIBDIR = $(DESTDIR)$(PREFIX)/lib
BINDIR = $(DESTDIR)$(PREFIX)/bin
else
LIBDIR = $(DESTDIR)$(PREFIX)/lib/debug
BINDIR = $(DESTDIR)$(PREFIX)/bin/debug
endif

all: bin/canopen-master

bin/canopen-master: src/master.o src/sdo_common.o src/sdo_req.o \
		    src/byteorder.o src/network.o src/canopen.o \
		    src/sdo_async.o src/socketcan.o src/legacy-driver.o \
		    src/DriverManager.o src/Driver.o src/rest.o src/http.o \
		    src/eds.o src/ini_parser.o src/types.o src/sdo-rest.o \
		    src/conversions.o src/strlcpy.o
	@mkdir -p $(@D)
	$(CXX) $^ $(LDFLAGS) -pthread -lappbase -lmloop -ldl -o $@

bin/canopen-dump: src/canopen-dump.o src/sdo_common.o src/byteorder.o \
		  src/network.o src/canopen.o src/socketcan.o
	@mkdir -p $(@D)
	$(CC) $^ $(LDFLAGS) -o $@

bin/canbridge: src/canopen.o src/socketcan.o src/network.o src/canbridge.o
	@mkdir -p $(@D)
	$(CC) $^ $(LDFLAGS) -o $@

bin/fakenode: src/fakenode.o src/canopen.o src/socketcan.o \
	      src/sdo_common.o src/sdo_srv.o src/byteorder.o src/network.o
	@mkdir -p $(@D)
	$(CC) $^ $(LDFLAGS) -llua5.1 -o $@

.PHONY: .c.o
.c.o:
	$(CC) -c $(CFLAGS) $< -o $@

.PHONY: .cpp.o
.cpp.o:
	$(CXX) -c $(CXXFLAGS) $< -o $@

.PHONY: clean
clean:
	rm -rf bin
	rm -f src/*.o tst/*.o
	rm -f tst/test_* tst/fuzz_test_*

.PHONY: distclean
distclean: clean
	rm -rf build-*
	rm -f *.deb

tst/test_sdo_srv: src/sdo_common.o src/sdo_srv.o src/byteorder.o tst/sdo_srv.o
	$(CC) $^ $(LDFLAGS) -o $@

tst/test_network: src/canopen.o src/byteorder.o src/network.o tst/network_test.o
	$(CC) $^ -o $@

tst/test_vector: tst/vector_test.o
	$(CC) $^ -o $@

tst/test_sdo_async: tst/sdo_async_test.o src/sdo_srv.o src/byteorder.o \
		    src/sdo_common.o src/sdo_async.o src/network.o \
		    src/canopen.o
	$(CC) $^ -o $@

tst/fuzz_test_sdo_async: tst/sdo_async_fuzz_test.o src/sdo_srv.o \
			 src/byteorder.o src/sdo_common.o src/sdo_async.o \
			 src/canopen.o
	$(CC) $^ -o $@

tst/test_sdo_req: tst/sdo_req_test.o src/sdo_req.o
	$(CC) $^ -o $@

tst/test_http: tst/http_test.o src/http.o
	$(CC) $^ -o $@

tst/test_ini_parser: tst/ini_parser_test.o src/ini_parser.o
	$(CC) $^ -o $@

tst/test_conversions: tst/conversions_test.o src/conversions.o src/types.o \
		      src/byteorder.o src/strlcpy.o
	$(CC) $^ -o $@

tst/test_string-utils: tst/string-utils_test.o
	$(CC) $^ -o $@

.PHONY:
test: tst/test_sdo_srv tst/test_network tst/test_vector tst/test_sdo_async \
      tst/fuzz_test_sdo_async tst/test_sdo_req tst/test_http \
      tst/test_ini_parser
	run-parts tst

install: all
	mkdir -p $(BINDIR)
	install bin/canopen-master $(BINDIR)

# vi: noet sw=8 ts=8 tw=80

