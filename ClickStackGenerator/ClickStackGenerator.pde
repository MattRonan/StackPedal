/* ClickStack Pedal Generator
   2022 Matt Ronan
   https://github.com/MattRonan/ClickStack
   
   A program to generate gcode and a printable template
   For a custom ClickStack build.
  
   *Be sure to set the values in the 'USER VALUES' box below*
   
   *ALL DIMENSIONS ARE IN MM*
*/

import java.awt.*;
import java.awt.event.*;
import java.io.*;
import processing.serial.*;

//-----------------------~~!!!! USER VALUES !!!!
float toolR = 1.5; //measure your bit, divide by 2.
int highSpeed = 650; //set these speeds to what your machine needs.
int normalSpeed = 450;
int lowSpeed = 200;
int plungeSpeed = 50;

float sF = 5; //scale factor.  This is important if you want to export a png to use as a printed template. on a 1600x900 Dell E7470, 5 created a very accruate template. 

int stockT = 12;  //the thickness of your board.  Determines the thickness of each level.
int baseHeight = 125; //this the dimension of the base measured parallel to the pedals. ie this minus pedalL is how much space is left for the microcontroller area.

float mcuW = 17.5; //change to the width/length/height of your microcontroller.  This is an Elegoo Arduino Nano
float mcuL = 43;
float mcuH = 7.5; //total height of board.  This determines how deep the mcu pocket will be.
float mcuUSBW = 7.5; //width of usb jack.  Determines width of opening in plactic side panel.
float mcuUSBH = 3.75; //height of usb jack.  Determines how tall the opening is in the plastic side panel.
float mcuUSBHeightOffset = 0;// on some boards such as ESP32, the usb jack might not be the highest point.  This is how much lower the usb jack is than the highest point.  (highest point in those cases is usually a PH connector)
int mcuJackWall = 0;  //Which wall does the jack come out of.  0 = left side, 1 = back side, 2 = right side 
float mcuJackPos = .5; //shift the location of the jack by inputting a value from 0-1.  .5 puts it in the middle of that wall.
float mcuConnectionClearanceSize = 5; //open up some space around mcu to help wires fit in easier.  this is how far it extends out from the pins. 
float clearanceFactor = .75;//Percent of material to remove along mcu pocket sides.  greater than .75 is going to risk the mcu not being held in place as sungly.
//------------------------------------------------------------

float actuatorPosOffset = 1.5;  //button on official pcbs is not directly in the center, so this offset accounts for that.

ClickStack clickStack = new ClickStack(stockT,baseHeight);

int escapeTime = 0;

void setup() {
  
  size(1400, 800);
  
  clickStack.sF = sF;
  clickStack.defaultPedalW = 43; //if you want to make a pedal wider, say 1 wide middle pedal and 2 thinner outers, you can set them individually after this
  clickStack.defaultPedalL = 72; //there's typically no reason to have different lengths between pedals but you can later if you want.
  clickStack.defaultPedalMargin = 2; //margin between pedals.  doesnt get applied to the 2 outside edges
  clickStack.defaultFoamThickness = 6.0; //foam slot width.  This is set to use 6mm foam that you can find at Michaels or online.
  clickStack.defaultFoamSlotWall = 4; //thickness of the front foam slot wall
  clickStack.defaultPedalLedgeW = 15; //plastic presser panel screws into here. 15mm is usually fine.
  clickStack.defaultButtonReliefDepth = 8; //section where button+PCB sits.  with a 5mm button and the 1.6mm board+solder joints, there should be .5mm to 1mm of clearance for the button
  clickStack.defaultOtherReliefDepth = 5; //where the button isnt, remove enough material so that the plastic presser panels dont get blocked by wood when pressed.
  
  clickStack.addButton(0); //add buttons from left to right, specifying their level. For level 0 relief gets carved into base board, 1 or higher gets cut as a separate piece to be glued on.
  clickStack.addButton(1); //the buttons ID depends on the order you add them
  clickStack.addButton(2);
  
  //clickStack.setButtonWidth(1,120);//use button ID followed by value to make middle button wider.  Large middle button and 2 side buttons
  
  clickStack.addButton(3);
  clickStack.addButton(4);
  
  clickStack.setButtonWidth(0,25);//use button ID followed by value
  clickStack.setButtonWidth(1,45);//use button ID followed by value
  clickStack.setButtonWidth(2,120);//use button ID followed by value
  clickStack.setButtonWidth(3,45);//use button ID followed by value
  clickStack.setButtonWidth(4,25);//use button ID followed by value
  
}


void draw() {
 
  background(255);
   fill(150,0,255);
  stroke(0);
  text("Press 'p' to export png template for print. (Properly set sF first so that this image is a 1:1 scale)",5,12);
  text("Press 'g' to export G Code",5,27);
  text("(Click inside window first or button presses won't register)",5,42);
  clickStack.update();
  
  if(keyPressed && millis() > escapeTime){
    if(key == 'p'){
      println("butt");
      exportTemplate();
      keyPressed = false;
    }
    
    escapeTime = millis() + 120;
  }  
}

