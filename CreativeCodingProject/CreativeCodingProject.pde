// FPL Creative Coding Sketch - FINAL FIX
// Fixes: Remove GW0s, better spacing, force rank variation visibility

Table table;

// Chart dimensions
float x_margin = 120;  
float y_margin = 60;
int max_points = 100; 
int num_gameweeks;   

int highest_rank;
int lowest_rank;

float rank_line_y_top;
float rank_line_y_bottom;
float ground_y; 

ArrayList<Integer> validRows = new ArrayList<Integer>();

void setup() {
  size(1200, 700);
  smooth();
  
  table = loadTable("FPLDataTrackingSheet.csv", "header"); 
  
  // Filter out invalid rows (GW0 or missing data)
  for (int i = 0; i < table.getRowCount(); i++) {
    TableRow row = table.getRow(i);
    int gameweek = row.getInt("Gameweek");
    int pointsEarned = row.getInt("PointsEarned");
    
    // Only include rows with valid gameweek (not 0) and points
    if (gameweek > 0 && pointsEarned >= 0) {
      validRows.add(i);
    }
  }
  
  num_gameweeks = validRows.size();
  println("Valid gameweeks found: " + num_gameweeks);
  
  // Find actual rank range from VALID data only
  highest_rank = Integer.MAX_VALUE;
  lowest_rank = 0;
  boolean hasValidRanks = false;
  
  for (int i : validRows) {
    TableRow row = table.getRow(i);
    int current_rank = row.getInt("OverallRank");
    println("GW" + row.getInt("Gameweek") + " - Points: " + row.getInt("PointsEarned") + " - Rank: " + current_rank);
    
    if (current_rank > 0) {  // Only count valid ranks
      hasValidRanks = true;
      if (current_rank < highest_rank) highest_rank = current_rank;
      if (current_rank > lowest_rank) lowest_rank = current_rank;
    }
  }
  
  // If no valid ranks found, use dummy values to prevent errors
  if (!hasValidRanks) {
    println("\n⚠️ WARNING: No valid rank data found (all ranks are 0)!");
    println("Please add actual rank numbers to the 'OverallRank' column in your CSV.");
    println("Using placeholder values - rank line will not be meaningful.\n");
    highest_rank = 1;
    lowest_rank = 1000000;
  }
  
  println("\nRank range: " + highest_rank + " (best) to " + lowest_rank + " (worst)");
  
  // Smart padding to make variations visible
  int range = lowest_rank - highest_rank;
  
  if (range == 0) {
    // All ranks are the same - add artificial range
    println("Warning: All ranks are identical!");
    highest_rank = max(1, highest_rank - 5000);
    lowest_rank = lowest_rank + 5000;
  } else if (range < 5000) {
    // Small range - add significant padding
    highest_rank = max(1, highest_rank - range);
    lowest_rank = lowest_rank + range;
  } else {
    // Normal range - add 20% padding
    int padding = range / 5;
    highest_rank = max(1, highest_rank - padding);
    lowest_rank = lowest_rank + padding;
  }
  
  println("Adjusted range for visibility: " + highest_rank + " to " + lowest_rank);
  println("This creates a " + (lowest_rank - highest_rank) + " rank spread\n");
  
  // Define chart coordinates
  ground_y = height - y_margin - 30;
  rank_line_y_top = y_margin + 80;
  rank_line_y_bottom = y_margin + 200;

  textSize(14);
  textAlign(CENTER, CENTER);
  colorMode(RGB, 255);
  noLoop();
}

