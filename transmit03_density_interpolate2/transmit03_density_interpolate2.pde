//把算出的平均密度做內插
PVector[] v=new PVector[1000];
float [][] density=new float[20][20];
void setup() {
  size(500, 500, P3D);
  for (int k=0; k<1000; k++) {
    v[k]=new PVector(randomGaussian()*50, randomGaussian()*50);
    int i=int(v[k].x+100)/10, j=int (v[k].y+100)/10;
    if (i<0||j<00||i>=20||j>=20)continue;
    density[i][j]++;
  }
}
void draw() {
  background(0);//黑底白字
  translate(width/2, height/2);
  for (int i=0; i<20; i++) {
    for (int j=0; j<20; j++) {
      float x=i*10-100, y=j*10-100;
      pushMatrix();
      translate(x, y);
      fill(255, 0, 0, density[i][j]*50);
      if (mousePressed)box(10);//按下滑鼠才出現輔助格子10是格子寬度
      popMatrix();
    }
  }
  for (int k=0; k<1000; k++) {
    stroke(255);//白色的頂點
    point(v[k].x, v[k].y, 10);//白色的頂點

    stroke(255, 0, 0, Interpolate(v[k].x, v[k].y)*50);
    point(v[k].x, v[k].y, 10);
    //int i=int(v[k].x+100)/10, j=int (v[k].y+100)/10;//推算ij
    //if(i<0||j<00||i>=20||j>=20)continue;//超過範圍不畫
    //else stroke(255, 0, 0,density[i][j]*50);//模仿剛剛畫格子的fill()56
    //point(v[k].x, v[k].y, 10);//在畫一次紅色的點
  }
}
float Interpolate(float x, float y) {
  for (int i=0; i<20-1; i++) {
    for (int j=0; j<20-1; j++) {
      float x1=i*10-100+5, y1=j*10-100+5;
      float x2=(i+1)*10-100+5, y2=(j+1)*10-100+5;
      if (x1<=x&&x<=x2&&y1<=y&&y<=y2) {
        return bilinear(x, y, x1, y1, x2, y2,i,j);
      }
    }
  }
  return 0;
}
float bilinear(float x, float y, float x1, float y1, float x2, float y2, int i, int j) {
  float alphaX=(x-x1)/(x2-x1), alphaY=(y-y1)/(y2-y1);
  float densityUp=density[i][j]*(1-alphaX)+density[i][j+1]*alphaX;
  float densityDown=density[i+1][j]*(1-alphaX)+density[i+1][j+1]*alphaX;
  float densityCenter=densityUp*(1-alphaY)+densityDown*alphaY;
  return densityCenter;
}
