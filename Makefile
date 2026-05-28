# define anything system specific here
#
# set these variables if needed
# PROGSUFFIX: suffix added to binaries
# BUILDTPREFIX: prefix added to build utilities (cc, etc.) for xcompile
# can also set them when invoking "make"
#PROGSUFFIX := .exe
#BUILDTPREFIX=i586-mingw32msvc-

ifeq ($(PREFIX),)
ifneq ($(DESTDIR),)
PREFIX = /usr
else
PREFIX = /usr/local
endif
endif

LIBDIR = $(PREFIX)/lib
BINDIR = $(PREFIX)/bin

INSTALLDIR = $(DESTDIR)$(PREFIX)
INSTALLBIN = $(DESTDIR)$(BINDIR)
INSTALLLIB = $(DESTDIR)$(LIBDIR)

LWCC_LIBDIR = $(LIBDIR)/lwcc/$(PACKAGE_VERSION)
LWCC_INSTALLLIBDIR = $(DESTDIR)$(LWCC_LIBDIR)

# this are probably pointless but they will make sure
# the variables are set without overriding the environment
# or automatic values from make itself.
CC ?= cc
AR ?= ar
RANLIB ?= ranlib

# Set variables for cross compiling
ifneq ($(BUILDTPREFIX),)
CC := $(BUILDTPREFIX)$(CC)
AR := $(BUILDTPREFIX)$(AR)
RANLIB := $(BUILDTPREFIX)$(RANLIB)
endif

CPPFLAGS += -I lwlib -Icommon
CPPFLAGS += -DPREFIX=$(PREFIX) -DLWCC_LIBDIR=$(LWCC_LIBDIR)
CPPFLAGS += -DPROGSUFFIX=$(PROGSUFFIX)
LDFLAGS += -Llwlib -llw

# The format truncation warnings are bleeping stupid when applied to
# snprintf() and friends. I'm using snprintf() precisely to prevent
# overflows and I don't care if the string is truncated, so why should
# I need to test the return value? Bleeping stupid.

# -O3 breaks the build on some compiler/system targets so default to
# -O2 which seems okay for now. Ideally identifying what breaks at
# -O3 is indicated, but so far, identifying the specific source of
# the breakage has been problematic.
CFLAGS ?= -O2 -Wno-char-subscripts -Wno-format-truncation

MAIN_TARGETS := lwasm/lwasm$(PROGSUFFIX) \
	lwlink/lwlink$(PROGSUFFIX) \
	lwar/lwar$(PROGSUFFIX) \
	lwlink/lwobjdump$(PROGSUFFIX) \
	lwcc/lwcc-cpp$(PROGSUFFIX)

SECONDARY_TARGETS := lwcc/lwcc$(PROGSUFFIX) \
	lwcc/lwcc-cc$(PROGSUFFIX)

LWCC_LIBBIN_FILES = lwcc/lwcc-cpp$(PROGSUFFIX) lwcc/lwcc-cc$(PROGSUFFIX)
LWCC_LIBLIB_FILES =
LWCC_LIBINC_FILES =

