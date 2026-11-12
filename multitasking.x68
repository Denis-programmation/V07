
    ORG     0

    DC.L    STACK           ; Reset SP - Not really a vector. Used to initialize the stack pointer.
    DC.L    START           ; Reset PC - Reset/startup
    DC.L    DUMMYHANDLER    ; Bus error - Bus cycle couldn't complete properly.
    DC.L    ADDRESS_ERROR   ; Address error - Misaligned (odd) word or longword memory access.
    DC.L    DUMMYHANDLER    ; Illegal instruction - Tried executing an invalid opcode.
    DC.L    DUMMYHANDLER    ; Division by zero - DIVUed or DIVSed by zero.
    DC.L    DUMMYHANDLER    ; CHK instruction - CHK resulted in "out of bounds".
    DC.L    DUMMYHANDLER    ; TRAPV instruction - TRAPV with overflow flag set.
    DC.L    DUMMYHANDLER    ; Privilege violation - Use of privileged instruction in user mode.
    DC.L    DUMMYHANDLER    ; Trace - After each executed instruction when 68k is in trace mode (debugger function).
    DC.L    DUMMYHANDLER    ; Unimplemented instruction (line A) - Used to implement 680xx instructions in software.
    DC.L    DUMMYHANDLER    ; Unimplemented instruction (line F) - Used to implement 680xx instructions in software.
    DC.L    DUMMYHANDLER    ; Reserved
    DC.L    DUMMYHANDLER    ; Coprocessor protocol violation
    DC.L    DUMMYHANDLER    ; Format error
    DC.L    DUMMYHANDLER    ; Uninitialized interrupt
    DC.L    DUMMYHANDLER    ; Reserved
    DC.L    DUMMYHANDLER    ; Reserved
    DC.L    DUMMYHANDLER    ; Reserved
    DC.L    DUMMYHANDLER    ; Reserved
    DC.L    DUMMYHANDLER    ; Reserved
    DC.L    DUMMYHANDLER    ; Reserved
    DC.L    DUMMYHANDLER    ; Reserved
    DC.L    DUMMYHANDLER    ; Reserved
    DC.L    DUMMYHANDLER    ; Spurious interrupt - No acknowledge from hardware.
    DC.L    SCHEDULER       ; IRQ1
    DC.L    DUMMYHANDLER    ; IRQ2
    DC.L    DUMMYHANDLER    ; IRQ3
    DC.L    DUMMYHANDLER    ; IRQ4
    DC.L    DUMMYHANDLER    ; IRQ5
    DC.L    DUMMYHANDLER    ; IRQ6
    DC.L    DUMMYHANDLER    ; IRQ7
    DC.L    DUMMYHANDLER    ; TRAP #0
    DC.L    DUMMYHANDLER    ; TRAP #1
    DC.L    DUMMYHANDLER    ; TRAP #2
    DC.L    DUMMYHANDLER    ; TRAP #3
    DC.L    DUMMYHANDLER    ; TRAP #4
    DC.L    DUMMYHANDLER    ; TRAP #5
    DC.L    DUMMYHANDLER    ; TRAP #6
    DC.L    DUMMYHANDLER    ; TRAP #7
    DC.L    DUMMYHANDLER    ; TRAP #8
    DC.L    DUMMYHANDLER    ; TRAP #9
    DC.L    DUMMYHANDLER    ; TRAP #10
    DC.L    DUMMYHANDLER    ; TRAP #11
    DC.L    DUMMYHANDLER    ; TRAP #12
    DC.L    DUMMYHANDLER    ; TRAP #13
    DC.L    DUMMYHANDLER    ; TRAP #14
*    DC.L    DUMMYHANDLER    ; TRAP #15

    ORG     $1000

START:
    LEA     STACK, A7
    MOVE.L  #32, D0             ; trap task to get address of hardware (panneau de commande)
    MOVE.L  #0, D1
    TRAP    #15                 ; display hardware window
    MOVE.L  #1, D1
    TRAP    #15                 ; get address of 7-segment display
    MOVE.L  D1, SEGMENTS_ADDRESS
    MOVE.L  D1, A0
    MOVE.L  #8-1, D3
