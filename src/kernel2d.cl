
#define clamp(x, a, b) ((x) < (a) ? (a) : ((x) > (b) ? (b) : (x)))


__kernel void 
default_kernel (__global const uint* dst, 
                __global       uint* src, 
                         const ulong width,
                         const ulong height)
{
  const int x = get_global_id (0);
  const int y = get_global_id (1);
  const int idx = y * width + x;
  
  float v = (float) src[gid];
  float c = v / 10;
  dst[idx] = c;
  
//  printf("%d, %d\n", x, y);
}
