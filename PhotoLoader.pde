import org.json.*;
import java.util.*;

class PhotoLoader implements Runnable {
  //String[] feeds = {"https://api.instagram.com/v1/tags/food/media/recent?access_token=19453848.e3ef9b3.028791cb4f1743d0a59da2eba059786a"};
  String[] feeds = {"https://api.instagram.com/v1/users/1885828/media/recent?access_token=19453848.e3ef9b3.028791cb4f1743d0a59da2eba059786a"};
  int[] feedCount = {0};
  float[] feedBalance = {1};

  Stack<String> photoStack;
  Stack<Boolean> availability;
  Stack<String> captions;
  
  static final int MIN_STACK_SIZE = 305; //305;
  
  boolean loading;
  
  float lastUpdateTime = 0;
  static final int UPDATE_FREQUENCY = 4000;  // milliseconds
  
  boolean initialLoad = true;
  
  PhotoArranger parent;
  
  PhotoLoader(PhotoArranger _parent) {
    this.parent = _parent;
    
    photoStack =   new Stack<String>();
    availability = new Stack<Boolean>();
    captions =     new Stack<String>();
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
    println("Reloading feed...");

    float totalBalance = 0;
    for(int i=0; i<feedBalance.length; i++) totalBalance += feedBalance[i];
    
    for(int i=0; i<feeds.length; i++) {
      float balanceFraction = feedBalance[i] / totalBalance;
      int balanceLimit = (int)(photoStack.size() < MIN_STACK_SIZE ? balanceFraction * MIN_STACK_SIZE :
                               (photoStack.size() * balanceFraction - feedCount[i]));
      if(feeds.length == 1) balanceLimit = MAX_INT;
      int newPhotos = loadPhotos(feeds[i], 20, MIN_STACK_SIZE, balanceLimit);
      feedCount[i] += newPhotos;
      //if(newPhotos > 0)
      println(newPhotos + " added from feed " + i);
    }
    
    lastUpdateTime = millis();
    loading = false;
    
    initialLoad = false;
  } 
  
  int loadPhotos(String feed, int atATime, int keepFull) {
    return loadPhotos(feed, atATime, keepFull, Integer.MAX_VALUE);
  }
  int loadPhotos(String feed, int atATime, int keepFull, int limit) {
    int newPhotos = 0;    
    int retrieved = 0;
    String max_id = "";
    ArrayList<Photo> newPhotoList = new ArrayList<Photo>();
    
    while((photoStack.size() < keepFull || retrieved < atATime) && newPhotos < limit) {
      print(".");
      boolean lastPage = false;
      try {
        String lines[] = loadStrings(feed + (max_id.equals("") ? "" : ("&max_id=" + max_id)));
        String json = join(lines, "\n");    
        JSONObject jsonObj = new JSONObject(json);
        JSONArray photosArray = jsonObj.getJSONArray("data");
        try {
          max_id = jsonObj.getJSONObject("pagination").getString("next_max_id");
          //max_id = jsonObj.getJSONObject("pagination").getString("next_max_tag_id");
        }
        catch (JSONException e) { println("Last Page"); lastPage = true; }
        
        if(photosArray.length() == 0) { println("No photos.");  break; }
        
        for(int i=0; i<photosArray.length(); i++) {
          if(newPhotos >= limit) break;  // Stop if enough have been loaded
          
          JSONObject obj = photosArray.getJSONObject(i);
          
          String url = obj.getJSONObject("images").getJSONObject("low_resolution").getString("url");
          
          String caption = "";
          if(obj.has("caption")) {
            try {
              caption = obj.getJSONObject("caption").getString("text");
            }
            catch (JSONException e) { }
          }
          
          //println(caption);
          
          retrieved++;
          
          if(!photoStack.contains(url)) {
            // Add this to the stack
            photoStack.push(url);
            availability.push(true);
            captions.push(caption);
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
        println("Problem with Instagram API: " + e);
      }
      
      if(lastPage) break;
    }
    
    // Add the new photos to the entrance stack in reverse order
    if(!initialLoad) {
      for(int i=newPhotoList.size()-1; i>=0; i--) {
         parent.entranceStack.push(newPhotoList.get(i));
      }
    }

    // done    
    return newPhotos;
  }  
}
