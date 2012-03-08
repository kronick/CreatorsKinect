

class PhotoArranger {
  PVector center;
  PVector centerTarget;
  float zoom;
  float zoomTarget;
  float zoomK = 0.1;
  float centerK = 0.1;
    
  VerletPhysics2D physics;
  PerlinNoise noise;
  
  ArrayList<Photo> photos;
  ArrayList<Photo> activePhotos;
  ArrayList<VerletParticle2D> photoBaseParticles;
  ArrayList<VerletSpring2D> photoBaseSprings;
  ArrayList<AttractionBehavior> handAttractors;
  ArrayList<AttractionBehavior> gridpointAttractors;
  ArrayList<AttractionBehavior> activePhotoAttractors;
  static final float BASE_SPRING_STRENGTH = 0.01;
  
  int photoCount = 135; // 135
  
  PhotoLoader loader;
  CreatorsKinect applet;
  
  static final int GRID_MODE = 0;
  static final int CONVEYOR_MODE = 1;
  static final int WAVE_MODE = 2;
  int mode = WAVE_MODE;
  boolean convey = true;
  
  int gridRows = 9;
  int gridCols = 15;
  float gridSpacing;
  
  static final float HAND_MIN_DISTANCE = 1400;
  static final float HAND_MAX_DISTANCE = 2300;
  static final float HAND_MIN_FORCE    = 0.01;  // 0.2
  static final float HAND_MAX_FORCE    = 0.05;  // 0.9
  
  public PhotoArranger(CreatorsKinect applet) {
    this.applet = applet;
    this.loader = new PhotoLoader(this);
    
    physics = new VerletPhysics2D();
    physics.setDrag(0.5);
    physics.setWorldBounds(new Rect(0,0, width, height));
    
    physics.setNumIterations(1);
    
    gridSpacing = width / (float)gridCols;
    
    handAttractors = new ArrayList<AttractionBehavior>();
    activePhotoAttractors = new ArrayList<AttractionBehavior>();
    gridpointAttractors = new ArrayList<AttractionBehavior>();
    if(mode == CONVEYOR_MODE) {
      for(int r=2; r<gridRows; r++) {
        for(int c=0; c<gridCols; c++) {
          AttractionBehavior a = new AttractionBehavior(new Vec2D((r+0.5)*gridSpacing, (c+0.5)*gridSpacing),
                                                        gridSpacing, 0.05);
          gridpointAttractors.add(a);  
          physics.addBehavior(a);
        }
      }
    }
    
    noise = new PerlinNoise();
    
    photos = new ArrayList<Photo>(photoCount);
    activePhotos = new ArrayList<Photo>();
    photoBaseParticles = new ArrayList<VerletParticle2D>(photoCount);
    photoBaseSprings = new ArrayList<VerletSpring2D>(photoCount);
    for(int i=0; i<photoCount; i++) {
      Photo p = new Photo(this, "", gridSpacing,
                          (i%gridCols + 0.5) * gridSpacing, (i/gridCols + 0.5) * gridSpacing);
                          
      VerletParticle2D base = new VerletParticle2D((i%gridCols + 0.5) * gridSpacing, (i/gridCols + 0.5) * gridSpacing);
      base.lock();
      VerletSpring2D spring = new VerletSpring2D(base, p, 0, BASE_SPRING_STRENGTH * random(0.5, 2));
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

      if(mode == CONVEYOR_MODE) {
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
      }
      else if(mode == WAVE_MODE) {
        VerletSpring2D s = photoBaseSprings.get(i);
        float displacement = s.a.distanceTo(s.b);
        _p.angleY = (s.a.x - s.b.x);
        _p.angleX = (s.a.y - s.b.y);
        
        //float scaleNoise = map(noise.noise(_p.x * 0.01, _p.y * 0.01, millis()/1000.), 0,1, 1/(1+displacement/50.), 1+displacement/50.);
        //scaleNoise = constrain(scaleNoise, 0.5, 3);
        displacement /= 50;
        displacement = constrain(displacement, 0, 0.25);
        float scaleNoise = (displacement * cos(millis()/500.));
        float displacementScale = 1 + displacement*2;
        //_p.scale = scaleNoise + displacementScale;
        _p.scale = displacementScale;
        
        _p.setVertices();
        //if(!activePhotos.contains(_p)) activePhotos.add(_p);
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
    //applet.handTracker.updateHands(handPositions);
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
        
        float noiseAngle = noise.noise(_h.x * 0.1, _h.y * 0.1, millis()/100.) * 15;
        Vec2D n = new Vec2D(10*cos(noiseAngle), 10*sin(noiseAngle));
        
        AttractionBehavior attractor = new AttractionBehavior(new Vec2D(n.x + _h.x, n.y + _h.y), 300, -force);
        physics.addBehavior(attractor);
        handAttractors.add(attractor);
        
        AttractionBehavior repeller = new AttractionBehavior(new Vec2D(n.x + _h.x, n.y + _h.y), 50, force*2);
        physics.addBehavior(repeller);
        handAttractors.add(repeller);        
      }
    }
  }
  void draw() {
    //depthSort();
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
