
import beads.*;
import org.jaudiolibs.beads.*;
import java.util.*;

TextToSpeechMaker ttsMaker; 

// Global variables for sound generation
WavePlayer anglePlayer, powerPlayer;
Gain angleGain, powerGain;
float angleFrequency, powerVolume;
Pulse pulse; // For generating regular pulses
WavePlayer ballPlayer;
Panner ballPanner;
float ballSpeedPitch;

String tennisDataJSON1 = "tennis_session_left.json";
String tennisDataJSON2 = "tennis_session_right.json";
String tennisDataJSON3 = "tennis_session_centre.json";

StrokeDataServer strokeServer;
ArrayList<TennisStroke> tennisStrokes;

TennisExample tennisExample;

PriorityQueue<TennisStroke> strokeQueue;

void setup() {
  size(1000,800);
  
  TennisStrokeComparator strokeComp = new TennisStrokeComparator();
  strokeQueue = new PriorityQueue<TennisStroke>(10, strokeComp);
  
  ac = new AudioContext();
  
  ttsMaker = new TextToSpeechMaker();
  
  String exampleSpeech = "Analyzing tennis stroke.";
  ttsExamplePlayback(exampleSpeech);
  
  strokeServer = new StrokeDataServer();
  tennisExample = new TennisExample();
  strokeServer.addListener(tennisExample);
  
  strokeServer.loadStrokeStream(tennisDataJSON1);
  
  // Initialize the pulse for the metronome
    setupPulse(1.0f); // Start with a 1-second interval
    setupSonification();
    setupBallSonification();
    
    // Load images
    courtImage = loadImage("tennis_court.png"); // Replace with your court image path
    playerAvatar = loadImage("player_avatar.png"); // Replace with your avatar image path

    // Setup UI Elements
    setupUI();
    
    ac.start();
    
   
}

// Initialize sonification in the setup
void setupSonification() {
  angleFrequency = 440; // Default frequency for angle
  powerVolume = 0.5; // Default volume for power

  anglePlayer = new WavePlayer(ac, angleFrequency, Buffer.SINE);
  powerPlayer = new WavePlayer(ac, 440, Buffer.SINE); // Use a constant frequency for power

  angleGain = new Gain(ac, 1, anglePlayer);
  powerGain = new Gain(ac, 1, powerPlayer);

  ac.out.addInput(angleGain);
  ac.out.addInput(powerGain);
}

// Call this in processRacketAngle method
void racketAngleSonification(float angle) {

  println("Racket Angle Sonification: " + angle);  // Debugging print statement
  angleFrequency = map(angle, 0, 180, 200, 800); // Map angle to frequency
  anglePlayer.setFrequency(angleFrequency);
}

// Call this in processStrokePower method
void strokePowerSonification(float power) {
  powerVolume = map(power, 0, 100, 0, 1); // Map power to volume
  powerGain.setGain(powerVolume);
}

private void swingTimingSonification(float timing) {
    float interval = map(timing, 0, 100, 0.5f, 2.0f); // Map timing to an interval range
    updateMetronomeInterval(interval);
}

private void ballTrajectorySonification(String trajectory) {
    float pan = 0; // Center by default
    if (trajectory.equals("Left")) {
        pan = -1; // Pan to left
    } else if (trajectory.equals("Right")) {
        pan = 1; // Pan to right
    }
    ballPanner.setPos(pan);
}

private void ballSpeedSonification(float speed) {
    float pitch = map(speed, 0, 100, 400, 1000); // Map speed to a pitch range
    ballPlayer.setFrequency(pitch);
}




void draw() {
  // Processing events
  
  background(255);

    // Draw the main screen
    drawCourt();

    // Update and draw UI elements
    updateAndDrawUI();
    
    // Direct audio test
    float testFrequency = 440; // Standard A note frequency
    WavePlayer testPlayer = new WavePlayer(ac, testFrequency, Buffer.SINE);
    Gain testGain = new Gain(ac, 1, testPlayer);
    ac.out.addInput(testGain);
    
    
}

