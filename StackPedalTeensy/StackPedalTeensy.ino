
int buttonPins[] = {10,14};
int buttonStates[] ={0,0};
unsigned long buttonPressedAt[] = {0,0};
unsigned long buttonReleaseTrackers[] = {0,0}; //if you're saving millis() values, it must be a unsigned long. int only saves up to 32,768
elapsedMillis scrollTimer = 0;
int scrollRetriggerTime = 100;

void setup() {
  Serial.begin(115200);
 
  for(int i = 0; i < sizeof(buttonPins)/sizeof(int);i++){
    pinMode(buttonPins[i],INPUT_PULLUP);
  }


}

void loop() {

  //--------------------------------------BUTTON
  
    for(int i = 0; i<sizeof(buttonPins)/sizeof(int); i++){
      if(digitalRead(buttonPins[i]) == 1){ //button voltage higih
      
        if((millis() ) >= buttonReleaseTrackers[i] + 50){//BRT resets when button depressed, so xMs must pass with the button idle before we accept it's released.  Helps avoid jitter problems when unsigned long pressing.
          if(buttonStates[i] != 0){

            if(buttonStates[i] == 2){  //i dont think we even care about more advanced states with mouse buttons.
            }
            else if(buttonStates[i] == 3){  
            }

            if(i == 0){  
            }
            else if(i == 1){
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
          else if(buttonStates[i] == 1 && (millis() ) > buttonPressedAt[i] + 10){ //remove the +x if you dont want any delay.  It prolly doesnt matter
            
            buttonStates[i] = 2;              
          }
          else if(buttonStates[i] == 2 && (millis() ) > buttonPressedAt[i] + 1000){
            
            buttonStates[i] = 3;
          }
          else if(buttonStates[i] == 3){
          }

          if(buttonStates[i] == 1 || buttonStates[i] == 2 || buttonStates[i] == 3){ //optional repeat block.  useful for a scroll pedal
            /*
            Serial.print(i);
            Serial.print(": ");
            Serial.println(buttonStates[i]);*/
            if(scrollTimer >= scrollRetriggerTime){
              if(i == 0){  
                //Serial.print("down");
                Mouse.scroll(-1);
              }
              else if(i == 1){
                 //Serial.print("up");
                 Mouse.scroll(1);
              }

              scrollTimer = 0;
            }
          }
          
          buttonReleaseTrackers[i] = (millis() ); //sticky low effect
      }
    }

}
