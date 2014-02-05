#include <SPI.h>
#include <ble.h>
#include <Servo.h> 
 
#define LEFT_VIBRATOR_PIN    4
#define RIGHT_VIBRATOR_PIN   5

void setup()
{
  SPI.setDataMode(SPI_MODE0);
  SPI.setBitOrder(LSBFIRST);
  SPI.setClockDivider(SPI_CLOCK_DIV16);
  SPI.begin();

  ble_begin();
  
  pinMode(LEFT_VIBRATOR_PIN, OUTPUT);
  pinMode(RIGHT_VIBRATOR_PIN, OUTPUT);    
}

void loop()
{  
  // If data is ready
  while(ble_available())
  {
    // read out command and data
    byte data0 = ble_read();
    byte data1 = ble_read();
    byte data2 = ble_read();
    
    if (data0 == 0x01)  // Command is to control the left vibrator
    {
      if (data1 == 0x01)
        digitalWrite(LEFT_VIBRATOR_PIN, HIGH);
      else
        digitalWrite(LEFT_VIBRATOR_PIN, LOW);
    }
    
    if (data0 == 0x02)  // Command is to control the right vibrator
    {
      if (data1 == 0x01)
        digitalWrite(RIGHT_VIBRATOR_PIN, HIGH);
      else
        digitalWrite(RIGHT_VIBRATOR_PIN, LOW);
    }

  }
  
  if (!ble_connected())
  {
    digitalWrite(LEFT_VIBRATOR_PIN, HIGH);
    digitalWrite(RIGHT_VIBRATOR_PIN, HIGH);
  }
  
  // Allow BLE Shield to send/receive data
  ble_do_events();  
}