void keyPressed() {
  if (key == RETURN || key == ENTER) {
    strokeServer.stopStrokeStream();
    strokeServer.loadStrokeStream(tennisDataJSON2);
    println("**** New tennis data stream loaded ****");
  }
}

class TennisExample implements StrokeDataListener {
  
  public TennisExample() {
    // Setup for tennis data processing
  }
  
  public void strokeDataReceived(TennisStroke stroke) { 
    println("<TennisExample> Stroke data received at " + stroke.getTimestamp() + " ms");

    // Processing different types of tennis strokes
    switch (stroke.getType()) {
      case RacketAngle:
        processRacketAngle(stroke.getValue());
        racketAngleLabel.setText("Racket Angle: " + stroke.getValue());
        break;
      case StrokePower:
        processStrokePower(stroke.getValue());
        strokePowerLabel.setText("Stroke Power: " + stroke.getValue());
        break;
      case SwingTiming:
        processSwingTiming(stroke.getValue());
        swingTimingLabel.setText("Swing Timing: " + stroke.getValue());
        break;
      case BallTrajectory:
        processBallTrajectory(stroke.getContext());
        ballTrajectoryLabel.setText("Ball Trajectory: " + stroke.getContext());
        break;
      case BallSpeed:
        processBallSpeed(stroke.getValue());
        ballSpeedLabel.setText("Ball Speed: " + stroke.getValue());
        break;
      default:
        println("Unknown stroke type");
    }
    
    // Processing different types of tennis strokes and triggering sonification
    switch (stroke.getType()) {
      case RacketAngle:
        racketAngleSonification(stroke.getValue());
        racketAngleLabel.setText("Racket Angle: " + stroke.getValue());
        break;
      case StrokePower:
        strokePowerSonification(stroke.getValue());
        strokePowerLabel.setText("Stroke Power: " + stroke.getValue());
        break;
      case SwingTiming:
        swingTimingSonification(stroke.getValue());
        swingTimingLabel.setText("Swing Timing: " + stroke.getValue());
        break;
      case BallTrajectory:
        ballTrajectorySonification(stroke.getContext());
        ballTrajectoryLabel.setText("Ball Trajectory: " + stroke.getContext());
        break;
      case BallSpeed:
        ballSpeedSonification(stroke.getValue());
        ballSpeedLabel.setText("Ball Speed: " + stroke.getValue());
        break;
      default:
        println("Unknown stroke type");
    }
    
    
  }

  private void processRacketAngle(float angle) {
    // Process and provide feedback on racket angle
    String feedback = "Racket angle: " + angle + " degrees.";
    ttsMaker.createTTSWavFile(feedback);
    // Add more logic as needed
    
    // Add sonification call
    racketAngleSonification(angle);
  }

  private void processStrokePower(float power) {
    // Process and provide feedback on stroke power
    String feedback = "Stroke power: " + power + ".";
    ttsMaker.createTTSWavFile(feedback);
    // Add more logic as needed
    
    // Add sonification call
    strokePowerSonification(power);
  }

  private void processSwingTiming(float timing) {
    // Process and provide feedback on swing timing
    String feedback = "Swing timing: " + timing + ".";
    ttsMaker.createTTSWavFile(feedback);
    // Add more logic as needed
    
    // Example: Map the timing to a suitable interval range for the metronome
    float interval = map(timing, 0, 100, 0.5f, 2.0f); // Adjust these values as needed
    updateMetronomeInterval(interval);
  }

  private void processBallTrajectory(String trajectory) {
    // Process and provide feedback on ball trajectory
    String feedback = "Ball trajectory: " + trajectory + ".";
    ttsMaker.createTTSWavFile(feedback);
    // Add more logic as needed
  }

  private void processBallSpeed(float speed) {
    // Process and provide feedback on ball speed
    String feedback = "Ball speed: " + speed + " units.";
    ttsMaker.createTTSWavFile(feedback);
    // Add more logic as needed
  }
}


