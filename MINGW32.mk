# -*- Mode: makefile -*-
#
#
#  Based on patch submitted to mozilla.dev.tech.js-engine by 'Andy':
#    http://groups.google.com/group/mozilla.dev.tech.js-engine/browse_thread/thread/16972946bf7df82e
#
#
# ***** BEGIN LICENSE BLOCK *****
# Version: MPL 1.1/GPL 2.0/LGPL 2.1
#
# The contents of this file are subject to the Mozilla Public License Version
# 1.1 (the "License"); you may not use this file except in compliance with
# the License. You may obtain a copy of the License at
# http://www.mozilla.org/MPL/
#
# Software distributed under the License is distributed on an "AS IS" basis,
# WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License
# for the specific language governing rights and limitations under the
# License.
#
# The Original Code is Mozilla Communicator client code, released
# March 31, 1998.
#
# The Initial Developer of the Original Code is
# Netscape Communications Corporation.
# Portions created by the Initial Developer are Copyright (C) 1998
# the Initial Developer. All Rights Reserved.
#
# Contributor(s):
#
# Alternatively, the contents of this file may be used under the terms of
# either the GNU General Public License Version 2 or later (the "GPL"), or
# the GNU Lesser General Public License Version 2.1 or later (the "LGPL"),
# in which case the provisions of the GPL or the LGPL are applicable instead
# of those above. If you wish to allow use of your version of this file only
# under the terms of either the GPL or the LGPL, and not to allow others to
# use your version of this file under the terms of the MPL, indicate your
# decision by deleting the provisions above and replace them with the notice
# and other provisions required by the GPL or the LGPL. If you do not delete
# the provisions above, a recipient may use your version of this file under
# the terms of any one of the MPL, the GPL or the LGPL.
#
# ***** END LICENSE BLOCK *****

#
# Config for all versions of Mingw (copy and modified from Linux)
#

AR = i586-mingw32msvc-ar
CC = i586-mingw32msvc-gcc
LD = i586-mingw32msvc-ld
CCC = i586-mingw32msvc-g++

CFLAGS +=  -Wall -Wno-format
#OS_CFLAGS = -DXP_UNIX -DSVR4 -DSYSV -D_BSD_SOURCE -DPOSIX_SOURCE -DHAVE_LOCALTIME_R -DEXPORT_JS_API
OS_CFLAGS = -D_X86_=1 -DXP_WIN -DXP_WIN32 -DWIN32 -D_WINDOWS -D_WIN32 $(WIN_CFLAGS) -DEXPORT_JS_API
JSDLL_CFLAGS = -DEXPORT_JS_API  # not work, dunno why?
SO_SUFFIX = dll
# libgcc.a:__divdi3 kernel32:DebugBreak,GetSystemTimeAsFileTime
# winmm:timeBeginPeriod,timeEndPeriod
WINLIBS = -lmsvcrt -lm -lkernel32 -lwinmm /usr/lib/gcc/i586-mingw32msvc/4.2.1-sjlj/libgcc.a
#LDFLAGS += $(WINLIBS) # dont work. rewrite by Makefile.ref
OTHER_LIBS += $(WINLIBS)

RANLIB = echo
MKSHLIB = $(LD) -shared $(XMKSHLIBOPTS)

# These don't work :(
LIBRARY = $(OBJDIR)/js32.lib
SHARED_LIBRARY = $(OBJDIR)/js32.dll
PROGRAM = $(OBJDIR)/js.exe

#.c.o:
#      $(CC) -c -MD $*.d $(CFLAGS) $<

CPU_ARCH = $(shell uname -m)
# don't filter in x86-64 architecture
ifneq (x86_64,$(CPU_ARCH))
ifeq (86,$(findstring 86,$(CPU_ARCH)))
CPU_ARCH = x86
OS_CFLAGS+= -DX86_LINUX

ifeq (gcc, $(CC))
# if using gcc on x86, check version for opt bug
# (http://bugzilla.mozilla.org/show_bug.cgi?id=24892)
GCC_VERSION := $(shell gcc -v 2>&1 | grep version | awk '{ print $$3 }')
GCC_LIST:=$(sort 2.91.66 $(GCC_VERSION) )

ifeq (2.91.66, $(firstword $(GCC_LIST)))
CFLAGS+= -DGCC_OPT_BUG
endif
endif
endif
endif

GFX_ARCH = x

OS_LIBS = -lm -lc

ASFLAGS += -x assembler-with-cpp


ifeq ($(CPU_ARCH),alpha)

# Ask the C compiler on alpha linux to let us work with denormalized
# double values, which are required by the ECMA spec.

OS_CFLAGS += -mieee
endif

# Use the editline library to provide line-editing support.
#JS_EDITLINE = 1   // not support by Mingw

ifeq ($(CPU_ARCH),x86_64)
# Use VA_COPY() standard macro on x86-64
# FIXME: better use it everywhere
OS_CFLAGS += -DHAVE_VA_COPY
endif

ifeq ($(CPU_ARCH),x86_64)
# We need PIC code for shared libraries
# FIXME: better patch rules.mk & fdlibm/Makefile*
OS_CFLAGS += -DPIC -fPIC
endif 
