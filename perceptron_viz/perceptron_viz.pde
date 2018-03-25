// Perceptron Visualizer
// @author: Bradley Dice
// Link: https://github.com/bdice/perceptron-viz

// Initial code from Atomic Sprocket Visualizer
// @author: Ben Farahmand
// Link: https://gist.github.com/benfarahmand/6902359#file-audio-visualizer-atomic-sprocket

import ddf.minim.analysis.*;
import ddf.minim.*;
Minim minim;
AudioPlayer player;
AudioSource wavesource;
FFT fft;
AudioInput in;
float[] angle;
float[] y, x;
PImage logo_img;

String logoFile = "logo.png";

boolean useMic = true;
boolean autochange = false;
float micSensitivity = 5;
float noise_offset = 0.0;
int wavesourceLength;
long currentTime, previousTime, dt, nextChangeTime, previousNoiseTime;

int algorithmSelection = 0;
int currentAlgorithm = 0;
int showSprocket, showFT = 1;
int showLogo, showWaveform, showNoiseLines, showMessage = 0;
int messageDisabled = 1;
int messageCounter = 0;
int messageTimer = 0;

int noiseAlgorithm = 0;
float noiseWarmthValue = 0;

PFont font;
// The font must be located in the sketch's 
// "data" directory to load successfully


void setup()
{
  size(displayWidth, displayHeight, P3D);
  logo_img = loadImage(logoFile);
  font = loadFont("Dosis-Light-48.vlw");
  textFont(font, 48);  minim = new Minim(this);
  if(useMic){
    in = minim.getLineIn();
    fft = new FFT(in.bufferSize(), in.sampleRate());
  }else{
    player = minim.loadFile("Artist - Title.mp3");
    fft = new FFT(player.bufferSize(), player.sampleRate());
  }
  y = new float[fft.specSize()];
  x = new float[fft.specSize()];
  angle = new float[fft.specSize()];
  if(!useMic){
    wavesource = player;
    player.play();
  }else{
    wavesource = in;
  }
  wavesourceLength = wavesource.left.size();
  frameRate(240);
}
 
void draw(){
  // Update timesteps
  previousTime = currentTime;
  currentTime = millis();
  dt = currentTime - previousTime;

  if(nextChangeTime - currentTime < 0 && autochange){
    nextChangeTime = currentTime + 10000 + int(random(10000));
    algorithmSelection = int(random(6));
  }
  
  if(algorithmSelection > 0 && currentAlgorithm != algorithmSelection){
    currentAlgorithm = algorithmSelection;
    switch(algorithmSelection){
      case 0:
        showLogo = 1;
        showSprocket = 0;
        showFT = 1;
        showWaveform = 1;
        showNoiseLines = 0;
        noiseAlgorithm = 0;
        showMessage = 0;
        break;
      case 1:
        showLogo = 1;
        showSprocket = 0;
        showFT = 0;
        showWaveform = 1;
        showNoiseLines = 0;
        noiseAlgorithm = 0;
        showMessage = 0;
        break;
      case 2:
        showLogo = 0;
        showSprocket = 1;
        showFT = 0;
        showWaveform = 1;
        showNoiseLines = 0;
        noiseAlgorithm = 2;
        showMessage = 0;
        break;
      case 3:
        showLogo = 0;
        showSprocket = 0;
        showFT = 1;
        showWaveform = 0;
        showNoiseLines = 0;
        noiseAlgorithm = 0;
        showMessage = 0;
        break;
      case 4:
        showLogo = 0;
        showSprocket = 1;
        showFT = 0;
        showWaveform = 0;
        showNoiseLines = 1;
        noiseAlgorithm = 2;
        showMessage = 0;
        break;
      case 5:
        showLogo = 0;
        showSprocket = 1;
        showFT = 1;
        showWaveform = 0;
        showNoiseLines = 0;
        noiseAlgorithm = 2;
        showMessage = 0;
        break;
      case 6:
        showLogo = 1;
        showSprocket = 1;
        showFT = 0;
        showWaveform = 0;
        showNoiseLines = 1;
        noiseAlgorithm = 0;
        showMessage = 0;
        break;
    }
  }
  
  background(0);
  fft.forward(wavesource.mix);
  
  if(showNoiseLines == 1){
    drawNoiseLines();
  }
  if(showSprocket == 1){
    drawSprocket();
  }
  if(showFT == 1){
    drawFT();
  }
  if(showWaveform == 1){
    drawWaveform();
  }
  if(showLogo == 1){
    drawLogo();
  }
  if(showMessage == 1){
    drawMessage();
  }else{
    messageDisabled = 1;
  }
}

