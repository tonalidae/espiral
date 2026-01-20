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
  
  // Initial energy seeding: Bootstrap ecosystem with scattered high-energy cells
  for (int i = 0; i < 100; i++) {
    int x = int(random(cols));
    int y = int(random(rows));
    cellEnergy[x][y] = random(50, 80);  // Start with viable energy levels
    tokensA[x][y] = int(random(2, 5));  // Add some initial tokens
  }
  
  olas.add(new Ola(width/2, height/2));
  background(hexToColor(#01000E));
}

void mousePressed() {
  olas.add(new Ola(mouseX, mouseY));
  interaction = 1.0;
}

void keyPressed() {
  if (key == 'r' || key == 'R') {
    targetZoom = 1.5;  // Reset to art installation default
    cameraX = 0;
    cameraY = 0;
  } else if (key == '+' || key == '=') {
    targetZoom = min(5.0, targetZoom + 0.2);
  } else if (key == '-' || key == '_') {
    targetZoom = max(0.5, targetZoom - 0.2);
  }
}

void mouseWheel(MouseEvent event) {
  float delta = event.getCount();
  targetZoom = constrain(targetZoom - delta * 0.1, 0.5, 5.0);
}

void mouseDragged() {
  if (mouseButton == RIGHT) {
    float dx = (mouseX - pmouseX) / zoomLevel;
    float dy = (mouseY - pmouseY) / zoomLevel;
    cameraX += dx;
    cameraY += dy;
  }
}

void draw() {
  // Smooth zoom
  zoomLevel = lerp(zoomLevel, targetZoom, 0.1);
  
  interaction = max(0.0, interaction - interactionDecay);
  
  // Fade BEFORE zoom transform (not scaled)
  fadeWithColor();
  
  // Apply camera transformation
  pushMatrix();
  translate(width/2, height/2);
  scale(zoomLevel);
  
  // Update and draw energy particles (within transform)
  for (int i = energyParticles.size() - 1; i >= 0; i--) {
    EnergyParticle particle = energyParticles.get(i);
    particle.update();
    particle.display();
    if (particle.isDead()) energyParticles.remove(i);
  }
  translate(-width/2 + cameraX, -height/2 + cameraY);
  
  frameCounter++;
  if (frameCounter % updateInterval == 0) updateAutomata();
  drawAutomata();
  
  if (frameCounter % 10 == 0) {
    detectOrganisms();
  }
  
  for (Organism org : organisms) {
    org.display();
  }
  
  for (int i = olas.size() - 1; i >= 0; i--) {
    Ola ola = olas.get(i);
    ola.display();
    ola.update();
    
    if (ola.radio > MAX_OLA_RADIUS) {
      olas.remove(i);
    }
  }
  
  injectPointsToAutomata();
  
  popMatrix();  // End camera transformation
  
  // Minimal UI overlay for art installation
  fill(0, 0, 100, 40);  // More subtle
  textSize(12);
  textAlign(LEFT, TOP);
  text("Organisms: " + organisms.size(), 12, 10);
  text("Generation " + getMaxGeneration(), 12, 28);
  
  // Controls hint (very subtle)
  fill(0, 0, 100, 20);
  textAlign(RIGHT, TOP);
  text("Scroll: Zoom  |  Right-Drag: Pan  |  R: Reset", width - 12, 10);
  
  if (frameCount % 60 == 0) {
    surface.setTitle("Espiral | Autopoietic Life | FPS: " + nf(frameRate, 0, 1));
  }
}

// Get highest generation number for display
int getMaxGeneration() {
  int maxGen = 0;
  for (Organism org : organisms) {
    if (org.generationNumber > maxGen) {
      maxGen = org.generationNumber;
    }
  }
  return maxGen;
}
