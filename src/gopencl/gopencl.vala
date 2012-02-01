
/*
 * A simple wrapper around OpenCL - May OpenCL gain momentum. :)
 */

void check_result (OpenCL.ErrorCode r, string m) throws Error
{
  if (r != OpenCL.ErrorCode.SUCCESS) 
    throw new GOpenCL.PlatformError.UNKNOWN (m + @"\nErrorCode: $(r)");
}


[CCode (cprefix = "g_opencl_", lower_case_cprefix = "g_opencl_")]
namespace GOpenCL
{
  public errordomain PlatformError
  {
    NO_PLATFORM,
    UNKNOWN
  }

  /*
   * Wrapper for PlatformId
   */
  public class Platform : Object
  {
    public OpenCL.PlatformId id;

    public string profile {
      owned get { return this.get_info (OpenCL.PlatformInfo.PROFILE); }
    }

    public string version {
      owned get { return this.get_info (OpenCL.PlatformInfo.VERSION); }
    }

    public string name {
      owned get { return this.get_info (OpenCL.PlatformInfo.NAME); }
    }

    public string vendor {
      owned get { return this.get_info (OpenCL.PlatformInfo.VENDOR); }
    }

    public string extensions {
      owned get { return this.get_info (OpenCL.PlatformInfo.EXTENSIONS); }
    }


    public Platform.with_id (OpenCL.PlatformId i)
    {
      this.id = i;
    }

    public static Platform[] get_available () throws Error
    {
      OpenCL.ErrorCode result;
      OpenCL.PlatformId[] platforms = null;
      uint num_platforms = 0;
      Platform[] gplatforms = null;

      result = OpenCL.GetPlatformIDs(0, null, out num_platforms);
      check_result (result, "Error while getting the number of platforms.");

      if (num_platforms == 0)
      {
        gplatforms = new Platform[0];
      }
      else
      {
        platforms = new OpenCL.PlatformId[ num_platforms ];

        result = OpenCL.GetPlatformIDs(platforms.length, platforms, out num_platforms);
        check_result (result, "Error while getting the platforms.");

        gplatforms = Platform.from_opencl_array (platforms);
      }

      return gplatforms;
    }

    public string get_info (OpenCL.PlatformInfo info)
    {
      OpenCL.ErrorCode result;
      char[] buf = new char[128];
      size_t buf_len;

      try
      {
        result = OpenCL.GetPlatformInfo(this.id, info, buf.length, buf, out buf_len);
        check_result (result, "Invalid retun value while fetching platform info" + 
                      " %s.".printf(info.to_string ()));
        buf.length = (int) buf_len;
      }
      catch (Error e)
      {
        warning (e.message);
        buf = null;
      }

      return (string) buf;
    }

    public Device[] get_devices (OpenCL.DeviceType type = 
                                  OpenCL.DeviceType.DEFAULT) throws Error
    {
      OpenCL.ErrorCode result;
      OpenCL.DeviceId[] devices = null;
      uint num_devices = 0;
      Device[] gdevices = null;

      result = OpenCL.GetDeviceIDs(this.id, type, 0, null, out num_devices);
      check_result (result, "Unable to get the number of devices.");

      devices = new OpenCL.DeviceId[ num_devices ];

      result = OpenCL.GetDeviceIDs(this.id, type, devices.length, devices, 
                            out num_devices);
      check_result (result, "Unable to get the devices.");

      gdevices = Device.from_opencl_array (this, devices);

      return gdevices;
    }

    public Context create_context (OpenCL.DeviceType type = 
                                  OpenCL.DeviceType.DEFAULT) throws Error
    {
      return new Context (null, this.get_devices (type));
    }

    public static Platform[] from_opencl_array (OpenCL.PlatformId[] ids)
    {
      Platform[] platforms = new Platform[ ids.length ];
      for (int i = 0; i < ids.length; i++)
      {
        platforms[i] = new Platform.with_id (ids[i]);
      }
      return platforms;
    }

