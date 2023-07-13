//從felt09_directed_undirected_layers_color_segments 加上 grid
PImage img, gray, sobelX, sobelY, sobel;
float[][] m=new float [256][256];//用來存gray的值
float[] Gx=new float [256*256];
float[] Gy=new float [256*256];
float[] G=new float [256*256];
float sigma = 0.5; //sigma值越大，segmentN越大，sigma越小則反之
int segmentN = 10; //10 segments OR 30 segments
PVector[][][]Layer=new PVector[12][256*256][segmentN]; //3層 directed Layer + 9層 undirected Layers
float[][][]LayerX=new float [12][256*256][segmentN];
float[][][]LayerY=new float [12][256*256][segmentN];
float[][][]LayerZ=new float [12][256*256][segmentN]; //30個 segment 可以組合出一根 strand, 每一個pixel是一根strand
float [][][]StrandTrans = new float[12][256*256][segmentN+1]; //strand 的 vertex 有31個
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
  for (int L=0; L<12; L++) { //3層 directed, 9層 undirected
    LL[L]=true;
    for (int ii=0; ii<256*256; ii++) {
      boolean directed = true; //directed
      if (L>3) directed = false; //undirected
      PVector D = Dxyz(ii, directed);
      for (int s=0; s<segmentN; s++) { //30 segments = 1 strand 毛
        Layer[L][ii][s]=new PVector(
          randomGaussian()*sigma+D.x,
          randomGaussian()*sigma+D.y,
          randomGaussian()*sigma+D.z).normalize();
        LayerX[L][ii][s]=Layer[L][ii][s].x;
        LayerY[L][ii][s]=Layer[L][ii][s].y;
        LayerZ[L][ii][s]=Layer[L][ii][s].z;
      }
    }
  }
  updateDensity();
}
int NX=256, NY=256, NZ=32;
float [][][]T = new float[NX][NY][NZ];
float [][][]density = new float[NX][NY][NZ]; //因為論文的i方向是光的方向，現在要用z來代表
//float [][][]StrandTrans = new float[12][256*256][segmentN]; //要用trilinear 算出每個 vertex 的 strand 值
void addDensity(float x, float y, float z) {
  int ix = int(x), iy = int(y), iz = int(z);
  if (ix<0 || ix>=NX || iy<0 || iy>=NY || iz<0 || iz>=NZ) return;
  density[ix][iy][iz]++; //x,y,z的z方向在最右邊，與論文不同
}
void updateDensity() { //假設最簡單的，從正上方光線射入
  float len=2.0;
  for (int L=12-1; L>=0; L--) {
    for (int i=0; i<256; i+=1) {
      for (int j=0; j<256; j+=1) {
        int ii =i*256+j;
        float x=j*(NX/256), y=i*(NY/256), z=L*(NZ/12);
        addDensity(x, y, z);
        for (int s=0; s<segmentN; s++) {
          x+=LayerX[L][ii][s]*len;
          y+=LayerY[L][ii][s]*len;
          z+=LayerZ[L][ii][s]*len;
          addDensity(x, y, z);
        }
      }
    }
  }
  updateTransmittance();
}
float f=1, ds=1;
void updateTransmittance() {
  //根據 felt論文及2005年頭髮的論文 Tijk 的 ijk 不是 xyz。ijk 的i是光的方向，也就是z的方向。
  for (int ix=0; ix<NX; ix++) {
    for (int iy=0; iy<NY; iy++) { //j、k決定平面打光的點
      float prevTrans = 1;
      for (int iz=0; iz<NZ; iz++) { //往z方向打穿，也就是從 imin 一直打到 i 為止
        T[ix][iy][iz] = prevTrans;
        prevTrans *= exp(-density[ix][iy][iz]*f*ds);
      }
    }
  }
  updateStrandTransTrilinear();
}
void updateStrandTransTrilinear() {
  float len=2.0;
  for (int L=12-1; L>=0; L--) {
    for (int i=0; i<256; i+=1) {
      for (int j=0; j<256; j+=1) {
        int ii =i*256+j;
        float x=j*(NX/256), y=i*(NY/256), z=L*(NZ/12);
        StrandTrans[L][ii][0] = Interpolate(x, y, z);
        for (int s=0; s<segmentN; s++) {
          x+=LayerX[L][ii][s]*len;
          y+=LayerY[L][ii][s]*len;
          z+=LayerZ[L][ii][s]*len;
          StrandTrans[L][ii][s+1] = Interpolate(x, y, z);
        }
      }
    }
  }
}
float Interpolate(float x, float y, float z) {
  return 0;
  /*  for (int i=0; i<NX-1; i++) {
   for (int j=0; j<NY-1; j++) {
   for (int k=0; k<NZ-1; k++) { //這裡的i,j,k只是要找到x,y,z對應的虛擬中心格子
   //float x=j*(NX/256), y=i*(NY/256), z=L*(NZ/12);
   float x1 = j*(NX/256)+(NX/256)*0.5, y1 = i*(NY/256)+(NY/256)*0.5, z1 = k+0.5; //
   float x2 = (j+1)*(NX/256)+(NX/256)*0.5, y2 = (i+1)*(NY/256)+(NY/256)*0.5, z2 = k+1+0.5;
   if (x1<=x && x<x2 && y1<=y && y<y2 && z1<=z && z<z2) {
   return trilinear(x, y, z, x1, y1, z1, x2, y2, z2, i, j, k);
   }
   }
   }
   }
   return 0;*/
}
float trilinear(float x, float y, float z, float x1, float y1, float z1, float x2, float y2, float z2, int i, int j, int k) {
  float alphaX = (x-x1)/(x2-x1), alphaY = (y-y1)/(y2-y1), alphaZ = (z-z1)/(z2-z1);
  float []TCenter = new float[2];
  for (int kk=0; kk<2; kk++) {
    float TUp = T[i][j][k+kk]*(1-alphaX) + T[i][j+1][k+kk]*alphaX;
    float TDown = T[i+1][j][k+kk]*(1-alphaX) + T[i+1][j+1][k+kk]*alphaX;
    TCenter[kk] = TUp*(1-alphaY) + TDown*alphaY;
  }
  return TCenter[0]*(1-alphaZ) + TCenter[1]*alphaZ;
}

