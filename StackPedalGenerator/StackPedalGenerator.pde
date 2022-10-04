/* StackPedal Generator
   2022 Matt Ronan
   https://github.com/MattRonan/StackPedal
   
   A program to generate gcode and a printable template
   for a custom StackPedal.
  
   *Be sure to set the values in the 'USER VALUES' box below*
   
   *ALL DIMENSIONS ARE IN MM*
   
*/

import java.awt.*;
import java.awt.event.*;
import java.io.*;

//-----------------------~~!!!! USER VALUES !!!!
//------CNC MACHINE RELATED---
float toolR = 1.5;         //** measure your bit, divide by 2.  A 3mm (1/8") bit is recommended
float woodStockT = 12.5;   //** the thickness of your wooden board.  Determines the thickness of each stack level.
float woodStockW = 140;    //** the width of your woodenboard.  This is important for the calculation of layout of the stacks in job1
float plasticStockT = 1.5; //** thickness of the plastic used for the electronics cover and the presser panels.

int highSpeed = 750;       //set these speeds and steps to what your machine needs. THESE ARE CURRENTLY SET FOR PINE on a small machine.  If you use a harder wood make sure these aren't too agressive for your machine.
int normalSpeed = 500;
int lowSpeed = 250;
int plungeSpeed = 50;
float bigStep = 2;          //steps are how deep each pass is on the z axis
float normalStep = 1;
float smallStep = .5;
float microStep = .25;  
float defaultTabT = 2;      //default tab thickness.  width is set per procedure down in GCode Zone
float stepover = 2;         //default stepover

//----TEMPLATE SCALE RELATED
float sF = 5.25;//scale factor of the pixels for the drawing of the design. depnding on your screen it may not be equally accurate in BOTH x and y.  TODO, a way to export a png thats unit-based instead of using saveFrame?

//----UNIVERSAL DESIGN SETTINGS
float baseHeight = 125; //the dimension of the base measured parallel to the pedals. ie this minus stackL is how much space is left for the microcontroller area.
float mcuW = 17.5; //the width of your microcontroller.  These dimensions are an Elegoo Arduino Nano
float mcuL = 43;//the length of your microcontroller. 
float mcuH = 7.5; //the total height of your microcontroller.  This determines how deep the mcu pocket will be.
float mcuUSBW = 7.5; //width of usb jack.  Determines width of opening in plactic side panel.
float mcuUSBH = 3.75; //height of usb jack.  Determines how tall the opening is in the plastic side panel.
float usbPanelBottomMargin = 3; //plastic USB panel will cover the entire depth of the MCU pocket + this value.  ie this + mcuH = the height of your usb cover panel
float mcuUSBHeightOffset = 0;// on some boards such as ESP32, the usb jack might not be the highest point.  This is how much lower the usb jack is than the highest point.  (highest point in those cases is usually a PH connector)
int mcuJackWall = 1;  //Which wall does the jack come out of.  0 = left side, 1 = back side, 2 = right side 
float mcuJackPos = .5; //shift the location of the jack by inputting a value from 0-1.  .5 puts it in the middle of that wall.
float mcuConnectionClearanceSize = 5; //open up some space around mcu to help wires fit in easier.  this is how far it extends out from the pins. 
float clearanceFactor = .65;//Percent of material to remove along mcu pocket sides.  greater than .75 is going to risk the mcu not being held in place as sungly.
float usbPanelL = mcuW + 20; // 20 gives 10mm on each side for the mounting screws for the usb panel.  More isnt neccessary and less might cause structural issues, especially if the wood is pine.
float presserPanelScrewClearance = 8; //2 screws hold in each presser panel.  Holes are drilled this distance from right and left side.  For extra long panels, you may want to add a 3rd middle screw by hand.
float topCoverScrewClearance = 4; //distance of screw holes from edges on top cover
float buttonReliefDepth = 8; //section where button+PCB sits.  with a 5mm button and the 1.6mm board+solder joints, there should be .5mm to 1mm of clearance for the button
float otherReliefDepth = 5; //where the button isnt, remove enough material so that the plastic presser panels dont get blocked by wood when pressed.
float wireTrackDepth = 3; //depth of tracks leading to the mcu pocket
float ledgeClearance = 6; //distance out from top side of pedal to carve straight before heading to mcu
float stackL = 72; //length of button stacks.  
float stackLedgeW = 15; //plastic presser panel screws into here. 15mm is usually fine.

//----PER-STACK DESIGN SETTINGS
//(these can be customized per button stack in setup below)
float defaultStackW = 43; //if you want to make a stack wider, say 1 wide middle stack and 2 thinner outers, you can set them individually after this
float defaultStackMargin = 2; //margin between stacks.  Doesnt get applied to the 2 outside edges.  
float defaultFoamThickness = 6.0; //foam slot width.  This is set to use 6mm foam that you can find at Michaels or online.
float defaultFoamSlotWall = 4; //thickness of the front foam slot wall
//------------------------------------------------------------

float[] buttonPCBDimension = {18,12}; //the official PCB is on osh park at https://oshpark.com/shared_projects/baTaN6WL
float actuatorPosOffset = 1.5;  //button on official pcbs is not directly in the center, so this offset accounts for that.

StackPedalManager pedalManager = new StackPedalManager(); 

int escapeTime = 0;

boolean drawDesign = true;

float tabSize = 0; //this gets set per procedure in the gCode zone. ctrl+f to search for 'tabSize =' and you can easily find where 

OutputFile F = new OutputFile(60000);

