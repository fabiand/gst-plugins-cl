
__kernel void 
default_kernel (__global       uchar* dst, 
                __global const uchar* src, 
                         const uint   size)
{
  int gid = get_global_id (0);
  int lid = get_local_id (0);
  dst[gid] = src[gid];
}

__kernel void 
reduce (__global       uchar* dst, 
        __global const uchar* src, 
                 const uint   size)
{
  int gid = get_global_id (0);
  int lid = get_local_id (0);
  dst[gid] = clamp(src[gid] - 10, 0, 255);
}
