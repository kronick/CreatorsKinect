
void loadSettings() {
  // Populate default settings
  settings = new HashMap<String, String>();
  settings.put("feed-url", "http://localhost:8080/tag/creators");
  settings.put("feed-update-period", "1000");
  settings.put("default-logo", "default.png");
  settings.put("hashtag-image", "hashtag.png");
  settings.put("kinect-near", "2400");
  settings.put("kinect-far", "3600"); 
  settings.put("kinect-min-force", "0.005");
  settings.put("kinect-max-force", "0.03");
  settings.put("physics-drag", "0.5");
  settings.put("watchdog-file", "/tmp/watching-the-clock");
  settings.put("grid-rows", "7");
  settings.put("grid-cols", "12");
  
  // Load settings from file
  String[] settingsLines = loadStrings(settingsFile);
  if(settingsLines != null && settingsLines.length > 0) {
    for(int i=0; i<settingsLines.length; i++) {
      String key, value;
      String[] split = split(settingsLines[i], ": ");
      if(split.length > 1) {
        key = split[0].trim();
        value = split[1].trim();
        settings.put(key, value);
      }  
    }
  }  
}

boolean configurationInitialized = false;
boolean chooseHashtagOn = false;
boolean chooseLogoOn = false;

void setupConfigScreen() {
  cp5 = new ControlP5(this);
  // Hashtag image chooser
  cp5.setFont(createFont("Helvetica-Bold", 16));
  
  cp5.addButton("chooseHashtag")
    .setCaptionLabel("Choose Hashtag Image")
    .setValue(0)
    .setPosition(100,100)
    .setSize(300,40);
  cp5.getController("chooseHashtag").getCaptionLabel().align(ControlP5.CENTER, ControlP5.CENTER);        

  cp5.addButton("chooseLogo")
    .setCaptionLabel("Choose Default Logo Image")
    .setValue(0)
    .setPosition(100,150)
    .setSize(300,40);    
  cp5.getController("chooseLogo").getCaptionLabel().align(ControlP5.CENTER, ControlP5.CENTER);        
   
  // Grid size
  cp5.addSlider2D("gridSizeSelector")
    .setPosition(450,100)
    .setSize(160,100)
    .setMinX(0).setMinY(0)
    .setMaxX(16).setMaxY(10)
    .setArrayValue(new float[] {int(settings.get("grid-cols")), int(settings.get("grid-rows"))})
    .setCaptionLabel("Grid Size");
  cp5.getController("gridSizeSelector").getCaptionLabel().align(ControlP5.LEFT, ControlP5.TOP_OUTSIDE);        
  
  // Feed URL text field
  cp5.addTextfield("feedURL")
    .setPosition(100, 230)
    .setCaptionLabel("Feed URL")
    .setValue(settings.get("feed-url"))
    .setSize(400, 40);
  cp5.getController("feedURL").getCaptionLabel().align(ControlP5.LEFT, ControlP5.TOP_OUTSIDE); 

  // Done
  cp5.addButton("changeFeedURL")
    .setCaptionLabel("CHANGE")
    .setPosition(520, 230)
    .setSize(100,40);
  cp5.getController("changeFeedURL").getCaptionLabel().align(ControlP5.CENTER, ControlP5.CENTER);      
  
  // Feed update period range (milliseconds)
  cp5.addSlider("updatePeriod")
    .setPosition(100,310)
    .setCaptionLabel("Feed Update Time (Seconds)")
    .setSize(300,40)
    .setWidth(400)
    .setRange(0.1,10)
    .setValue(int(settings.get("feed-update-period")) / 1000.)    
    .setDecimalPrecision(1);
  cp5.getController("updatePeriod").getCaptionLabel().align(ControlP5.LEFT, ControlP5.TOP_OUTSIDE);            
  
  // Kinect distance range
  cp5.addRange("kinectRange")
    .setPosition(100,390)
    .setCaptionLabel("Kinect Range")
    .setSize(300,40)
    .setWidth(400)
    .setRange(1000,10000)
    .setRangeValues(int(settings.get("kinect-near")), int(settings.get("kinect-far")))    
    .setDecimalPrecision(0);
  cp5.getController("kinectRange").getCaptionLabel().align(ControlP5.LEFT, ControlP5.TOP_OUTSIDE);            
  
  // Kinect sensitivity range
  cp5.addRange("kinectSensitivity")
    .setPosition(100,470)
    .setCaptionLabel("Kinect Sensitivity")
    .setSize(300,40)
    .setWidth(400)
    .setRange(0,1000)
    .setRangeValues(int(float(settings.get("kinect-min-force")) * 1000), int(float(settings.get("kinect-max-force")) * 1000))    
    .setDecimalPrecision(0);
  cp5.getController("kinectSensitivity").getCaptionLabel().align(ControlP5.LEFT, ControlP5.TOP_OUTSIDE);  
  // Physics drag slider
  
  // Done
  cp5.addButton("doneButton")
    .setCaptionLabel("DONE")
    .setPosition(100, 550)
    .setSize(100,40);
  cp5.getController("doneButton").getCaptionLabel().align(ControlP5.CENTER, ControlP5.CENTER);    
    
  // Quit
  cp5.addButton("quitButton")
    .setCaptionLabel("QUIT")
    .setPosition(250, 550)
    .setSize(100,40);
  cp5.getController("quitButton").getCaptionLabel().align(ControlP5.CENTER, ControlP5.CENTER);    
    
  // Restart
    cp5.addButton("restartButton")
    .setCaptionLabel("RESTART")
    .setPosition(400, 550)
    .setSize(100,40);
  cp5.getController("restartButton").getCaptionLabel().align(ControlP5.CENTER, ControlP5.CENTER);        
    
  configurationInitialized = true;
}