LOOP1:
    CLR.W   (A0)+
    DBRA    D3, LOOP1           ; clear 7 segments
    MOVE.L  #2, D1
    TRAP    #15                 ; get address of LEDs
    MOVE.L  D1, LEDS_ADDRESS
    MOVE.L  D1, A0
    CLR.B   (A0)
    MOVE.L  #3, D1
    TRAP    #15                 ; get address of switches
    MOVE.L  D1, SWITCHES_ADDRESS
    MOVE.L  #6, D1              ; set auto irq
    MOVE.L  #%10000001, D2      ; irq1
    MOVE.L  #100, D3            ; interval
    TRAP    #15
START_SCHEDULER:
    LEA     READY_LIST_HEAD, A0 ; A0 gets address of first task in list
    MOVEA.L (A0), A2            ; A2 holds address of first task's TCB
    LEA     CURR_TASK, A1
    MOVE.L  A2, (A1)            ; set up CURR_TASK
    MOVE.L  12(A2), A3          ; get first task's stack pointer into A3
    MOVE.L  A3, USP             ; 
    MOVE.L  20(A2), D0          ; get initial program counter from TCB
    MOVE.L  D0, -(A7)           ; create interrupt stack frame on supervisor stack
    MOVE.W  16(A2), D0          ; get status register out of TCB
    MOVE.W  D0, -(A7)           ; 
    RTE

SCHEDULER:
    MOVEM.L D0-D7/A0-A6, -(A7)  ; save user registers
    MOVE.L  USP, A1             ; get user stack pointer into A1
    SUB.L   #60, A1             ; make space on user stack to store registers
    MOVEM.L (A7)+, D0-D7        ; pop data registers off supervisor stack...
    MOVEM.L D0-D7, (A1)         ; ... and save them onto user stack
    MOVEM.L (A7)+, D0-D6        ; D0-D6 = A0-A6
    MOVEM.L D0-D6, 32(A1)       ; D0-D6 = A0-A6
* save task's state into its TCB
    MOVEA.L CURR_TASK, A0       ; get address of TCB into A0
    MOVE.L  A1, 12(A0)          ; A1 holds task's SP, save it into TCB
    MOVE.W  (A7)+, D0           ; pop task's status register
    MOVE.W  D0, 16(A0)          ; save status register into TCB
    MOVE.L  (A7)+, D0           ; pop task's PC
    MOVE.L  D0, 20(A0)          ; save task's PC into TCB
*
    MOVEA.L (A0), A0            ; next pointer
    MOVE.L  A0, CURR_TASK       ; store in current task variable
*****************************
    MOVEM.L D3/A5, -(A7)
    EOR.L   D3, D3
    MOVE.B  11(A0), D3          ; task number
    MOVE.L  SEGMENTS_ADDRESS, A5
    BSR     SEGMENT7
    MOVE.L  LEDS_ADDRESS, A5
    MOVE.B  D3, (A5)  
    MOVEM.L (A7)+, D3/A5
******************************
    MOVEA.L 12(A0), A1          ; stack
    MOVEA.L A1, A2
    ADDA.L  #60, A2
    MOVE.L  A2, USP
*
    MOVE.L  20(A0), D0          ; program counter
    MOVE.L  D0, -(A7)
    MOVE.W  16(A0), D0          ; status register
    MOVE.W  D0, -(A7)
    MOVEM.L (A1), D0-A6
    RTE

TASK1:
    MOVE.L  SWITCHES_ADDRESS, A0
    TST.B   (A0)
    BEQ     TASK1_SKIP_SEMAPHORE
    TAS     SEMAPHORE
    BNE     TASK1
TASK1_SKIP_SEMAPHORE:
    LEA     TASK1_MSG, A0
    MOVE.L  #6, D0          ; output single char
TASK1_LOOP1:
    MOVE.B  (A0)+, D1
    TST.B   D1
    BEQ     TASK1_CLEAR
    TRAP    #15
    BRA     TASK1_LOOP1
TASK1_CLEAR:
    CLR.B   SEMAPHORE
TASK1_LOOP2:
    BRA     TASK1_LOOP2
    
TASK2:
    MOVE.L  SWITCHES_ADDRESS, A0
    TST.B   (A0)
    BEQ     TASK2_SKIP_SEMAPHORE
    TAS     SEMAPHORE
    BNE     TASK2
TASK2_SKIP_SEMAPHORE:
    LEA     TASK2_MSG, A0
    MOVE.L  #6, D0          ; output single char
TASK2_LOOP1:
    MOVE.B  (A0)+, D1
    TST.B   D1
    BEQ     TASK2_CLEAR
    TRAP    #15
    BRA     TASK2_LOOP1
TASK2_CLEAR:
    CLR.B   SEMAPHORE
