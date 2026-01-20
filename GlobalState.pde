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

// --- Frame Control ---
int updateInterval = 6;
int frameCounter = 0;
