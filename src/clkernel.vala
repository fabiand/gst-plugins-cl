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
      GOpenCL.Buffer buf_src,
                     buf_dst;
      GOpenCL.Kernel kernel;
      
      prepare_buffers (inbuf, outbuf, 
                       out buf_src, out buf_dst);

      process (out kernel, 
               inbuf, outbuf,
               buf_src, buf_dst);
      
      return Gst.FlowReturn.OK;
    }
    
    public virtual void prepare_buffers (Gst.Buffer inbuf, Gst.Buffer outbuf,
                          out GOpenCL.Buffer buf_src, out GOpenCL.Buffer buf_dst)
    {
      buf_src = ctx.create_buffer (inbuf.size, 
                                   OpenCL.MemFlags.COPY_HOST_PTR | 
                                   OpenCL.MemFlags.READ_ONLY, 
                                   inbuf.data);
      buf_dst = ctx.create_buffer (outbuf.size,
                                   OpenCL.MemFlags.WRITE_ONLY);
    }
    
    public virtual void process (out GOpenCL.Kernel kernel, 
                            Gst.Buffer inbuf, Gst.Buffer outbuf,
                            GOpenCL.Buffer buf_src, GOpenCL.Buffer buf_dst)
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
  
}
