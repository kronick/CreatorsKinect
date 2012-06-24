import processing.core.*; 
import processing.xml.*; 

import toxi.physics2d.constraints.*; 
import toxi.physics.*; 
import toxi.physics.constraints.*; 
import toxi.physics2d.behaviors.*; 
import toxi.physics2d.*; 
import toxi.geom.*; 
import SimpleOpenNI.*; 
import codeanticode.glgraphics.*; 
import javax.media.opengl.*; 
import java.util.*; 
import toxi.math.noise.*; 
import SimpleOpenNI.*; 
import org.json.*; 
import java.util.*; 

import java.applet.*; 
import java.awt.Dimension; 
import java.awt.Frame; 
import java.awt.event.MouseEvent; 
import java.awt.event.KeyEvent; 
import java.awt.event.FocusEvent; 
import java.awt.Image; 
import java.io.*; 
import java.net.*; 
import java.text.*; 
import java.util.*; 
import java.util.zip.*; 
import java.util.regex.*; 

public class CreatorsKinect extends PApplet {














KinectManager kinectManager;
HandTracker handTracker;

GLGraphics renderer;
static GLTexture dropshadowTexture;
static GLTexture defaultTexture;

PImage[] staticImages;
int staticImageIndex = 0;

PFont infoFont;
GLTexture creatorsTag;
int hashtagStep = 0;
static final int HASHTAG_FADE_TIME = 960;
static final int HASHTAG_SIZE = 10;
int hashtagPosition = 0;
boolean showHashtag = true;

PhotoArranger photoArranger;

boolean shuttingDown = false;
int shutdownTimer = 0;
static final int SHUTDOWN_TIME = 60;

String watchdogFile = "/tmp/watching-the-clock";

public void setup() {
  size(screenWidth, screenHeight-1, GLConstants.GLGRAPHICS);
 
  kinectManager = new KinectManager(this);
  handTracker = new HandTracker(this);
 
  generateStatic();
 
  background(200,0,0);
  //size(kinect.depthWidth(), kinect.depthHeight());
  
  infoFont = createFont("Courier Bold", 12);
  textFont(infoFont);
  
  creatorsTag = new GLTexture(this, "creators-tag.png");

  photoArranger = new PhotoArranger(this);
  
  frameRate(30);

  // Stop tearing
  GLGraphics pgl = (GLGraphics) g; //processing graphics object
  GL gl = pgl.beginGL(); //begin opengl
  gl.setSwapInterval(1); //set vertical sync on
  pgl.endGL(); //end opengl
}

public void draw(){
  //println(frameRate);
  keepAlive();
  background(0);
  if(frameCount % 3 == 0) staticImageIndex = (int)random(0,staticImages.length);
  image(staticImages[staticImageIndex], 0,0);

  if(second() < 30)          photoArranger.setMode(2);
  else if(minute() % 2 == 0) photoArranger.setMode(3);
  else                       photoArranger.setMode(4);
  
  kinectManager.update();
  handTracker.update();
  
  /*
  ArrayList<Vec3D> handPositions = new ArrayList<Vec3D>();
  handPositions.add(new Vec3D(kinectManager.handPosition.x*2, kinectManager.handPosition.y*2, 0));
  photoArranger.updateHands(handPositions);
  */
 
  
  //pushMatrix();
  //scale(2);
  //stroke(255,0,128);
  kinectManager.draw();
  //popMatrix();
  
  handTracker.draw();
  
   renderer = (GLGraphics)g;
  renderer.beginGL();
    photoArranger.update();
    photoArranger.draw();
  renderer.endGL(); 
  
  if(showHashtag) drawHashtag();
  
  
  if(shuttingDown) {
    fill(0,0,0, shutdownTimer / (float)SHUTDOWN_TIME * 255);
    rect(0,0,width,height);
    shutdownTimer++;
    if(shutdownTimer > SHUTDOWN_TIME) safeShutdown();  
  }
  //text(frameRate, 20,20);
  
}

public void keyPressed() {  
  if(key == ']') photoArranger.setGridDimensions(photoArranger.gridRows + 1, photoArranger.gridCols);
  if(key == '[') photoArranger.setGridDimensions(photoArranger.gridRows - 1, photoArranger.gridCols);
  if(key == '\'') photoArranger.setGridDimensions(photoArranger.gridRows, photoArranger.gridCols + 1);
  if(key == ';') photoArranger.setGridDimensions(photoArranger.gridRows, photoArranger.gridCols - 1);
  
  if(key == '.') kinectManager.depthThreshold += 20;
  if(key == ',') kinectManager.depthThreshold -= 20;
  if(key == 'q') shuttingDown = true;
  
  switch(key) {
    case '1':
      photoArranger.setMode(1);
      break;
    case '2':
      photoArranger.setMode(2);
      break;
    case '3':
      photoArranger.setMode(3);
      break;
    case '4':
      photoArranger.setMode(4);
      break;
    case '5':
      photoArranger.setMode(5);
      break;
    case 'r':
      photoArranger.entranceStack.push(photoArranger.randomPhoto());
      break;
    case 'f':
      ArrayList<Photo> photosCopy = (ArrayList<Photo>)photoArranger.photos.clone();
      Collections.shuffle(photosCopy);
      for(int i=0; i<60; i++) {
        photosCopy.get(i).flipSoon = true;  
        photosCopy.get(i).bounceSoon = true;
      }
      break;
  }
}

public void generateStatic() {
  staticImages = new PImage[10];
  int gray = 0;
  for(int i=0; i<staticImages.length; i++) {
    staticImages[i] = createImage(width, height, RGB);
    staticImages[i].loadPixels();
    for(int p=0; p<staticImages[i].pixels.length; p++) {
      gray = (int)random(0,100);
      staticImages[i].pixels[p] = color(gray, gray, gray);
    }
    staticImages[i].updatePixels();
  }  
}

public void drawHashtag() {
  hashtagStep++;
  if(hashtagStep > HASHTAG_FADE_TIME) {
    hashtagStep = 0;
    hashtagPosition = (int)random(0,4); 
  }
  
  if(hashtagStep < HASHTAG_FADE_TIME) {
    //float alpha = (sin(frameCount/50.)+2)*60;
    float alpha = 0;
    if(hashtagStep < 360)
      alpha = tweenEaseInOut(hashtagStep, 360, 0, 240);
    else if(hashtagStep < HASHTAG_FADE_TIME-360)  
      alpha = 240;
    else
      alpha = tweenEaseInOut(HASHTAG_FADE_TIME-hashtagStep, 360, 0, 240);
    
    float hashtagOffset = HASHTAG_SIZE/200.f * 150;
    
    pushMatrix();
    switch(hashtagPosition) {
      case 0:
        translate(hashtagOffset, height);
        rotate(radians(-90));
        translate(-30,-30);
        break;
      case 1:
        translate(width-creatorsTag.height, height);
        rotate(radians(-90));      
        break;
      case 2:
        translate(0,hashtagOffset);
        translate(-30,-30);
        break;
      case 3:
      default:
        translate(width - creatorsTag.width, height - creatorsTag.height);
        break;
    }
    colorMode(RGB);
    tint(alpha,alpha,alpha, alpha);
    //image(creatorsTag,0,0);
    creatorsTag.render();
    tint(1,1,1,1);
    popMatrix();
  }
}

public void keepAlive() {
  if(frameCount % 10 == 0) {
    String[] out = {"Alive", str((int)(System.currentTimeMillis() / 100L))}; 
    saveStrings(watchdogFile, out);
  }
}

public void safeShutdown() {
  String[] out = {"Shutdown", str((int)(System.currentTimeMillis() / 100L))};
  saveStrings(watchdogFile, out);
  exit();
}
class AgingParticle extends VerletParticle2D {
  int age;
  int lifeSpan;
  int sides;
  int fillColor;
  private boolean dead = false;

  public AgingParticle(float startX, float startY, int lifeSpan) {
    super(startX, startY);
    this.lifeSpan = lifeSpan;
    this.age = 0;
    float r = random(0,1);
    //this.sides = r < 0.33 ? 3 : (r < 0.66 ? 6 : 15);
    this.sides = 5;
    this.sides = (int)random(3,6);
    colorMode(HSB);
    this.fillColor = color(random(0,255), 255,255, 80);
  }  
  
  public void update() {
    dead = age++ > lifeSpan;
    super.update();
  }
  
