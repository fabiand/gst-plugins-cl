/* vim: set tabstop=8 softtabstop=2 shiftwidth=2 expandtab: */

using GOpenCL;

namespace Gst.OpenCl
{

  const string DEFAULT_SOURCE_KERNEL = """
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

  /*
   * An OpenCL Kernel element.
   */
  public class Kernel : OpenCLBaseTransform
  {
    protected GOpenCL.Buffer buf_src;
    protected Gst.MapInfo buf_src_info;
    protected GOpenCL.Buffer buf_dst;
    protected Gst.MapInfo buf_dst_info;


    static construct {
      set_static_metadata (
        "clkernel", 
        "Filter", 
        "Applying a 1-D OpenCl kernel", 
        "author@fabiand.name");

      init_any_caps ();
    }

    construct {
      kernel_source = DEFAULT_SOURCE_KERNEL;
    }

    public override bool set_caps (Gst.Caps incaps, Gst.Caps outcaps)
    {
      debug (@"Incaps: $(incaps)");
      return true;
    }

    public override Gst.FlowReturn transform (Gst.Buffer inbuf, Gst.Buffer outbuf)
    requires (inbuf.get_size() == outbuf.get_size())
    {
      prepare_buffers (inbuf, outbuf);

      process (inbuf, outbuf);

      finalize_buffers (inbuf, outbuf);

      return Gst.FlowReturn.OK;
    }

    public virtual void prepare_buffers (Gst.Buffer inbuf, Gst.Buffer outbuf)
    {
      buf_src_info = Gst.MapInfo();
      inbuf.map(out buf_src_info, Gst.MapFlags.READ);
      buf_src = ctx.create_buffer (buf_src_info.size,
                                   OpenCL.MemFlags.COPY_HOST_PTR |
                                   OpenCL.MemFlags.READ_ONLY,
                                   buf_src_info.data);

      buf_dst_info = Gst.MapInfo();
      outbuf.map(out buf_dst_info, Gst.MapFlags.WRITE);
      buf_dst = ctx.create_buffer (outbuf.get_size(),
                                   OpenCL.MemFlags.WRITE_ONLY);
    }

    public virtual void process (Gst.Buffer inbuf, Gst.Buffer outbuf)
    {
      kernel.set_argument (0, &buf_dst.mem, sizeof(OpenCL.Mem));
      kernel.set_argument (1, &buf_src.mem, sizeof(OpenCL.Mem));
      kernel.set_argument (2, &buf_src_info.size, sizeof(uint));

      q.enqueue_kernel (kernel, 1, {inbuf.get_size()});
      q.enqueue_read_buffer (buf_dst, true, buf_dst_info.data,
                             buf_dst_info.size);
      q.finish ();
    }

    public virtual void finalize_buffers (Gst.Buffer inbuf, Gst.Buffer outbuf)
    {
      inbuf.unmap(buf_src_info);
      inbuf.unmap(buf_dst_info);
    }

  }
  
}