void drawNoiseLines(){
  noiseAlgorithm = noiseAlgorithm % 3;
  pushStyle();
  pushMatrix();
  translate(0, 0, -1); // Put these lines behind the logo and other stuff
  colorMode(HSB, 360, 100, 100);
  if(currentTime - previousNoiseTime > 100){
    noise_offset = noise_offset + .03;
    for(int i = 0; i < width; i++){
      float n = -40 + noise(noise_offset+i*0.05)*80;
      n += noise(-noise_offset+i*0.03)*20;
      if(noiseAlgorithm == 2){
        noiseWarmthValue = noise(-noise_offset+i*0.03)*20;
      }
      switch(noiseAlgorithm){
        case 0: stroke(0, 0, min(100, n)); break;
        case 1: stroke(0, 100, min(100, n)); break;
        case 2:
          stroke(noiseWarmthValue*6%360, 100-min(n,40), min(n*n*n/100,100));
          break;
      }
      line(i, 0, i, height);
    }
  }
  popMatrix();
  popStyle();
}
 
void drawSprocket(){
  float sprocketRingMoveScale = 500*micSensitivity;
  float sprocketBoxScale = 50*micSensitivity;
  pushStyle();
  noStroke();
  pushMatrix();
  translate(width/2, height/2);
  pushStyle();
  for (int i = 0; i < fft.specSize(); i++) {
    y[i] += pow(sprocketRingMoveScale*fft.getBand(i)/100, 0.6);
    x[i] += pow(sprocketRingMoveScale*fft.getFreq(i)/100, 0.6);
    angle[i] = angle[i] + fft.getFreq(i)/2000;
    rotateX(sin(angle[i]/2));
    rotateY(cos(angle[i]/2));
    if(noiseAlgorithm != 2){
      fill(fft.getFreq(i)*2, 255, 0);
    }else{
      if(showNoiseLines == 1){
        colorMode(HSB, 360, 100, 100);
        fill(noiseWarmthValue*6%360, 100, 100);
      }else{
        fill(255, 0, 0);
      }
    }
    pushMatrix();
    translate((x[i]+50)%width/3, (y[i]+50)%height/3);
    box(pow(sprocketBoxScale*fft.getBand(i)/20+fft.getFreq(i)/15, 0.6));
    popMatrix();
  }
  popMatrix();
  popStyle();
  pushStyle();
  pushMatrix();
  translate(width/2, height/2, 0);
  for (int i = 0; i < fft.specSize(); i++) {
    y[i] += pow(sprocketRingMoveScale*fft.getBand(i)/1000, 0.6);
    x[i] += pow(sprocketRingMoveScale*fft.getFreq(i)/1000, 0.6);
    angle[i] = angle[i] + fft.getFreq(i)/100000;
    rotateX(sin(angle[i]/2));
    rotateY(cos(angle[i]/2));
    if(noiseAlgorithm < 2){
      fill(0, 255-fft.getFreq(i)*2, 255-micSensitivity*fft.getBand(i)*2);
    }else{
      if(showNoiseLines == 1){
        colorMode(HSB, 360, 100, 100);
        fill(noiseWarmthValue*6%360, 100, 100);
      }else{
        fill(255, 0, 0);
      }
    }
    pushMatrix();
    translate((x[i]+250)%width, (y[i]+250)%height);
    box(pow(sprocketBoxScale*fft.getBand(i)/20+fft.getFreq(i)/15, 0.6));
    popMatrix();
  }
  popMatrix();
  popStyle();
  popStyle();
}

