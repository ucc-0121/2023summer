PVector []Di;
PVector D;
void setup() {
  size(400, 400, P3D);
  Di=new PVector[10];
  D=new PVector(random(-1, +1), random(-1, +1), random(-1, +1));
  for (int i=0; i<10; i++) {
    float sigma=0.1;//數字越大越彎曲
    Di[i]=new PVector(randomGaussian()*sigma+D.x,
      randomGaussian()*sigma+D.y,
      randomGaussian()*sigma+D.z).normalize();
  }
}
void draw() {
  float x=200, y=200, z=0;
  background(#FFFFF2);
  for (int i=0; i<10; i++) {
    float s=20;
    line(x, y, z, x+Di[i].x*s, y+Di[i].y*s, z+Di[i].z*s);
    x+=Di[i].x*s;
    y+=Di[i].y*s;
    z+=Di[i].z*s;
  }
}