  public boolean isDead() {
    return dead;
  }
  
  
}


class HandTracker {
  ArrayList<Vec2D> oldHandPositions;
  VerletPhysics2D physics;
  ArrayList<AgingParticle> particles;
  PerlinNoise noise;
  
  CreatorsKinect applet;
  
  int particleAgeLimit = 10;
  
  public HandTracker(CreatorsKinect applet) {
    this.applet = applet;
   
    physics = new VerletPhysics2D();
    physics.setDrag(0.1f);
    //physics.setWorldBounds(new Rect(0,0, width, height)); 
    physics.setNumIterations(1);

    noise = new PerlinNoise();

    particles = new ArrayList<AgingParticle>();    
    oldHandPositions = new ArrayList<Vec2D>();
  }
  
  public void updateHands(ArrayList<Vec3D> handPositions) {
    applet.photoArranger.updateHands(handPositions);
    
    for(int i=0; i<handPositions.size(); i++) {
      Vec2D velocity = new Vec2D(0,0);
      if(i < oldHandPositions.size()) {
        Vec2D a = oldHandPositions.get(i);
        Vec2D b = new Vec2D(handPositions.get(i).x, handPositions.get(i).y);  
        velocity = b.sub(a).scale(0.25f);
      }
      
      AgingParticle _p = new AgingParticle(handPositions.get(i).x + random(-5,5), handPositions.get(i).y + random(-5,5), (int)random(30,100));
      if(random(0,40) < 1) {
        particles.add(_p);  
        physics.addParticle(_p);
      }
      //_p.addVelocity(velocity);
      //float m = velocity.magnitude() + 0.1;
      //_p.addVelocity(new Vec2D(random(-m,m), random(-m,m)));
      //println("Adding particle velocity: ");
    }
    
    oldHandPositions.clear();
    for(int i=0; i<handPositions.size(); i++) {
      oldHandPositions.add(new Vec2D(handPositions.get(i).x, handPositions.get(i).y));        
    }
  }
  
  public void update() {
    physics.update();
    
    ArrayList<AgingParticle> survivors = new ArrayList<AgingParticle>();
    for(int i=0; i<particles.size(); i++) {
      if(!particles.get(i).isDead()) {
        survivors.add(particles.get(i));
      }
    }
    
    particles = survivors;
    physics.clear();
    AgingParticle _p;
    for(int i=0; i<particles.size(); i++) {
      _p = particles.get(i);
      float noiseAngle = noise.noise(_p.x * 0.05f, _p.y * 0.05f, millis()/100) * 15;
      _p.addVelocity(new Vec2D(0.25f*cos(noiseAngle), 0.25f*sin(noiseAngle)));
      physics.addParticle(_p);
    }
  }
  
  public void draw() {
    //noStroke();
    //fill(255);
    noFill();
    colorMode(HSB);
    strokeWeight(1);
    stroke(255);
    AgingParticle _p;
    for(int i=0; i<particles.size(); i++) {
      _p = particles.get(i);
      float pSize = (_p.lifeSpan - _p.age) / (float)_p.lifeSpan * 10;
      stroke(0,0,255, pSize / 10.f * 255);
      beginShape();
        int sides = _p.sides;
        for(int s=0; s<sides; s++) {
          vertex(_p.x + pSize*cos(_p.age/10.f + s/(float)sides*TWO_PI), _p.y + pSize*sin(_p.age/10.f + s/(float)sides*TWO_PI));
        }
      endShape(CLOSE);
      //ellipse(particles.get(i).x, particles.get(i).y, pSize, pSize);
    }
  }

  
}


public class KinectManager {
  SimpleOpenNI kinect;
  
  // NITE
  XnVSessionManager sessionManager;
  XnVFlowRouter     flowRouter;
  PointDrawer       pointDrawer;
  
  CreatorsKinect applet;
  boolean simulate = true;
  
  ArrayList<ScanLine> scanLines;
  PVector handPosition, oldHandPosition;

  float scaleFactor = 1;
  
  PImage depthMap;
  int depthThreshold = 3600;
  
  public KinectManager(CreatorsKinect applet) {
    this.applet = applet;
    kinect = new SimpleOpenNI(applet);
    
    
    handPosition = new PVector();
    oldHandPosition = handPosition.get();

    scanLines = new ArrayList<ScanLine>(); 
    
    // Enable depthMap generation 
    if(!kinect.enableDepth()) {
      println("Can't open DepthMap. Is the camera connected?");
      //exit();
      //return;
      simulate = true;
      scaleFactor = 1;
    }
    else {
      kinect.setMirror(true);
      
      // enable the hands + gesture
      kinect.enableGesture();
      kinect.enableHands();
     
      // setup NITE 
      sessionManager = kinect.createSessionManager("Click,Wave", "RaiseHand");
      
      colorMode(RGB);
      pointDrawer = new PointDrawer(this);
      flowRouter = new XnVFlowRouter();
      flowRouter.SetActive(pointDrawer);
      sessionManager.AddListener(flowRouter);

      kinect.update();
      scaleFactor = width / kinect.depthImage().width;
    }    
  }
  
  public void update() {
    if(frameCount % 2 == 0) return;
    if(!simulate) {
      // update the cam
      kinect.update();
      
      kinect.update(sessionManager);
      
      // draw depthImageMap
      depthMap = kinect.depthImage();
      int pos;
      int lineStart, lineEnd, lineLength, gapLength;
      int lastDepth = 0;
      int DEPTH_DISCONTINUITY_THRESHOLD = 20;
      float avgDepth = 0;
      lineStart = lineEnd = -1;
      lineLength = gapLength = 0;
      
      int gapLimit = 5;
      int scanSpacing = 6;
      
      ArrayList<Vec3D> activeHands = new ArrayList<Vec3D>();
      
      //depthMap.loadPixels();
      for(int y=0; y<depthMap.height; y+=scanSpacing) {
        for(int x=0; x<depthMap.width; x++) {
          pos = y*depthMap.width + x;
          
          boolean endLine = false;
          int thisDepth = kinect.depthMap()[pos];
          if(x < depthMap.width-1 && (thisDepth < depthThreshold && thisDepth > 0)) {
            if(abs(thisDepth - lastDepth) > DEPTH_DISCONTINUITY_THRESHOLD) {
              endLine = true;
            }
            else {
              if(lineStart < 0) lineStart = x;
              lineEnd = x;
              lineLength++;
              lastDepth = kinect.depthMap()[pos];
              avgDepth += (depthThreshold - kinect.depthMap()[pos]) / (float)depthThreshold;
            }
            
            lastDepth = thisDepth;
            //depthMap.pixels[pos] = color(0,128,255);
          }
          else if(lineStart > -1) {
            // A line has been started
            if(gapLength++ > gapLimit || x == depthMap.width-1) {
              //scanLines.add(new ScanLine(lineStart, y, lineEnd,y, avgDepth/lineLength));
              endLine = true;
            }
          }
          
          if(endLine) {
            if(lineStart > -1) {
              Vec2D endpointA = scaleToScreen(new Vec2D(lineStart, y));
              Vec2D endpointB = scaleToScreen(new Vec2D(lineEnd,   y));
              
              ScanLine s = new ScanLine(endpointA, endpointB, scanSpacing);
              
              activeHands.add(new Vec3D(endpointA.x, endpointA.y, 1600));
              activeHands.add(new Vec3D(endpointB.x, endpointB.y, 1600));
              colorMode(HSB);
              s.lineColor = color(0+(avgDepth/(float)lineLength) * 255,255, 255);
              scanLines.add(s);
            }
            lineStart = -1;
            gapLength = 0;
            lineLength = 0;
            avgDepth = 0;
          }
        }
        lineStart = -1;
        gapLength = 0;
        lineLength = 0;
        avgDepth = 0;
      }    
      
      applet.handTracker.updateHands(activeHands);
    }
    else {
      ArrayList<Vec3D> activeHands = new ArrayList<Vec3D>();
      activeHands.add(new Vec3D(mouseX, mouseY, 1000));
      applet.handTracker.updateHands(activeHands);
    }
  }
  