    public static OpenCL.PlatformId[] to_opencl_array (Platform[] os)
    {
      OpenCL.PlatformId[] ids = new OpenCL.PlatformId[ os.length ];
      for (int i = 0; i < os.length; i++)
      {
        ids[i] = os[i].id;
      }
      return ids;
    }

    public string to_string ()
    {
      return "Platform %p".printf((void*) this.id);
    }

    public string get_summary ()
    {
      return @"$(this):\n Profile: %s\n Version: %s\n Name: %s\n Vendor: %s".printf (
                this.profile,
                this.version,
                this.name,
                this.vendor);
    }
  }



  /*
   * Wrapper for DeviceId
   */
  public class Device : Object
  {
    public OpenCL.DeviceId id;
    public Platform platform;

    public OpenCL.DeviceType device_type {
      get { return this.get_info<OpenCL.DeviceType> (OpenCL.DeviceInfo.TYPE); }
    }

    public string name {
      owned get { return this.get_info<string> (OpenCL.DeviceInfo.NAME); }
    }

    public string vendor {
      owned get { return this.get_info<string> (OpenCL.DeviceInfo.VENDOR); }
    }

    public string device_version {
      owned get { return this.get_info<string> (OpenCL.DeviceInfo.VERSION); }
    }

    public string profile {
      owned get { return this.get_info<string> (OpenCL.DeviceInfo.PROFILE); }
    }

    public string driver_version {
      owned get { return this.get_info<string> (OpenCL.DeviceInfo.DRIVER_VERSION); }
    }

    public ulong local_mem_size {
      get { return this.get_info<ulong> (OpenCL.DeviceInfo.LOCAL_MEM_SIZE); }
    }

    public OpenCL.LocalMemType local_mem_type {
      get { return this.get_info<OpenCL.LocalMemType> (OpenCL.DeviceInfo.LOCAL_MEM_TYPE); }
    }

    public uint max_compute_units {
      get { return this.get_info<uint> (OpenCL.DeviceInfo.MAX_COMPUTE_UNITS); }
    }
    
    public uint max_work_item_dimensions {
      get { return this.get_info<uint> (OpenCL.DeviceInfo.MAX_WORK_ITEM_DIMENSIONS); }
    }

    public size_t* max_work_item_sizes {
      get { return this.get_info<size_t*> (OpenCL.DeviceInfo.MAX_WORK_ITEM_SIZES); }
    }

    public size_t max_work_group_size {
      get { return this.get_info<size_t> (OpenCL.DeviceInfo.MAX_WORK_GROUP_SIZE); }
    }
    
    public bool has_image_support {
      get { return this.get_info<bool> (OpenCL.DeviceInfo.IMAGE_SUPPORT); }
    }
    
    public size_t image2d_max_width {
      get { return this.get_info<size_t> (OpenCL.DeviceInfo.IMAGE2D_MAX_WIDTH); }
    }

    public size_t image2d_max_height {
      get { return this.get_info<size_t> (OpenCL.DeviceInfo.IMAGE2D_MAX_HEIGHT); }
    }

    public ulong global_mem_size {
      get { return this.get_info<ulong> (OpenCL.DeviceInfo.GLOBAL_MEM_SIZE); }
    }
    
    public bool available {
      get { return this.get_info<bool> (OpenCL.DeviceInfo.AVAILABLE); }
    }
    
    public OpenCL.PlatformId platform_id {
      get { return this.get_info<OpenCL.PlatformId> (OpenCL.DeviceInfo.PLATFORM); }
    }

    public Device.with_id (Platform p, OpenCL.DeviceId did)
    {
      this.platform = p;
      this.id = did;
    }