//boolean L0, L1, L2, L3 = true;
boolean [] LL= new boolean[12]; //LL[0] LL[1]...LL[12]
void keyPressed() {
  if (key=='1') LL[0]=true;
  if (key=='2') LL[1]=true;
  if (key=='3') LL[2]=true;
}
void keyReleased() {
  if (key=='1') LL[0]=false;
  if (key=='2') LL[1]=false;
  if (key=='3') LL[2]=false;
}
void draw() {
  float transparent = 0.5;
  for (int L=0; L<3; L++) {
    if (LL[L] == true) transparent = 0.2;
  }
  background(0);
  stroke(255, 128);
  float len=2.0;
  LL[3] = true;
  for (int L=12-1; L>=0; L--) { //12層全秀
    for (int i=0; i<256; i+=1) {
      for (int j=0; j<256; j+=1) {
        int ii =i*256+j;
        if (mousePressed) { //照著梯度的垂直方向畫出來的線，剛好和線的方向有關
          //line(j*4, i*4, j*4+Gy[ii]/20.0, i*4-Gx[ii]/20.0);
        } else {
          stroke(img.pixels[ii], 255*transparent);
          if (LL[L]) {
            beginShape(LINES);
            float x=j*4, y=i*4;
            for (int s=0; s<segmentN; s++) { //照原始照片，加上色彩
              //畫越多層越慢，預設先畫Undirected Layers
              myStroke(img.pixels[ii], StrandTrans[L][ii][s]*1, 255*transparent);
              vertex(x, y);
              myStroke(img.pixels[ii], StrandTrans[L][ii][s]*1, 255*transparent);
              vertex(x+LayerX[L][ii][s]*len, y+LayerY[L][ii][s]*len);
              //line(x, y, x+LayerX[L][ii][s]*len, y+LayerY[L][ii][s]*len) ;
              x+=LayerX[L][ii][s]*len;
              y+=LayerY[L][ii][s]*len;
            }
            endShape();
          }
        }
      }
    }
  }
  if (mousePressed)image(gray, 0, 0); //按 mouse時，秀出gray 的圖，方便比較
}
void myStroke(color c, float trans, float a) {
  trans=0.8+trans;
  stroke(red(c)*trans, green(c)*trans, blue(c)*trans,a);
}
PVector Dxyz(int ii, boolean directed) {
  float alpha=1500, beta=1; //要調alpha 的值
  if (directed) return new PVector (alpha*U(), alpha*U(), beta*U()).normalize(); //Undirected Layer
  float GGy=Gx[ii]; //因為要垂直轉90度，所以x,y交換
  float GGx=-Gy[ii]; //因為要垂直轉90度，所以x,y交換
  float GG=G[ii]/1.0;
  return new PVector(GGx*GG+alpha*U(), GGy*GG+alpha*U(), beta*U()).normalize(); //Directed Layer
  //return new PVector (alpha*U(), alpha*U(), beta*U()).normalize();
}
float U() {
  return random(-1, +1);
}
