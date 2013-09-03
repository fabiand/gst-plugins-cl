/* vim: set tabstop=8 softtabstop=2 shiftwidth=2 expandtab: */

[CCode(cname = "GST_VIDEO_CAPS_MAKE")]
extern Gst.Caps GST_VIDEO_CAPS_MAKE(Gst.Video.Format format);

namespace Gst.OpenCl
{

  const string OPENCL_MIME_IMAGE2D = "application/x-opencl-image2d";

  const string DEFAULT_SOURCE_VIDEOFILTER =  """
__kernel void 
default_kernel (__write_only  image2d_t dst, 
                __read_only   image2d_t src, 
                const         sampler_t src_sampler, 
                const         int       width,
                const         int       height)
{
  const int2 pos = (int2) (get_global_id (0), get_global_id (1));

  uint4 val = read_imageui (src, src_sampler, pos);
  write_imageui(dst, pos, val);
}
""";

  public class VideoFilter : Kernel
  {
    Gst.Video.Format format;
    int width;
    int height;

    /*
     * Overwrite previous variables, as we are in an imagespace.
     */
    new GOpenCL.Image2D buf_src;
    new GOpenCL.Image2D buf_dst;
    GOpenCL.Sampler src_sampler;

    const OpenCL.ImageFormat required_cl_image_format = {
      OpenCL.ChannelOrder.RGBA, 
      OpenCL.ChannelType.UNSIGNED_INT8
    };

    static construct {
      set_static_metadata (
        "clvideofilter", 
        "Filter", 
        "Applying a OpenCl kernel as a filter to a video.", 
        "author@fabiand.name");

      sink_factory = new Gst.PadTemplate (
        "sink", 
        Gst.PadDirection.SINK, 
        Gst.PadPresence.REQUEST, 
        GST_VIDEO_CAPS_MAKE (Gst.Video.Format.RGBA)
      );

      src_factory = new Gst.PadTemplate (
        "src", 
        Gst.PadDirection.SRC, 
        Gst.PadPresence.ALWAYS, 
        GST_VIDEO_CAPS_MAKE (Gst.Video.Format.RGBA)
      );

      add_pad_template (sink_factory);
      add_pad_template (src_factory);
    }

    construct {
      kernel_source = DEFAULT_SOURCE_VIDEOFILTER;
    }

    public override bool set_caps (Gst.Caps incaps, Gst.Caps outcaps)
    {
      debug (@"$(incaps)");
      var incapsinfo = Gst.Video.Info();
      incapsinfo.from_caps (incaps);
      this.format = incapsinfo.finfo.format;
      this.width = incapsinfo.width;
      this.height = incapsinfo.height;

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

    public override Gst.FlowReturn transform (Gst.Buffer inbuf,
                                              Gst.Buffer outbuf)
    requires (inbuf.get_size() == outbuf.get_size())
    {
      outbuf.memset(0, 0, outbuf.get_size());

      src_sampler = new GOpenCL.Sampler (ctx, false, 
                                         OpenCL.AddressingMode.CLAMP, 
                                         OpenCL.FilterMode.NEAREST);

      buf_dst = ctx.create_image (width, height);
      buf_src = ctx.create_image (width, height);
      
      kernel.set_argument (0, &buf_dst.mem, sizeof(OpenCL.Mem));
      kernel.set_argument (1, &buf_src.mem, sizeof(OpenCL.Mem));
      kernel.set_argument (2, &src_sampler.sampler, sizeof(OpenCL.Sampler));
      kernel.set_argument (3, &width, sizeof(int));
      kernel.set_argument (4, &height, sizeof(int));

      q.enqueue_write_image (buf_dst, buf_dst_info.data, true);
      q.enqueue_write_image (buf_src, buf_src_info.data, true);
      q.enqueue_kernel (kernel, 2, {width, height});
      q.enqueue_read_image (buf_dst, true, buf_src_info.data);
      q.finish ();

      return Gst.FlowReturn.OK;
    }
  }
}
