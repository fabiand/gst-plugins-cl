

float conv2
  (__global       uchar* dst, 
   __global const uchar* src, 
            const int2 rangex,
            const int2 rangey)
{
  float r = 0;
  
  for (int y = rangex.x ; x < rangex.y ; y++)
  for (int x = rangex.x ; x < rangex.y ; x++)
  {
    
  }
  
  return r;
}


__kernel void bidiff 
  (__global       uchar* dst, 
   __global const uchar* src,1 
            const int width,
            const int height)
{
  int2 pos = (int2) ( get_global_id (0), get_global_id (1) );
  
  
}