public void chooseHashtag(int theValue) {
  if(!configurationInitialized) return;  
  
  new Thread(new Runnable() {
    public void run() {
      String hashtagPath = selectInput("Select hashtag image location");
      if(hashtagPath != null) {
        settings.put("hashtag-image", hashtagPath);
        chooseHashtagOn = true;
      }        
    }
  }).start(); 
}

public void chooseLogo(int theValue) {
  if(!configurationInitialized) return;  
  
  new Thread(new Runnable() {
    public void run() {
      String logoPath = selectInput("Select default image location");
      if(logoPath != null) {
        settings.put("default-logo", logoPath);
        chooseLogoOn = true;
      }        
    }
  }).start(); 
}

public void controlEvent(ControlEvent theEvent) {
  if(!configurationInitialized) return;
  
  if(theEvent.getName().equals("gridSizeSelector")) {
    Slider2D s = (Slider2D)theEvent.getController();
    photoArranger.setGridDimensions((int)s.arrayValue()[1], (int)s.arrayValue()[0]);
    settings.put("grid-rows", str((int)s.arrayValue()[1]));
    settings.put("grid-cols", str((int)s.arrayValue()[0]));
  }
  else if(theEvent.getName().equals("updatePeriod")) {
    Slider s = (Slider)theEvent.getController();
    int time = (int)(s.getValue() * 1000);
    photoArranger.loader.UPDATE_FREQUENCY = time;
    settings.put("feed-update-period", str(time));
  }
  else if(theEvent.getName().equals("kinectRange")) {
    Range r = (Range)theEvent.getController();
    float near = r.getArrayValue()[0];
    float far = r.getArrayValue()[1];
    
    kinectManager.depthThreshold = (int)far;
    photoArranger.HAND_MIN_DISTANCE = near;
    photoArranger.HAND_MAX_DISTANCE = far;
    
    settings.put("kinect-near", str(near));
    settings.put("kinect-far", str(far));
  }
  else if(theEvent.getName().equals("kinectSensitivity")) {
    Range r = (Range)theEvent.getController();
    float min = r.getArrayValue()[0] / 1000.;
    float max = r.getArrayValue()[1] / 1000.;    
    
    photoArranger.HAND_MIN_FORCE = min;
    photoArranger.HAND_MAX_FORCE = max;
    
    settings.put("kinect-min-force", str(min));
    settings.put("kinect-max-force", str(max));
  }  
}

public void doneButton(int v) {
  configuring = false;  
  saveSettings();
}

public void quitButton(int v) {
  configuring = false;
  shuttingDown = true;
  saveSettings();
}
public void restartButton(int v) {
  configuring = false;
  restarting = true;
  saveSettings();
}

public void changeFeedURL(int v) {
  Textfield t = (Textfield)cp5.getController("feedURL");
  photoArranger.loader.feed = t.getText();
  settings.put("feed-url", t.getText());
}

void updateConfigScreen() {
  if(chooseHashtagOn) {
    chooseHashtagOn = false;
    try {
      creatorsTag = new GLTexture(this, settings.get("hashtag-image"));
    }
    catch(NullPointerException e) {
      println("Could not load hashtag image.");
    }
  }  
  if(chooseLogoOn) {
    chooseLogoOn = false;
    try {
      defaultTexture = new GLTexture(this, settings.get("default-logo"));
    }
    catch(NullPointerException e) {
      println("Could not load default logo image.");
    }
  }    
}

void drawConfigScreen() {
  fill(0,0,0,180);
  rect(50,50, 800,600);
}

void saveSettings() {
  changeFeedURL(0);
  String lines[] = new String[settings.size()];
  Iterator it = settings.entrySet().iterator();
  int i=0;
  while(it.hasNext()) {
    Map.Entry me = (Map.Entry)it.next();
    lines[i++] = (String)me.getKey() + ": " + (String)me.getValue();
  }
  
  saveStrings(settingsFile, lines);
}

