.386
.model flat,stdcall
include Includes.inc   

.const
ROWS = 25
COLS = 50
PLATFORM_GAPS = 3
BALL_SPEED = 150
PLATFORM_SPEED = 300

.data
    ; ------------------------- VARIABLES -------------------------
    stdHandle DWORD 0
    info CONSOLE_CURSOR_INFO <>

    ballChar = 'O'
    gaps BYTE COLS DUP(' ')
    platformChar BYTE COLS DUP('=')
    
    ballScr SCREEN <ROWS, COLS, <25,0>>
    platformScr SCREEN <ROWS, COLS, <25,0>>

    ball BALL <3,30>
    platforms PLATFORM ROWS  DUP(<>)

    coord COORD <0,0>
    buff_in BYTE 0, 0
    buff_out BYTE 'Y'
    bytesRead DWORD 0

    threadArr HANDLE 0,0
    start_time DWORD ?
    end_game BYTE FALSE

    ; ------------------------- PROTOTYPES -------------------------
    GeneratePlatform PROTO
    ClearPlatform PROTO
    PlatformFn PROTO
    BallFn PROTO

.code

main PROC
    ; get handle of console
    INVOKE GetStdHandle, STD_OUTPUT_HANDLE
    mov stdHandle, eax
    ; initialize info of cursor
    mov info.dwSize, 100
    mov info.bVisible, FALSE       ; turn off visibility

    Call Randomize
    ; set color of screen:
    mov eax, red + (lightGray * 16)
	Call SetTextColor
	Call Clrscr

    INVOKE CreateScreen, ADDR platformScr, PlatformFn ; initialize 'platform' screen
    INVOKE CreateScreen, ADDR ballScr, BallFn         ; initialize 'ball' screen

    ; store the handles in separate array:
    mov eax, platformScr.thread
    mov threadArr[0], eax 
    mov eax, ballScr.thread
    mov threadArr[4], eax 

    ; resume the sleeping threads:
    INVOKE ResumeThread, ballScr.thread
    INVOKE ResumeThread, platformScr.thread

    ; get starting time:
    Call GetMseconds
    mov start_time, eax
    
    ; print borders:
    ; move left upto x-offset:
    mov dl, BYTE PTR [platformScr.off.x]
    mov dh, 0
    call Gotoxy
    mWrite "||||||||||||||||||||||||||||||||||||||||||||||||||"
    mov dl, BYTE PTR [platformScr.off.x]
    mov dh, ROWS +1
    call Gotoxy
    mWrite "||||||||||||||||||||||||||||||||||||||||||||||||||"

    _while:
        INVOKE SetConsoleCursorInfo, stdHandle, ADDR info
        ; continue until threads are not completed
        INVOKE WaitForMultipleObjects, 1, ADDR threadArr, TRUE, 0
        cmp eax, 0
        JE _end_while

        INVOKE PrintScreen, ADDR platformScr
        INVOKE PrintScreen, ADDR ballScr
    JMP _while
    _end_while:

    INVOKE DeleteScreen, ADDR ballScr                 ; clean up allocated resources
    INVOKE DeleteScreen, ADDR platformScr             ; clean up allocated resources
    Call Crlf
    Call GetScore

Call WaitMsg
Call ReadDec
exit
main ENDP

PlatformFn PROC
    
    LOCAL x:BYTE
    mov x, 0

    _while:
        cmp end_game, TRUE      ; loop == max iterations?
        JE _end_while           ; yes: exit while_loop
        
        call PlatformPrint      ; print all platformScr
        call PlatformMove       ; move them up

        cmp x, 0                ; gaps between lines == 0?
        JNE _dont_print
            INVOKE GeneratePlatform     ; create last platform
            mov x, PLATFORM_GAPS        ; 3 lines between platformScr
            JMP _next
        _dont_print:
            INVOKE ClearPlatform        ; empty last platform
            dec x

        _next:
        INVOKE Sleep, PLATFORM_SPEED
        INVOKE ClearScreen, ADDR platformScr  ; clear screen

    JMP _while
    _end_while:

    INVOKE ExitThread, 0
    RET
