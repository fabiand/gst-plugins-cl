
#define clamp(x, a, b) ((x) < (a) ? (a) : ((x) > (b) ? (b) : (x)))

__kernel void 
default_kernel_image2d (__write_only  image2d_t dst, 
                        __read_only   image2d_t src, 
                        const         sampler_t src_sampler, 
                        const         int       width,
                        const         int       height)
{
  const int x = get_global_id (0);
  const int y = get_global_id (1);

  uint4 val = read_imageui (src, src_sampler, (int2) (x, y));
  write_imageui(dst, (int2)( x, y ), val);
}

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



#define IM_RADIX 3
__kernel void 
im2 (__write_only  image2d_t dst, 
                        __read_only   image2d_t src, 
                        const         sampler_t src_sampler, 
                        const         int       width,
                        const         int       height)
{
  const int x = get_global_id (0);
  const int y = get_global_id (1);


  float4 r = 0.0f;
  int n = 0;
  for (int i = clamp(x - IM_RADIX, 0, width); i < clamp(x + IM_RADIX, 0, width); i++)
  for (int j = clamp(y - IM_RADIX, 0, height); j < clamp(y + IM_RADIX, 0, height); j++)
  {
    uint4 val = read_imageui (src, src_sampler, (int2) (i, j));
    r += convert_float4(val);
    n++;
  }
  r /= n;
  
  uint4 rval = convert_uint4(r);
  write_imageui(dst, (int2)( x, y ), rval);
}

