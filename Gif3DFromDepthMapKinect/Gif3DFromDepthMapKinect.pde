//renders a wiggling left-right video of live kinect footage with RGB & depth map. 
//it uses the depth-first aproach (optimized as much as i could) : 
//go through the image from background to foreground (no clipping problem for pixel of the same plane because they are moved the same amount) 
//each pixel is moved the amount defined by its weight in the depth map
//pixels have a correction radius in wich they can be cloned to replace pixels belonging to further grounds

//works good, still some artifacts
//optimization : real time for image of about 800x600px at around 30fps

import KinectPV2.*;
KinectPV2 kinect;


//variables to set
float moveAmp = 20; // default 10
float focusPoint = 0.7; //default = 2; 0 = focus bg
float depthSmoothing = 4; //ammount of blur applied to the depthMap, can reduce artifacts but creates clipping

int nbFrames = 2; //default 2; nb of frames beetween initial point & max amplitude (= 1/2 of total number of frames)
int myFrameRate = 60;
int sizeX =  512, sizeY = 424; //must be the size of the input image

int correctionRadius = 1; //can prevent small artifacts but can be ugly. set to 0-1 or 2 max

//computing variables  
PImage diffuse, diffuseSmall, diffuseTmp, depth, printed;
int totalFrames = 2 * nbFrames + 1;

int frameId = 0;
int frameDif = nbFrames;
boolean goingRight = true;
boolean rendering = true;
int nbLayers = (int)(moveAmp + focusPoint) + 1;

float greyColor, disp;
int f, i, x, y, newX, xx, maxDifX;
color pixelColor;

void settings() {
  size(sizeX, sizeY);
}
  
void setup () {
  //initialisation of variables
  kinect = new KinectPV2(this);
  kinect.enableColorImg(true);
  kinect.enableDepthImg(true);  
  kinect.init();
  
  diffuseTmp = new PImage(sizeX,sizeY);
  
  colorMode(RGB, nbLayers);
  frameRate(myFrameRate);
  
  background(0);
}

void draw () {
  diffuse = new PImage(1920,1080);
  diffuse.width = 1920;
  diffuse.height = 1080;
  diffuse = kinect.getColorImage();
  //diffuse.loadPixels();
  depth = kinect.getDepthImage(); //must have the same size as the diffuse
  depth.filter(GRAY);
  depth.filter(BLUR,depthSmoothing);
  depth.filter(INVERT);
  depth.loadPixels();
  
  //1304 * 1080 - 600
  //753.7 * 424 - 242
  diffuseSmall = diffuse.copy();
  diffuseSmall.resize(754, 424);
  diffuseTmp.copy(diffuseSmall,121,0,sizeX,sizeY,0,0,sizeX,sizeY);
  printed = diffuseTmp.copy();
  
  //print("frameDiff " + frameDif + "\n");
  frameDif = nbFrames - frameId;
  renderFrameDepthFirst(printed, frameDif);
  
  image(printed,0,0); 
  
  backAndForth();
}

/*gémère la frame "img" avec un déplacement relatif de "frameDIf"*/
void renderFrameDepthFirst(PImage img, int frameDif) {
  for (i=0; i<=nbLayers; i++) {
    for (y=0; y<sizeY; y++) {
      //print("y : "+ y + "\n");
      for (x=0; x<sizeX; x++) {
        //print("x : "+ x + "\n");
        greyColor = red(depth.pixels[y * sizeX + x]);
        //print("grey : " + (int)greyColor + " i : " + i +"\n");
        if ((int)greyColor == i) { 
          newX = clamp((int)(x + (greyColor / nbLayers - focusPoint) * moveAmp * frameDif / nbFrames),0,sizeX-1);
          pixelColor = diffuseTmp.get(x,y);
          for (xx = clamp(newX-correctionRadius,0,sizeX); xx<clamp(newX+correctionRadius,0,sizeX); xx++) {
            //print("xx : "+ xx + "\n");
            if (greyColor > red(depth.pixels[y * sizeX + xx])) {
              img.pixels[y * sizeX + xx] = pixelColor;
            }
          }
          img.pixels [y * sizeX + newX] = pixelColor;          
        }
      }
    }
  }
}

int clamp(int i, int a, int b){
  return (max(min(b,i),a));
}

void backAndForth(){
  if (goingRight) {
    if (frameId >= totalFrames-1) {
      frameId--;
      goingRight = false;
    }
    else {
      frameId++;
    }
  }
  else {
    if (frameId <= 0) {
      frameId++;
      goingRight = true;
    }
    else {
      frameId--;
    }
  }
}