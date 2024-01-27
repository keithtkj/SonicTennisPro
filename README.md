# SonicTennisPro: Tennis Stroke Optimization Simulator

## Project Overview
SonicTennisPro is a cutting-edge Java-based simulator developed to enhance tennis training through the innovative use of audio sonification. Targeted primarily at beginners, this tool focuses on optimizing tennis strokes by helping players hit the ball with their racket's sweet spot using auditory feedback. SonicTennisPro represents a unique method in sports training, where sound is utilized to improve understanding and mastery of tennis techniques.

![Screenshot 2024-01-27 at 5 04 59 PM](https://github.com/keithtkj/SonicTennisPro/assets/68370921/83b91cd3-26e8-4028-8002-866da3e91ce7)


## Features

### Tennis Court Visualization
The simulator provides a visual representation of a tennis court, serving as the main interface for simulating racket movements and ball trajectories.

### Premade Scenario Control Panel
Users can select from a variety of premade scenarios through a control panel. These scenarios are visualized and accompanied by specific sonification audio, based on their respective JSON event files.

### Researcher Sonification Sliders
These sliders, positioned at the bottom left of the screen, offer four different sonification schemes. They are essential for conducting Wizard of Oz testing and various research applications.

### Manual Ball Trajectory Settings
For a more hands-on approach, researchers can adjust the ball's launch and target points using these settings, which complement the sonification sliders for in-depth experimental control.

## Sonification Scheme
SonicTennisPro uses an advanced sonification system to translate key tennis data elements into sound:

#### Ball Trajectory: Audio cues in stereo panning reflect the ball's left or right trajectory.
#### Ball Speed: The pitch of a SAW wave changes according to the ball's speed, offering an auditory representation of speed variations.
#### Court Ambience: Users can adjust the volume of background court sounds for a more immersive experience.
#### Swing Timing: A metronome assists in timing the racket swings, with the tempo varying based on the anticipated landing area of the ball.

## Usage
### Running Premade Scenarios
Due to current technical constraints, users need to restart the program for a different scenario.
Detailed instructions guide users through the process of activating sonification schemes and playing scenarios to ensure proper audio playback.

### Wizard of Oz Testing Controls
The simulator allows for manual control over racket movement and the setting of ball trajectories, facilitating real-time training and experimentation.