  public void draw() {
    ArrayList<ScanLine> keeperLines = new ArrayList<ScanLine>();
    for(int i=0; i<scanLines.size(); i++) {
      scanLines.get(i).update();
      if(scanLines.get(i).age < ScanLine.AGE_LIMIT)
        keeperLines.add(scanLines.get(i));
    }
    scanLines = keeperLines;
    
    for(int i=0; i<scanLines.size(); i++) {
      scanLines.get(i).draw();
    }    
    
    if(!simulate) {
      //pointDrawer.update();
      //pointDrawer.draw();
    }
  }
  
  
  public int getDepth(Vec2D p) {
    return getDepth(p.x, p.y,false);  
  }
  public int getDepth(float x, float y) {
    return getDepth(x,y, false);
  }
  public int getDepth(float x, float y, boolean noThreshold) {
    if(simulate || kinect.depthMap() == null) return 0;
    
    int row = (int)(y/scaleFactor);
    int col = (int)(x/scaleFactor);
    int idx = row*depthMap.width + col;
    if(idx >= 0 && idx < kinect.depthMap().length) {
      int depth = kinect.depthMap()[row*depthMap.width+col];
      if(noThreshold || (depth < depthThreshold && depth > 0))
        return depth;
      else return 0;
    }
    else return 0;
  }
  
  public int getGaussianDepth(float x, float y, int size, int step) {
    if(kinect.depthMap() == null) return 0;
    int centerRow = (int)(y/scaleFactor);  
    int centerCol = (int)(x/scaleFactor);
    int sum = 0;
    int count = 0;

    for(int a=-size; a<=size; a++) {
      for(int b=-size; b<=size; b++) {
        int row = centerRow + a*step;
        int col = centerCol + b*step;
        int idx = row*depthMap.width + col;
        if(idx >= 0 && idx < kinect.depthMap().length ) {
          int depth = kinect.depthMap()[idx];
          //if(depth < depthThreshold && depth > 0) {
            sum += depth * (int)((size - abs(b))/(float)size + (size - abs(a))/(float)size);
            count++;
          //}
        }
      }
    }
    
    if(count == 0) return 0;
    else return sum/count;
  }
  
  public float scaleToScreen(float x) {
    return x * scaleFactor;
  }  
  public float scaleToScreen(int x) {
    return x * scaleFactor;
  }
  public PVector scaleToScreen(PVector p) {
    return new PVector(scaleToScreen(p.x), scaleToScreen(p.y));
  }
  public Vec2D scaleToScreen(Vec2D p) {
    return new Vec2D(scaleToScreen(p.x), scaleToScreen(p.y));
  }
  public Vec3D scaleToScreen(Vec3D p) {
    return new Vec3D(scaleToScreen(p.x), scaleToScreen(p.y), p.z);
  }  
}

/////////////////////////////////////////////////////////////////////////////////////////////////////
// session callbacks

public void onStartSession(PVector pos)
{
  println("onStartSession: " + pos);
}

public void onEndSession()
{
  println("onEndSession: ");
}

public void onFocusSession(String strFocus,PVector pos,float progress)
{
  println("onFocusSession: focus=" + strFocus + ",pos=" + pos + ",progress=" + progress);
}



/////////////////////////////////////////////////////////////////////////////////////////////////////
// PointDrawer keeps track of the handpoints

class PointDrawer extends XnVPointControl {
  
  KinectManager parent;
  HashMap    _pointLists;
  int        _maxPoints;
  int[]    _colorList = { color(255,0,128),color(0,128,255),color(0,0,255),color(255,255,0)};
  
  public PointDrawer(KinectManager _parent)
  {
    this.parent = _parent;
    _maxPoints = 30;
    _pointLists = new HashMap();
  }
	
  public void OnPointCreate(XnVHandPointContext cxt)
  {
    // create a new list
    addPoint(cxt.getNID(),new PVector(cxt.getPtPosition().getX(),cxt.getPtPosition().getY(),cxt.getPtPosition().getZ()));
    
    println("OnPointCreate, handId: " + cxt.getNID());
  }
  
  public void OnPointUpdate(XnVHandPointContext cxt)
  {
    println("OnPointUpdate " + cxt.getPtPosition());   
    addPoint(cxt.getNID(),new PVector(cxt.getPtPosition().getX(),cxt.getPtPosition().getY(),cxt.getPtPosition().getZ()));
    
    parent.oldHandPosition = parent.handPosition.get();
    PVector newPosition = new PVector(cxt.getPtPosition().getX(),cxt.getPtPosition().getY(),cxt.getPtPosition().getZ());
    parent.kinect.convertRealWorldToProjective(newPosition,parent.handPosition);    
  }
  
  public void OnPointDestroy(long nID)
  {
    //println("OnPointDestroy, handId: " + nID);
    
    // remove list
    if(_pointLists.containsKey(nID))
       _pointLists.remove(nID);
  }
  
  public ArrayList getPointList(long handId)
  {
    ArrayList curList;
    if(_pointLists.containsKey(handId))
      curList = (ArrayList)_pointLists.get(handId);
    else
    {
      curList = new ArrayList(_maxPoints);
      _pointLists.put(handId,curList);
    }
    return curList;  
  }
  
  public void addPoint(long handId,PVector handPoint)
  {
    //println("Adding point.");
    ArrayList curList = getPointList(handId);
    
    curList.add(0,handPoint);      
    if(curList.size() > _maxPoints)
      curList.remove(curList.size() - 1);
  }
  
  public void update() {
    if(true || _pointLists.size() > 0) {
      
      ArrayList<Vec3D> activeHands = new ArrayList<Vec3D>();
      // draw the hand lists
      Iterator<Map.Entry> itrList = _pointLists.entrySet().iterator();
      while(itrList.hasNext()) {
        ArrayList curList = (ArrayList)itrList.next().getValue();     
  
        
        PVector firstVec = (PVector)curList.get(0);
        PVector screenPos = new PVector(0,0); 
        if(firstVec != null) {
          parent.kinect.convertRealWorldToProjective(firstVec,screenPos);
          activeHands.add(parent.scaleToScreen(new Vec3D(screenPos.x, screenPos.y, screenPos.z)));
        }
      }
      
      parent.applet.photoArranger.updateHands(activeHands);
    }
  }
  
  public void draw() {
  }

}

class Photo extends VerletParticle2D implements Runnable {
  //PVector position, oldPosition, positionTarget;
  //PVector velocity;
  int id = 1;
  float velocityDamping = 0.85f;
  float positionK = 0.1f;
  boolean hasMoved = false;
  float size;
  float scale = 1;
  float scaleK = 0.02f;
  
  float opacity = 1;
  
  float scaleTarget = 1;
  
  float z = 0;
  
  boolean selected = false;
  
  String frontURL, backURL;
  String nextURL;
  String nextCaption;
  GLTexture frontTexture, backTexture;
  GLModel texturedQuad;
  GLModel dropshadowQuad;
  
  String frontCaption, backCaption;
  
  PImage frontImage, backImage;
  boolean backWaiting, frontWaiting;
  
  boolean frontLoaded = false;
  boolean backLoaded = false;
  boolean backLoading = false;
  boolean frontLoading = false;
  
  int side = 1;
  int lastSide = 1;
  
  PhotoArranger parent;

  int age = 1;
  int flipStep = 0;
  float angleY = 0; float angleYTarget = 0;
  float angleX = 0; float angleXTarget = 0;
  float angleK = 0.05f;
  float flipY = 0;
  float flipX = 0;
  boolean flipping = false;
  boolean flipSoon = false;  // If true, will flip at next possible chance (after other side is loaded)
  int flipDirection;
  static final float FLIP_SPEED = 2;
  
  boolean bouncing = false;
  boolean bounceSoon = false;
  int bounceStep = 0;
  float bounceScale = 0;
  static final float BOUNCE_MAX_SIZE = 1.5f;
  static final int BOUNCE_TIME = 60;
 
  boolean zooming = false;
  boolean zoomOnLoad = false;
  boolean zoomSoon = false;  // If true, will zoom at the next possible chance.
  int zoomStep = 0;
  float zoomLevel = 1;
  int zoomDirection = 1;
  static final float MAX_ZOOM = 3;
  static final int ZOOM_TIME = 5000;
  
  static final float PERSPECTIVE_FACTOR = 0.2f;
  
  static final float RANDOM_ZOOM_CHANCE = 0.0001f;
  static final float RANDOM_FLIP_CHANCE = 0.0001f;
  static final float RANDOM_RELOAD_CHANCE = 0.0001f;
  static final float RANDOM_VISIT_CHANCE = 0.44f;
  
