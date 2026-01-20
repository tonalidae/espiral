// ============================================================
// CONSTANTS.PDE
// All configuration constants for the espiral simulation
// ============================================================

// --- Visual Constants ---
final int CELL_SIZE = 2;
final int STATES = 3;
final int VECINDAD = 1;
final float GLOBAL_DEEP = 0.2;
final float INTERACTION_DECAY = 0.0005;  // Slower decay for art installation (was 0.002)
final int MAX_OLA_RADIUS = 1500;
final int FADE_ALPHA = 12;  // Slower fade for longer trails (was 15)
final int GLOW_LAYERS = 2;

// --- Color Palette (Nebula Theme) ---
int[] baseBG = {hexToColor(#01000E), hexToColor(#02011E), hexToColor(#05022E), hexToColor(#0A073B), hexToColor(#0D044D)};
int[] blueNebula = {hexToColor(#1E0F82), hexToColor(#271F9B), hexToColor(#302A98), hexToColor(#3734A7), hexToColor(#6B6CB0), hexToColor(#7071B1)};
int[] greenNebula = {hexToColor(#4B6B40), hexToColor(#5E775B), hexToColor(#5F7A56), hexToColor(#97BA79), hexToColor(#ADCB87), hexToColor(#AFD28A)};
int[] sparkles = {hexToColor(#B3B3D5), hexToColor(#9AB0C6), hexToColor(#A685BB)};

// --- Petri Net + Energy Constants ---
final int MAX_TOKENS = 10;
final float MAX_ENERGY = 100.0;
final float ENERGY_TO_TOKEN_THRESHOLD = 15.0;
final int ACTIVATION_THRESHOLD = 2;
final int COLOR_THRESHOLD = 3;
final float BASELINE_DECAY = 0.2;  // Reduced from 0.5 to prevent rapid death
final float ISOLATION_DECAY = 0.5;  // Reduced from 1.5 to help isolated cells survive
final float ENERGY_TRANSFER = 0.3;  // Reduced from 0.7 to prevent token movement drain
final float ENERGY_DIFFUSION = 0.05;

// --- Energy Packets (ALIEN-inspired) ---
final float PACKET_EMIT_RATE = 0.02;
final float PACKET_SIZE = 5.0;  // Increased from 2.0 for better energy transfer
final int PACKETS_MAX_PER_CELL = 3;
final float PACKET_LOSS = 0.02;
final float DIFFUSION_BLEND = 0.40;  // Increased from 0.20 for better energy sharing

// --- Biome Mechanics ---
final float DAMAGE_THRESHOLD = 8.0;
final float SCAR_RATE = 0.03;
final float HEAL_RATE = 0.01;
final float SCAR_CAPACITY_PENALTY = 0.5;
final float SCAR_DIFFUSION_PENALTY = 0.6;
final float ADHESION_THRESHOLD = 4;
final float ADHESION_STRENGTH = 0.5;

// --- Token Lanes ---
final int PHASES = 6;

// --- Organism System ---
final int MIN_ORGANISM_SIZE = 5;
final float ORGANISM_DETECTION_ENERGY = 10.0;

// --- Autopoietic Life Narrative ---
// A tokens = MEMBRANE (self-boundary, mobile, protective)
// B tokens = CORE (metabolic center, stable, vulnerable)
// Healthy organisms maintain balance between openness and closure
final float OPTIMAL_AB_RATIO = 0.6;  // 60% A / 40% B = healthy boundary
final float REPRODUCTION_THRESHOLD = 150.0;  // Energy buffer needed to reproduce
final float STARVATION_THRESHOLD = 5.0;  // Reduced from 10.0 for longer survival time
final float OVERSTIMULATION_SCAR_RATE = 0.05;  // Memory formation from touch
final float TOUCH_RECEPTIVITY_DECAY = 0.5;  // High-energy cells resist further input
final float HUNGER_AMPLIFICATION = 1.5;  // Low-energy cells amplify connection
