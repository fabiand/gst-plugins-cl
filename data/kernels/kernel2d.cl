
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

#define MEAN_RADIX 2
__kernel void 
mean_filter (__global       uchar* dst, 
               __global const uchar* src, 
                        const int width,
                        const int height)
{
  const int x = get_global_id (0);
  const int y = get_global_id (1);
  const int idx = y * width + x;
  
  float r = 0;
  float n = 0;
  for (int i = clamp(x - MEAN_RADIX, 0, width); i < clamp(x + MEAN_RADIX, 0, width); i++)
  for (int j = clamp(y - MEAN_RADIX, 0, height); j < clamp(y + MEAN_RADIX, 0, height); j++)
  {
    r += src[j * width + i];
    n += 1;
  }

  dst[idx] = r / n;
}

#define MEDIAN_RADIX 4
__kernel void 
median_filter (__global       uchar* dst, 
               __global const uchar* src, 
                        const int width,
                        const int height)
{
  const int x = get_global_id (0);
  const int y = get_global_id (1);
  const int idx = y * width + x;
  
  float rx = 0, ri = 255;
  for (int i = clamp(x - MEDIAN_RADIX, 0, width); i < clamp(x + MEDIAN_RADIX, 0, width); i++)
  for (int j = clamp(y - MEDIAN_RADIX, 0, height); j < clamp(y + MEDIAN_RADIX, 0, height); j++)
  {
    float v = (float) src[j * width + i];
    rx = max ((float) rx, v);
    ri = min ((float) ri, v);
  }

  dst[idx] = (rx + ri) / 2;
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

#define NUM_BINS 6
__kernel void 
posterize (__write_only  image2d_t dst, 
     __read_only   image2d_t src, 
     const         sampler_t src_sampler, 
     const         int       width,
     const         int       height)
{
  const int x = get_global_id (0);
  const int y = get_global_id (1);
  
  float4 v = convert_float4(read_imageui (src, src_sampler, (int2) (x,y)));
  v *= NUM_BINS;
  v /= 255;
  v = round(v);
  v *= 255 / NUM_BINS;
  write_imageui(dst, (int2)( x, y ), convert_uint4(v));
}