class ClickStack{
  
  public float defaultPedalW = 43;
  public float defaultPedalL = 72;
  public float defaultPedalMargin = 2;
  public float defaultFoamThickness = 6;
  public float defaultFoamSlotWall = 4;
  public float defaultPedalLedgeW = 15;
  public float defaultButtonReliefDepth = 8;
  public float defaultOtherReliefDepth = 5;
  
  public float stockT;
  public float baseHeight;
 
  public float baseWidth = 0; 
 
  public int numButtons = 0;
  
  public float[] origin = {20,60}; //top left corner of base in pixels
  public float[] bottomLeft = new float[2];
  
  public float sF; //scaleFactor;
  
  public float[] buttonPCBDimension = {18,12}; //the official PCB is on osh park at https://oshpark.com/shared_projects/baTaN6WL
  
  PedalButton[] buttons = new PedalButton[5]; 
  
  public ClickStack(float stockT, float baseHeight){
     this.stockT = stockT;
     this.baseHeight = baseHeight;
     this.bottomLeft[0] = this.origin[0] + this.baseHeight;
     this.bottomLeft[1] = this.origin[1] + this.baseHeight;
  }
  
  public void addButton(int level){
    buttons[numButtons] = new PedalButton(level);
    numButtons++;
    println("recalculating");
    recalculatePedal();
  }
   
  public void recalculatePedal(){
    baseWidth = 0;
    
    for(int i = 0; i < numButtons; i++){
      
      buttons[i].y = this.baseHeight - buttons[i].pedalL; //we think from top left corner down since thats how P draws stuff.  So button coords refer to the top left corner of the button.
      
      
      if(i != 0){

         baseWidth += this.defaultPedalMargin;
      }

      buttons[i].x = baseWidth;
      baseWidth += buttons[i].pedalW;
    }
  }
  
  public void update(){ //draw all the features of the current pedal design
  
     //draw base
     noFill();
     stroke(0);
     strokeWeight(5);
     rect(this.origin[0],this.origin[1],this.baseWidth*sF,this.baseHeight*sF);
     
     //draw buttons
     for(int i = 0; i < numButtons; i++){
     
       //button outlines
       strokeWeight(3);
       stroke(245,0,255);
       rect((buttons[i].x*sF)+this.origin[0],(buttons[i].y*sF)+this.origin[1],buttons[i].pedalW*sF,buttons[i].pedalL*sF);
      
       //foam slots
       stroke(102,100,255);
       rect( ((buttons[i].foamSlotTL[0]+buttons[i].x)*sF)+this.origin[0],  ((buttons[i].foamSlotTL[1]+buttons[i].y)*sF)+this.origin[1],  buttons[i].foamSlotWidth*sF,  buttons[i].foamThickness*sF  );
       
       //ledges
       stroke(0,200,255);
       line((buttons[i].x*sF) + this.origin[0], ((buttons[i].y+buttons[i].pedalLedgeW)*sF) + this.origin[1] , ((buttons[i].x+buttons[i].pedalW)*sF)+ this.origin[0], ((buttons[i].y+buttons[i].pedalLedgeW)*sF) + this.origin[1]);
       
       //button PCB pockets
       stroke(102,250,55);
       rect( ((buttons[i].buttonPCBTL[0]+buttons[i].x)*sF)+this.origin[0],  ((buttons[i].buttonPCBTL[1]+buttons[i].y-actuatorPosOffset)*sF)+this.origin[1],  buttonPCBDimension[0]*sF,  buttonPCBDimension[1]*sF  );
       
       //wire tracks
       line(((buttons[i].x+(buttons[i].pedalW/2))*sF) + this.origin[0],((buttons[i].y+buttons[i].buttonActuatorY)*sF)+this.origin[1],((buttons[i].x+(buttons[i].pedalW/2))*sF) + this.origin[0],((buttons[i].y+buttons[i].pedalLedgeW)*sF) + this.origin[1]);//first line reaches ledge.
       
       if(buttons[i].level == 0){
         line(((buttons[i].x+(buttons[i].pedalW/2))*sF) + this.origin[0], ((buttons[i].y+buttons[i].pedalLedgeW)*sF) + this.origin[1], ((buttons[i].x+(buttons[i].pedalW/2))*sF) + this.origin[0], ((buttons[i].y)*sF) + this.origin[1]);//base level buttons carve thru the ledge.
       }
       
       
       //mcu pocket
       stroke(252,250,0);
       switch(mcuJackWall){
         case 0: rect(0+this.origin[0],  (((baseHeight-ClickStack.this.defaultPedalL)*mcuJackPos-(mcuW/2))*sF)+this.origin[1],  mcuL*sF,  mcuW*sF  ); //mcu pocket
                 rect(0+this.origin[0]+((mcuL-(mcuL*clearanceFactor))/2*sF),  (((baseHeight-ClickStack.this.defaultPedalL)*mcuJackPos-(mcuW/2) - mcuConnectionClearanceSize )*sF)+this.origin[1],  (mcuL*clearanceFactor)*sF,  (mcuW+(mcuConnectionClearanceSize*2))*sF  ); //extra relief for wires
                 //mcuConnectionClearanceSize
                 break;
         case 1: 
                 break;
         case 2:
                 break;
     
       }
       /*
       float mcuW = 17.5; //change to the width/length/height of your microcontroller.  This is an Elegoo Arduino Nano
      float mcuL = 43;
      float mcuH = 7.5; //total height of board.  This determines how deep the mcu pocket will be.
      float mcuUSBW = 7.5; //width of usb jack.  Determines width of opening in plactic side panel.
      float mcuUSBH = 3.75; //height of usb jack.  Determines how tall the opening is in the plastic side panel.
      float mcuUSBHeightOffset = 0;// on some boards such as ESP32, the usb jack might not be the highest point.  This is how much lower the usb jack is than the highest point.  (highest point in those cases is usually a PH connector)
      int mcuJackWall = 0;  //Which wall does the jack come out of.  0 = left side, 1 = back side, 2 = right side 
      float mcuJackPos = .5;*/
       
       //actuator locations
       stroke(250,0,55);
       circle(((buttons[i].x+(buttons[i].pedalW/2))*sF) + this.origin[0],((buttons[i].y+buttons[i].buttonActuatorY)*sF)+this.origin[1],6);
     
       

     
       //draw info
       text("Level = " + buttons[i].level, ((buttons[i].buttonPCBTL[0]+buttons[i].x)*sF)+this.origin[0],  ((buttons[i].buttonPCBTL[1]+buttons[i].y+ buttonPCBDimension[1]+3)*sF)+this.origin[1]);
       
   
     }
     
  }
  public void setButtonWidth(int id, float val){
     buttons[id].pedalW = val;
     buttons[id].recalculate(); //need to recalculate foam slot, button pcb relief location, et      
     this.recalculatePedal(); //then need to update the whole pedal.
  }
   
  
  class PedalButton{
      
