
#define clamp(x, a, b) ((x) < (a) ? (a) : ((x) > (b) ? (b) : (x)))

__kernel void 
default_kernel (__global       uchar* dst, 
                __global const uchar* src, 
                         const int width,
                         const int height)
{
  const int x = get_global_id (0);
  const int y = get_global_id (1);
  const int idx = y * width + x;

  dst[idx] = src[idx];
}

#define RADIX 2
__kernel void 
median_filter (__global       uchar* dst, 
               __global const uchar* src, 
                        const int width,
                        const int height)
{
  const int x = get_global_id (0);
  const int y = get_global_id (1);
  const int idx = y * width + x;
  
  float r = 0;
  float n = 0;
  for (int i = clamp(x - RADIX, 0, width); i < clamp(x + RADIX, 0, width); i++)
  for (int j = clamp(y - RADIX, 0, height); j < clamp(y + RADIX, 0, height); j++)
  {
    r += src[j * width + i];
    n += 1;
  }

  dst[idx] = r / n;
}
