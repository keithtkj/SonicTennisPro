
enum StrokeData {
    BallTrajectory, BallSpeed, CourtAmbience, SwingTiming
}


class TennisStroke {
  
  int timestamp; // Time when the data was recorded
  StrokeData type; // Type of data: Racket angle, stroke power, etc.
  float value; // Numeric value of the data, could represent angle in degrees, power in some unit, or time in milliseconmastds
  String context; // Context of the stroke: "Centre", "Left", "Right"
  int priority; // Priority of the data for sonification (1 is highest, 3 is lowest)
  
  public TennisStroke(JSONObject json) {
    this.timestamp = json.getInt("timestamp");
    
    String typeString = json.getString("type");
    try {
      this.type = StrokeData.valueOf(typeString);
    } catch (IllegalArgumentException e) {
      throw new RuntimeException(typeString + " is not a valid value for enum StrokeData.");
    }
    
    this.value = json.getFloat("value");

    if (json.isNull("context")) {
      this.context = "Centre"; // Default context
    } else {
      this.context = json.getString("context");      
    }
    
    this.priority = json.getInt("priority");   
  }
  
  // Getters
  public int getTimestamp() { return timestamp; }
  public StrokeData getType() { return type; }
  public float getValue() { return value; }
  public String getContext() { return context; }
  public int getPriorityLevel() { return priority; }
  
  // toString method for easy debugging and logging
  public String toString() {
      String output = "Stroke Data - " + getType().toString() + ": ";
      output += "(Context: " + getContext() + ") ";
      output += "(Value: " + getValue() + ") ";
      output += "(Priority: " + getPriorityLevel() + ") ";
      return output;
  }
}
