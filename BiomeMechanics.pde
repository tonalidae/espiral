// ============================================================
// BIOMEMECHANICS.PDE
// Damage, healing, and adhesion systems for biome behavior
// ============================================================

void updateBiomeDamageAndHealing() {
  for (int x = 0; x < cols; x++) {
    for (int y = 0; y < rows; y++) {
      float currentScar = cellScar[x][y];
      float drain = energyDrainTracker[x][y];
      
      // DAMAGE: Aggressive energy transfer causes scarring
      if (drain > DAMAGE_THRESHOLD) {
        float damageAmount = SCAR_RATE * ((drain - DAMAGE_THRESHOLD) / DAMAGE_THRESHOLD);
        cellScar[x][y] = min(1.0, currentScar + damageAmount);
      }
      
      // HEALING: Healthy neighbors help repair scars
      if (currentScar > 0) {
        float neighborScarAvg = 0;
        int count = 0;
        for (int dx = -1; dx <= 1; dx++) {
          for (int dy = -1; dy <= 1; dy++) {
            if (dx == 0 && dy == 0) continue;
            int nx = (x + dx + cols) % cols;
            int ny = (y + dy + rows) % rows;
            neighborScarAvg += cellScar[nx][ny];
            count++;
          }
        }
        neighborScarAvg /= count;
        
        // Heal faster when surrounded by healthy neighbors
        if (neighborScarAvg < currentScar) {
          float healAmount = HEAL_RATE * (1.0 + (1.0 - neighborScarAvg));
          cellScar[x][y] = max(0, currentScar - healAmount);
        }
      }
      
      // Reset drain tracker
      energyDrainTracker[x][y] = 0;
    }
  }
}
