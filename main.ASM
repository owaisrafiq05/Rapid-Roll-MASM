.model flat,stdcall
include Includes.inc   

.const
ROWS = 25
COLS = 50
PLATFORM_GAP = 3
BALL_SPEED = 150
PLATFORM_MOVE_SPEED = 300

.data
    ; ------------------------- GLOBAL VARIABLES -------------------------
    stdHandle DWORD 0
    cursorInfo CONSOLE_CURSOR_INFO <>

    ballChar BYTE 'O'
    gapSpaces BYTE COLS DUP(' ')
    platformChar BYTE COLS DUP('=')

    ballScreen SCREEN <ROWS, COLS, <25,0>>
    platformScreen SCREEN <ROWS, COLS, <25,0>>

    ballPos BALL <3,30>
    platforms PLATFORM ROWS DUP(<>)

    cursorPos COORD <0,0>
    bufferIn BYTE 0, 0
    bufferOut BYTE 'Y'
    bytesRead DWORD 0

    threadHandles HANDLE 0,0
    startTime DWORD ?
    gameEnded BYTE FALSE

    ; ------------------------- PROCEDURE DECLARATIONS -------------------------
    GenerateRandomPlatform PROTO
    ClearPlatform PROTO
    MovePlatformUp PROTO
    BallMovement PROC USES edx ecx

.code

main PROC
    ; Get standard output handle
    INVOKE GetStdHandle, STD_OUTPUT_HANDLE
    mov stdHandle, eax

    ; Hide the cursor
    mov cursorInfo.dwSize, 100
    mov cursorInfo.bVisible, FALSE
    Call SetCursorVisibility

    ; Set color scheme
    mov eax, red + (lightGray * 16)
    Call SetTextColor
    Call ClearScreen

    ; Create screens for ball and platforms
    INVOKE CreateScreen, ADDR platformScreen, MovePlatformUp 
    INVOKE CreateScreen, ADDR ballScreen, BallMovement 

    ; Store thread handles
    mov eax, platformScreen.thread
    mov threadHandles[0], eax 
    mov eax, ballScreen.thread
    mov threadHandles[1], eax 

    ; Resume threads
    INVOKE ResumeThread, ballScreen.thread
    INVOKE ResumeThread, platformScreen.thread

    ; Get start time
    Call GetMilliseconds
    mov startTime, eax
    
    ; Print borders
    mov dl, BYTE PTR [platformScreen.offset.x]
    mov dh, 0
    call MoveCursor
    mWrite "||||||||||||||||||||||||||||||||||||||||||||||||||"
    
    mov dl, BYTE PTR [platformScreen.offset.x]
    mov dh, ROWS + 1
    call MoveCursor
    mWrite "||||||||||||||||||||||||||||||||||||||||||||||||||"

    ; Main game loop
    _main_game_loop:
        INVOKE SetConsoleCursorInfo, stdHandle, ADDR cursorInfo
        INVOKE WaitForMultipleObjects, 1, ADDR threadHandles, TRUE, 0
        cmp eax, 0
        JE _game_over

        ; Print screens for ball and platforms
        INVOKE PrintScreen, ADDR platformScreen
        INVOKE PrintScreen, ADDR ballScreen
    JMP _main_game_loop

    _game_over:
        INVOKE DeleteScreen, ADDR ballScreen
        INVOKE DeleteScreen, ADDR platformScreen
        Call NewLine
        Call DisplayScore

    Call WaitForMessage
    Call ReadDecimalInput
    exit
main ENDP

; Procedure to handle platform movement
MovePlatformUp PROC
    LOCAL count:BYTE
    mov count, 0

    _move_loop:
        cmp gameEnded, TRUE
        JE _exit_move_loop

        call DrawPlatforms
        call ShiftPlatformsUp

        cmp count, 0
        JNE _do_not_generate_new
        INVOKE GenerateRandomPlatform
        mov count, PLATFORM_GAP
        JMP _next_iteration
    _do_not_generate_new:
        INVOKE ClearPlatform
        dec count

    _next_iteration:
        INVOKE Sleep, PLATFORM_MOVE_SPEED
        INVOKE ClearScreen, ADDR platformScreen

    JMP _move_loop
    _exit_move_loop:
    INVOKE ExitThread, 0
    RET
MovePlatformUp ENDP

; Procedure to handle ball movement
BallMovement PROC USES edx ecx
    LOCAL userInput1:BYTE, userInput2:BYTE
    
    _movement_loop:
        cmp ballPos.row, 0
        JE _end_ball_movement
        cmp ballPos.row, ROWS - 1
        JE _end_ball_movement

        call ReadKey
        JZ _adjust_position

        ; Read key inputs:
        mov userInput1, ah
        mov userInput2, al

        cmp userInput2, 0
        JNE _adjust_position

        cmp userInput1, LEFT_ARROW
        JNE _check_next_direction
        call MoveBallLeft
        JMP _update_position

    _check_next_direction:
        cmp userInput1, RIGHT_ARROW
        JNE _update_position
        call MoveBallRight

    _update_position:
        call RenderBall
    _adjust_position:

        ; Update ball position:
        movzx edx, ballScreen.offset.x
        add edx, ballPos.col
        mov cursorPos.x, dx 
        mov edx, ballPos.row
        inc edx
        mov cursorPos.y, dx

        ; Read from console buffer
        mov edx, OFFSET cursorPos
        INVOKE ReadConsoleOutputCharacter, stdHandle, ADDR bufferIn, 1, [edx], ADDR bytesRead

        ; Check if ball is on platform
        cmp bufferIn, '='
        JNE _fall_down
        call MoveBallUp
        JMP _next_position

    _fall_down:
        cmp bufferIn[1], ' '   ; Check if below space is empty
        JNE _next_position
        call MoveBallDown
        INVOKE Sleep, BALL_SPEED

    _next_position:
        call RenderBall
    JMP _movement_loop

    _end_ball_movement:
        mov gameEnded, TRUE
        INVOKE ExitThread, 0
        RET
