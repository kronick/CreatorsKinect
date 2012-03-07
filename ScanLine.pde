class ScanLine {
  public PVector p1, p2;
  public float thickness;
  public color lineColor;
  int age;
  static final int AGE_LIMIT = 5;

  public ScanLine(PVector a, PVector b) {
    this.p1 = a.get();
    this.p2 = b.get();
    this.thickness = 5;
  }

  public ScanLine(float a1, float a2, float b1, float b2) {
    this.p1 = new PVector(a1, a2);
    this.p2 = new PVector(b1, b2);
    this.thickness = 5;
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
    color newColor = color(hue(lineColor), saturation(lineColor), brightness(lineColor),  64);
    stroke(newColor);
    line(p1.x, p1.y, p2.x, p2.y); 
    //stroke(0,0,255);
    //line(p1.x, p1.y+thickness, p2.x, p2.y+thickness); 
  }  
}