TASK2_LOOP2:
    BRA     TASK2_LOOP2
    
DUMMYHANDLER:
    NOP
    RTE

ADDRESS_ERROR:
    NOP
    RTE
    
* Display a digit on the 7-segment display
* Pre:  D3.B contains 1 digit to display
*       A5 points to 7-segment LED to use
* Post: A5 points to next 7-segment LED

SEGMENT7:
    MOVEM.L A1, -(A7)       ; save registers
    LEA     DIGITS, A1      ; bit pattern table
    AND.L   #$00FF, D3
    MOVE.B  (A1,D3), (A5)   ; display digit
    SUBA.L  #2, A5
    MOVEM.L (A7)+, A1       ; restore registers
    RTS

STACK_BOTTOM:
    DS.L    $400
STACK:

CURR_TASK:
    DC.L    1               ; points to TCB of currently running task

READY_LIST_HEAD:
    DC.L    TASK1_TCB


TASK1_TCB:
    DC.L    TASK2_TCB       ; next pointer
    DC.L    READY_LIST_HEAD ; previous pointer
    DC.L    1               ; name
    DC.L    TASK1_STACK-60  ; stack
    DC.L    0               ; status register
    DC.L    TASK1           ; program counter
    

TASK2_TCB:
    DC.L    TASK1_TCB       ; next pointer
    DC.L    TASK1_TCB       ; previous pointer
    DC.L    2               ; name
    DC.L    TASK2_STACK-60  ; stack
    DC.L    0               ; status register
    DC.L    TASK2           ; program counter
    
TASK1_STACK_BOTTOM:
    DS.L    $400        ; 1kB
TASK1_STACK:
    
TASK2_STACK_BOTTOM:
    DS.L    $400        ; 1kB
TASK2_STACK:
    
TASK1_MSG:
    DC.B    '11 Il arriva chez nous un dimanche de novembre189... Je continue à dire « chez', $0D, $0A
    DC.B    '12 nous », bien que la maison ne nous appartienne plus. Nous avons quitté le', $0D, $0A
    DC.B    '13 pays depuis bientôt quinze ans et nous n y reviendrons certainement jamais.', $0D, $0A
    DC.B    '14 Nous habitions les bâtiments du Cours Supérieur de Sainte-Agathe. Mon père,', $0D, $0A
    DC.B    '15 que j appelais M. Seurel, comme les autres élèves, y dirigeait à la fois le', $0D, $0A
    DC.B    '16 Cours Supérieur,où l on préparait le brevet d instituteur, et le Cours Moyen', $0D, $0A, 0

TASK2_MSG:
    DC.B    '21 Le hasard des « changements », une décision d inspecteur ou de préfet nous', $0D, $0A
    DC.B    '22 avaient conduits là. Vers la fin des vacances, il y a bien longtemps, une ', $0D, $0A
    DC.B    '23 voiture de paysan, qui précédait notre ménage, nous avait déposés, ma mère', $0D, $0A
    DC.B    '24 et moi, devant la petite grille rouillée. Des gamins qui volaient des pêches', $0D, $0A
    DC.B    '25 dans le jardin s étaient enfuis silencieusement par les trous de la haie...',  $0D, $0A, 0

    DS.W    1       ; alignement adresse paire

SWITCHES_ADDRESS:
    DS.L    1
SEGMENTS_ADDRESS:
    DS.L    1
LEDS_ADDRESS:
    DS.L    1

SEMAPHORE:
    DC.B    0

*-----------------------------------------------------------
*         A
*       -----
*     F|     |B
*      |  G  |
*       -----
*     E|     |C
*      |  D  |
*       -----   .H
*
* Bit Number  7 6 5 4 3 2 1 0
* Segment     H G F E D C B A

* bit patterns to form digits on readout
DIGITS:
    DC.B  $3F           DIGIT 0
    DC.B  $06           DIGIT 1
    DC.B  $5B           DIGIT 2
    DC.B  $4F           DIGIT 3
    DC.B  $66           DIGIT 4
    DC.B  $6D           DIGIT 5
    DC.B  $7D           DIGIT 6
    DC.B  $07           DIGIT 7
    DC.B  $7F           DIGIT 8
    DC.B  $6F           DIGIT 9
    DC.B  $00           DIGIT OFF
    DC.B  $40           DASH

    DS.W  0             force word boundary

    END     START

*~Font name~Fixedsys~
*~Font size~9~
*~Tab type~1~
*~Tab size~4~
