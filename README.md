# LC-3 Wordle Game

This is a simplified **Wordle-style word guessing game** implemented in **LC-3 Assembly language**. The user has 6 attempts to guess a 5-letter secret word. After each guess, the program provides feedback using the classic Wordle color indicators:

- **G** for Green: correct letter in the correct position
- **Y** for Yellow: correct letter in the wrong position
- **B** for Black: incorrect letter (not in the word)

---

## 🔗 Simulator Link


**LC3web** (browser-based, no install):

👉 [https://lc3tutor.org]([https://lc3tutor.org](https://wchargin.com/lc3web/))

---

## 📋 Program Requirements

- **LC-3 Simulator**: The program must be assembled and run in a simulator that supports the `.STRINGZ`, `.BLKW`, and standard TRAP routines (`GETC`, `OUT`, `PUTS`, etc.).
- **Text-based Input**: Enter your guess using lowercase or uppercase letters. The program converts lowercase letters to uppercase automatically.
- **Display**: Since the program runs in a console environment, no special graphics resolution is required — just make sure the console window is large enough to view multiline text output.

---

## 💡 Features

- Converts lowercase input to uppercase
- Detects exact (green), partial (yellow), and wrong (black) letter matches
- Tracks number of guesses
- Outputs win/loss message after the game ends
- You can **easily change the secret word** by modifying the `SECRET` line in the data section:
  SECRET .STRINGZ "HELLO"  ; change "HELLO" to your desired word
