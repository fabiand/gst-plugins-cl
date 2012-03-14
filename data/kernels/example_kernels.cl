
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


__kernel void 
imrotate (__write_only  image2d_t dst, 
          __read_only   image2d_t src, 
          const         sampler_t src_sampler, 
          const         int       width,
          const         int       height)
{
  const int x = get_global_id (0);
  const int y = get_global_id (1);
  int x2 = 0, y2 = 0;
  float a = -0.4;
  
  float fx = x, 
        fy = y;
  
  x2 = fx * cos(a) + fy * sin(a);
  y2 = -fx * sin(a) + fy * cos(a);
  
  uint4 val = read_imageui (src, src_sampler, (int2) (x2, y2));
  write_imageui(dst, (int2)( x, y ), val);
}



inline int xy2idx (int x, int y, int w)
{
  return  y * w + x;
}

inline int2 idx2xy (int idx, int w)
{
  int2 pos = (int2) (0);
  pos.x = idx % w;
  pos.y = (idx - (pos.x)) / w;
  return pos;
}

float ndp2
  (__global const uchar* src,
            const int2   posFeature,
            const int2   posCandidate,
            const int2   featureSize,
            const int2   size)
{
  float r = 0,
        lenL = 0,
        lenR = 0;
  int step = 2;
  
  float valL, valR;
  for (int dy = -featureSize.y ; dy < featureSize.y ; dy += 2)
  for (int dx = -featureSize.x ; dx < featureSize.x ; dx += 2)
  {
    valL = src[xy2idx(clamp(posFeature.x + dx,   0,          size.x), 
                      clamp(posFeature.y + dy,   0,          size.y/2    ), size.x)];
    valR = src[xy2idx(clamp(posCandidate.x + dx, 0, size.x    ), 
                      clamp(posCandidate.y + dy, size.y/2,          size.y    ), size.x)];
    r += valL * valR;
    lenL += valL * valL;
    lenR += valR * valR;
  }
  
  r /= sqrt(lenL) * sqrt(lenR);
  
  return r;
}


float ndp2_dist
  (__global const uchar* src,
            const int2   pos,
            const int2   ranges,
            const int2   ndp2Dim,
            const int2   size)
{
  float match = 0,
        best_match = 0,
        dist_of_best = -1;
  int2 pos_of_best = (int2) (0);
  int step = 30;
  
  for (int dy = -ranges.y / 2 ; dy < ranges.y / 2 ; dy += step)
  for (int dx = -ranges.x / 2 ; dx < ranges.x / 2 ; dx += step)
  {
    int2 posCandidate = (int2) (0);
    posCandidate.x = clamp(pos.x + dx, 0, size.x);
    posCandidate.y = clamp(pos.y + dy + size.y / 2, size.y / 2, size.y);
    
    match = ndp2 (src, pos, posCandidate, ndp2Dim, size);
    
    if (match > best_match)
    {
      best_match = match;
      dist_of_best = sqrt(convert_float(dx * dx + dy * dy));
      pos_of_best = posCandidate;
    }
  } 
  
//  dist_of_best /= sqrt(pow(convert_float(pos.x - pos_of_best.x), 2) * pow(convert_float(pos.y - pos_of_best.y), 2));
  dist_of_best /= sqrt(pow((float)(ranges.x), 2.0f) * pow((float)(ranges.y), 2.0f));
  dist_of_best = pow(dist_of_best, 1.0f/20.0f);
  
  return dist_of_best;
}


__kernel void 
bidiff (__global       uchar* dst, 
        __global const uchar* src, 
                 const int width,
                 const int height)
{
  int x = get_global_id (0), 
      y = get_global_id (1);
  int w = height / 2;
  int idx = xy2idx (x,y,width);
  int2 pos = (int2) (x,y);
  int2 size = (int2) (width, height);
  
  int d = 30, 
      rh = 400, rv = 1.1*d;
  int2 ndp2Dim = (int2) (d, d);
  
  int2 ranges = (int2) (rh, rv);
  
  if (y < w)
  {
    float r = 0;

    r = ndp2_dist (src, pos, ranges, ndp2Dim, size);
    r *= 200;
    r += 50;
    
    //printf("idx %d r %.4f\n", idx, r);
    
    dst[idx] = r;
  }
  else
  {
    dst[idx] = src[idx];
//    dst[idx] = abs(src[idx] - src[idx+w]);
  }
}


// http://damien.douxchamps.net/ieee1394/libdc1394/v2.x/api/conversions/
// video/x-raw-yuv,pixel-aspect-ratio=1/1,format=\(fourcc\)YUY2
__kernel void deinterlace_stereo
 (__global       uchar2* dst, 
  __global const uchar2* src, 
           const int width,
           const int height)
{
  const int2 pos = (int2) (get_global_id (0), get_global_id (1));
  const int idx = xy2idx (pos.x, pos.y, width);

  uchar2 val = src[idx];
  
  {
    dst[idx/2] = val.lo;
    dst[(width*height/2) + (idx)/2] = val.hi;
  }
}
