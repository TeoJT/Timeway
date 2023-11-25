PShape s;
PShape funny;
import java.io.BufferedReader;
import java.io.FileReader;
import java.io.IOException;
import java.util.ArrayList;
import java.util.List;

List<PVector[]> sh;

void setup() {
  size(800, 800, P3D);
  // The file "bot.obj" must be in the data folder
  // of the current sketch to load successfully
  sh = loadOBJ(sketchPath()+"/data/egg.obj");
  
}

void draw() {
  background(0);
  //translate(width/2, height/2, 600);
  
  noFill();
  stroke(255);
  strokeWeight(1);
  //fill(127);
  //noStroke();
  
  float scale = -20.;
  float x = 0.;
  float y = 0.;
  float z = 0.;
  
  
  for (PVector[] f : sh) {
    beginShape();
    for (PVector v : f) {
      vertex(v.x*scale+x, v.y*scale+y, v.z*scale+z);
      //println(v.x, v.y, v.z);
    }
    endShape();
  }
  
  
  float t = frameCount*0.01;
  float d = 150;
  camera(sin(t)*d, 35.0, cos(t)*d, 0.0, 0.0, 0.0, 
       0.0, 1.0, 0.0);
}


public List<PVector[]> loadOBJ(String path) {
    List<PVector> vertices = new ArrayList<PVector>();
    List<PVector[]> faces = new ArrayList<PVector[]>();

    try {
        BufferedReader br = new BufferedReader(new FileReader(path));
        String line;

        while ((line = br.readLine()) != null) {
            if (line.startsWith("v ")) {
                String[] parts = line.split("\\s+");
                float x = Float.parseFloat(parts[1]);
                float y = Float.parseFloat(parts[2]);
                float z = Float.parseFloat(parts[3]);
                vertices.add(new PVector(x, y, z));
            }
            else if (line.startsWith("f ")) {
                String[] parts = line.split("\\s+");
                PVector[] vertexIndices = new PVector[parts.length - 1];
                for (int i = 0; i < vertexIndices.length; i++) {
                    String s = parts[i + 1];
                    s = s.substring(0, s.indexOf('/'));
                    vertexIndices[i] = vertices.get(Integer.parseInt(s)-1); // OBJ indices are 1-based
                }
                faces.add(vertexIndices);
            }
        }

        br.close();
    } catch (IOException e) {
        e.printStackTrace();
    }
    
    return faces;
}
