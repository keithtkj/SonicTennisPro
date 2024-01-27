

import beads.*;
import org.jaudiolibs.beads.*;
import java.util.*;

import controlP5.*;

ControlP5 cp5;

SamplePlayer shotPlayer;
Envelope shotEnvelope;
Gain shotGain;
float racketAngle = 45; // Default angleanalyzf
float ballSpeed = 10; // Default speed
boolean isRunning = false;
Label racketAngleValueLabel, strokePowerValueLabel;
// Global variables for ball starting positions and velocities
PVector startPositionLeft, startPositionCenter, startPositionRight;
PVector velocityLeft, velocityCenter, velocityRight;
boolean ballMovingTowardsRacket = true;
boolean shouldSwing = false;
int swingCounter = 0;
PVector racketPosition;
// Global Variable for Sonification
float ballTrajectory;
boolean strokePowerSonificationEnabled = false;
Sample ambientSound;
Gain ambientGain;
SamplePlayer ambientPlayer;
boolean ambientSoundPlaying = false;
WavePlayer metronomePlayer;
Gain metronomeGain;
float metronomeInterval = 1.0; // 1 second interval

String startDirection = "center"; // Default start direction
String targetDirection = "center"; // Default target direction

// Ball position and velocity variables
PVector ballPosition;
PVector ballVelocity;
boolean isBallMoving = false;

void setupMetronome() {
    if (ac == null) {
        println("AudioContext not initialized");
        return;
    }

    metronomePlayer = new WavePlayer(ac, 1.0 / metronomeInterval, Buffer.SQUARE);
    metronomeGain = new Gain(ac, 1);
    metronomeGain.addInput(metronomePlayer);
    ac.out.addInput(metronomeGain);
    metronomeGain.setGain(0); // Start muted
}




TextToSpeechMaker ttsMaker; 
String selectedShot = "centre"; // Default scenario


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
//Button runButton;



PriorityQueue<TennisStroke> strokeQueue;



void setup() {
  size(1200,800);
  
  TennisStrokeComparator strokeComp = new TennisStrokeComparator();
  strokeQueue = new PriorityQueue<TennisStroke>(10, strokeComp);
  cp5 = new ControlP5(this);
  ac = new AudioContext();
  
  setupSonification();
  
  ttsMaker = new TextToSpeechMaker();
  // Initialize ball starting positions based on screen width
  startPositionLeft = new PVector(170, -20); // Left corner of the screen
  startPositionCenter = new PVector(width / 2-140, -20); // Center top of the screen
  startPositionRight = new PVector(width-450, -20); // Right corner of the screen

  // Initialize velocities to point towards the racket
  float racketX = width / 2 - 150; // Racket X position
  float racketY = height - 250; // Racket Y position 
  velocityLeft = calculateVelocity(startPositionLeft, racketX, racketY);
  velocityCenter = calculateVelocity(startPositionCenter, racketX, racketY);
  velocityRight = calculateVelocity(startPositionRight, racketX, racketY);
  
  String exampleSpeech = "Welcome to TennisSonicPro Program";
  ttsExamplePlayback(exampleSpeech);
  racketPosition = new PVector(width / 2 - 150, height - 250); 
 
  
  strokeServer = new StrokeDataServer();
  tennisExample = new TennisExample();
  strokeServer.addListener(tennisExample);

  
  cp5.addSlider("racketAngle")
     .setPosition(50, 700)
     .setRange(0, 90) // Racket angle range
     .setValue(45);

  // Creating a slider for the ball speed
  cp5.addSlider("ballSpeed")
     .setPosition(250, 700)
     .setRange(0, 100) // Ball speed range
     .setValue(50);
  
  // Initialize the pulse for the metronome
    setupPulse(1.0f); // Start with a 1-second interval
    //setupSonification();
    setupBallSonification();
    setupMetronome();
    
    // Load images
    courtImage = loadImage("tennis_court.png"); 
  

    // Setup UI Elements
    setupUI();
    updateSonificationButtonLabel();
    
    
    // Start position buttons
    cp5.addButton("startLeft")
       .setPosition(100, 750)
       .setSize(100, 40)
       .setLabel("Start Left")
       .onClick(event -> startBall("left"));

    cp5.addButton("startCenter")
       .setPosition(210, 750)
       .setSize(100, 40)
       .setLabel("Start Center")
       .onClick(event -> startBall("center"));

    cp5.addButton("startRight")
       .setPosition(320, 750)
       .setSize(100, 40)
       .setLabel("Start Right")
       .onClick(event -> startBall("right"));

    // Target position buttons
    cp5.addButton("targetLeft")
       .setPosition(430, 750)
       .setSize(100, 40)
       .setLabel("Target Left")
       .onClick(event -> targetBall("left"));

    cp5.addButton("targetCenter")
       .setPosition(540, 750)
       .setSize(100, 40)
       .setLabel("Target Center")
       .onClick(event -> targetBall("center"));

    cp5.addButton("targetRight")
       .setPosition(650, 750)
       .setSize(100, 40)
       .setLabel("Target Right")
       .onClick(event -> targetBall("right"));

    // Shoot button
    cp5.addButton("shoot")
       .setPosition(760, 750)
       .setSize(100, 40)
       .setLabel("Shoot")
       .onClick(event -> shootBall());

    // Ball Speed Slider
    cp5.addSlider("ballSpeed")
       .setPosition(870, 750)
       .setSize(100, 40)
       .setRange(1, 10) // Min and max speed
       .setValue(5)
       .setLabel("Ball Speed")
       .onRelease(event -> setBallSpeed(cp5.getController("ballSpeed").getValue()));

    // Initialize ball position and velocity
    ballPosition = new PVector(width / 2, -20);
    isBallVisible = false; 
    ballVelocity = new PVector(0, 0); // Initial velocity is zero
    
    cp5.addSlider("strokePower")
   .setPosition(270, 700) 
   .setRange(0, 100) // Range for stroke power
   .setValue(50) // Default value
   .setLabel("Stroke Power");
    
   try {
        Sample ambientSample = SampleManager.sample(sketchPath("data/tennissounds.wav"));
        if (ambientSample == null) {
            throw new Exception("Sample file could not be loaded.");
        }

        ambientPlayer = new SamplePlayer(ac, ambientSample);
        ambientPlayer.setLoopType(SamplePlayer.LoopType.LOOP_FORWARDS);

        ambientGain = new Gain(ac, 1);
        ambientGain.addInput(ambientPlayer);

        
    } catch (Exception e) {
        println("Error loading ambient sound: " + e.getMessage());
    }
    
    try {
        // Load the tennis ball shot sound
        Sample shotSample = SampleManager.sample(sketchPath("data/tennisballshotsound.wav"));
        if (shotSample == null) {
            throw new Exception("Sample file could not be loaded.");
        }

        // Create a SamplePlayer for the shot sound
        shotPlayer = new SamplePlayer(ac, shotSample);
        shotPlayer.setKillOnEnd(true);

        // Create an envelope with an initial value of 0 (silent)
        shotEnvelope = new Envelope(ac, 0);

        // Create a Gain and connect the envelope to it
        shotGain = new Gain(ac, 1);
        shotGain.addInput(shotEnvelope);
        shotGain.addInput(shotPlayer);
    
        // Add the gain to the audio context
        ac.out.addInput(shotGain);

    } catch (Exception e) {
        println("Error loading shot sound: " + e.getMessage());
    }


    
    ac.start();
  
    
   
}
boolean isBallVisible = false;

