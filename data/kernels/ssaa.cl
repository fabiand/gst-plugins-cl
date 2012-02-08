/*
 * Provides an OpenCL kernel implementing the SSAA
 * Derived from http://www.gamestart3d.com/blog/ssaa-antialiasing
 */

inline float lumRGB(uint3 v)
{
  return dot(convert_float3(v), (float3)(0.212, 0.716, 0.072));
}

__kernel void 
default_kernel (__write_only  image2d_t dst, 
                __read_only   image2d_t src, 
                const         sampler_t src_sampler, 
                const         int       width,
                const         int       height)
{
  const float inverse_buffer_size = 1;
  const int2 pos = (int2) ( get_global_id (0), get_global_id (1) );
  const float2 UV = convert_float2(pos) * inverse_buffer_size;
 
  float w = 1.75;

  float t = lumRGB(read_imageui (src, src_sampler, UV + (float2)(0.0, -1.0) * w * inverse_buffer_size).xyz),
        l = lumRGB(read_imageui (src, src_sampler, UV + (float2)(-1.0, 0.0) * w * inverse_buffer_size).xyz),
        r = lumRGB(read_imageui (src, src_sampler, UV + (float2)(1.0, 0.0) * w * inverse_buffer_size).xyz),
        b = lumRGB(read_imageui (src, src_sampler, UV + (float2)(0.0, 1.0) * w * inverse_buffer_size).xyz);

  float2 n = (float2)(-(t - b), r - l);
  float nl = length(n);

  float4 fcolor;
  if (nl < (1.0 / 16.0))
  {
    fcolor = convert_float4(read_imageui (src, src_sampler, UV));
  }
  else
  {
    n *= inverse_buffer_size / nl;
     
    float4 o = convert_float4(read_imageui (src, src_sampler, UV)),
           t0 = convert_float4(read_imageui (src, src_sampler, UV + n * 0.5)) * 0.9,
           t1 = convert_float4(read_imageui (src, src_sampler, UV - n * 0.5)) * 0.9,
           t2 = convert_float4(read_imageui (src, src_sampler, UV + n)) * 0.75,
           t3 = convert_float4(read_imageui (src, src_sampler, UV - n)) * 0.75;
     
    fcolor = (o + t0 + t1 + t2 + t3) / 4.3;
  }
  
  write_imageui(dst, pos, convert_uint4(fcolor));
}

