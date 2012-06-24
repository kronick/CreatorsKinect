float tweenEaseInOut(float step, float duration, float min, float max) {
  return (-cos(radians(step/duration*180))+1)/2*(max-min)+min;  
}

float tweenLinear(float step, float duration, float min, float max) {
  return step/duration*(max-min)+min;  
}

float tweenEaseInOutBack(float step, float duration, float min, float max) {
  return tweenEaseInOutBack(step, duration, min, max, 1);
}
float tweenEaseInOutBack(float step, float duration, float min, float max, float overshoot) {
  float s = overshoot * 1.70158;
  float t = step/duration * 2;
  if( t < 1 ) {
      s *= 1.525f;
      return 0.5f*(t*t*((s+1)*t - s)) * (max-min) + min;
  }
  else {
      t -= 2;
      s *= 1.525f;
      return 0.5f*(t*t*((s+1)*t+ s) + 2)  * (max-min) + min;
  }  
 
  //return (-cos(radians(step/duration*180 - duration/20))+1)/2*(max-min)+min;  
}
