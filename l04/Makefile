CFLAGS = -Wall -Werror -g
CXXFLAGS = -Wall -Werror -std=c++17 -g -I../test
LINK.o = $(CXX) $(LDFLAGS) $(TARGET_ARCH) # we're (maybe) linking c++ objects

TESTS := TestCBuffer TestBuffer
RUN_TEST_DEFAULT := run-TestBuffer
RUN_TESTS := $(foreach t,$(TESTS),run-$t)

.PHONY: default all test
default: test
all: $(RUN_TESTS)
test: $(RUN_TEST_DEFAULT)

memcheck: TestBuffer
	valgrind --leak-check=yes ./testBuffer

TestCBuffer.o cbuffer.o: cbuffer.h Makefile
TestCBuffer: test.o TestCBuffer.o cbuffer.o

TestBuffer.o Buffer.o: Buffer.h Makefile
TestBuffer: test.o TestBuffer.o Buffer.o

run-%: %
	@echo
	@echo "Running $<"
	./$<

.PHONY: clean distclean test
clean:
	rm -f *.o
distclean: clean
	rm -f $(TESTS)
