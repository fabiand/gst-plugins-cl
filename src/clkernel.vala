
/* vim: set tabstop=8 softtabstop=2 shiftwidth=2 expandtab: */

// Have a look at https://gitorious.org/valastuff/ etc
using GOpenCL;

const string default_kernel_source = """
__kernel void 
default_kernel (__global const uint* src, 
                         const ulong size_src,
                __global       uint* dst, 
                         const ulong size_dst)
{
  int gid = get_global_id (0);
  int lid = get_local_id (0);
  dst[gid] = src[gid];
}
""";

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
    protected static Gst.PadTemplate sink_factory;
    protected static Gst.PadTemplate src_factory;
    
    static construct {
      set_details_simple (
        "clkernel", 
        "Filter", 
        "Applying a OpenCl kernel", 
        "author@fabiand.name");

      sink_factory = new Gst.PadTemplate (
        "sink", Gst.PadDirection.SINK, Gst.PadPresence.REQUEST, 
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
    protected Platform platform;
    protected Context ctx;
    protected CommandQueue q;
    protected Program program;
    
    public string kernel_name { get; set; default = "default_kernel"; }
    public string kernel_file { get; set; default = null; }
    
    public override bool start ()
    {
      Platform[] platforms = Platform.get_available ();
      platform = platforms[0];
      Device[] devices = platform.get_devices ();

      debug (@"\n$(platforms.length) platform(s) available.");
      debug (@"\n$(devices.length) device(s) attached to platform $(platform).");
      
      ctx = platform.create_context ();
      q = ctx.create_command_queue ();
      
      string source = this.load_kernel_source () ?? default_kernel_source;
      debug (@"Building program from:\n $(source)");
      program = ctx.create_program_with_source (source);
      
      return true;
    }

    public override bool stop ()
    {
      return true;
    }

    Gst.Pad p;
    public override unowned Gst.Pad request_new_pad (Gst.PadTemplate templ, string? name)
    {
      debug (@"New pad requested! $(name)");
      p = new Gst.Pad.from_template (templ, name);
      this.add_pad ( p);
      return p;
    }

    public override Gst.FlowReturn transform (Gst.Buffer inbuf, Gst.Buffer outbuf)
    requires (inbuf.size == outbuf.size)
    {
      GOpenCL.Buffer buf_src,
                     buf_src_s,
                     buf_dst,
                     buf_dst_s;

      uint8[] dst = new uint8[outbuf.size];
      
      buf_src = ctx.create_source_buffer (sizeof(uint) * inbuf.size, inbuf.data);
      buf_dst = ctx.create_dst_buffer (sizeof(uint) * outbuf.size);
      
      ulong src_s = inbuf.size, 
            dst_s = outbuf.size;
      buf_src_s = ctx.create_source_buffer (sizeof(ulong), &src_s);
      buf_dst_s = ctx.create_source_buffer (sizeof(ulong), &dst_s);
      
      var kernel = program.create_kernel (this.kernel_name, {buf_dst, 
                                                             buf_dst_s,
                                                             buf_src,
                                                             buf_src_s});
      
      q.enqueue_kernel (kernel, 1, {inbuf.size});
      q.enqueue_read_buffer (buf_dst, true, dst, sizeof(uint8) * outbuf.size);

      q.finish ();

      Posix.memcpy (outbuf.data, dst, outbuf.size);

      return Gst.FlowReturn.OK;
    }
    
    
    string load_kernel_source ()
    {
      uint8[] c = null;
      if (this.kernel_file != null)
      {
        File f = File.new_for_path (this.kernel_file);
        f.load_contents (null, out c);
      }
      return (string) c;
    }
  }
}
