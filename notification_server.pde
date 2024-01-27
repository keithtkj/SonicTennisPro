import java.util.Calendar;
import java.util.Timer;
import java.util.TimerTask;
import java.util.ArrayList;
import processing.data.JSONArray;

class StrokeDataServer {
  
  Boolean debugMode = true; // Set to false to turn off println statements for each TennisStroke
  
  Timer timer;
  Calendar calendar;
  private ArrayList<StrokeDataListener> listeners;
  private ArrayList<TennisStroke> currentStrokes;

  public StrokeDataServer() {
    timer = new Timer();
    listeners = new ArrayList<StrokeDataListener>();
    calendar = Calendar.getInstance();
    currentStrokes = new ArrayList<TennisStroke>();
  }
  
 public void loadStrokeStream(String eventDataJSON) {
    if (currentStrokes != null) { // Check if currentStrokes is not null
    
      currentStrokes.clear();
      currentStrokes = this.getStrokeDataFromJSON(loadJSONArray(eventDataJSON));
      
      for (int i = 0; i < currentStrokes.size(); i++) {
        this.scheduleTask(currentStrokes.get(i));
      }
    }
  
  }


  
 public void stopStrokeStream() {
    if (timer != null) {
      timer.cancel();
      timer.purge(); 
    }
    timer = new Timer();
    if (currentStrokes != null) { // Clear the list if it's not null
      currentStrokes.clear();
    }
  }
  
  public ArrayList<TennisStroke> getCurrentStrokes() {
    return currentStrokes;
  }
  
  public ArrayList<TennisStroke> getStrokeDataFromJSON(JSONArray values) {
    ArrayList<TennisStroke> strokes = new ArrayList<TennisStroke>();
    for (int i = 0; i < values.size(); i++) {
      if(debugMode) println(values.getJSONObject(i));
      strokes.add(new TennisStroke(values.getJSONObject(i)));
    }
    return strokes;
  }

  public void scheduleTask(TennisStroke stroke) {
    timer.schedule(new StrokeTask(this, stroke), stroke.getTimestamp());
  }
  
  public void addListener(StrokeDataListener listenerToAdd) {
    listeners.add(listenerToAdd);
  }
  
  public void notifyListeners(TennisStroke stroke) {
    if (debugMode)
      println("<StrokeDataServer> " + stroke.toString());
    for (StrokeDataListener listener : listeners) {
      listener.strokeDataReceived(stroke);
    }
  }
  

  class StrokeTask extends TimerTask {
    
    StrokeDataServer server;
    TennisStroke stroke;
    
    public StrokeTask(StrokeDataServer server, TennisStroke stroke) {
      super();
      this.server = server;
      this.stroke = stroke;
    }
    
    public void run() {
      server.notifyListeners(stroke);
    }
    
  }
}
