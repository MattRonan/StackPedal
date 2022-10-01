import java.awt.*;
import java.awt.event.*;
import java.io.*;
import processing.serial.*;

float sF = 5; //scale factor.  This is important if you want to export a png to use as a printed template and 
              //build a pedal by hand. For CNC it really doesn't matter.  On my Dell E7470 a value of 5 made the drawing a 1:1 ratio.
              //TODO how do you convert mm to pixels? it depends on how many pixels per mm there on screen
              //which varys from monitor to monitor...
int monitorW = displayWidth;
int monitorH = displayHeight;

int stockT = 12;  //the thickness of your board.
int baseHeight = 125; //this the dimension of the base measured parallel to the pedals. ie this minus pedalL is how much space is left for the microcontroller.
float toolR = 1.5;

ClickStack clickStack = new ClickStack(stockT,baseHeight);

int escapeTime = 0;

void setup() {
  
  size(1400, 800);
  
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
  
  //clickStack.setButtonWidth(1,120);//use button ID followed by value.  Large middle button and 2 side buttons
  
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
  
  public float defaultPedalW;
  public float defaultPedalL;
  public float defaultPedalMargin;
  public float defaultFoamThickness;
  public float defaultFoamSlotWall;
  public float defaultPedalLedgeW;
  public float defaultButtonReliefDepth;
  public float defaultOtherReliefDepth;
  
  public float stockT;
  public float baseHeight;
 
  public float baseWidth = 0; 
 
  public int numButtons = 0;
  
  public float[] origin = {20,60}; //top left corner of base in pixels
  public float[] bottomLeft = new float[2];
  
  float sF = 5; //scaleFactor;
  
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
  
  public void update(){
     //draw base
     noFill();
     stroke(0);
     strokeWeight(5);
     rect(this.origin[0],this.origin[1],this.baseWidth*sF,this.baseHeight*sF);
     
     //draw buttons
     stroke(245,0,255);
     strokeWeight(3);
     for(int i = 0; i < numButtons; i++){
       rect((buttons[i].x*sF)+this.origin[0],(buttons[i].y*sF)+this.origin[1],buttons[i].pedalW*sF,buttons[i].pedalL*sF);
     }
     
     //foam slots
     strokeWeight(3);
     for(int i = 0; i < numButtons; i++){
   
       rect( ((buttons[i].foamSlotTL[0]+buttons[i].x)*sF)+this.origin[0],  ((buttons[i].foamSlotTL[1]+buttons[i].y)*sF)+this.origin[1],  buttons[i].foamSlotWidth*sF,  buttons[i].foamThickness*sF  );
     
     
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
    
    public float[] foamSlotTL = new float[2];
    public float foamSlotWidth; 
    float foamSlotPercent = .5; //percent of total width (.5 is a good value typically)
    
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
      this.recalculate();
    }
    
    public void recalculate(){
      this.foamSlotWidth = this.pedalW * this.foamSlotPercent;
      this.foamSlotTL[0] = ((pedalW-foamSlotWidth) * this.foamSlotPercent);//basically from the buttons perspective, TL of button is 0,0
      this.foamSlotTL[1] = this.pedalL - this.foamSlotWall - this.foamThickness;
     println( this.foamSlotTL[0]);
     println( this.foamSlotTL[1]);
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