void ttsExamplePlayback(String inputSpeech) {
  String ttsFilePath = ttsMaker.createTTSWavFile(inputSpeech);
  println("File created at " + ttsFilePath);
  
  SamplePlayer sp = getSamplePlayer(ttsFilePath, true); 
  ac.out.addInput(sp);
  sp.setToLoopStart();
  sp.start();
  println("TTS: " + inputSpeech);
}


class Pulse {
    AudioContext ac;
    WavePlayer pulsePlayer;
    Gain pulseGain;
    boolean isOn;

    Pulse(AudioContext ac, float interval) {
        this.ac = ac;
        // Create a WavePlayer that plays a pulse
        pulsePlayer = new WavePlayer(ac, 1.0 / interval, Buffer.SQUARE);
        pulseGain = new Gain(ac, 1, pulsePlayer);
        ac.out.addInput(pulseGain);
        isOn = false;
    }

    void start() {
        pulseGain.setGain(0.5f); // Set volume for pulse
        isOn = true;
    }

    void stop() {
        pulseGain.setGain(0); // Mute the pulse
        isOn = false;
    }

    void setInterval(float interval) {
        if (interval > 0) {
            pulsePlayer.setFrequency(1.0 / interval);
        }
    }
}

// Global Pulse object
Pulse metronomePulse;

// Initialize the Pulse object in setup
void setupPulse(float interval) {
    metronomePulse = new Pulse(ac, interval);
}

// To start the metronome pulse
void startMetronome() {
    metronomePulse.start();
}

// To stop the metronome pulse
void stopMetronome() {
    metronomePulse.stop();
}

// Adjust the interval (seconds between pulses)
void updateMetronomeInterval(float interval) {
    metronomePulse.setInterval(interval);
}

void setupBallSonification() {
  ballSpeedPitch = 440; // Default pitch
  ballPlayer = new WavePlayer(ac, ballSpeedPitch, Buffer.SINE);
  ballPanner = new Panner(ac);

  ballPlayer.addInput(ballPanner);
  ac.out.addInput(ballPanner);
}

void processBallTrajectory(String trajectory) {
  float pan = 0; // Center by default
  if (trajectory.equals("Left")) {
    pan = -1; // Pan to left
  } else if (trajectory.equals("Right")) {
    pan = 1; // Pan to right
  }
  ballPanner.setPos(pan);
}

void processBallSpeed(float speed) {
  ballSpeedPitch = map(speed, 0, 100, 400, 1000); // Map speed to pitch
  ballPlayer.setFrequency(ballSpeedPitch);
}

// UI Components
Button scenarioCenterButton, scenarioLeftButton, scenarioRightButton;
Label racketAngleLabel, strokePowerLabel, swingTimingLabel, ballTrajectoryLabel, ballSpeedLabel;
Slider sonificationVolumeSlider;
PImage courtImage, playerAvatar;
String currentScenario = "centre"; // Default scenario

void setupUI() {
    int verticalOffset = 650; // Increase this value to move UI components further down

    // Initialize buttons for scenario selection
    scenarioCenterButton = new Button(50, verticalOffset, 100, 30, "Center Shot");
    scenarioLeftButton = new Button(160, verticalOffset, 100, 30, "Left Shot");
    scenarioRightButton = new Button(270, verticalOffset, 100, 30, "Right Shot");

    // Initialize labels for feedback
    racketAngleLabel = new Label(400, verticalOffset, "Racket Angle: 0");
    strokePowerLabel = new Label(400, verticalOffset + 30, "Stroke Power: 0");
    swingTimingLabel = new Label(550, verticalOffset, "Swing Timing: 0");
    ballTrajectoryLabel = new Label(550, verticalOffset + 30, "Ball Trajectory: Center");
    ballSpeedLabel = new Label(700, verticalOffset, "Ball Speed: 0");

    // Initialize slider for sonification volume
    sonificationVolumeSlider = new Slider(700, verticalOffset + 30, 100, 20, 0, 1);
}


void drawCourt() {
    image(courtImage, 0, 0, width, height - 100);
    image(playerAvatar, width / 2 - 30, height / 2 - 60, 60, 60);
}

