// ============================================================
// ORGANISMS.PDE
// Organism detection, tracking, and rendering
// ============================================================

void detectOrganisms() {
  for (Organism org : organisms) {
    org.matchedThisDetection = false;
  }
  
  boolean[][] visited = new boolean[cols][rows];
  final float MATCH_THRESHOLD = 25.0;
  
  for (int x = 0; x < cols; x++) {
    for (int y = 0; y < rows; y++) {
      if (!visited[x][y] && cellEnergy[x][y] >= ORGANISM_DETECTION_ENERGY) {
        ArrayList<PVector> cluster = new ArrayList<PVector>();
        floodFill(x, y, visited, cluster);
        
        if (cluster.size() >= MIN_ORGANISM_SIZE) {
          float sumX = 0, sumY = 0, sumEnergy = 0;
          for (PVector cell : cluster) {
            int cx = int(cell.x);
            int cy = int(cell.y);
            float energy = cellEnergy[cx][cy];
            sumX += cx * energy;
            sumY += cy * energy;
            sumEnergy += energy;
          }
          PVector clusterCenter = new PVector(sumX / sumEnergy, sumY / sumEnergy);
          
          Organism bestMatch = null;
          float bestDist = MATCH_THRESHOLD;
          for (Organism org : organisms) {
            if (org.matchedThisDetection) continue;
            if (org.centerOfMass == null) continue;
            
            float dx = abs(org.centerOfMass.x - clusterCenter.x);
            float dy = abs(org.centerOfMass.y - clusterCenter.y);
            if (dx > cols / 2) dx = cols - dx;
            if (dy > rows / 2) dy = rows - dy;
            float dist = sqrt(dx * dx + dy * dy);
            
            if (dist < bestDist) {
              bestDist = dist;
              bestMatch = org;
            }
          }
          
          if (bestMatch != null) {
            bestMatch.cells = cluster;
            bestMatch.matchedThisDetection = true;
            bestMatch.lastSeenFrame = frameCount;
            bestMatch.displayAlpha = min(255, bestMatch.displayAlpha + 40);
            bestMatch.update();
          } else {
            Organism newOrg = new Organism(organismIDCounter++);
            newOrg.cells = cluster;
            newOrg.matchedThisDetection = true;
            newOrg.lastSeenFrame = frameCount;
            newOrg.displayAlpha = 255;
            newOrg.update();
            organisms.add(newOrg);
          }
        }
      }
    }
  }
  
  for (int i = organisms.size() - 1; i >= 0; i--) {
    Organism org = organisms.get(i);
    if (!org.matchedThisDetection) {
      org.displayAlpha -= 6;
      org.displayAlpha = max(0, org.displayAlpha);
    }
    
    if (org.displayAlpha <= 0 || (frameCount - org.lastSeenFrame) > 240) {
      organisms.remove(i);
    }
  }
}

void floodFill(int x, int y, boolean[][] visited, ArrayList<PVector> cluster) {
  // Iterative flood fill using stack to prevent stack overflow
  ArrayList<int[]> stack = new ArrayList<int[]>();
  stack.add(new int[]{x, y});
  
  while (stack.size() > 0 && cluster.size() < 200) {
    int[] current = stack.remove(stack.size() - 1);
    int cx = current[0];
    int cy = current[1];
    
    if (visited[cx][cy]) continue;
    if (cellEnergy[cx][cy] < ORGANISM_DETECTION_ENERGY) continue;
    
    visited[cx][cy] = true;
    cluster.add(new PVector(cx, cy));
    
    // Add neighbors to stack
    for (int dx = -1; dx <= 1; dx++) {
      for (int dy = -1; dy <= 1; dy++) {
        if (dx == 0 && dy == 0) continue;
        int nx = (cx + dx + cols) % cols;
        int ny = (cy + dy + rows) % rows;
        if (!visited[nx][ny] && cellEnergy[nx][ny] >= ORGANISM_DETECTION_ENERGY) {
          stack.add(new int[]{nx, ny});
        }
      }
    }
  }
}