PlatformFn ENDP

BallFn PROC USES edx ecx
    LOCAL key1:BYTE, key2:BYTE
    
	_while:
        cmp ball.row, 0
        JE _endWhile
        cmp ball.row, ROWS - 1
        JE _endWhile

		call ReadKey
        JZ _adjust      ; no key was detected?
        
        ; receive inputs:
        mov key1, ah
        mov key2, al

		cmp key2, 0	; al == 0?
		JNE _adjust	; no: not the required key

		cmp key1, LEFT_PRESSED
        JNE _check_next
            call MoveLeft
            JMP _done
        _check_next:
		    cmp key1, RIGHT_PRESSED
            JNE _done
            call MoveRight
        _done:
        call PrintBall

        _adjust:
        ; calculate ball position:
        movzx edx, ballScr.off.x
        add edx, ball.col
        mov coord.x, dx 
        mov edx, ball.row
        inc edx
        mov coord.y, dx
        ; read from console:
        mov edx, OFFSET coord
        INVOKE ReadConsoleOutputCharacter, stdHandle, ADDR buff_in, 1, [edx], ADDR bytesRead
        ; also read a char below the position 
        inc coord.y
        mov edx, OFFSET coord
        INVOKE ReadConsoleOutputCharacter, stdHandle, ADDR buff_in + 1, 1, [edx], ADDR bytesRead

        cmp buff_in, '='       ; is the ball at any platform?
        JNE _down              ; no: move down
            call MoveUp        ; yes: move up with platforms
            JMP _next
        _down:
            cmp buff_in[1], ' ' ; is the space below is empty?
            JNE _next           ; no: do nothing
                call MoveDown   ; yes: move down 
                INVOKE Sleep, BALL_SPEED
        _next:
        call PrintBall         ; print new position
	JMP _while
	_endWhile:
    
    mov end_game, TRUE         ; end game
    INVOKE ExitThread, 0
    RET
BallFn ENDP

; prints on platformScr buffer 
PlatformPrint PROC USES edx ecx esi 
    mov esi, OFFSET platforms
    mov ecx,  LENGTHOF platforms
    _plat EQU (PLATFORM PTR [esi])
    Lp:
        ; print a single platform:
        mov edx, _plat.offsetFromLeft
        INVOKE WriteScreen, ADDR platformScr, ADDR gaps, edx
        mov edx, _plat.Len
        INVOKE WriteScreen, ADDR platformScr, ADDR platformChar, edx
        mov edx, _plat.offsetFromRight
        INVOKE WriteScreen, ADDR platformScr, ADDR gaps, edx
        
        add esi, SIZEOF PLATFORM
    LOOP Lp
	RET
PlatformPrint ENDP

; Generates last platform of random length at random position
GeneratePlatform PROC USES eax esi ecx  
    ; calculate last platform:
    mov esi, (ROWS - 1) * SIZEOF PLATFORM
    add esi, OFFSET platforms
    _plat EQU (PLATFORM PTR [esi])

    ; Determining its length
    mov eax, 11         ; range = 0 - 10
    Call RandomRange
    add eax, 10         ; len = 10 - 20
    mov _plat.Len, eax
    ; determine offset from left
    NEG eax
    add eax, COLS + 1   ; range = 0 - 40
    Call RandomRange
    mov _plat.offsetFromLeft, eax
    ; determine offset from right
    mov ecx, COLS
    sub ecx, _plat.Len
    sub ecx, _plat.offsetFromLeft
    mov _plat.offsetFromRight, ecx   
    RET
GeneratePlatform ENDP

