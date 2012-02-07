/* vim: set tabstop=8 softtabstop=2 shiftwidth=2 expandtab: */

namespace Gst.OpenCl
{

  const string DEFAULT_SOURCE_VIDEOFILTER =  """
__kernel void 
default_kernel (__write_only  image2d_t dst, 
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
""";

  public class VideoFilter : Kernel
  {
    Gst.VideoFormat format;
    int width;
    int height;
    
    GOpenCL.Image2D buf_src;
    GOpenCL.Image2D buf_dst;
    GOpenCL.Sampler src_sampler;
    GOpenCL.Kernel kernel;
    
    const OpenCL.ImageFormat required_cl_image_format = {
      OpenCL.ChannelOrder.RGBA, 
      OpenCL.ChannelType.UNSIGNED_INT8
    };
    
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
        video_format_new_template_caps (Gst.VideoFormat.RGBA)
      );

      src_factory = new Gst.PadTemplate (
        "src", 
        Gst.PadDirection.SRC, 
        Gst.PadPresence.ALWAYS, 
        video_format_new_template_caps (Gst.VideoFormat.RGBA)
      );

      add_pad_template (sink_factory);
      add_pad_template (src_factory);
    }
    
    construct {
      kernel_source = DEFAULT_SOURCE_VIDEOFILTER;
      
      kernel = program.create_kernel (this.kernel_name);
      
      src_sampler = new GOpenCL.Sampler (ctx, false, 
                                         OpenCL.AddressingMode.CLAMP, 
                                         OpenCL.FilterMode.NEAREST);
    }
    
    public override bool set_caps (Gst.Caps incaps, Gst.Caps outcaps)
    {
      debug (@"$(incaps)");
      Gst.video_format_parse_caps  (incaps, ref format, ref width, ref height);
      
      bool r = true;
      
      if (!(required_cl_image_format in ctx.supported_image_formats ()))
      {
        error ("OpenCL context does not support the required image format (%s %s).",
                 required_cl_image_format.image_channel_order.to_string(),
                 required_cl_image_format.image_channel_data_type.to_string());
        r = false;
      }
      
      return r;
    }
    
    public override Gst.FlowReturn transform (Gst.Buffer inbuf, Gst.Buffer outbuf)
    requires (inbuf.size == outbuf.size)
    {
      Memory.set (outbuf.data, 0, outbuf.size);
      
      buf_dst = ctx.create_image (width, height);
      buf_src = ctx.create_image (width, height);
      
      kernel.set_argument (0, &buf_dst.mem, sizeof(OpenCL.Mem));
      kernel.set_argument (1, &buf_src.mem, sizeof(OpenCL.Mem));
      kernel.set_argument (2, &src_sampler.sampler, sizeof(OpenCL.Sampler));
      kernel.set_argument (3, &width, sizeof(int));
      kernel.set_argument (4, &height, sizeof(int));

      q.enqueue_write_image (buf_dst, outbuf.data, true);
      q.enqueue_write_image (buf_src, inbuf.data, true);
      q.enqueue_kernel (kernel, 2, {width, height});      
      q.enqueue_read_image (buf_dst, true, outbuf.data);
      q.finish ();

      return Gst.FlowReturn.OK;
    }
  }
}
