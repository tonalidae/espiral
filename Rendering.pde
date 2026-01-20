// ============================================================
// RENDERING.PDE
// Visual rendering: cells, glow halos, and fade effects
// ============================================================

void drawAutomata() {
  // Viewport culling: Calculate visible cell range based on camera and zoom
  int startX = max(0, int((-cameraX - width/(2*zoomLevel)) / cellSize));
  int endX = min(cols, int((-cameraX + width/(2*zoomLevel)) / cellSize) + 1);
  int startY = max(0, int((-cameraY - height/(2*zoomLevel)) / cellSize));
  int endY = min(rows, int((-cameraY + height/(2*zoomLevel)) / cellSize) + 1);
  
  loadPixels();
  for (int x = startX; x < endX; x++) {
    for (int y = startY; y < endY; y++) {
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
      
      // AUTOPOIETIC MEMORY: Scars shimmer with remembered touch
      if (scarLevel > 0.1) {
        float memoryGlow = scarLevel * 30;  // 0-30% brightness boost
        colorBri = min(100, colorBri + memoryGlow);
        colorSat = colorSat * (1.0 - scarLevel * 0.5);  // Desaturate toward white/silver
      }
      
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
  
  // === GLOW HALOS === (with viewport culling)
  noStroke();
  for (int x = startX; x < endX; x++) {
    for (int y = startY; y < endY; y++) {
      int tokenCount = tokensA[x][y] + tokensB[x][y];
      float energy = cellEnergy[x][y];
      
      // Enhanced bloom for very high energy cells (visual "heat")
      if (energy > 70 && tokenCount >= COLOR_THRESHOLD) {
        float cx = x * cellSize + cellSize * 0.5;
        float cy = y * cellSize + cellSize * 0.5;
        float life = constrain(energy / MAX_ENERGY, 0, 1);
        float bloomIntensity = map(energy, 70, MAX_ENERGY, 0, 1);
        
        float haloHue = hueGrid[x][y];
        float haloSat = satGrid[x][y];
        
        // Outer bloom ring
        fill(haloHue, haloSat * 0.3, 100, 8 * life * bloomIntensity);
        ellipse(cx, cy, cellSize * 5, cellSize * 5);
        
        // Middle bloom
        fill(haloHue, haloSat * 0.5, 100, 15 * life * bloomIntensity);
        ellipse(cx, cy, cellSize * 3, cellSize * 3);
      }
      
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
      
      // Reduced glow sizes to make organisms more visible
      fill(haloHue, haloSat * 0.6, haloBri * 0.8, 15 * life);
      ellipse(cx, cy, cellSize * 3, cellSize * 3);
      
      fill(haloHue, haloSat * 0.8, haloBri * 1.2, 25 * life);
      ellipse(cx, cy, cellSize * 1.5, cellSize * 1.5);
      
      if (tokenCount >= COLOR_THRESHOLD) {
        fill(haloHue, haloSat * 0.4, 100, 40 * life);
        ellipse(cx, cy, cellSize * 0.8, cellSize * 0.8);
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