  static final float VISIT_ZOOM_MIN = 1.5f;
  final float VISIT_ZOOM_MAX = 2.5f; //ROWS/6.;
  
  Photo(PhotoArranger _parent, String _url, float _size, float iX, float iY) {
     super(iX, iY);
     this.parent = _parent;
     this.frontURL = _url;
     this.size = _size;
     //this.position = new PVector(0,0,0);
     //this.velocity = new PVector(0,0,0);
     //this.positionTarget = position.get();
     //this.oldPosition = this.position.get();;
     
     this.frontCaption = "";
     this.backCaption = "";
     
     texturedQuad = new GLModel(parent.applet, 6, GLModel.TRIANGLE_FAN, GLModel.DYNAMIC);
     dropshadowQuad = new GLModel(parent.applet, 6, GLModel.TRIANGLE_FAN, GLModel.DYNAMIC);
     texturedQuad.initColors();
     dropshadowQuad.initColors();
     setVertices();
     texturedQuad.initTextures(1);  // Reserve room for 1 texture on the graphics card
     dropshadowQuad.initTextures(1);  // Reserve room for 1 texture on the graphics card
      
     GLTextureParameters texParam = new GLTextureParameters();
     //texParam.magFilter = GLTextureParameters.LINEAR;
     //texParam.minFilter = GLTextureParameters.LINEAR;
     
     if(defaultTexture == null) {
       defaultTexture = new GLTexture(parent.applet, "default.jpg", texParam);
     }
     
     
     //frontTexture = new GLTexture(parent.applet, "default.jpg", texParam);
     frontTexture = new GLTexture(parent.applet, defaultTexture.width, defaultTexture.height, texParam);
     frontTexture.copy(defaultTexture);
     frontLoaded = true;
     //backTexture = new GLTexture(parent.applet, "default.jpg", texParam);
     backTexture = new GLTexture(parent.applet, defaultTexture.width, defaultTexture.height, texParam);
     backTexture.copy(defaultTexture);
     texturedQuad.setTexture(0, frontTexture);

     //gl.setSwapInterval(1); //set vertical sync on     //gl.
      
     dropshadowTexture = new GLTexture(parent.applet, "drop-shadow-01.png", texParam);
     dropshadowQuad.setTexture(0,dropshadowTexture);
     
     setTexCoords();  
     
     /*
     texturedQuad.initColors();
     texturedQuad.beginUpdateColors();
     for (int i = 0; i < 6; i++) {
       texturedQuad.updateColor(i, random(0, 255), random(0, 255), random(0, 255), 225);
     }
     texturedQuad.endUpdateColors();        
     */
     
     frontWaiting = false;
     backWaiting = false;
     
     update();
     setVertices();
     
  } 
  
  public void update() {
    super.update();
    // TRANSFER TEXTURE
    // ----------------
    if(frontWaiting) {
      try {
        frontTexture.init(frontImage.width, frontImage.height);
        frontTexture.putImage(frontImage);
        frontWaiting = false;
      }
      catch(Exception e) {
        println(e); 
      }
    }
    if(backWaiting) {
      try {
        backTexture.init(backImage.width, backImage.height);
        backTexture.putImage(backImage);
        backWaiting = false;
      
      }
      catch(Exception e) {
        println(e); 
      }      
    }
    
    age++;    

    if(!flipping && !zooming && (random(0,1) < RANDOM_FLIP_CHANCE || flipSoon))
      triggerFlip();

    if(!flipping && !zooming && (random(0,1) < RANDOM_ZOOM_CHANCE || zoomSoon))
      triggerZoom();

    if(!flipping && !flipSoon && bounceSoon)
      triggerBounce();
    
    if(!flipping && random(0,1) < RANDOM_RELOAD_CHANCE) {
      try {
        String u = parent.loader.randomPhoto();
        if(u != null)
          changeImage(u);  
      }
      catch (Exception e) { println(e); }
    }    
    
    // FLIP STUFF
    // ----------
    // Try to flip if the other side is loaded
    if(flipping && !(flipDirection < 0 && backLoading) &&
                   !(flipDirection > 0 && frontLoading)) {
      flipStep += flipDirection*FLIP_SPEED;
      zoomDirection = zoomLevel >= MAX_ZOOM ? -1 : 1;
    }
    if(flipStep >= 180 || flipStep <= 0) {
      // Stop flipping if at 180 or 0 degrees
      flipping = false;
    }
    
    if(bouncing) {
      bounceStep++;
      if(bounceStep < BOUNCE_TIME / 2) {
        bounceScale = tweenEaseInOutBack(bounceStep, BOUNCE_TIME/2, 0, BOUNCE_MAX_SIZE);
      }
      else {
        bounceScale = tweenEaseInOutBack(bounceStep-BOUNCE_TIME/2, BOUNCE_TIME/2, BOUNCE_MAX_SIZE, 0);
      }
    
      if(bounceStep > BOUNCE_TIME) {
        bounceStep = 0;
        bouncing = false;
        bounceScale = 0;
      }  
    }
    
    // Figure out which side is showing
    // --------------------------------
    // if(flipStep >= 90) side = -1;
    // else side = 1;
    
    flipY = tweenEaseInOutBack(flipStep, 180, 0, 180, 0.5f);
    
    angleY += (angleYTarget - angleY) * angleK;
    angleX += (angleXTarget - angleX) * angleK;
    
    //if(angleY + flipY >= 90) side = -1;
    if(flipStep >= 90) side = -1;
    else side = 1;
    
    if(side != lastSide)
      // Update texture coordinates to flip if necessary
      setTexCoords();    
 
    lastSide = side;    
    
    // ZOOM STUFF
    // ----------
    if(zooming) {
      zoomStep += zoomDirection * 3;
      if(zoomStep < 0) {
        zoomStep = 0;
        if(zoomDirection < 0) zoomDirection *= 0;
      }
    }
    if(zoomStep <= 180)
      //zoomLevel = (-cos(radians(zoomStep))+1)/2 * (MAX_ZOOM-1) + 1;
      zoomLevel = tweenEaseInOutBack(zoomStep, 180, 1, MAX_ZOOM, 0.5f);
    else zoomLevel = MAX_ZOOM;
    
    if(zoomStep > ZOOM_TIME) {
      zoomDirection = -1;
      zoomStep = 180;
    }
    
    scale += ((scaleTarget + bounceScale) - scale) * scaleK;
    
    /*
    velocity.x *= velocityDamping;
    velocity.y *= velocityDamping;
    velocity.z *= velocityDamping;
    
    positionTarget.add(velocity);
    x += (positionTarget.x - x) * positionK;
    y += (positionTarget.y - y) * positionK;
    position.z += (positionTarget.z - position.z) * positionK;
    position.z = zoomLevel > 1 ? zoomLevel : (flipping ? 1 : 0);
    hasMoved = (x != oldx || y != oldy);  
      
    oldPosition = position.get();
    */
    
    setVertices();
  }
  
  public void setTexCoords() {
    // Choose texture
    texturedQuad.setTexture(0, side > 0 ? frontTexture : backTexture);
    
    int X1 = side > 0 ? 0 : 1;
    int X2 = side > 0 ? 1 : 0;
    texturedQuad.beginUpdateTexCoords(0);
      texturedQuad.updateTexCoord(0, 0.5f,0.5f);
      texturedQuad.updateTexCoord(1, X1,0);
      texturedQuad.updateTexCoord(2, X1,1);
      texturedQuad.updateTexCoord(3, X2,1);
      texturedQuad.updateTexCoord(4, X2,0);
      texturedQuad.updateTexCoord(5, X1,0);
    texturedQuad.endUpdateTexCoords();  
    
    dropshadowQuad.beginUpdateTexCoords(0);
      dropshadowQuad.updateTexCoord(0, 0.5f,0.5f);
      dropshadowQuad.updateTexCoord(1, X1,0);
      dropshadowQuad.updateTexCoord(2, X1,1);
      dropshadowQuad.updateTexCoord(3, X2,1);
      dropshadowQuad.updateTexCoord(4, X2,0);
      dropshadowQuad.updateTexCoord(5, X1,0);
    dropshadowQuad.endUpdateTexCoords();      

  }
  