    public T get_info<T> (OpenCL.DeviceInfo info, out size_t len = null)
    {
      OpenCL.ErrorCode result;
      char[] buf = null;
      size_t buf_len = -1;

      void* ptr = null;

      /*
       * Just handles a small subset of getdevicinfo
       */
      switch (info)
      {
        case OpenCL.DeviceInfo.TYPE:
          result = OpenCL.GetDeviceInfo(this.id, info, sizeof(OpenCL.DeviceType), &ptr, null);
          break;

        case OpenCL.DeviceInfo.HOST_UNIFIED_MEMORY:
        case OpenCL.DeviceInfo.LOCAL_MEM_SIZE:
        case OpenCL.DeviceInfo.LOCAL_MEM_TYPE:
          result = OpenCL.GetDeviceInfo(this.id, info, sizeof(void*), &ptr, null);
          break;

        default:
          buf = new char[128];
          result = OpenCL.GetDeviceInfo(this.id, info, buf.length, buf, out buf_len);
          break;
      }

      try
      {
        check_result (result, "Invalid return value while fetching device info" +
                      " %s.".printf(info.to_string ()));
      }
      catch (Error e)
      {
        warning (e.message);
        ptr = null;
      }

      if (buf_len > -1 || buf != null)
      {
        len = buf_len;
        return (T) buf;
      }

      return (T) ptr;
    }

    public static Device[] from_opencl_array (Platform p, OpenCL.DeviceId[] ids)
    {
      Device[] devices = new Device[ ids.length ];
      for (int i = 0; i < ids.length; i++)
      {
        devices[i] = new Device.with_id (p, ids[i]);
      }
      return devices;
    }

    public static OpenCL.DeviceId[] to_opencl_array (Device[] os)
    {
      OpenCL.DeviceId[] ids = new OpenCL.DeviceId[ os.length ];
      for (int i = 0; i < os.length; i++)
      {
        ids[i] = os[i].id;
      }
      return ids;
    }

    public string to_string ()
    {
      return "Device %p (%p)".printf ((void*) this.id, 
                                      (void*) this.platform.id);
    }

    public string get_summary ()
    {
      return @"$(this):\n Type: %s\n Name: %s\n Vendor: %s\n Device version: %s\n Driver version: %s\n Mem. size/type: %s %s".printf (
                this.device_type.to_string (),
                this.name,
                this.vendor,
                this.device_version,
                this.driver_version,
                this.local_mem_size.to_string (),
                this.local_mem_type.to_string ());
    }
  }

  /*
   * Wrapper for Context
   */
  public class Context : Object
  {
    public OpenCL.Context context;
    public OpenCL.ContextProperties[] properties;

    public Device[] devices;

    public Context (OpenCL.ContextProperties[]? ps, Device[] ds) throws Error
    {
      this.properties = ps;
      this.devices = ds;

      OpenCL.ErrorCode err;
      OpenCL.DeviceId[] clds = new OpenCL.DeviceId[ds.length];

      for (int i = 0; i < ds.length; i++)
      {
        clds[i] = ds[i].id;
      }

      this.context = OpenCL.CreateContext (ps, clds.length, clds, null, null, out err);
      check_result (err, "Something failed while creating a context.");
    }

    public Context.from_type (OpenCL.DeviceType t, OpenCL.ContextProperties[]? ps = null) throws Error
    {
      this.properties = ps;

      OpenCL.ErrorCode err;
      this.context = OpenCL.CreateContextFromType (ps, t, null, null, out err);
      check_result (err, "Something failed while creating a context from type.");
    }


    /* FIXME to device? */
    public CommandQueue create_command_queue (Device? d = null, OpenCL.CommandQueueProperties ps = 0) throws Error
    {
      if (d == null)
      {
        d = this.devices[0]; //FIXME take first device or some other
      }

      if (!(d in this.devices))
      {
        throw new PlatformError.UNKNOWN ("Device needs to be in context.");
      }

      return new CommandQueue.from_context (this, d, ps);
    }

    public Program create_program_with_source (string source) throws Error
    {
      return new Program.with_source (this, source);
    }

    public Buffer create_buffer (size_t size, OpenCL.MemFlags flags = OpenCL.MemFlags.READ_WRITE, void* ptr = null) throws Error
    {
      return new Buffer.in_context (this, flags, size, ptr);
    }

    public Image2D create_image (size_t w, size_t h, void* buf = null, size_t pitch = 0) throws Error
    {
      return new Image2D.in_context (this, 
                                     OpenCL.MemFlags.READ_WRITE, 
                                     w, 
                                     h, 
                                     pitch, 
                                     buf);
    }
    
