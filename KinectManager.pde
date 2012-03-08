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
    }    
  }
  
  public void update() {
    if(frameCount % 2 == 0) return;
    if(!simulate) {
      // update the cam
      kinect.update();
      
      kinect.update(sessionManager);
      
      // draw depthImageMap
      PImage depthMap = kinect.depthImage();
      int pos;
      int lineStart, lineEnd, lineLength, gapLength;
      int lastDepth = 0;
      int DEPTH_DISCONTINUITY_THRESHOLD = 20;
      float avgDepth = 0;
      lineStart = lineEnd = -1;
      lineLength = gapLength = 0;
      
      int gapLimit = 5;
      int scanSpacing = 6;
      
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
              ScanLine s = new ScanLine(lineStart, y, lineEnd,y, scanSpacing);
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
    }
    else {
      ArrayList<Vec3D> activeHands = new ArrayList<Vec3D>();
      activeHands.add(new Vec3D(mouseX, mouseY, 1000));
      applet.photoArranger.updateHands(activeHands);
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
          activeHands.add(new Vec3D(screenPos.x*2, screenPos.y*2, screenPos.z));
          point(screenPos.x,screenPos.y);
        }
      }
      
      parent.applet.photoArranger.updateHands(activeHands);
    }
  }
  
  public void draw() {
    if(_pointLists.size() <= 0)
      return;
      
    pushStyle();
      noFill();
      
      PVector vec;
      PVector firstVec;
      PVector screenPos = new PVector();
      int colorIndex=0;
      
      // draw the hand lists
      Iterator<Map.Entry> itrList = _pointLists.entrySet().iterator();
      while(itrList.hasNext()) 
      {
        strokeWeight(8);
        stroke(_colorList[colorIndex % (_colorList.length - 1)]);

        ArrayList curList = (ArrayList)itrList.next().getValue();     
        
        // draw line
        firstVec = null;
        Iterator<PVector> itr = curList.iterator();
        beginShape();
          while (itr.hasNext()) 
          {
            vec = itr.next();
            if(firstVec == null)
              firstVec = vec;
            // calc the screen pos
            parent.kinect.convertRealWorldToProjective(vec,screenPos);
            vertex(screenPos.x,screenPos.y);    
          } 
        endShape();   
  
        // draw current pos of the hand
        if(firstVec != null)
        {
          strokeWeight(10);
          parent.kinect.convertRealWorldToProjective(firstVec,screenPos);
          point(screenPos.x,screenPos.y);
        }
        colorIndex++;
      }
      
    popStyle();
  }

}

