
/*
 * A sobel filter, original taken from http://code.imagej.net/trac/imagej/browser/trunk/opencl/sobel.cl
 */
__kernel void sobel( __global uchar* output, __global uchar* input, int width, int height)
{
    int x = get_global_id(0);
    int y = get_global_id(1);
    int p[9];
    int offset = y * width + x;
if( x < 1 || y < 1 || x > width - 2 || y > height - 2 )
{
  output[offset] = 0; //TODO implement image edges
}
else
{
    p[0] = input[offset - width - 1] & 0xff;
    p[1] = input[offset - width] & 0xff;
    p[2] = input[offset - width + 1] & 0xff;
    p[3] = input[offset - 1] & 0xff;
    p[4] = input[offset] & 0xff;
    p[5] = input[offset + 1] & 0xff;
    p[6] = input[offset + width - 1] & 0xff;
    p[7] = input[offset + width] & 0xff;
    p[8] = input[offset + width + 1] & 0xff;

    int sum1 = p[0] + 2*p[1] + p[2] - p[6] - 2*p[7] - p[8];
    int sum2 = p[0] + 2*p[3] + p[6] - p[2] - 2*p[5] - p[8];
    float sum3 = sum1*sum1 + sum2*sum2;
   
    int sum = sqrt( sum3 );
    if (sum > 255) sum = 255;
    output[offset] = (char) sum;
 }
};


#define BI_RADIX 48
__kernel void 
bidiff (__global       uchar* dst, 
        __global const uchar* src, 
                 const int width,
                 const int height)
{
  int x = get_global_id (0),
      y = get_global_id (1);
  
  int idx = y * width + x;

  int w = width / 2;
  if (x < w)
  {
    int n = 0;
    float r = 0;
    float sum_a = 0, 
          sum_b = 0;
    
    for (int lx = clamp(x-BI_RADIX, 0, w) ; lx < clamp(x+BI_RADIX, 0, w) ; lx++)
    {
      for (int ly = clamp(y-BI_RADIX, 0, height) ; ly < clamp(y+BI_RADIX, 0, height) ; ly++)
    {
        int lidx = ly * width + lx;
        float lv = convert_float(src[lidx]), 
              rv = convert_float(src[lidx + w]);

        r += lv * rv;
        sum_a += lv * lv;
        sum_b += rv * rv;
        n++;
      }
    }
    r = r / (sqrt(sum_a) * sqrt(sum_b));
    dst[idx] = 0; //convert_uchar(r * 255);
  }
  else
  {
    dst[idx] = src[idx];
//    dst[idx] = abs(src[idx] - src[idx+w]);
  }
}