void draw() {
  background(245); 
  
  // Title
  fill(40);
  textAlign(CENTER, TOP);
  textSize(28);
  text("FPL Performance: The Manager's Forest", width/2, 20);
  
  // Draw Legend first (so it's in background)
  drawLegend();
  
  // Ground/X-Axis 
  fill(220, 220, 210);
  noStroke();
  rect(x_margin, ground_y, width - 2 * x_margin, 40);
  
  stroke(160);
  strokeWeight(2);
  line(x_margin, ground_y, width - x_margin, ground_y); 
  
  // Calculate spacing - MORE space between trees, stop before legend
  float legendStartX = width - 300;
  float usable_width = legendStartX - x_margin - 40;  // Extra margin before legend
  float step_size = usable_width / num_gameweeks;
  
  println("Step size between trees: " + step_size + "px");
  
  // Draw gridlines first
  stroke(220);
  strokeWeight(1);
  for(int i = 0; i < num_gameweeks; i++){
    float treeX = x_margin + (i + 0.5) * step_size;
    line(treeX, ground_y, treeX, rank_line_y_bottom + 20);
  }
  
  // Draw Rank Trend Line
  colorMode(RGB, 255);
  noFill();
  stroke(50, 100, 200); 
  strokeWeight(3); 
  
  beginShape();
  for(int i = 0; i < num_gameweeks; i++){
    int rowIndex = validRows.get(i);
    TableRow row = table.getRow(rowIndex);
    int overallRank = row.getInt("OverallRank");
    
    // If rank is 0 (missing), skip drawing this point
    if (overallRank == 0) continue;
    
    float rankX = x_margin + (i + 0.5) * step_size;
    float rankY = map(overallRank, highest_rank, lowest_rank, rank_line_y_top, rank_line_y_bottom);
    
    println("GW" + row.getInt("Gameweek") + " plotting at Y=" + rankY + " (rank=" + overallRank + ")");
    
    vertex(rankX, rankY);
  }
  endShape();
  
  // Draw rank points
  fill(50, 100, 200);
  noStroke();
  for(int i = 0; i < num_gameweeks; i++){
    int rowIndex = validRows.get(i);
    TableRow row = table.getRow(rowIndex);
    int overallRank = row.getInt("OverallRank");
    
    // If rank is 0 (missing), skip drawing this point
    if (overallRank == 0) continue;
    
    float rankX = x_margin + (i + 0.5) * step_size;
    float rankY = map(overallRank, highest_rank, lowest_rank, rank_line_y_top, rank_line_y_bottom);
    
    ellipse(rankX, rankY, 7, 7);
  }
  
  // Y-Axis Labels for Rank
  fill(40);
  textAlign(RIGHT, CENTER);
  textSize(13);
  text("Overall Rank", x_margin - 20, rank_line_y_top - 25); 
  
  textSize(11);
  text("Best", x_margin - 20, rank_line_y_top);
  text(nfc(highest_rank), x_margin - 20, rank_line_y_top + 15);
  
  // Middle label
  int midRank = (highest_rank + lowest_rank) / 2;
  float midY = (rank_line_y_top + rank_line_y_bottom) / 2;
  text(nfc(midRank), x_margin - 20, midY);
  
  text(nfc(lowest_rank), x_margin - 20, rank_line_y_bottom - 15);
  text("Worst", x_margin - 20, rank_line_y_bottom);
  
  // Draw the Forest - ONLY VALID DATA
  colorMode(HSB, 255);
  
  for(int i = 0; i < num_gameweeks; i++){
    int rowIndex = validRows.get(i);
    TableRow row = table.getRow(rowIndex);
    
    int gameweek = row.getInt("Gameweek");
    int pointsEarned = row.getInt("PointsEarned");
    int transfersMade = row.getInt("TransfersMade");
    int emotionRating = row.getInt("EmotionRating");
    int benchWasted = row.getInt("BenchPointsWasted");
    
    float treeX = x_margin + (i + 0.5) * step_size;
    
    float trunkHeight = map(pointsEarned, 0, max_points, 20, 280);
    float trunkWidth = 10 + transfersMade * 2.5;  // Slightly wider variation
    
    float canopyHue = map(emotionRating, 1, 5, 0, 120); 
    float canopySat = map(emotionRating, 1, 5, 180, 255); 
    float canopySize = map(emotionRating, 1, 5, 35, 70);
    
    // Draw trunk
    fill(30, 120, 100); 
    noStroke();
    rectMode(CENTER);
    rect(treeX, ground_y - (trunkHeight / 2), trunkWidth, trunkHeight);
    
    // Draw canopy
    fill(canopyHue, canopySat, 200); 
    noStroke();
    ellipse(treeX, ground_y - trunkHeight, canopySize, canopySize * 1.3);
    
    // Points label on canopy
    colorMode(RGB, 255);
    fill(255); 
    textSize(12); 
    textAlign(CENTER, CENTER);
    text(pointsEarned, treeX, ground_y - trunkHeight);
    colorMode(HSB, 255);
    
    // Fallen fruit - MORE VISIBLE
    if (benchWasted > 0) {
      colorMode(RGB, 255);
      fill(180, 100, 120);  // More visible pink/red color
      noStroke();
      int num_fruit = min(8, benchWasted / 2 + 2);  // More fruit
      for (int j = 0; j < num_fruit; j++) { 
        ellipse(treeX + random(-22, 22), ground_y + random(5, 18), 6, 6);  // Larger, wider spread
      }
      colorMode(HSB, 255); 
    }
    
    // Gameweek label
    colorMode(RGB, 255);
    fill(60);
    textAlign(CENTER, TOP);
    textSize(13);
    text("GW" + gameweek, treeX, ground_y + 10);
    colorMode(HSB, 255);
  }
  
  colorMode(RGB, 255);
}

