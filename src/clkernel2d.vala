/* vim: set tabstop=8 softtabstop=2 shiftwidth=2 expandtab: */

using GOpenCL;

namespace Gst.OpenCl
{
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

    public override void process (out GOpenCL.Kernel kernel, 
                            Gst.Buffer inbuf, Gst.Buffer outbuf,
                            GOpenCL.Buffer buf_src, GOpenCL.Buffer buf_dst)
    {
      kernel = program.create_kernel (this.kernel_name);
      kernel.add_buffer_argument (buf_dst);
      kernel.add_buffer_argument (buf_src);
      kernel.add_argument (&width, sizeof(int));
      kernel.add_argument (&height, sizeof(int));
      
      q.enqueue_kernel (kernel, 2, {width, height});
      q.enqueue_read_buffer (buf_dst, true, outbuf.data, 
                             outbuf.size);
      q.finish ();
    }
  }
}
