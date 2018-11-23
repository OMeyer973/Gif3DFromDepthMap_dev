

//renders the gif with the depth-first aproach (optimized as much as i could) : 
//go through the image from background to foreground (no clipping problem for pixel of the same plane because they are moved the same amount) 
//each pixel is moved the amount defined by its weight in the depth map
//pixels have a correction radius in wich they can be cloned to replace pixels belonging to further grounds

//works good, still some artifacts
//optimization : real time for image of about 800x600px at around 30fps

import controlP5.*;
import com.hamoid.*;

//variables to set
float moveAmp = 12; // default 10
float focusPoint = 1; //default = 2; 0 = focus bg
float depthSmoothing = 1.5; //ammount of blur applied to the depthMap, can reduce artifacts but creates clipping

int nbFrames = 6; //default 2; nb of frames beetween initial point & max amplitude (= 1/2 of total number of frames)
int nbFramesMax = 128;
int myFrameRate = 50;
int UIX = 320, UIY = 260;
int sizeX = UIX, sizeY = UIY; //must be the size of the input image

int correctionRadius = 1; //can prevent small artifacts but can be ugly. set to 0-1 or 2 max

//computing variables  
String diffusePath, diffuseName, depthPath;
PImage diffuse, depth;
boolean init = false;
boolean running = false;
int totalFrames = 2 * nbFrames + 1;
int totalFramesMax = 2 * nbFramesMax + 1;
PImage frames[];
int frameId = 0;
int frameDif = nbFrames;
boolean goingRight = true;
boolean rendering = true;
int nbLayers = (int)(moveAmp + focusPoint) + 1;

float greyColor, disp;
int f, i, x, y, newX, xx, maxDifX;
color pixelColor;

//GUI variables
ControlP5 cp5;

//export variables
String exportPath;
String exportFile;
String exportId;
boolean saving = false;
int exportFrameCount = 0, totalExportFrames = 2*totalFrames-2;
VideoExport videoExport;
PGraphics pg;

void settings() {
  
  size(sizeX, sizeY);
}

  
void setup () {
  //initialisation of variables
  background(0);
  noStroke();
  frames = new PImage[totalFramesMax];
  cp5 = new ControlP5(this);
  
  cp5.addButton("selectFiles")
   .setLabel("select picture")
   .setPosition(10,10)
   .setSize(90,20)
   ;
   
   cp5.addButton("resetImages")
   .setLabel("apply parameters")
   .setPosition(120,10)
   .setSize(90,20)
   ;
  
   cp5.addButton("export")
   .setLabel("export image")
   .setPosition(65,35)
   .setSize(90,20)
   ;
    
   cp5.addSlider("moveAmp")
     .setLabel("Amplitude")
     .setPosition(10,60)
     .setSize(200,10)
     .setRange(0,128)
     ;
     
   cp5.addSlider("focusPoint")
     .setLabel("focus Point")
     .setPosition(10,85)
     .setSize(200,10)
     .setRange(0,3)
     ;
     
   cp5.addSlider("depthSmoothing")
     .setLabel("Depth Map Smoothing")
     .setPosition(10,110)
     .setSize(200,10)
     .setRange(0,10)
     ;
     
     
   cp5.addSlider("nbFrames")
     .setLabel("number of frames")
     .setPosition(10,150)
     .setSize(200,10)
     .setRange(0,nbFramesMax)
     ;
     
   cp5.addSlider("myFrameRate")
     .setLabel("Framerate")
     .setPosition(10,175)
     .setSize(200,10)
     .setRange(0,120)
     ;
  
   cp5.addSlider("correctionRadius")
     .setLabel("correction coef")
     .setNumberOfTickMarks(4)
     .setPosition(10,215)
     .setSize(200,10)
     .setRange(0,3)
     ;
  
  //selectFiles();
}

