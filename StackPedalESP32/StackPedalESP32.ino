//Notes about ESP32.  
//
//-- It MIGHT be neccessary to press the rst button at least once to get
//code to upload.  For my LOLIN32 it wasnt neccessary after that first time.
//
//--set clock speed to 80Mhz. There's no reason for this thing to blast away at 240Mhz, itll get hot.
//
//--"GPIO 34-39 can only be set as input mode and do not have software
//enabled pullup functions" so those pins CANT be used for buttons

#include <BleMouse.h>

BleMouse bleMouse;

//currently clickStack unit is COM10
//0,1,2 = left middle right.    
int buttonPins[] = {32,33,25}; //change to match your pins
int buttonStates[] ={0,0,0};
unsigned long buttonPressedAt[] = {0,0,0};
unsigned long buttonReleaseTrackers[] = {0,0,0}; //if you're saving millis() values, it must be a unsigned long. int only saves up to 32,768


void setup() {
 // esp_err_t results = esp_wifi_stop();
  Serial.begin(115200);
  //bleMouse.deviceName = "ClickStack"; this didnt work...
  bleMouse.begin();
  
  for(int i = 0; i < sizeof(buttonPins)/sizeof(int);i++){
    pinMode(buttonPins[i],INPUT_PULLUP);
  }

  /*
  while(!bleMouse.isConnected()){ 
    
  }*/


}

void loop() {

  //--------------------------------------BUTTON
  
    for(int i = 0; i<3; i++){
      if(digitalRead(buttonPins[i]) == 1){ //button voltage higih
      
        if((millis() ) >= buttonReleaseTrackers[i] + 50){//BRT resets when button depressed, so xMs must pass with the button idle before we accept it's released.  Helps avoid jitter problems when unsigned long pressing.
          if(buttonStates[i] != 0){

            if(buttonStates[i] == 2){  //i dont think we even care about more advanced states with mouse buttons.
            }
            else if(buttonStates[i] == 3){  
            }

            if(i == 0){  
              bleMouse.release(MOUSE_LEFT);
            }
            else if(i == 1){
              bleMouse.release(MOUSE_MIDDLE);
            }
            else if(i == 2){
              bleMouse.release(MOUSE_RIGHT);
            }
            buttonStates[i] = 0;  
          }
        } 
      }
      
      else{ //button voltage low (presssed)
  
          if(buttonStates[i] == 0){ //this lets us add a touch of delay to button to remove jitter (if we want)
            buttonStates[i] = 1;
            buttonPressedAt[i] = (millis() );
          }
          else if(buttonStates[i] == 1 && (millis() ) > buttonPressedAt[i] + 10){ //remove the +x if you dont want any delay.  It prolly doesnt matter.
            if(i == 0){  
              bleMouse.press(MOUSE_LEFT);
            }
            else if(i == 1){
              bleMouse.press(MOUSE_MIDDLE);
            }
            else if(i == 2){
              bleMouse.press(MOUSE_RIGHT);
            }
            buttonStates[i] = 2;              
          }
          else if(buttonStates[i] == 2 && (millis() ) > buttonPressedAt[i] + 1000){
            
            buttonStates[i] = 3;
          }
          else if(buttonStates[i] == 3){
          }
          
          buttonReleaseTrackers[i] = (millis() ); //sticky low effect
      }
    }

}
