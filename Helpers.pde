// ============================================================
// HELPERS.PDE
// Utility functions: color conversion, packed indices, 
// organism rendering helpers
// ============================================================

// === COLOR CONVERSION ===
int hexToColor(int hexValue) {
  int r = (hexValue >> 16) & 0xFF;
  int g = (hexValue >> 8) & 0xFF;
  int b = hexValue & 0xFF;
  return (r << 16) | (g << 8) | b;
}

float getHueFromHex(int hexColor) {
  int r = (hexColor >> 16) & 0xFF;
  int g = (hexColor >> 8) & 0xFF;
  int b = hexColor & 0xFF;
  
  float rf = r / 255.0;
  float gf = g / 255.0;
  float bf = b / 255.0;
  
  float max = max(rf, gf, bf);
  float min = min(rf, gf, bf);
  float delta = max - min;
  
  float h = 0;
  if (delta != 0) {
    if (max == rf) {
      h = 60 * (((gf - bf) / delta) % 6);
    } else if (max == gf) {
      h = 60 * (((bf - rf) / delta) + 2);
    } else {
      h = 60 * (((rf - gf) / delta) + 4);
    }
  }
  if (h < 0) h += 360;
  return h;
}

float getSatFromHex(int hexColor) {
  int r = (hexColor >> 16) & 0xFF;
  int g = (hexColor >> 8) & 0xFF;
  int b = hexColor & 0xFF;
  
  float rf = r / 255.0;
  float gf = g / 255.0;
  float bf = b / 255.0;
  
  float max = max(rf, gf, bf);
  float min = min(rf, gf, bf);
  float delta = max - min;
  
  if (max == 0) return 0;
  return (delta / max) * 100;
}

float getBriFromHex(int hexColor) {
  int r = (hexColor >> 16) & 0xFF;
  int g = (hexColor >> 8) & 0xFF;
  int b = hexColor & 0xFF;
  
  float rf = r / 255.0;
  float gf = g / 255.0;
  float bf = b / 255.0;
  
  return max(rf, gf, bf) * 100;
}

// === PACKED INDICES ===
int pack(int x, int y) {
  return x + y * cols;
}

int unpackX(int idx) {
  return idx % cols;
}

int unpackY(int idx) {
  return idx / cols;
}

int getRandomNeighborPacked(int x, int y) {
  int r = int(random(8));
  int dx = 0, dy = 0;
  switch (r) {
    case 0: dx = -1; dy = -1; break;
    case 1: dx =  0; dy = -1; break;
    case 2: dx =  1; dy = -1; break;
    case 3: dx = -1; dy =  0; break;
    case 4: dx =  1; dy =  0; break;
    case 5: dx = -1; dy =  1; break;
    case 6: dx =  0; dy =  1; break;
    case 7: dx =  1; dy =  1; break;
  }
  int nx = (x + dx + cols) % cols;
  int ny = (y + dy + rows) % rows;
  return pack(nx, ny);
}

int getBestEnergyNeighborPacked(int x, int y) {
  float bestE = cellEnergy[x][y];
  int bestX = x, bestY = y;

  for (int dx = -1; dx <= 1; dx++) {
    for (int dy = -1; dy <= 1; dy++) {
      if (dx == 0 && dy == 0) continue;
      int nx = (x + dx + cols) % cols;
      int ny = (y + dy + rows) % rows;
      float e = cellEnergy[nx][ny];
      if (e > bestE) {
        bestE = e;
        bestX = nx;
        bestY = ny;
      }
    }
  }
  
  if (bestX == x && bestY == y) return -1;
  return pack(bestX, bestY);
}

int getBestEnergyNeighborPackedPhase(int x, int y) {
  int currentPhase = cellPhase[x][y];
  int targetPhase = (currentPhase + 1) % PHASES;
  float bestE = -1;
  int bestX = -1, bestY = -1;

  for (int dx = -1; dx <= 1; dx++) {
    for (int dy = -1; dy <= 1; dy++) {
      if (dx == 0 && dy == 0) continue;
      int nx = (x + dx + cols) % cols;
      int ny = (y + dy + rows) % rows;
      
      if (cellPhase[nx][ny] == targetPhase) {
        float e = cellEnergy[nx][ny];
        if (e > bestE) {
          bestE = e;
          bestX = nx;
          bestY = ny;
        }
      }
    }
  }
  
  if (bestX == -1) return -1;
  return pack(bestX, bestY);
}

// === ORGANISM RENDERING ===
void drawGlowCircle(float x, float y, float size, float h, float s, float b, float a) {
  noStroke();
  fill(h, s * 0.60, b * 0.55, a * 0.10);
  ellipse(x, y, size * 2.0, size * 2.0);
  fill(h, s * 0.80, b * 0.75, a * 0.18);
  ellipse(x, y, size * 1.35, size * 1.35);
  fill(h, s, b, a);
  ellipse(x, y, size, size);
}

void drawFlower(float x, float y, float size, float a) {
  pushStyle();
  noStroke();

  float petalR = size * 0.55;
  for (int i = 0; i < 5; i++) {
    float ang = TWO_PI * i / 5.0;
    float px = x + cos(ang) * petalR;
    float py = y + sin(ang) * petalR;
    fill(55, 10, 100, a * 0.55);
    ellipse(px, py, size * 0.70, size * 0.50);
  }

  fill(50, 30, 100, a);
  ellipse(x, y, size * 0.45, size * 0.45);

  popStyle();
}
