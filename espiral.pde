// ============================================================
// ESPIRAL.PDE - Main Entry Point
// Artificial life simulation with energy packets, biome mechanics,
// and emergent organism behavior. Art installation optimized.
//
// FILE STRUCTURE:
// - espiral.pde: Main loop (this file)
// - Constants.pde: Configuration values
// - GlobalState.pde: Runtime variables & arrays  
// - AutomataCore.pde: Token movement & energy packets
// - BiomeMechanics.pde: Damage, healing, adhesion
// - Rendering.pde: Visual output & glow effects
// - Organisms.pde: Detection & tracking
// - OrganismClass.pde: Organism class definition
// - Spirals.pde: Ola & Punto classes
// - Helpers.pde: Utilities & color functions
// ============================================================

void settings() {
  size(1200, 800);
}

void setup() {
  colorMode(HSB, 360, 100, 100);
  
  cols = width / cellSize;
  rows = height / cellSize;
  
  tokensA = new int[cols][rows];
  tokensB = new int[cols][rows];
  nextTokensA = new int[cols][rows];
  nextTokensB = new int[cols][rows];
  deltaTokensA = new int[cols][rows];
  deltaTokensB = new int[cols][rows];
  
  cellEnergy = new float[cols][rows];
  nextEnergy = new float[cols][rows];
  deltaEnergy = new float[cols][rows];
  
  hueGrid = new float[cols][rows];
  satGrid = new float[cols][rows];
  briGrid = new float[cols][rows];
  
  cellPhase = new int[cols][rows];
  for (int x = 0; x < cols; x++) {
    for (int y = 0; y < rows; y++) {
      cellPhase[x][y] = (x + y) % PHASES;
    }
  }
  
  cellScar = new float[cols][rows];
  energyDrainTracker = new float[cols][rows];
  orgStamp = new int[cols][rows];
  
  olas.add(new Ola(width/2, height/2));
  background(hexToColor(#01000E));
}

void mousePressed() {
  olas.add(new Ola(mouseX, mouseY));
  interaction = 1.0;
}

void keyPressed() {
  if (keyCode == UP) {
    radiationStrength = constrain(radiationStrength + RADIATION_STEP, RADIATION_MIN, RADIATION_MAX);
  } else if (keyCode == DOWN) {
    radiationStrength = constrain(radiationStrength - RADIATION_STEP, RADIATION_MIN, RADIATION_MAX);
  } else if (key == 'r' || key == 'R') {
    radiationStrength = 1.0;
  }
}

void draw() {
  interaction = max(0.0, interaction - interactionDecay);
  
  fadeWithColor();
  
  frameCounter++;
  if (frameCounter % updateInterval == 0) updateAutomata();
  drawAutomata();
  
  if (frameCounter % 10 == 0) {
    detectOrganisms();
  }
  
  for (Organism org : organisms) {
    org.display();
  }

  fill(0, 0, 100, 60);
  textSize(14);
  textAlign(LEFT, TOP);
  text("Radiation: " + nf(radiationStrength, 0, 2) + "  (UP/DOWN)", 12, 10);
  text("Organisms: " + organisms.size(), 12, 30);
  
  for (int i = olas.size() - 1; i >= 0; i--) {
    Ola ola = olas.get(i);
    ola.display();
    ola.update();
    
    if (ola.radio > MAX_OLA_RADIUS) {
      olas.remove(i);
    }
  }
  
  injectPointsToAutomata();
  
  if (frameCount % 60 == 0) {
    surface.setTitle("Espiral - FPS: " + nf(frameRate, 0, 1) + " | Olas: " + olas.size());
  }
}
