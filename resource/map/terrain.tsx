<?xml version="1.0" encoding="UTF-8"?>
<tileset name="terrain" tilewidth="32" tileheight="32">
 <image source="../../content/image/terrain.png" width="256" height="352"/>
 <terraintypes>
  <terrain name="ground" tile="0"/>
  <terrain name="chasm" tile="12"/>
  <terrain name="cliff" tile="36"/>
 </terraintypes>
 <tile id="0" terrain="0,0,0,0">
  <properties>
   <property name="name" value="Ground"/>
  </properties>
 </tile>
 <tile id="1">
  <properties>
   <property name="cover" value="1"/>
   <property name="moveCost" value="1"/>
   <property name="name" value="Flora"/>
  </properties>
 </tile>
 <tile id="2">
  <properties>
   <property name="cover" value="2"/>
   <property name="moveCost" value="2"/>
   <property name="name" value="Foliage"/>
  </properties>
 </tile>
 <tile id="3" terrain="0,0,0,1">
  <properties>
   <property name="moveCost" value="1"/>
   <property name="name" value="Ground"/>
  </properties>
 </tile>
 <tile id="4" terrain="0,0,1,1">
  <properties>
   <property name="moveCost" value="1"/>
   <property name="name" value="Ground"/>
  </properties>
 </tile>
 <tile id="5" terrain="0,0,1,0">
  <properties>
   <property name="moveCost" value="1"/>
   <property name="name" value="Ground"/>
  </properties>
 </tile>
 <tile id="6" terrain="1,1,1,0">
  <properties>
   <property name="name" value="ground"/>
  </properties>
 </tile>
 <tile id="7" terrain="1,1,0,1">
  <properties>
   <property name="name" value="ground"/>
  </properties>
 </tile>
 <tile id="8">
  <properties>
   <property name="name" value="Obelisk"/>
  </properties>
 </tile>
 <tile id="9">
  <properties>
   <property name="name" value="Obelisk"/>
  </properties>
 </tile>
 <tile id="10">
  <properties>
   <property name="name" value="Obelisk"/>
  </properties>
 </tile>
 <tile id="11" terrain="0,1,0,1">
  <properties>
   <property name="moveCost" value="1"/>
   <property name="name" value="Ground"/>
  </properties>
 </tile>
 <tile id="12" terrain="1,1,1,1">
  <properties>
   <property name="moveCost" value="99"/>
   <property name="name" value="Chasm"/>
  </properties>
 </tile>
 <tile id="13" terrain="1,0,1,0">
  <properties>
   <property name="moveCost" value="1"/>
   <property name="name" value="Ground"/>
  </properties>
 </tile>
 <tile id="14" terrain="1,0,1,1">
  <properties>
   <property name="name" value="ground"/>
  </properties>
 </tile>
 <tile id="15" terrain="0,1,1,1">
  <properties>
   <property name="name" value="ground"/>
  </properties>
 </tile>
 <tile id="16">
  <properties>
   <property name="name" value="Ground"/>
  </properties>
 </tile>
 <tile id="17">
  <properties>
   <property name="name" value="Ground"/>
  </properties>
 </tile>
 <tile id="18">
  <properties>
   <property name="name" value="Spawn"/>
  </properties>
 </tile>
 <tile id="19" terrain="0,1,0,0">
  <properties>
   <property name="moveCost" value="1"/>
   <property name="name" value="Ground"/>
  </properties>
 </tile>
 <tile id="20" terrain="1,1,0,0">
  <properties>
   <property name="moveCost" value="1"/>
   <property name="name" value="Ground"/>
  </properties>
 </tile>
 <tile id="21" terrain="1,0,0,0">
  <properties>
   <property name="moveCost" value="1"/>
   <property name="name" value="Ground"/>
  </properties>
 </tile>
 <tile id="27" terrain="0,0,0,2">
  <properties>
   <property name="moveCost" value="99"/>
   <property name="name" value="Cliff"/>
  </properties>
 </tile>
 <tile id="28" terrain="0,0,2,2">
  <properties>
   <property name="moveCost" value="99"/>
   <property name="name" value="Cliff"/>
  </properties>
 </tile>
 <tile id="29" terrain="0,0,2,0">
  <properties>
   <property name="moveCost" value="99"/>
   <property name="name" value="Cliff"/>
  </properties>
 </tile>
 <tile id="30" terrain="2,2,2,0">
  <properties>
   <property name="moveCost" value="99"/>
   <property name="name" value="Cliff"/>
  </properties>
 </tile>
 <tile id="31" terrain="2,2,0,2">
  <properties>
   <property name="moveCost" value="99"/>
   <property name="name" value="Cliff"/>
  </properties>
 </tile>
 <tile id="35" terrain="0,2,0,2">
  <properties>
   <property name="moveCost" value="99"/>
   <property name="name" value="Cliff"/>
  </properties>
 </tile>
 <tile id="36" terrain="2,2,2,2">
  <properties>
   <property name="name" value="Ground"/>
  </properties>
 </tile>
 <tile id="37" terrain="2,0,2,0">
  <properties>
   <property name="moveCost" value="99"/>
   <property name="name" value="Cliff"/>
  </properties>
 </tile>
 <tile id="38" terrain="2,0,2,2">
  <properties>
   <property name="moveCost" value="99"/>
   <property name="name" value="Cliff"/>
  </properties>
 </tile>
 <tile id="39" terrain="0,2,2,2">
  <properties>
   <property name="moveCost" value="99"/>
   <property name="name" value="Cliff"/>
  </properties>
 </tile>
 <tile id="43" terrain="0,2,0,0">
  <properties>
   <property name="moveCost" value="99"/>
   <property name="name" value="Cliff"/>
  </properties>
 </tile>
 <tile id="44" terrain="2,2,0,0">
  <properties>
   <property name="moveCost" value="99"/>
   <property name="name" value="Cliff"/>
  </properties>
 </tile>
 <tile id="45" terrain="2,0,0,0">
  <properties>
   <property name="moveCost" value="99"/>
   <property name="name" value="Cliff"/>
  </properties>
 </tile>
</tileset>
