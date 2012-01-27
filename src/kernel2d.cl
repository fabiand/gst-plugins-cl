
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

#define MEDIAN_RADIX 6
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
  for (int i = clamp(x - MEDIAN_RADIX, 0, width); i < clamp(x + MEDIAN_RADIX, 0, width); i++)
  for (int j = clamp(y - MEDIAN_RADIX, 0, height); j < clamp(y + MEDIAN_RADIX, 0, height); j++)
  {
    r += src[j * width + i];
    n += 1;
  }

  dst[idx] = r / n;
}

#define MAX_RADIX 2
__kernel void 
max_filter (__global       uchar* dst, 
               __global const uchar* src, 
                        const int width,
                        const int height)
{
  const int x = get_global_id (0);
  const int y = get_global_id (1);
  const int idx = y * width + x;
  
  float r = 0;
  for (int i = clamp(x - MAX_RADIX, 0, width); i < clamp(x + MAX_RADIX, 0, width); i++)
  for (int j = clamp(y - MAX_RADIX, 0, height); j < clamp(y + MAX_RADIX, 0, height); j++)
  {
    r = max( (float)r, (float)src[j * width + i]);
  }

  dst[idx] = r;
}

#define NUM_BINS 16
__kernel void 
posterize (__global       uchar* dst, 
           __global const uchar* src, 
                    const int width,
                    const int height)
{
  const int x = get_global_id (0);
  const int y = get_global_id (1);
  const int idx = y * width + x;
  
  float v = src[y * width + x];
  v = v / 255 * NUM_BINS;
  v = (uint) v * 255 / NUM_BINS;
  dst[idx] = v;
}

