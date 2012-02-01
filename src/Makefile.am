# Note: plugindir is set in configure

##############################################################################
# TODO: change libgstplugin.la to something else, e.g. libmysomething.la     #
##############################################################################
plugin_LTLIBRARIES = libgstopencl.la

##############################################################################
# TODO: for the next set of variables, name the prefix if you named the .la, #
#  e.g. libmysomething.la => libmysomething_la_SOURCES                       #
#                            libmysomething_la_CFLAGS                        #
#                            libmysomething_la_LIBADD                        #
#                            libmysomething_la_LDFLAGS                       #
##############################################################################

# sources used to compile this plug-in


VALAFLAGS = --verbose --debug --vapidir=. --vapidir=../vapi \
--pkg posix --pkg gio-2.0 \
--pkg gstreamer-0.10 --pkg gstreamer-video-0.10 \
--pkg OpenCL

gstopencl.c: gopencl/gopencl.c gstopencl.vala clkernel.vala clvideofilter.vala
	$(VALAC) $(VALAFLAGS) --pkg libgopencl \
	--ccode --library=libgstcl -H gstcl.h -o gstopencl.c \
	gstopencl.vala clkernel.vala clvideofilter.vala

gopencl/gopencl.c: gopencl/gopencl.vala
	$(VALAC) $(VALAFLAGS) \
	--ccode --library=libgopencl -H gopencl.h -o gopencl.c \
	gopencl/gopencl.vala

libgstopencl_la_SOURCES = gopencl/gopencl.c gstopencl.c clkernel.c clvideofilter.c

# compiler and linker flags used to compile this plugin, set in configure.ac
libgstopencl_la_CFLAGS = $(GST_CFLAGS)
libgstopencl_la_LIBADD = $(GST_LIBS)
libgstopencl_la_LDFLAGS = $(GST_PLUGIN_LDFLAGS)
libgstopencl_la_LIBTOOLFLAGS = --tag=disable-static

# headers we need but don't want installed
#noinst_HEADERS = gstplugin.h

CLEANFILES = *.c *.h *.vapi gopencl\*.c
