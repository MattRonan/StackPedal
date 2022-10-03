# ClickStack

### A beautiful, dirt cheap, open source mouse pedal. 

ClickStack is ideal for activities that involve lots of clicking, such as graphic design, PCB layout, and video editing.  The cheapest available mouse pedals are typically around 50$ and bulky.  The cost of materials in a ClickStack can be as low as 10$, and your pedal can be designed to be as lightweight and compact as you want.  Provided are a Processing sketch which generates a design based on your parameters, and a basic Arduino sketch to let you dictate the messages your buttons will send.  The default sketch settings are for an Arduino Nano as the microcontroller but you can use whatever you want.

## Build Instructions:

There are 2 ways to build the physical pedal.  Either export Gcode files from the Processing sketch to run on a CNC router, or export a PNG template, print it out, and route everything by hand. 

### Recommended Supplies List:

- Microcontroller (Arduino Nano or ESP32 recommended)
- Pine board, 1/2" (12.5mm) thick. 
- Plastic sheet, 1/16" (1.5mm) thick.
- 5mm tactile buttons
- Button PCB ([Offical board on OSHPark](https://oshpark.com/shared_projects/baTaN6WL "Named link title"))
- Foam sheet, 6mm thick.  
- #4 wood screws
- 26AWG wire (or similar)

### Designing Your Pedal

First [download Processing](https://oshpark.com/shared_projects/baTaN6WL "Named link title") and run the ClickStackGenerator sketch.  At the top of the sketch is a section called **'USER VALUES'**.  There are 3 different subsections of variables to fiddle with:
- **'CNC MACHINE RELATED'** If you are going to go the CNC route, make sure to set all these values so that they are correct for your machine, especially the first 4 which are marked with '**'.  Ignore these if routing by hand.
- **'TEMPLATE SCALE RELATED'** If your plan is to route by hand, make sure that the value for'sF' results in your PNG exporting at a 1:1 scale.  If it doesn't, raise or lower it accordingly.
- **'DEFAULT PEDAL DESIGN RELATED'** These give you control over the basic dimensions of the pedal.  You can change things like the location of the usb jack, length of the pedals, overall depth of the pedal, etc.  You can probably leave these alone if you're unsure, aside from making sure the ones that begin with 'mcu' relfect the correct dimensions for your microcontroller.

The basic concept of ClickStack is to stagger button stacks at different heights in order to make it easy to locate the button
you want despite the buttons being very close to each other.  These heights are referred to as levels.  Level 0 buttons are sunk into the base itself, and higher level buttons get glued on.  Each successive level adds an extra height of whatever your 'woodStockT' value is set to.  To add buttons to your design, do clickStack.addButton(level) in the order that you want them to be located on the pedal going from left to right:<br/>
```
clickStack.addButton(0); //this button is the leftmost, since it's the first added, and its level is 0
clickStack.addButton(1); //middle button
clickStack.addButton(2); //the last button added is the rightmost, and its level is 2
```

The above example creates a simple pedal with equally-sized buttons increasing in height from left to right.  If you want different widths for your buttons, you can use clickStack.setButtonWidth(button ID).  The button ID is automatically determined by the order you add the buttons, with first/leftmost being 0.
Here is a 5 button pedal with a larger middle button:
```
clickStack.addButton(2); //the buttons ID depends on the order you add them, this is button 0
clickStack.addButton(1); //button 1
clickStack.addButton(0); // button 2
clickStack.addButton(1); // button 3
clickStack.addButton(2); //button 4
clickStack.setButtonWidth(0,25);//use button ID followed by value
clickStack.setButtonWidth(1,45);
clickStack.setButtonWidth(2,120);
clickStack.setButtonWidth(3,45);
clickStack.setButtonWidth(4,25);
  ```
The above example creates a design with a large base-level button in the center, bigger buttons on either side of it one level higher, and the smaller buttons on the far left and right another level hgiher.

Template: If you want a template during the build process, press 'p' in the processing sketch to export a PNG of your design which you can then print. Measure your printout to ensure the scale is correct.  If not, change 'sF' in the sketch to modify the scale factor up or down.

Make the wooden parts and plastic panels:

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


Both methods, drill wire holes for higher level buttons:

Any button at level 0 gets its tracks to the mcu fully routed.  Buttons at level 1 or higher require hand drilling diagonally down to connect the
button track to the track routed in the base.  Typically a 1/8 bit works well for this for most wires.

Wiring:

Wire up the buttons to either some protoboard or get the official button pcb at https://oshpark.com/shared_projects/baTaN6WL
Using the pcb is a better option because you can avoid needing screws to hold it in place since it's a perfect fit.  You can achieve the same thing with protoboard if you take the time to dial it in.  Make your connections to the microcontroller.

Add foam:

Cut a strip of foam to sit into the foam cutout for each panel.  For a stiffer button feel, fill up the whole slot.  For an easier to press one use
a shorter piece.  You dont have to add foam at all but the button will be extremely clicky and will probably wear out sooner.

Final usb panel:

Add all your topside plastic panels.  This final panel goes on the side to contain the microcontroller and support the usb jack.  Depending on where your usb jack sits, which depends on your microcontroller, you may need to adjust the opening in this panel up or down.  Ideally this should be a snug fit around the jack to give it support and avoid stress on its solder joints.


Software:

First of all, there are a few options for how the ClickStack actually interfaces with a computer:

A) The simplest is to use something like an Arduino Nano and the default Arduino Mouse library, with a usb cable providing both power and data connection.  In the ClickStackGenerator sketch, an Elegoo Arduino Nano is used for the mcu pocket size and usb jack location. 

B) An ESP32 or other mcu with built-in Bluetooth, using a usb cable for power only.  This can be powered via the computer's port if you want, but can also plug into a wall outlet via a 5V block.  This is helpful since the ClickStack sits on the ground where reaching the computer with a cable might be a hassle.  It also frees up a port.

C)  ESP32 or other mcu with built-in Bluetooth, using a battery pack (rechargeable or not).  This is a fully wireless solution but requires changing the code to make the mcu go to sleep when not transmitting, otherwise it will be constantly needing charging or new batteries.  A great writeup on ESP32 deep sleep can be found here https://lastminuteengineers.com/esp32-deep-sleep-wakeup-sources/ It seems that in order to use multiple GPIO pins to wake up the mcu, a button press needs to be logic HIGH, which is the reverse of the code I have in the current included Arduino sketch.  ESP32 supports INPUT_PULLDOWN when setting pinMode so you can do whatever you need to do in software.

For options B and C, T-vK made a great BLE mouse library for the ESP32 which can be found at https://github.com/T-vK/ESP32-BLE-Mouse 

If using the default Arduino Nano approach, use the "non-Bluetooth" sketch to set your buttons to send the commands that you want.
For ESP32, use the "ESP32_BLE" sketch.


If you don't want to go through the process of making your own ClickStack, I sell them over at Etsy for less $ than the typical Amazon pedals.




