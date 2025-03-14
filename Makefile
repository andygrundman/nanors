OBJ=rs.o
OBJ_MOON=moonlight/rs.o

TEST_UTILS=\
t/00util/test\
t/00util/bench\
t/00util/bench_moon

#CPPFLAGS=-DOBLAS_NEON
#CPPFLAGS=-DOBLAS_AVX512
CPPFLAGS=-DOBLAS_AVX2
#CPPFLAGS=-DOBLAS_SSE3
CFLAGS   = -O3 -g -std=c11 -Wall -I. -Ideps/obl
CFLAGS  += -march=native -funroll-loops -ftree-vectorize

moonlight/rs.o: CPPFLAGS+=-D_MOONLIGHT

all: rs.o moonlight/rs.o

t/00util/test.o: CPPFLAGS+=-D_DEFAULT_SOURCE

t/00util/bench.o: CPPFLAGS+=-D_DEFAULT_SOURCE

t/00util/bench_moon.o: CPPFLAGS+=-D_DEFAULT_SOURCE -D_MOONLIGHT

t/00util/test: t/00util/test.o $(OBJ)

t/00util/bench: t/00util/bench.o $(OBJ)

t/00util/bench_moon: t/00util/bench_moon.o $(OBJ_MOON)

check: clean $(TEST_UTILS)
	prove -I. -v t/*.t

clean:
	$(RM) *.o *.a t/00util/*.o moonlight/*.o $(TEST_UTILS) $(OBJ)

indent:
	find -name '*.[h,c]' | xargs clang-format -i

scan:
	scan-build --status-bugs $(MAKE) clean $(OBJ) $(TEST_UTILS)

valgrind: CFLAGS = -O0 -g -std=c11 -Wall -I. -Ideps/obl
valgrind: clean $(TEST_UTILS)
	valgrind --error-exitcode=2 ./t/00util/bench 200 20 512

gperf: LDLIBS = -lprofiler -ltcmalloc
gperf: clean t/00util/bench
	CPUPROFILE_FREQUENCY=100000000 CPUPROFILE=gperf.prof ./t/00util/bench 200 20 512
	pprof ./t/00util/bench gperf.prof --callgrind > callgrind.gperf
	gprof2dot --format=callgrind callgrind.gperf -z main | dot -T svg > gperf.svg

ubsan: CC=clang
ubsan: CFLAGS += -fsanitize=undefined,implicit-conversion
ubsan: LDLIBS += -lubsan
ubsan: clean t/00util/test
	./t/00util/test