void updateAndDrawUI() {
    // Update and draw buttons
    scenarioCenterButton.update();
    scenarioLeftButton.update();
    scenarioRightButton.update();

    // Update and draw labels
    racketAngleLabel.update();
    strokePowerLabel.update();
    swingTimingLabel.update();
    ballTrajectoryLabel.update();
    ballSpeedLabel.update();

    // Update and draw slider
    sonificationVolumeSlider.update();
}

void mouseClicked() {
    if (scenarioCenterButton.isMouseOver()) {
        loadScenario("centre");
        println("center button pressed and working");
    } else if (scenarioLeftButton.isMouseOver()) {
        loadScenario("left");
    } else if (scenarioRightButton.isMouseOver()) {
        loadScenario("right");
    }
}

void loadScenario(String scenario) {
    println("Loading scenario: " + scenario); // Debugging statement
    String jsonFilePath = getJSONFilePathForScenario(scenario);
    strokeServer.stopStrokeStream(); // Stop any previous stroke stream
    strokeServer.loadStrokeStream(jsonFilePath); // Load new scenario data
    // Update UI or other elements as necessary
}

String getJSONFilePathForScenario(String scenario) {
    switch(scenario) {
        case "centre":
        System.out.println("center button working part 2");
            return "tennis_session_centre.json";
        case "left":
            return "tennis_session_left.json";
        case "right":
            return "tennis_session_right.json";
        default:
            return "tennis_session_centre.json";
    }
}

void loadScenarioData(String filePath) {
    println("Loading data from: " + filePath); // Debugging statement
    JSONArray data = loadJSONArray(filePath);
    // Process the data as required for your application
    if (data.size() > 0) {
        println("First data object: " + data.getJSONObject(0)); // Debugging
    }
}

class Button {
    float x, y, w, h;
    String text;
    boolean isOver = false;

    Button(float x, float y, float w, float h, String text) {
        this.x = x; this.y = y; this.w = w; this.h = h; this.text = text;
    }

    void update() {
        isOver = (mouseX > x && mouseX < x + w && mouseY > y && mouseY < y + h);
        if (isOver) {
            fill(220); // Lighter color when the mouse is over the button
        } else {
            fill(200); // Default button color
        }
        rect(x, y, w, h);
        fill(0);
        text(text, x + 10, y + h / 2);
    }

    boolean isMouseOver() {
        return isOver;
    }
}


// Example Label class
class Label {
    float x, y;
    String text;
    Label(float x, float y, String text) {
        this.x = x; this.y = y; this.text = text;
    }
    void update() {
        fill(0);
        text(text, x, y);
    }
    
    void setText(String newText) {
        this.text = newText;
    }
}

// Example Slider class
class Slider {
    float x, y, w, h, minVal, maxVal, currentVal;
    Slider(float x, float y, float w, float h, float minVal, float maxVal) {
        this.x = x; this.y = y; this.w = w; this.h = h;
        this.minVal = minVal; this.maxVal = maxVal;
        this.currentVal = (minVal + maxVal) / 2;
    }
    void update() {
        fill(150);
        rect(x, y, w, h);
        float sliderPos = map(currentVal, minVal, maxVal, x, x + w);
        fill(255, 0, 0);
        ellipse(sliderPos, y + h / 2, 10, 10);
    }
}

