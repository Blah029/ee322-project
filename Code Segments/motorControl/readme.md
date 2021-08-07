	|on time			|off time
# motorControl
Subroutines for cotroling gate (motor3), platform rotation (motor2), and platform tipping (motor1). Copy and paste to mainCode.

- Variables (remap to new registers if required)
  - 0x0c - count1
  - 0x0d - count2
  - 0x0e - count3
- Subroutines
  - motor3 </br>
    Open and close gate.
  - motor2Pos1 </br>
    Rotate platform to 0 degree position.
  - motor2Pos2 </br>
    Rotate platform to 90 degree position.
  - motor1Pos1 </br>
    Tip platform to -30 degree position.
  - motor1Pos2 </br>
    Tip platform to 0 degree position.
   - motor1Pos3 </br>
    Tip platform to 30 degree position.

angle	|count1	|count2	|count3		|count1	|count2	|count3
-90 ----| 72----|2------|1--------------| 72----|2------|1-----
  0 ----|238----|2------|1--------------|161----|1------|1-----
+90 ----|149----|3------|1--------------|-------|-------|------