    public OpenCL.ImageFormat[] supported_image_formats ()
    {
      uint num_formats = 0;
      OpenCL.ImageFormat[] formats = new OpenCL.ImageFormat[256];
      OpenCL.ErrorCode err;
      err = OpenCL.GetSupportedImageFormats (this.context,
                                             OpenCL.MemFlags.READ_WRITE, 
                                             OpenCL.MemObjectType.IMAGE2D,
                                             formats.length,
                                             formats,
                                             out num_formats);
      check_result (err, "Something failed while querying available image formats.");
      formats = formats[0:num_formats];
      return formats;
    }
  }

  /*
   * Wrapper for CommandQueue
   */
  public class CommandQueue : Object
  {
    public OpenCL.CommandQueue command_queue;

    public Device device;

    public CommandQueue.from_context (Context ctx, Device d, OpenCL.CommandQueueProperties ps = 0) throws Error
    {
      this.device = d;

      OpenCL.ErrorCode err;
      this.command_queue = OpenCL.CreateCommandQueue (
                              ctx.context, 
                              d.id, 
                              ps, 
                              out err);
      check_result (err, "Something failed while creating a command queue.");
    }

    public NativeKernel create_native_kernel (void* kernel, Buffer[] bs)
    {
      return new NativeKernel.from_commandqueue (this, kernel, bs);
    }

    public Event enqueue_task (Kernel k) throws Error
    {
      OpenCL.ErrorCode result;
      OpenCL.Event event;

      result = OpenCL.EnqueueTask (this.command_queue, k.kernel, 0, null, out event);
      check_result (result, "Failed while executing task.");

      return new Event.with_event (event);
    }

    public Event enqueue_kernel (Kernel k, uint work_dim, size_t[] gwork_s, OpenCL.Event[]? wait_for = null) throws Error
    {
      OpenCL.ErrorCode result;
      OpenCL.Event event;

      size_t[] lwork_s = null;
      result = OpenCL.EnqueueNDRangeKernel (this.command_queue, k.kernel, 
        work_dim, null, gwork_s, lwork_s, 
        wait_for == null ? 0 : wait_for.length, wait_for, 
        out event);
      check_result (result, "Failed while executing ndrange kernel.");

      if (event == null)
      {
        warning ("Kernel event is null.");
      }

      return new Event.with_event (event);
    }

    
    public void flush ()
    {
      OpenCL.Flush (this.command_queue);
    }

    public void finish ()
    {
      OpenCL.Finish (this.command_queue);
    }

    public Event enqueue_write_buffer (Buffer b, bool is_blocking, void* buf, size_t buf_len, OpenCL.Event[]? wait_for = null) throws Error
    {
      OpenCL.ErrorCode result;
      OpenCL.Event? event;
      result = OpenCL.EnqueueWriteBuffer (
        this.command_queue, 
        b.mem, 
        is_blocking, 
        0, 
        buf_len, buf, 
        0, null,
        out event);
      check_result (result, "Error while writing buffer.");
      return new Event.with_event (event);
    }

    public Event enqueue_read_buffer (Buffer b, bool is_blocking, void* buf, size_t buf_len, OpenCL.Event[]? wait_for = null) throws Error
    {
      OpenCL.ErrorCode result;
      OpenCL.Event? event;
      result = OpenCL.EnqueueReadBuffer (
        this.command_queue, 
        b.mem, 
        is_blocking, 
        0, 
        buf_len, buf, 
        0, null,
        out event);
      check_result (result, "Error while reading buffer.");
      return new Event.with_event (event);
    }
    
    
    public Event enqueue_write_image  (Image2D buf, void* im, bool is_blocking)
    {
      OpenCL.ErrorCode result;
      OpenCL.Event event;
      size_t[] origin = { 0, 0, 0 };
      size_t[] region = { buf.width, buf.height, 1 };
      size_t input_row_pitch = 0, input_slice_pitch = 0;
      result = OpenCL.EnqueueWriteImage(this.command_queue,
                    buf.mem,
                    is_blocking, 
                    origin,
                    region,
                    input_row_pitch,
                    input_slice_pitch, 
                    im /*buf.obj*/,
                    0,
                    null,
                    out event);
      check_result (result, "Failed while writing image.");
      return new Event.with_event (event);
    }
    
