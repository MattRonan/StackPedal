# StackPedal

### A beautiful, dirt cheap, open source mouse pedal. 

StackPedal is ideal for activities that involve lots of clicking or scrolling, such as graphic design, CAD, video editing, and copyediting.  The cheapest available mouse pedals are typically around 50$ and bulky.  With StackPedal you can have a compact, lightweight design with however many buttons you need for under 20$ (see price notes at very bottom).  Provided are a Processing sketch which generates a design based on your parameters, and a basic Arduino sketch to let you dictate the messages your buttons will send.  The default sketch settings are for either an Arduino Nano or ESP32 as the microcontroller but you can use whatever you want.

# Build Instructions:

There are 2 ways to build the physical pedal.  Either export Gcode files from the Processing sketch to run on a CNC router, or export a PNG template, print it out, and route everything by hand. 

### Recommended Supplies List:

- Microcontroller (Arduino Nano or ESP32 recommended)
- Pine board, 1/2" (12.5mm) thick
- Plastic sheet, 1/16" (1.5mm) thick
- 5mm tactile buttons
- Button PCB ([Official board on OSHPark](https://oshpark.com/shared_projects/baTaN6WL "Named link title"))
- Foam sheet, 6mm thick 
- Foam sheet, 2mm thick (or adhesive non-slip backing)
- #4 wood screws
- 26AWG wire (or similar)

### Designing the Pedal

![Classic3StackDiagram](https://user-images.githubusercontent.com/11184076/194709257-098e2597-f47f-4a00-bd6d-ce763a41a467.jpg)

First [download Processing](https://processing.org/download "Named link title") and open the StackPedalGenerator sketch.  At the top of the sketch is a section called **'USER VALUES'**.  There are 4 different subsections of variables to fiddle with:
- **'CNC MACHINE RELATED'** If you are going to go the CNC route, make sure to set all these values so that they are correct for your machine, especially the first 4 which are marked with '**'.  Ignore these if routing by hand.
- **'TEMPLATE SCALE RELATED'** This changes the on-screen scale of the pedal and consequently the scale of the PDF that you export.  Getting a perfectly scaled printout can take some trial and error.  It may be easiest to leave this at the default value and then fine tune the scale from the print dialog of your PDF viewer. 
- **'UNIVERSAL DESIGN RELATED'** These give you control over the basic dimensions of the pedal.  You can change things like the location of the usb jack, length of the pedals, overall depth of the pedal, etc.  You can probably leave most of these alone if you're unsure, but make sure the ones that begin with 'mcu' relfect the correct dimensions for your microcontroller.
- **'PER BUTTON DESIGN RELATED'** These can be set indivudually for each button stack.

Now you can work on the button layout.  The basic concept of StackPedal is to stagger button stacks at different heights in order to make it easy hit the correct button with your foot despite everything being very compact.  These heights are referred to as levels.  Level 0 buttons are sunk into the base itself, and higher level buttons get glued on.  Each successive level adds an extra height of whatever your 'woodStockT' value is set to.  To add buttons to your design, do pedalManager.addButton(level) in the order that you want them to be located on the pedal going from left to right:<br/>
```
pedalManager.addButton(0); //this button is the leftmost, since it's the first added, and its level is 0
pedalManager.addButton(1); //middle button
pedalManager.addButton(2); //the last button added is the rightmost, and its level is 2
```

The above example creates a simple pedal with 3 equally-sized buttons increasing in height from left to right.  If you want different widths for your buttons, you can use pedalManager.setButtonWidth(button ID).  The button ID is automatically determined by the order you add the buttons, with first/leftmost being 0.
The  next example creates a design with 1 large base-level button in the center, 2 bigger buttons on either side of it one level higher, and 2 smaller buttons on the far left and right another level higher.
```
pedalManager.addButton(2); //the button's ID depends on the order you add them, this is button 0
pedalManager.addButton(1); //button 1
pedalManager.addButton(0); //button 2
pedalManager.addButton(1); //button 3
pedalManager.addButton(2); //button 4
pedalManager.setButtonWidth(0,25); //use button ID followed by value
pedalManager.setButtonWidth(1,45);
pedalManager.setButtonWidth(2,120);
pedalManager.setButtonWidth(3,45);
pedalManager.setButtonWidth(4,25);
  ```

You may also want to change the position of the MCU, which in turn impacts the position of the USB jack.  The jack can be on either the left, back, or right walls of the pedal, and you can choose the wall as well as the relative position on that wall with the following 2 variables:

```
int mcuJackWall = 1;   //0 = left side, 1 = back side, 2 = right side 
float mcuJackPos = .5; //shift jack on selected wall by inputting a value from 0-1 with .5 putting it in the middle.
```

### Pedal Construction

**CNC Method:**

Press 'g' in the processing sketch to export gcode once you've finished your design.  It will output 4 separate .nc files, job0, job1, job2, and job3.

Run job0 to cut out the base. Make sure you export your design with the correct toolR and woodStockT values.  A 3mm bit is recommended.   Level 0 buttons get cut into the base itself.  

Run job1 to cut out the higher level button stacks.

Run job2 to cut out plastic presser panels.  1.5mm thick ABS plastic is ideal. Thicker and it may not flex right, but thinner and it may flex too much.  

Run job3 to cut out the plastic top cover panel and the usb panel

**By Hand Method:**

This requires a little more elbow grease than the cnc method but it's how I made the first prototype, which only took a few hours.
Print a template and use it to mark your parts.  Carefully saw everything out and route the pockets and wire tracks with a Dremel. A trick for getting accurate depths by hand is to snap a drill bit in half so its short enough to stick only a few mm out of the chuck of a hand drill, and then set it to the exact depth you want for a given section.  Then just quickly sink a bunch of holes in that area.  Now when you dremel, you just need to erase the holes and you'll end up with a relatively even and correct depth.  It may help to glue up the button stacks before routing (see photos below) so that you have a bigger object which is easier to clamp down.

For cutting out the plastic panels, scissors or shears work fine.  

**Both Methods:**

You now should have all your wooden parts cut and routed:

![AllWoodenParts](https://user-images.githubusercontent.com/11184076/194709312-8ccc57ca-bd32-420a-b293-44cc3b8276b4.jpg)

You want to glue up the stacks according to your design:

![gluedStacks](https://user-images.githubusercontent.com/11184076/194709350-ee8aec3d-d0d6-4c07-8790-e6ef6b2a4e07.jpg)

The next step is to connect the higher level wire tracks to the tracks routed in the base by drilling diagonally down to create a tunnel.  Typically a 1/8 bit works well for most wires:

![DrillChannelBetweenStackAndBase](https://user-images.githubusercontent.com/11184076/194709375-d7ec4cb2-669f-4f45-b680-b4775ba5ba58.jpg)

If you are going to stain/seal the pedal, now is the time to do it.


### Wiring and Finishing the Pedal

Wire up the buttons to either some protoboard or the [official button pcb](https://oshpark.com/shared_projects/baTaN6WL "Named link title")
Using the pcb is a better option because the tight fits means no need for screws.  You can achieve the same thing with protoboard if you take the time to dial it in.  Make your connections to the microcontroller.

Cut a strip of 6mm foam to sit into the foam cutout for each panel.  For a stiffer button feel, fill up the whole slot.  For an easier to press one use
a shorter piece.  You dont have to add foam at all but the button will be extremely clicky and will probably wear out sooner.

Use a hand drill to make 1/16" pilot holes for all the plastic panels and connect them with #4 wood screws.

At this point you want to put some kind of grippy backing onto the bottom of the pedal.  The cheapest option is standard 2mm craft foam and some kind of adhesive such as hardware store silisone.  You could also try adhesive-backed tapes or furniture sliders, which will probably provide better grip at higher cost.

### Software:

There are a few options for how the StackPedal actually interfaces with a computer:

A) The simplest is to use something like an Arduino Nano and the default Arduino Mouse library, with a usb cable providing both power and data connection.  In the StackPedalGenerator sketch, an Elegoo Arduino Nano is used for the mcu pocket size and usb jack location.  If using an offbrand board (such as an Elegoo Nano) you may need to download the ch430 usb driver and install it on your computer.

B) An ESP32 or other mcu with built-in Bluetooth, using a usb cable for power only.  This can be powered via the computer's port if you want, but can also plug into a wall outlet via a 5V block.  This is helpful since the StackPedal sits on the ground where reaching the computer with a cable might be a hassle.  It also frees up a port.

C)  ESP32 or other mcu with built-in Bluetooth, using a battery pack (rechargeable or not).  This is a fully wireless solution but requires changing the code to make the mcu go to sleep when not transmitting, otherwise it will tear thru batteries really quickly.  A great writeup on ESP32 deep sleep can be found here https://lastminuteengineers.com/esp32-deep-sleep-wakeup-sources/ 

For options B and C, T-vK made a great BLE mouse library for the ESP32 which can be found at https://github.com/T-vK/ESP32-BLE-Mouse 

If using the default Arduino Nano approach, use the "non-Bluetooth" sketch to set your buttons to send the commands that you want.
For ESP32, use the "ESP32_BLE" sketch. These have options for left, right, and middle clicks, plus scrolling up and down but more are possible.  The StackPedal can also be used to send keyboard strokes for foot-controlled hotkeys.


### Price Notes

An example list of materials and their source, with base cost followed by approximate actual cost for the 3-stack pedal shown in construction photos.  

- Arduino Nano (Offbrand), Amazon, pack of three:  $20, 1 x $6.33
- Pine board, Lowes, 1/2" thick 3ft long: $5, approx $2.50 per
- Plastic sheet, Amazon, 1/16" thick: $8, $4 per 
- 5mm tactile buttons, Amazon, pack of 100: $6, 3 x $.06 (I hate Amazon but it's hard not to buy things priced like this)
- Button PCB ([Official board on OSHPark](https://oshpark.com/shared_projects/baTaN6WL "Named link title")) $1.65 for 3
- Foam sheet, 6mm thick, Michaels, $1, approx $.1 per
- Foam sheet, 2mm thick, Michaels, $1, approx $.50 per
- #4 wood screws, Lowes, 2 x packs of 8: $3.00

Total cost if you have to buy all of these things is $45.65.  But the per pedal cost is a maximum of $18.26.  It goes down more if you buy a bigger pack of screws, a bigger sheet of plastic, etc.  I'm not including other odds and ends like wire, solder, adhesive, polyurethane, brushes etc.  

