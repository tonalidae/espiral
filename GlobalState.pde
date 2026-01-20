// ============================================================
// GLOBALSTATE.PDE
// Global runtime variables and state arrays
// ============================================================

// --- Runtime Variables ---
int cellSize = CELL_SIZE;
int states = STATES;
int vecindad = VECINDAD;
float globalDeep = GLOBAL_DEEP;
float interaction = 0.75;
float interactionDecay = INTERACTION_DECAY;

// --- Camera/Zoom Controls ---
float zoomLevel = 2.0;      // Art installation: Start zoomed in to see organisms
float cameraX = 0;
float cameraY = 0;
float targetZoom = 2.0;     // Match initial zoom

// --- Grid Dimensions ---
int cols, rows;

// --- Token Arrays ---
int[][] tokensA, tokensB;
int[][] nextTokensA, nextTokensB;
int[][] deltaTokensA, deltaTokensB;

// --- Energy Arrays ---
float[][] cellEnergy, nextEnergy;
float[][] deltaEnergy;

// --- Visual Arrays ---
float[][] hueGrid, satGrid, briGrid;

// --- Phase Field ---
int[][] cellPhase;

// --- Biome State ---
float[][] cellScar;
float[][] energyDrainTracker;

// --- Organism Tracking ---
ArrayList<Organism> organisms = new ArrayList<Organism>();
int organismIDCounter = 1;
int[][] orgStamp;
int stampCounter = 1;

// --- Spirals and Points ---
ArrayList<Ola> olas = new ArrayList<Ola>();
ArrayList<Punto> puntosGlobales = new ArrayList<Punto>();

// --- Visual Effects ---
ArrayList<EnergyParticle> energyParticles = new ArrayList<EnergyParticle>();

class EnergyParticle {
  PVector pos;
  PVector target;
  float life;
  float hue;
  
  EnergyParticle(float x1, float y1, float x2, float y2, float h) {
    pos = new PVector(x1, y1);
    target = new PVector(x2, y2);
    life = 1.0;
    hue = h;
  }
  
  void update() {
    pos.lerp(target, 0.15);
    life -= 0.05;
  }
  
  boolean isDead() {
    return life <= 0 || PVector.dist(pos, target) < 0.5;
  }
  
  void display() {
    pushStyle();
    noStroke();
    fill(hue, 80, 100, life * 100);
    ellipse(pos.x * cellSize, pos.y * cellSize, cellSize * 1.5, cellSize * 1.5);
    popStyle();
  }
}

// --- Frame Control ---
int updateInterval = 6;
int frameCounter = 0;
