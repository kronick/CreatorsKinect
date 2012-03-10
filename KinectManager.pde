class KinectManager {
  SimpleOpenNI kinect;
  
  // NITE
  XnVSessionManager sessionManager;
  XnVFlowRouter     flowRouter;
  PointDrawer       pointDrawer;
  
  CreatorsKinect applet;
  boolean simulate = false;
  
  ArrayList<ScanLine> scanLines;
  PVector handPosition, oldHandPosition;
  
  float scaleFactor = 1;
  
  PImage depthMap;
  int depthThreshold = 2400;
  
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
              s.lineColor = color(100+(avgDepth/(float)lineLength) * 155,255, 255);
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
      pointDrawer.update();
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
    if(kinect.depthMap() == null) return 0;
    
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
  
  float scaleToScreen(float x) {
    return x * scaleFactor;
  }  
  float scaleToScreen(int x) {
    return x * scaleFactor;
  }
  PVector scaleToScreen(PVector p) {
    return new PVector(scaleToScreen(p.x), scaleToScreen(p.y));
  }
  Vec2D scaleToScreen(Vec2D p) {
    return new Vec2D(scaleToScreen(p.x), scaleToScreen(p.y));
  }
  Vec3D scaleToScreen(Vec3D p) {
    return new Vec3D(scaleToScreen(p.x), scaleToScreen(p.y), p.z);
  }  
}

/////////////////////////////////////////////////////////////////////////////////////////////////////
// session callbacks

void onStartSession(PVector pos)
{
  println("onStartSession: " + pos);
}

void onEndSession()
{
  println("onEndSession: ");
}

void onFocusSession(String strFocus,PVector pos,float progress)
{
  println("onFocusSession: focus=" + strFocus + ",pos=" + pos + ",progress=" + progress);
}



/////////////////////////////////////////////////////////////////////////////////////////////////////
// PointDrawer keeps track of the handpoints

class PointDrawer extends XnVPointControl {
  
  KinectManager parent;
  HashMap    _pointLists;
  int        _maxPoints;
  color[]    _colorList = { color(255,0,128),color(0,128,255),color(0,0,255),color(255,255,0)};
  
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

