/* ClickStack Pedal Generator
   2022 Matt Ronan
   https://github.com/MattRonan/ClickStack
   
   A program to generate gcode and a printable template
   For a custom ClickStack build.
  
   *Be sure to set the values in the 'USER VALUES' box below*
   
   *ALL DIMENSIONS ARE IN MM*
   
   currently due to processing's y axis being reversd, the design shows is a mirror image.  basically if you want the LEFTmost pedal to be level0 in the actual device, the design should show the RIGHTmost being level0.
   If you want the jack on the right side, put it on the left side, etc.
   I'll fix this at some point, it just involves flipping either all y values before drawing or before exporting gcode. Simple but annoying to do.
*/

import java.awt.*;
import java.awt.event.*;
import java.io.*;
import processing.serial.*;

//-----------------------~~!!!! USER VALUES !!!!
float toolR = 1.5; //measure your bit, divide by 2.
int highSpeed = 750; //set these speeds and steps to what your machine needs. THESE ARE CURRENTLY SET FOR PINE on a small machine.  If you use a harder wood make sure these aren't too agressive for your machine.
int normalSpeed = 500;
int lowSpeed = 250;
int plungeSpeed = 50;
float bigStep = 2;  
float normalStep = 1;
float smallStep = .5;
float microStep = .25;  
float defaultTabT = 2;

float sF = 5; //scale factor.  This is important if you want to export a png to use as a printed template. on a 1600x900 Dell E7470, 5 created a very accruate template. 

float stockT = 12;  //the thickness of your board.  Determines the thickness of each level.
float plasticT = 1.5; //thickness of the plastic.  Used for the electronics cover and the presser panels.
float baseHeight = 125; //this the dimension of the base measured parallel to the pedals. ie this minus pedalL is how much space is left for the microcontroller area.


float mcuW = 17.5; //change to the width/length/height of your microcontroller.  This is an Elegoo Arduino Nano
float mcuL = 43;
float mcuH = 7.5; //total height of board.  This determines how deep the mcu pocket will be.
float mcuUSBW = 7.5; //width of usb jack.  Determines width of opening in plactic side panel.
float mcuUSBH = 3.75; //height of usb jack.  Determines how tall the opening is in the plastic side panel.
float mcuUSBHeightOffset = 0;// on some boards such as ESP32, the usb jack might not be the highest point.  This is how much lower the usb jack is than the highest point.  (highest point in those cases is usually a PH connector)
int mcuJackWall = 1;  //Which wall does the jack come out of.  0 = left side, 1 = back side, 2 = right side 
float mcuJackPos = .5; //shift the location of the jack by inputting a value from 0-1.  .5 puts it in the middle of that wall.
float mcuConnectionClearanceSize = 5; //open up some space around mcu to help wires fit in easier.  this is how far it extends out from the pins. 
float clearanceFactor = .65;//Percent of material to remove along mcu pocket sides.  greater than .75 is going to risk the mcu not being held in place as sungly.
float usbPanelL = mcuW + 20; // 20 gives 10mm on each side for the mounting screws for the usb panel.  More isnt neccessary and less might cause structural issues, especially if the wood is pine.
float pedalScrewClearance = 8;
float topCoverScrewClearance = 4;
float buttonReliefDepth = 8; //section where button+PCB sits.  with a 5mm button and the 1.6mm board+solder joints, there should be .5mm to 1mm of clearance for the button
float otherReliefDepth = 5; //where the button isnt, remove enough material so that the plastic presser panels dont get blocked by wood when pressed.
float wireTrackDepth = 3;
float ledgeClearance = 6;
//------------------------------------------------------------

float[] buttonPCBDimension = {18,12}; //the official PCB is on osh park at https://oshpark.com/shared_projects/baTaN6WL
float actuatorPosOffset = 1.5;  //button on official pcbs is not directly in the center, so this offset accounts for that.

ClickStack clickStack = new ClickStack(stockT,baseHeight);

int escapeTime = 0;

boolean drawDesign = true;

float hyp;
float theta;
float a,b;
float tabSize = 0;
float stepover = 2;
float zO = 0;

OutputFile F = new OutputFile(60000);

void setup() {
  
  size(1400, 800);
  
  clickStack.sF = sF;
  clickStack.defaultPedalW = 43; //if you want to make a pedal wider, say 1 wide middle pedal and 2 thinner outers, you can set them individually after this
  clickStack.defaultPedalL = 72; //there's typically no reason to have different lengths between pedals but you can later if you want.
  clickStack.defaultPedalMargin = 2; //margin between pedals.  doesnt get applied to the 2 outside edges
  clickStack.defaultFoamThickness = 6.0; //foam slot width.  This is set to use 6mm foam that you can find at Michaels or online.
  clickStack.defaultFoamSlotWall = 4; //thickness of the front foam slot wall
  clickStack.defaultPedalLedgeW = 15; //plastic presser panel screws into here. 15mm is usually fine.
  
  
  //big center button layout
  /*
  clickStack.addButton(2); //add buttons from left to right, specifying their level. For level 0 relief gets carved into base board, 1 or higher gets cut as a separate piece to be glued on.
  clickStack.addButton(1); //the buttons ID depends on the order you add them
  clickStack.addButton(0);
  clickStack.addButton(1);
  clickStack.addButton(2);  
  clickStack.setButtonWidth(0,25);//use button ID followed by value
  clickStack.setButtonWidth(1,45);//use button ID followed by value
  clickStack.setButtonWidth(2,120);//use button ID followed by value
  clickStack.setButtonWidth(3,45);//use button ID followed by value
  clickStack.setButtonWidth(4,25);//use button ID followed by value*/
  
  //classic 3-stack
  clickStack.addButton(2); //add buttons from left to right, specifying their level. For level 0 relief gets carved into base board, 1 or higher gets cut as a separate piece to be glued on.
  clickStack.addButton(1); //the buttons ID depends on the order you add them
  clickStack.addButton(0);
  
}


