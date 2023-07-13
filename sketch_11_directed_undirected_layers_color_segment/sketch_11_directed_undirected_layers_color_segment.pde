PImage img, gray, sobel, sobelX, sobelY;
float [][]m = new float[256][256];//用來存gray裡面的值
float []Gx = new float[256*256];
float []Gy = new float[256*256];
float []G = new float[256*256];
float sigma=0.5;//可試試不同sigma值 segmentN值越大,sigma值要越小
int segmentN=10;//分段10等分30分
PVector[][][]Layer=new PVector [12][256*256][segmentN];//用來存gray的值
float[][][]LayerX=new float [12][256*256][segmentN];
float[][][]LayerY=new float [12][256*256][segmentN];
float[][][]LayerZ=new float [12][256*256][segmentN];
void setup() {
  size(1024, 1024);
  img=loadImage("baboon.png");
  img.resize(256, 256);
  img.loadPixels();

  gray= createImage(256, 256, RGB);
  gray.loadPixels();
  for (int i=0; i<256*256; i++) {
    gray.pixels[i]=color(red(img.pixels[i]));
    m[i/256][i%256]=red(img.pixels[i]);
  }
  gray.updatePixels();

  sobelX= createImage(256, 256, RGB);
  sobelX.loadPixels();
  sobelY= createImage(256, 256, RGB);
  sobelY.loadPixels();
  sobel= createImage(256, 256, RGB);
  sobel.loadPixels();
  for (int i=0+1; i<256-1; i++) {
    for (int j=0+1; j<256-1; j++) {
      int ii=i*256+j;
      //計算梯度
      Gx[ii]=-m[i-1][j-1]+m[i-1][j+1]
        -m[i][j-1]*2+m[i][j+1]*2
        -m[i+1][j-1]+m[i+1][j+1];
      Gy[ii]=m[i-1][j-1]+m[i-1][j]*2+m[i-1][j+1]
        -m[i+1][j-1]-m[i+1][j]*2-m[i+1][j+1];
      //Gy[ii]=-Gy[ii];
      G[ii]=sqrt(Gx[ii]*Gx[ii]+Gy[ii]*Gy[ii]);
      sobelX.pixels[ii]=color(Gx[ii]);
      sobelY.pixels[ii]=color(Gy[ii]);
      sobel.pixels[ii]=color(G[ii]);
    }
  }
  sobelX.updatePixels();
  sobelY.updatePixels();
  sobel.updatePixels();
  for (int L=0; L<12; L++) {
    for (int ii=0; ii<256*256; ii++) {
      boolean directed=true;
      if (L>=3) directed=false;
      PVector D=Dxyz(ii, directed);
      for (int s=0; s<segmentN; s++) {
        Layer[L][ii][s]=new PVector(randomGaussian()*sigma+D.x,
          randomGaussian()*sigma+D.y,
          randomGaussian()*sigma+D.z).normalize();
        LayerX[L][ii][s]=Layer[L][ii][s].x;
        LayerY[L][ii][s]=Layer[L][ii][s].y;
        LayerZ[L][ii][s]=Layer[L][ii][s].z;
      }
    }
  }
}
//boolean L0, L1, L2, L3=true;
boolean []LL=new boolean[4];//LL[1]LL[2]LL[3]LL[4]....LL[11]
void keyPressed() {
  if (key=='1')LL[0]=true;
  if (key=='2')LL[1]=true;
  if (key=='3')LL[2]=true;
}
void keyReleased() {
  if (key=='1')LL[0]=false;
  if (key=='2')LL[1]=false;
  if (key=='3')LL[2]=false;
}
void draw() {
  float transparent=0.5;
  for(int L=0;L<3;L++){
    if(LL[L]==true) transparent=0.2;
  }
  background(0);
  stroke(255, 128);
  float len=2.0;
  LL[3]=true;
  for (int L=3; L>=0; L--) {
    for (int i=0; i<256; i+=1) {
      for (int j=0; j<256; j+=1) {
        int ii =i*256+j;
        if (mousePressed) {
          line(j*4, i*4, j*4+Gy[ii]/20.0, i*4-Gx[ii]/20.0);
        } else {
          stroke(img.pixels[ii], 255*transparent);//照原始照片加上色彩
          //畫越多層越慢
          if (LL[L]) {
            float x=j*4, y=i*4;
            for (int s=0; s<segmentN; s++) {
              if (LL[L])line(x, y, x+LayerX[L][ii][s]*len, y+LayerY[L][ii][s]*len) ;
              x+=LayerX[L][ii][s]*len;
              y+=LayerY[L][ii][s]*len;
            }
          }
        }
      }
    }
  }
  if (mousePressed)image(gray, 0, 0);
}
PVector Dxyz(int ii, boolean directed) {
  float alpha=1500, beta=1;
  if (directed)return new PVector(alpha*U(), alpha*U(), beta*U()).normalize();//無向
  float GGy=Gx[ii];
  float GGx=-Gy[ii];
  float GG=G[ii];
  return new PVector(GGx*GG+alpha*U(), GGy*GG+alpha*U(), beta*U()).normalize();//有向
  //return new PVector (alpha*U(), alpha*U(), beta*U()).normalize();//無向
}
float U() {
  return random(-1, +1);
}