  public void setVertices() {
    float a = cos(radians(angleY+flipY));
    float b = sin(radians(angleY+flipY)); 
    //float g = -parent.gridSpace/2 * zoomLevel;
    float g = -(size*scale)/2 * zoomLevel;
    
    texturedQuad.beginUpdateVertices();
      texturedQuad.updateVertex(0, x,y);  // Center point
      texturedQuad.updateVertex(1, g*a + x,  g - b*g*PERSPECTIVE_FACTOR + y);
      texturedQuad.updateVertex(2, g*a + x, -g + b*g*PERSPECTIVE_FACTOR + y);
      texturedQuad.updateVertex(3, -g*a + x, -g - b*g*PERSPECTIVE_FACTOR + y);
      texturedQuad.updateVertex(4, -g*a + x,  g + b*g*PERSPECTIVE_FACTOR + y);
      texturedQuad.updateVertex(5, g*a + x,  g - b*g*PERSPECTIVE_FACTOR + y); 
    texturedQuad.endUpdateVertices();
    
    float k = 1.2f;
    dropshadowQuad.beginUpdateVertices();
      dropshadowQuad.updateVertex(0, x,y);  // Center point
      dropshadowQuad.updateVertex(1, k*g*a + x,  k*g - k*b*g*PERSPECTIVE_FACTOR + y);
      dropshadowQuad.updateVertex(2, k*g*a + x, -k*g + k*b*g*PERSPECTIVE_FACTOR + y);
      dropshadowQuad.updateVertex(3, -k*g*a + x, -k*g - k*b*g*PERSPECTIVE_FACTOR + y);
      dropshadowQuad.updateVertex(4, -k*g*a + x,  k*g + k*b*g*PERSPECTIVE_FACTOR + y);
      dropshadowQuad.updateVertex(5, k*g*a + x,  k*g - k*b*g*PERSPECTIVE_FACTOR + y); 
    dropshadowQuad.endUpdateVertices();    
    

    
    texturedQuad.beginUpdateColors();
    for (int i = 0; i < 6; i++) {
      texturedQuad.updateColor(i,255,0,255, opacity * 255);
    }
    texturedQuad.endUpdateColors();    
    
    dropshadowQuad.beginUpdateColors();
    for (int i = 0; i < 6; i++) {
      dropshadowQuad.updateColor(i,255,0,255, opacity * 128);
    }
    dropshadowQuad.endUpdateColors();
  }
  
  public void draw() {
    textureMode(NORMALIZED);
    
    noStroke();
    //stroke(255);
    //tint(255,255,255,100);

    dropshadowQuad.render();
    texturedQuad.render();
  }
  
  
  public void triggerFlip() { triggerFlip(false); }
  public void triggerFlip(boolean force) {
    //if(force || (side > 0 && backLoaded) || (side < 0 && frontLoaded)) {  // Only trigger a flip if the other side is available
    if(force || (backLoaded && frontLoaded)) {
      flipping = true; 
      flipDirection = flipStep > 0 ? -1 : 1;
      flipSoon = false;
    }
  }
  
  public void triggerZoom() { triggerZoom(false); }
  public void triggerZoom(boolean force) {
    if(force || parent.canZoom(this)) {
      zooming = true;
      zoomSoon = false;  // Reset
      
      if(random(0,1) < RANDOM_VISIT_CHANCE)
        visitMe();
    }
  }
  
  public void triggerBounce() { triggerBounce(false); }
  public void triggerBounce(boolean force) {
    if(force || (backLoaded && frontLoaded)) {
      bouncing = true;
      //bounceStep = 0;
      bounceSoon = false;
    }
  }
  
  public void downloadNextImage(String _url) {
    this.nextURL = _url;
    Thread t = new Thread(this);
    t.start();
  }
  
  public void changeImage(String _url) {
    changeImage(_url, false);
  }
  
  public void changeImage(String _url, boolean _flipOnLoad) {
    changeImage(_url, _flipOnLoad, false);
  }
  public void changeImage(String _url, boolean _flipOnLoad, boolean brandNew) {
    flipSoon = _flipOnLoad;
    //zoomOnLoad = _zoomOnLoad;
    
    downloadNextImage(_url);
    age = 0;
    
    //if(zoomOnLoad) visitMe(brandNew);
    
    //parent.focusTarget = grid.getCenter(this);
    //parent.focusZoom = random(.75,2);
  }
  
  public void visitMe() {
    visitMe(false);
  }
  public void visitMe(boolean priority) {
    /*
    float offsetX = (int)random(-3,4)*parent.gridSpace;
    float offsetY = (int)random(-2,3)*parent.gridSpace;
    PVector loc = new PVector(parent.getCenter(this).x + offsetX,
                              parent.getCenter(this).y + offsetY,
                              random(VISIT_ZOOM_MIN, VISIT_ZOOM_MAX));
    
    if(priority) parent.visitPriorityQueue.push(loc);
    else         parent.visitQueue.push(loc);
    */
  }
  
  public void run() {
    // Reserve the next photo to be loaded
    int newIndex = parent.loader.photoStack.indexOf(nextURL);
    if(newIndex > -1)
      parent.loader.availability.set(newIndex, false);// = Boolean.FALSE;

    try {
      while(flipping) Thread.sleep(10);  // Wait until flipping is done
    }
    catch(InterruptedException e) { }

    if(side > 0 && !backLoading) {
      // Currently on front, transition to back
      backLoaded = false;
      backLoading = true;
      try {
        backImage = loadImage(nextURL);
      }
      catch (Exception e) { 
        loadImage("default.jpg"); 
        println("Couldn't load photo: " + nextURL);
      }
      backWaiting = true;  // Ready to be transfered to GLTexture on main thread
      backLoaded = true; 
      backLoading = false;  
      if(zoomOnLoad) zoomSoon = true;
      zoomOnLoad = false; 
      
      //backCaption = parent.loader.captions.get(newIndex);
      
      // Free up the old photo so another space can use it
      int oldIndex = parent.loader.photoStack.indexOf(frontURL);
      if(oldIndex > -1)
        parent.loader.availability.set(oldIndex, true);
        
      backURL = nextURL;
    }
    else if(side < 0 && !frontLoading) {
      // Currently on back, transition to front
      frontLoaded = false;
      frontLoading = true;
      try {
        frontImage = loadImage(nextURL);
      }
      catch (Exception e) {
        loadImage("default.jpg");
        println("Couldn't load photo: " + nextURL);
      }
      frontWaiting = true; // Ready to be transfered to GLTexture on main thread
      frontLoaded = true; 
      frontLoading = false; 
      
      if(zoomOnLoad) zoomSoon = true;
      zoomOnLoad = false; 
      
      //frontCaption = parent.loader.captions.get(newIndex);
      
      // Free up the old photo so another space can use it
      int oldIndex = parent.loader.photoStack.indexOf(backURL);
      if(oldIndex > -1)
        parent.loader.availability.set(oldIndex, true);
        
      frontURL = nextURL;
    }
  }
  
  public boolean contains(PVector p) {
    /*
    float g = -size/2 * zoomLevel;
    
    PVector tl = new PVector(x - g, y - g);
    PVector br = new PVector(x + g, y + g);
    
    return (p.x > tl.x && p.x < br.x && p.y > tl.y && p.y < br.y);
    */
    
    PVector a = new PVector(x, y);
    PVector b = new PVector(p.x*2, p.y*2);
    return a.dist(b) < 100;
  }
  
}

class PhotoArranger {
  PVector center;
  PVector centerTarget;
  float zoom;
  float zoomTarget;
  float zoomK = 0.1f;
  float centerK = 0.1f;
    
  VerletPhysics2D physics;
  PerlinNoise noise;
  
  ArrayList<Photo> photos;
  ArrayList<Photo> activePhotos;
  ArrayList<VerletParticle2D> photoBaseParticles;
  ArrayList<VerletSpring2D> photoBaseSprings;
  ArrayList<AttractionBehavior> handAttractors;
  ArrayList<AttractionBehavior> gridpointAttractors;
  ArrayList<AttractionBehavior> activePhotoAttractors;
  static final float BASE_SPRING_STRENGTH = 0.01f;
  
  Stack<Photo> entranceStack;
  Photo enteringPhoto;
  VerletParticle2D entranceAnchor;
  VerletSpring2D entranceSpring;
  float entranceSpringStrength = 0.05f;
  int entranceStep;
  int entranceLength = 300;
  float entrancePause = 0.5f;
  float entrancePhotoSize = 6;
  
  int photoCount = 84; // 135
  
  PhotoLoader loader;
  CreatorsKinect applet;
  
