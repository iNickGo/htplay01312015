#include <Grove_LED_Bar.h>

#define PIR_MOTION_SENSOR 2
#define BUTTON_PIN 6
#define VIBRATION_PIN 5
#define LED_PIN 8

Grove_LED_Bar bar(9,LED_PIN,0);

void setup()
{
  Serial.begin(9600);
  
  pinMode(PIR_MOTION_SENSOR, INPUT);
  pinMode(BUTTON_PIN, INPUT);
  pinMode(VIBRATION_PIN, OUTPUT );
}


char data[100];
int data_index = 0;
unsigned char has_data = 0;


int buttonState = LOW;
void loop()
{
  buttonState = digitalRead(BUTTON_PIN);

  if (buttonState == LOW) {
    return;
  }
  delay(5000);
  /*
   memset(data,0,sizeof(data));
   strcpy(data,"hi");
   
   Serial.println(data);
   
   delay(1000);
*/

  while(1) {
    int sensorValue = digitalRead(PIR_MOTION_SENSOR);
    if(sensorValue == HIGH)//if the sensor value is HIGH?
    {
      //pir on
      Serial.println("p1");
      digitalWrite(VIBRATION_PIN, HIGH);
      
      for (int j=0;j<3;j++) {
        for(int i=0;i<=10;i++) {
          bar.setLevel(i);
          delay(100);
        }
        bar.setBits(0x3ff);
        delay(100);
      }
      
      
      digitalWrite(VIBRATION_PIN, LOW);
      delay(1000);
      
      buttonState = LOW;
    } 
  }
}


