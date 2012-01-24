
/* vim: set tabstop=8 softtabstop=2 shiftwidth=2 expandtab: */

namespace Gst.OpenCl
{
  public class VideoFilter : Kernel
  {
    /*
     * Class part
     */
    static construct {
      set_details_simple (
        "clvideofilter", 
        "Filter", 
        "Applying a OpenCl kernel as a filter to a video.", 
        "author@fabiand.name");
      
      sink_factory = new Gst.PadTemplate (
        "sink", 
        Gst.PadDirection.SINK, 
        Gst.PadPresence.REQUEST, 
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
    Gst.VideoFormat format;
    int width;
    int height;
    
    string default_videofilter_source = """
__kernel void 
default_kernel (__global       uchar* dst, 
                __global const uchar* src, 
                         const int width,
                         const int height)
{
  const int x = get_global_id (0);
  const int y = get_global_id (1);
  const int idx = y * width + x;

  dst[idx] = src[idx];
}
""";
    
    construct {
      kernel_source = default_videofilter_source;
    }
    
    /*public override unowned Gst.Pad request_new_pad_full (Gst.PadTemplate? templ, string? name, Gst.Caps? caps)
    {
      debug (@"New pad requested!");
      this.add_pad (new Gst.Pad.from_template (templ, name));
      return null;
    }*/
    
    public override bool set_caps (Gst.Caps incaps, Gst.Caps outcaps)
    {
      debug (@"$(incaps)");
      int w = 0, h = 0;
      Gst.video_format_parse_caps  (incaps, ref format, ref width, ref height);
      return true;
    }
    
    public override Gst.FlowReturn transform (Gst.Buffer inbuf, Gst.Buffer outbuf)
    requires (inbuf.size == outbuf.size)
    {
      GOpenCL.Buffer buf_src,
                     buf_dst;

      uint8[] dst = new uint8[outbuf.size];
      
      buf_dst = ctx.create_dst_buffer (sizeof(uint) * outbuf.size);
      buf_src = ctx.create_source_buffer (sizeof(uint) * inbuf.size, inbuf.data);
      
      var kernel = program.create_kernel (this.kernel_name, {buf_dst, 
                                                             buf_src});
      kernel.add_argument (&width, sizeof(int));
      kernel.add_argument (&height, sizeof(int));
      
      q.enqueue_kernel (kernel, 2, {width, height});
      q.enqueue_read_buffer (buf_dst, true, dst, sizeof(uint8) * outbuf.size);

      q.finish ();

      Posix.memcpy (outbuf.data, dst, outbuf.size);

      return Gst.FlowReturn.OK;
    }
  }
}
