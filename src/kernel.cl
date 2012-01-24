
__kernel void 
default_kernel (__global const uchar* src, 
                         const ulong  size_src,
                __global       uchar* dst, 
                         const ulong  size_dst)
{
  int gid = get_global_id (0);
  int lid = get_local_id (0);
  dst[gid] = src[gid];
}