void triggerBallShotSound() {
    // Clear previous envelope segments
    shotEnvelope.clear();

    // Add segments to the envelope: Quick rise and longer decay
    shotEnvelope.addSegment(1.0, 10); // Quick rise to full volume
    shotEnvelope.addSegment(0.0, 500); // Fade out

    // Start the SamplePlayer
    shotPlayer.setToLoopStart();
    shotPlayer.start();
}

void startBall(String direction) {
  
  
    startDirection = direction;
    isBallVisible = true;  // Ball becomes visible when the game starts

    switch (direction) {
        case "left":
            ballPosition.set(startPositionLeft); // Use the startPositionLeft
            break;
        case "center":
            ballPosition.set(startPositionCenter); // Use the startPositionCenter
            break;
        case "right":
            ballPosition.set(startPositionRight); // Use the startPositionRight
            break;
    }
    ballVelocity.set(0, 0); // Reset the ball's velocity
}

void targetBall(String direction) {
    targetDirection = direction;
  
}

void setBallSpeed(float speed) {
    ballSpeed = speed;
    // The speed will be used to calculate the velocity in shootBall
}

void shootBall() {
    float angle;

    if (startDirection.equals("left") && targetDirection.equals("right")) {
        angle = PI / 4;  // 45 degrees to the right
    } else if (startDirection.equals("right") && targetDirection.equals("left")) {
        angle = 3 * PI / 4;  // 135 degrees to the left
    } else if (startDirection.equals("left") && targetDirection.equals("center")) {
        angle = 2 * PI / 6;  // Diagonally towards the right, but less sharply
    } else if (startDirection.equals("center") && targetDirection.equals("left")) {
        angle = 2 * PI / 3;  // Diagonally towards the left
    } else if (startDirection.equals("center") && targetDirection.equals("right")) {
        angle = PI / 3;  // Diagonally towards the right
    } else if (startDirection.equals("right") && targetDirection.equals("center")) {
        angle = 4 * PI / 6;  // Diagonally towards the left, but less sharply
    } else {
        angle = PI / 2;  // Straight down for any other combination
    }

    // Set the ball's velocity based on the angle and speed
    ballVelocity.set(cos(angle) * ballSpeed, sin(angle) * ballSpeed);
    isBallMoving = true;  // Ball starts moving
     triggerBallShotSound();

}







PVector calculateVelocity(PVector start, float racketX, float racketY) {
  PVector end = new PVector(racketX, racketY);
  if (selectedShot.equals("left")) {
    end.y += 50; // Adjust for the sweet spot on the left side
  } else if (selectedShot.equals("right")) {
    end.y -= 50; // Adjust for the sweet spot on the right side
  }
  PVector velocity = PVector.sub(end, start);
  velocity.normalize(); // Get the direction
  velocity.mult(ballSpeed); // Apply the speed
  return velocity;
}

boolean sonificationInitialized = false;

boolean sonificationAddedToContext = false;

void setupSonification() {
    // Check if sonification has already been initialized
    if (sonificationInitialized) return;

    // Set default values for frequency and volume
    float angleFrequency = 440; // Default frequency for angle
    float powerVolume = 0.5; // Default volume for power

    // Initialize WavePlayers for angle and power
    anglePlayer = new WavePlayer(ac, angleFrequency, Buffer.SINE);
    powerPlayer = new WavePlayer(ac, 440, Buffer.SINE);

    // Initialize Gain objects for angle and power
    angleGain = new Gain(ac, 1);
    angleGain.addInput(anglePlayer);
    angleGain.setGain(0); // Initially mute

    powerGain = new Gain(ac, 1);
    powerGain.addInput(powerPlayer);
    powerGain.setGain(0); // Initially mute

    // Add gains to audio context if not already added
    if (!sonificationAddedToContext) {
        ac.out.addInput(angleGain);
        ac.out.addInput(powerGain);
        sonificationAddedToContext = true;
    }

    // Mark sonification as initialized
    sonificationInitialized = true;
    println("Sonification initialized");
}


// Call this in processRacketAngle method
void racketAngleSonification(float angle) {

//if (!isRunning || anglePlayer == null || angleGain == null) return;
  println("Racket Angle Sonification: " + angle);  // Debugging print statement
  angleFrequency = map(angle, 0, 90, 200, 800); // Map angle to frequency
  anglePlayer.setFrequency(angleFrequency);
}


void racketAngleSonification() {
if (!racketAngleSonificationEnabled) return;

 float angle = cp5.getController("racketAngleSonification").getValue();
 
        angleFrequency = map(angle, 0, 90, 200, 800);
        anglePlayer.setFrequency(angleFrequency);
        angleGain.setGain(0.5); // Adjust the gain as needed
    
}

void strokePowerSonification(float power) {
    if (!strokePowerSonificationEnabled || powerGain == null) return;
    powerVolume = map(power, 0, 100, 0, 1); // Map power to volume
    powerGain.setGain(powerVolume);
}




void strokePowerSonification() {
  //if (!isRunning || powerGain == null) return;
 float power = cp5.getController("strokePowerSonification").getValue();
    if (power != 50) { // Check if slider has been moved from the initial value
        powerVolume = map(power, 0, 100, 0, 1);
        powerGain.setGain(powerVolume);
    }
  
   
}


void swingTimingSonification(float timing) {
    float interval = map(timing, 0, 100, 0.5, 2.0); // Map timing to interval
    updateMetronomeInterval(interval);
}


