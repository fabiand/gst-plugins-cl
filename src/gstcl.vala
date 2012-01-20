
using GOpenCL;

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


const string program_source = """
__kernel void simple_kernel (__global float* src, __global float* dst)
{
  int gid = get_global_id (0);
  int lid = get_local_id (0);
  dst[gid] = src[gid]; //sin(src[gid]) + exp(src[gid]);
#if DEBUG
  printf ("Kernel on %d %d- %d\n", gid, lid, dst[gid]);
#endif
}
""";

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
        "sink", Gst.PadDirection.SINK, Gst.PadPresence.ALWAYS, 
        video_format_new_template_caps (Gst.VideoFormat.GRAY8)
      );

      src_factory = new Gst.PadTemplate (
        "src", Gst.PadDirection.SRC, Gst.PadPresence.ALWAYS, 
        video_format_new_template_caps (Gst.VideoFormat.GRAY8)
      );

      add_pad_template (sink_factory);
      add_pad_template (src_factory);
    }

    /*
     * Instance part
     */
    Context ctx;
    CommandQueue q;
    Program program;
    
    public override bool start ()
    {
      Platform[] platforms = Platform.get_available ();
      Platform platform = platforms[0];
      Device[] devices = platform.get_devices ();

      debug (@"\n$(platforms.length) platform(s) available.");
      debug (@"\n$(devices.length) device(s) attached to platform $(platform).");
      
      ctx = platform.create_context ();
      q = ctx.create_command_queue ();
      
      program = ctx.create_program_with_source (program_source);
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
      var buf_src = ctx.create_host_buffer (sizeof(uint8) * inbuf.data.length, inbuf.data);
      var buf_dst = ctx.create_host_buffer (sizeof(uint8) * outbuf.data.length, outbuf.data);

      var kernel = program.create_kernel ("simple_kernel", {buf_src, buf_dst});
//debug("%g", outbuf.data.length);
      q.enqueue_kernel (kernel, 1, {outbuf.data.length}).wait ();
//      q.flush ();
/*      q.enqueue_map_buffer (buf_dst, true).wait ();*/

      return Gst.FlowReturn.OK;
    }
  }
}

