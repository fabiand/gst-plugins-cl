__kernel void 
default_kernel (__global const uint* src, 
                         const ulong size_src,
               __global       uint* dst, 
                         const ulong size_dst)
{
  int gid = get_global_id (0);
  int lid = get_local_id (0);
  float v = (float) src[gid];
  float c = v / 10;
  dst[gid] = c;
}
