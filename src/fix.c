#include <stdio.h>
#include <gst/gst.h>
#include "gstcl.h"


#define PACKAGE "clpus"

static gboolean
plugin_init (GstPlugin * plugin)
{
gst_element_register (plugin, "clpush", GST_RANK_NONE, GST_CL_TYPE_PUSH);

return TRUE;
}


GST_PLUGIN_DEFINE (
  0, 10, 
  "clpush", 
  "push to opencl",
  plugin_init,
  "0.10",
  "LGPL",
  "g",
  "h"
)