  static final int GRID_MODE = 0;
  static final int CONVEYOR_MODE = 1;
  static final int WAVE_MODE = 2;
  static final int BULGE_MODE = 3;
  static final int FLIP_MODE = 4;
  int mode = BULGE_MODE;
  boolean convey = true;
  
  public int gridRows = 7;  // 9
  public int gridCols = 12; // 15
  float gridSpacing;
  
  float closestZ;
  float farthestZ;
  
  static final float HAND_MIN_DISTANCE = 2400;
  static final float HAND_MAX_DISTANCE = 3600;
  static final float HAND_MIN_FORCE    = 0.005f;  // 0.2
  static final float HAND_MAX_FORCE    = 0.03f;  // 0.9
  
  public PhotoArranger(CreatorsKinect applet) {
    this.applet = applet;
    this.loader = new PhotoLoader(this);
    
    physics = new VerletPhysics2D();
    physics.setDrag(0.5f);
    //physics.setWorldBounds(new Rect(0,0, width, height));
    
    physics.setNumIterations(1);
    
    gridSpacing = width / (float)gridCols;
    
    handAttractors = new ArrayList<AttractionBehavior>();
    activePhotoAttractors = new ArrayList<AttractionBehavior>();
    gridpointAttractors = new ArrayList<AttractionBehavior>();
    
    entranceStack = new Stack<Photo>();
    entranceAnchor = new VerletParticle2D(width/2, height/2);
    entranceAnchor.lock();
    
    noise = new PerlinNoise();
    
    photos = new ArrayList<Photo>(photoCount);
    activePhotos = new ArrayList<Photo>();
    photoBaseParticles = new ArrayList<VerletParticle2D>(photoCount);
    photoBaseSprings = new ArrayList<VerletSpring2D>(photoCount);
    for(int i=0; i<photoCount; i++) {
      Photo p = new Photo(this, "", gridSpacing,
                          (i%gridCols + 0.5f) * gridSpacing, (i/gridCols + 0.5f) * gridSpacing);
      p.id = i;
      
      VerletParticle2D base = new VerletParticle2D((i%gridCols + 0.5f) * gridSpacing, (i/gridCols + 0.5f) * gridSpacing);
      base.lock();
      VerletSpring2D spring = new VerletSpring2D(base, p, 0, BASE_SPRING_STRENGTH * random(0.5f, 2));
      //p.positionTarget = new PVector((i%gridCols + 0.5) * gridSpacing, (i/gridCols + 0.5) * gridSpacing, 0);
      physics.addParticle(p);
      physics.addParticle(base);
      physics.addSpring(spring);
      photos.add(p);
      photoBaseParticles.add(base);
      photoBaseSprings.add(spring);
    }
  }
 
  public void setGridDimensions(int rows, int cols) {
    if(rows < 1 || cols < 1 || rows * cols > 500) return;  // Bounds check
    
    this.gridRows = rows;
    this.gridCols = cols;
    int oldPhotoCount = photoCount;
    this.photoCount = rows * cols;
    this.gridSpacing = width / (float)gridCols;
    if(photoCount < oldPhotoCount) {
      // Fewer photos to display, so remove some from the array list
      ArrayList<Photo> photosToKeep = new ArrayList<Photo>(photoCount);
      ArrayList<VerletParticle2D> basesToKeep = new ArrayList<VerletParticle2D>(photoCount);
      ArrayList<VerletSpring2D> springsToKeep = new ArrayList<VerletSpring2D>(photoCount);
      
      for(int i=0; i<photos.size(); i++) {
        if(photos.get(i).id < photoCount) {
          photosToKeep.add(photos.get(i));
          basesToKeep.add(photoBaseParticles.get(i));
          springsToKeep.add(photoBaseSprings.get(i));
        }
      }
      
      photos = photosToKeep;
      photoBaseParticles = basesToKeep;
      photoBaseSprings = springsToKeep;
      
      /*
      for(int i=0; i<photos.size(); i++) {
        if(photos.get(i).id >= photoCount) {
          photos.remove(i);
          photoBaseParticles.remove(i);
          photoBaseSprings.remove(i);  
        }
      }
      */
    }
    else {
      // More photos on the grid, so add some to the list
      for(int i=oldPhotoCount; i<photoCount; i++) {
        Photo p = new Photo(this, "", gridSpacing,
                            (i%gridCols + 0.5f) * gridSpacing, (i/gridCols + 0.5f) * gridSpacing);
        p.id = i;
        
        VerletParticle2D base = new VerletParticle2D((i%gridCols + 0.5f) * gridSpacing, (i/gridCols + 0.5f) * gridSpacing);
        base.lock();
        VerletSpring2D spring = new VerletSpring2D(base, p, 0, BASE_SPRING_STRENGTH * random(0.5f, 2));
        //p.positionTarget = new PVector((i%gridCols + 0.5) * gridSpacing, (i/gridCols + 0.5) * gridSpacing, 0);
        physics.addParticle(p);
        physics.addParticle(base);
        physics.addSpring(spring);
        photos.add(p);
        photoBaseParticles.add(base);
        photoBaseSprings.add(spring);        
      }      
    }
    
    // Move the base particles into their new positions
    for(int i=0; i<photoBaseParticles.size(); i++) {
      int id = photos.get(i).id;
      photoBaseParticles.get(i).set((id%gridCols + 0.5f) * gridSpacing, (id/gridCols + 0.5f) * gridSpacing);
      photos.get(i).set((id%gridCols + 0.5f) * gridSpacing, (id/gridCols + 0.5f) * gridSpacing);
      photos.get(i).size = gridSpacing;
      photos.get(i).clearVelocity();
    }
    
    loader.reset();
  }
  
  public void setMode(int mode) {
    if(mode == 1) return;
    this.mode = mode;
  }
  
