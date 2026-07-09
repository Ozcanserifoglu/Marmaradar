[out:json][timeout:180];
(
  node["highway"="speed_camera"](40.0,27.5,41.5,30.5);
  relation["type"="enforcement"]["enforcement"~"maxspeed|average_speed"](40.0,27.5,41.5,30.5);
);
out body;
>;
out skel qt;
