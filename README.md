# asm-galacta

## Description

This was probably my favorite Computer Science project in college, and I have been wanting to revisit it for a while.

It is a simple game written in MIPS Assembly Language. The player controls a spaceship that can move left and right, and shoot bullets at the enemies. It is loosely based on the classic arcade game Galaga, the player must destroy all the enemies to win the game.

![Main Screen](./docs/00-gameplay.gif)

## Additional Features

- Welcome screen with animated rainbow border
- Game over screen
- HUD with ammo, score, and lives
- Explosion animations when an enemy is destroyed

## Running the game

### Prerequisites

- Java 8+ (I used [Liberica JDK 21 LTS](https://bell-sw.com/pages/downloads/#jdk-21-lts))
- Clone this repository:

```
git clone https://github.com/zpg6/asm-galacta.git
```

<br>

### 1. Open the JAR for the MIPS Simulator (`tools/Mars.jar`) and open the `src/game.asm` file.
<br>

![Open Game](./docs/01-open-game.png)
<br><br><br>

### 2. Be sure to select "Assemble All Files" in the Settings menu.
<br>

![Assemble All Files](./docs/02-assemble-all-files.png)
<br><br><br>

### 3. Click the "Assemble" button and then the "Run" button.
<br>

![Assemble](./docs/03-assemble.png)
<br><br><br>
![Run](./docs/04-run.png)
<br><br><br>

### 4. Open the simulator and click the "Connect to MIPS" button.
<br>

![Open Simulator](./docs/05-open-simulator.png)
<br><br><br>
![Main Screen](./docs/06-main-screen.png)
<br><br><br>