BallMovement ENDP

; Draw platforms on screen
DrawPlatforms PROC USES edx ecx esi
    mov esi, OFFSET platforms
    mov ecx, LENGTHOF platforms
    _platform EQU (PLATFORM PTR [esi])
    LoopDraw:
        ; Draw a single platform
        mov edx, _platform.offsetFromLeft
        INVOKE WriteScreen, ADDR platformScreen, ADDR gapSpaces, edx
        mov edx, _platform.Len
        INVOKE WriteScreen, ADDR platformScreen, ADDR platformChar, edx
        mov edx, _platform.offsetFromRight
        INVOKE WriteScreen, ADDR platformScreen, ADDR gapSpaces, edx

        add esi, SIZEOF PLATFORM
    LOOP LoopDraw
    RET
DrawPlatforms ENDP

; Generate random platform parameters
GenerateRandomPlatform PROC USES eax esi ecx
    mov esi, (ROWS - 1) * SIZEOF PLATFORM
    add esi, OFFSET platforms
    _platform EQU (PLATFORM PTR [esi])

    ; Generate random platform length
    mov eax, 11         ; Range = 0 - 10
    Call RandomRange
    add eax, 10         ; Length = 10 - 20
    mov _platform.Len, eax

    ; Determine offset from left
    NEG eax
    add eax, COLS + 1
    Call RandomRange
    mov _platform.offsetFromLeft, eax

    ; Calculate offset from right
    mov ecx, COLS
    sub ecx, _platform.Len
    sub ecx, _platform.offsetFromLeft
    mov _platform.offsetFromRight, ecx   
    RET
GenerateRandomPlatform ENDP

; Clear platform buffer (reset)
ClearPlatform PROC USES esi
    mov esi, (ROWS - 1) * SIZEOF PLATFORM
    add esi, OFFSET platforms
    _platform EQU (PLATFORM PTR [esi])

    mov _platform.offsetFromLeft, COLS
    mov _platform.Len, 0
    mov _platform.offsetFromRight, 0
    RET
ClearPlatform ENDP

; Shift platforms up
ShiftPlatformsUp PROC USES eax ecx esi
    mov edi, OFFSET platforms
    mov esi, OFFSET platforms
    add esi, SIZEOF PLATFORM
    mov ecx, LENGTHOF platforms - 1
    LoopCopyPlatforms:
        INVOKE CopyPlatform, edi, esi
        add edi, SIZEOF PLATFORM
        add esi, SIZEOF PLATFORM
    LOOP LoopCopyPlatforms
    RET
ShiftPlatformsUp ENDP

; Ball movement - down by one row
MoveBallDown PROC
    cmp ballPos.row, ROWS - 1
    JE end_move
        inc ballPos.row
    end_move:
    RET
MoveBallDown ENDP

; Ball movement - up by one row
MoveBallUp PROC
    cmp ballPos.row, 0
    JE end_move
        dec ballPos.row
    end_move:
    RET
MoveBallUp ENDP

; Ball movement - left by one column
MoveBallLeft PROC
    cmp ballPos.col, 0
    JE end_move
        dec ballPos.col
    end_move:
    RET
MoveBallLeft ENDP

; Ball movement - right by one column
MoveBallRight PROC
    cmp ballPos.col, COLS - 1
    JE end_move
        inc ballPos.col
    end_move:
    RET
MoveBallRight ENDP

; Render ball on screen
RenderBall PROC USES edx
    mov edx, ballScreen.cursor
    add edx, ballScreen.bucket
    mov BYTE PTR [edx], NOCHAR
    mov edx, ballPos.row
    imul edx, COLS
    add edx, ballPos.col
    mov ballScreen.cursor, edx
    add edx, ballScreen.bucket
    mov BYTE PTR [edx], ballChar
    RET
RenderBall ENDP

; Display score after the game ends
DisplayScore PROC USES eax ebx ecx edx
    LOCAL score: DWORD, FileHandle: HANDLE, Buffer[6]: BYTE
    .data
    FileName BYTE "score.txt", 0

    .code
    Call GetMilliseconds
    sub eax, startTime
    mov edx, 0
    mov ebx, 100
    DIV ebx
    mov score, eax

    LEA edx, FileName
    Call OpenFileForInput
    mov FileHandle, eax
    LEA edx, Buffer
    mov ecx, SIZEOF Buffer
    mov eax, FileHandle
    Call ReadFileData

    JC error_occurred
    LEA edx, Buffer
    mov ecx, eax
    Call ParseToDecimal32
    mov edx, eax

    ; Output score
    mWrite "Your score: "
    mov eax, score
    Call WriteDecimal
    Call NewLine

    ; Compare score with high score
    CMP eax, edx
    JA new_high_score

    mWrite "High score: "
    mov eax, edx
    Call WriteDecimal
    Call NewLine
    JMP end_proc

    new_high_score:
        mWrite "New High Score! "
        Call WriteDecimal
        Call NewLine

        ; Update high score in file
        INVOKE IntToString, ADDR Buffer, eax
        LEA edx, Buffer
        mov eax, FileHandle
        Call WriteFileData
        JC error_occurred

    JMP end_proc

    error_occurred:
        mWrite "An error occurred!"
        Call NewLine

    end_proc:
        Call CloseFile
        RET
DisplayScore ENDP

END main
