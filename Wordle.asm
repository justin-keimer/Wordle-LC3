;*************************************************************************
; Name: Justin Keimer
; Date: 4/21/25
; Description:
; Initializes guess counter, reads up to 6 guesses,
; validates character input, converts lowercase to uppercase,
; stores each guess in GUESSBUF, calls GIVE_FEEDBACK,
; checks win condition, loops or ends the game.
; Notes: 
;
; ***MUST ENTER SECRET WORD INTO (SECRET .STRINGZ)***
; 
; Register Usage:
; R0 - used for I/O (input char, output, newline, messages)
; R1-R5 - general processing during input
; R6 - guess counter / win flag
; R7 - return address

 .ORIG x3000

        AND R6, R6, #0      ; R6 = 0
        ST R6, SAVE_COUNTER ; Save to memory

LOOP_START
        LD R6, SAVE_COUNTER
        LD R1, NEG6
        ADD R2, R6, R1
        BRzp GAME_OVER
        
        LEA R0, PROMPT
        PUTS

        LEA R4, GUESSBUF
        AND R5, R5, #0      ; index = 0

READ_CHAR_LOOP
        GETC
        OUT
        AND R1, R1, #0
        ADD R1, R0, #0

        ; Check if R1 >= 'a'
        LD R2, LOWERA
        NOT R2, R2
        ADD R2, R2, #1
        ADD R3, R1, R2
        BRn CHAR_OK

        ; Check if R1 <= 'z'
        LD R2, LOWERZ
        NOT R2, R2
        ADD R2, R2, #1
        ADD R3, R1, R2
        BRp CHAR_OK

        ; Convert to uppercase
        LD R2, NEG32
        ADD R1, R1, R2

CHAR_OK
        STR R1, R4, #0
        ADD R4, R4, #1
        ADD R5, R5, #1
        LD R7, WORDLEN      ; use R7 instead of R6
        NOT R7, R7
        ADD R7, R5, R7
        BRn READ_CHAR_LOOP

        AND R1, R1, #0
        STR R1, R4, #0       ; null-terminate

        JSR GIVE_FEEDBACK

        ADD R6, R6, #0     ; Check if R6 == 0 (no win)
        BRz CONTINUE_GAME  ; If R6 == 0, continue
        BRnzp WINNER       ; Otherwise, you win

CONTINUE_GAME
        LD R6, SAVE_COUNTER
        ADD R6, R6, #1
        ST R6, SAVE_COUNTER
        BRnzp LOOP_START

GAME_OVER
        LEA R0, ENDMSG
        PUTS
        LEA R0, REVEALMSG     ; "The word was: "
        PUTS
        LEA R0, SECRET        ; Print the secret word
        PUTS
        HALT

WINNER
        LEA R0, WINMSG
        PUTS
        HALT

    ;************************Give_Feedback*****************************
    ; Compares the player's guess (GUESSBUF) to the secret word (SECRET),
    ; prints feedback for each letter as:
    ;   G = Green (correct position),
    ;   Y = Yellow (correct letter, wrong position),
    ;   B = Black (not in word).
    ; 
    ; Sets R6 = 1 if all letters match (win condition).
    ;
    ; Also copies SECRET into SECRET_COPY to allow yellow-checking
    ; without reusing matched letters.
    ;
    ; Register Usage:
    ; R0 - character to output (G, Y, B, newline)
    ; R1 - pointer to GUESSBUF
    ; R2 - pointer to SECRET
    ; R3 - loop counter for 5 letters
    ; R4 - current guess character
    ; R5 - match count
    ; R6 - win flag (set to 1 if guess is correct)
    ; R7 - return address
    ;************************************************************** 
GIVE_FEEDBACK

        ; Copy SECRET to SECRET_COPY
        LEA R1, SECRET
        LEA R2, SECRET_COPY
        LD R3, WORDLEN
COPY_LOOP
        LDR R4, R1, #0
        STR R4, R2, #0
        ADD R1, R1, #1
        ADD R2, R2, #1
        ADD R3, R3, #-1
        BRp COPY_LOOP
        
        
        ST R7, SAVED_R7
        ST R1, SAVED_R1
        ST R2, SAVED_R2
        ST R3, SAVED_R3
        ST R4, SAVED_R4
        ST R5, SAVED_R5
        ST R6, SAVED_R6

        LEA R1, GUESSBUF
        LEA R2, SECRET
        LD R3, WORDLEN
        AND R5, R5, #0      ; match count
        AND R6, R6, #0      ; win flag

GFB_LOOP
        LDR R4, R1, #0      ; guess char
        LDR R0, R2, #0      ; secret char

                NOT R0, R0
        ADD R0, R0, #1
        ADD R0, R4, R0
        BRnp CHECK_YELLOW   ; If not green, maybe it's yellow

         ; Green match
        LD R0, GREEN
        OUT
        ADD R5, R5, #1

        ; Mark letter used in SECRET_COPY
        LEA R7, SECRET_COPY
        ADD R7, R7, R5      ; R5 is index
        ADD R7, R7, #-1     ; adjust for post-increment
        AND R4, R4, #0      ; R4 = 0
        STR R4, R7, #0      ; SECRET_COPY[i] = 0
        BR GFB_NEXT_CONTINUE

