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
  
  // Autopoietic lifecycle properties
  float reproductionBuffer = 0.0;  // Accumulated energy for reproduction
  float reproductionReadiness = 0.0;  // 0-1 for visual feedback
  int generationNumber = 0;  // Lineage tracking
  int parentID = -1;  // Parent organism ID
  int birthFrame = 0;  // When organism was born/detected
  boolean isReproducing = false;  // Reproduction state flag
  float hue = 200.0;  // Organism color (inherited with variation)
  
  // === MOVEMENT & MOTOR SYSTEM ===
  float contractionPhase = 0.0;  // Rhythmic contraction cycle (0-TWO_PI)
  PVector movementDirection = new PVector(0, 0);  // Intended movement direction
  float metabolicActivity = 1.0;  // Energy availability for movement (0-1)
  
  // === EVOLUTIONARY GENOME ===
  Genome genome;
  StructuralPhenotype phenotype;
  
  Organism(int id) {
    this.id = id;
    cells = new ArrayList<PVector>();
    sensoryOrgans = new ArrayList<PVector>();
    structuralOrgans = new ArrayList<PVector>();
    age = 0;
    birthFrame = frameCount;
    
    // Initialize random genome and express into structure
    this.genome = new Genome();
    this.genome.randomize();
    this.phenotype = new StructuralPhenotype(genome);
    this.hue = genome.hueBase;
    // Note: Initial structure will grow on first update (age==1)
  }
  
  void update() {
    age++;
    calculateCenterOfMass();
    calculateMetabolism();
    identifyOrgans();
    
    // MOVEMENT SYSTEMS: Apply motor forces to actively move organism
    if (cells.size() > 5 && centerOfMass != null) {
      // Rhythmic contraction (every frame for smooth pulsing)
      contractionPhase += 0.08;  // ~13 seconds per cycle at 60fps
      applyContraction();
      
      // Directed movement toward food (every 5 frames to reduce computation)
      if (age % 5 == 0) {
        applyMotorForces();
      }
    }
    
    // Initial growth immediately, then periodic regrowth every 120 frames
    if ((age == 1 || age % 120 == 0) && cells.size() > 0) {
      phenotype.growFromCells(cells);
    }
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
    
    // EVOLUTIONARY SELECTION: Structural efficiency bonus
    float structuralEfficiency = 1.0;
    if (cells.size() > 0 && phenotype.branchNetwork.size() > 0) {
      // Count how many cells have filament connections
      int connectedCells = 0;
      for (PVector cell : cells) {
        int connections = phenotype.countConnectionsToCell(cell);
        if (connections > 0) connectedCells++;
      }
      float connectionRatio = connectedCells / float(cells.size());
      structuralEfficiency = 0.9 + 0.4 * connectionRatio;  // 90-130% efficiency (no penalty when branches absent)
    }
    
    // AUTOPOIETIC METABOLISM: Accumulate surplus energy for reproduction
    float avgEnergy = cells.size() > 0 ? totalEnergy / cells.size() : 0;
    float surplus = totalEnergy - (cells.size() * STARVATION_THRESHOLD);
    
    if (surplus > 0) {
      // Convert 1% of surplus to reproduction buffer (modified by genome efficiency)
      reproductionBuffer += surplus * 0.01 * genome.energyEfficiency * structuralEfficiency;
    }
    
    // Calculate structural health (A/B ratio balance)
    float totalTokens = totalTokensA + totalTokensB;
    float currentRatio = totalTokens > 0 ? totalTokensA / totalTokens : 0.5;
    float structuralHealth = 1.0 - abs(currentRatio - OPTIMAL_AB_RATIO);
    
    // Calculate reproduction readiness (0-1) - using genome threshold
    float maturityFactor = constrain((frameCount - birthFrame) / 600.0, 0, 1);
    float energyFactor = constrain(avgEnergy / MAX_ENERGY, 0, 1);
    reproductionReadiness = energyFactor * structuralHealth * maturityFactor * 
                            constrain(reproductionBuffer / genome.reproductionThreshold, 0, 1);
  }
  
  // CONTRACTILE MOTION: Rhythmic pulsing like jellyfish/heart
  void applyContraction() {
    if (centerOfMass == null || cells.size() < 5) return;
    
    float contraction = sin(contractionPhase);  // -1 to +1 oscillation
    float avgEnergy = cells.size() > 0 ? totalEnergy / cells.size() : 0;
    metabolicActivity = constrain(avgEnergy / MAX_ENERGY, 0.2, 1.0);
    
    // Scale contraction by metabolic activity (weak organisms pulse less)
    contraction *= metabolicActivity;
    
    for (PVector cell : cells) {
      int x = int(cell.x);
      int y = int(cell.y);
      
      if (cellEnergy[x][y] < 5) continue;  // Skip depleted cells
      
      PVector toCenter = PVector.sub(centerOfMass, cell);
      float dist = toCenter.mag();
      
      if (dist < 0.5) continue;  // Skip cells at center
      
      toCenter.normalize();
      
      if (contraction > 0) {
        // CONTRACTION: Pull energy toward center
        if (dist > 2) {
          int nx = (x + int(toCenter.x) + cols) % cols;
          int ny = (y + int(toCenter.y) + rows) % rows;
          
          float transfer = contraction * 1.5;
          float available = cellEnergy[x][y];
          float moved = min(available, transfer);
          if (moved > 0) {
            cellEnergy[nx][ny] = min(MAX_ENERGY, cellEnergy[nx][ny] + moved);
            cellEnergy[x][y] = available - moved;
          }
        }
      } else {
        // EXPANSION: Push energy outward (creates jet propulsion)
        toCenter.mult(-1);
        int nx = (x + int(toCenter.x) + cols) % cols;
        int ny = (y + int(toCenter.y) + rows) % rows;
        
        float transfer = abs(contraction) * 1.2;
        float available = cellEnergy[x][y];
        float moved = min(available, transfer);
        if (moved > 0) {
          cellEnergy[nx][ny] = min(MAX_ENERGY, cellEnergy[nx][ny] + moved);
          cellEnergy[x][y] = available - moved;
        }
      }
    }
  }
  
  // DIRECTED PUMPING: Move toward food sources
  void applyMotorForces() {
    if (centerOfMass == null || cells.size() < 5) return;
    if (metabolicActivity < 0.3) return;  // Too weak to move
    
    // Find food direction (high-energy regions)
    movementDirection = findFoodDirection();
    
    if (movementDirection.mag() < 0.1) {
      // No food found, random exploration
      movementDirection = PVector.random2D();
      movementDirection.mult(0.3);  // Weaker random movement
    }
    
    // Apply asymmetric energy pumping to create directed motion
    for (PVector cell : cells) {
      int x = int(cell.x);
      int y = int(cell.y);
      
      if (cellEnergy[x][y] < 12) continue;  // Need energy to pump
      
      // Calculate if cell is on leading edge of movement
      PVector cellOffset = PVector.sub(cell, centerOfMass);
      if (cellOffset.mag() < 0.5) continue;
      
      cellOffset.normalize();
      float alignment = PVector.dot(cellOffset, movementDirection);
      
      if (alignment > 0.4) {  // Cell is on leading edge
        // Pump energy forward
        int nx = (x + int(movementDirection.x * 2) + cols) % cols;
        int ny = (y + int(movementDirection.y * 2) + rows) % rows;
        
        float transfer = 2.5 * metabolicActivity * alignment;
        float available = cellEnergy[x][y];
        float moved = min(available, transfer);
        if (moved > 0) {
          cellEnergy[nx][ny] = min(MAX_ENERGY, cellEnergy[nx][ny] + moved);
          cellEnergy[x][y] = available - moved;
        }
      }
    }
  }
  
  // Helper: Find direction toward nearest high-energy food source
  PVector findFoodDirection() {
    PVector bestDirection = new PVector(0, 0);
    float maxScore = 0;
    
    // Sample environment in radial pattern (performance optimized)
    int searchRadius = 30;
    int numSamples = 16;  // Check 16 directions
    
    for (int i = 0; i < numSamples; i++) {
      float angle = TWO_PI * i / numSamples;
      
      for (int r = 5; r < searchRadius; r += 3) {
        int sx = int(centerOfMass.x + cos(angle) * r);
        int sy = int(centerOfMass.y + sin(angle) * r);
        
        sx = (sx + cols) % cols;
        sy = (sy + rows) % rows;
        
        // Skip own cells
        if (orgStamp[sx][sy] == stampCounter) continue;
        
        float energy = cellEnergy[sx][sy];
        
        if (energy > 40) {  // Found high-energy cell
          PVector direction = new PVector(sx - centerOfMass.x, sy - centerOfMass.y);
          float dist = direction.mag();
          
          if (dist > 5) {  // Not too close
            float score = energy / dist;  // Closer + higher energy = better
            
            if (score > maxScore) {
              maxScore = score;
              direction.normalize();
              bestDirection = direction;
            }
          }
        }
      }
    }
    
    return bestDirection;
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
  
  // AUTOPOIETIC REPRODUCTION: Life creates life
  void reproduce() {
    if (cells.size() < 10) return;  // Too small to divide
    
    // Split organism into parent + offspring
    int splitPoint = cells.size() / 2;
    ArrayList<PVector> offspringCells = new ArrayList<PVector>();
    
    for (int i = 0; i < splitPoint; i++) {
      offspringCells.add(cells.get(i));
    }
    
    // Remove offspring cells from parent
    for (int i = 0; i < splitPoint; i++) {
      cells.remove(0);
    }
    
    // Create new organism
    Organism offspring = new Organism(organismIDCounter++);
    offspring.cells = offspringCells;
    offspring.birthFrame = frameCount;
    offspring.generationNumber = this.generationNumber + 1;
    offspring.parentID = this.id;
    offspring.matchedThisDetection = true;
    offspring.lastSeenFrame = frameCount;
    
    // EVOLUTIONARY REPRODUCTION: Mutate genome
    offspring.genome = this.genome.mutate(0.05);  // 5% mutation rate (reduced from 15%)
    offspring.hue = offspring.genome.hueBase;
    
    // Grow structures for both parent and offspring (triggers morphological change)
    this.phenotype.growFromCells(this.cells);
    offspring.phenotype = new StructuralPhenotype(offspring.genome);
    offspring.phenotype.growFromCells(offspring.cells);
    
    organisms.add(offspring);
    
    // Reproduction costs energy (autopoietic maintenance)
    for (PVector cell : cells) {
      int x = int(cell.x);
      int y = int(cell.y);
      cellEnergy[x][y] *= 0.9;  // Parent loses 10% energy (reduced from 30%)
      
      // Visual birth flash
      briGrid[x][y] = 100;
    }
    
    for (PVector cell : offspring.cells) {
      int x = int(cell.x);
      int y = int(cell.y);
      cellEnergy[x][y] *= 0.9;  // Offspring starts with slightly reduced energy (10% cost)
      
      // Visual birth flash
      briGrid[x][y] = 100;
    }
    
    // Reset reproduction buffer
    reproductionBuffer = 0;
    isReproducing = false;
  }
  
  // Check if organism should die (energy exhaustion or structural collapse)
  boolean shouldDie() {
    float avgEnergy = cells.size() > 0 ? totalEnergy / cells.size() : 0;
    int lifespan = frameCount - birthFrame;
    
    // Starvation death
    if (avgEnergy < STARVATION_THRESHOLD && lifespan > 300) {
      return true;
    }
    
    // Structural collapse (too much damage)
    float totalScar = 0;
    for (PVector cell : cells) {
      int x = int(cell.x);
      int y = int(cell.y);
      totalScar += cellScar[x][y];
    }
    float avgScar = cells.size() > 0 ? totalScar / cells.size() : 0;
    if (avgScar > 0.8) {
      return true;
    }
    
    return false;
  }
  
  // Graceful dissolution - return energy to environment with visual burst
  void dissolve() {
    for (PVector cell : cells) {
      int x = int(cell.x);
      int y = int(cell.y);
      cellEnergy[x][y] *= 0.3;  // Release energy back to commons
      briGrid[x][y] = 100;  // Death flash
      
      // Spawn radial burst particles (sparse for performance)
      if (random(1) < 0.2) {  // 20% of cells emit particles
        for (int i = 0; i < 2; i++) {
          float angle = random(TWO_PI);
          float speed = random(2, 5);
          float targetX = x + cos(angle) * speed;
          float targetY = y + sin(angle) * speed;
          energyParticles.add(new EnergyParticle(x, y, targetX, targetY, 0));  // Red hue for death
        }
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

    // EVOLVED FILAMENT NETWORK (using structural phenotype)
    float avgEnergy = cells.size() > 0 ? totalEnergy / cells.size() : 0;
    float life = constrain(avgEnergy / MAX_ENERGY, 0, 1);
    
    // Age-based color evolution: organisms shift hue as they mature
    int lifespan = frameCount - birthFrame;
    float maturity = constrain(lifespan / 1200.0, 0, 1);  // Mature over 20 seconds
    float evolvedHue = (hue + maturity * 60) % 360;  // Shift 60 degrees over lifetime
    
    phenotype.display(life * alphaMultiplier, evolvedHue);

    // Energy nodes (LOD: reduce detail when zoomed out)
    blendMode(ADD);
    noStroke();
    int maxNodes = zoomLevel < 1.0 ? 60 : 120;  // Half nodes when zoomed out
    int nodeStep = max(1, cells.size() / maxNodes);
    for (int i = 0; i < cells.size(); i += nodeStep) {
      PVector c = cells.get(i);
      int cx = int(c.x);
      int cy = int(c.y);
      float e = cellEnergy[cx][cy];
      if (e < 18) continue;

      float x = cx * cellSize + cellSize * 0.5;
      float y = cy * cellSize + cellSize * 0.5;
      float cellLife = constrain(e / MAX_ENERGY, 0, 1);

      float size = cellSize * (0.7 + 1.2 * cellLife);  // Reduced from 0.9 + 1.6
      float hueY = 50;
      float satY = 35 + 30 * cellLife;
      float briY = 50 + 25 * cellLife;  // Reduced from 70 + 30
      float a = 20 + 50 * alphaMultiplier * (0.25 + 0.75 * cellLife);  // Reduced from 25 + 65
      drawGlowCircle(x, y, size, hueY, satY, briY, a);
    }

    // Core nucleus (with reproduction readiness pulse)
    if (coreCell != null) {
      float coreX = coreCell.x * cellSize + cellSize * 0.5;
      float coreY = coreCell.y * cellSize + cellSize * 0.5;
      
      // AUTOPOIETIC FEEDBACK: Core pulses with reproduction readiness
      float baseCoreSize = cellSize * 3.8;
      float pulse = sin(frameCount * 0.1) * 0.5 + 0.5;  // 0-1 oscillation
      float readinessPulse = reproductionReadiness * pulse * cellSize * 1.5;
      float coreSize = baseCoreSize + readinessPulse;
      
      // Shift toward reproduction color (cyan/white) when ready
      float coreHue = lerp(52, 180, reproductionReadiness * 0.5);
      float coreBri = lerp(100, 100, reproductionReadiness);
      float coreAlpha = 80 * alphaMultiplier + reproductionReadiness * 40;
      
      drawGlowCircle(coreX, coreY, coreSize, coreHue, 25, coreBri, coreAlpha);
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

// ============================================================
// GENOME CLASS - Evolutionary DNA
// ============================================================
class Genome {
  // Structural genes (body plan encoding)
  float branchingProbability;    // How often filaments split (0-1)
  float branchAngle;              // Angle of branches (radians)
  int maxBranchDepth;            // How deep branching goes (1-5)
  float filamentLength;          // Length of each segment (pixels)
  float filamentDensity;         // How many filaments per cell (0-1)
  
  // Metabolic genes
  float energyEfficiency;        // Energy absorption multiplier (0.5-1.5)
  float reproductionThreshold;   // Energy needed to reproduce (100-200)
  
  // Aesthetic genes
  float hueBase;                 // Base color (0-360)
  float hueVariation;            // Color mutation range (0-60)
  
  void randomize() {
    branchingProbability = random(0.2, 0.8);
    branchAngle = random(PI/6, PI/3);  // 30-60 degrees
    maxBranchDepth = int(random(2, 5));
    filamentLength = random(8, 20);
    filamentDensity = random(0.3, 0.8);
    
    energyEfficiency = random(0.9, 1.1);  // Tightened from 0.7-1.3 for initial viability
    reproductionThreshold = random(120, 180);
    
    hueBase = random(360);
    hueVariation = random(20, 40);
  }
  
  Genome mutate(float mutationRate) {
    Genome offspring = this.copy();
    
    if (random(1) < mutationRate) offspring.branchingProbability += random(-0.1, 0.1);
    if (random(1) < mutationRate) offspring.branchAngle += random(-PI/12, PI/12);
    if (random(1) < mutationRate) offspring.maxBranchDepth += int(random(-1, 2));
    if (random(1) < mutationRate) offspring.filamentLength += random(-3, 3);
    if (random(1) < mutationRate) offspring.filamentDensity += random(-0.15, 0.15);
    
    if (random(1) < mutationRate) offspring.energyEfficiency += random(-0.2, 0.2);
    if (random(1) < mutationRate) offspring.reproductionThreshold += random(-20, 20);
    
    if (random(1) < mutationRate) offspring.hueBase += random(-30, 30);
    
    // Constrain to valid ranges
    offspring.branchingProbability = constrain(offspring.branchingProbability, 0.1, 0.9);
    offspring.branchAngle = constrain(offspring.branchAngle, PI/8, PI/2);
    offspring.maxBranchDepth = constrain(offspring.maxBranchDepth, 1, 6);
    offspring.filamentLength = constrain(offspring.filamentLength, 5, 30);
    offspring.filamentDensity = constrain(offspring.filamentDensity, 0.1, 1.0);
    offspring.energyEfficiency = constrain(offspring.energyEfficiency, 0.5, 1.5);
    offspring.reproductionThreshold = constrain(offspring.reproductionThreshold, 80, 250);
    offspring.hueBase = (offspring.hueBase + 360) % 360;
    
    return offspring;
  }
  
  Genome copy() {
    Genome g = new Genome();
    g.branchingProbability = this.branchingProbability;
    g.branchAngle = this.branchAngle;
    g.maxBranchDepth = this.maxBranchDepth;
    g.filamentLength = this.filamentLength;
    g.filamentDensity = this.filamentDensity;
    g.energyEfficiency = this.energyEfficiency;
    g.reproductionThreshold = this.reproductionThreshold;
    g.hueBase = this.hueBase;
    g.hueVariation = this.hueVariation;
    return g;
  }
}

// ============================================================
// FILAMENT BRANCH - Tree structure node
// ============================================================
class FilamentBranch {
  PVector start;
  PVector end;
  float angle;
  int depth;
  FilamentBranch parent;
  ArrayList<FilamentBranch> children;
  PVector targetCell;  // Cell this branch connects to
  
  FilamentBranch(PVector start, float angle, int depth, FilamentBranch parent) {
    this.start = start;
    this.angle = angle;
    this.depth = depth;
    this.parent = parent;
    this.children = new ArrayList<FilamentBranch>();
    this.targetCell = null;
  }
}

// ============================================================
// STRUCTURAL PHENOTYPE - Growth expression from genome
// ============================================================
class StructuralPhenotype {
  ArrayList<FilamentBranch> branchNetwork;
  Genome genome;
  
  StructuralPhenotype(Genome g) {
    this.genome = g;
    this.branchNetwork = new ArrayList<FilamentBranch>();
  }
  
  void growFromCells(ArrayList<PVector> cells) {
    if (cells.size() == 0) return;
    
    branchNetwork.clear();
    
    // Find organism centroid (metabolic core)
    PVector centroid = new PVector(0, 0);
    for (PVector cell : cells) {
      centroid.add(cell);
    }
    centroid.div(cells.size());
    
    // BIOLOGICAL: Detect dominant growth axis (like spine/stem)
    PVector growthAxis = findLongestAxis(cells, centroid);
    float dominantAngle = atan2(growthAxis.y, growthAxis.x);
    
    // BIOLOGICAL: Grow branches along axis, not radially symmetric
    int numPrimaryBranches = int(cells.size() * genome.filamentDensity);
    numPrimaryBranches = constrain(numPrimaryBranches, 2, 8);
    
    for (int i = 0; i < numPrimaryBranches; i++) {
      // Cluster branches around dominant axis (like ribs from spine)
      float angleVariation = map(i, 0, numPrimaryBranches - 1, -PI/3, PI/3);
      float angle = dominantAngle + angleVariation + random(-0.3, 0.3);  // Add organic noise
      
      // Offset start point along axis (not all from centroid)
      float axisPosition = map(i, 0, numPrimaryBranches - 1, -0.5, 0.5);
      PVector start = PVector.add(centroid, PVector.mult(growthAxis, axisPosition));
      
      FilamentBranch primary = new FilamentBranch(start, angle, 0, null);
      growBranch(primary, cells);
      branchNetwork.add(primary);
    }
  }
  
  // Helper: Find longest dimension of organism (defines growth direction)
  PVector findLongestAxis(ArrayList<PVector> cells, PVector center) {
    float maxDist = 0;
    PVector farthestCell = cells.get(0);
    
    for (PVector cell : cells) {
      float d = PVector.dist(cell, center);
      if (d > maxDist) {
        maxDist = d;
        farthestCell = cell;
      }
    }
    
    PVector axis = PVector.sub(farthestCell, center);
    if (axis.mag() > 0) axis.normalize();
    return axis;
  }
  
  void growBranch(FilamentBranch branch, ArrayList<PVector> cells) {
    // Recursive branching with biological variation
    float segmentLength = genome.filamentLength / cellSize;
    PVector direction = PVector.fromAngle(branch.angle);
    direction.mult(segmentLength);
    
    PVector endPoint = PVector.add(branch.start, direction);
    branch.end = endPoint;
    
    // BIOLOGICAL: Prioritize connecting to high-energy cells (organs/cores)
    PVector bestCell = null;
    float bestScore = -1;
    
    for (PVector cell : cells) {
      float dist = PVector.dist(endPoint, cell);
      if (dist < 3.0) {  // Within connection range
        int cx = int(cell.x);
        int cy = int(cell.y);
        float energy = cellEnergy[cx][cy];
        
        // Score: prefer high-energy cells (organs), penalize distance
        float score = energy / (dist + 1);
        if (score > bestScore) {
          bestScore = score;
          bestCell = cell;
        }
      }
    }
    
    if (bestCell != null) {
      branch.targetCell = bestCell;
    }
    
    // BIOLOGICAL: Variable branching (1-4 children, not always 2)
    if (branch.depth < genome.maxBranchDepth && random(1) < genome.branchingProbability) {
      int numChildren = int(random(1, 4));  // 1-3 branches (biological variation)
      
      for (int i = 0; i < numChildren; i++) {
        float angleOffset;
        if (numChildren == 1) {
          angleOffset = random(-0.2, 0.2);  // Slight wobble
        } else {
          // Spread children around parent angle
          angleOffset = map(i, 0, numChildren - 1, -genome.branchAngle, genome.branchAngle);
          angleOffset += random(-0.3, 0.3);  // Add organic noise
        }
        
        float childAngle = branch.angle + angleOffset;
        FilamentBranch child = new FilamentBranch(endPoint.copy(), childAngle, branch.depth + 1, branch);
        growBranch(child, cells);
        branch.children.add(child);
      }
    }
  }
  
  void display(float life, float hueBase) {
    pushStyle();
    blendMode(ADD);
    
    for (FilamentBranch branch : branchNetwork) {
      displayBranch(branch, life, hueBase);
    }
    
    popStyle();
  }
  
  void displayBranch(FilamentBranch branch, float life, float hueBase) {
    if (branch.end == null) return;
    
    // Visual style based on depth (thicker at base, thinner at tips)
    float depthFactor = 1.0 - (branch.depth / float(genome.maxBranchDepth));
    
    float hue = hueBase + random(-genome.hueVariation, genome.hueVariation);
    float sat = 70 + 30 * depthFactor;
    float bri = 50 + 40 * life * depthFactor;
    float alpha = 40 + 80 * life * depthFactor;
    
    stroke(hue, sat, bri, alpha);
    strokeWeight(0.8 + 2.5 * depthFactor * life);
    
    // BIOLOGICAL: Use curved Bezier lines instead of straight lines
    PVector start = branch.start;
    PVector end = branch.end;
    
    // Calculate control point for curve (perpendicular to branch direction)
    PVector mid = PVector.lerp(start, end, 0.5);
    PVector perpendicular = PVector.sub(end, start);
    perpendicular.rotate(HALF_PI);
    perpendicular.normalize();
    perpendicular.mult(PVector.dist(start, end) * 0.2);  // Curve intensity
    PVector control = PVector.add(mid, perpendicular);
    
    // Draw curved line
    noFill();
    beginShape();
    vertex(start.x * cellSize, start.y * cellSize);
    quadraticVertex(control.x * cellSize, control.y * cellSize,
                    end.x * cellSize, end.y * cellSize);
    endShape();
    
    // Draw connection to target cell (also curved with organic wobble)
    if (branch.targetCell != null) {
      stroke(hue, sat * 0.5, bri * 1.3, alpha * 0.6);
      strokeWeight(1.0 * life);
      
      PVector target = branch.targetCell;
      PVector controlTarget = PVector.lerp(end, target, 0.5);
      controlTarget.add(random(-1, 1), random(-1, 1));  // Organic wobble
      
      noFill();
      beginShape();
      vertex(end.x * cellSize, end.y * cellSize);
      quadraticVertex(controlTarget.x * cellSize, controlTarget.y * cellSize,
                      target.x * cellSize, target.y * cellSize);
      endShape();
    }
    
    // Recurse to children
    for (FilamentBranch child : branch.children) {
      displayBranch(child, life, hueBase);
    }
  }
  
  int countConnectionsToCell(PVector cell) {
    int count = 0;
    for (FilamentBranch branch : branchNetwork) {
      count += countConnectionsRecursive(branch, cell);
    }
    return count;
  }
  
  int countConnectionsRecursive(FilamentBranch branch, PVector cell) {
    int count = 0;
    if (branch.targetCell != null && PVector.dist(branch.targetCell, cell) < 0.1) {
      count = 1;
    }
    for (FilamentBranch child : branch.children) {
      count += countConnectionsRecursive(child, cell);
    }
    return count;
  }
}
