// ============================================================
// AUTOMATACORE.PDE
// Core cellular automata logic: token movement, energy packets,
// Petri net transitions, and state updates
// ============================================================

// === MAIN UPDATE FUNCTION ===
void updateAutomata() {
  // Reset deltas (atomic accumulators)
  for (int x = 0; x < cols; x++) {
    for (int y = 0; y < rows; y++) {
      deltaTokensA[x][y] = 0;
      deltaTokensB[x][y] = 0;
      deltaEnergy[x][y] = 0;
    }
  }

  for (int x = 0; x < cols; x++) {
    for (int y = 0; y < rows; y++) {
      int a = tokensA[x][y];
      int b = tokensB[x][y];
      int currentTokens = a + b;
      float currentEnergy = cellEnergy[x][y];

      // Copy current state to next state as baseline
      nextTokensA[x][y] = a;
      nextTokensB[x][y] = b;
      nextEnergy[x][y] = currentEnergy;

      // Skip dead cells
      if (currentTokens == 0 && currentEnergy < 0.1) {
        nextTokensA[x][y] = 0;
        nextTokensB[x][y] = 0;
        nextEnergy[x][y] = 0;
        continue;
      }

      int neighborTokens = countNeighborTokens(x, y);
      float neighborAvgEnergy = getNeighborAvgEnergy(x, y);

      // === DEGENERATION ===
      float energyLoss = BASELINE_DECAY;
      if (neighborTokens == 0) energyLoss += ISOLATION_DECAY;
      float newEnergy = max(0, currentEnergy - energyLoss);
      
      energyDrainTracker[x][y] = energyLoss;

      // === ENERGY PACKETS ===
      float pEmit = PACKET_EMIT_RATE * constrain(newEnergy / MAX_ENERGY, 0, 1);
      pEmit *= (1.0 - 0.10 * min(b, 5));
      
      int emitCount = 0;
      while (emitCount < PACKETS_MAX_PER_CELL && random(1) < pEmit) emitCount++;
      
      for (int p = 0; p < emitCount; p++) {
        int packed = getRandomNeighborPacked(x, y);
        int nx = unpackX(packed);
        int ny = unpackY(packed);
        
        float packetEnergy = min(PACKET_SIZE, newEnergy);
        float lossMultiplier = 1.0 - PACKET_LOSS;
        float packetAfterLoss = max(0, packetEnergy * lossMultiplier);

        // Destination receives reduced energy; source pays full packetEnergy.
        // The difference is true loss from the system.
        deltaEnergy[nx][ny] += packetAfterLoss;
        newEnergy -= packetEnergy;
        if (newEnergy < 0) newEnergy = 0;
        
        // Visual particle trail (10% spawn rate for performance)
        if (random(1) < 0.1) {
          energyParticles.add(new EnergyParticle(x, y, nx, ny, hueGrid[x][y]));
        }
      }

      // === RESIDUAL DIFFUSION ===
      float diffusion = ENERGY_DIFFUSION * (1.0 - 0.15 * min(b, 5));
      diffusion = constrain(diffusion, 0.0, ENERGY_DIFFUSION);
      diffusion *= DIFFUSION_BLEND;
      
      float scarLevel = cellScar[x][y];
      diffusion *= (1.0 - scarLevel * SCAR_DIFFUSION_PENALTY);
      
      newEnergy = lerp(newEnergy, neighborAvgEnergy, diffusion);
      
      float effectiveMaxEnergy = MAX_ENERGY * (1.0 - scarLevel * SCAR_CAPACITY_PENALTY);
      newEnergy = min(newEnergy, effectiveMaxEnergy);

      int newA = a;
      int newB = b;

      // === TOKEN MOVEMENT (A movers) ===
      if (newA > 0 && newEnergy > 10) {
        float pMove = 0.05 + 0.20 * constrain((newEnergy - 10) / 40.0, 0, 1);
        pMove *= (1.0 + 0.10 * min(newA - 1, 5));
        
        // ADHESION
        if (b >= ADHESION_THRESHOLD) {
          float adhesion = 1.0 - (ADHESION_STRENGTH * (min(b, 8) / 8.0));
          pMove *= adhesion;
        }
        
        if (random(1) < pMove) {
          int packed = getBestEnergyNeighborPackedPhase(x, y);
          if (packed == -1) packed = getBestEnergyNeighborPacked(x, y);
          
          if (packed != -1) {
            int nx = unpackX(packed);
            int ny = unpackY(packed);
            int destTotal = tokensA[nx][ny] + tokensB[nx][ny] + deltaTokensA[nx][ny] + deltaTokensB[nx][ny];
            if (destTotal < MAX_TOKENS) {
              newA -= 1;
              deltaTokensA[nx][ny] += 1;

              float energyToTransfer = newEnergy * ENERGY_TRANSFER;
              energyToTransfer = max(0, energyToTransfer);
              deltaEnergy[nx][ny] += energyToTransfer;
              newEnergy -= energyToTransfer;
              
              // Note: energyDrainTracker tracks decay/damage loss only, not token movement energy
            }
          }
        }
      }

      // === TOKEN MOVEMENT (B blockers) ===
      if (newB > 0 && newEnergy > 30 && random(1) < 0.03) {
        int packed = getRandomNeighborPacked(x, y);
        int nx = unpackX(packed);
        int ny = unpackY(packed);
        int destTotal = tokensA[nx][ny] + tokensB[nx][ny] + deltaTokensA[nx][ny] + deltaTokensB[nx][ny];
        if (destTotal < MAX_TOKENS) {
          newB -= 1;
          deltaTokensB[nx][ny] += 1;
        }
      }

      // === TOKEN CREATION (AUTOPOIETIC DIFFERENTIATION) ===
      // Organisms self-organize toward optimal A/B ratio
      // A = membrane (boundary, mobile) / B = core (metabolic, stable)
      int totalAfterLocal = newA + newB;
      if (newEnergy >= ENERGY_TO_TOKEN_THRESHOLD && totalAfterLocal < MAX_TOKENS) {
        float currentRatio = totalAfterLocal > 0 ? float(newA) / totalAfterLocal : 0.5;
        
        // Self-regulate toward healthy structure (operational closure)
        if (currentRatio < OPTIMAL_AB_RATIO) {
          newA++;  // Need more membrane (protective boundary)
        } else {
          newB++;  // Need more metabolic core (stability)
        }
        
        newEnergy -= ENERGY_TO_TOKEN_THRESHOLD;
      }

      // === TOKEN DECAY ===
      if (newEnergy < 1.0 && (newA + newB) > 0) {
        if (newA > 0 && random(1) < 0.1) newA--;
        else if (newB > 0 && random(1) < 0.05) newB--;
      }

      nextTokensA[x][y] = newA;
      nextTokensB[x][y] = newB;
      nextEnergy[x][y] = newEnergy;

      // === COLOR UPDATE ===
      int updatedTokens = newA + newB;
      if (updatedTokens < COLOR_THRESHOLD) {
        hueGrid[x][y] = lerp(hueGrid[x][y], 0, 0.05);
        satGrid[x][y] = lerp(satGrid[x][y], 0, 0.05);
        briGrid[x][y] = lerp(briGrid[x][y], 0, 0.05);
      } else {
        // Cache color to avoid redundant calculations (only update occasionally)
        if (random(1) < 0.1 || hueGrid[x][y] < 1.0) {
          int blueCol = blueNebula[int(random(blueNebula.length))];
          hueGrid[x][y] = lerp(hueGrid[x][y], getHueFromHex(blueCol), 0.03);
          satGrid[x][y] = lerp(satGrid[x][y], getSatFromHex(blueCol) * 0.8, 0.03);
          briGrid[x][y] = lerp(briGrid[x][y], getBriFromHex(blueCol) * 0.7, 0.03);
        }
      }

      float noiseFactor = noise(x * 0.05, y * 0.05, millis() * 0.0003);
      satGrid[x][y] *= map(noiseFactor, 0, 1, 0.9, 1.1);
      briGrid[x][y] *= map(noiseFactor, 0, 1, 0.85, 1.15);
    }
  }

  // Apply deltas (nextTokens arrays hold local changes, deltas hold neighbor contributions)
  for (int x = 0; x < cols; x++) {
    for (int y = 0; y < rows; y++) {
      nextTokensA[x][y] = constrain(nextTokensA[x][y] + deltaTokensA[x][y], 0, MAX_TOKENS);
      nextTokensB[x][y] = constrain(nextTokensB[x][y] + deltaTokensB[x][y], 0, MAX_TOKENS);
      nextEnergy[x][y] = constrain(nextEnergy[x][y] + deltaEnergy[x][y], 0, MAX_ENERGY);
    }
  }

  updateBiomeDamageAndHealing();

  // Swap buffers
  int[][] tmpA = tokensA; tokensA = nextTokensA; nextTokensA = tmpA;
  int[][] tmpB = tokensB; tokensB = nextTokensB; nextTokensB = tmpB;
  float[][] tmpE = cellEnergy; cellEnergy = nextEnergy; nextEnergy = tmpE;
}