private void ballTrajectorySonification(String trajectory) {


     ballTrajectory = cp5.getController("ballTrajectory").getValue();
    // Debugging print statement
    println("Ball Trajectory Sonification: " + ballTrajectory);

    // Exaggerating the panning effect
    float exaggeratedPan = int(trajectory) *20; // Multiply by 2 or more to make the effect more noticeable
    exaggeratedPan = constrain(exaggeratedPan, -1, 1); // Constrain to the range -1 to 1

    ballPanner.setPos(exaggeratedPan);
    
   
}

void updateSonificationButtonLabel() {
    String label = ballTrajectorySonificationEnabled ? "Sonification: On" : "Sonification: Off";
    cp5.getController("toggleBallTrajectorySonification").setLabel(label);
}


private void ballTrajectorySonification() {
  
  if (ballPlayer == null || ballPanner == null) {
        if (ballTrajectorySonificationEnabled) {
            setupBallSonification();
        } else {
            return;
        }
    }
    

    // Adjust the panning based on the ball trajectory
    ballTrajectory = cp5.getController("ballTrajectory").getValue();
    float exaggeratedPan = ballTrajectory * 8;
    exaggeratedPan = constrain(exaggeratedPan, -1, 1);
    ballPanner.setPos(exaggeratedPan);
}

private void ballSpeedSonification(float speed) {
  if (!ballSpeedSonificationEnabled) return;
  if (!isRunning || !ballSpeedSonificationEnabled) return;
    float pitch = map(speed, 0, 100, 400, 1000); // Map speed to a pitch range
    ballPlayer.setFrequency(pitch);
}

boolean ballSpeedSonificationEnabled = false;

private void ballSpeedSonification() {
if (!ballSpeedSonificationEnabled || ballPlayer == null) return;
 // if (!isRunning || ballPlayer == null) return;

    float speed = cp5.getController("ballSpeedSonification").getValue();
    ballSpeedPitch = map(speed, 0, 100, 400, 1000); // Map speed to pitch
    ballPlayer.setFrequency(ballSpeedPitch);
    //ballPlayer.setGain(0.5);
    
    /**
    void racketAngleSonification() {
if (!racketAngleSonificationEnabled) return;

 float angle = cp5.getController("racketAngleSonification").getValue();
 
        angleFrequency = map(angle, 0, 90, 200, 800);
        anglePlayer.setFrequency(angleFrequency);
        angleGain.setGain(0.5); // Adjust the gain as needed
    
}
**/
}







float ballX, ballY;
float ballSpeedX, ballSpeedY;
boolean ballInMotion = false;

final float courtWidth = 800; // Adjust as per your court's dimensions
final float courtHeight = 400; // Adjust as per your court's dimensions
final float netHeight = 100; // Adjust as per your net's height
final float gravity = 0.98; // Gravity constant
// Variables for ball physics
boolean ballDescending = false;

void drawBall() {
    if (ballInMotion && isRunning) {
        // Update ball position based on velocity
        
        ballX += ballSpeedX;
        ballY += ballSpeedY;
        
        /**
         // Check if the ball is close to the racket
        if (!shouldSwing && ballMovingTowardsRacket && abs(ballY - (height - 250)) < 50) {
            shouldSwing = true; // Trigger the racket swing
            swingCounter = 10; // Set the duration for the swing
        }
        
        
         if (selectedShot.equals("right") && !shouldSwing && ballMovingTowardsRacket && abs(ballX - racketPosition.x) < 50) {
        // Adjust the condition for the right shotbal
        shouldSwing = true;
        swingCounter = 10;
    }
    **/
        
       if (checkCollisionWithRacket()) {
            if (isSpacePressed) {
                // Racket swings and hits the ball
                handleCollision(); // Handle the collision logic
               // ballSpeedY = -abs(ballSpeedY); // Reverse the Y-direction of the ball
                ballMovingTowardsRacket = false; // Ball now moves away from the racket
            } else {
                // No swing or miss - ball continues moving downwards and disappears
                if (isBallMoving && checkCollisionWithRacket()) {
            handleCollision();
        }
                if (ballY > height) {
                    resetBall(); // Reset ball if it goes out of bounds
                }
            }
        }

    /**
        if (shouldSwing && swingCounter > 0) {
            swingRacket();

            if (swingCounter <= 0) {
                // Adjust the ball's direction based on the racket's angle
                float newAngle = radians(racketAngle); // Convert angle to radians
                ballSpeedX = cos(newAngle) * ballSpeed;
                ballSpeedY = -sin(newAngle) * ballSpeed;

                ballMovingTowardsRacket = !ballMovingTowardsRacket;
            }
        } else {
            shouldSwing = false;
        }
        **/
        
        // Check boundaries and adjust ball movement
        if (ballX < 0 || ballX > width) ballSpeedX = -ballSpeedX;
        if (ballY < 0 || ballY > height) resetBall(); // Reset ball if it goes out of bounds

        // Draw the ball
        ellipse(ballX, ballY, 20, 20);
    }
}

boolean isLeftPressed = false;
boolean isRightPressed = false;
boolean isSpacePressed = false;

void updateRacketMovement() {
    if (isLeftPressed) {
        racketPosition.x -= 5; // Adjust speed as needed
    }
    if (isRightPressed) {
        racketPosition.x += 5; // Adjust speed as needed
    }
}



void resetBall() {
    // Reset ball to initial position and stop its movement
    ballInMotion = false;
    ballX = startPositionCenter.x;
    ballY = startPositionCenter.y;
    ballSpeedX = 0;
    ballSpeedY = 0;
    
    isBallVisible = false;
}

// Additional global variables
boolean isSwinging = false;
float swingPower = 0;
float maxSwingPower = 100; // Maximum power of swing
float swingIncrement = 5; // Increase in power per frame
float MAX_SWING_ANGLE_INCREMENT = 30;

// Constants
final float MAX_SWING_ANGLE = 190;  // Perpendicular angle
final float ANGLE_INCREMENT = 5;   // Speed of the angle change

void swingRacket() {
    if (isSpacePressed) {
        // Retrieve the swing power from the "ballSpeed" slider
        swingPower = cp5.getController("ballSpeed").getValue();
        // Ensure that swingPower is within the expected range (0 to maxSwingPower)
        swingPower = cp5.getController("strokePower").getValue();

        // Use swingPower to influence the racket swing
        // Change the racket angle based on swingPower
        racketAngle += map(swingPower, 0, maxSwingPower, ANGLE_INCREMENT, MAX_SWING_ANGLE_INCREMENT);
        racketAngle = constrain(racketAngle, 0, MAX_SWING_ANGLE);
    } else {
        // When the spacebar is released, reset the racket angle and swingPower
        racketAngle = 45;
        swingPower = 0;
    }
}



