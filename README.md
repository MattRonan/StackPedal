# ClickStack
An open hardware/source Bluetooth foot pedal

Build Instructions:

First download Processing and run the ClickStackGenerator sketch.  Fiddle with the parameters to get the layout you want.  For most cases you probably just want to change the amount of buttons added in setup via addButton and their width using setButtonWidth.  There are a couple common layouts included which you can uncomment to use.

Template: If you want a template during the build process, press 'p' in the processing sketch to export a PNG of your design which you can then print. Measure your printout to ensure the scale is correct.  If not, change 'sF' in the sketch to modify the scale factor up or down.

Make the wodden parts and plastic panels:

CNC Method:

Press 'g' in the processing sketch to export gcode once you've finished your design.  It will output 3 separate .nc files, job1, job2, and job3.

Run job1 to cut out the base. Make sure you export your design with the correct toolR value.  A 3mm bit or smaller is recommended.   Level 0 buttons get cut into the base itself.  

Run job2 to cut out the higher level buttons.

Glue higher level buttons to base.  You can print out a template as described above to make it easier to line these up.

Run job3 to cutout plastic panels.  I use 1.5mm thick ABS plastic.  Thicker than that and it may not flex right, but thinner and it may flex too much.  CNC cutting plastic can be tricky; typically you need to screw it into a piece of backing wood to get enough height to use your clamps.

By hand method:

This requires a little more elbow grease but it's how I made the first prototype, which only took a few hours.
Print a template and use it to mark your parts.  You want to cut out the buttons first and glue up your stacks.
Now you'll need a dremel.  A trick for getting accurate depths by hand is to snap a drill bit in half so its short enough to stick only a few mm out of the chuck of a hand drill, and then set it to the exact depth you want for a given section.  Then just quickly sink a bunch of holes in that area.  Now when you dremel, you just need to erase the holes and you'll end up with a relatively even and correct depth.

For the plastic, scissors or shears work fine.  


Wiring:

Wire up the bubttons to either some protoboard or get the official button pcb at https://oshpark.com/shared_projects/baTaN6WL
Using the pcb is a better option because you can avoid needing screws to hold it in place since it's a perfect fit.  You can achieve the same thing with protoboard if you take the time to dial it in.  Make your connections to the microcontroller.

Add foam:

Cut a strip of foam to sit into the foam cutout for each panel.  For a stiffer button feel, fill up the whole slot.  For an easier to press one use
a shorter piece.  You dont have to add foam at all but the button will be extremely clicky and will probably wear out sooner.

Final usb panel:

Add all your topside plastic panels.  This final panel goes on the side to contain the microcontroller and support the usb jack.  Depending on where your usb jack sits, which depends on your microcontroller, you may need to adjust the opening in this panel up or down.  Ideally this should be a snug fit around the jack to give it support and avoid stress on its solder joints.


Software:

First of all, there are a few options for how the ClickStack actually interfaces with a computer:

A) The simplest is to use something like an arduino nano and the default arduino Mouse library, with a usb cable providing both power and data connection.  In the ClickStackGenerator sketch, an Elegoo Arduino Nano is used for the mcu pocket size and usb jack location. 

B) An ESP32 or other mcu with built-in Bluetooth, using a usb cable for power only.  This can be powered via the computer's port if you want, but can also plug into a wall outlet via a 5V block.  This is helpful since the ClickStack sits on the ground where reaching the computer with a cable might be a hassle.  It also frees up a port.

C)  ESP32 or other mcu with built-in Bluetooth, using a battery pack (rechargeable or not).  This is a fully wireless solution but requires changing the code to make the mcu go to sleep when not transmitting, otherwise it will be constantly needing charging or new batteries.  A great writeup on ESP32 deep sleep can be found here https://lastminuteengineers.com/esp32-deep-sleep-wakeup-sources/ It seems that in order to use multiple GPIO pins to wake up the mcu, a button press needs to be logic HIGH, which is the reverse of the code I have in the current included Arduino sketch.  ESP32 supports INPUT_PULLDOWN when setting pinMode so you can do whatever you need to do in software.

For options B and C, T-vK made a great BLE mouse library for the ESP32 which can be found at https://github.com/T-vK/ESP32-BLE-Mouse 

If using the default Arduino Nano approach, use the "non-Bluetooth" sketch to set your buttons to send the commands that you want.
For ESP32, use the "ESP32_BLE" sketch.


If you don't want to go through the process of making your own ClickStack, I sell them over at Etsy for less $ than the typical Amazon pedals.




