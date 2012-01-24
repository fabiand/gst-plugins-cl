
#define clamp(x, a, b) ((x) < (a) ? (a) : ((x) > (b) ? (b) : (x)))


__kernel void 
default_kernel (__global const uint* dst, 
                         const ulong dst_size,
                __global       uint* src, 
                         const ulong src_size)
{
  int gid = get_global_id (0);
  int lid = get_local_id (0);
  
  float v = (float) src[gid];
  float c = v / 10;
  dst[gid] = c;
  
//  printf("%d, %d\n", x, y);
}