void draw() {
 
  if(drawDesign){
    background(255);
    fill(150,0,255);
    stroke(0);
    text("Press 'p' to export png template for print. (Properly set sF first so that this image is a 1:1 scale)",5,12);
    text("Press 'g' to export G Code",5,27);
    text("(Click inside window first or button presses won't register)",5,42);
    clickStack.update();
    drawDesign = false;
    
  }
  
  if(keyPressed && millis() > escapeTime){
    if(key == 'p'){
      exportTemplate();
      keyPressed = false; //idk why these keys sometimes stick but this solves that
    }
    if(key == 'g'){
      println("exporting");
      exportGCode();
      keyPressed = false;
    }
    else if(key == '0'){
      drawDesign = true;
      mcuJackWall = 0;
      clickStack.recalculatePedal();
    }
    else if(key == '1'){
      drawDesign = true;
      mcuJackWall = 1;
      clickStack.recalculatePedal();
    }
    else if(key == '2'){
      drawDesign = true;
      mcuJackWall = 2;
      clickStack.recalculatePedal();
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
  
  public float stockT;
  public float baseHeight;
 
  public float baseWidth = 0; 
 
  public int numButtons = 0;
  
  public float[] origin = {20,60}; //top left corner of base in pixels
 
  public float sF; //scaleFactor;
  
  float[] mcuCenter = {0,0};
  float[] mcuTL = {0,0};
  
  PedalButton[] buttons = new PedalButton[5]; 
  
  public ClickStack(float stockT, float baseHeight){
     this.stockT = stockT;
     this.baseHeight = baseHeight;
  }
  
  public void addButton(int level){
    buttons[numButtons] = new PedalButton(level);
    numButtons++;
    //println("recalculating");
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
    
    switch(mcuJackWall){
         case 0: mcuTL[0] = plasticT;//this looks wierd but its just that we recess the plastic usb panel, which pushes the mcu right in this case, where it would otherwise be at 0
                 mcuTL[1] = (baseHeight-ClickStack.this.defaultPedalL)*mcuJackPos-(mcuW/2);
                 mcuCenter[0] = mcuTL[0] + mcuL/2;
                 mcuCenter[1] = mcuTL[1] +(mcuW/2);
                 break;
         case 1: mcuTL[0] = (this.baseWidth*mcuJackPos) - (mcuW/2);
                 mcuTL[1] = plasticT;
                 mcuCenter[0] = mcuTL[0] + mcuW/2;
                 mcuCenter[1] = mcuTL[1] +(mcuL/2);
                 break;
         case 2:  mcuTL[0] = this.baseWidth-mcuL;//this looks wierd but its just that we recess the plastic usb panel, which pushes the mcu right in this case, where it would otherwise be at 0
                 mcuTL[1] = (baseHeight-ClickStack.this.defaultPedalL)*mcuJackPos-(mcuW/2);
                 mcuCenter[0] = mcuTL[0] + mcuL/2;
                 mcuCenter[1] = mcuTL[1] +(mcuW/2);
                 break;
       }
  }
  
  public void update(){ //draw all the features of the current pedal design
  
     //draw base
     noFill();
     stroke(0);
     strokeWeight(5);
     rect(this.origin[0],this.origin[1],this.baseWidth*sF,this.baseHeight*sF);
 
     //mcu and related pockets
       stroke(252,250,0);
       strokeWeight(3);
       switch(mcuJackWall){
         case 0: 
                 rect((mcuTL[0]*sF) + this.origin[0], (mcuTL[1]*sF) + origin[1],  mcuL*sF,  mcuW*sF  ); //mcu pocket
                 rect((mcuTL[0]*sF)+this.origin[0]+((mcuL-(mcuL*clearanceFactor))/2*sF),  (( mcuTL[1] - mcuConnectionClearanceSize )*sF)+this.origin[1],  (mcuL*clearanceFactor)*sF,  (mcuW+(mcuConnectionClearanceSize*2))*sF  ); //extra relief for wires
                 strokeWeight(5);
                 line(0+origin[0],  (mcuTL[1]-(usbPanelL-mcuW)/2) * sF +origin[1],  0+origin[0],  ((mcuTL[1]-(usbPanelL-mcuW)/2)+usbPanelL)*sF+origin[1]);
                 strokeWeight(4);
                 break;
         case 1: 
                 rect((mcuTL[0]*sF) + this.origin[0], (mcuTL[1]*sF) + origin[1],  mcuW*sF,  mcuL*sF  ); //mcu pocket
                 rect(((mcuTL[0] - mcuConnectionClearanceSize)*sF) + this.origin[0], (mcuTL[1]*sF) + origin[1]+((mcuL-(mcuL*clearanceFactor))/2*sF), ( mcuW+mcuConnectionClearanceSize*2)*sF,  mcuL*sF*clearanceFactor  ); 
                 strokeWeight(5);
                 line((mcuTL[0]-(usbPanelL-mcuW)/2) * sF + origin[0],  0+origin[1], ((mcuTL[0]-(usbPanelL-mcuW)/2)+usbPanelL)*sF+origin[0],  0+origin[1]);
                 strokeWeight(4);
                 break;
         case 2:  
                 rect((mcuTL[0]*sF) + this.origin[0], (mcuTL[1]*sF) + origin[1],  mcuL*sF,  mcuW*sF  ); //mcu pocket
                 rect((mcuTL[0]*sF)+this.origin[0]+((mcuL-(mcuL*clearanceFactor))/2*sF),  (( mcuTL[1] - mcuConnectionClearanceSize )*sF)+this.origin[1],  (mcuL*clearanceFactor)*sF,  (mcuW+(mcuConnectionClearanceSize*2))*sF  ); //extra relief for wires
                 strokeWeight(5);
                 line(this.baseWidth*sF+origin[0],  (mcuTL[1]-(usbPanelL-mcuW)/2) * sF +origin[1],  this.baseWidth*sF+origin[0],  ((mcuTL[1]-(usbPanelL-mcuW)/2)+usbPanelL)*sF+origin[1]);
                 strokeWeight(4);
                 break;
     
       }
       
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
       if(buttons[i].level == 0){
         stroke(102,250,55);//green are tracks routed directly into the base
       }
       else{
         stroke(252,100,55);//orange are tracks that are routed into a separate pedal piece.  ie buttons that are level 1 or higher.  The a diagnal hand-drilled hole connects it to the track in the base.
       }
       
       rect( ((buttons[i].buttonPCBTL[0]+buttons[i].x)*sF)+this.origin[0],  ((buttons[i].buttonPCBTL[1]+buttons[i].y-actuatorPosOffset)*sF)+this.origin[1],  buttonPCBDimension[0]*sF,  buttonPCBDimension[1]*sF  );
       
       //wire tracks
       line(((buttons[i].x+(buttons[i].pedalW/2))*sF) + this.origin[0],((buttons[i].y+buttons[i].buttonActuatorY)*sF)+this.origin[1],((buttons[i].x+(buttons[i].pedalW/2))*sF) + this.origin[0],((buttons[i].y+buttons[i].pedalLedgeW)*sF) + this.origin[1]);//first line reaches ledge.
       
       if(buttons[i].level == 0){
         line(((buttons[i].x+(buttons[i].pedalW/2))*sF) + this.origin[0], ((buttons[i].y+buttons[i].pedalLedgeW)*sF) + this.origin[1], ((buttons[i].x+(buttons[i].pedalW/2))*sF) + this.origin[0], ((buttons[i].y)*sF) + this.origin[1]);//base level buttons carve thru the ledge.
       }
       
       stroke(102,250,55);
       line(((buttons[i].x+(buttons[i].pedalW/2))*sF) + this.origin[0], ((buttons[i].y)*sF) + this.origin[1],((buttons[i].x+(buttons[i].pedalW/2))*sF) + this.origin[0],((buttons[i].y-ledgeClearance)*sF) + this.origin[1]);//carve straight out from edge of button before heading to mcu
       
       line(((buttons[i].x+(buttons[i].pedalW/2))*sF) + this.origin[0],((buttons[i].y-ledgeClearance)*sF) + this.origin[1],mcuCenter[0]*sF+origin[0],mcuCenter[1]*sF+origin[1]);//now carve to mcu pocket

       //actuator locations
       stroke(250,0,55);
       circle(((buttons[i].x+(buttons[i].pedalW/2))*sF) + this.origin[0],((buttons[i].y+buttons[i].buttonActuatorY)*sF)+this.origin[1],6);

       //screw locactions
       stroke(100,100,5);
       //peeal screws
       circle((buttons[i].x+pedalScrewClearance)*sF+origin[0],(buttons[i].y+buttons[i].pedalLedgeW/2)*sF+origin[1],toolR*2*sF);
       circle((buttons[i].x+buttons[i].pedalW-pedalScrewClearance)*sF+origin[0],(buttons[i].y+buttons[i].pedalLedgeW/2)*sF+origin[1],toolR*2*sF);
       
       //top cover screws.  For now it just does 4 corner screws.  If you need more its easy to add them by hand, since the 4 done by the machine will hold it perfectly aligned.  TODO, ability to add more screws in specific locations
       
       circle(topCoverScrewClearance*sF+origin[0],(baseHeight-defaultPedalL-topCoverScrewClearance)*sF+origin[1],toolR*2*sF); //BL
       circle(topCoverScrewClearance*sF+origin[0],topCoverScrewClearance*sF+origin[1],toolR*2*sF); //TL
       circle((this.baseWidth-topCoverScrewClearance)*sF+origin[0],topCoverScrewClearance*sF+origin[1],toolR*2*sF); //TR
       circle((this.baseWidth-topCoverScrewClearance)*sF+origin[0],(baseHeight-defaultPedalL-topCoverScrewClearance)*sF+origin[1],toolR*2*sF); //BR
      
       //draw info
       text("Level = " + buttons[i].level, ((buttons[i].buttonPCBTL[0]+buttons[i].x)*sF)+this.origin[0],  ((buttons[i].buttonPCBTL[1]+buttons[i].y+ buttonPCBDimension[1]+3)*sF)+this.origin[1]);
     
     
     }//end button loop
     
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
      this.buttonActuatorY = ((this.pedalL-this.pedalLedgeW)/2) + (this.pedalLedgeW);//the y positionn of the actual clicky button plunger
      this.level = level;
      this.recalculate();
    }
    
    public void recalculate(){
      this.foamSlotWidth = this.pedalW * this.foamSlotPercent;
      this.foamSlotTL[0] = ((pedalW-foamSlotWidth) * this.foamSlotPercent);//basically from the buttons perspective, TL of button is 0,0
      this.foamSlotTL[1] = this.pedalL - this.foamSlotWall - this.foamThickness;
   
      this.buttonPCBTL[0] = ((this.pedalW/2)-(buttonPCBDimension[0]/2));
      this.buttonPCBTL[1] = this.buttonActuatorY - (buttonPCBDimension[1]/2);
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






//--------------------------------------------------------------------------GCODE ZONE----------------------------------------
//--------------------------------------------------------------------------GCODE ZONE----------------------------------------
//--------------------------------------------------------------------------GCODE ZONE----------------------------------------
//--------------------------------------------------------------------------GCODE ZONE----------------------------------------
//--------------------------------------------------------------------------GCODE ZONE----------------------------------------
//--------------------------------------------------------------------------GCODE ZONE----------------------------------------
//--------------------------------------------------------------------------GCODE ZONE----------------------------------------

//gcode note.  Processing thinks of the top left corner as 0,0.  But on a cnc machine it's the bottom left corner, ir moving the head from 0,0  to  0,10 will go in the reverse direction as in Processing.
//

void exportGCode(){
   
  int job = 0;
  
  
  int in = 0;
  int out = 1;
  int corner = 0;
  int cent = 1;
  
  //job 0 is the base
  header();
    
   F.plus("F"+highSpeed);
   
   //mark screw locations for top cover
   drillHole(topCoverScrewClearance+0,(baseHeight-clickStack.defaultPedalL-topCoverScrewClearance)+0,-.5); //BL
   drillHole(topCoverScrewClearance+0,topCoverScrewClearance+0,-.5); //TL
   drillHole((clickStack.baseWidth-topCoverScrewClearance)+0,topCoverScrewClearance+0,-.5); //TR
   drillHole((clickStack.baseWidth-topCoverScrewClearance)+0,(baseHeight-clickStack.defaultPedalL-topCoverScrewClearance)+0,-.5); //BR
       
   F.plus("G01 Z2");
   F.plus("G00 F" + normalSpeed);
 
   for(float z = 0; z >= mcuH*-1; z -= normalStep){
     switch(mcuJackWall){
           case 0: 
                   rectangularFace((clickStack.mcuTL[0]) + 0, (clickStack.mcuTL[1]) +0,  mcuL,  mcuW,in,corner,z,toolR,2 ); //clickStack.mcu pocket
                   rectangularFace((clickStack.mcuTL[0])+0+((mcuL-(mcuL*clearanceFactor))/2),  (( clickStack.mcuTL[1] - mcuConnectionClearanceSize ))+0,  (mcuL*clearanceFactor),  (mcuW+(mcuConnectionClearanceSize*2)),in,corner,z,toolR,2  ); //extra relief for wires           
                 
                   break;
           case 1: 
                   rectangularFace((clickStack.mcuTL[0]) + 0, (clickStack.mcuTL[1]) +0,  mcuW,  mcuL,in,corner,z,toolR,2  ); //clickStack.mcu pocket
                   rectangularFace(((clickStack.mcuTL[0] - mcuConnectionClearanceSize)) + 0, (clickStack.mcuTL[1]) +0+((mcuL-(mcuL*clearanceFactor))/2), ( mcuW+mcuConnectionClearanceSize*2),  mcuL*clearanceFactor,in,corner,z,toolR,2  );               
                   
                   break;
           case 2:  
                   rectangularFace((clickStack.mcuTL[0]) + 0, (clickStack.mcuTL[1]) +0, mcuL,  mcuW,in,corner,z,toolR,2  ); //clickStack.mcu pocket
                   rectangularFace((clickStack.mcuTL[0])+0+((mcuL-(mcuL*clearanceFactor))/2),  (( clickStack.mcuTL[1] - mcuConnectionClearanceSize ))+0,  (mcuL*clearanceFactor),  (mcuW+(mcuConnectionClearanceSize*2)),in,corner,z,toolR,2  ); //extra relief for wires
                  
                   break;
         }
     }
     
     F.plus("G01 Z2");
     F.plus("G00 F" + normalSpeed);
     
     //usb recess
       switch(mcuJackWall){
           case 0:         
                   lineOptimized(0+0,  (clickStack.mcuTL[1]-(usbPanelL-mcuW)/2)  +0,  0+0,  ((clickStack.mcuTL[1]-(usbPanelL-mcuW)/2)+usbPanelL)+0,0,(mcuH+3)*-1,normalStep);
                   break;
           case 1:             
                   lineOptimized((clickStack.mcuTL[0]-(usbPanelL-mcuW)/2)  + 0,  0+0, ((clickStack.mcuTL[0]-(usbPanelL-mcuW)/2)+usbPanelL)+0,  0+0,0,(mcuH+3)*-1,normalStep);
                   break;
           case 2:  
                   lineOptimized(clickStack.baseWidth+0,  (clickStack.mcuTL[1]-(usbPanelL-mcuW)/2)  + 0,  clickStack.baseWidth+0,  ((clickStack.mcuTL[1]-(usbPanelL-mcuW)/2)+usbPanelL)+0,0,(mcuH+3)*-1,normalStep);
                   break;
         }
     
     
     F.plus("G01 Z2");
     F.plus("G00 F" + normalSpeed);
     
     //level 0 button related
     for(int i = 0; i < clickStack.numButtons; i++){
     
       if(clickStack.buttons[i].level == 0){ //any level 0 buttons end up in job0 where we cut the base.  Other ones get put into job1
       
         //general relief to leave a ledge
         for(float z = 0; z >= otherReliefDepth*-1; z -= normalStep){
           rectangularFace((clickStack.buttons[i].x) + 0, ((clickStack.buttons[i].y+clickStack.buttons[i].pedalLedgeW)) + 0 , clickStack.buttons[i].pedalW,clickStack.buttons[i].pedalL -clickStack.buttons[i].pedalLedgeW,in,corner,z,toolR,2 );
         }
         
         tabSize = 0;
         F.plus("G01 Z2");
         F.plus("G00 F" + normalSpeed);
         
         //foam slot
         for(float z = otherReliefDepth*-1; z >= (otherReliefDepth+4)*-1; z -= normalStep){
           rectangularFace( ((clickStack.buttons[i].foamSlotTL[0]+clickStack.buttons[i].x))+0,  ((clickStack.buttons[i].foamSlotTL[1]+clickStack.buttons[i].y))+0-toolR,  clickStack.buttons[i].foamSlotWidth,  clickStack.buttons[i].foamThickness,in,corner,z,toolR,2  );
         }
         
         F.plus("G01 Z2");
         F.plus("G00 F" + normalSpeed);
          
         //pcb holder
         for(float z = otherReliefDepth*-1; z >= buttonReliefDepth*-1; z -= normalStep){
           rectangularFace( ((clickStack.buttons[i].buttonPCBTL[0]+clickStack.buttons[i].x))+0,  ((clickStack.buttons[i].buttonPCBTL[1]+clickStack.buttons[i].y-actuatorPosOffset))+0,  buttonPCBDimension[0],  buttonPCBDimension[1],in,corner,z,toolR,2  );
         }
         
         F.plus("G01 Z2");
         F.plus("G00 F" + normalSpeed);
         
         //wire track in button are
         lineOptimized(((clickStack.buttons[i].x+(clickStack.buttons[i].pedalW/2))) + 0,((clickStack.buttons[i].y+clickStack.buttons[i].buttonActuatorY))+0,((clickStack.buttons[i].x+(clickStack.buttons[i].pedalW/2))) + 0,((clickStack.buttons[i].y+clickStack.buttons[i].pedalLedgeW))+toolR + 0,otherReliefDepth*-1,(otherReliefDepth+wireTrackDepth)*-1,normalStep);//first line reaches ledge.
         
         //carve thru ledge
         lineOptimized(((clickStack.buttons[i].x+(clickStack.buttons[i].pedalW/2))) + 0, ((clickStack.buttons[i].y+clickStack.buttons[i].pedalLedgeW)) + 0+toolR, ((clickStack.buttons[i].x+(clickStack.buttons[i].pedalW/2))) + 0, ((clickStack.buttons[i].y)) + 0 + toolR,0,(otherReliefDepth+wireTrackDepth)*-1,normalStep);//base level buttons carve thru the ledge.
         
         //screw locations 
         F.plus("G01 Z2");
         F.plus("G00 F" + normalSpeed);
         drillHole((clickStack.buttons[i].x+pedalScrewClearance)+0,(clickStack.buttons[i].y+clickStack.buttons[i].pedalLedgeW/2)+0,-.5);
         drillHole((clickStack.buttons[i].x+clickStack.buttons[i].pedalW-pedalScrewClearance)+0,(clickStack.buttons[i].y+clickStack.buttons[i].pedalLedgeW/2)+0,-.5);
         }
         
         //carve tracks into base to mcu pocket
         lineOptimized(((clickStack.buttons[i].x+(clickStack.buttons[i].pedalW/2))) + 0, ((clickStack.buttons[i].y)) + 0 + toolR,((clickStack.buttons[i].x+(clickStack.buttons[i].pedalW/2))) + 0,((clickStack.buttons[i].y-ledgeClearance)) + 0 + toolR,0,(otherReliefDepth+wireTrackDepth)*-1,normalStep);//carve straight out from edge of button before heading to mcu
         
         lineOptimized(((clickStack.buttons[i].x+(clickStack.buttons[i].pedalW/2))) + 0,((clickStack.buttons[i].y-ledgeClearance)) + 0 + toolR,clickStack.mcuCenter[0],clickStack.mcuCenter[1],0,(wireTrackDepth)*-1,normalStep);//now carve to mcu pocket 
         
     }//end button loop
     
     //outline base
     tabSize = 0; 
     for(float z = 0; z >= stockT*-1; z -= normalStep){
       if(z <= (stockT-defaultTabT) *-1){ tabSize = 20;}
       cutRectangle(0,0,clickStack.baseWidth,clickStack.baseHeight,out,corner,z,toolR,tabSize,2); 
     }
     tabSize = 0;
     
 
  footer();
  F.export("job" + job +".nc");
  println("exported job " + job + " to sketch folder"); 
  F.reset();

  job++;
  
  //-------------------------job1, higher level button stacks
  
  //button stack outline
         
         //this doesnt happen on level 0 buttons
         /*
         tabSize = 0;
         for(float z = 0; z >= stockT*-1; z -= normalStep){
           if(z <= (stockT-1) *-1){ tabSize = 10;}
           cutRectangle((clickStack.buttons[i].x)+0,(clickStack.buttons[i].y)+0,clickStack.buttons[i].pedalW,clickStack.buttons[i].pedalL,out,corner,z,toolR,0,2);
         }
         tabSize = 0;*/
         
}

void header(){
    F.plus("G17 G21 G90 G94 G40");
    F.plus("M05");
    F.plus("F" + normalSpeed+" S1000");
    F.plus("M03");
    F.plus("G00 Z2");
    F.plus("G00 X0 Y0"); 
}

void footer(){
    F.plus("G00 Z2");
    F.plus("M05");
    F.plus("M02"); 
}

void justALine(float xS, float yS, float xE, float yE, float z){
  
     F.plus("G01 X"+ze((xS)) + " Y" + ze((yS)));//inital positionning
     F.plus("F"+plungeSpeed);
     F.plus("G01 Z"+ze(z)); //go to requested depth
     F.plus("F"+normalSpeed);
  
     F.plus("G01 X"+ze(xE) + " Y" + ze(yE)); //move to end point
   
}
void lineOptimized(float xS, float yS, float xE, float yE, float zS, float zE, float step){//go back and forth, reducing z each time
    float z = zS;
    F.plus("G00 X"+ze((xS)) + " Y" + ze((yS)));//inital positionning
    while(z >= zE){
      F.plus("one side");
     F.plus("G01 X"+ze((xS)) + " Y" + ze((yS)));
     F.plus("F"+plungeSpeed);
     F.plus("G01 Z"+ze(z)); //go to requested depth
     F.plus("F"+normalSpeed);
     F.plus("G01 X"+ze(xE) + " Y" + ze(yE)); //move to end point
     z-= step;
     F.plus("z= " + z + ".  zE = " + zE);
     if(z < zE){ break;}
      F.plus("2 side");
     F.plus("F"+plungeSpeed);
     F.plus("G01 Z"+ze(z)); //go to requested depth
     F.plus("F"+normalSpeed);
     F.plus("G01 X"+ze(xS) + " Y" + ze(yS)); //move back to start
     z-= step;
     
    }
    
   
}
void drillHole(float x, float y, float zee){
       for(float z = 0; z >= zee; z -= .5){
           F.plus("F"+normalSpeed);
           F.plus("G01 X" + (x) + " Y" + (y));
           F.plus("F" + plungeSpeed);
           F.plus("G01 Z" + z);
           F.plus("F" + normalSpeed);
           F.plus("G01 Z" + (z+1));
         }
         
         F.plus("G00 Z2");
         F.plus("F"+normalSpeed);
}

void rectangularFace(float x, float y, float l, float w, int inOut, int cornOrCent, float z, float toolR, float stepover){
  //xy either refers to top left corner or to center. defined by cornOrCent
          
  
  if(cornOrCent == 0){  
  }
  else if(cornOrCent == 1){//we always compute rectangles from bottom left corner.  So to cut one thats centered on the xy we passed in, we simply pull that left corner back by l/2 and down by w/2
     x -= (l/2); y-= (w/2);
  }
  
  float centerPointX = x+(l/2);
  float centerPointY = y+(w/2);
  float currentX = x;
  float currentY = y;
  
  boolean flag = false;
  
  while(currentX != centerPointX && currentY != centerPointY){
    cutRectangle(currentX,currentY,l,w,inOut,2,z,toolR,tabSize,stepover);
    currentX += (toolR*2);
    currentY += (toolR*2);
    l -= (toolR*4);
    w -= (toolR*4);
    if(l < 0){ l = 0;}
    if(w < 0){ w = 0;}
    if(currentX > centerPointX ){ currentX = centerPointX;}
    if(currentY > centerPointY){ currentY = centerPointY; }
    
  }

     //run straight down the center, this helps avoid any rags
     if(w == 0){
       cutRectangle(centerPointX-(l/2)-toolR,centerPointY,l+(toolR*2),w,inOut,2,z,0,0,stepover); //finish off center
     }
     else if(l == 0){
       cutRectangle(centerPointX,centerPointY-(w/2)-toolR,l,w+(toolR*2),inOut,2,z,0,0,stepover); //finish off center
     }
     //justALine(centerPointX-(l/2)-toolR,centerPointY,l+(toolR*2),w,2,2,z,toolR,0,stepover); //finish off center
  
  F.plus("G01 Z" + (z+stepover));
}

void cutRectangle(float x, float y,float l, float w, int inOut, int cornOrCent, float z,  float toolR, float tabSize,float stepover){
  
  float modX = 0;
  float modY = 0;
  float a,b,hyp,theta;
  
  if(cornOrCent == 0){//coords indicatebottom left corner, offset circle position
    
  }
  else if(cornOrCent == 1){
     x -= (l/2); y -= (w/2);
  }
 
  
  //when inout is 0 we are cutting an ID rectangle.  When inout is 1 we're cutting an OD rectangle
  //retangles always start from bottom left corner.
  
   if(tabSize == 0){
     
     if(inOut == 0){modX = toolR;modY = toolR; }else if(inOut == 1){modX = (toolR*-1); modY = (toolR*-1);}
     F.plus("G01 X"+(x+modX) + " Y" + (y+modY));//inital positionning
     F.plus("F"+plungeSpeed);
     F.plus("G01 Z"+z);
     F.plus("F"+normalSpeed);
     if(inOut == 0){modX = toolR;modY = (toolR*-1); }else if(inOut == 1){modX = (toolR*-1); modY = (toolR);}
     F.plus("G01 X"+(x+modX) + " Y" + (y+modY+w));
     
     if(inOut == 0){modX = (toolR*-1);modY = (toolR*-1); }else if(inOut == 1){modX = (toolR); modY = (toolR);}
     F.plus("G01 X"+(x+modX+l) + " Y" + (y+modY+w));
     
     if(inOut == 0){modX = (toolR*-1);modY = toolR; }else if(inOut == 1){modX = (toolR); modY = (toolR*-1);}
     F.plus("G01 X"+(x+modX+l) + " Y" + (y+modY));
     
     if(inOut == 0){modX = toolR;modY = toolR; }else if(inOut == 1){modX = (toolR*-1); modY = (toolR*-1);}
     F.plus("G01 X"+(x+modX) + " Y" + (y+modY)); //return to start
   }
   else{
     
     //it's just easier to do this if our rectangle is defined in an array format
     float[][] points = { {x,y},
                          {x,y+w},
                          {x+l,y+w},
                          {x+l,y},
                          {x,y},
                         };
  
     float[][][] mods = {  { {1,1},{1,-1}, {-1,-1},{-1,1},{1,1} },  { {-1,-1},{-1,1},{1,1},{1,-1},{-1,-1}}  };
     
     for(int i = 0; i < 4; i++){
       
       a = abs((points[i+1][0]+(toolR*mods[inOut][i+1][0])) - (points[i][0]+toolR*mods[inOut][i][0]));
       b = abs((points[i+1][1]+toolR*mods[inOut][i+1][1]) - (points[i][1]+toolR*mods[inOut][i][1]));
       hyp = sqrt(pow(a,2) + pow(b,2));
       theta = atan(b/a);
       
       if(points[i+1][0] < points[i][0]){ 
              theta += PI;
       }
       else if(points[i+1][1] < points[i][1]){
          theta += PI; 
       }
       
       F.plus("G01 X"+(points[i][0]+(toolR*mods[inOut][i][0])) + " Y" + (points[i][1]+toolR*mods[inOut][i][1]));//inital positionning
        F.plus("F"+plungeSpeed);
        F.plus("G01 Z"+z);
        F.plus("F"+normalSpeed);
       
       F.plus("G01 X"+ ze(((toolR*mods[inOut][i][0])+points[i][0] + (((hyp/2)-(tabSize/2))*cos(theta)))) + "Y" + ze(((toolR*mods[inOut][i][1])+points[i][1] + (((hyp/2)-(tabSize/2))*sin(theta)))));//over
       F.plus("G01 Z" + (z+stepover));//up
       F.plus("G01 X"+ ze(((toolR*mods[inOut][i][0])+points[i][0] + (((hyp/2)+(tabSize/2))*cos(theta)))) + "Y" + ze(((toolR*mods[inOut][i][1])+points[i][1] + (((hyp/2)+(tabSize/2))*sin(theta)))));//over
        F.plus("F"+plungeSpeed);
       F.plus("G01 Z"+z);//down
       F.plus("F"+normalSpeed);
       F.plus("G01 X"+ ((toolR*mods[inOut][i][0])+points[i+1][0]) + "Y" + ((toolR*mods[inOut][i][1])+points[i+1][1]) );//next point
     
     }
   }
}

void cutCircle(int inOut,int cornOrCent,float xCent, float yCent, float z,  float r,float toolR,float tabAmount, float stepover,int speed){
  //(tab amount is in degrees)
 
  if(inOut == 0){
    r -= toolR; //if r is referring to ID, SUBTRACT toolR
  }
  else if(inOut == 1){
    r += toolR; //if r is referring to OD, ADD toolR
  }
  
  if(cornOrCent == 0){//coords indicatebottom left corner, offset circle position
     xCent += r; yCent += r;
  }
 
      F.plus("G01 " + "X"+fmt((cos(radians(180-tabAmount))*r) + xCent) + " Y"+ fmt((sin(radians(180-tabAmount))*r) + yCent)); //initial pos
      F.plus("F" + speed);
      F.plus("G02 X"+fmt((cos(radians(180-tabAmount))*r) + xCent) + " Y"+ fmt((sin(radians(180-tabAmount))*r) + yCent)  + " R" + r) ;
      F.plus("F" + plungeSpeed);
      F.plus("G01 Z"+z);
      
      F.plus("F" + speed);
      F.plus("G02 " + "X"+fmt((cos(radians(90+tabAmount))*r) + xCent) + " Y"+ fmt((sin(radians(90+tabAmount))*r) + yCent) + " R" + r);
      if(tabAmount == 0){F.plus("F" + plungeSpeed); F.plus("G01 Z"+z); } 
      else{F.plus("G01 Z"+(z+stepover));}
      F.plus("F" + speed);
      F.plus("G02 " + "X"+fmt((cos(radians(90-tabAmount))*r) + xCent) + " Y"+ fmt((sin(radians(90-tabAmount))*r) + yCent) + " R" + r);
      F.plus("F" + plungeSpeed);
      F.plus("G01 Z"+z);
      F.plus("F" + speed);
      
      F.plus("G02 " + "X"+fmt((cos(radians(0+tabAmount))*r) + xCent) + " Y"+ fmt((sin(radians(0+tabAmount))*r) + yCent) + " R" + r);
      if(tabAmount == 0){F.plus("F" + plungeSpeed); F.plus("G01 Z"+z); } 
      else{F.plus("G01 Z"+(z+stepover));}
      F.plus("F" + speed);
      F.plus("G02 " + "X"+fmt((cos(radians(360-tabAmount))*r) + xCent) + " Y"+ fmt((sin(radians(360-tabAmount))*r) + yCent) + " R" + r);
      F.plus("F" + plungeSpeed);
      F.plus("G01 Z"+z);
      F.plus("F" + speed);
      
      F.plus("G02 " + "X"+fmt((cos(radians(270+tabAmount))*r) + xCent) + " Y"+ fmt((sin(radians(270+tabAmount))*r) + yCent) + " R" + r);
      if(tabAmount == 0){F.plus("F" + plungeSpeed); F.plus("G01 Z"+z); } 
      else{F.plus("G01 Z"+(z+stepover));}
      F.plus("F" + speed);
      F.plus("G02 " + "X"+fmt((cos(radians(270-tabAmount))*r) + xCent) + " Y"+ fmt((sin(radians(270-tabAmount))*r) + yCent) + " R" + r);
      F.plus("F" + plungeSpeed);
      F.plus("G01 Z"+z);
      F.plus("F" + speed);
      
      F.plus("G02 " + "X"+fmt((cos(radians(180+tabAmount))*r) + xCent) + " Y"+ fmt((sin(radians(180+tabAmount))*r) + yCent) + " R" + r);
      if(tabAmount == 0){F.plus("F" + plungeSpeed); F.plus("G01 Z"+z); } 
      else{F.plus("G01 Z"+(z+stepover));}
      F.plus("F" + speed);
}

float fmt(float n){
   return parseFloat(nf(n,0,2));
}

float ze(float in){

  if(in >= 0 && in < .01){
    return 0; 
  }
  else if(in < 0 && in > -.01) {
    return 0;
  }
  else{
    return in; 
  }
}

class OutputFile{
  
  String[] data;
  int index;
  
  public OutputFile(int s){
    data = new String[s]; 
    index = 0;
  }
  public void plus(String s){
    data[index] = s;
    index++;
  }
  public void export(String name){
    String[] output = new String[index];
    
    //otherwise the unfilled spaces in the original data array will print 'null' to the txt file.
    for(int i = 0; i < index; i++){
      output[i] = data[i];
    }
    
    saveStrings(name, output);
  }
  public void reset(){
    index = 0; 
  }
}
