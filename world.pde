// ********************** WORLD **************************

public class World extends Screen {
    public float height = 0;
    public PGraphics pg;
    int myRandomSeed = 0;
    float xscroll = 0;
    float yscroll = 0;
    float moveStarX = 0;
    boolean displayStars = true;

    class NightSkyStar {
        boolean active;
        float x;
        float y;
        int image;
        int config;
    }
    NightSkyStar[] nightskyStars;


    int MAX_NIGHT_SKY_STARS = 100;

    float TREE_SPACE = 50;
    float MAX_RANDOM_HEIGHT = 500;
    float WATER_LEVEL = 300;
    float VARI = 0.0009;
    float HILL_WIDTH = 300;
    float MOUNTAIN_FREQUENCY = 3.;
    float LOW_DIPS_REQUENCY = 0.5;
    float HIGHEST_MOUNTAIN = 1500;
    float LOWEST_DIPS = 1200;
    int   OCTAVE = 2;
    

    public World(Engine engine) {
        super(engine);

        this.height = engine.HEIGHT-myLowerBarWeight-myUpperBarWeight;

        // Random seed for noise generation
        myRandomSeed = (int)app.random(100000);
        scatterNightskyStars();
    }

    public void scatterNightskyStars() {
        int selectedNum = int(app.random(MAX_NIGHT_SKY_STARS/2, MAX_NIGHT_SKY_STARS));
        nightskyStars = new NightSkyStar[selectedNum];
        
        for (int i = 0; i < selectedNum; i++) {
            nightskyStars[i] = new NightSkyStar();
            int x = int(app.random(-16, engine.WIDTH));
            int y = int(app.random(-16, this.height));
            
            int j = 0;
            boolean colliding = false;
            final int spacing = 4;
            
            while (colliding) {
            colliding = false;
            
            while ((j < i) && !colliding) {
                if (((x+spacing+16) > (nightskyStars[j].x-spacing)) && ((x-spacing) < (nightskyStars[j].x+spacing+16)) && ((y+spacing+16) > (nightskyStars[j].y-spacing)) && ((y-spacing) < (nightskyStars[j].y+spacing+16))) {
                    colliding = true;
                }
                j++;
            }
            
            }
            
            nightskyStars[i].x = x;
            nightskyStars[i].y = y;
            nightskyStars[i].image = int(app.random(0, 5));
            nightskyStars[i].config = int(app.random(0, 4));
            nightskyStars[i].active = true;
        }
    }


    private void drawNightSkyStars() {
        for (NightSkyStar star : nightskyStars) {
            if (star.active) {
                
                // Render the star
                engine.img("nightsky"+str(star.image), star.x, star.y, 16, 16);

                // Move the star
                star.x -= moveStarX;
                
                // If the star is off the screen, deactivate it
                if (star.x < -16 || star.x > engine.WIDTH) {
                    star.active = false;
                }
            }
            else {
                // Random chance for the star to be reborn on the right of the screen
                // Also only if it's moved
                if (int(app.random(0, 20)) == 1 && moveStarX != 0.0) {
                    star.x = engine.WIDTH;
                    star.y = int(app.random(-16, this.height));
                    star.image = int(app.random(0, 5));
                    star.config = int(app.random(0, 4));
                    star.active = true;
                }
            }
        }
    }

    // You should call this before you begin calling any noise functions
    private void beginRandom() {
        app.noiseSeed(myRandomSeed);
    }

    // Note: as I just found out, turns out the noise function is very performance heavy
    // for whatever reason. The use of rand should be avoided if possible.
    public float rand(float i, float min, float max) {
        beginRandom();
        return app.noise(i) * (max-min) + min;
    }

    public float getHillHeight(float x) {
        float slow = x * 0.0001;
        return app.floor(rand(x*VARI, 40, MAX_RANDOM_HEIGHT))
         + (app.pow(app.sin(slow*MOUNTAIN_FREQUENCY), 3)*HIGHEST_MOUNTAIN*0.5 + HIGHEST_MOUNTAIN)
         - (app.sin(slow*LOW_DIPS_REQUENCY)*LOWEST_DIPS*0.5 + LOWEST_DIPS);
    }

    // Despite it being an overloading method, this method is quite different.
    // Returns the height of the hill from the array given the x position.
    // If the x position does not exactly match a position in the array, it will
    // return a linear interpolation between the two closest points.
    // public float getHillHeight(float[] arr, float x) {
    //     int index = int(x / HILL_WIDTH);
    //     if (index < 0) {
    //         return 0;
    //     }
    //     if (index >= arr.length) {
    //         return 0;
    //     }
    //     else if (index == arr.length-1) {
    //         return arr[index];
    //     }
    //     else {
    //         float offSet = x % HILL_WIDTH;
    //         float x1 = index * HILL_WIDTH + offSet;
    //         float x2 = (index+1) * HILL_WIDTH + offSet;
    //         float y1 = arr[index];
    //         float y2 = arr[index+1];
    //         return y1 + (y2-y1) * ((x-x1) / (x2-x1));
    //     }