void draw () {
  
  if (running) { 
    if (f < totalFrames) {
      frames[f] = diffuse.copy();
      frameDif = f-nbFrames;
      print("rendering frame : "+ f + "\n");
      if (f != nbFrames) { //condition to not render the frame that is exactly the input image
        renderFrameDepthFirst(frames[f], frameDif);
      }
    f++;
    }
     
    image(frames[frameId],UIX,0);
    backAndForth();
    
    if (f<totalFrames) {
      drawLoadingBar(10,240,200,10,((float)f/(float)totalFrames));
    } else {
      drawLoadingBar(10,240,200,10,0);
    }
  }
  
  //export
  exportRoutine();

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
          pixelColor = diffuse.get(x,y);
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


void selectFiles() {
  running = false;
  println("select a file");
  selectInput("Select an image to use as color (exemples available in the 'data' folder)", "diffuseSelected");
}

void diffuseSelected(File selection) {
  if (selection == null) {
    println("diffuse import got cancelled");
  } else {
    diffusePath = selection.getAbsolutePath();
    diffuseName = selection.getName();
    selectInput("Select an image to use as depth", "depthSelected");
  }
}

void depthSelected(File selection) {
  if (selection == null) {
    println("depth import got cancelled");
  } else {
    depthPath = selection.getAbsolutePath();
    
    resetImages();
  }
}
 void resetImages() {
   running = false;
    diffuse = loadImage(diffusePath);
    depth = loadImage(depthPath); //must have the same size as the diffuse
    if (diffuse.width != depth.width || diffuse.height != depth.height) {
      println("color image and depth image must have the same resolution");
      javax.swing.JOptionPane.showMessageDialog(null,"Please choose color image and depth image\n with the same resolution");
    
    }
    else {
      diffuse.loadPixels();
      depth.filter(GRAY);
      depth.filter(BLUR,depthSmoothing);
      depth.loadPixels();
      sizeX = diffuse.width;
      sizeY = diffuse.height;
      surface.setSize(sizeX+UIX,max(sizeY, UIY));
    
      resetVariables();
    }
 }
 
 void resetVariables() {
    colorMode(RGB, nbLayers);
    totalFrames = 2 * nbFrames + 1;
    frameRate(myFrameRate);  
    f = 0;
    for (i=0; i<totalFrames; i++) {
      frames[i] = diffuse.copy();
    }
    //image(depth,0,0);
    running = true;
 }
 
 void drawLoadingBar(float x, float y, float lwidth, float lheight, float percentage) {
   fill(0);
   rect(x,y,lwidth,lheight);
   fill(nbLayers);
   rect(x,y,percentage*lwidth,lheight);
 }
 
 
void export() {
  if (running) {
  println("exporting");
  saving = true;
  totalExportFrames = 2*totalFrames-2;
  exportFrameCount = 0;
  exportFile = diffuseName.substring(0,diffuseName.length()-4);
  exportId = exportFile + year() + month() + day() + hour() + minute() + second();
  
  pg = createGraphics(2*(sizeX/2), 2*(sizeY/2));
  videoExport = new VideoExport(this, "/export/" + exportId +".mp4", pg);
  //videoExport.forgetFfmpegPath();
  videoExport.setFrameRate(myFrameRate);
  videoExport.setDebugging(false);
  videoExport.startMovie();
  } else {
    javax.swing.JOptionPane.showMessageDialog(null, "please choose a file and/or wait for animation to finish rendering");    
  }
}

void exportRoutine() {
    if (saving && f >= totalFrames && exportFrameCount < totalExportFrames && videoExport.getFfmpegPath() != "ffmpeg_path_unset") {
    //line to save frames as individual pngs
    //frames[frameId].save("/export/" + exportId + "/" + exportId + "_" + String.format("%04d", exportFrameCount) + ".jpg");
    pg.beginDraw();
    pg.image(frames[frameId],0,0);
    pg.endDraw();  
    videoExport.saveFrame();
    exportFrameCount++;
    drawLoadingBar(10,240,200,10,((float)exportFrameCount/(float)totalExportFrames));
    
    //export is over
    if (exportFrameCount >= totalExportFrames) {
      javax.swing.JOptionPane.showMessageDialog(null, "export done to \n" + sketchPath("") +"export");    
      videoExport.endMovie();
      drawLoadingBar(10,240,200,10,0);  
    }
  }
}