import org.json.*;
import java.util.*;

class PhotoLoader implements Runnable {
  String feed = "http://localhost:8080/tag/creators";
  
  Stack<String> photoStack;
  Stack<Boolean> availability;
  Stack<String> captions;
  
  static final int MIN_STACK_SIZE = 305; //305;
  
  boolean loading;  
  boolean shouldReset = false;
  
  float lastUpdateTime = 0;
  static final int UPDATE_FREQUENCY = 1000;  // milliseconds
  
  boolean initialLoad = true;
  
  PhotoArranger parent;
  
  PhotoLoader(PhotoArranger _parent) {
    this.parent = _parent;
    
    photoStack =   new Stack<String>();
    availability = new Stack<Boolean>();
    captions =     new Stack<String>();
  }
  
  void reset() {
    shouldReset = true;   
  }
  
  void update() {
    if(millis() - lastUpdateTime > UPDATE_FREQUENCY)
      reloadFeed();
  }
  
  String randomPhoto() {
    // Build a list of available ones
    ArrayList<String> elligible = new ArrayList<String>();
    for(int i=0; i<availability.size(); i++) {
      if(availability.get(i) && i < photoStack.size())
        elligible.add(photoStack.get(i));
    }
      
    if(elligible.size() > 0)
      return elligible.get((int)random(0,elligible.size()));  
    else return null;
  }
  
  void reloadFeed() {
    if(!loading) {
      loading = true;
      Thread t = new Thread(this);
      t.start();
    }
  }
  
  void run() {
    if(shouldReset) {
      println("Reset photo loader.");
      photoStack =   new Stack<String>();
      availability = new Stack<Boolean>();
      captions =     new Stack<String>();

      initialLoad = true; 
      
      shouldReset = false;
    }
    
    println("Reloading feed...");

    int newPhotos = loadPhotos(feed, 400);
    println(newPhotos + " added from feed");
    
    lastUpdateTime = millis();
    loading = false;
    
    initialLoad = false;
  } 
 
  int loadPhotos(String feed, int limit) {
    int newPhotos = 0;    
    int retrieved = 0;
    String max_id = "";
    ArrayList<Photo> newPhotoList = new ArrayList<Photo>();
    
    try {
      String urls[] = loadStrings(feed);   
      
      if(urls.length == 0) { println("No photos.");  return 0; }
      
      for(int i=0; i<urls.length && i < limit; i++) {
        String url = urls[i];
        if(url.equals("")) break;
        
        boolean forceNew = url.charAt(0) == '*';
        if(forceNew) url = url.substring(1);
        boolean cached = photoStack.contains(url);
        
        String caption = "";
        
        retrieved++;
        
        
        if(forceNew || !cached) {
          // Add this to the stack if it's not already there
          if(!cached) {
            photoStack.push(url);
            availability.push(true);
            captions.push(caption);
          }
          
          Photo p;
          // Grab an empty (if this is the initial load) or random photo space
          if(initialLoad)
            p = parent.emptyPhoto();
          else
            p = parent.randomPhoto(10, false);
            
          if(p != null) {  // Ok, this is a good new photo
            // Tell the selected grid space to change its image
            p.changeImage(url, initialLoad, !initialLoad);
            newPhotoList.add(p);
            //print(".");
          }
          
          newPhotos++;
          
        }
      }
    }
    catch (Exception e) {
      println("Problem with API: " + e);
    }
    
    // Add the new photos to the entrance stack in reverse order
    if(!initialLoad) {
      if(newPhotoList.size() < 10) {
        for(int i=newPhotoList.size()-1; i>=0; i--) {
          // Add to the new photos stack to be featured
          parent.entranceStack.push(newPhotoList.get(i));
        }
      }
      else {
        for(int i=0; i<newPhotoList.size(); i++) {
          // Flip and bounce as soon as each new photo is loaded
          newPhotoList.get(i).flipSoon = true;
          newPhotoList.get(i).bounceSoon = true;
        }
      }
    }

    // done    
    return newPhotos;
  }  
}
