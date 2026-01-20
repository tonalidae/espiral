// ============================================================
// SPIRALS.PDE
// Ola spiral generation and Punto data structures
// ============================================================

class Punto {
  float x, y;
  float hue, sat, bri;
  
  Punto(float x_, float y_, float hue_, float sat_, float bri_) {
    x = x_;
    y = y_;
    hue = hue_;
    sat = sat_;
    bri = bri_;
  }
}

class Ola {
  float x, y;
  int radio;
  float baseHue1, baseHue2;
  char[] ring;
  HashMap<String, Character> rules;
  char[] characters;
  int puntosPorAnillo = 200;
  float petals;
  float goldenAngle;
  float goldenVariation;
  
  Ola(float x_, float y_) {
    x = x_;
    y = y_;
    
    if (random(1) > 0.5) {
      int col1 = blueNebula[int(random(blueNebula.length))];
      int col2 = blueNebula[int(random(blueNebula.length))];
      baseHue1 = getHueFromHex(col1);
      baseHue2 = getHueFromHex(col2);
    } else {
      int col1 = greenNebula[int(random(greenNebula.length))];
      int col2 = greenNebula[int(random(greenNebula.length))];
      baseHue1 = getHueFromHex(col1);
      baseHue2 = getHueFromHex(col2);
    }
    
    goldenVariation = random(0.85, 1.15);
    goldenAngle = radians(137.50776 * goldenVariation);
    radio = 0;

    characters = new char[states];
    for (int i = 0; i < states; i++) characters[i] = (char)(i + 48);

    ring = new char[puntosPorAnillo];
    for (int i = 0; i < puntosPorAnillo; i++) ring[i] = characters[int(random(states))];

    rules = new HashMap<String, Character>();
    generateRules("", vecindad * 2 + 1);
    petals = random(3, 40);
  }

  void display() {
    float animatedAngle = goldenAngle + 0.05 * sin(millis() * 0.0003);

    for (int i = 0; i < puntosPorAnillo; i++) {
      float angS = i * animatedAngle;
      float angP = map(i, 0, puntosPorAnillo, 0, TWO_PI);
      float spiralOffset = i * cellSize * 0.03 * goldenVariation;
      float r = radio + spiralOffset;

      float px = x + cos(angS) * r;
      float py = y + sin(angS) * r;

      float g = growthConstraint(angP, r, petals);
      if (random(2) > g) continue;

      boolean branchA = (i % 2 == 0);
      float hue = branchA ? baseHue1 : baseHue2;
      float sat = 100;
      float bri = branchA ? 100 : 70;

      float h = lerp(0, hue, interaction);
      float s = lerp(0, sat * 0.6, interaction);

      float profundidad = map(r, 0, width, 1.0, 0.3) * globalDeep;
      float z = sin((r + i) * 0.05 + millis() * 0.002) * 5;
      float baseSize = cellSize * profundidad * 8 + z * 0.4;

      fill(h, s * 0.3, bri * 0.4, 3);
      ellipse(px, py, baseSize * 4, baseSize * 4);
      
      fill(h, s * 0.5, bri * 0.6, 8);
      ellipse(px, py, baseSize * 2.5, baseSize * 2.5);
      
      fill(h, s * 0.8, bri * 0.9, 20);
      ellipse(px, py, baseSize * 1.5, baseSize * 1.5);
      
      fill(h, s, bri, 60);
      ellipse(px, py, baseSize, baseSize);
      
      if (random(1) > 0.7) {
        int sparkleCol = sparkles[int(random(sparkles.length))];
        fill(getHueFromHex(sparkleCol), getSatFromHex(sparkleCol) * interaction, 100, 120);
        ellipse(px, py, baseSize * 0.4, baseSize * 0.4);
      }

      puntosGlobales.add(new Punto(px, py, hue, sat, bri));
    }
  }

  void update() {
    char[] newr = new char[puntosPorAnillo];
    StringBuilder sb = new StringBuilder(vecindad * 2 + 1);
    
    for (int i = 0; i < puntosPorAnillo; i++) {
      sb.setLength(0);
      for (int dx = -vecindad; dx <= vecindad; dx++) {
        int idx = (i + dx + puntosPorAnillo) % puntosPorAnillo;
        sb.append(ring[idx]);
      }
      newr[i] = rules.get(sb.toString());
    }
    arrayCopy(newr, ring);
    radio += cellSize;
  }

  void generateRules(String str, int l) {
    if (l == 0) {
      rules.put(str, characters[int(random(states))]);
      return;
    }
    for (char c : characters) generateRules(str + c, l - 1);
  }
}

float growthConstraint(float ang, float r, float petals) {
  float petalShape = pow(abs(cos(ang * petals * 0.5)), 1.5);
  float radialDrop = exp(-pow(r / (width * 0.9), 3.0));
  float nx = cos(ang) * r / width;
  float ny = sin(ang) * r / height;
  float noiseField = noise(nx * 3.0, ny * 3.0, millis() * 0.00005);
  return petalShape * radialDrop * (0.8 + 0.2 * noiseField);
}
