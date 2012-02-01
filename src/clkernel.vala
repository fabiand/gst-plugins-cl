
/* vim: set tabstop=8 softtabstop=2 shiftwidth=2 expandtab: */

// Have a look at https://gitorious.org/valastuff/ etc
using GOpenCL;

namespace Gst.OpenCl
{
  /*
   * An OpenCL Kernel element.
   */
  public class OpenCLVideoFilter : Gst.VideoFilter
  {
    protected static Gst.PadTemplate sink_factory;
    protected static Gst.PadTemplate src_factory;
    
    protected Platform platform;
    protected Context ctx;
    protected CommandQueue q;
    protected Program program;
    
    protected string kernel_source;
    
    public uint platform_idx {
      get;
      set;
      default = 0;
    }
    public string kernel_name {
      get;
      set;
      default = "default_kernel";
    }
    public string kernel_file {
      get;
      set;
      default = null;
    }
    
    protected class void init_any_caps ()
    {
      sink_factory = new Gst.PadTemplate (
        "sink", 
        Gst.PadDirection.SINK, 
        Gst.PadPresence.ALWAYS, 
        new Gst.Caps.any ()
      );

      src_factory = new Gst.PadTemplate (
        "src", 
        Gst.PadDirection.SRC, 
        Gst.PadPresence.ALWAYS, 
        new Gst.Caps.any ()
      );

      add_pad_template (sink_factory);
      add_pad_template (src_factory);
    }
    
    string load_source_from_file ()
    {
      uint8[] c = null;
      if (this.kernel_file != null)
      {
        File f = File.new_for_path (this.kernel_file);
        f.load_contents (null, out c);
      }
      return (string) c;
    }
    
    public override bool start ()
    {
      Platform[] platforms = Platform.get_available ();
      platform = platforms[platform_idx];
      Device[] devices = platform.get_devices ();

      debug (@"\n$(platforms.length) platform(s) available.");
      debug (@"Platform: $(platform.get_info(OpenCL.PlatformInfo.NAME))");
      debug (@"\n$(devices.length) device(s) attached to platform $(platform).");
      
      ctx = platform.create_context ();
      q = ctx.create_command_queue ();
      
      string source = this.load_source_from_file () ?? kernel_source;
      debug (@"Building program from:\n $(source)");
      program = ctx.create_program_with_source (source);
      
      return true;
    }

    public override bool stop ()
    {
      return true;
    }
  }
  
  public class Kernel : OpenCLVideoFilter
  {
    static construct {
      set_details_simple (
        "clkernel", 
        "Filter", 
        "Applying a 1-D OpenCl kernel", 
        "author@fabiand.name");

      init_any_caps ();
    }
    
    construct {
      kernel_source = """
__kernel void 
default_kernel (__global       uchar* dst, 
                __global const uchar* src, 
                         const uint   size)
{
  int gid = get_global_id (0);
  int lid = get_local_id (0);
  dst[gid] = src[gid];
}
""";
    }
    
    public override Gst.FlowReturn transform (Gst.Buffer inbuf, Gst.Buffer outbuf)
    requires (inbuf.size == outbuf.size)
    {
      GOpenCL.Buffer buf_src,
                     buf_dst;
      GOpenCL.Kernel kernel;
      
      prepare_buffers (inbuf, outbuf, 
                       out buf_src, out buf_dst);

      process (out kernel, 
               inbuf, outbuf,
               ref buf_src, ref buf_dst);
      
      return Gst.FlowReturn.OK;
    }
    
    public void prepare_buffers (Gst.Buffer inbuf, Gst.Buffer outbuf,
                          out GOpenCL.Buffer buf_src, out GOpenCL.Buffer buf_dst)
    {
      buf_src = ctx.create_buffer (inbuf.size, 
                                   OpenCL.MemFlags.COPY_HOST_PTR | 
                                   OpenCL.MemFlags.READ_ONLY, 
                                   inbuf.data);
      buf_dst = ctx.create_buffer (outbuf.size,
                                   OpenCL.MemFlags.WRITE_ONLY);
    }
    
    public void process (out GOpenCL.Kernel kernel, 
                            Gst.Buffer inbuf, Gst.Buffer outbuf,
                            ref GOpenCL.Buffer buf_src, ref GOpenCL.Buffer buf_dst)
    {
      kernel = program.create_kernel (this.kernel_name);
      kernel.add_buffer_argument (buf_dst);
      kernel.add_buffer_argument (buf_src);
      kernel.add_argument (&inbuf.size, sizeof(uint));
      
      q.enqueue_kernel (kernel, 1, {inbuf.size});
      q.enqueue_read_buffer (buf_dst, true, outbuf.data, 
                             outbuf.size);
      q.finish ();
    }
  }
  
  public class Kernel2D : Kernel
  {
    Gst.VideoFormat format;
    int width;
    int height;
    
    static construct {
      set_details_simple (
        "clvideofilter", 
        "Filter", 
        "Applying a 2-D OpenCl kernel.", 
        "author@fabiand.name");
      
      init_any_caps ();
    }

    construct {
      kernel_source = """
__kernel void 
default_kernel (__global        uchar* dst, 
                __global const  uchar* src, 
                         const  int width,
                         const  int height)
{
  const int x = get_global_id (0);
  const int y = get_global_id (1);
  const int idx = y * width + x;

  dst[idx] = src[idx];
}
""";
    }

    public override bool set_caps (Gst.Caps incaps, Gst.Caps outcaps)
    {
      debug (@"Incaps $(incaps).");
      Gst.video_format_parse_caps  (incaps, ref format, ref width, ref height);
      return true;
    }

    public override Gst.FlowReturn transform (Gst.Buffer inbuf, Gst.Buffer outbuf)
    requires (inbuf.size == outbuf.size)
    {
      GOpenCL.Buffer buf_src,
                     buf_dst;
      GOpenCL.Kernel kernel;
      
      prepare_buffers (inbuf, outbuf, 
                       out buf_src, out buf_dst);

      kernel = program.create_kernel (this.kernel_name);
      kernel.add_buffer_argument (buf_dst);
      kernel.add_buffer_argument (buf_src);
      kernel.add_argument (&width, sizeof(int));
      kernel.add_argument (&height, sizeof(int));
      
      q.enqueue_kernel (kernel, 2, {width, height});
      q.enqueue_read_buffer (buf_dst, true, outbuf.data, 
                             outbuf.size);
      q.finish ();
      
      return Gst.FlowReturn.OK;
    }
  }
}