void drawLegend() {
  float legendX = width - 280;
  float legendY = rank_line_y_top - 30;
  
  colorMode(RGB, 255);
  
  // Legend box
  fill(255, 250);
  stroke(140);
  strokeWeight(1.5);
  rect(legendX - 15, legendY - 15, 260, 280, 5); 
  
  // Title
  fill(40);
  noStroke();
  textAlign(LEFT, TOP);
  textSize(20); 
  text("Legend", legendX, legendY);
  
  float lineHeight = 28; 
  float y = legendY + 35;
  textSize(13);
  
  // Trunk Height
  fill(70);
  text("Trunk Height:", legendX, y);
  fill(20);
  text("Points Earned", legendX + 95, y);
  y += lineHeight;
  
  // Trunk Width
  fill(70);
  text("Trunk Width:", legendX, y);
  fill(20);
  text("Transfers Made", legendX + 95, y);
  y += lineHeight;
  
  // Canopy Color
  fill(70);
  text("Canopy Color:", legendX, y);
  fill(20);
  text("Emotion (1-5)", legendX + 95, y);
  
  // Color gradient
  colorMode(HSB, 255);
  y += lineHeight - 5;
  float colorBoxSize = 22; 
  noStroke();
  for (int i = 0; i < 5; i++) {
    float hue = map(i + 1, 1, 5, 0, 120);
    fill(hue, 200, 200);
    rect(legendX + 95 + (i * colorBoxSize), y, colorBoxSize, colorBoxSize);
  }
  
  colorMode(RGB, 255);
  fill(60);
  textSize(10);
  textAlign(LEFT, TOP);
  text("Bad", legendX + 95, y + colorBoxSize + 3);
  textAlign(RIGHT, TOP);
  text("Great", legendX + 95 + (5 * colorBoxSize), y + colorBoxSize + 3);
  
  y += lineHeight * 2.2;
  
  // Fallen Fruit - UPDATED COLOR
  textAlign(LEFT, TOP);
  textSize(13);
  fill(70);
  text("Fallen Fruit:", legendX, y);
  fill(180, 100, 120);  // Match new fruit color
  noStroke();
  ellipse(legendX + 100, y + 8, 9, 9);
  fill(20);
  text("Bench Points", legendX + 110, y);
  y += lineHeight;
  
  // Rank Line
  stroke(50, 100, 200);
  strokeWeight(3);
  line(legendX, y + 8, legendX + 80, y + 8);
  fill(50, 100, 200);
  noStroke();
  ellipse(legendX + 40, y + 8, 7, 7);
  fill(20);
  textAlign(LEFT, TOP);
  text("Rank Trend", legendX + 95, y);
  
  colorMode(RGB, 255);
}