void drawFT(){
  float ftHeightScale = 30;
  pushStyle();
  stroke(255, 0, 0);
  for(int i = 0; i < fft.specSize()/2; i++)
  {
    float xval = (float(i)-0.5)/fft.specSize()*width;
    float yval = log(fft.getBand(i)*40)*ftHeightScale;
    line(width/2+xval, height/2 - yval, width/2+xval, height/2 + yval);
    line(width/2-xval, height/2 - yval, width/2-xval, height/2 + yval);
  }
  popStyle();
}

void drawWaveform(){
  pushStyle();
  stroke(255);
  // I draw the waveform by connecting 
  // neighbor values with a line. I multiply 
  // each of the values by 50 
  // because the values in the buffers are normalized
  // this means that they have values between -1 and 1. 
  // If we don't scale them up our waveform 
  // will look more or less like a straight line.
  float xval1, xval2, yval1, yval2;
  strokeWeight(2);
  float waveformWidthScale = 1;
  float waveformHeightScale = micSensitivity*100;
  
  for(int i = 0; i < wavesourceLength/waveformWidthScale - 1; i++){
      xval1 = waveformWidthScale*width*i/float(wavesourceLength);
      xval2 = waveformWidthScale*width*(i+1)/float(wavesourceLength);
      yval1 = (height/2) + waveformHeightScale*wavesource.left.get(i);
      yval2 = (height/2) + waveformHeightScale*wavesource.left.get(i+1);
      line(xval1, yval1, xval2, yval2);
  }
  popStyle();
}

void drawLogo(){
  pushStyle();
  blendMode(EXCLUSION);
  float aspect_ratio = logo_img.width/logo_img.height;
  float logo_width = min(width, logo_img.width);
  float logo_height = logo_width / aspect_ratio;
  image(logo_img, width/2-logo_width/2, height/2-logo_height/2, logo_width, logo_height);
  popStyle();
}

void drawMessage(){
  if (messageDisabled == 1){
    messageDisabled = 0;
    messageCounter = 0;
    messageTimer = millis();
  }
  String message = "This sample message \n will make you question \n just how long \n ";
  message += "you've been dancing \n in this place \n where the lights pulsate \n and the rhythms surround you...\n";
  messageCounter = min((millis() - messageTimer) / 60, message.length());
  pushStyle();
  blendMode(EXCLUSION);
  translate(width/2, height/2);
  textAlign(CENTER, CENTER);
  text(message.substring(max(0, messageCounter-80), messageCounter), 0, 0);
  popStyle();
  // Automatically reset message after it finishes.
  if (millis() > messageCounter * 60 + messageTimer + 4000){
    messageTimer = millis();
  }
}
 
void stop(){
  // always close Minim audio classes when you finish with them
  player.close();
  minim.stop();
  super.stop();
}

void keyPressed(){
  if (key == CODED) {
    if (keyCode == UP) {
      micSensitivity *= 1.1;
    } else if (keyCode == DOWN) {
      micSensitivity /= 1.1;
    }
  } else {
    switch(key){
      case '`':
        autochange = true;
        break;
      case '1':
        showSprocket = 1-showSprocket;
        autochange = false;
        break;
      case '2':
        showFT = 1-showFT;
        autochange = false;
        break;
      case '3':
        showWaveform = 1-showWaveform;
        autochange = false;
        break;
      case '4':
        showLogo = 1-showLogo;
        autochange = false;
        break;
      case '5':
        showNoiseLines = 1-showNoiseLines;
        autochange = false;
        break;
      case '6':
        showMessage = 1-showMessage;
        autochange = false;
        break;
      case ' ':
        noiseAlgorithm = (noiseAlgorithm+1)%3;
        autochange = false;
        break;
      case 'q':
        algorithmSelection = 0;
        autochange = false;
        break;
      case 'w':
        algorithmSelection = 1;
        autochange = false;
        break;
      case 'e':
        algorithmSelection = 2;
        autochange = false;
        break;
      case 'r':
        algorithmSelection = 3;
        autochange = false;
        break;
      case 't':
        algorithmSelection = 4;
        autochange = false;
        break;
      case 'y':
        algorithmSelection = 5;
        autochange = false;
        break;
      case 'u':
        algorithmSelection = 6;
        autochange = false;
        break;
    }
  }
}