    // }


    

    // Old code, flexile but uses too much cpu.
    // private void drawNightSkyStars() {
    //     int num = 100;
    //     int numImages = 4;
    //     app.noiseDetail(4, 0.5);
    //     // get the nightsky0.png image
    //     PImage star = engine.systemImages.get("nightsky0");
        
    //     for (int i = 0; i < num; i++) {
    //         //app.pushMatrix();
    //         // We multiply the index by random numbers to get plenty of variation in the randomness.
    //         float x = i*(engine.WIDTH/num) + rand(float(i*192), -100, 100);
    //         float y = rand(float(i*58), -engine.HEIGHT/4+myUpperBarWeight, engine.HEIGHT);

    //         // Translating and rotating is performance expensive :(
    //         // Uncomment at your own risk    
    //         //app.translate(x, y);
    //         //app.rotate(rand(i*384, 0, 360));
    //         //engine.imgCentre("nightsky"+str(int(i/(num/numImages))), 0, 0);

    //         engine.img("nightsky"+str(int(rand(i*293, 0, numImages))), x, y, 16, 16);
    //         //app.popMatrix();
    //     }
    // }

    public float interpolate(float arr[], float x) {
        float y1 = arr[int(x)];
        float y2 = arr[int(x)+1];
        float i = (x / HILL_WIDTH);
        
        return app.lerp(y1, y2, i);
        
    }

    public float getHillHeight(float arr[], float myX) {
        //float offset = 
        return 0;
    }

    

    public void content() {
        app.noiseDetail(OCTAVE, 2.);
        
        engine.img("sky_1", 0, myUpperBarWeight, engine.WIDTH, this.height);

        if (displayStars)
            drawNightSkyStars();

        
        // Create some polygonal hills with random heights with vertex
        float hillWidth = HILL_WIDTH;
        float prevWaveHeight = WATER_LEVEL;
        float prevHeight = 0;
        float floorPos = this.height + myUpperBarWeight;
        boolean switchToWater = false;

        if (engine.mouseEventClick) {
            xscroll += 5;
        }

        xscroll += 50;
        moveStarX = 1;

        // List to store each vertex height
        float[] chunks = new float[int(engine.WIDTH/hillWidth)*2];

        // Index for the chunks list
        int j = 0;


        float w = engine.WIDTH+hillWidth;
        for (float i = -hillWidth; i < w; i += hillWidth) {
            float x = i + app.floor(xscroll/hillWidth) * hillWidth;

            float hillHeight = getHillHeight(x);



            // If roughly in the middle of the screen
            if (i > engine.WIDTH/2 - hillWidth && i < engine.WIDTH/2 + hillWidth) {
                // smoothly scroll to the y position
                yscroll = app.lerp(yscroll, hillHeight-300, 0.01);
            }

            chunks[j++] = hillHeight;

            float off = float(int(xscroll)%int(hillWidth));

            // Draw 4 verticies to create a hill
            // Note: I was trying to figure out how to get
            // a perfect hill scroller and turns out I just
            // need to replace x with i in verticies
            app.beginShape();
            app.fill(0);
            app.vertex(i-off, floorPos-prevHeight+yscroll);              // Top left
            app.vertex(i-off, floorPos);              // Bottom left
            app.vertex(i-off + hillWidth, floorPos);  // Bottom right
            app.vertex(i-off + hillWidth, floorPos-hillHeight+yscroll);  // Top right
            app.endShape();

            app.beginShape();
            app.fill(0, 127, 255, 100);
            float wave = WATER_LEVEL+app.sin(x*0.01+app.frameCount*0.1)*10;
            app.vertex(i-off, app.max(floorPos-prevWaveHeight+yscroll, 0));              // Top left
            app.vertex(i-off, floorPos);              // Bottom left
            app.vertex(i-off + hillWidth, floorPos);  // Bottom right
            app.vertex(i-off + hillWidth, app.max(floorPos-wave+yscroll, 0));  // Top right
            app.endShape();
            prevHeight = hillHeight;
            prevWaveHeight = wave;






        
        
        }

            // Draw a tree on the hill
        //Draw the palm trees using the chunks array
        for (float i = 0; i < w; i += TREE_SPACE) {
            float off = float(int(xscroll)%int(TREE_SPACE));
            float x = i - off;

            int index = int(x / hillWidth);
            float hillHeight = 0;
            if (index >= 0 && index < chunks.length)
                hillHeight = chunks[index];
            if (hillHeight > WATER_LEVEL) {
                float y1 = 0.;
                float y2 = 0.;
                float y  = x / HILL_WIDTH;
                try {
                    y1 = chunks[index+1];
                    y2 = chunks[index+2];
                }
                catch (Exception e) {

                }
                // get a value between 0. and 1. between the current hill and the next hill
                //engine.img("palm_2_256", x-hillWidth, floorPos-interpolate+yscroll-256);
            }
        }
    }
}
