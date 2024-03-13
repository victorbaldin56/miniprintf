# Compiler
CXX = g++

# Flags
CXXFLAGS = -std=c++17 -Wall -Wextra -Weffc++ \
	-Waggressive-loop-optimizations \
	-Wc++14-compat -Wmissing-declarations -Wcast-align -Wcast-qual \
	-Wchar-subscripts \
	-Wconditionally-supported -Wconversion -Wctor-dtor-privacy -Wempty-body \
	-Wfloat-equal \
	-Wformat-nonliteral -Wformat-security -Wformat-signedness -Wformat=2 \
	-Winline -Wlogical-op \
	-Wnon-virtual-dtor -Wopenmp-simd -Woverloaded-virtual -Wpacked \
	-Winit-self \
	-Wredundant-decls \
	-Wshadow -Wsign-conversion -Wsign-promo -Wstrict-null-sentinel \
	-Wstrict-overflow=2 \
	-Wsuggest-attribute=noreturn -Wsuggest-final-methods \
	-Wsuggest-final-types \
	-Wsuggest-override \
	-Wswitch-default -Wswitch-enum -Wsync-nand -Wundef -Wunreachable-code \
	-Wunused -Wuseless-cast \
	-Wvariadic-macros -Wno-literal-suffix -Wno-missing-field-initializers \
	-Wno-narrowing \
	-Wno-old-style-cast -Wno-varargs -Wstack-protector -fcheck-new \
	-fsized-deallocation

ifdef DEBUG
CXXFLAGS += -O0 -D _DEBUG -ggdb3 -fstack-protector -fstrict-overflow -flto-odr-type-merging \
	-fno-omit-frame-pointer \
	-Wlarger-than=8192 -Wstack-usage=8192 -pie -fPIE -Werror=vla \
	-fsanitize=address,alignment,bool,bounds,enum,float-cast-overflow,$\
	float-divide-by-zero,$\
	integer-divide-by-zero,leak,nonnull-attribute,null,object-size,return,$\
	returns-nonnull-attribute,$\
	shift,signed-integer-overflow,undefined,unreachable,vla-bound,vptr
else
CXXFLAGS += -O3 -D NDEBUG
endif

all: main.cpp.o miniprintf.o
	@g++ main.cpp.o miniprintf.o -z noexecstack -no-pie

debug:
	@edb --run a.out

main.cpp.o:
	@$(CXX) $(CXXFLAGS) -c main.cpp -o main.cpp.o

miniprintf.o:
	@nasm -f elf64 miniprintf.s

.PHONY: clean

clean:
	@rm -rf $(BUILD_DIR)
