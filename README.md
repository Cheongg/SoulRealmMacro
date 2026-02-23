# SoulRealmMacro
A macro for soul cultivation [Roblox]

General Guide 
This serves as a general guide on how to utilise the macro 

Requirements:
1. Display resolution to be 1920, 1080 
2. Roblox to be in full screen       

Pre-requisites
1. Download the Files
2. Configure the image path to match where you saved it
3. Press F6
4. Ensure that both the images are found when you run the ImageChecker file 

Set-Up Guide
1. Configuration/ Customisation
There are 2 places where you can configure - CONFIGURABLES [line 4] and CalculateIntervals() [line 326] 
The rest of the code can be comfigured but is not recommended unless you know what you are doing

Here's what the configurations affect
CONFIGURABLES - currentRealm, maxRealm and resetAfterBreakthrough
CalculateIntervals() - cultivateTime, breakthroughDuration, breakthroughInterval

2. Configure 'ITEM / BACKPACK HELPERS' section
The codes under 'ITEM / BACKPACK HELPERS' (line 376) works those who are using 24 inch monitor and may not work for the rest 
Prepare to make many adjustments under this section as there are too many factors affecting this - monitor display, game UI etc 

Before Starting Macro
1. Ensure that CONFIGURABLES [line 4] are set, without configuring those the macro will throw an error 
2. Ensure that backpack tab is visible
3. Ensure that backpack filter is set to 'All' 
4. Have adequate recovery pills - min 100 
5. Open bag and click on a random item, ensure that item is shown