/* vim: set tabstop=8 softtabstop=2 shiftwidth=2 expandtab: */

using GOpenCL;

namespace Gst.OpenCl
{

  const string DEFAULT_SOURCE_KERNEL2D = """
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

  public class Kernel2D : Kernel
  {
    Gst.Video.Format format;
    int width;
    int height;

    static construct {
      set_static_metadata (
        "clvideofilter", 
        "Filter", 
        "Applying a 2-D OpenCl kernel.", 
        "author@fabiand.name");

      init_any_caps ();
    }

    construct {
      kernel_source = DEFAULT_SOURCE_KERNEL2D;
    }

    public override bool set_caps (Gst.Caps incaps, Gst.Caps outcaps)
    {
      debug (@"Incaps $(incaps).");
      var incapsinfo = Gst.Video.Info();
      incapsinfo.from_caps (incaps);
      this.format = incapsinfo.finfo.format;
      this.width = incapsinfo.width;
      this.height = incapsinfo.height;
      return true;
    }

    public override void process (Gst.Buffer inbuf, Gst.Buffer outbuf)
    {
      kernel.set_argument (0, &buf_dst.mem, sizeof(OpenCL.Mem));
      kernel.set_argument (1, &buf_src.mem, sizeof(OpenCL.Mem));
      kernel.set_argument (2, &width, sizeof(int));
      kernel.set_argument (3, &height, sizeof(int));

      q.enqueue_kernel (kernel, 2, {width, height});
      q.enqueue_read_buffer (buf_dst, true, buf_dst_info.data,
                             buf_dst_info.size);
      q.finish ();
    }
  }
}
