# Note: plugindir is set in configure

##############################################################################
# TODO: change libgstplugin.la to something else, e.g. libmysomething.la     #
##############################################################################
plugin_LTLIBRARIES = libgstpush.la

##############################################################################
# TODO: for the next set of variables, name the prefix if you named the .la, #
#  e.g. libmysomething.la => libmysomething_la_SOURCES                       #
#                            libmysomething_la_CFLAGS                        #
#                            libmysomething_la_LIBADD                        #
#                            libmysomething_la_LDFLAGS                       #
##############################################################################
VALAFLAGS = --verbose --pkg gstreamer-0.10 --pkg gstreamer-video-0.10
# sources used to compile this plug-in

.PHONY: gstcl.c

gstcl.c:
	$(VALAC) $(VALAFLAGS) --library=libgstcl -H gstcl.h --ccode -o gstcl.c gstcl.vala --vapidir=.

libgstpush_la_SOURCES = gstcl.c #fix.c

# compiler and linker flags used to compile this plugin, set in configure.ac
libgstpush_la_CFLAGS = $(GST_CFLAGS)
libgstpush_la_LIBADD = $(GST_LIBS)
libgstpush_la_LDFLAGS = $(GST_PLUGIN_LDFLAGS)
libgstpush_la_LIBTOOLFLAGS = --tag=disable-static


# headers we need but don't want installed
#noinst_HEADERS = gstplugin.h