void executeSwing() {
   
    racketAngle += map(swingPower, 0, maxSwingPower, 5, 20); 

    // Implement opposite racket movement
    if (racketPosition.x < width / 2) {
        racketPosition.x += swingPower; // Move right if on the left side
    } else {
        racketPosition.x -= swingPower; // Move left if on the right side
    }

    // Reset the swing power after the swing is executed
    swingPower = 0;
}



boolean checkCollisionWithRacket() {
  // translate(width / 2 - 150, height - 250); racket position so adjust range given this
  // Calculate the closest point on the racket to the ball
 // float closestX = constrain(ballX, width / 2 - 130, width / 2 + 130); // Racket's width range
  //float closestY = constrain(ballY, height - 50 - 180, height - 50 + 280); // Racket's height range
  
  // Racket dimensions
float racketWidth = 20;
float racketHeight = 100;

  float racketX = racketPosition.x;
  float racketY = racketPosition.y;

// Calculate the closest point on the racket to the ball
float closestX = constrain(ballX, racketX - racketWidth / 2, racketX + racketWidth / 2);
float closestY = constrain(ballY, racketY - racketHeight / 2, racketY + racketHeight / 2);


float distanceX = ballX - closestX;
    float distanceY = ballY - closestY;
    float distance = distanceX * distanceX + distanceY * distanceY;
    // Check collision with sweet spot
    return distance < 100 && (ballY > racketY - 50 && ballY < racketY + 50);
    
    // return True; this works and ball is hit back
}




void handleCollision() {
    // Calculate the new angle of the ball
    float angleOfReflection = radians(racketAngle);
    ballSpeedX = cos(angleOfReflection) * ballSpeed;
    ballSpeedY = -sin(angleOfReflection) * ballSpeed;
    ballVelocity.set(cos(angleOfReflection) * ballSpeed, -sin(angleOfReflection) * ballSpeed);
}




// Call this method to start the ball's motion (e.g., when the racket hits the ball)
void hitBall() {
  if (isRunning) {
    ballInMotion = true;
    ballMovingTowardsRacket = true; // Ball starts moving towards the racket

    // Adjust the speed for slower movement
    ballSpeedX = cos(radians(racketAngle)) * ballSpeed * 0.05; // Reduced speed for slower movement
    ballSpeedY = -sin(radians(racketAngle)) * ballSpeed * 0.05;
  }
}



void drawRacket() {
    pushMatrix(); // Start a new drawing state

    // Translate to the racket's position
    translate(racketPosition.x, racketPosition.y);

    // Rotate the racket based on the angle
    rotate(radians(-racketAngle)-0.785);

    // Draw the racket
    fill(255, 0, 0); // Red color for racket
    rectMode(CENTER);
    rect(0, 0, 20, 140); // Increased racket length

    // Draw sweet spots for backhand and forehand
    fill(0, 255, 0); // Green color for sweet spots
    rect(0, 50, 20, 27); // Sweet spot for backhand
   // rect(0, -50, 20, 27); // Sweet spot for forehand

    popMatrix(); // Restore the previous drawing state
}


void updateRacketPosition() {
  float centerX = width / 2 - 150;
     if (selectedShot.equals("left")) {
        float targetX = ballX - 30; // Adjust this value for the left racket
       // racketPosition.x = lerp(racketPosition.x, targetX, 0.1); // Lerp for the left racket
        racketPosition.x = lerp(racketPosition.x, centerX, 0.05);
       
    } 
    if (selectedShot.equals("right")) {
        // Adjust the target X position based on the ball's position
        float targetX = ballX + 30; // Modify this value as needed
        //racketPosition.x = lerp(racketPosition.x, targetX, 0.1); // Use lerp to smoothly move the racket
        //racketPosition.x = width - 100;
        racketPosition.x = lerp(racketPosition.x, centerX, 0.01);
    }
    // Add similar logic for other scenarios if needed
}

boolean isUpPressed = false;
boolean isDownPressed = false;



void keyPressed() {
    if (key == CODED) {
        if (keyCode == LEFT) {
            isLeftPressed = true;
        } else if (keyCode == RIGHT) {
            isRightPressed = true;
        } else if (keyCode == UP) {
            isUpPressed = true;
        } else if (keyCode == DOWN) {
            isDownPressed = true;
        }
    }
    /**
    if (key == ' ') {
        isSpacePressed = true;
        // Start the swing, increase power or angle
        if (isBallMoving && checkCollisionWithRacket()) {
            handleCollision();
        }
    }
    **/
}