  public void update() {
    physics.update();
    depthSort();
    loader.update(); 
    Photo _p;
    for(int i=0; i<photos.size(); i++) {
      _p = photos.get(i);
      _p.update();

      if(mode == WAVE_MODE) {
        VerletSpring2D s = photoBaseSprings.get(i);
        float displacement = s.a.distanceTo(s.b);
        _p.angleYTarget = (s.a.x - s.b.x);
        _p.angleXTarget = (s.a.y - s.b.y);
        
        //float scaleNoise = map(noise.noise(_p.x * 0.01, _p.y * 0.01, millis()/1000.), 0,1, 1/(1+displacement/50.), 1+displacement/50.);
        //scaleNoise = constrain(scaleNoise, 0.5, 3);
        displacement /= 50;
        displacement = constrain(displacement, 0, 0.25f);
        float scaleNoise = (displacement * cos(millis()/500.f));
        float displacementScale = 1 + displacement*4;
        //_p.scale = scaleNoise + displacementScale;
        _p.scaleTarget = displacementScale;
        _p.setVertices();
        
        _p.opacity = map(_p.scale, closestZ + 0.01f, farthestZ, 1, 1/(closestZ + 0.01f));
        //if(!activePhotos.contains(_p)) activePhotos.add(_p);
        
        if(_p == enteringPhoto) {
          entranceStep++;
          
          //_p.angleYTarget = 0;
          
          if(entranceSpring == null) {
            entranceSpring = new VerletSpring2D(entranceAnchor, enteringPhoto, 0, 0);
            physics.addSpring(entranceSpring);
          }
          
          float transitionLength = (entranceLength - entranceLength*entrancePause) / 2.f;
          if(entranceStep < transitionLength) {
            //float step, float duration, float min, float max
            _p.scaleTarget = tweenEaseInOutBack(entranceStep, transitionLength, 1, entrancePhotoSize);  
            entranceSpring.setStrength(entranceSpringStrength*tweenEaseInOutBack(entranceStep, transitionLength, 0, 1));
            _p.angleYTarget = tweenEaseInOutBack(entranceStep, transitionLength, 0, 360);
          }
          else if(entranceStep > entranceLength - transitionLength) {
            _p.scaleTarget = tweenEaseInOutBack(entranceStep-(entranceLength - transitionLength), transitionLength, entrancePhotoSize, 1);  
            entranceSpring.setStrength(entranceSpringStrength*tweenEaseInOutBack(entranceStep-(entranceLength - transitionLength), transitionLength, 1, 0));
            _p.angleYTarget = tweenEaseInOutBack(entranceStep-(entranceLength - transitionLength), transitionLength, 360, 0);  
          }
          else {
            _p.scaleTarget = 5;
            if(entranceStep == (int)(entranceLength/4)) _p.triggerFlip();
            _p.angleYTarget = 360;
          }
          
          if(entranceStep >= entranceLength) {
            entranceStep = 0;
            enteringPhoto = null;
          }
        }        
        
      }
      else if(mode == BULGE_MODE) {
        for(int j=0; j<handAttractors.size(); j++) {
          physics.removeBehavior(handAttractors.get(j));
        }
        handAttractors.clear();        
        
        float displacement = applet.kinectManager.getDepth(_p.x, _p.y);
        if(displacement == 0 || displacement > applet.kinectManager.depthThreshold) displacement = 1;
        else displacement = map(displacement, HAND_MIN_DISTANCE, applet.kinectManager.depthThreshold, 3,1);
        
        _p.scaleTarget = displacement;
        _p.angleYTarget = 0;
        
        if(_p == enteringPhoto) {
          entranceStep++;
          
          if(entranceSpring == null) {
            entranceSpring = new VerletSpring2D(entranceAnchor, enteringPhoto, 0, 0);
            physics.addSpring(entranceSpring);
          }
          
          float transitionLength = (entranceLength - entranceLength*entrancePause) / 2.f;
          if(entranceStep < transitionLength) {
            //float step, float duration, float min, float max
            _p.scaleTarget = tweenEaseInOutBack(entranceStep, transitionLength, 1, entrancePhotoSize);  
            entranceSpring.setStrength(entranceSpringStrength*tweenEaseInOutBack(entranceStep, transitionLength, 0, 1));
          }
          else if(entranceStep > entranceLength - transitionLength) {
            _p.scaleTarget = tweenEaseInOutBack(entranceStep-(entranceLength - transitionLength), transitionLength, entrancePhotoSize, 1);  
            entranceSpring.setStrength(entranceSpringStrength*tweenEaseInOutBack(entranceStep-(entranceLength - transitionLength), transitionLength, 1, 0));
          }
          else {
            _p.scaleTarget = 5;
            if(entranceStep == (int)(entranceLength/4)) _p.triggerFlip();
          }
          
          if(entranceStep >= entranceLength) {
            entranceStep = 0;
            enteringPhoto = null;
          }
        }
        
        //_p.scaleTarget += cos(frameCount/10. + _p.id*13) * _p.scale * 0.25;
        
        _p.opacity = map(_p.scale, closestZ + 0.01f, farthestZ, 1, 1/(closestZ + 0.01f));
        
        _p.setVertices();        
      }
      else if(mode == FLIP_MODE) {
        for(int j=0; j<handAttractors.size(); j++) {
          physics.removeBehavior(handAttractors.get(j));
        }
        handAttractors.clear();        
        
        float displacement = applet.kinectManager.getDepth(_p.x, _p.y);
        if(displacement == 0 || displacement > applet.kinectManager.depthThreshold) displacement = 1;
        else displacement = map(displacement, HAND_MIN_DISTANCE, applet.kinectManager.depthThreshold, 6,1);
        
        _p.scaleTarget = 1;
        //_p.opacity = 1;
        _p.opacity = map(_p.scale, closestZ + 0.01f, farthestZ, 1, 1/(closestZ + 0.01f));
        _p.angleYTarget = 60*(displacement - 1);        
        
        if(_p == enteringPhoto) {
          entranceStep++;
          
          if(entranceSpring == null) {
            entranceSpring = new VerletSpring2D(entranceAnchor, enteringPhoto, 0, 0);
            physics.addSpring(entranceSpring);
          }
          
          float transitionLength = (entranceLength - entranceLength*entrancePause) / 2.f;
          if(entranceStep < transitionLength) {
            //float step, float duration, float min, float max
            _p.scaleTarget = tweenEaseInOutBack(entranceStep, transitionLength, 1, entrancePhotoSize);  
            entranceSpring.setStrength(entranceSpringStrength*tweenEaseInOutBack(entranceStep, transitionLength, 0, 1));
            _p.angleYTarget = tweenEaseInOutBack(entranceStep, transitionLength, 0, 360);
          }
          else if(entranceStep > entranceLength - transitionLength) {
            _p.scaleTarget = tweenEaseInOutBack(entranceStep-(entranceLength - transitionLength), transitionLength, entrancePhotoSize, 1);  
            entranceSpring.setStrength(entranceSpringStrength*tweenEaseInOutBack(entranceStep-(entranceLength - transitionLength), transitionLength, 1, 0));
            _p.angleYTarget = tweenEaseInOutBack(entranceStep-(entranceLength - transitionLength), transitionLength, 360, 0);  
          }
          else {
            _p.scaleTarget = 5;
            if(entranceStep == (int)(entranceLength/4)) _p.triggerFlip();
            _p.angleYTarget = 360;
          }
          
          if(entranceStep >= entranceLength) {
            entranceStep = 0;
            enteringPhoto = null;
          }
          
        }          
     
        _p.setVertices();         
      }
    }
    
    if(enteringPhoto == null) {
      if(!entranceStack.empty())
        enteringPhoto = entranceStack.pop();
      if(entranceSpring != null) {
        physics.removeSpring(entranceSpring);
        entranceSpring = null;
      }
    }
    
    updateActivePhotos();
  }
  
  
  public void updateActivePhotos() {
    for(int i=0; i<activePhotoAttractors.size(); i++) {
      physics.removeBehavior(activePhotoAttractors.get(i));
    }
    activePhotoAttractors.clear();
    
    for(int i=0; i<activePhotos.size(); i++) {
      AttractionBehavior attractor = new AttractionBehavior(activePhotos.get(i), activePhotos.get(i).size, -0.5f);
      physics.addBehavior(attractor);
      activePhotoAttractors.add(attractor);
    }
  }
  
  public void updateHands(ArrayList<Vec3D> handPositions) {
    if(mode == WAVE_MODE) {
      // Get rid of all the old attractors
      for(int i=0; i<handAttractors.size(); i++) {
        physics.removeBehavior(handAttractors.get(i));
      }
      handAttractors.clear();
      
      Vec3D _h;
      for(int i=0; i<handPositions.size(); i++) {
        _h = handPositions.get(i);
        if(_h.y < height-10) {
          float force = map(_h.z, HAND_MIN_DISTANCE, HAND_MAX_DISTANCE, HAND_MAX_FORCE, HAND_MIN_FORCE);
          
          float noiseAngle = noise.noise(_h.x * 0.1f, _h.y * 0.1f, millis()/100.f) * 15;
          Vec2D n = new Vec2D(10*cos(noiseAngle), 10*sin(noiseAngle));
          
          AttractionBehavior attractor = new AttractionBehavior(new Vec2D(n.x + _h.x, n.y + _h.y), 200, -force);
          physics.addBehavior(attractor);
          handAttractors.add(attractor);
          
          AttractionBehavior repeller = new AttractionBehavior(new Vec2D(n.x + _h.x, n.y + _h.y), 50, force*2);
          physics.addBehavior(repeller);
          handAttractors.add(repeller);        
        }
      }
    }
  }
  public void draw() {
    //depthSort();
    for(int i=0; i<photos.size(); i++)
      photos.get(i).draw();
  }
  
  public Photo randomPhoto() { return randomPhoto(0, false); }
  public Photo randomPhoto(int ageThreshold, boolean zoomableOnly) {
    // Build a list of photos that are old enough
    ArrayList<Photo> elligiblePhotos = new ArrayList<Photo>();
    for(int i=0; i<photos.size(); i++) {
      if(photos.get(i).age > ageThreshold && (!zoomableOnly || canZoom(photos.get(i))))
        elligiblePhotos.add(photos.get(i));
    }
    
    if(elligiblePhotos.size() > 0)
      return elligiblePhotos.get((int)random(0,elligiblePhotos.size()));
    else return null;
  }
  
  public Photo emptyPhoto() {
    ArrayList<Photo> elligible = new ArrayList<Photo>();
    for(int i=0; i<photos.size(); i++) {
      if(photos.get(i).backImage == null || photos.get(i).frontImage == null)
        elligible.add(photos.get(i));
    }
    
    if(elligible.size() > 0)
      return elligible.get((int)random(0,elligible.size()));
    else return null;
  }
  
  public boolean canZoom(Photo p) {
    return false;
  }
  
