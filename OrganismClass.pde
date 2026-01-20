// ============================================================
// ORGANISMCLASS.PDE
// Organism class definition and rendering
// ============================================================

class Organism {
  int id;
  ArrayList<PVector> cells;
  PVector centerOfMass;
  float totalEnergy;
  float totalTokensA;
  float totalTokensB;
  int age;
  
  PVector coreCell;
  ArrayList<PVector> sensoryOrgans;
  ArrayList<PVector> structuralOrgans;
  
  float displayAlpha = 255;
  int lastSeenFrame = 0;
  boolean matchedThisDetection = false;
  
  Organism(int id) {
    this.id = id;
    cells = new ArrayList<PVector>();
    sensoryOrgans = new ArrayList<PVector>();
    structuralOrgans = new ArrayList<PVector>();
    age = 0;
  }
  
  void update() {
    age++;
    calculateCenterOfMass();
    calculateMetabolism();
    identifyOrgans();
  }
  
  void calculateCenterOfMass() {
    float sumX = 0, sumY = 0;
    float sumEnergy = 0;
    
    for (PVector cell : cells) {
      int x = int(cell.x);
      int y = int(cell.y);
      float energy = cellEnergy[x][y];
      sumX += x * energy;
      sumY += y * energy;
      sumEnergy += energy;
    }
    
    if (sumEnergy > 0) {
      centerOfMass = new PVector(sumX / sumEnergy, sumY / sumEnergy);
    }
  }
  
  void calculateMetabolism() {
    totalEnergy = 0;
    totalTokensA = 0;
    totalTokensB = 0;
    
    for (PVector cell : cells) {
      int x = int(cell.x);
      int y = int(cell.y);
      totalEnergy += cellEnergy[x][y];
      totalTokensA += tokensA[x][y];
      totalTokensB += tokensB[x][y];
    }
  }
  
  void identifyOrgans() {
    stampCounter++;
    for (PVector cell : cells) {
      int x = int(cell.x);
      int y = int(cell.y);
      orgStamp[x][y] = stampCounter;
    }
    
    float maxEnergy = 0;
    for (PVector cell : cells) {
      int x = int(cell.x);
      int y = int(cell.y);
      float energy = cellEnergy[x][y];
      if (energy > maxEnergy) {
        maxEnergy = energy;
        coreCell = cell.copy();
      }
    }
    
    sensoryOrgans.clear();
    for (PVector cell : cells) {
      int x = int(cell.x);
      int y = int(cell.y);
      if (tokensA[x][y] >= 5 && isAtEdge(x, y)) {
        sensoryOrgans.add(cell.copy());
      }
    }
    
    structuralOrgans.clear();
    for (PVector cell : cells) {
      int x = int(cell.x);
      int y = int(cell.y);
      if (tokensB[x][y] >= 5) {
        structuralOrgans.add(cell.copy());
      }
    }
  }
  
  boolean isAtEdge(int x, int y) {
    int neighbors = 0;
    for (int dx = -1; dx <= 1; dx++) {
      for (int dy = -1; dy <= 1; dy++) {
        if (dx == 0 && dy == 0) continue;
        int nx = (x + dx + cols) % cols;
        int ny = (y + dy + rows) % rows;
        if (orgStamp[nx][ny] == stampCounter) neighbors++;
      }
    }
    return neighbors < 8;
  }
  
  boolean belongsToOrganism(int x, int y) {
    return orgStamp[x][y] == stampCounter;
  }
  