void keyReleased() {
    if (key == CODED) {
        if (keyCode == LEFT) {
            isLeftPressed = false;
        } else if (keyCode == RIGHT) {
            isRightPressed = false;
        } else if (keyCode == UP) {
            isUpPressed = false;
        } else if (keyCode == DOWN) {
            isDownPressed = false;
        }
    }
    if (key == ' ') {
        isSpacePressed = false;
        // Release the swing, apply effect to ball, change direction
        if (isBallMoving && checkCollisionWithRacket()) {
            handleCollision();
        }
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
            case SwingTiming:
                processSwingTiming(stroke.getValue());
                swingTimingLabel.setText("Swing Timing: " + stroke.getValue());
                swingTimingSonification(stroke.getValue()); 
                break;
            case BallTrajectory:
                processBallTrajectory(stroke.getContext());
                ballTrajectoryLabel.setText("Ball Trajectory: " + stroke.getContext());
                ballTrajectorySonification(stroke.getContext()); 
                break;
            case BallSpeed:
                processBallSpeed(stroke.getValue());
                ballSpeedLabel.setText("Ball Speed: " + stroke.getValue());
                ballSpeedSonification(stroke.getValue()); 
                break;
            case CourtAmbience:
               
                processCourtAmbience(stroke.getValue());
              
                break;
            default:
                println("Unknown stroke type");
        }
    }
    
   
     private void processCourtAmbience(float ambience) {
   
    ambientVolumeChanged(ambience);
  }
    
  

  private void processRacketAngle(float angle) {
    // Process and provide feedback on racket angle
    String feedback = "Racket angle: " + angle + " degrees.";
     racketAngleValueLabel.setText("Angle: " + angle);
    ttsMaker.createTTSWavFile(feedback);

    racketAngleSonification(angle);
  }

 private void processStrokePower(float power) {
    // Process and provide feedback on stroke power
    String feedback = "Stroke power: " + power + ".";
    ttsMaker.createTTSWavFile(feedback);
    strokePowerValueLabel.setText("Power: " + power);
 
    if (strokePowerSonificationEnabled) {
        strokePowerSonification(power);
    }
}


  private void processSwingTiming(float timing) {
    // Process and provide feedback on swing timing
    String feedback = "Swing timing: " + timing + ".";
    ttsMaker.createTTSWavFile(feedback);
 
    float interval = map(timing, 0, 100, 0.5f, 2.0f); // Adjust these values as needed
    updateMetronomeInterval(interval);
  }

  void processBallTrajectory(String trajectory) {
    if (!ballTrajectorySonificationEnabled) return;
    float pan = 0; // Center by default
    if (trajectory.equals("Left")) {
        pan = -2; // Pan to left
    } else if (trajectory.equals("Right")) {
        pan = 2; // Pan to right
    }
    ballPanner.setPos(pan);
}

  void processBallSpeed(float speed) {
    ballSpeedPitch = map(speed, 0, 100, 400, 1000); // Higher speed = higher pitch
    ballPlayer.setFrequency(ballSpeedPitch);
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

void startMetronome() {
    if (metronomeGain != null) {
        metronomeGain.setGain(0.5); // You can adjust this value as needed
    }
}


void stopMetronome() {
    metronomeGain.setGain(0);
}

void updateMetronomeInterval(float interval) {
    if (metronomePlayer != null && metronomeGain != null) {
        metronomePlayer.setFrequency(1.0 / interval);
        metronomeGain.setGain(0.5); // Ensure the metronome volume is set
        startMetronome(); // Start playing the metronome
    } else {
        println("Metronome objects not initialized");
    }
    
    if (!metronomeSonificationEnabled){
      stopMetronome();
    }
}




Gain ballSpeedGain;

void setupBallSonification() {
    if (ballPlayer == null) {
        ballSpeedPitch = 440; // Default pitch
        ballPlayer = new WavePlayer(ac, ballSpeedPitch, Buffer.SAW);
        ballPanner = new Panner(ac);
        ballPanner.addInput(ballPlayer);
       // ballPlayer.setFrequency(0);
       //ac.out.addInput(ballPanner);
       

        // Initialize the Gain for ballPlayer
        ballSpeedGain = new Gain(ac, 1, ballPanner);
        ballSpeedGain.addInput(ballPanner);
        ballSpeedGain.setGain(0); // Start muted
        ac.out.addInput(ballSpeedGain);
    }
}




void processBallTrajectory(String trajectory) {
  float pan = 0; // Center by default
  if (trajectory.equals("Left")) {
    pan = -2; // Pan to left
  } else if (trajectory.equals("Right")) {
    pan = 2; // Pan to right
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
//Slider sonificationVolumeSlider;
PImage courtImage, playerAvatar;
String currentScenario = "centre"; // Default scenario
 Label leftLabel;
    Label rightLabel;
Label trajectorysonification;
boolean ballTrajectorySonificationEnabled = false; // Default off


void draw() {
    background(255);

    // Draw the main screen
    updateRacketPosition();
    drawCourt();

    // Update and draw UI elements
    updateAndDrawUI();
    //runButton.update();

// Sonify the distance to the racket as a beat
   if (ballInMotion && isRunning) {
    float distanceToRacket = abs(ballY - (height - 250)); // Height - 250 is the racket's Y position
    float beatInterval = map(distanceToRacket, 0, height, 0.1f, 1.0f); // Closer = faster beat
    updateMetronomeInterval(beatInterval);
}
 ballTrajectoryLabel.update();
 
    leftLabel.update();
    rightLabel.update();

if (ballTrajectorySonificationEnabled) {
        ballTrajectorySonification();
    }
    
    if(racketAngleSonificationEnabled){
      racketAngleSonification();
    }
    if (selectedShot.equals("left") && isBallMoving && checkCollisionWithRacket()) {
        handleCollision(); // Handle the collision and swing the racket
        shouldSwing = false; // Reset the swing flag
    }
    
    if (isUpPressed && racketAngle < MAX_SWING_ANGLE+360) {
        racketAngle += ANGLE_INCREMENT;
    }
    if (isDownPressed && racketAngle > 0) {
        racketAngle -= ANGLE_INCREMENT;
    }
    println("Racket Angle: " + racketAngle);

if(ballSpeedSonificationEnabled) {
  ballSpeedSonification();
}

if (isBallMoving && isBallVisible) {
        handleBallMovementAndCollision();
    }
    
    if(isBallMoving && isBallVisible && checkCollisionWithRacket()){
      handleCollision();
    }
  
    //strokePowerSonification();
    // Drawing static elements like racket and ball
    drawRacket();
    drawBall();
    updateRacketMovement();
    swingRacket();
    trajectorysonification.update();
   // racketanglesonification.update();
    ballSpeedSonificationLabel.update();
   // strokepowerSonificationLabel.update();
    courtsoundsSonificationLabel.update();
    metronomeIntervalLabel.update();
    instructions.update();
    instructions2.update();
    instructions3.update();
    instructions4.update();
    ballSpeedTitleLabel.update();
    manualinstructions.update();
    
    if (isBallMoving && isBallVisible) {
        ballPosition.add(ballVelocity);

        // Check if the ball reaches the bottom of the screen
        if (ballPosition.y > height) {
            isBallMoving = false; // Stop the ball
            // Optionally reset the ball position
            ballPosition.set(width / 2, -20);
        }

        // Draw the ball if it is moving
        if (isBallMoving) {
            ellipse(ballPosition.x, ballPosition.y, 20, 20);
        }
        
         fill(255, 215, 0); // Set fill color (example: gold)
        ellipse(ballPosition.x, ballPosition.y, 20, 20);
    }

    ellipse(ballPosition.x, ballPosition.y, 20, 20);
    
}
void handleBallMovementAndCollision() {
    ballPosition.add(ballVelocity);

    // Check for collision with the racket
    if (checkCollisionWithRacket()) {
        if (isSpacePressed) {
            // Change ball direction on racket hit
            ballVelocity.y = -abs(ballVelocity.y);
        } else {
            // Let the ball fall off screen if not hit
            handleCollision();
            if (ballPosition.y > height) {
                isBallMoving = false;
                resetBall();
            }
        }
    }

    // Draw the ball
    ellipse(ballPosition.x, ballPosition.y, 20, 20);
}

boolean metronomeSonificationEnabled = false; 
boolean racketAngleSonificationEnabled = false;
Label racketanglesonification;
Label ballSpeedSonificationLabel;
Label strokepowerSonificationLabel;
Label courtsoundsSonificationLabel;
Label metronomeIntervalLabel;
Label instructions;
Label instructions2;
Label instructions3;
Label instructions4;
Label ballSpeedTitleLabel;
Label manualinstructions;


void resetSonification() {
    // Stop and mute the ambient player
    if (ambientPlayer != null) {
        ambientPlayer.pause(true);
       
    }

    // Stop and mute the metronome player
    if (metronomePlayer != null) {
        metronomePlayer.pause(true);
       
    }

    // Stop and mute the angle player
    if (anglePlayer != null) {
        anglePlayer.pause(true);
      
    }

    // Stop and mute the power player
    if (powerPlayer != null) {
        powerPlayer.pause(true);
        
    }

    // Stop and mute the ball player
    if (ballPlayer != null) {
        ballPlayer.pause(true);
        
    }
}



void setupUI() {

    int panelX = 1020; // X position of the vertical panel, further to the right
    int panelY = 20;   // Starting Y position of the panel elements
    int buttonWidth = 230;
    int buttonHeight = 30;
    int labelWidth = 150;
    int labelHeight = 20;
    int sliderWidth = 150;
    int sliderHeight = 20;
    int verticalSpacing = 40; // Space between each UI element
    
    ballSpeedTitleLabel = new Label(880, 735, "Adjust Ball Speed: ");
    manualinstructions = new Label(440, 735, "Choose start and target positions to set the trajectory. Move slider to adjust ball speed. Press 'Shoot' to launch the ball.");
    racketAngleValueLabel = new Label(70, 700, "Angle:");
    strokePowerValueLabel = new Label(230, 700, "Power:");
    instructions = new Label(450, 690, "");
    instructions2 = new Label(450, 685, "align incoming ball with racket's sweet spot by using left/right arrow keys to move racket horizontally");
    instructions3 = new Label(450, 660, "");
    instructions4 = new Label(450, 665, "goal: help beginner players master hitting the ball with racket's sweet spot");
    
    cp5.addButton("Reset")
       .setPosition(950, panelY + 4 * verticalSpacing-50) 
       .setSize(150, 30)
       .onClick(new CallbackListener() {
            public void controlEvent(CallbackEvent event) {
                resetProgram();
               resetSonification();
            }
        });
        
         trajectorysonification = new Label(panelX, panelY + verticalSpacing * 4 + 290, "Ball Trajectory: ");
     cp5.addSlider("ballTrajectory")
       .setPosition(panelX -70, panelY + verticalSpacing * 4 + 300)
       .setSize(200, 20)
       .setRange(-1, 1)
       .setValue(0)
       .onChange(new CallbackListener() {
            public void controlEvent(CallbackEvent event) {
              ambientPlayer.pause(false);
metronomePlayer.pause(false);
 powerPlayer.pause(false);
ballPlayer.pause(false);
                ballTrajectorySonification();
            }
        });
        leftLabel = new Label(panelX - 100, panelY + verticalSpacing * 4 + 308, "L"); // Adjust position as needed
     rightLabel = new Label(panelX + 145, panelY + verticalSpacing * 4 + 308, "R");
     // Add a toggle button for ball trajectory sonification
    cp5.addButton("toggleBallTrajectorySonification")
   .setPosition(panelX+40, panelY + verticalSpacing * 4 + 300-20)
   .setSize(100, 15)
   .setLabel("Sonification: Off")
   .onClick(new CallbackListener() {
        public void controlEvent(CallbackEvent event) {
            ballTrajectorySonificationEnabled = !ballTrajectorySonificationEnabled;
            String label = ballTrajectorySonificationEnabled ? "Sonification: On" : "Sonification: Off";
            
            ambientPlayer.pause(false);
metronomePlayer.pause(false);
 powerPlayer.pause(false);
ballPlayer.pause(false);
            cp5.getController("toggleBallTrajectorySonification").setLabel(label);

            if (ballTrajectorySonificationEnabled) {
             
       ac.out.addInput(ballPanner);
                startSonification();
            } else {
                stopSonification();
                ballPlayer.setFrequency(0);
            }
        }
    });

/**
     racketanglesonification = new Label(panelX, panelY + verticalSpacing * 4 + 340, "Racket Angle: ");
 cp5.addSlider("racketAngleSonification")
       .setPosition(panelX -70, panelY + verticalSpacing * 4 + 350)
       .setSize(200, 20)
       .setRange(0, 90)
       .setValue(45);

    cp5.addButton("toggleRacketAngleSonification")
   .setPosition(panelX+40, panelY + verticalSpacing * 4 + 300+30)
   .setSize(100, 15)
   .setLabel("Sonification: Off")
   .onClick(new CallbackListener() {
        public void controlEvent(CallbackEvent event) {
            racketAngleSonificationEnabled = !racketAngleSonificationEnabled;
            updateRacketAngleSonificationButtonLabel();
            if (racketAngleSonificationEnabled) {
                racketAngleSonification(cp5.getController("racketAngle").getValue());
            } else {
                stopRacketAngleSonification();
            }
        }
    });
**/

 ballSpeedSonificationLabel = new Label(panelX, panelY + verticalSpacing * 4 + 390, "Ball Speed: ");
cp5.addSlider("ballSpeedSonification")
   .setPosition(panelX - 70, panelY + verticalSpacing * 4 + 400)
   .setSize(200, 20)
   .setRange(0, 100)
   .setValue(50);
   
    
  cp5.addButton("toggleBallSpeedSonification")
   .setPosition(panelX + 40, panelY + verticalSpacing * 4 + 300+80)
   .setSize(100, 15)
   .setLabel("Sonification: Off")
   .onClick(new CallbackListener() {
        public void controlEvent(CallbackEvent event) {
            ballSpeedSonificationEnabled = !ballSpeedSonificationEnabled;
            
            ambientPlayer.pause(false);
metronomePlayer.pause(false);
 powerPlayer.pause(false);
ballPlayer.pause(false);
            updateBallSpeedSonificationButtonLabel();
            if (ballSpeedSonificationEnabled) {
                ballSpeedGain.setGain(0.5); // Or any desired volume level
            } else {
                ballSpeedGain.setGain(0); // Mute the sound
                ballPlayer.setFrequency(0);
            }
        }
    });



      
       /**
       
       strokepowerSonificationLabel = new Label(panelX, panelY + verticalSpacing * 4 + 440, "Stroke Power: ");
          // Stroke Power Sonification Slider
    cp5.addSlider("strokePowerSonification")
       .setPosition(panelX - 70, panelY + verticalSpacing * 4 + 450)
       .setSize(200, 20)
       .setRange(0, 100)
       .setValue(50)
       .onChange(new CallbackListener() {
            public void controlEvent(CallbackEvent event) {
                strokePowerSonification(cp5.getController("strokePowerSonification").getValue());
            }
        });

    cp5.addButton("toggleStrokePowerSonification")
    .setPosition(panelX + 40, panelY + verticalSpacing * 4 + 430)
    .setSize(100, 15)
    .setLabel("Sonification: Off") // Initial label
    .onClick(new CallbackListener() {
         public void controlEvent(CallbackEvent event) {
             strokePowerSonificationEnabled = !strokePowerSonificationEnabled;
             updateStrokePowerSonificationButtonLabel();
             if (strokePowerSonificationEnabled) {
                 strokePowerSonification(cp5.getController("strokePowerSonification").getValue());
             } else {
                 powerGain.setGain(0); // Mute the sonification
             }
         }
     });
     **/


courtsoundsSonificationLabel = new Label(panelX-10, panelY + verticalSpacing * 4 + 440, "Court Ambience: ");
cp5.addSlider("ambientVolume")
       .setPosition(panelX - 70, panelY + verticalSpacing * 4 + 450)
       .setRange(0, 100) // Volume range from 0 (mute) to 1 (full volume)
       .setValue(50) // Default value
       .setSize(200, 20)
       .setLabel("Court Ambience: ")
       .onChange(new CallbackListener() {
            public void controlEvent(CallbackEvent event) {
              
              ambientPlayer.pause(false);
metronomePlayer.pause(false);
 powerPlayer.pause(false);
ballPlayer.pause(false);
                ambientVolumeChanged(cp5.getController("ambientVolume").getValue());
            }
        });
        
   cp5.addButton("toggleAmbientSound")
       .setPosition(panelX + 40, panelY + verticalSpacing * 4 + 432)
       .setSize(100, 15)
       .setLabel("Sonification: Off")
       .onClick(new CallbackListener() {
            public void controlEvent(CallbackEvent event) {
                ambientSoundPlaying = !ambientSoundPlaying;
                updateAmbientSoundState();
            }
        });
        
         metronomeIntervalLabel = new Label(panelX, panelY + verticalSpacing * 4 + 340, "Swing Timing: ");
    cp5.addSlider("metronomeInterval")
       .setPosition(panelX -70, panelY + verticalSpacing * 4 + 350)
       .setSize(200, 20)
       .setRange(0.0, 2.0) // Range for metronome interval (seconds)
       .setValue(1.0)
       .onChange(new CallbackListener() {
            public void controlEvent(CallbackEvent event) {
                float interval = cp5.getController("metronomeInterval").getValue();
                updateMetronomeInterval(interval);
                
            }
        });
        
        
  cp5.addButton("toggleMetronomeSonification")
       .setPosition(panelX+40, panelY + verticalSpacing * 4 + 300+30) 
       .setSize(100, 15)
       .setLabel("Sonification: Off")
       .onClick(new CallbackListener() {
            public void controlEvent(CallbackEvent event) {
                metronomeSonificationEnabled = !metronomeSonificationEnabled;
                updateMetronomeSonificationButtonLabel();
                 if (!metronomeSonificationEnabled){
      stopMetronome();
    } else {
      startMetronome();
    }
            }
        });

       
       

    // Initialize buttons for scenario selection
    scenarioCenterButton = new Button(panelX, panelY, buttonWidth, buttonHeight, "Position: Centre, Incoming Ball: Centre");
    scenarioLeftButton = new Button(panelX, panelY + verticalSpacing, buttonWidth, buttonHeight, "Position: Left, Incoming Ball: Left");
    scenarioRightButton = new Button(panelX, panelY + 2 * verticalSpacing, buttonWidth, buttonHeight, "Position: Right, Incoming Ball: Right");
    //runButton = new Button(panelX, panelY + 3 * verticalSpacing, buttonWidth, buttonHeight, "Run");

    // Vertical offset for labels
    int labelOffset = panelY + 4 * verticalSpacing;

    // Initialize labels for feedback
    racketAngleLabel = new Label(panelX, labelOffset, "Racket Angle: 0");
    strokePowerLabel = new Label(panelX, labelOffset + verticalSpacing, "Stroke Power: 0");
    swingTimingLabel = new Label(panelX, labelOffset + 2 * verticalSpacing, "Swing Timing: 0");
    ballTrajectoryLabel = new Label(panelX, labelOffset + 3 * verticalSpacing, "Ball Trajectory: Center");
    ballSpeedLabel = new Label(panelX, labelOffset + 4 * verticalSpacing, "Ball Speed: 0");
    Label ballTrajectoryLabel2 = new Label(panelX, panelY + verticalSpacing * 4 - 20, "Ball Trajectory:");

    // Vertical offset for slider
    int sliderOffset = labelOffset + 5 * verticalSpacing;

    // Initialize slider for sonification volume
   // sonificationVolumeSlider = new Slider(panelX, sliderOffset, sliderWidth, sliderHeight, 0, 1);
}

void updateMetronomeSonificationButtonLabel() {
    String label = metronomeSonificationEnabled ? "Sonification: On" : "Sonification: Off";
    cp5.getController("toggleMetronomeSonification").setLabel(label);
}

void updateAmbientSoundState() {
    if (ambientSoundPlaying) {
        ambientPlayer.start();  // Only start here
        ac.out.addInput(ambientGain);
        cp5.getController("toggleAmbientSound").setLabel("Sonification: On");
    } else {
        ambientPlayer.pause(true);  // Pause when needed
        cp5.getController("toggleAmbientSound").setLabel("Sonification: Off");
    }
}


void ambientVolumeChanged(float value) {
    if (!ambientSoundPlaying) return;

    float volume = map(value, 0, 100, 0, 1);
    ambientGain.setGain(volume);
}




void updateStrokePowerSonificationButtonLabel() {
    String label = strokePowerSonificationEnabled ? "Sonification: On" : "Sonification: Off";
    cp5.getController("toggleStrokePowerSonification").setLabel(label);
}

void updateBallSpeedSonificationButtonLabel() {
    String label = ballSpeedSonificationEnabled ? "Sonification: On" : "Sonification: Off";
    cp5.getController("toggleBallSpeedSonification").setLabel(label);
}

void stopBallSpeedSonification() {
    if (ballPlayer != null) {
        ballPlayer.setFrequency(0); // Effectively silence it
    }
}


void stopRacketAngleSonification() {
    if (angleGain != null) {
        angleGain.setGain(0);
    }
}


void updateRacketAngleSonificationButtonLabel() {
    String label = racketAngleSonificationEnabled ? "Sonification: On" : "Sonification: Off";
    cp5.getController("toggleRacketAngleSonification").setLabel(label);
}

void startSonification() {
    if (!sonificationInitialized) {
        setupSonification();
    }
  
    // Activate angle sonification
    if (angleGain != null) {
        angleGain.setGain(1); // Set a suitable gain level
    }

    // Activate power sonification
    if (powerGain != null) {
        powerGain.setGain(1); // Set a suitable gain level
    }

    // Activate ball trajectory sonification

      
      //  ballPanner.setPos(0); // Set the initial position
      // ballPlayer.setFrequency(440);
        ballTrajectory = cp5.getController("ballTrajectory").getValue();
    // Debugging print statement

    // Exaggerating the panning effect
    float exaggeratedPan = ballTrajectory *20; // Multiply by 2 or more to make the effect more noticeable
    exaggeratedPan = constrain(exaggeratedPan, -1, 1); // Constrain to the range -1 to 1

    ballPanner.setPos(exaggeratedPan);
    
}

void stopSonification() {
    // Mute angle and power sonification
    if (angleGain != null) {
        angleGain.setGain(0);
    }
    if (powerGain != null) {
        powerGain.setGain(0);
    }

    // Mute ball trajectory sonification
    if (ballPlayer != null && ballPanner != null) {
        // Mute the player or reset its frequency/pitch
        ballPlayer.setFrequency(0); // This sets the frequency to zero, effectively silencing it
        ballPanner.setPos(0); // Reset the position
    }
}



void resetProgram() {
  
   stopProgram();
   
   setupSonification();
   
    // Reset all variables to their initial values
    racketAngle = 45;
    //ballSpeed = 30;
    isRunning = false;
    ballMovingTowardsRacket = true;
    shouldSwing = false;
    swingCounter = 0;

    // Stop any ongoing stroke data stream
    strokeServer.stopStrokeStream();

    // Reset ball position and velocities
    ballX = startPositionCenter.x;
    ballY = startPositionCenter.y;
    ballSpeedX = 0;
    ballSpeedY = 0;
    ballInMotion = false;
    racketPosition.x = width / 2 - 200 / 2; 
    racketPosition.y = height - 250;
    
    ballPosition.set(width / 2, -20);
    ballVelocity.set(0, 0);
    isBallMoving = false;
    
    startDirection = "center";
    targetDirection = "center";
    ballVelocity = new PVector(0, 0);

    // Reset UI elements
    cp5.getController("racketAngle").setValue(45);
   
    isRunning = false;
}




void drawCourt() {
    image(courtImage, 0, 0, 850, 700);
    //image(playerAvatar, width / 2 - 30, height / 2 - 60, 60, 60);
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
    racketAngleValueLabel.update();
    strokePowerValueLabel.update();

    // Update and draw slider
   // sonificationVolumeSlider.update();
}

String selectedScenario = "";

void mouseClicked() {
    if (!ballInMotion && !isRunning) {
        if (scenarioCenterButton.isMouseOver()) {
          racketPosition.x = width / 2 - 200 / 2; 
    racketPosition.y = height - 250;
            selectedShot = "centre";
            setBallStartPositionAndVelocity(startPositionCenter, velocityCenter);
            loadScenario("centre");
            
            startBall("center");
    targetBall("center");
    isBallVisible = true;
    isBallMoving = true;
   
    shootBall();
    
     //String exampleSpeech = "Analyzing tennis stroke.";
  //ttsExamplePlayback(exampleSpeech);
            
            
            startProgram();
        } else if (scenarioLeftButton.isMouseOver()) {
            selectedShot = "left";
             selectedScenario = "leftToCenter";
            setBallStartPositionAndVelocity(startPositionLeft, velocityLeft);
            // Set the initial racket position for the left scenario
            racketPosition = new PVector(100, height - 250); // Starting on the left side
            loadScenario("left");
            startBallLeftToCenter();
startProgram();
        } else if (scenarioRightButton.isMouseOver()) {
            selectedShot = "right"; // New scenario identifier
            racketPosition = new PVector(width - 50, height - 250); // Racket starts from right
            setBallStartPositionAndVelocity(startPositionRight, velocityRight); // Ball starts from center
            
            loadScenario("right"); // Load the right-center scenario
            
            startBall("right");
    targetBall("right");
    isBallVisible = true;
    isBallMoving = true;
    
    shootBall();
            
            startProgram();
        }
    }

  
}

void startBallLeftToCenter() { 
    // Set the start and target positions for the ball
    startBall("left");
    targetBall("center");
    isBallVisible = true;
    isBallMoving = true;

    shootBall();
    shouldSwing = true;
}


void prepareForNewShot() {
    if (isRunning) {
        ballInMotion = true; // Start the ball motion only if the program is running
        ballMovingTowardsRacket = true;
        shouldSwing = false; // Reset the swing state
        swingCounter = 0; // Reset the swing counter
    }
}


void setBallStartPositionAndVelocity(PVector startPosition, PVector velocity) {
  
    
ballX = startPosition.x;
  ballY = startPosition.y; // Starting from the top of the screen
  ballSpeedX = velocity.x;
  ballSpeedY = velocity.y;
  ballInMotion = true; // Start the ball motion
}

void startProgram() {
  
  if (angleGain != null) {
        angleGain.setGain(powerVolume); // Set to an initial volume level
    }
    if (powerGain != null) {
        powerGain.setGain(powerVolume); // Set to an initial volume level
    }
  
  if (angleGain != null && powerGain != null) {
       // ac.out.addInput(angleGain);
        //ac.out.addInput(powerGain);
    }
    strokeServer.loadStrokeStream(tennisDataJSON1); // Load data when the program starts
    // Any other setup required to start the program
    // Adding the Gains to the audio context's output
    ballInMotion = true;
    
    
 
}

void stopProgram() {
    if (angleGain != null) {
        angleGain.setGain(0);
    }
    if (powerGain != null) {
        powerGain.setGain(0);
    }
  //setupSonification();
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
        textAlign(CENTER, CENTER);
        text(text, x + 10, y + h / 2 -17);
    }

    boolean isMouseOver() {
        return isOver;
    }
     void setText(String newText) {
        text = newText;
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