    public Event enqueue_read_image (Image2D b, bool is_blocking, void* buf, OpenCL.Event[]? wait_for = null) throws Error
    {
      OpenCL.ErrorCode result;
      OpenCL.Event? event;
      size_t[] origin = { 0, 0, 0 };
      size_t[] region = { b.width, b.height, 1 };
      result = OpenCL.EnqueueReadImage (
        this.command_queue, 
        b.mem, 
        is_blocking, 
        origin, 
        region, 
        0,  0,
        buf,
        0, null,
        out event);
      check_result (result, "Error while reading buffer.");
      return new Event.with_event (event);
    }
  }

  /*
   * Wrapper for MemObject
   */
  public class Buffer : Object
  {
    public OpenCL.Mem mem;
    protected OpenCL.MemFlags flags;

    protected Context context;
    public void* obj;
    public size_t size;

    public Buffer.in_context (Context ctx, OpenCL.MemFlags flags, size_t size, void* buf) throws Error
    {
      this.context = ctx;
      this.flags = flags;

      this.obj = buf;
      this.size = size;

      OpenCL.ErrorCode err;
      this.mem = OpenCL.CreateBuffer (ctx.context, flags, size, buf, out err);
      check_result (err, "Something failed while creating a buffer from a context.");
    }

    public static void* to_opencl_array (Buffer[] bs)
    {
      OpenCL.Mem[] mems = new OpenCL.Mem[ bs.length ];
      for (int i = 0; i < bs.length; i++)
      {
        mems[i] = (owned) bs[i].mem;
      }
      return &mems;
    }
  }

  public class Image2D : Buffer
  {
    public size_t width;
    public size_t height;
    public size_t pitch;

    public const OpenCL.ImageFormat default_image_format = {
      OpenCL.ChannelOrder.RGBA, 
      OpenCL.ChannelType.UNSIGNED_INT8
    };

    public Image2D.in_context (Context ctx, 
                               OpenCL.MemFlags flags, 
                               size_t width, 
                               size_t height, 
                               size_t pitch, 
                               void* buf,
                               OpenCL.ImageFormat image_format = default_image_format) throws Error
    {
      this.context = ctx;
      this.flags = flags;

      this.obj = buf;
      this.width = width;
      this.height = height;
      this.pitch = pitch;

      OpenCL.ErrorCode err;
      this.mem = OpenCL.CreateImage2D(ctx.context,
                             flags,
                             &image_format,
                             width,
                             height,
                             pitch,
                             buf,
                             out err);
      check_result (err, "Something failed while creating an image2d in a context.");
    }
  }
  
  public class Sampler : Object
  {
    public OpenCL.Sampler sampler;
    
    public Sampler (Context ctx, bool normalized_coords, 
                    OpenCL.AddressingMode addressing_mode, 
                    OpenCL.FilterMode filter_mode)
    {
      OpenCL.ErrorCode err;
      this.sampler = OpenCL.CreateSampler (ctx.context, 
                                         normalized_coords, 
                                         addressing_mode, 
                                         filter_mode,
                                         out err);
      check_result (err, "Something failed while creating a sampler.");
    }
  }

  public class Program :  Object
  {
    public OpenCL.Program program;
    string source;
    public Context context;

    public Program.with_source (Context ctx, string s, bool do_build = true) throws Error
    {
      this.context = ctx;
      this.source = s;

      OpenCL.ErrorCode err;
      size_t len = s.length;
      this.program = OpenCL.CreateProgramWithSource (ctx.context, 1, {(char[])s.data}, {(size_t) s.data.length}, out err);
      check_result (err, @"Failed to create program from source:\n$(s)");

      if (do_build)
      {
        this.build ();
      }
    }

