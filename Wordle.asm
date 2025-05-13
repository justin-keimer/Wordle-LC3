        .ORIG x3000

; ========================
; Initialize guess counter
        AND R6, R6, #0
        ST R6, SAVE_COUNTER

LOOP_START
        LD R6, SAVE_COUNTER
        LD R1, NEG6
        ADD R2, R6, R1
        BRzp GAME_OVER
        
        LEA R0, PROMPT
        PUTS

        LEA R4, GUESSBUF
        AND R5, R5, #0

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
        LD R7, WORDLEN
        NOT R7, R7
        ADD R7, R5, R7
        BRn READ_CHAR_LOOP

        AND R1, R1, #0
        STR R1, R4, #0

        JSR GIVE_FEEDBACK

        ADD R6, R6, #0
        BRz CONTINUE_GAME
        BRnzp WINNER

CONTINUE_GAME
        LD R6, SAVE_COUNTER
        ADD R6, R6, #1
        ST R6, SAVE_COUNTER
        BRnzp LOOP_START

GAME_OVER
        LEA R0, ENDMSG
        PUTS
        HALT

WINNER
        LEA R0, WINMSG
        PUTS
        HALT

; ===========================================================
; GIVE_FEEDBACK - Compares guess to secret, prints feedback
GIVE_FEEDBACK
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
        AND R5, R5, #0
        AND R6, R6, #0

GFB_LOOP
        LDR R4, R1, #0
        LDR R0, R2, #0

        NOT R0, R0
        ADD R0, R0, #1
        ADD R0, R4, R0
        BRnp CHECK_YELLOW

        LD R0, GREEN
        OUT
        ADD R5, R5, #1

        LEA R7, SECRET_COPY
        ADD R7, R7, R5
        ADD R7, R7, #-1
        AND R4, R4, #0
        STR R4, R7, #0
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

        ST R1, SAVED_R1
        ST R2, SAVED_R2
        ST R3, SAVED_R3

        LEA R1, BAD_LETTERS
        LD R2, BAD_COUNT
        ADD R1, R1, R2
        LD R3, BAD_COUNT

CHECK_BAD_LOOP
        BRz STORE_BAD
        LDR R5, R1, #-1
        NOT R5, R5
        ADD R5, R5, #1
        ADD R5, R5, R4
        BRz BAD_ALREADY_EXISTS
        ADD R1, R1, #-1
        ADD R3, R3, #-1
        BRp CHECK_BAD_LOOP

STORE_BAD
        LD R1, BAD_COUNT
        LEA R2, BAD_LETTERS
        ADD R2, R2, R1
        STR R4, R2, #0
        ADD R1, R1, #1
        ST R1, BAD_COUNT

BAD_ALREADY_EXISTS
        LD R1, SAVED_R1
        LD R2, SAVED_R2
        LD R3, SAVED_R3

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
        ; Print bad letters
        LEA R0, BADMSG
        PUTS

        LEA R1, BAD_LETTERS
        LD R2, BAD_COUNT
PRINT_BAD_LOOP
        BRz PRINT_DONE
        LDR R0, R1, #0
        OUT
        ADD R1, R1, #1
        ADD R2, R2, #-1
        BRnzp PRINT_BAD_LOOP

PRINT_DONE
        LD R0, NEWLINE
        OUT

        LD R1, SAVED_R1
        LD R2, SAVED_R2
        LD R3, SAVED_R3
        LD R4, SAVED_R4
        LD R5, SAVED_R5
        LD R6, SAVED_R6
        LD R7, SAVED_R7
        RET

; ===========================================================
; IS_IN_SECRET - Returns R0 = 1 if SAVED_CHAR is in SECRET_COPY
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
        AND R4, R4, #0
        STR R4, R1, #0
        AND R0, R0, #0
        ADD R0, R0, #1
        LD R1, SAVED_R1_SEC
        LD R2, SAVED_R2_SEC
        LD R3, SAVED_R3_SEC
        LD R5, SAVED_R5_SEC
        LD R7, SAVED_R7_SEC
        RET

; ===========================================================
; DATA SECTION

WORDLEN     .FILL #5
GUESSMAX    .FILL #6
NEWLINE     .FILL x0A
GREEN       .FILL x47
YELLOW      .FILL x59
BLACK       .FILL x42
LOWERA      .FILL x61
LOWERZ      .FILL x7A
UPPERA      .FILL x41
UPPERZ      .FILL x5A
NEG32       .FILL xFFE0
NEG6        .FILL #-6

SECRET      .STRINGZ "HELLO"
PROMPT      .STRINGZ "\nEnter guess: "
ENDMSG      .STRINGZ "\nGame Over.\n"
WINMSG      .STRINGZ "\nYou win!\n"
BADMSG      .STRINGZ "Bad letters: "

GUESSBUF        .BLKW 6
SECRET_COPY     .BLKW 6
BAD_LETTERS     .BLKW 27
BAD_COUNT       .FILL #0

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