  void display() {
    if (centerOfMass == null) return;

    float alphaMultiplier = displayAlpha / 255.0;
    if (alphaMultiplier <= 0.001) return;

    float cmX = centerOfMass.x * cellSize + cellSize * 0.5;
    float cmY = centerOfMass.y * cellSize + cellSize * 0.5;

    pushStyle();

    // Filament network
    blendMode(ADD);
    strokeCap(ROUND);
    strokeJoin(ROUND);

    int maxLinks = 240;
    int step = max(1, cells.size() / maxLinks);

    for (int i = 0; i < cells.size(); i += step) {
      PVector c = cells.get(i);
      int x = int(c.x);
      int y = int(c.y);

      if (!isAtEdge(x, y) && random(1) > 0.35) continue;

      int bestNx = -1, bestNy = -1;
      float bestE = -1;
      for (int dx = -1; dx <= 1; dx++) {
        for (int dy = -1; dy <= 1; dy++) {
          if (dx == 0 && dy == 0) continue;
          int nx = (x + dx + cols) % cols;
          int ny = (y + dy + rows) % rows;
          if (orgStamp[nx][ny] != stampCounter) continue;
          float e = cellEnergy[nx][ny];
          if (e > bestE) {
            bestE = e;
            bestNx = nx;
            bestNy = ny;
          }
        }
      }
      if (bestNx < 0) continue;

      float x1 = x * cellSize + cellSize * 0.5;
      float y1 = y * cellSize + cellSize * 0.5;
      float x2 = bestNx * cellSize + cellSize * 0.5;
      float y2 = bestNy * cellSize + cellSize * 0.5;

      float e1 = cellEnergy[x][y];
      float life = constrain((e1 + bestE) * 0.5 / MAX_ENERGY, 0, 1);

      float t = frameCount * 0.02 + id * 0.31 + i * 0.005;
      float bend = (noise(t, x * 0.03, y * 0.03) - 0.5) * cellSize * 6.0;
      float bend2 = (noise(t + 9.7, x * 0.03, y * 0.03) - 0.5) * cellSize * 6.0;
      float mx = (x1 + x2) * 0.5 + bend;
      float my = (y1 + y2) * 0.5 + bend2;

      float hueG = 110 + 18 * noise(t * 0.6);
      float satG = 55 + 20 * life;
      float briG = 35 + 45 * life;
      float a = 10 + 35 * alphaMultiplier * (0.25 + 0.75 * life);

      stroke(hueG, satG, briG, a);
      strokeWeight(0.6 + 1.2 * life);
      noFill();
      beginShape();
      curveVertex(x1, y1);
      curveVertex(x1, y1);
      curveVertex(mx, my);
      curveVertex(x2, y2);
      curveVertex(x2, y2);
      endShape();
    }

    // Energy nodes
    noStroke();
    int maxNodes = 120;
    int nodeStep = max(1, cells.size() / maxNodes);
    for (int i = 0; i < cells.size(); i += nodeStep) {
      PVector c = cells.get(i);
      int cx = int(c.x);
      int cy = int(c.y);
      float e = cellEnergy[cx][cy];
      if (e < 18) continue;

      float x = cx * cellSize + cellSize * 0.5;
      float y = cy * cellSize + cellSize * 0.5;
      float life = constrain(e / MAX_ENERGY, 0, 1);

      float size = cellSize * (0.9 + 1.6 * life);
      float hueY = 50;
      float satY = 35 + 30 * life;
      float briY = 70 + 30 * life;
      float a = 25 + 65 * alphaMultiplier * (0.25 + 0.75 * life);
      drawGlowCircle(x, y, size, hueY, satY, briY, a);
    }

    // Core nucleus
    if (coreCell != null) {
      float coreX = coreCell.x * cellSize + cellSize * 0.5;
      float coreY = coreCell.y * cellSize + cellSize * 0.5;
      drawGlowCircle(coreX, coreY, cellSize * 3.8, 52, 25, 100, 80 * alphaMultiplier);
    }

    // Transport paths
    int maxPaths = min(14, sensoryOrgans.size());
    for (int i = 0; i < maxPaths; i++) {
      PVector s = sensoryOrgans.get(i);
      float sx = s.x * cellSize + cellSize * 0.5;
      float sy = s.y * cellSize + cellSize * 0.5;

      int segments = 7;
      for (int k = 1; k <= segments; k++) {
        float u = k / (float)segments;
        float wob = (noise(id * 0.17, frameCount * 0.03, i * 0.5 + k) - 0.5) * cellSize * 2.0;
        float px = lerp(sx, cmX, u) + wob;
        float py = lerp(sy, cmY, u) - wob;

        float hueP = 285;
        float satP = 45;
        float briP = 80;
        float a = 10 + 35 * alphaMultiplier * (1.0 - u);
        drawGlowCircle(px, py, cellSize * 0.75, hueP, satP, briP, a);
      }
    }

    // Flowers
    blendMode(BLEND);
    int maxFlowers = min(10, sensoryOrgans.size());
    for (int i = 0; i < maxFlowers; i++) {
      PVector s = sensoryOrgans.get(i);
      float fx = s.x * cellSize + cellSize * 0.5;
      float fy = s.y * cellSize + cellSize * 0.5;

      float wob = (noise(frameCount * 0.02, id * 0.11, i * 0.33) - 0.5) * cellSize * 1.2;
      float size = cellSize * 2.2;
      drawFlower(fx + wob, fy - wob, size, 55 * alphaMultiplier);
    }

    popStyle();
  }
  
  boolean isAlive() {
    return cells.size() >= MIN_ORGANISM_SIZE && totalEnergy > 1.0;
  }
}
