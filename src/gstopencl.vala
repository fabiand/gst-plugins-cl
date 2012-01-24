

/*
 * Plugin boilerplate.
 */
const Gst.PluginDesc gst_plugin_desc = {
  0, 10, 
  "opencl", 
  "OpenCl plugin",
  plugin_init,
  "0.1",
  "LGPL",
  "http://",
  "Package?",
  "Origin?"
};

public static bool plugin_init (Gst.Plugin p)
{
  Gst.Element.register (p, "clkernel", Gst.Rank.NONE, typeof(Gst.OpenCl.Kernel));
  Gst.Element.register (p, "clvideofilter", Gst.Rank.NONE, typeof(Gst.OpenCl.VideoFilter));
  return true;
}

/*
 * Opening a new namespace below Gst.
 * It is important that the prefix of your namespace matches the symbol 
 * export regex.
 */
namespace Gst.OpenCl
{
  // Bummer
}

