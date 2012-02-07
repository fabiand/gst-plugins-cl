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
    protected GOpenCL.Buffer buf_dst;
      
    static construct {
      set_details_simple (
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
    requires (inbuf.size == outbuf.size)
    {      
      prepare_buffers (inbuf, outbuf);

      process (inbuf, outbuf);
      
      return Gst.FlowReturn.OK;
    }
    
    public virtual void prepare_buffers (Gst.Buffer inbuf, Gst.Buffer outbuf)
    {
      buf_src = ctx.create_buffer (inbuf.size, 
                                   OpenCL.MemFlags.COPY_HOST_PTR | 
                                   OpenCL.MemFlags.READ_ONLY, 
                                   inbuf.data);
      buf_dst = ctx.create_buffer (outbuf.size,
                                   OpenCL.MemFlags.WRITE_ONLY);
    }
    
    public virtual void process (Gst.Buffer inbuf, Gst.Buffer outbuf)
    {
      kernel.set_argument (0, &buf_dst.mem, sizeof(OpenCL.Mem));
      kernel.set_argument (1, &buf_src.mem, sizeof(OpenCL.Mem));
      kernel.set_argument (2, &inbuf.size, sizeof(uint));
      
      q.enqueue_kernel (kernel, 1, {inbuf.size});
      q.enqueue_read_buffer (buf_dst, true, outbuf.data, outbuf.size);
      q.finish ();
    }
  }
  
}
