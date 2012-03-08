import toxi.math.noise.*;

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
    physics.setDrag(0.1);
    //physics.setWorldBounds(new Rect(0,0, width, height)); 
    physics.setNumIterations(1);

    noise = new PerlinNoise();

    particles = new ArrayList<AgingParticle>();    
    oldHandPositions = new ArrayList<Vec2D>();
  }
  
  void updateHands(ArrayList<Vec3D> handPositions) {
    applet.photoArranger.updateHands(handPositions);
    
    for(int i=0; i<handPositions.size(); i++) {
      Vec2D velocity = new Vec2D(0,0);
      if(i < oldHandPositions.size()) {
        Vec2D a = oldHandPositions.get(i);
        Vec2D b = new Vec2D(handPositions.get(i).x, handPositions.get(i).y);  
        velocity = b.sub(a).scale(0.25);
      }
      
      AgingParticle _p = new AgingParticle(handPositions.get(i).x + random(-5,5), handPositions.get(i).y + random(-5,5), (int)random(30,100));
      if(random(0,10) < 1) {
        particles.add(_p);  
        physics.addParticle(_p);
      }
      //_p.addVelocity(velocity);
      //float m = velocity.magnitude() + 0.1;
      //_p.addVelocity(new Vec2D(random(-m,m), random(-m,m)));
      println("Adding particle velocity: ");
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
      float noiseAngle = noise.noise(_p.x * 0.05, _p.y * 0.05, millis()/100) * 15;
      _p.addVelocity(new Vec2D(0.25*cos(noiseAngle), 0.25*sin(noiseAngle)));
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
      stroke(0,0,255, pSize / 10. * 255);
      beginShape();
        int sides = _p.sides;
        for(int s=0; s<sides; s++) {
          vertex(_p.x + pSize*cos(_p.age/10. + s/(float)sides*TWO_PI), _p.y + pSize*sin(_p.age/10. + s/(float)sides*TWO_PI));
        }
      endShape(CLOSE);
      //ellipse(particles.get(i).x, particles.get(i).y, pSize, pSize);
    }
  }

  
}
