import toxi.physics2d.constraints.*;
import toxi.physics.*;
import toxi.physics.constraints.*;
import toxi.physics2d.behaviors.*;
import toxi.physics2d.*;
import toxi.geom.*;

import SimpleOpenNI.*;

//import processing.opengl.*;
import codeanticode.glgraphics.*;
import javax.media.opengl.*;
import java.util.*;

KinectManager kinectManager;
HandTracker handTracker;

GLGraphics renderer;

PFont infoFont;

int depthThreshold = 2000;

PhotoArranger photoArranger;

void setup() {
  size(screenWidth, screenHeight-1, GLConstants.GLGRAPHICS);

  kinectManager = new KinectManager(this);
  handTracker = new HandTracker(this);
 
  background(200,0,0);
  //size(kinect.depthWidth(), kinect.depthHeight());
  
  // Stop tearing
  GLGraphics pgl = (GLGraphics) g; //processing graphics object
  GL gl = pgl.beginGL(); //begin opengl
  gl.setSwapInterval(1); //set vertical sync on
  pgl.endGL(); //end opengl
  
  infoFont = createFont("Courier Bold", 12);
  textFont(infoFont);

  photoArranger = new PhotoArranger(this);
}

void draw(){
  background(0);
  
  kinectManager.update();
  handTracker.update();
  
  /*
  ArrayList<Vec3D> handPositions = new ArrayList<Vec3D>();
  handPositions.add(new Vec3D(kinectManager.handPosition.x*2, kinectManager.handPosition.y*2, 0));
  photoArranger.updateHands(handPositions);
  */
  
  renderer = (GLGraphics)g;
  renderer.beginGL();
    photoArranger.update();
    photoArranger.draw();
  renderer.endGL();
  
  pushMatrix();
  scale(2);
  //stroke(255,0,128);
  kinectManager.draw();
  popMatrix();
  
  handTracker.draw();
  
  //text(frameRate, 20,20);
}

void keyPressed() {  
  if(key == '.') depthThreshold += 20;
  if(key == ',') depthThreshold -= 20;
}

