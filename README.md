# **PROJECT REPORT**

**Project Title:** Rapid Roll (Ping Ball)  
**Course:** Computer Organization Assembly Language Lab (COAL)  
**Course Instructor:** Mr. Waseem Rauf

**PROJECT MEMBERS:**  
- MUHAMMAD OWAIS RAFIQ (23K-2042)  
- ABUBAKAR BIN HASSAN (23K-2025)

---

## **INTRODUCTION**

The **Rapid Roll** project is a console-based game implemented entirely in assembly language. It showcases core concepts of low-level programming by simulating a simple yet engaging game. Players control a ball to avoid falling off randomly generated platforms. The project integrates multi-threading, user input handling, and custom screen management to deliver smooth gameplay.

This project serves as a bridge between theoretical concepts of assembly language and practical application, emphasizing real-time systems and efficient use of resources.

---

## **Features Implemented**

1. **Dynamic Platform Generation:** Platforms are randomly generated with varying lengths and positions for each game iteration, ensuring unique gameplay.
2. **Multi-Threading:** Separate threads handle platform movement and user-controlled ball movement, utilizing Windows API for thread management and synchronization.
3. **Screen Management:** Independent screens for the ball and platforms eliminate screen flickering and improve user experience.
4. **Real-Time User Input:** Continuous monitoring of keyboard input allows players to move the ball left or right instantly.
5. **Score Management:** A scoring mechanism calculates the time survived during the game. High scores are saved to and retrieved from a file (**score.txt**).
6. **Collision Detection:** The game identifies when the ball interacts with a platform or falls, enforcing gameplay rules and triggering game-over conditions.
7. **Thread Synchronization:** Precise synchronization ensures smooth interaction between the ball's movement and the platforms' dynamics.

---

## **Development Workflow**

### **3.1 Initialization**

- The console was configured for game screens and cursor management using `GetStdHandle` and `SetConsoleCursorInfo`.
- Initial values for the ball's position, platform configurations, and threading were established.

### **3.2 Game Loop**

- The loop handled:
    - Platform movement.
    - Real-time user input to control the ball.
    - Continuous updates to the game screen.

### **3.3 Platform Management**

- A dedicated thread (`PlatformFn`) moved platforms upwards and cleared those reaching the top.
- Platforms were dynamically regenerated at random lengths and positions.

### **3.4 Ball Movement**

- Another thread (`BallFn`) processed ball movement based on keyboard inputs.
- Collision detection was implemented to adjust the ball's position and determine game-over conditions.

### **3.5 Score Calculation**

- Scores were derived from the time elapsed since the start of the game.
- High scores were saved and compared using file I/O operations.

---

## **Libraries and Technologies Used**

### **4.1 Windows API**

- **CreateScreen, DeleteScreen:** Screen management.
- **ResumeThread, ExitThread:** Multi-threading.
- **ReadConsoleOutputCharacter:** Real-time input handling.
- **Sleep:** Controlling thread execution timing.

### **4.2 Assembly Language Techniques**

- **Memory Management:** Efficient data structures (e.g., `PLATFORM`, `BALL`) to minimize resource usage.
- **Thread Synchronization:** Ensured coordinated movement of the ball and platforms.
- **Console Graphics:** Simplistic yet effective ASCII-based visuals for real-time gameplay.

---

## **Key Challenges and Solutions**

### **1. Real-Time Interaction:**
- **Challenge:** Handling simultaneous movements without lag.
- **Solution:** Implemented multi-threading for ball and platform updates, synchronized using Windows API.

### **2. Screen Flickering:**
- **Challenge:** Preventing visual glitches during screen refreshes.
- **Solution:** Created separate screen buffers for the ball and platforms.

### **3. Collision Detection:**
- **Challenge:** Detecting interactions between ball and platforms.
- **Solution:** Used coordinate comparisons and ASCII checks with `ReadConsoleOutputCharacter`.

### **4. Randomization of Platforms:**
- **Challenge:** Ensuring non-repetitive gameplay.
- **Solution:** Utilized random number generation (`RandomRange`) for platform length and position.

---

## **Gameplay Screenshots**

*Screenshots demonstrating the gameplay:*

- Initial gameplay with the ball positioned on a platform.
- Dynamic movement of platforms as the game progresses.
- Game-over screen displaying the player's score and high score.

![Gameplay Screenshot 1](vertopal_2d48e912267a4efc826c9e3c83f7bc15/media/image2.png){width="6.5in" height="2.95in"}
![Gameplay Screenshot 2](vertopal_2d48e912267a4efc826c9e3c83f7bc15/media/image3.png){width="6.5in" height="3.24in"}

---

## **Lessons Learned**

- **Multi-Threading:** Gained hands-on experience with managing concurrent processes in assembly language.
- **Low-Level Input Handling:** Explored efficient mechanisms for real-time keyboard input processing.
- **Resource Optimization:** Learned to manage screen buffers and memory effectively for real-time applications.

---

## **Conclusion**

The **Rapid Roll** project successfully achieved its goals of creating an engaging console-based game while demonstrating the power and intricacies of assembly language. By integrating multi-threading, dynamic platform generation, and real-time input, the game exemplifies how low-level programming concepts translate into interactive systems.

This project not only serves as a learning experience but also highlights assembly language's relevance in developing real-time systems and gaming applications.

Future enhancements could include additional features like difficulty levels, improved graphics, or networked multiplayer support.

---

## **References**

1. COAL Course Materials and Lectures
2. Windows API Documentation
3. **Project Proposal** – Rapid Roll

---

## **⚙️ How to Run Locally**

To run the game on your local machine, follow these steps:

1. **Clone the Repository:**
   Clone the project to your local machine using Git.
   ```bash
   git clone https://github.com/owaisrafiq05/Rapid-Roll-MASM.git

2. **Set Up MASM32 and Irvine Libraries:**

Go to the Includes.inc file located in the include/ directory and update the paths according to where MASM32 and Irvine libraries are installed on your system.
Example of what you might need to update in Includes.inc:

; Example path update for MASM32
MASM32_PATH = "C:\\path\\to\\masm32\\"

; Example path update for Irvine Library
IRVINE_PATH = "C:\\path\\to\\irvine\\"



Similarly, in the run.bat file, change the path to MASM32 in line 3 and the path to your cloned project in line 4.
Example of what you might need to update in run.bat:

REM Update MASM32 path (line 3)
SET MASM32=C:\path\to\masm32

REM Update project directory path (line 4)
SET PROJECT_DIR=C:\path\to\your\cloned\project

2. **Build and Run:**
 
Once the paths are set up, execute the following command in your command line terminal to build and run the game:
 ```bash
./run.bat main.ASM
