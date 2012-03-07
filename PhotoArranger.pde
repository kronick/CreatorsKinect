

class PhotoArranger {
  PVector center;
  PVector centerTarget;
  float zoom;
  float zoomTarget;
  float zoomK = 0.1;
  float centerK = 0.1;
    
  VerletPhysics2D physics;
  
  ArrayList<Photo> photos;
  ArrayList<Photo> activePhotos;
  ArrayList<VerletParticle2D> photoBaseParticles;
  ArrayList<VerletSpring2D> photoBaseSprings;
  ArrayList<AttractionBehavior> handAttractors;
  ArrayList<AttractionBehavior> gridpointAttractors;
  ArrayList<AttractionBehavior> activePhotoAttractors;
  static final float BASE_SPRING_STRENGTH = 0.01;
  
  int photoCount = 30; // 135
  
  PhotoLoader loader;
  CreatorsKinect applet;
  
  static final int GRID_MODE = 0;
  static final int CONVEYOR_MODE = 1;
  int mode = CONVEYOR_MODE;
  boolean convey = true;
  
  int gridRows = 9;
  int gridCols = 15;
  float gridSpacing;
  
  static final float HAND_MIN_DISTANCE = 1400;
  static final float HAND_MAX_DISTANCE = 2300;
  static final float HAND_MIN_FORCE    = 0.2;
  static final float HAND_MAX_FORCE    = 0.9;
  
  public PhotoArranger(CreatorsKinect applet) {
    this.applet = applet;
    this.loader = new PhotoLoader(this);
    
    physics = new VerletPhysics2D();
    physics.setDrag(0.3);
    physics.setWorldBounds(new Rect(0,0, width, height));
    
    physics.setNumIterations(1);
    
    gridSpacing = width / (float)gridCols;
    
    handAttractors = new ArrayList<AttractionBehavior>();
    activePhotoAttractors = new ArrayList<AttractionBehavior>();
    gridpointAttractors = new ArrayList<AttractionBehavior>();
    for(int r=2; r<gridRows; r++) {
      for(int c=0; c<gridCols; c++) {
        AttractionBehavior a = new AttractionBehavior(new Vec2D((r+0.5)*gridSpacing, (c+0.5)*gridSpacing),
                                                      gridSpacing, 0.05);
        gridpointAttractors.add(a);  
        physics.addBehavior(a);
      }
    }
    
    photos = new ArrayList<Photo>(photoCount);
    activePhotos = new ArrayList<Photo>();
    photoBaseParticles = new ArrayList<VerletParticle2D>(photoCount);
    photoBaseSprings = new ArrayList<VerletSpring2D>(photoCount);
    for(int i=0; i<photoCount; i++) {
      Photo p = new Photo(this, "", gridSpacing,
                          (i%gridCols + 0.5) * gridSpacing, (i/gridCols + 0.5) * gridSpacing);
                          
      VerletParticle2D base = new VerletParticle2D((i%gridCols + 0.5) * gridSpacing, (i/gridCols + 0.5) * gridSpacing);
      base.lock();
      VerletSpring2D spring = new VerletSpring2D(base, p, 0, BASE_SPRING_STRENGTH);
      //p.positionTarget = new PVector((i%gridCols + 0.5) * gridSpacing, (i/gridCols + 0.5) * gridSpacing, 0);
      physics.addParticle(p);
      physics.addParticle(base);
      physics.addSpring(spring);
      photos.add(p);
      photoBaseParticles.add(base);
      photoBaseSprings.add(spring);
    }
  }
  
  void update() {
    physics.update();
    depthSort();
    loader.update(); 
    Photo _p;
    for(int i=0; i<photos.size(); i++) {
      _p = photos.get(i);
      _p.update();      
      if(_p.y > 200) {
        photoBaseSprings.get(i).setStrength(0); 
        _p.size = gridSpacing * (1+(_p.y - 200)/100.);
        _p.size = constrain(_p.size, gridSpacing, gridSpacing * 3);
        
        if(!activePhotos.contains(_p)) activePhotos.add(_p);
      }
      else {
        photoBaseSprings.get(i).setStrength(BASE_SPRING_STRENGTH);
        if(activePhotos.contains(_p)) activePhotos.remove(activePhotos.indexOf(_p));
      }
      
      if(convey) {
        photoBaseParticles.get(i).x += 1;
        if(photoBaseParticles.get(i).x > width) {
          photoBaseParticles.get(i).x = 0;  
          if(!activePhotos.contains(_p)) _p.x = 0;
        }
      }
      /*
      if(_p.positionTarget.x < 0 || _p.positionTarget.x > width) _p.velocity.x *= -1;
      if(_p.positionTarget.y < 0 || _p.positionTarget.y > width) _p.velocity.y *= -1;
      */
      
      //if(_p.position.y > _p.size*2+0.5 && !_p.zooming) _p.triggerZoom(true);
    }
    
    updateActivePhotos();
  }
  
  
  void updateActivePhotos() {
    for(int i=0; i<activePhotoAttractors.size(); i++) {
      physics.removeBehavior(activePhotoAttractors.get(i));
    }
    activePhotoAttractors.clear();
    
    for(int i=0; i<activePhotos.size(); i++) {
      AttractionBehavior attractor = new AttractionBehavior(activePhotos.get(i), activePhotos.get(i).size, -0.5);
      physics.addBehavior(attractor);
      activePhotoAttractors.add(attractor);
    }
  }
  
  void updateHands(ArrayList<Vec3D> handPositions) {
    applet.handTracker.updateHands(handPositions);
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
        AttractionBehavior attractor = new AttractionBehavior(new Vec2D(_h.x, _h.y), 300, force);
        physics.addBehavior(attractor);
        handAttractors.add(attractor);
        
        AttractionBehavior repeller = new AttractionBehavior(new Vec2D(_h.x, _h.y), 50, -force);
        physics.addBehavior(repeller);
        handAttractors.add(repeller);        
      }
    }
  }
  void draw() {
    for(int i=0; i<photos.size(); i++)
      photos.get(i).draw();
  }
  
  Photo randomPhoto() { return randomPhoto(0, false); }
  Photo randomPhoto(int ageThreshold, boolean zoomableOnly) {
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
  
  Photo emptyPhoto() {
    ArrayList<Photo> elligible = new ArrayList<Photo>();
    for(int i=0; i<photos.size(); i++) {
      if(photos.get(i).backImage == null || photos.get(i).frontImage == null)
        elligible.add(photos.get(i));
    }
    
    if(elligible.size() > 0)
      return elligible.get((int)random(0,elligible.size()));
    else return null;
  }
  
  boolean canZoom(Photo p) {
    return false;
  }
  
  void depthSort() {
    boolean sorted = false;
    Photo a, b, c;
    while(!sorted) {
      sorted = true;
      for(int i=0; i<photos.size()-1; i++) {
        a = photos.get(i);
        b = photos.get(i+1);
        if(a.z > b.z) {
          c = a;  // temporary
          photos.set(i,b);
          photos.set(i+1,c);
          
          sorted = false;
        }
      }  
    }
  }
  
  
  void adjustVelocity(Photo photo, PVector dP) {
    //photo.velocity.x += dP.x;
    //photo.velocity.y += dP.y;
    //photo.velocity.z += dP.z;
  }
  
  void returnToHome(Photo photo) {
    int index = photos.indexOf(photo);
    if(index >= 0) {
      float gridSpacing = screenWidth / (float)gridCols;
      //photo.positionTarget = new PVector((index%gridCols + 0.5) * gridSpacing, (index/gridCols + 0.5) * gridSpacing, 0);
    }
  }
}
