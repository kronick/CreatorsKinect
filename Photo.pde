class Photo extends VerletParticle2D implements Runnable {
  //PVector position, oldPosition, positionTarget;
  //PVector velocity;
  int id = 1;
  float velocityDamping = 0.85;
  float positionK = 0.1;
  boolean hasMoved = false;
  float size;
  float scale = 1;
  float scaleK = 0.01;
  
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
  float angleK = 0.03;
  float flipY = 0;
  float flipX = 0;
  boolean flipping = false;
  boolean flipSoon = false;  // If true, will flip at next possible chance (after other side is loaded)
  int flipDirection;
  static final float FLIP_SPEED = 2;
 
  boolean zooming = false;
  boolean zoomOnLoad = false;
  boolean zoomSoon = false;  // If true, will zoom at the next possible chance.
  int zoomStep = 0;
  float zoomLevel = 1;
  int zoomDirection = 1;
  static final float MAX_ZOOM = 3;
  static final int ZOOM_TIME = 5000;
  
  static final float PERSPECTIVE_FACTOR = 0.2;
  
  static final float RANDOM_ZOOM_CHANCE = 0.0001;
  static final float RANDOM_FLIP_CHANCE = -1;
  static final float RANDOM_RELOAD_CHANCE = 0.0001;
  static final float RANDOM_VISIT_CHANCE = 0.44;
  
  static final float VISIT_ZOOM_MIN = 1.5;
  final float VISIT_ZOOM_MAX = 2.5; //ROWS/6.;
  
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
     
     frontTexture = new GLTexture(parent.applet, "default.jpg", texParam);
     //println(frontTexture.usingMipmaps() + " using mipmaps");
     frontLoaded = true;
     backTexture = new GLTexture(parent.applet, "default.jpg", texParam);
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
  
  void update() {
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
    
    // Figure out which side is showing
    // --------------------------------
    // if(flipStep >= 90) side = -1;
    // else side = 1;
    
    flipY = tweenEaseInOutBack(flipStep, 180, 0, 180, 0.5);
    
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
      zoomLevel = tweenEaseInOutBack(zoomStep, 180, 1, MAX_ZOOM, 0.5);
    else zoomLevel = MAX_ZOOM;
    
    if(zoomStep > ZOOM_TIME) {
      zoomDirection = -1;
      zoomStep = 180;
    }
    
    scale += (scaleTarget - scale) * scaleK;
    
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
  
  void setTexCoords() {
    // Choose texture
    texturedQuad.setTexture(0, side > 0 ? frontTexture : backTexture);
    
    int X1 = side > 0 ? 0 : 1;
    int X2 = side > 0 ? 1 : 0;
    texturedQuad.beginUpdateTexCoords(0);
      texturedQuad.updateTexCoord(0, 0.5,0.5);
      texturedQuad.updateTexCoord(1, X1,0);
      texturedQuad.updateTexCoord(2, X1,1);
      texturedQuad.updateTexCoord(3, X2,1);
      texturedQuad.updateTexCoord(4, X2,0);
      texturedQuad.updateTexCoord(5, X1,0);
    texturedQuad.endUpdateTexCoords();  
    
    dropshadowQuad.beginUpdateTexCoords(0);
      dropshadowQuad.updateTexCoord(0, 0.5,0.5);
      dropshadowQuad.updateTexCoord(1, X1,0);
      dropshadowQuad.updateTexCoord(2, X1,1);
      dropshadowQuad.updateTexCoord(3, X2,1);
      dropshadowQuad.updateTexCoord(4, X2,0);
      dropshadowQuad.updateTexCoord(5, X1,0);
    dropshadowQuad.endUpdateTexCoords();      

  }
  
  void setVertices() {
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
    
    float k = 1.2;
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
  
  void draw() {
    textureMode(NORMALIZED);
    
    noStroke();
    //stroke(255);
    //tint(255,255,255,100);

    dropshadowQuad.render();
    texturedQuad.render();
  }
  
  
  void triggerFlip() { triggerFlip(false); }
  void triggerFlip(boolean force) {
    //if(force || (side > 0 && backLoaded) || (side < 0 && frontLoaded)) {  // Only trigger a flip if the other side is available
    if(force || (backLoaded && frontLoaded)) {
      flipping = true; 
      flipDirection = flipStep > 0 ? -1 : 1;
      flipSoon = false;
    }
  }
  
  void triggerZoom() { triggerZoom(false); }
  void triggerZoom(boolean force) {
    if(force || parent.canZoom(this)) {
      zooming = true;
      zoomSoon = false;  // Reset
      
      if(random(0,1) < RANDOM_VISIT_CHANCE)
        visitMe();
    }
  }
  
  void downloadNextImage(String _url) {
    this.nextURL = _url;
    Thread t = new Thread(this);
    t.start();
  }
  
  void changeImage(String _url) {
    changeImage(_url, false);
  }
  
  void changeImage(String _url, boolean _flipOnLoad) {
    changeImage(_url, _flipOnLoad, false);
  }
  void changeImage(String _url, boolean _flipOnLoad, boolean brandNew) {
    flipSoon = _flipOnLoad;
    //zoomOnLoad = _zoomOnLoad;
    
    downloadNextImage(_url);
    age = 0;
    
    //if(zoomOnLoad) visitMe(brandNew);
    
    //parent.focusTarget = grid.getCenter(this);
    //parent.focusZoom = random(.75,2);
  }
  
  void visitMe() {
    visitMe(false);
  }
  void visitMe(boolean priority) {
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
  
  void run() {
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
      backImage = loadImage(nextURL);
      backWaiting = true;  // Ready to be transfered to GLTexture on main thread
      backLoaded = true; 
      backLoading = false;  
      if(zoomOnLoad) zoomSoon = true;
      zoomOnLoad = false; 
      
      backCaption = parent.loader.captions.get(newIndex);
      
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
      frontImage = loadImage(nextURL);
      frontWaiting = true; // Ready to be transfered to GLTexture on main thread
      frontLoaded = true; 
      frontLoading = false; 
      
      if(zoomOnLoad) zoomSoon = true;
      zoomOnLoad = false; 
      
      frontCaption = parent.loader.captions.get(newIndex);
      
      // Free up the old photo so another space can use it
      int oldIndex = parent.loader.photoStack.indexOf(backURL);
      if(oldIndex > -1)
        parent.loader.availability.set(oldIndex, true);
        
      frontURL = nextURL;
    }
  }
  
  boolean contains(PVector p) {
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