    public void build (Device[]? ds = null, string options = "", out string build_log = null) throws Error
    {
      OpenCL.ErrorCode result;
      Device[] devices = ds ?? context.devices;

      result = OpenCL.BuildProgram (this.program, 1, Device.to_opencl_array(devices), (char[]) options.data);
      if (result != OpenCL.ErrorCode.SUCCESS)
      {
        build_log = "";
        foreach (unowned Device d in devices)
        {
          size_t len;
          char[] log;
          OpenCL.GetProgramBuildInfo (this.program, d.id, OpenCL.ProgramBuildInfo.LOG, 0, null, out len);
          log = new char[len];
          OpenCL.GetProgramBuildInfo (this.program, d.id, OpenCL.ProgramBuildInfo.LOG, len, log, out len);
          build_log += "%s:\n%s\n".printf(d.to_string (), (string) log);
        }
        debug(build_log);
      }
      check_result (result, "Failed to build program.");
    }

    public Kernel create_kernel (string name, Buffer[]? buffers = null) throws Error
    {
      Kernel k = new Kernel.from_program (this, name);

      /* Additional arguments are expexted to be buffers. */
      foreach (var b in buffers)
      {
        k.add_buffer_argument (b);
      }

      return k;
    }
  }

    
  public class Kernel : Object
  {
    public OpenCL.Kernel kernel;

    Program program;
    string name;

    int num_args_set = 0;

    public Kernel.from_program (Program p, string n) throws Error
    {
      OpenCL.ErrorCode err;
      this.program = p;
      this.name = n;
      this.kernel = OpenCL.CreateKernel (p.program, (char[]) name.data, out err);
    }
    
    public void add_argument (void* p, size_t s) throws Error
    {
      OpenCL.ErrorCode result;
      result = OpenCL.SetKernelArg (this.kernel, this.num_args_set, s, p);
      check_result (result, @"Failed setting an argument on kernel '$(this.name)' ($(this.num_args_set)).");
      this.num_args_set++;
    }
    
    public void add_buffer_argument (Buffer b) throws Error
    {
      add_argument (&b.mem, sizeof(OpenCL.Mem));
    }
  }

  public class Event: Object 
  {
    public OpenCL.Event event;

    public OpenCL.CommandExecutionStatus execution_status {
      get { return this.get_info<OpenCL.CommandExecutionStatus> (OpenCL.EventInfo.COMMAND_EXECUTION_STATUS); }
    }

    public Event.with_event (OpenCL.Event e)
    {
      this.event = e;
    }

    public void wait () throws Error
    {
      OpenCL.ErrorCode result;
      result = OpenCL.WaitForEvents ({this.event});
      check_result (result, "Failed waiting for an event.");
    }

    public T get_info<T> (OpenCL.EventInfo info, out size_t len = null)
    {
      OpenCL.ErrorCode result;
      void* ptr = null;

      result = OpenCL.GetEventInfo(this.event, info, sizeof(void*), &ptr, null);

      try
      {
        check_result (result, "Invalid return value while fetching event info" +
                      " %s.".printf(info.to_string ()));
      }
      catch (Error e)
      {
        warning (e.message);
        ptr = null;
      }

      return (T) ptr;
    }
  }

  public class NativeKernel : Object
  {
    CommandQueue queue;
    Buffer[] buffers;

    OpenCL.Event[] events;

    void* kernel;

    public NativeKernel.from_commandqueue (CommandQueue q, void* k, Buffer[] bs)
    {
      this.queue = q;
      this.buffers = bs;
      this.kernel = k;
    }

    public void enqueue (void* args = null, int len_args = 0) throws Error
    {
      this.events = new OpenCL.Event[1];

      //void* mem_loc = &args;
      OpenCL.ErrorCode result;

      result = OpenCL.EnqueueNativeKernel(this.queue.command_queue, 
                                          this.kernel, 
                                          null, 0, /*args*/
                                          0, null, null, 
                                          0, null,  /*event*/
                                          out this.events[0]);

      check_result (result, "An error occurred whil queueing a native kernel.");
    }
  }
}
