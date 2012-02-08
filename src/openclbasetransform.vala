/* vim: set tabstop=8 softtabstop=2 shiftwidth=2 expandtab: */

using GOpenCL;

namespace Gst.OpenCl
{
  /*
   * An OpenCL Kernel element.
   */
  public class OpenCLBaseTransform : Gst.BaseTransform
  {
    protected static Gst.PadTemplate sink_factory;
    protected static Gst.PadTemplate src_factory;
    
    protected Platform platform;
    protected Context ctx;
    protected CommandQueue q;
    protected Program program;
    
    protected string kernel_source;
    protected GOpenCL.Kernel kernel;
    
    public uint platform_idx {
      get;
      set;
      default = 0;
    }
    public string kernel_name {
      get;
      set;
      default = "default_kernel";
    }
    public string? kernel_file {
      get;
      set;
      default = null;
    }
    
    construct {
      Platform[] platforms = Platform.get_available ();
      platform = platforms[platform_idx];
      Device[] devices = platform.get_devices ();

      debug (@"$(platforms.length) platform(s) available.");
      debug (@"Platform: $(platform.get_info(OpenCL.PlatformInfo.NAME))");
      debug (@"$(devices.length) device(s) attached to platform $(platform).");
      
      ctx = platform.create_context ();
      q = ctx.create_command_queue ();
    }
    
    protected class void init_any_caps ()
    {
      sink_factory = new Gst.PadTemplate (
        "sink", 
        Gst.PadDirection.SINK, 
        Gst.PadPresence.ALWAYS, 
        new Gst.Caps.any ()
      );

      src_factory = new Gst.PadTemplate (
        "src", 
        Gst.PadDirection.SRC, 
        Gst.PadPresence.ALWAYS, 
        new Gst.Caps.any ()
      );

      add_pad_template (sink_factory);
      add_pad_template (src_factory);
    }
    
    string load_source_from_file ()
    {
      uint8[] c = null;
      if (this.kernel_file != null)
      {
        File f = File.new_for_path (this.kernel_file);
        f.load_contents (null, out c);
      }
      return (string) c;
    }
    
    public override bool start ()
    {
      string source = this.load_source_from_file () ?? kernel_source;
      debug (@"Building program from:\n $(kernel_file)\n ?? $(source)"); // FIXME it should be file ?? source, but this segfaults
      program = ctx.create_program_with_source (source);
      kernel = program.create_kernel (this.kernel_name);
      
      return true;
    }

    public override bool stop ()
    {
      return true;
    }
  }
}
