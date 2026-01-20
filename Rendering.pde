// ============================================================
// RENDERING.PDE
// Visual rendering: cells, glow halos, and fade effects
// ============================================================

void drawAutomata() {
  loadPixels();
  for (int x = 0; x < cols; x++) {
    for (int y = 0; y < rows; y++) {
      int tokenCount = tokensA[x][y] + tokensB[x][y];
      int bTokens = tokensB[x][y];
      float energy = cellEnergy[x][y];

      float life = map(energy, 0, MAX_ENERGY, 0, 1);
      if (tokenCount == 0 && energy < 0.5) continue;

      float colorHue = hueGrid[x][y];
      float colorSat = satGrid[x][y];
      float colorBri = briGrid[x][y] * life;

      // BIOME COLOR-CODING
      float scarLevel = cellScar[x][y];
      float adhesion = bTokens >= ADHESION_THRESHOLD ? (min(bTokens, 8) / 8.0) : 0;
      
      if (scarLevel > 0.3) {
        colorHue = lerp(colorHue, 0, scarLevel);
        colorSat = lerp(colorSat, 80, scarLevel * 0.7);
      }
      
      if (adhesion > 0.5 && scarLevel < 0.2) {
        colorHue = lerp(colorHue, 180, adhesion * 0.6);
        colorSat = lerp(colorSat, 70, adhesion * 0.5);
      }

      if (tokenCount >= COLOR_THRESHOLD) {
        colorBri *= 1.8;
      }
      
      if (energy > 60) {
        colorSat *= 0.85;
        colorBri *= 1.3;
      }

      float h = colorHue;
      float s = colorSat * interaction;
      float b = colorBri;
      
      b *= (1.0 - scarLevel * 0.5);

      int c = color(h, s, b, map(life, 0, 1, 40, 120));
      int baseIndex = (y * cellSize * width) + (x * cellSize);

      for (int dy = 0; dy < cellSize; dy++) {
        for (int dx = 0; dx < cellSize; dx++) {
          int px = baseIndex + dy * width + dx;
          if (px < pixels.length) pixels[px] = c;
        }
      }
    }
  }
  updatePixels();
  
  // === GLOW HALOS ===
  noStroke();
  for (int x = 0; x < cols; x++) {
    for (int y = 0; y < rows; y++) {
      int tokenCount = tokensA[x][y] + tokensB[x][y];
      float energy = cellEnergy[x][y];
      
      if (energy < 20 || tokenCount < 2) continue;
      
      float life = map(energy, 0, MAX_ENERGY, 0, 1);
      float cx = x * cellSize + cellSize/2;
      float cy = y * cellSize + cellSize/2;
      
      float haloHue = hueGrid[x][y];
      float haloSat = satGrid[x][y] * 0.8;
      float haloBri = briGrid[x][y] * life * 0.6;
      
      float scarLevel = cellScar[x][y];
      if (scarLevel > 0.3) {
        haloHue = 0;
        haloSat *= 0.7;
      }
      
      fill(haloHue, haloSat * 0.6, haloBri * 0.8, 15 * life);
      ellipse(cx, cy, cellSize * 6, cellSize * 6);
      
      fill(haloHue, haloSat * 0.8, haloBri * 1.2, 25 * life);
      ellipse(cx, cy, cellSize * 3, cellSize * 3);
      
      if (tokenCount >= COLOR_THRESHOLD) {
        fill(haloHue, haloSat * 0.4, 100, 40 * life);
        ellipse(cx, cy, cellSize * 1.5, cellSize * 1.5);
      }
    }
  }
}

void fadeWithColor() {
  int fadeCol = baseBG[0];
  
  float h = getHueFromHex(fadeCol);
  float s = getSatFromHex(fadeCol);
  float b = getBriFromHex(fadeCol);
  
  fill(h, s, b, FADE_ALPHA);
  rect(0, 0, width, height);
}
