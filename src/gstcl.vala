
using Gst;




/*[CCode (cname = "plugin_init")]
public static bool plugin_init (Gst.Plugin p)
{
  debug ("Init push xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx");
  return Gst.Element.register (p, "clpush", Gst.Rank.NONE, typeof(Cl.Push));
}*/

namespace Gst
{

  public class Push : Gst.Element
  {
    public static Gst.Caps caps; 
    public static Gst.PadTemplate sink_factory = new Gst.PadTemplate ("sink", Gst.PadDirection.SINK, Gst.PadPresence.ALWAYS, caps.copy());
    public static Gst.PadTemplate src_factory = new Gst.PadTemplate ("src", Gst.PadDirection.SRC, Gst.PadPresence.ALWAYS, caps.copy());

    public static new Gst.StateChangeReturn change_state (Gst.StateChange transition)
    {
      return Gst.StateChangeReturn.SUCCESS;
    }

    Gst.Pad sink_pad;
    Gst.Pad src_pad;
    
    public Push ()
    {
      this.set_details_simple (
        "OpenCL Pusher", 
        "w/t/f", 
        "pushing to a opencl buffer", 
        "me");
      
      this.caps = Gst.Caps.from_string (VideoCaps.RGB);
      
      this.sink_pad = new Gst.Pad.from_template (Push.sink_factory, "sink");
      this.sink_pad.set_setcaps_function (Push.setcaps);
      this.sink_pad.set_chain_function (Push.chain);
      this.add_pad (this.sink_pad);

      this.src_pad = new Gst.Pad.from_template (Push.src_factory, "src");
      this.add_pad (this.src_pad);
    }
    
    public static bool setcaps (Gst.Pad pad, Gst.Caps caps)
    {
      // FIXME check caps get props p22
      return true;
    }

    public static Gst.FlowReturn chain (Gst.Pad pad, owned Gst.Buffer buf)
    {
      Push filter = pad.get_parent () as Push;
      return Gst.FlowReturn.OK;
    }





    public static bool setup (Push p, Gst.Buffer buf)
    {
      // FIXME ?
      debug ("Setup push xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx");
      return true;
    }
    public Gst.FlowReturn filter (Gst.BaseTransform bt, Gst.Buffer buf_out, Gst.Buffer buf_in)
    {
      return 0;
    }
  }
}