/**
import beads.*;
import org.jaudiolibs.beads.*;
import java.util.*;

//to use text to speech functionality, copy text_to_speech.pde from this sketch to yours
//example usage below

//IMPORTANT (notice from text_to_speech.pde):
//to use this you must import 'ttslib' into Processing, as this code uses the included FreeTTS library
//e.g. from the Menu Bar select Sketch -> Import Library... -> ttslib

TextToSpeechMaker ttsMaker; 

//<import statements here>

//to use this, copy notification.pde, notification_listener.pde and notification_server.pde from this sketch to yours.
//Example usage below.

//name of a file to load from the data directory
String eventDataJSON1 = "smarthome2020_morning.json";
String eventDataJSON2 = "smarthome2020_midday.json";
String eventDataJSON3 = "smarthome2020_evening.json";

NotificationServer server;
ArrayList<Notification> notifications;

Example example;

//Comparator<Notification> comparator;
//PriorityQueue<Notification> queue;
PriorityQueue<Notification> q2;

void setup() {
  size(600,600);
  
  NotificationComparator priorityComp = new NotificationComparator();
  
  q2 = new PriorityQueue<Notification>(10, priorityComp);
  
  //comparator = new NotificationComparator();
  //queue = new PriorityQueue<Notification>(10, comparator);
  
  ac = new AudioContext(); //ac is defined in helper_functions.pde
  ac.start();
  
  //this will create WAV files in your data directory from input speech 
  //which you will then need to hook up to SamplePlayer Beads
  ttsMaker = new TextToSpeechMaker();
  
  String exampleSpeech = "Text to speech is okay, I guess.";
  
  ttsExamplePlayback(exampleSpeech); //see ttsExamplePlayback below for usage
  
  //START NotificationServer setup
  server = new NotificationServer();
  
  //instantiating a custom class (seen below) and registering it as a listener to the server
  example = new Example();
  server.addListener(example);
  
  //loading the event stream, which also starts the timer serving events
  server.loadEventStream(eventDataJSON1);
  
  //END NotificationServer setup
  
}

void draw() {
  //this method must be present (even if empty) to process events such as keyPressed()  
}

void keyPressed() {
  //example of stopping the current event stream and loading the second one
  if (key == RETURN || key == ENTER) {
    server.stopEventStream(); //always call this before loading a new stream
    server.loadEventStream(eventDataJSON2);
    println("**** New event stream loaded: " + eventDataJSON2 + " ****");
  }
    
}

//in your own custom class, you will implement the NotificationListener interface 
//(with the notificationReceived() method) to receive Notification events as they come in
class Example implements NotificationListener {
  
  public Example() {
    //setup here
  }
  
  //this method must be implemented to receive notifications
  public void notificationReceived(Notification notification) { 
    println("<Example> " + notification.getType().toString() + " notification received at " 
    + Integer.toString(notification.getTimestamp()) + " ms");
    
    String debugOutput = ">>> ";
    switch (notification.getType()) {
      case Door:
        debugOutput += "Door moved: ";
        break;
      case PersonMoveHome:
        debugOutput += "Person moved at home: ";
        break;
      case PersonMoveWork:
        debugOutput += "Person moved at work: ";
        break;
      case PersonStatus:
        debugOutput += "Co-worker changed their free/busy status: ";
        break;
      case Meeting:
        debugOutput += "Meeting time: ";
        break;
      case ObjectMove:
        debugOutput += "Object moved: ";
        break;
      case ApplianceStateChange:
        debugOutput += "Appliance changed state: ";
        break;
      case PackageDelivery:
        debugOutput += "Package delivered: ";
        break;
      case Message:
        debugOutput += "New message: ";
        break;
    }
    debugOutput += notification.toString();
    //debugOutput += notification.getLocation() + ", " + notification.getTag();
    
    println(debugOutput);
    
   //You can experiment with the timing by altering the timestamp values (in ms) in the exampleData.json file
    //(located in the data directory)
  }
}

void ttsExamplePlayback(String inputSpeech) {
  //create TTS file and play it back immediately
  //the SamplePlayer will remove itself when it is finished in this case
  
  String ttsFilePath = ttsMaker.createTTSWavFile(inputSpeech);
  println("File created at " + ttsFilePath);
  
  //createTTSWavFile makes a new WAV file of name ttsX.wav, where X is a unique integer
  //it returns the path relative to the sketch's data directory to the wav file
  
  //see helper_functions.pde for actual loading of the WAV file into a SamplePlayer
  
  SamplePlayer sp = getSamplePlayer(ttsFilePath, true); 
  //true means it will delete itself when it is finished playing
  //you may or may not want this behavior!
  
  ac.out.addInput(sp);
  sp.setToLoopStart();
  sp.start();
  println("TTS: " + inputSpeech);
}
**/
