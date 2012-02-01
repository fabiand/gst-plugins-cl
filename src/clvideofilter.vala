
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
        video_format_new_template_caps (Gst.VideoFormat.ARGB)
      );

      src_factory = new Gst.PadTemplate (
        "src", 
        Gst.PadDirection.SRC, 
        Gst.PadPresence.ALWAYS, 
        video_format_new_template_caps (Gst.VideoFormat.ARGB)
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
default_kernel_image2d (__write_only  image2d_t dst, 
                        __read_only   image2d_t src, 
                        const         sampler_t src_sampler, 
                        const         int       width,
                        const         int       height)
{
  const int x = get_global_id (0);
  const int y = get_global_id (1);

  uint4 val = read_imageui (src, src_sampler, (int2) (x, y));
  write_imageui(dst, (int2)( x, y ), val);
}

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
    construct {
      kernel_source = default_videofilter_source;
      
      kernel_name = "default_kernel_image2d";
    }
    
    public override bool set_caps (Gst.Caps incaps, Gst.Caps outcaps)
    {
      debug (@"$(incaps)");
      int w = 0, h = 0;
      Gst.video_format_parse_caps  (incaps, ref format, ref width, ref height);
      
      bool r = true;
      
      r &= context_supports_imageformat ();
      
      return r;
    }
    
    public override Gst.FlowReturn transform (Gst.Buffer inbuf, Gst.Buffer outbuf)
    requires (inbuf.size == outbuf.size)
    {
      return transform_image2d (inbuf, outbuf);
    }
    
    
    /*
     * The buffer (representing a 2d iimage) is passed to the opencl kernel as 
     * a buffer, not as an image.
     */
    Gst.FlowReturn transform_buffer (Gst.Buffer inbuf, Gst.Buffer outbuf)
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
    
    bool context_supports_imageformat ()
    {
      OpenCL.ImageFormat[] fs = ctx.supported_image_formats ();
      return true; //FIXME
    }
    
    Gst.FlowReturn transform_image2d (Gst.Buffer inbuf, Gst.Buffer outbuf)
    {
      GOpenCL.Image2D buf_src,
                      buf_dst;

      uint8[] dst = new uint8[outbuf.size];
      
      /*
      foreach (var f in fs)
      {
        debug ("%s %s", f.image_channel_order.to_string (), f.image_channel_data_type.to_string ());
      }*/
      
      buf_dst = ctx.create_image (width, height);
      buf_src = ctx.create_image (width, height);

      GOpenCL.Sampler src_sampler = new GOpenCL.Sampler (ctx, false, OpenCL.AddressingMode.CLAMP, OpenCL.FilterMode.NEAREST);

      q.enqueue_write_image (buf_src, inbuf.data, true);
      
      var kernel = program.create_kernel (this.kernel_name, {buf_dst, 
                                                             buf_src});
                                                             
      kernel.add_argument (&src_sampler.sampler, sizeof(OpenCL.Sampler));
      kernel.add_argument (&width, sizeof(int));
      kernel.add_argument (&height, sizeof(int));
      
      q.enqueue_kernel (kernel, 2, {width, height});

      q.finish ();
      
      q.enqueue_read_image (buf_dst, true, dst);

      q.finish ();

      Posix.memcpy (outbuf.data, dst, outbuf.size);

      return Gst.FlowReturn.OK;
    }
  }
}
