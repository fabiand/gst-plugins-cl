
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
  return Gst.Element.register (p, "clkernel", Gst.Rank.NONE, typeof(Gst.OpenCl.Kernel));
}



/*
 * Opening a new namespace below Gst.
 * It is important that the prefix of your namespace matches the symbol 
 * export regex.
 */
namespace Gst.OpenCl
{
  /*
   * An OpenCL Kernel element.
   */
  public class Kernel : Gst.VideoFilter
  {
    /*
     * Class part
     */
    static Gst.PadTemplate sink_factory;
    static Gst.PadTemplate src_factory;
    
    static construct {
      set_details_simple (
        "clkernel", 
        "Filter", 
        "Applying a OpenCl kernel", 
        "author@fabiand.name");

      sink_factory = new Gst.PadTemplate (
        "sink", 
        Gst.PadDirection.SINK, 
        Gst.PadPresence.ALWAYS, 
        video_format_new_template_caps (Gst.VideoFormat.GRAY8)
      );

      src_factory = new Gst.PadTemplate (
        "src", 
        Gst.PadDirection.SRC, 
        Gst.PadPresence.ALWAYS, 
        video_format_new_template_caps (Gst.VideoFormat.GRAY8)
      );

      add_pad_template (sink_factory);
      add_pad_template (src_factory);
    }
    




    /*
     * Instance part
     */
    public override bool start ()
    {
      return true;
    }

    public override bool stop ()
    {
      return true;
    }
    
    public override bool set_caps (Gst.Caps incaps, Gst.Caps outcaps)
    {
      return true;
    }
    
    long u = 0;
    public override Gst.FlowReturn transform (Gst.Buffer inbuf, Gst.Buffer outbuf)
    {
      for (uint i = outbuf.size; i > 10 ; i--)
      {
        float sum = 0;
        for (uint j = 10 ; j > 0 ; j--)
          sum += inbuf.data[i+j];
        sum = sum / 8;
        outbuf.data[i] = (uint8) sum;
      }
//      debug("%g", outbuf.size / 3);
      return Gst.FlowReturn.OK;
    }

    /*All by ourselfs
    Gst.Pad sink_pad;
    Gst.Pad src_pad;
    
    construct
    {
      debug ("construct push");
      
      sink_pad = new Gst.Pad.from_template (sink_factory, "sink");
      sink_pad.set_setcaps_function (setcaps);
      sink_pad.set_chain_function (chain);
      sink_pad.set_link_function (link_func);
      
      src_pad = new Gst.Pad.from_template (src_factory, "src");
      sink_pad.set_setcaps_function (setcaps);
      src_pad.set_link_function (link_func);
      
      add_pad (sink_pad);
      add_pad (src_pad);
    }
    
    public static bool setcaps (Gst.Pad pad, Gst.Caps caps)
    {
      return true;
    }
    
    public static Gst.PadLinkReturn link_func (Gst.Pad pad, Gst.Pad peer)
    {
      return Gst.PadLinkReturn.OK;
    }

    public static Gst.FlowReturn chain (Gst.Pad pad, owned Gst.Buffer buf)
    {
      Kernel filter = pad.get_parent () as Kernel;
      //debug ("got thing");
      return Gst.FlowReturn.OK;
    }*/
  }
}