// === SPIRAL ENERGY INJECTION (AUTOPOIETIC TOUCH) ===
// Touch creates bidirectional relationship: viewer affects organism, organism responds
void injectPointsToAutomata() {
  for (Punto p : puntosGlobales) {
    int gx = int(p.x / cellSize);
    int gy = int(p.y / cellSize);
    if (gx >= 0 && gx < cols && gy >= 0 && gy < rows) {
      float currentEnergy = cellEnergy[gx][gy];
      float baseInjection = 8.0;
      
      // AUTOPOIETIC RULE 1: Structural Coupling
      // High-energy cells RESIST overstimulation (maintain boundary)
      float receptivity = 1.0 - (currentEnergy / MAX_ENERGY) * TOUCH_RECEPTIVITY_DECAY;
      receptivity = max(0.1, receptivity);  // Never completely closed
      
      // Low-energy cells are HUNGRY (responsive to environment)
      if (currentEnergy < 20) {
        receptivity *= HUNGER_AMPLIFICATION;
      }
      
      float injectionAmount = baseInjection * receptivity;
      
      // AUTOPOIETIC RULE 2: Memory Formation
      // Touch creates lasting trace (scar = experience, not just damage)
      float touchIntensity = injectionAmount / baseInjection;
      cellScar[gx][gy] = min(1.0, cellScar[gx][gy] + touchIntensity * OVERSTIMULATION_SCAR_RATE);
      
      // Apply energy
      cellEnergy[gx][gy] = min(MAX_ENERGY, currentEnergy + injectionAmount);
      
      // Visual feedback
      hueGrid[gx][gy] = lerp(hueGrid[gx][gy], p.hue, 0.3);
      satGrid[gx][gy] = lerp(satGrid[gx][gy], p.sat * 0.6, 0.3);
      briGrid[gx][gy] = lerp(briGrid[gx][gy], p.bri * 0.8, 0.3);
      
      // AUTOPOIETIC RULE 3: Need-Based Distribution
      // Energy flows toward deficiency, not evenly
      for (int dx = -1; dx <= 1; dx++) {
        for (int dy = -1; dy <= 1; dy++) {
          if (dx == 0 && dy == 0) continue;
          int nx = (gx + dx + cols) % cols;
          int ny = (gy + dy + rows) % rows;
          
          // Calculate neighbor's need (inversely proportional to current energy)
          float neighborEnergy = cellEnergy[nx][ny];
          float neighborNeed = (MAX_ENERGY - neighborEnergy) / MAX_ENERGY;
          float transferAmount = injectionAmount * 0.2 * neighborNeed;
          
          cellEnergy[nx][ny] = min(MAX_ENERGY, neighborEnergy + transferAmount);
        }
      }
    }
  }
  puntosGlobales.clear();
}

// === NEIGHBOR QUERIES ===
int countNeighborTokens(int x, int y) {
  int count = 0;
  for (int dx = -1; dx <= 1; dx++) {
    for (int dy = -1; dy <= 1; dy++) {
      if (dx == 0 && dy == 0) continue;
      int nx = (x + dx + cols) % cols;
      int ny = (y + dy + rows) % rows;
      if (tokensA[nx][ny] + tokensB[nx][ny] > 0) count++;
    }
  }
  return count;
}

float getNeighborAvgEnergy(int x, int y) {
  float totalEnergy = 0;
  int count = 0;
  for (int dx = -1; dx <= 1; dx++) {
    for (int dy = -1; dy <= 1; dy++) {
      if (dx == 0 && dy == 0) continue;
      int nx = (x + dx + cols) % cols;
      int ny = (y + dy + rows) % rows;
      totalEnergy += cellEnergy[nx][ny];
      count++;
    }
  }
  return count > 0 ? totalEnergy / count : 0;
}
