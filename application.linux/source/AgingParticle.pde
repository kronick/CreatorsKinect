class AgingParticle extends VerletParticle2D {
  int age;
  int lifeSpan;
  int sides;
  color fillColor;
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
  
  void update() {
    dead = age++ > lifeSpan;
    super.update();
  }
  
  boolean isDead() {
    return dead;
  }
  
  
}