void setup() {
  
  size(1500, 800);

  //big center button layout
  /*
  pedalManager.addButton(2); //add buttons from left to right, specifying their level. For level 0 relief gets carved into base board, 1 or higher gets cut as a separate piece to be glued on.
  pedalManager.addButton(1); //the buttons ID depends on the order you add them
  pedalManager.addButton(0);
  pedalManager.addButton(1);
  pedalManager.addButton(2);  
  pedalManager.setButtonWidth(0,25);//use button ID followed by value
  pedalManager.setButtonWidth(1,45);//use button ID followed by value
  pedalManager.setButtonWidth(2,120);//use button ID followed by value
  pedalManager.setButtonWidth(3,45);//use button ID followed by value
  pedalManager.setButtonWidth(4,25);//use button ID followed by value
  *
  
  //classic 3-stack
  /*
  pedalManager.addButton(0); //add buttons from left to right, specifying their level. For level 0 relief gets carved into base board, 1 or higher gets cut as a separate piece to be glued on.
  pedalManager.addButton(1); //the buttons ID depends on the order you add them
  pedalManager.addButton(2);
  */
  
  //lil 2 stack
  
  pedalManager.addButton(0); //add buttons from left to right, specifying their level. For level 0 relief gets carved into base board, 1 or higher gets cut as a separate piece to be glued on.
  pedalManager.addButton(1); //the buttons ID depends on the order you add them
  pedalManager.setButtonWidth(0,115);//use button ID followed by value
  
}


void draw() {
 
  if(drawDesign){
    background(255);
    drawGrid();
    fill(150,0,255);
    stroke(0);
    text("Press 'p' to export png template for print. (Properly set sF first so that this image is a 1:1 scale)",5,12);
    text("Press 'g' to export G Code",5,27);
    text("(Click inside window first or button presses won't register)",5,42);
    pedalManager.update();
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
    
    
    escapeTime = millis() + 120;
  }  
}

void drawGrid(){
   float inc = 1;
   float major = 5;
   
   for(int y = 0; y < height; y += inc){
     if(y%major == 0){ stroke(0,30);}
     else{ stroke(0,10);}
     line(0*sF,y*sF,width*sF,y*sF);      
   }
   
   for(int x = 0; x < width; x += inc){
     if(x % major == 0){ stroke(0,30);}
     else{ stroke(0,10);}
     line(x*sF,0*sF,x*sF,height*sF);      
   }
   
}


class StackPedalManager{
  
  public float baseWidth = 0; 
 
  public int numButtons = 0;
  
  public float[] origin = {20,60}; //top left corner of base in pixels for drawing.  For gCode origin is always 0,0
 
  float[] mcuCenter = {0,0};
  float[] mcuTL = {0,0};
  
  ButtonStack[] buttons = new ButtonStack[20]; 
  
  public StackPedalManager(){

  }
  
  public void addButton(int level){
    buttons[numButtons] = new ButtonStack(level);
    numButtons++;
    recalculatePedal();
  }
   