    public float pedalW;
    public float pedalL;
    public float pedalMargin;
    public float foamThickness;
    public float foamSlotWall;
    public float pedalLedgeW;
    public float buttonReliefDepth;
    public float otherReliefDepth;
    
    public float x,y;
    public int level;
    
    public float[] foamSlotTL = new float[2];
    public float foamSlotWidth; 
    float foamSlotPercent = .5; //percent of total width (.5 is a good value typically
    
    public float buttonActuatorY; 
    public float[] buttonPCBTL = new float[2];
    
    public PedalButton(){
      
    }
  
    public PedalButton(int level){
      this.pedalW = ClickStack.this.defaultPedalW;
      this.pedalL =  ClickStack.this.defaultPedalL;
      this.pedalMargin =  ClickStack.this.defaultPedalMargin;
      this.foamThickness = ClickStack.this.defaultFoamThickness;
      this.foamSlotWall =  ClickStack.this.defaultFoamSlotWall;
      this.pedalLedgeW =  ClickStack.this.defaultPedalLedgeW;
      this.buttonReliefDepth =  ClickStack.this.defaultButtonReliefDepth;
      this.otherReliefDepth =  ClickStack.this.defaultOtherReliefDepth;
      this.buttonActuatorY = ((this.pedalL-this.pedalLedgeW)/2) + (this.pedalLedgeW);//the y positionn of the actual clicky button plunger
      this.level = level;
      this.recalculate();
    }
    
    public void recalculate(){
      this.foamSlotWidth = this.pedalW * this.foamSlotPercent;
      this.foamSlotTL[0] = ((pedalW-foamSlotWidth) * this.foamSlotPercent);//basically from the buttons perspective, TL of button is 0,0
      this.foamSlotTL[1] = this.pedalL - this.foamSlotWall - this.foamThickness;
   
      this.buttonPCBTL[0] = ((this.pedalW/2)-(ClickStack.this.buttonPCBDimension[0]/2));
      this.buttonPCBTL[1] = this.buttonActuatorY - (ClickStack.this.buttonPCBDimension[1]/2);
    }
  }
}

void exportTemplate(){
    
  Frame frame = new Frame();
  String title = "type the name of the file";
  String defDir = sketchPath();
  String fileType = ".png";
  
  FileDialog fd = new FileDialog(frame, title, FileDialog.SAVE);
  fd.setFile(fileType);
  fd.setDirectory(defDir);
  fd.setLocation(50, 50);
  fd.show();
  
  String filenameRaw = fd.getFile();
 
  String peeth = fd.getDirectory()+ filenameRaw + fileType; //so now we got the path we want to save to, but first need to try to LOAD from that path to see if file exists, and integrate new model with existing file if needed.
  
  println("going to export to " + peeth);
  
  saveFrame(peeth);
  
}