; clears a given platform with blank lines
ClearPlatform PROC USES esi
    ; calculate last platform:
    mov esi, (ROWS - 1) * SIZEOF PLATFORM
    add esi, OFFSET platforms
    _plat EQU (PLATFORM PTR [esi])

    mov _plat.offsetFromLeft, COLS
    mov _plat.Len, 0
    mov _plat.offsetFromRight, 0   
    RET
ClearPlatform ENDP

; moves all platforms up by ones unit
; the first platform is lost (overriden by 2nd)
; the last platform is not changed
PlatformMove PROC USES eax ecx esi
    mov edi, OFFSET platforms   ; edi -> 1st plat
    mov esi, OFFSET platforms   
    add esi, SIZEOF PLATFORM    ; esi -> 2nd plat
    mov ecx, LENGTHOF platforms - 1
    Lcopy:
        INVOKE CopyPlatform, edi, esi
        add edi, SIZEOF PLATFORM
        add esi, SIZEOF PLATFORM
    LOOP Lcopy
    _end_proc:
    RET
PlatformMove ENDP

; moves the ball down by one row
MoveDown PROC
    cmp ball.row, ROWS - 1  ; is it safe to move down?
    JE end_proc             ; no: exit
        inc ball.row
    end_proc:
    RET
MoveDown ENDP

; moves the ball up by one row
MoveUp PROC
    cmp ball.row, 0          ; is it safe to move up?
    JE end_proc              ; no: exit
        dec ball.row
    end_proc:
    RET
MoveUp ENDP

; moves the ball left by one col
MoveLeft PROC
    cmp ball.row, 0         ; is it safe to move left?
    JE end_proc             ; no: exit
        dec ball.col
    end_proc:
    RET
MoveLeft ENDP

; moves the ball right by one col
MoveRight PROC
    cmp ball.row, COLS - 1  ; is it safe to move right?
    JE end_proc             ; no: exit
        inc ball.col
    end_proc:
    RET
MoveRight ENDP

; prints the ball on the ball buffer
PrintBall PROC USES edx
    ; remove old position:
    mov edx, ballScr.cursor
    add edx, ballScr.bucket
    mov BYTE PTR [edx], NOCHAR
    ; write new position:
    mov edx, ball.row
    imul edx, COLS
    add edx, ball.col
    mov ballScr.cursor, edx
    add edx, ballScr.bucket
    mov BYTE PTR [edx], ballChar
    RET
PrintBall ENDP

GetScore PROC USES eax ebx ecx edx  ; Calculates the score
    
    LOCAL score: DWORD, FileHandle: HANDLE, Buffer[6]: BYTE
    .data
    FileName BYTE "score.txt", 0

    .code
    Call GetMseconds
    sub eax, start_time
    mov edx, 0
    mov ebx, 100
    DIV ebx        ; duration divided by 100 gives us the score
    mov score, eax
    
    LEA edx, FileName
    Call OpenInputFile
    mov FileHandle, eax
    LEA edx, Buffer
    mov ecx, SIZEOF Buffer
    mov eax, FileHandle
    Call ReadFromFile

    JC err
    LEA edx, Buffer
    mov ecx, eax
    Call ParseDecimal32
    mov edx, eax

    ; Output
    mWrite "Your score: "
    mov eax, score
    Call WriteDec
    Call Crlf

    CMP eax, edx      ; Does score exceed high score?
    JA High_score

    mWrite "High score: "
    mov eax, edx
    Call WriteDec
    Call Crlf
    JMP end_proc
    
    High_score:
        mWrite "New High score: "
        Call WriteDec
        Call Crlf

        ; Updating file with new high score
        INVOKE IntToString, ADDR Buffer, eax     ; ecx stores length of Buffer
        LEA edx, Buffer
        mov eax, FileHandle
        Call WriteToFile
        JC err

        JMP end_proc
    err:
        mWrite "Sorry! An error occured!"
        Call Crlf
    end_proc:
        Call CloseFile
        RET
GetScore ENDP
END main