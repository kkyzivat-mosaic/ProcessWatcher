CC := $(shell xcrun -find clang)
RM := rm -rf
MKDIR := mkdir -p

sdk := $(shell sw_vers -productVersion | sed 's/\(10.[0-9]\).*/\1/')
sysroot := $(shell xcode-select -print-path)/Platforms/MacOSX.platform/Developer/SDKs/MacOSX$(sdk).sdk

srcdir := src/main/native
builddir := target/daemon/lib

jvminc := $(sysroot)/System/Library/Frameworks/JavaVM.framework/Headers
incs := -I$(jvminc) -I$(srcdir)

cflags := -g -ggdb -O0 -Wall -std=c99 -dynamiclib -isysroot $(sysroot) -mmacosx-version-min=10.6 $(incs)
mflags := $(cflags) -x objective-c -fobjc-arc
ldflags := -framework AppKit -framework Foundation -framework CoreServices -framework SystemConfiguration

volumewatcher := $(builddir)/libvolumewatcher.dylib
volumewatcher_sources := $(srcdir)/com_mosaic_daemon_VolumeWatcher.m

networkmonitor := $(builddir)/libnetworkmonitor.dylib
networkmonitor_sources := $(srcdir)/com_mosaic_daemon_NetworkMonitor.m

lrprocessmonitor := $(builddir)/liblightroomprocessmonitor.dylib
lrprocessmonitor_sources := $(srcdir)/com_mosaic_daemon_LightroomProcessMonitor.m

shared_libs := $(volumewatcher) $(networkmonitor) $(lrprocessmonitor)
debug_symbols := $(volumewatcher).dSYM $(networkmonitor).dSYM $(lrprocessmonitor).dSYM

.PHONY: all clean

all: $(shared_libs)

$(volumewatcher): $(volumewatcher_sources)
	$(MKDIR) $(builddir)
	$(CC) $(mflags) $(ldflags) -o $@ $<

$(networkmonitor): $(networkmonitor_sources)
	$(MKDIR) $(builddir)
	$(CC) $(mflags) $(ldflags) -o $@ $<

$(lrprocessmonitor): $(lrprocessmonitor_sources)
	$(MKDIR) $(builddir)
	$(CC) $(mflags) $(ldflags) -o $@ $<

clean:
	$(RM) $(shared_libs) $(debug_symbols)
