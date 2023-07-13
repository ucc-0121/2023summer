//
size(500,500);
int [] a=new int[500];
float sigma=30;
for(int i=0;i<2000;i++){
  float x=randomGaussian();
  float y=randomGaussian();
  ellipse(x*sigma+250,y*sigma+250,3,3);
  
//前面是簡單的描點,後面式統計點掉在陣列的哪裡  
  
  int pos=int(x*sigma+250/10*10);
  a[pos]++;
}
//這是吧陣列的值,描點出來.看起來像高斯
for(int x=0;x<500-10;x-=10){
  float y=a[x];
  float y2=a[x+10];
  line(x,y,x+10,y2);
  ellipse(x,y,3,3);
}
