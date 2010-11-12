//RGB LED pins
int ledSleep[] = {
  7,8,12}; //the three pins of the digital LED

//These pins must be PWM         
int ledProbabilityFade[] = {
  3, 5, 6}; //the three pins of the first analog LED 

//These pins must be PWM         
int ledProbability[] = {
  9,10,11}; //the three pins of the second analog LED


const boolean ON = LOW;
const boolean OFF = HIGH;

const boolean AWAKE[] = {ON, ON, OFF}; 
const boolean ASLEEP[] = {OFF, OFF, ON}; 
const boolean BLACK[] = {OFF, OFF, OFF}; 


// incoming serial data
int sleepByte = 0;	// for incoming serial data
int probabilityByte = 0;	// for incoming serial data
int probabilityFadeBytes[6] = {0}; // six bytes for the next hour's probability
int red, green, blue; // rgb ints for my loop

void setup(){
  for(int i = 0; i < 3; i++){
    pinMode(ledSleep[i], OUTPUT);   
    pinMode(ledProbability[i], OUTPUT);   
  }

  setDigitalColor(ledSleep, BLACK);       //Turn off sleep led
  setColor(ledProbability, 0,0,0);       //Turn off probability led
  setColor(ledProbabilityFade, 0,0,0);       //Turn off probability led

  // serial setup
  Serial.begin(9600);
  pinMode(2, INPUT);   // digital sensor is on digital pin 2
  establishContact();  // send a byte to establish contact until receiver responds 
}

void establishContact() {
  while (Serial.available() <= 0) {
    Serial.print('-', BYTE);   // send a capital A
    delay(300);
  }
}


void setColor(int* led, int red, int green, int blue) {
  // with the common anode led, we write low voltage for on
  // and high voltage for off, so we need to subtract our rgb bytes off 255
  analogWrite(led[0],255-red);
  analogWrite(led[1],255-green);
  analogWrite(led[2],255-blue);
}

/* digital version of set color */
void setDigitalColor(int* led, const boolean* color){
  for(int i = 0; i < 3; i++){            
    digitalWrite(led[i], color[i]);   
  }
}



void loop() {
  if (Serial.available() >= 8) {
    // read two incoming byte:
    sleepByte = Serial.read();
    probabilityByte = Serial.read();
    for(int i= 0; i < 6; i++) {
      probabilityFadeBytes[i] = Serial.read();
    }
    Serial.flush();

    // debug what we have
    Serial.print("Sleep Byte: ");
    Serial.println(sleepByte, DEC);
    Serial.print("Probability Byte: ");
    Serial.println(probabilityByte, DEC);

    if(sleepByte == 0) {
      setDigitalColor(ledSleep,ASLEEP);
    }
    else if(sleepByte == 1) {
      setDigitalColor(ledSleep,AWAKE); 
    }
    else {
      setDigitalColor(ledSleep,BLACK);
    }

    blue =  255 * ((float(probabilityByte) / 100));
    red = 255 * ((float(100-probabilityByte) / 100));
    green = 255 * ((float(100-probabilityByte) / 100));

    setColor(ledProbability, red, green,blue);                

    Serial.println("Probability RGB: ");
    Serial.println(red, DEC); 
    Serial.println(green, DEC); 
    Serial.println(blue, DEC);
  }


  setColor(ledProbabilityFade, 0,0,0);
  for(int i= 0; i < 6; i++) {
    blue =  255 * ((float(probabilityFadeBytes[i]) / 100));
    red = 255 * ((float(100-probabilityFadeBytes[i]) / 100));
    green = 255 * ((float(100-probabilityFadeBytes[i]) / 100));
    setColor(ledProbabilityFade, red,green,blue);
    delay(1000);
  }
  setColor(ledProbabilityFade, 0,0,0);
  delay(1000);
}

