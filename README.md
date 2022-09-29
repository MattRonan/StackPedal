# ClickStack
An open hardware/source Bluetooth foot pedal

Here are a few options for how the ClickStack actually interfaces with a computer:

A) The simplest is to use something like an arduino nano and the default arduino Mouse library, with a usb cable providing both power and data connection.  

B) An ESP32 or other mcu with built-in Bluetooth, using a usb cable for power only.  This can be powered via the computer's port if you want, but can also plug into a wall outlet via a 5V block.  This is helpful since the ClickStack sits on the ground where reaching the computer with a cable might be a hassle.  It also frees up a port.

C)  ESP32 or other mcu with built-in Bluetooth, using a battery pack (rechargeable or not).  This is a fully wireless solution but requires changing the code to make the mcu go to sleep when not transmitting, otherwise it will be constantly needing charging or new batteries.  A great writeup on ESP32 deep sleep can be found here https://lastminuteengineers.com/esp32-deep-sleep-wakeup-sources/ It seems that in order to use multiple GPIO pins to wake up the mcu, a button press needs to be logic HIGH, which is the reverse of the code I have in the current included Arduino sketch.  ESP32 supports INPUT_PULLDOWN when setting pinMode.

T-vK made a great BLE mouse library for the ESP32 which can be found at https://github.com/T-vK/ESP32-BLE-Mouse 