  public void recalculatePedal(){
    baseWidth = 0;
    
    for(int i = 0; i < numButtons; i++){
      
      buttons[i].y = baseHeight - stackL; //we think from top left corner down since thats how P draws stuff.  So button coords refer to the top left corner of the button.
       
      if(i != 0){

         baseWidth += buttons[i].stackMargin;
      }

      buttons[i].x = baseWidth;
      baseWidth += buttons[i].stackW;
    }
    
    switch(mcuJackWall){
         case 0: mcuTL[0] = plasticStockT;//this looks wierd but its just that we recess the plastic usb panel, which pushes the mcu right in this case, where it would otherwise be at 0
                 mcuTL[1] = (baseHeight-stackL)*mcuJackPos-(mcuW/2);
                 mcuCenter[0] = mcuTL[0] + mcuL/2;
                 mcuCenter[1] = mcuTL[1] +(mcuW/2);
                 break;
         case 1: mcuTL[0] = (baseWidth*mcuJackPos) - (mcuW/2);
                 mcuTL[1] = plasticStockT;
                 mcuCenter[0] = mcuTL[0] + mcuW/2;
                 mcuCenter[1] = mcuTL[1] +(mcuL/2);
                 break;
         case 2:  mcuTL[0] = baseWidth-mcuL;//this looks wierd but its just that we recess the plastic usb panel, which pushes the mcu right in this case, where it would otherwise be at 0
                 mcuTL[1] = (baseHeight-stackL)*mcuJackPos-(mcuW/2);
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
     rect(origin[0],origin[1],baseWidth*sF,baseHeight*sF);
 
     //mcu and related pockets
       stroke(252,50,100);
       strokeWeight(3);
       switch(mcuJackWall){
         case 0: 
                 rect((mcuTL[0]*sF) + origin[0], (mcuTL[1]*sF) + origin[1],  mcuL*sF,  mcuW*sF  ); //mcu pocket
                 rect((mcuTL[0]*sF)+origin[0]+((mcuL-(mcuL*clearanceFactor))/2*sF),  (( mcuTL[1] - mcuConnectionClearanceSize )*sF)+origin[1],  (mcuL*clearanceFactor)*sF,  (mcuW+(mcuConnectionClearanceSize*2))*sF  ); //extra relief for wires
                 strokeWeight(5);
                 line(0+origin[0],  (mcuTL[1]-(usbPanelL-mcuW)/2) * sF +origin[1],  0+origin[0],  ((mcuTL[1]-(usbPanelL-mcuW)/2)+usbPanelL)*sF+origin[1]);
                 strokeWeight(4);
                 break;
         case 1: 
                 rect((mcuTL[0]*sF) + origin[0], (mcuTL[1]*sF) + origin[1],  mcuW*sF,  mcuL*sF  ); //mcu pocket
                 rect(((mcuTL[0] - mcuConnectionClearanceSize)*sF) + origin[0], (mcuTL[1]*sF) + origin[1]+((mcuL-(mcuL*clearanceFactor))/2*sF), ( mcuW+mcuConnectionClearanceSize*2)*sF,  mcuL*sF*clearanceFactor  ); 
                 strokeWeight(5);
                 line((mcuTL[0]-(usbPanelL-mcuW)/2) * sF + origin[0],  0+origin[1], ((mcuTL[0]-(usbPanelL-mcuW)/2)+usbPanelL)*sF+origin[0],  0+origin[1]);
                 strokeWeight(4);
                 break;
         case 2:  
                 rect((mcuTL[0]*sF) + origin[0], (mcuTL[1]*sF) + origin[1],  mcuL*sF,  mcuW*sF  ); //mcu pocket
                 rect((mcuTL[0]*sF)+origin[0]+((mcuL-(mcuL*clearanceFactor))/2*sF),  (( mcuTL[1] - mcuConnectionClearanceSize )*sF)+origin[1],  (mcuL*clearanceFactor)*sF,  (mcuW+(mcuConnectionClearanceSize*2))*sF  ); //extra relief for wires
                 strokeWeight(5);
                 line(baseWidth*sF+origin[0],  (mcuTL[1]-(usbPanelL-mcuW)/2) * sF +origin[1],  baseWidth*sF+origin[0],  ((mcuTL[1]-(usbPanelL-mcuW)/2)+usbPanelL)*sF+origin[1]);
                 strokeWeight(4);
                 break;
     
       }
       
     //draw buttons
     for(int i = 0; i < numButtons; i++){
     
       //button outlines
       strokeWeight(3);
       stroke(145,0,255);
       rect((buttons[i].x*sF)+origin[0],(buttons[i].y*sF)+origin[1],buttons[i].stackW*sF,stackL*sF);
      
       //foam slots
       stroke(102,100,255);
       rect( ((buttons[i].foamSlotTL[0]+buttons[i].x)*sF)+origin[0],  ((buttons[i].foamSlotTL[1]+buttons[i].y)*sF)+origin[1],  buttons[i].foamSlotWidth*sF,  buttons[i].foamThickness*sF  );
       
       //ledges
       stroke(0,200,255);
       line((buttons[i].x*sF) + origin[0], ((buttons[i].y+stackLedgeW)*sF) + origin[1] , ((buttons[i].x+buttons[i].stackW)*sF)+ origin[0], ((buttons[i].y+stackLedgeW)*sF) + origin[1]);
       
       //button PCB pockets
       if(buttons[i].level == 0){
         stroke(102,250,55);//green are tracks routed directly into the base
       }
       else{
         stroke(252,100,55);//orange are tracks that are routed into a separate pedal piece.  ie buttons that are level 1 or higher.  The a diagnal hand-drilled hole connects it to the track in the base.
       }
       
       rect( ((buttons[i].buttonPCBTL[0]+buttons[i].x)*sF)+origin[0],  ((buttons[i].buttonPCBTL[1]+buttons[i].y-actuatorPosOffset)*sF)+origin[1],  buttonPCBDimension[0]*sF,  buttonPCBDimension[1]*sF  );
       
       //wire tracks
       line(((buttons[i].x+(buttons[i].stackW/2))*sF) + origin[0],((buttons[i].y+buttons[i].buttonActuatorY)*sF)+origin[1],((buttons[i].x+(buttons[i].stackW/2))*sF) + origin[0],((buttons[i].y+stackLedgeW)*sF) + origin[1]);//first line reaches ledge.
       
       if(buttons[i].level == 0){
         line(((buttons[i].x+(buttons[i].stackW/2))*sF) + origin[0], ((buttons[i].y+stackLedgeW)*sF) + origin[1], ((buttons[i].x+(buttons[i].stackW/2))*sF) + origin[0], ((buttons[i].y)*sF) + origin[1]);//base level buttons carve thru the ledge.
       }
       
       stroke(102,250,55);
       line(((buttons[i].x+(buttons[i].stackW/2))*sF) + origin[0], ((buttons[i].y)*sF) + origin[1],((buttons[i].x+(buttons[i].stackW/2))*sF) + origin[0],((buttons[i].y-ledgeClearance)*sF) + origin[1]);//carve straight out from edge of button before heading to mcu
       
       line(((buttons[i].x+(buttons[i].stackW/2))*sF) + origin[0],((buttons[i].y-ledgeClearance)*sF) + origin[1],mcuCenter[0]*sF+origin[0],mcuCenter[1]*sF+origin[1]);//now carve to mcu pocket

       //actuator locations
       stroke(250,0,55);
       circle(((buttons[i].x+(buttons[i].stackW/2))*sF) + origin[0],((buttons[i].y+buttons[i].buttonActuatorY)*sF)+origin[1],6);

       //screw locactions
       stroke(100,100,5);
       //peeal screws
       circle((buttons[i].x+presserPanelScrewClearance)*sF+origin[0],(buttons[i].y+stackLedgeW/2)*sF+origin[1],toolR*2*sF);
       circle((buttons[i].x+buttons[i].stackW-presserPanelScrewClearance)*sF+origin[0],(buttons[i].y+stackLedgeW/2)*sF+origin[1],toolR*2*sF);
       
       //top cover screws.  For now it just does 4 corner screws.  If you need more its easy to add them by hand, since the 4 done by the machine will hold it perfectly aligned.  TODO, ability to add more screws in specific locations
       
       circle(topCoverScrewClearance*sF+origin[0],(baseHeight-stackL-topCoverScrewClearance)*sF+origin[1],toolR*2*sF); //BL
       circle(topCoverScrewClearance*sF+origin[0],topCoverScrewClearance*sF+origin[1],toolR*2*sF); //TL
       circle((baseWidth-topCoverScrewClearance)*sF+origin[0],topCoverScrewClearance*sF+origin[1],toolR*2*sF); //TR
       circle((baseWidth-topCoverScrewClearance)*sF+origin[0],(baseHeight-stackL-topCoverScrewClearance)*sF+origin[1],toolR*2*sF); //BR
      
       //draw info
       text("Level = " + buttons[i].level, ((buttons[i].buttonPCBTL[0]+buttons[i].x)*sF)+origin[0],  ((buttons[i].buttonPCBTL[1]+buttons[i].y+ buttonPCBDimension[1]+3)*sF)+origin[1]);
     
     
     }//end button loop
     
  }
  public void setButtonWidth(int id, float val){
     buttons[id].stackW = val;
     buttons[id].recalculate(); //need to recalculate foam slot, button pcb relief location, et      
     this.recalculatePedal(); //then need to update the whole pedal.
  }
   
  
  class ButtonStack{
      
    public float stackW;
    public float stackMargin;
    public float foamThickness;
    public float foamSlotWall;
    
    public float x,y;
    public int level;
    
    public float[] foamSlotTL = new float[2];
    public float foamSlotWidth; 
    float foamSlotPercent = .5; //percent of total width (.5 is a good value typically
    
    public float buttonActuatorY; 
    public float[] buttonPCBTL = new float[2];
    
    public ButtonStack(){
      
    }
  
    public ButtonStack(int level){
      stackW = defaultStackW;
      stackMargin =  defaultStackMargin;
      foamThickness = defaultFoamThickness;
      foamSlotWall =  defaultFoamSlotWall;
      buttonActuatorY = ((stackL-stackLedgeW)/2) + (stackLedgeW);//the y positionn of the actual clicky button plunger
      this.level = level;
      this.recalculate();
    }
    
    public void recalculate(){
      this.foamSlotWidth = this.stackW * this.foamSlotPercent;
      this.foamSlotTL[0] = ((stackW-foamSlotWidth) * this.foamSlotPercent);//basically from the buttons perspective, TL of button is 0,0
      this.foamSlotTL[1] = stackL - this.foamSlotWall - this.foamThickness;
   
      this.buttonPCBTL[0] = ((this.stackW/2)-(buttonPCBDimension[0]/2));
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
  
  
  //-------------------------------------------------------------Job 0 , base
  header();
    
   F.plus("F"+highSpeed);
   
   float invY = -1; //cutting the bass requires flipping y-axis, otherwise it will cut as a mirror image of what you designed due to how Processing defines the y axis.
                    //you could flip the drawing instead but it doesn't really matter.
   
   //mark screw locations for top cover
   drillHole(topCoverScrewClearance+0,(baseHeight-stackL-topCoverScrewClearance)*invY,-.5); //BL
   drillHole(topCoverScrewClearance+0,topCoverScrewClearance*invY,-.5); //TL
   drillHole((pedalManager.baseWidth-topCoverScrewClearance)+0,topCoverScrewClearance*invY,-.5); //TR
   drillHole((pedalManager.baseWidth-topCoverScrewClearance)+0,(baseHeight-stackL-topCoverScrewClearance)*invY,-.5); //BR
       
   F.plus("G01 Z2");
   F.plus("G00 F" + normalSpeed);
 
   for(float z = 0; z >= mcuH*-1; z -= normalStep){
     switch(mcuJackWall){
           case 0: 
                   rectangularFace((pedalManager.mcuTL[0]) + 0, (pedalManager.mcuTL[1]) *invY,  mcuL,  mcuW*invY,in,corner,z,toolR,stepover ); //pedalManager.mcu pocket
                   rectangularFace((pedalManager.mcuTL[0])+0+((mcuL-(mcuL*clearanceFactor))/2),  (( pedalManager.mcuTL[1] - mcuConnectionClearanceSize ))*invY,  (mcuL*clearanceFactor),  (mcuW+(mcuConnectionClearanceSize*2))*invY,in,corner,z,toolR,stepover  ); //extra relief for wires           
                 
                   break;
           case 1: 
                   rectangularFace((pedalManager.mcuTL[0]) + 0, (pedalManager.mcuTL[1]) *invY,  mcuW,  mcuL*invY,in,corner,z,toolR,stepover  ); //pedalManager.mcu pocket
                   rectangularFace(((pedalManager.mcuTL[0] - mcuConnectionClearanceSize)) + 0, ((pedalManager.mcuTL[1]) +0+((mcuL-(mcuL*clearanceFactor))/2))*invY, ( mcuW+mcuConnectionClearanceSize*2),  mcuL*clearanceFactor*invY,in,corner,z,toolR,stepover  );               
                   
                   break;
           case 2:  
                   rectangularFace((pedalManager.mcuTL[0]) + 0, (pedalManager.mcuTL[1]) *invY, mcuL,  mcuW*invY,in,corner,z,toolR,stepover  ); //pedalManager.mcu pocket
                   rectangularFace((pedalManager.mcuTL[0])+0+((mcuL-(mcuL*clearanceFactor))/2),  (( pedalManager.mcuTL[1] - mcuConnectionClearanceSize ))*invY,  (mcuL*clearanceFactor),  (mcuW+(mcuConnectionClearanceSize*2))*invY,in,corner,z,toolR,stepover  ); //extra relief for wires
                  
                   break;
         }
     }
     
     F.plus("G01 Z2");
     F.plus("G00 F" + normalSpeed);
     
     //usb recess
     switch(mcuJackWall){
         case 0:         
                 lineOptimized(0+0,  (pedalManager.mcuTL[1]-(usbPanelL-mcuW)/2)*invY,  0,  ((pedalManager.mcuTL[1]-(usbPanelL-mcuW)/2)+usbPanelL)*invY,0,(mcuH+usbPanelBottomMargin)*-1,normalStep);
                 break;
         case 1:             
                 lineOptimized((pedalManager.mcuTL[0]-(usbPanelL-mcuW)/2),  0, ((pedalManager.mcuTL[0]-(usbPanelL-mcuW)/2)+usbPanelL), 0,0,(mcuH+usbPanelBottomMargin)*-1,normalStep);
                 break;
         case 2:  
                 lineOptimized(pedalManager.baseWidth+0,  (pedalManager.mcuTL[1]-(usbPanelL-mcuW)/2)*invY,  pedalManager.baseWidth+0,  ((pedalManager.mcuTL[1]-(usbPanelL-mcuW)/2)+usbPanelL)*invY,0,(mcuH+usbPanelBottomMargin)*-1,normalStep);
                 break;
       }
   
   
   F.plus("G01 Z2");
   F.plus("G00 F" + normalSpeed);
   
   //level 0 button related
   for(int i = 0; i < pedalManager.numButtons; i++){
   
     if(pedalManager.buttons[i].level == 0){ //any level 0 buttons end up in job0 where we cut the base.  Other ones get put into job1
     
       //general relief to leave a ledge
       for(float z = 0; z >= otherReliefDepth*-1; z -= normalStep){
                                                         //note for level0 buttons, we cut it wider than the outline dictates (hence the defaultStackMargin subtraction and then increasing W by margin*2) cause otherwise the presser panel would get hung up on the wood.  Not a problem for higher level buttons.
         rectangularFace((pedalManager.buttons[i].x) + 0-pedalManager.buttons[i].stackMargin, ((pedalManager.buttons[i].y+stackLedgeW))*invY  , pedalManager.buttons[i].stackW + (pedalManager.buttons[i].stackMargin*2),(stackL-stackLedgeW)*invY,in,corner,z,toolR,stepover );
       }
       
       tabSize = 0;
       F.plus("G01 Z2");
       F.plus("G00 F" + normalSpeed);
       
       //foam slot
       for(float z = otherReliefDepth*-1; z >= (otherReliefDepth+4)*-1; z -= normalStep){
         rectangularFace( ((pedalManager.buttons[i].foamSlotTL[0]+pedalManager.buttons[i].x))+0,  (((pedalManager.buttons[i].foamSlotTL[1]+pedalManager.buttons[i].y))+0-toolR)*invY,  pedalManager.buttons[i].foamSlotWidth,  pedalManager.buttons[i].foamThickness*invY,in,corner,z,toolR,stepover  );
       }
       
       F.plus("G01 Z2");
       F.plus("G00 F" + normalSpeed);
        
       //pcb holder
       for(float z = otherReliefDepth*-1; z >= buttonReliefDepth*-1; z -= normalStep){
         rectangularFace( ((pedalManager.buttons[i].buttonPCBTL[0]+pedalManager.buttons[i].x))+0,  ((pedalManager.buttons[i].buttonPCBTL[1]+pedalManager.buttons[i].y-actuatorPosOffset))*invY,  buttonPCBDimension[0],  buttonPCBDimension[1]*invY,in,corner,z,toolR,stepover  );
       }
       
       F.plus("G01 Z2");
       F.plus("G00 F" + normalSpeed);
       
       //wire track in button area
       lineOptimized(((pedalManager.buttons[i].x+(pedalManager.buttons[i].stackW/2))) + 0,((pedalManager.buttons[i].y+pedalManager.buttons[i].buttonActuatorY))*invY,((pedalManager.buttons[i].x+(pedalManager.buttons[i].stackW/2))) + 0,(((pedalManager.buttons[i].y+stackLedgeW))+toolR)*invY,otherReliefDepth*-1,(otherReliefDepth+wireTrackDepth)*-1,normalStep);//first line reaches ledge.
       
       //carve thru ledge
       lineOptimized(((pedalManager.buttons[i].x+(pedalManager.buttons[i].stackW/2))) + 0, (((pedalManager.buttons[i].y+stackLedgeW)) + toolR)*invY, ((pedalManager.buttons[i].x+(pedalManager.buttons[i].stackW/2))) + 0, (((pedalManager.buttons[i].y)) + toolR)*invY,0,(otherReliefDepth+wireTrackDepth)*-1,normalStep);//base level buttons carve thru the ledge.
       
       //screw locations 
       F.plus("G01 Z2");
       F.plus("G00 F" + normalSpeed);
       drillHole((pedalManager.buttons[i].x+presserPanelScrewClearance)+0,(pedalManager.buttons[i].y+stackLedgeW/2)*invY,-.5);
       drillHole((pedalManager.buttons[i].x+pedalManager.buttons[i].stackW-presserPanelScrewClearance)+0,(pedalManager.buttons[i].y+stackLedgeW/2)*invY,-.5);
       }
       
       //carve tracks into base to mcu pocket
       lineOptimized(((pedalManager.buttons[i].x+(pedalManager.buttons[i].stackW/2))) + 0, (((pedalManager.buttons[i].y)) + toolR)*invY,((pedalManager.buttons[i].x+(pedalManager.buttons[i].stackW/2))) + 0,(((pedalManager.buttons[i].y-ledgeClearance)) + toolR)*invY,0,(wireTrackDepth)*-1,normalStep);//carve straight out from edge of button before heading to mcu
       
       lineOptimized(((pedalManager.buttons[i].x+(pedalManager.buttons[i].stackW/2))) + 0,(((pedalManager.buttons[i].y-ledgeClearance)) + toolR)*invY,pedalManager.mcuCenter[0],pedalManager.mcuCenter[1]*invY,0,(wireTrackDepth)*-1,normalStep);//now carve to mcu pocket 
       
   }//end button loop
   
   //outline base
   tabSize = 0; 
   for(float z = 0; z >= (woodStockT+1)*-1; z -= normalStep){
     if(z <= (woodStockT-defaultTabT) *-1){ tabSize = 20;}
     cutRectangle(0,0,pedalManager.baseWidth,baseHeight*invY,out,corner,z,toolR,tabSize,stepover); 
   }
   tabSize = 0;
     
 
  footer();
  F.export("job" + job +".nc");
  println("exported job " + job + " to sketch folder"); 
  F.reset();

  job++;
  
  //-------------------------------------------------------------------------JOB 1 higher level button stacks
  
  //this job are flipped 90degrees, because generally it looks nicer if the grain follows the long dimension, but 
  
  header();
  
  //button stack outlines.    
  float xOff = 0;
  float yOff = 0;
  float yLimit = woodStockW-15; 
  float yClearance = 15;
  float xClearance = 20;
  
  for(int i = 0; i < pedalManager.numButtons; i++){
    
    if(pedalManager.buttons[i].level != 0){
      
      if(yOff+pedalManager.buttons[i].stackW > yLimit){ 
        yOff = 0;
        xOff += stackL+xClearance; //thisll be more complicated if you want variable length pedals, so for now best to keep them all the same length.  IDK why you'd want different lengths anyway.
      }
       
      F.plus("F"+normalSpeed);
      F.plus("G01 Z02");
      
      //general relief to leave a ledge
       for(float z = 0; z >= otherReliefDepth*-1; z -= normalStep){
         rectangularFace((xOff+stackLedgeW) + 0, (yOff) + 0 , stackL -stackLedgeW,pedalManager.buttons[i].stackW,in,corner,z,toolR,stepover );
       }
       
       F.plus("G01 Z2");
       F.plus("G00 F" + normalSpeed);
       
       //foam slot
       for(float z = otherReliefDepth*-1; z >= (otherReliefDepth+4)*-1; z -= normalStep){
         rectangularFace( pedalManager.buttons[i].foamSlotTL[1]+0-toolR +xOff,  pedalManager.buttons[i].foamSlotTL[0]+yOff, pedalManager.buttons[i].foamThickness,pedalManager.buttons[i].foamSlotWidth,in,corner,z,toolR,stepover  );
       }
       
       
       F.plus("G01 Z2");
       F.plus("G00 F" + normalSpeed);
        
       //pcb holder
       for(float z = otherReliefDepth*-1; z >= buttonReliefDepth*-1; z -= normalStep){
         rectangularFace(   ((pedalManager.buttons[i].buttonPCBTL[1]+xOff-actuatorPosOffset))+0,((pedalManager.buttons[i].buttonPCBTL[0]+yOff))+0,    buttonPCBDimension[1],buttonPCBDimension[0],in,corner,z,toolR,stepover  );
       }
       
       F.plus("G01 Z2");
       F.plus("G00 F" + normalSpeed);
       
       //wire track in button area
       lineOptimized(((xOff+pedalManager.buttons[i].buttonActuatorY))+0,((yOff+(pedalManager.buttons[i].stackW/2))) + 0,((xOff+stackLedgeW))+toolR + 0,((yOff+(pedalManager.buttons[i].stackW/2))) + 0,otherReliefDepth*-1,(otherReliefDepth+wireTrackDepth)*-1,normalStep);//first line reaches ledge.
       
       //carve thru ledge
       lineOptimized(((xOff+stackLedgeW)) + 0+toolR, ((yOff+(pedalManager.buttons[i].stackW/2))) + 0, ((xOff)) + 0 - toolR,((yOff+(pedalManager.buttons[i].stackW/2))) + 0,0,(otherReliefDepth+wireTrackDepth)*-1,normalStep);//base level buttons carve thru the ledge.
       
       
       //screw locations 
       F.plus("G01 Z2");
       F.plus("G00 F" + normalSpeed);
       drillHole((xOff+stackLedgeW/2)+0,(yOff+presserPanelScrewClearance)+0,-.5);
       drillHole((xOff+stackLedgeW/2)+0,(yOff+pedalManager.buttons[i].stackW-presserPanelScrewClearance)+0,-.5);
       
       //outline stack block
       tabSize = 0;
      for(float z = 0; z >= (woodStockT+1)*-1; z -= normalStep){
        if(z <= (woodStockT-1) *-1){ tabSize = 10;}
        cutRectangle(xOff,yOff,stackL,pedalManager.buttons[i].stackW,out,corner,z,toolR,tabSize,stepover);
      }
      
      tabSize = 0;
       
       yOff+= pedalManager.buttons[i].stackW+yClearance;
       
       //now here we cut out more stacks if needed
       int stackTracker = pedalManager.buttons[i].level-1; 
       
       while(stackTracker > 0){
         
         if(yOff+pedalManager.buttons[i].stackW > yLimit){ 
          yOff = 0;
          xOff += stackL+xClearance; //thisll be more complicated if you want variable length pedals, so for now best to keep them all the same length.  IDK why you'd want different lengths anyway.
         }
         
         tabSize = 0;
         
         for(float z = 0; z >= (woodStockT+1)*-1; z -= normalStep){
           if(z <= (woodStockT-1) *-1){ tabSize = 10;}
           cutRectangle(xOff,yOff,stackL,pedalManager.buttons[i].stackW,out,corner,z,toolR,tabSize,stepover);
         }
          
         tabSize = 0;
        
         stackTracker --;
         
         yOff+= pedalManager.buttons[i].stackW+yClearance;
       }
       
       }//end higher level button if
    }//end button loop
  
   footer();
   
   F.export("job" + job +".nc");
  println("exported job " + job + " to sketch folder"); 
  F.reset();
  
  job++;
  
  //-----------------------------------------------------------------------------JOB 2 plastic presser panels
  //like job 1, I flipped x and y so the long dimensions follow the y axis, just cause on small machines that might matter.  
  xOff = 0;
  yOff = 0;
  yLimit = woodStockW-15; 
  yClearance = 15;
  xClearance = 20;
  
  header();
  
  //panel outlines 
   tabSize = 0;
   for(int i = 0; i < pedalManager.numButtons; i++){
     
      //screw locations 
       F.plus("G01 Z2");
       F.plus("G00 F" + normalSpeed);
       drillHole((xOff+stackLedgeW/2)+0,(yOff+presserPanelScrewClearance)+0,(plasticStockT+.25)*-1);
       drillHole((xOff+stackLedgeW/2)+0,(yOff+pedalManager.buttons[i].stackW-presserPanelScrewClearance)+0,(plasticStockT+.25)*-1);
       
       
     for(float z = 0; z >= (plasticStockT+.5)*-1; z -= microStep){
       if(z <= (plasticStockT-.5) *-1){ tabSize = 10;}
       cutRectangle(xOff,yOff,stackL,pedalManager.buttons[i].stackW,out,corner,z,toolR,tabSize,stepover);
     }
    
     tabSize = 0;
     F.plus("Z02");
     
    
   
   yOff+= pedalManager.buttons[i].stackW+yClearance;
       
     
   if(yOff+pedalManager.buttons[i].stackW > yLimit){ 
        yOff = 0;
        xOff += stackL+xClearance; //thisll be more complicated if you want variable length pedals, so for now best to keep them all the same length.  IDK why you'd want different lengths anyway.
       }
   }
   
 
   footer();
   
   F.export("job" + job +".nc");
   println("exported job " + job + " to sketch folder"); 
   F.reset();
  
   job++;
   
   //---------------------------------------------------------------------------------------job3 top cover and usb panels
   
   header();
   
   xOff = 0;
   yOff = 0;
   //top cover
   
   //screw holes
   //mark screw locations for top cover. TODO for more/custom screw holes these need to be an array and then you can add however many you want and loop thru
   drillHole(topCoverScrewClearance+0,(baseHeight-stackL-topCoverScrewClearance)+0,(plasticStockT+.25)*-1); //BL
   drillHole(topCoverScrewClearance+0,topCoverScrewClearance+0,(plasticStockT+.25)*-1); //TL
   drillHole((pedalManager.baseWidth-topCoverScrewClearance)+0,topCoverScrewClearance+0,(plasticStockT+.25)*-1); //TR
   drillHole((pedalManager.baseWidth-topCoverScrewClearance)+0,(baseHeight-stackL-topCoverScrewClearance)+0,(plasticStockT+.25)*-1); //BR
      
   //outline base
   tabSize = 0; 
   for(float z = 0; z >= (plasticStockT+.5)*-1; z -= microStep){
     if(z <= (plasticStockT-.5) *-1){ tabSize = 20;}
     cutRectangle(0,0,pedalManager.baseWidth,baseHeight-stackL,out,corner,z,toolR,tabSize,stepover); 
   }
   tabSize = 0;   
   
   F.plus("Z02");
   
   yOff+= baseHeight-stackL + yClearance;
       
   
   //usb cutout
   for(float z = 0; z >= (plasticStockT+.5)*-1; z -= microStep){
     rectangularFace(xOff+(usbPanelL/2)-(mcuUSBW/2),  yOff+mcuUSBHeightOffset,  mcuUSBW,  mcuUSBH,in,corner,z,toolR,stepover);
   }
   
   //screw locations 
   F.plus("G01 Z2");
   F.plus("G00 F" + normalSpeed);
   drillHole(xOff+4,  yOff+(mcuH+usbPanelBottomMargin)/2,(plasticStockT+.25)*-1);
   drillHole(xOff+usbPanelL-4,  yOff+(mcuH+usbPanelBottomMargin)/2,(plasticStockT+.25)*-1);
   
   
   //do the usb panel outline
   tabSize = 0; 
   for(float z = 0; z >= (plasticStockT+.5)*-1; z -= microStep){
     if(z <= (plasticStockT-.5) *-1){ tabSize = 7;}
     cutRectangle(xOff,  yOff,  usbPanelL,  mcuH+usbPanelBottomMargin,out,corner,z,toolR,tabSize,stepover);
   }
   tabSize = 0;  
   
   
   
   footer();
   
   F.export("job" + job +".nc");
   println("exported job " + job + " to sketch folder"); 
   F.reset();
  
   job++;
         
}

void header(){
    F.plus("G17 G21 G90 G94 G40");
    F.plus("M05");
    F.plus("F" + normalSpeed+" S1000");
    F.plus("M03");
    F.plus("G00 Z2");
    F.plus("G00 X0 Y0"); 
    tabSize = 0;
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
  
  float centerPointX; 
  float centerPointY;
  
  if(l>=0){
    centerPointX = x+(l/2);
  }
  else{
    centerPointX = x+(l/2);
  }
  if(w>=0){
    centerPointY = y+(w/2);
  }
  else{
    centerPointY = y+(w/2);
  }
  
  float currentX = x;
  float currentY = y;
  
  boolean flag = false;
  
  while(currentX != centerPointX && currentY != centerPointY){
    cutRectangle(currentX,currentY,l,w,inOut,2,z,toolR,tabSize,stepover);
    if(l >= 0){//normal style
      currentX += (toolR*2);
      l -= (toolR*4);
      if(l < 0){ l = 0;}
      if(currentX > centerPointX ){ currentX = centerPointX;}
    }
    else{ //invert style (only needed for translating processing to cnc...)
     currentX -= (toolR*2); 
     l += (toolR*4);
     if(l > 0){ l = 0;}
     if(currentX < centerPointX ){ currentX = centerPointX;}
    }
    if(w >= 0){ //normal style
      currentY += (toolR*2);
      w -= (toolR*4);
      if(w < 0){ w = 0;}
      if(currentY > centerPointY){ currentY = centerPointY; }
    }
    else{ //invert style (only needed for translating processing to cnc...)
     currentY -= (toolR*2); 
     w += (toolR*4);
     if(w > 0){ w = 0;}
     if(currentY < centerPointY){ currentY = centerPointY; }
    }

  }

     //run straight down the center, this helps avoid any rags
     if(w == 0){
       cutRectangle(centerPointX-(l/2)-toolR,centerPointY,l+(toolR*2),w,inOut,2,z,0,0,stepover); //finish off center
     }
     else if(l == 0){
       cutRectangle(centerPointX,centerPointY-(w/2)-toolR,l,w+(toolR*2),inOut,2,z,0,0,stepover); //finish off center
     }
   
   
  F.plus("G01 Z" + (z+stepover));
}

void cutRectangle(float x, float y,float l, float w, int inOut, int cornOrCent, float z,  float toolR, float tabSize,float stepover){
  
  float modX = 0;
  float modY = 0;
  float a,b,hyp,theta;
  float invY = 1;
  
  if(w < 0){ invY = -1; }//if w is negative we have to flip toolR mod
  
  if(cornOrCent == 0){//coords indicatebottom left corner, offset circle position
    
  }
  else if(cornOrCent == 1){
     x -= (l/2); y -= (w/2);
  }
 
  
  //when inout is 0 we are cutting an ID rectangle.  When inout is 1 we're cutting an OD rectangle
  //retangles always start from bottom left corner.
  
   if(tabSize == 0){
     
     if(inOut == 0){modX = toolR;modY = invY * toolR; }else if(inOut == 1){modX = (toolR*-1); modY = invY * (toolR*-1);}
     F.plus("G01 X"+(x+modX) + " Y" + (y+modY));//inital positionning
     F.plus("F"+plungeSpeed);
     F.plus("G01 Z"+z);
     F.plus("F"+normalSpeed);
     if(inOut == 0){modX = toolR;modY = invY * (toolR*-1); }else if(inOut == 1){modX = (toolR*-1); modY = invY * (toolR);}
     F.plus("G01 X"+(x+modX) + " Y" + (y+modY+w));
     
     if(inOut == 0){modX = (toolR*-1);modY = invY * (toolR*-1); }else if(inOut == 1){modX = (toolR); modY = invY * (toolR);}
     F.plus("G01 X"+(x+modX+l) + " Y" + (y+modY+w));
     
     if(inOut == 0){modX = (toolR*-1);modY = invY * toolR; }else if(inOut == 1){modX = (toolR); modY = invY * (toolR*-1);}
     F.plus("G01 X"+(x+modX+l) + " Y" + (y+modY));
     
     if(inOut == 0){modX = toolR;modY = invY * toolR; }else if(inOut == 1){modX = (toolR*-1); modY = invY * (toolR*-1);}
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
       b = abs((points[i+1][1]+(toolR*mods[inOut][i+1][1])*invY) - (points[i][1]+(toolR*mods[inOut][i][1])*invY));
       hyp = sqrt(pow(a,2) + pow(b,2));
       theta = atan(b/a);
       
       if(points[i+1][0] < points[i][0]){ 
              theta += PI;
       }
       else if(points[i+1][1] < points[i][1]){
          theta += PI; 
       }
       
       F.plus("G01 X"+(points[i][0]+(toolR*mods[inOut][i][0])) + " Y" + (points[i][1]+(toolR*mods[inOut][i][1])*invY ) );//inital positionning
        F.plus("F"+plungeSpeed);
        F.plus("G01 Z"+z);
        F.plus("F"+normalSpeed);
       
       F.plus("G01 X"+ ze(((toolR*mods[inOut][i][0])+points[i][0] + (((hyp/2)-(tabSize/2))*cos(theta)))) + "Y" + ze(((toolR*mods[inOut][i][1])*invY+points[i][1] + (((hyp/2)-(tabSize/2))*sin(theta)))));//over
       F.plus("G01 Z" + (z+stepover));//up
       F.plus("G01 X"+ ze(((toolR*mods[inOut][i][0])+points[i][0] + (((hyp/2)+(tabSize/2))*cos(theta)))) + "Y" + ze(((toolR*mods[inOut][i][1])*invY+points[i][1] + (((hyp/2)+(tabSize/2))*sin(theta)))));//over
        F.plus("F"+plungeSpeed);
       F.plus("G01 Z"+z);//down
       F.plus("F"+normalSpeed);
       F.plus("G01 X"+ ((toolR*mods[inOut][i][0])+points[i+1][0]) + "Y" + ((toolR*mods[inOut][i][1])*invY+points[i+1][1]) );//next point
     
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