CHECK_YELLOW

        ST R4, SAVED_CHAR
        ST R3, SAVED_R3
        ST R1, SAVED_R1
        ST R2, SAVED_R2

        JSR IS_IN_SECRET

        LD R3, SAVED_R3
        LD R1, SAVED_R1
        LD R2, SAVED_R2

        ADD R0, R0, #0
        BRz NOT_FOUND

        LD R0, YELLOW
        OUT
        BR GFB_NEXT_CONTINUE

NOT_FOUND
        LD R0, BLACK
        OUT

GFB_NEXT_CONTINUE
        ADD R1, R1, #1
        ADD R2, R2, #1
        ADD R3, R3, #-1
        BRp GFB_LOOP

        LD R0, NEWLINE
        OUT

        LD R0, WORDLEN
        NOT R0, R0
        ADD R0, R0, #1
        ADD R0, R5, R0

        BRnp FEEDBACK_DONE

        AND R6, R6, #0
        ADD R6, R6, #1

FEEDBACK_DONE
        LD R1, SAVED_R1
        LD R2, SAVED_R2
        LD R3, SAVED_R3
        LD R4, SAVED_R4
        LD R5, SAVED_R5
        LD R7, SAVED_R7
        RET

    ;************************IS_IN_SECRET*****************************
    ; Checks if the guessed character (SAVED_CHAR) exists
    ; in SECRET_COPY (used to prevent double-yellow).
    ;
    ; If found, sets R0 = 1 and clears that letter in SECRET_COPY.
    ; If not found, sets R0 = 0.
    ;
    ; Register Usage
    ; R0 - result flag (1 = found, 0 = not found)
    ; R1 - pointer into SECRET_COPY
    ; R2 - guess character to search for (from SAVED_CHAR)
    ; R3 - loop counter (WORDLEN)
    ; R4 - current character from SECRET_COPY
    ; R5 - temp for comparison
    ; R7 - return address
    ;************************************************************** 
IS_IN_SECRET
        ST R7, SAVED_R7_SEC
        ST R1, SAVED_R1_SEC
        ST R2, SAVED_R2_SEC
        ST R3, SAVED_R3_SEC
        ST R5, SAVED_R5_SEC

        LD R3, WORDLEN
        LEA R1, SECRET_COPY
        AND R0, R0, #0
        LD R2, SAVED_CHAR

SEARCH_LOOP
        LDR R4, R1, #0
        NOT R5, R4
        ADD R5, R5, #1
        ADD R5, R2, R5
        BRz FOUND

        ADD R1, R1, #1
        ADD R3, R3, #-1
        BRp SEARCH_LOOP

        LD R1, SAVED_R1_SEC
        LD R2, SAVED_R2_SEC
        LD R3, SAVED_R3_SEC
        LD R5, SAVED_R5_SEC
        LD R7, SAVED_R7_SEC
        RET

FOUND
        ; R1 is pointing to match in SECRET_COPY
        AND R4, R4, #0
        STR R4, R1, #0      ; mark used
        AND R0, R0, #0
        ADD R0, R0, #1
        LD R1, SAVED_R1_SEC
        LD R2, SAVED_R2_SEC
        LD R3, SAVED_R3_SEC
        LD R5, SAVED_R5_SEC
        LD R7, SAVED_R7_SEC
        RET

; ---------------------------------------------------
; Data Section

WORDLEN     .FILL #5
GUESSMAX    .FILL #6
NEWLINE     .FILL x0A
GREEN       .FILL x47   ; 'G'
YELLOW      .FILL x59   ; 'Y'
BLACK       .FILL x42   ; 'B'
LOWERA      .FILL x61
LOWERZ      .FILL x7A
UPPERA      .FILL x41   ; 'A'
UPPERZ      .FILL x5A   ; 'Z'
NEG32       .FILL xFFE0
NEG6        .FILL #-6

SECRET      .STRINGZ "SPACE"
PROMPT      .STRINGZ "\nEnter guess: "
ENDMSG      .STRINGZ "\nGame Over.\n"
WINMSG      .STRINGZ "\nYou win!\n"
REVEALMSG   .STRINGZ "The word was: "

GUESSBUF        .BLKW 6
SECRET_COPY     .BLKW 6
SAVED_CHAR      .BLKW 1
SAVED_R1        .BLKW 1
SAVED_R2        .BLKW 1
SAVED_R3        .BLKW 1
SAVED_R4        .BLKW 1
SAVED_R5        .BLKW 1
SAVED_R6        .BLKW 1
SAVED_R7        .BLKW 1
SAVED_R1_SEC    .BLKW 1
SAVED_R2_SEC    .BLKW 1
SAVED_R3_SEC    .BLKW 1
SAVED_R5_SEC    .BLKW 1
SAVED_R7_SEC    .BLKW 1
SAVE_COUNTER    .BLKW 1

        .END