  public void depthSort() {
    boolean sorted = false;
    Photo a, b, c;
    VerletSpring2D springA, springB;
    VerletParticle2D baseA, baseB;
    while(!sorted) {
      sorted = true;
      for(int i=0; i<photos.size()-1; i++) {
        a = photos.get(i);
        b = photos.get(i+1);
        baseA = photoBaseParticles.get(i);
        baseB = photoBaseParticles.get(i+1);
        springA = photoBaseSprings.get(i);
        springB = photoBaseSprings.get(i+1);        
        //if(a.z * a.scale*a.size > b.z * b.scale*b.size) {
        if(a.scale > b.scale) {
       //if(random(0,1) < 0.001) {
          c = a;  // temporary
          photos.set(i,b);
          photos.set(i+1,a);
          photoBaseParticles.set(i,baseB);
          photoBaseParticles.set(i+1,baseA);          
          photoBaseSprings.set(i,springB);
          photoBaseSprings.set(i+1,springA);                    
          
          sorted = false;
        }
      }  
    }
    
    farthestZ = photos.get(0).scale;
    closestZ = photos.get(photos.size()-1).scale;
    //if(closestZ == 0) { closestZ = 1; farthestZ = 1; }
  }
  
  
  public void adjustVelocity(Photo photo, PVector dP) {
    //photo.velocity.x += dP.x;
    //photo.velocity.y += dP.y;
    //photo.velocity.z += dP.z;
  }
  
  public void returnToHome(Photo photo) {
    int index = photos.indexOf(photo);
    if(index >= 0) {
      float gridSpacing = screenWidth / (float)gridCols;
      //photo.positionTarget = new PVector((index%gridCols + 0.5) * gridSpacing, (index/gridCols + 0.5) * gridSpacing, 0);
    }
  }
}



class PhotoLoader implements Runnable {
  String feed = "http://localhost:8080/tag/creators";
  
  Stack<String> photoStack;
  Stack<Boolean> availability;
  Stack<String> captions;
  
  static final int MIN_STACK_SIZE = 305; //305;
  
  boolean loading;  
  boolean shouldReset = false;
  
  float lastUpdateTime = 0;
  static final int UPDATE_FREQUENCY = 1000;  // milliseconds
  
  boolean initialLoad = true;
  
  PhotoArranger parent;
  
  PhotoLoader(PhotoArranger _parent) {
    this.parent = _parent;
    
    photoStack =   new Stack<String>();
    availability = new Stack<Boolean>();
    captions =     new Stack<String>();
  }
  
  public void reset() {
    shouldReset = true;   
  }
  
  public void update() {
    if(millis() - lastUpdateTime > UPDATE_FREQUENCY)
      reloadFeed();
  }
  
  public String randomPhoto() {
    // Build a list of available ones
    ArrayList<String> elligible = new ArrayList<String>();
    for(int i=0; i<availability.size(); i++) {
      if(availability.get(i) && i < photoStack.size())
        elligible.add(photoStack.get(i));
    }
      
    if(elligible.size() > 0)
      return elligible.get((int)random(0,elligible.size()));  
    else return null;
  }
  
  public void reloadFeed() {
    if(!loading) {
      loading = true;
      Thread t = new Thread(this);
      t.start();
    }
  }
  
  public void run() {
    if(shouldReset) {
      println("Reset photo loader.");
      photoStack =   new Stack<String>();
      availability = new Stack<Boolean>();
      captions =     new Stack<String>();

      initialLoad = true; 
      
      shouldReset = false;
    }
    
    println("Reloading feed...");

    int newPhotos = loadPhotos(feed, 400);
    println(newPhotos + " added from feed");
    
    lastUpdateTime = millis();
    loading = false;
    
    initialLoad = false;
  } 
 
  public int loadPhotos(String feed, int limit) {
    int newPhotos = 0;    
    int retrieved = 0;
    String max_id = "";
    ArrayList<Photo> newPhotoList = new ArrayList<Photo>();
    
    try {
      String urls[] = loadStrings(feed);   
      
      if(urls.length == 0) { println("No photos.");  return 0; }
      
      for(int i=0; i<urls.length && i < limit; i++) {
        String url = urls[i];
        if(url.equals("")) break;
        
        boolean forceNew = url.charAt(0) == '*';
        if(forceNew) url = url.substring(1);
        boolean cached = photoStack.contains(url);
        
        String caption = "";
        
        retrieved++;
        
        
        if(forceNew || !cached) {
          // Add this to the stack if it's not already there
          if(!cached) {
            photoStack.push(url);
            availability.push(true);
            captions.push(caption);
          }
          
          Photo p;
          // Grab an empty (if this is the initial load) or random photo space
          if(initialLoad)
            p = parent.emptyPhoto();
          else
            p = parent.randomPhoto(10, false);
            
          if(p != null) {  // Ok, this is a good new photo
            // Tell the selected grid space to change its image
            p.changeImage(url, initialLoad, !initialLoad);
            newPhotoList.add(p);
            //print(".");
          }
          
          newPhotos++;
          
        }
      }
    }
    catch (Exception e) {
      println("Problem with API: " + e);
    }
    
    // Add the new photos to the entrance stack in reverse order
    if(!initialLoad) {
      if(newPhotoList.size() < 10) {
        for(int i=newPhotoList.size()-1; i>=0; i--) {
          // Add to the new photos stack to be featured
          parent.entranceStack.push(newPhotoList.get(i));
        }
      }
      else {
        for(int i=0; i<newPhotoList.size(); i++) {
          // Flip and bounce as soon as each new photo is loaded
          newPhotoList.get(i).flipSoon = true;
          newPhotoList.get(i).bounceSoon = true;
        }
      }
    }

    // done    
    return newPhotos;
  }  
}
class ScanLine {
  public PVector p1, p2;
  public float thickness;
  public int lineColor;
  int age;
  static final int AGE_LIMIT = 5;

  public ScanLine(PVector a, PVector b) {
    this.p1 = a.get();
    this.p2 = b.get();
    this.thickness = 5;
  }

  public ScanLine(Vec2D a, Vec2D b, float thick) {
    this(a.x, a.y, b.x, b.y, thick);  
  }
  public ScanLine(float a1, float a2, float b1, float b2) {
    this(a1, a2, b1, b2, 5);
  }
  
  public ScanLine(float a1, float a2, float b1, float b2, float thick) {
    this.p1 = new PVector(a1, a2);
    this.p2 = new PVector(b1, b2);
    this.thickness = thick;
  }  
  
  public void update() {
    age++;  
  }

  public void draw() {
    strokeWeight(thickness); // * (1-age/(float)AGE_LIMIT));
    colorMode(HSB);
    int newColor = color(hue(lineColor), saturation(lineColor), brightness(lineColor),  64);
    stroke(newColor);
    line(p1.x, p1.y, p2.x, p2.y); 
    //stroke(0,0,255);
    //line(p1.x, p1.y+thickness, p2.x, p2.y+thickness); 
  }  
}
/*

[ ] Duplicates bug -- ???
[x] Show #CREATORS tag
[ ] Integrate with Doug -- Friday?
[x] Better entrance for user photos
[x] Entrance for flushed photos
[x] Make box for Kinect
[x] Automated mode rotation

*/
public float tweenEaseInOut(float step, float duration, float min, float max) {
  return (-cos(radians(step/duration*180))+1)/2*(max-min)+min;  
}

public float tweenLinear(float step, float duration, float min, float max) {
  return step/duration*(max-min)+min;  
}

public float tweenEaseInOutBack(float step, float duration, float min, float max) {
  return tweenEaseInOutBack(step, duration, min, max, 1);
}
public float tweenEaseInOutBack(float step, float duration, float min, float max, float overshoot) {
  float s = overshoot * 1.70158f;
  float t = step/duration * 2;
  if( t < 1 ) {
      s *= 1.525f;
      return 0.5f*(t*t*((s+1)*t - s)) * (max-min) + min;
  }
  else {
      t -= 2;
      s *= 1.525f;
      return 0.5f*(t*t*((s+1)*t+ s) + 2)  * (max-min) + min;
  }  
 
  //return (-cos(radians(step/duration*180 - duration/20))+1)/2*(max-min)+min;  
}
  static public void main(String args[]) {
    PApplet.main(new String[] { "--present", "--bgcolor=#666666", "--stop-color=#cccccc", "CreatorsKinect" });
  }
}