ifneq ($(NO_COLOR),)
COLOR_RESET :=
COLOR_BOLD :=
COLOR_DIM :=
COLOR_TITLE :=
COLOR_SECTION :=
COLOR_TARGET :=
COLOR_VAR :=
else
COLOR_RESET := \033[0m
COLOR_BOLD := \033[1m
COLOR_DIM := \033[2m
COLOR_TITLE := \033[1;36m
COLOR_SECTION := \033[1;34m
COLOR_TARGET := \033[1;32m
COLOR_VAR := \033[1;33m
endif

.PHONY: default usage help
default: usage

usage: help

help:
	@printf "\n$(COLOR_TITLE)LWTOOLS Makefile$(COLOR_RESET)\n"
	@printf "$(COLOR_DIM)Usage:$(COLOR_RESET) make $(COLOR_TARGET)<target>$(COLOR_RESET) [$(COLOR_VAR)VARIABLE=value$(COLOR_RESET)]\n\n"
	@printf "$(COLOR_SECTION)Build targets$(COLOR_RESET)\n"
	@printf "  $(COLOR_TARGET)%-12s$(COLOR_RESET) %s\n" "all" "Build every program"
	@printf "  $(COLOR_TARGET)%-12s$(COLOR_RESET) %s\n" "lwasm" "Build the assembler"
	@printf "  $(COLOR_TARGET)%-12s$(COLOR_RESET) %s\n" "lwlink" "Build the linker"
	@printf "  $(COLOR_TARGET)%-12s$(COLOR_RESET) %s\n" "lwobjdump" "Build the object dumper"
	@printf "  $(COLOR_TARGET)%-12s$(COLOR_RESET) %s\n" "lwar" "Build the archive tool"
	@printf "  $(COLOR_TARGET)%-12s$(COLOR_RESET) %s\n" "lwcc" "Build the lwcc driver"
	@printf "  $(COLOR_TARGET)%-12s$(COLOR_RESET) %s\n" "lwcc-cpp" "Build the lwcc preprocessor"
	@printf "  $(COLOR_TARGET)%-12s$(COLOR_RESET) %s\n\n" "lwcc-cpplib" "Build the lwcc preprocessor library"
	@printf "$(COLOR_SECTION)Install targets$(COLOR_RESET)\n"
	@printf "  $(COLOR_TARGET)%-12s$(COLOR_RESET) %s\n" "install" "Install main programs to $(INSTALLBIN)"
	@printf "  $(COLOR_TARGET)%-12s$(COLOR_RESET) %s\n\n" "install-all" "Install every program and lwcc support files"
	@printf "$(COLOR_SECTION)Clean and check targets$(COLOR_RESET)\n"
	@printf "  $(COLOR_TARGET)%-12s$(COLOR_RESET) %s\n" "clean" "Remove built objects and programs"
	@printf "  $(COLOR_TARGET)%-12s$(COLOR_RESET) %s\n" "realclean" "Also remove generated dependency files"
	@printf "  $(COLOR_TARGET)%-12s$(COLOR_RESET) %s\n\n" "test" "Build everything and run the test suite"
	@printf "$(COLOR_SECTION)Utility targets$(COLOR_RESET)\n"
	@printf "  $(COLOR_TARGET)%-12s$(COLOR_RESET) %s\n" "help" "Show this usage screen"
	@printf "  $(COLOR_TARGET)%-12s$(COLOR_RESET) %s\n" "usage" "Alias for help"
	@printf "  $(COLOR_TARGET)%-12s$(COLOR_RESET) %s\n\n" "print-VAR" "Print a Make variable, for example make print-PREFIX"
	@printf "$(COLOR_SECTION)Useful variables$(COLOR_RESET)\n"
	@printf "  $(COLOR_VAR)%-12s$(COLOR_RESET) %s\n" "PREFIX" "Installation prefix (current: $(PREFIX))"
	@printf "  $(COLOR_VAR)%-12s$(COLOR_RESET) %s\n" "DESTDIR" "Staging root for packaging (current: $(DESTDIR))"
	@printf "  $(COLOR_VAR)%-12s$(COLOR_RESET) %s\n" "PROGSUFFIX" "Program suffix, for example .exe (current: $(PROGSUFFIX))"
	@printf "  $(COLOR_VAR)%-12s$(COLOR_RESET) %s\n" "BUILDTPREFIX" "Cross-toolchain prefix, for example i686-w64-mingw32- (current: $(BUILDTPREFIX))"
	@printf "  $(COLOR_VAR)%-12s$(COLOR_RESET) %s\n\n" "NO_COLOR" "Set to 1 to disable colors"
	@printf "$(COLOR_BOLD)Examples$(COLOR_RESET)\n"
	@printf "  make all\n"
	@printf "  make install PREFIX=/usr DESTDIR=/tmp/pkg\n"
	@printf "  make install PREFIX=${HOME}/.local\n"
	@printf "  make NO_COLOR=1\n\n"

.PHONY: all
all: $(MAIN_TARGETS) $(SECONDARY_TARGETS)

lwar_srcs := add.c extract.c list.c lwar.c main.c remove.c replace.c
lwar_srcs := $(addprefix lwar/,$(lwar_srcs))

lwlib_srcs := lw_alloc.c lw_realloc.c lw_free.c lw_error.c lw_expr.c \
	lw_stack.c lw_string.c lw_stringlist.c lw_cmdline.c lw_strbuf.c \
	lw_strpool.c lw_dict.c
lwlib_srcs := $(addprefix lwlib/,$(lwlib_srcs))

lwlink_srcs := main.c lwlink.c readfiles.c expr.c script.c link.c output.c map.c
lwobjdump_srcs := objdump.c
lwlink_srcs := $(addprefix lwlink/,$(lwlink_srcs))
lwobjdump_srcs := $(addprefix lwlink/,$(lwobjdump_srcs))

lwasm_srcs := cycle.c debug.c input.c insn_bitbit.c insn_gen.c insn_indexed.c \
	insn_inh.c insn_logicmem.c insn_rel.c insn_rlist.c insn_rtor.c insn_tfm.c \
	instab.c list.c lwasm.c macro.c main.c os9.c output.c pass1.c pass2.c \
	pass3.c pass4.c pass5.c pass6.c pass7.c pragma.c pseudo.c section.c \
	strings.c struct.c symbol.c symdump.c unicorns.c
lwasm_srcs := $(addprefix lwasm/,$(lwasm_srcs))

lwasm_objs := $(lwasm_srcs:.c=.o)
lwlink_objs := $(lwlink_srcs:.c=.o)
lwar_objs := $(lwar_srcs:.c=.o)
lwlib_objs := $(lwlib_srcs:.c=.o)
lwobjdump_objs := $(lwobjdump_srcs:.c=.o)

lwasm_deps := $(lwasm_srcs:.c=.d)
lwlink_deps := $(lwlink_srcs:.c=.d)
lwar_deps := $(lwar_srcs:.c=.d)
lwlib_deps := $(lwlib_srcs:.c=.d)
lwobjdump_deps := $(lwobjdump_srcs:.c=.d)

lwcc_driver_srcs := driver-main.c
lwcc_driver_srcs := $(addprefix lwcc/,$(lwcc_driver_srcs))
lwcc_driver_objs := $(lwcc_driver_srcs:.c=.o)
lwcc_driver_deps := $(lwcc_driver_srcs:.c=.d)

lwcc_cpp_srcs := cpp-main.c
lwcc_cpp_srcs := $(addprefix lwcc/,$(lwcc_cpp_srcs))
lwcc_cpp_objs := $(lwcc_cpp_srcs:.c=.o)
lwcc_cpp_deps := $(lwcc_cpp_srcs:.c=.d)

lwcc_cc_srcs := cc-main.c tree.c cc-parse.c cc-gencode.c
lwcc_cc_srcs := $(addprefix lwcc/,$(lwcc_cc_srcs))
lwcc_cc_objs := $(lwcc_cc_srcs:.c=.o)
lwcc_cc_deps := $(lwcc_cc_srcs:.c=.d)

lwcc_cpplib_srcs := cpp.c lex.c token.c preproc.c symbol.c
lwcc_cpplib_srcs := $(addprefix lwcc/,$(lwcc_cpplib_srcs))
lwcc_cpplib_objs := $(lwcc_cpplib_srcs:.c=.o)
lwcc_cpplib_deps := $(lwcc_cpplib_srcs:.c=.d)

lwcc_deps := $(lwcc_cpp_deps) $(lwcc_driver_deps) $(lwcc_cpplib_deps) $(lwcc_cc_deps)

.PHONY: lwlink lwasm lwar lwobjdump lwcc
lwlink: lwlink/lwlink$(PROGSUFFIX)
lwasm: lwasm/lwasm$(PROGSUFFIX)
lwar: lwar/lwar$(PROGSUFFIX)
lwobjdump: lwlink/lwobjdump$(PROGSUFFIX)
lwcc: lwcc/lwcc$(PROGSUFFIX)
lwcc-cpp: lwcc/lwcc-cpp$(PROGSUFFIX)
lwcc-cpplib: lwcc/libcpp.a

lwasm/lwasm$(PROGSUFFIX): $(lwasm_objs) lwlib
	@echo Linking $@
	@$(CC) -o $@ $(lwasm_objs) $(LDFLAGS)

lwlink/lwlink$(PROGSUFFIX): $(lwlink_objs) lwlib
	@echo Linking $@
	@$(CC) -o $@ $(lwlink_objs) $(LDFLAGS)

lwlink/lwobjdump$(PROGSUFFIX): $(lwobjdump_objs) lwlib
	@echo Linking $@
	@$(CC) -o $@ $(lwobjdump_objs) $(LDFLAGS)

lwar/lwar$(PROGSUFFIX): $(lwar_objs) lwlib
	@echo Linking $@
	@$(CC) -o $@ $(lwar_objs) $(LDFLAGS)

lwcc/lwcc$(PROGSUFFIX): $(lwcc_driver_objs) lwlib
	@echo Linking $@
	@$(CC) -o $@ $(lwcc_driver_objs) $(LDFLAGS)

lwcc/lwcc-cpp$(PROGSUFFIX): $(lwcc_cpp_objs) lwlib lwcc-cpplib
	@echo Linking $@
	@$(CC) -o $@ $(lwcc_cpp_objs) lwcc/libcpp.a $(LDFLAGS)

lwcc/lwcc-cc$(PROGSUFFIX): $(lwcc_cc_objs) lwlib lwcc-cpplib
	@echo Linking $@
	@$(CC) -o $@ $(lwcc_cc_objs) lwcc/libcpp.a $(LDFLAGS)

.INTERMEDIATE: lwcc-cpplib
lwcc-cpplib: lwcc/libcpp.a
lwcc/libcpp.a: $(lwcc_cpplib_objs)
	@echo Linking $@
	@$(AR) rc $@ $(lwcc_cpplib_objs)
	@$(RANLIB) $@

#.PHONY: lwlib
.INTERMEDIATE: lwlib
lwlib: lwlib/liblw.a

lwlib/liblw.a: $(lwlib_objs)
	@echo Linking $@
	@$(AR) rc $@ $(lwlib_objs)
	@$(RANLIB) $@

alldeps := $(lwasm_deps) $(lwlink_deps) $(lwar_deps) $(lwlib_deps) ($lwobjdump_deps) $(lwcc_deps)

-include $(alldeps)

extra_clean := $(extra_clean) *~ */*~

%.o: %.c
	@echo "Building dependencies for $@"
	@$(CC) -MM $(CPPFLAGS) -o $*.d $<
	@mv -f $*.d $*.d.tmp
	@sed -e 's|.*:|$*.o $*.d:|' < $*.d.tmp > $*.d
	@sed -e 's/.*://' -e 's/\\$$//' < $*.d.tmp | fmt -1 | sed -e 's/^ *//' -e 's/$$/:/' >> $*.d
	@rm -f $*.d.tmp
	@echo Building $@
	@$(CC) $(CPPFLAGS) $(CFLAGS) -o $@ -c $<
	

.PHONY: clean
clean: $(cleantargs)
	@echo "Cleaning up"
	@rm -f lwlib/liblw.a lwasm/lwasm$(PROGSUFFIX) lwlink/lwlink$(PROGSUFFIX) lwlink/lwobjdump$(PROGSUFFIX) lwar/lwar$(PROGSUFFIX)
	@rm -f lwcc/lwcc$(PROGSUFFIX) lwcc/lwcc-cpp$(PROGSUFFIX) lwcc/lwcc-cc$(PROGSUFFIX) lwcc/libcpp.a
	@rm -f $(lwcc_driver_objs) $(lwcc_cpp_objs) $(lwcc_cpplib_objs) $(lwcc_cc_objs)
	@rm -f $(lwasm_objs) $(lwlink_objs) $(lwar_objs) $(lwlib_objs) $(lwobjdump_objs)
	@rm -f $(extra_clean)
	@rm -f */*.exe

.PHONY: realclean
realclean: clean $(realcleantargs)
	@echo "Cleaning up even more"
	@rm -f $(lwasm_deps) $(lwlink_deps) $(lwar_deps) $(lwlib_deps) $(lwobjdump_deps)
	@rm -f $(lwcc_driver_deps) $(lwcc_cpp_deps) $(lwcc_cpplib_deps) $(lwcc_cc_deps)

print-%:
	@echo $* = $($*)

.PHONY: install
install: $(MAIN_TARGETS)
	install -d $(INSTALLDIR)
	install -d $(INSTALLBIN)
	install $(MAIN_TARGETS) $(INSTALLBIN)

.PHONY: install-all
install-all: install
	install $(SECONDARY_TARGETS) $(INSTALLBIN)
	install -d $(LWCC_INSTALLLIBDIR)
	install -d $(LWCC_INSTALLLIBDIR)/bin
	install -d $(LWCC_INSTALLLIBDIR)/lib
	install -d $(LWCC_INSTALLLIBDIR)/include
ifneq ($(LWCC_LIBBIN_FILES),)
	install $(LWCC_LIBBIN_FILES) $(LWCC_INSTALLLIBDIR)/bin
endif
ifneq ($(LWCC_LIBLIB_FILES),)
	install $(LWCC_LIBLIB_FILES) $(LWCC_INSTALLLIBDIR)/lib
endif
ifneq ($(LWCC_LIBINC_FILES),)
	install $(LWCC_LIBINC_FILES) $(LWCC_INSTALLLIBDIR)/include
endif

.PHONY: test
test: all test/runtests
	@test/runtests
