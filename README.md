# Godot Realistic GroundVehicles
**A Godot 4.7 plugin made  specifically for realistic tank projects (Also supports cars, however, its not recomended
as it is a secondary feature and may not work properly.)**

*Contains a TankBody3D (Which extends from RigidBody3D) and a TankWheel3D.*

**Setup Instructions:**
Visit my *Youtube* channel ; https://www.youtube.com/@GriffBolt4

Or:

1. Download the plugin from this repository
2. Unzip the downloaded plugin
3. put it in your Godot's **Addons** Folder
4. Activate it by going to **Project Settings > Addons**
5. Create a new Scene, choose **TankBody3D** as the root node;
6. import your tank's 3D model, or make your own model
(NOTE: Your tank model **MUST** have separate wheel meshes in order to use the **TankWheel3D**, Read the *Wheel Setup*
section if your model **DOES NOT** come with seperated wheels)
8. Add a **TankWheel3D**. as a child of your **TankBody3D.**
9. enter and tweak the *values* in TankWheel3D till it feels correct.
10. put your wheel mesh under the **TankWheel3D(As its child)**
11. Add a *CollisionShape3D*
12. Test and run it in game! *(Make sure you have a floor)*
13. Tweak the values till it feels correct.
Made in : **Godot 4.7**

# Wheel Setup (If your model comes with conjoined wheels)
in the **unfortunate** case your model comes with *conjoined* wheels (Your wheels are joined into 1 whole mesh, 
or connected to the hull, etc.)

You can either *find* another 3D model that is **Game-Ready**, OR:

Follow these steps:
1. Make sure you have *blender* on your desktop.
2. Import your Tank Model which has the conjoined wheels
3. Select *ALL* the wheels **(make sure you dont select anything else by accident!)**
4. Go into **Edit Mode** (*By pressing **tab***)
5. Click **P** then select **"By Loose Parts"** (This will seperate them by distance)
6. Not that this **isnt always perfect**, and , by any chance, *might* separate your wheels meshes.
  
 **(Eg: Seperating the rivets from the wheels, separating the inner ring from the outer ring, etc)**

 But dont worry! simply select everything in your wheel (or by using drag select) then, make sure an the parent object
 is selected (it will glow bright orange), click Ctrl + J. 
 Then do this to all the other wheels
 # IMPORTANT FOR WHEELS!!!!!
 This is **VERY** important, make sure that you set the **ORIGIN** of the mesh to its geometry,
 to do this, Right click > Set origin > Origin to geometry

if you have followed all these steps, You will now have a working tank in Godot!


 
