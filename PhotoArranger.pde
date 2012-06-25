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
  
  Stack<Photo> entranceStack;
  Photo enteringPhoto;
  VerletParticle2D entranceAnchor;
  VerletSpring2D entranceSpring;
  float entranceSpringStrength = 0.05;
  int entranceStep;
  int entranceLength = 300;
  float entrancePause = 0.5;
  float entrancePhotoSize = 6;
  
  PhotoLoader loader;
  CreatorsKinect applet;
  
  static final int GRID_MODE = 0;
  static final int CONVEYOR_MODE = 1;
  static final int WAVE_MODE = 2;
  static final int BULGE_MODE = 3;
  static final int FLIP_MODE = 4;
  int mode = BULGE_MODE;
  boolean convey = true;
  
  public int gridRows = int(settings.get("grid-rows"));  // 9
  public int gridCols = int(settings.get("grid-cols")); // 15
  public int photoCount = gridRows * gridCols; // 135
  float gridSpacing;
  
  float closestZ;
  float farthestZ;
  
  float HAND_MIN_DISTANCE = float(settings.get("kinect-near"));
  float HAND_MAX_DISTANCE = float(settings.get("kinect-far"));
  float HAND_MIN_FORCE    = float(settings.get("kinect-min-force"));  // 0.2
  float HAND_MAX_FORCE    = float(settings.get("kinect-max-force"));  // 0.9
  
  public PhotoArranger(CreatorsKinect applet) {
    this.applet = applet;
    this.loader = new PhotoLoader(this);
    
    physics = new VerletPhysics2D();
    physics.setDrag(float(settings.get("physics-drag")));
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
                          (i%gridCols + 0.5) * gridSpacing, (i/gridCols + 0.5) * gridSpacing);
      p.id = i;
      
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
 
  public void setGridDimensions(int rows, int cols) {
    if(rows < 1 || cols < 1 || rows * cols > 400) return;  // Bounds check
    
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
                            (i%gridCols + 0.5) * gridSpacing, (i/gridCols + 0.5) * gridSpacing);
        p.id = i;
        
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
    
    // Move the base particles into their new positions
    for(int i=0; i<photoBaseParticles.size(); i++) {
      int id = photos.get(i).id;
      photoBaseParticles.get(i).set((id%gridCols + 0.5) * gridSpacing, (id/gridCols + 0.5) * gridSpacing);
      photos.get(i).set((id%gridCols + 0.5) * gridSpacing, (id/gridCols + 0.5) * gridSpacing);
      photos.get(i).size = gridSpacing;
      photos.get(i).clearVelocity();
    }
    
    loader.reset();
  }
  
  void setMode(int mode) {
    if(mode == 1) return;
    this.mode = mode;
  }
  
  void update() {
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
        displacement = constrain(displacement, 0, 0.25);
        float scaleNoise = (displacement * cos(millis()/500.));
        float displacementScale = 1 + displacement*4;
        //_p.scale = scaleNoise + displacementScale;
        _p.scaleTarget = displacementScale;
        _p.setVertices();
        
        _p.opacity = map(_p.scale, closestZ + 0.01, farthestZ, 1, 1/(closestZ + 0.01));
        //if(!activePhotos.contains(_p)) activePhotos.add(_p);
        
        if(_p == enteringPhoto) {
          entranceStep++;
          
          //_p.angleYTarget = 0;
          
          if(entranceSpring == null) {
            entranceSpring = new VerletSpring2D(entranceAnchor, enteringPhoto, 0, 0);
            physics.addSpring(entranceSpring);
          }
          
          float transitionLength = (entranceLength - entranceLength*entrancePause) / 2.;
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
          
          float transitionLength = (entranceLength - entranceLength*entrancePause) / 2.;
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
        
        _p.opacity = map(_p.scale, closestZ + 0.01, farthestZ, 1, 1/(closestZ + 0.01));
        
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
        _p.opacity = map(_p.scale, closestZ + 0.01, farthestZ, 1, 1/(closestZ + 0.01));
        _p.angleYTarget = 60*(displacement - 1);        
        
        if(_p == enteringPhoto) {
          entranceStep++;
          
          if(entranceSpring == null) {
            entranceSpring = new VerletSpring2D(entranceAnchor, enteringPhoto, 0, 0);
            physics.addSpring(entranceSpring);
          }
          
          float transitionLength = (entranceLength - entranceLength*entrancePause) / 2.;
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
          
          float noiseAngle = noise.noise(_h.x * 0.1, _h.y * 0.1, millis()/100.) * 15;
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
    
    farthestZ = photos.get(0).scale;
    closestZ = photos.get(photos.size()-1).scale;
    //if(closestZ == 0) { closestZ = 1; farthestZ = 1; }
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
