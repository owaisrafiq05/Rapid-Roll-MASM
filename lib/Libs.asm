.386
.model flat,stdcall
INCLUDE Includes.inc
print EQU <mWrite>

.data
.code
; -----------------------------------------------------------------------
CreateScreen PROC USES eax esi, screen: PTR SCREEN, callback: DWORD
; Initializes a SCREEN by allocating required resources
; - Allocates an empty buffer in heap
; - Creates a sleeping thread pointing to the given function
; RECEIVES: screen = address of the SCREEN
;           callback = the executing function of SCREEN
; RETURNS: nothing
; -----------------------------------------------------------------------
    ; type alias:
    mov esi, screen
    scr EQU (SCREEN PTR [esi])

    ; CREATING THE BUFFER:
    INVOKE GetProcessHeap   ; get handle for program
    cmp eax, 0              ; any error?
    JE _error               ; yes: exit 
    mov scr.buffer, eax     ; store the handle
    ; calculate area of screen:
    mov eax, scr.rows         
    mul scr.cols
    mov scr.area, eax 
    ; allocate memory in heap:
    INVOKE HeapAlloc, scr.buffer, HEAP_ZERO_MEMORY, scr.area 
    cmp eax, 0              ; no space left in heap?
    JE _error               ; yes: exit
    mov scr.bucket, eax     ; store the pointer to memory

    ; CREATING THE THREAD:
    INVOKE CreateThread, 0, 0, callback, 0, CREATE_SUSPENDED, 0
    mov scr.thread, eax     ; store the handle
    JMP proc_end            ; end program
    _error:
        print "An error while creating the buffer. Error code = "
        INVOKE GetLastError
        call WriteDec
        call Crlf
    proc_end:
    RET
CreateScreen ENDP

; -----------------------------------------------------------------------
DeleteScreen PROC, screen: PTR SCREEN
; Deletes a SCREEN by cleaning up allocated resources
; - frees the allocated buffer from heap
; - closes the running thread
; RECEIVES: screen = address of the SCREEN
; RETURNS: nothing
; -----------------------------------------------------------------------
    scr EQU (SCREEN PTR [screen])
    INVOKE HeapFree, scr.buffer, 0, scr.bucket
    INVOKE CloseHandle, scr.thread
    RET
DeleteScreen ENDP

; -----------------------------------------------------------------------
PrintScreen PROC USES eax ecx esi edi edx, screen: PTR SCREEN
; Prints the contents of given SCREEN on the active buffer
; RECEIVES: screen = address of SCREEN
; RETURNS: nothing
; -----------------------------------------------------------------------
    ; type alias:
    mov esi, screen
    scr EQU (SCREEN PTR [esi])
    ; move down upto y-offset:
    mov dh, BYTE PTR [scr.off.y]
    mov dl, 0 
    call Gotoxy 

    ; display like a regular 2D array:
    mov edi, scr.bucket
    mov ecx, scr.rows
    outer:
    push ecx
        ; move left upto x-offset:
        mov dl, BYTE PTR [scr.off.x]
        inc dh
        call Gotoxy

        mov ecx, [scr.cols]
        inner:
            mov al, BYTE PTR [edi]
            cmp al, NOCHAR
            JE _NoChar
                call WriteChar
                JMP _next
            _NoChar:
                inc dl
                call Gotoxy
            _next:
            inc edi
        LOOP inner
        ; call Crlf
    pop ecx
    LOOP outer
    RET
PrintScreen ENDP

; -----------------------------------------------------------------------
WriteScreen PROC USES ecx esi edi edx, screen: PTR SCREEN, string: DWORD, strLen: DWORD
; prints the given string on the buffer
; ERROR: when there is no room for the given string
; RECEIVES: screen = address of SCREEN
;           string = address of the string
;           strLen = the length of string (without '\0' null char)
; RETURNS: nothing
; -----------------------------------------------------------------------
    ; type alias:
    mov edx, screen
    scr EQU (SCREEN PTR [edx])

    mov ecx, strLen
    add ecx, scr.cursor
    cmp ecx, scr.area   ; cursor exceeds the area?
    JA _overflow        ; yes: quit
    
    mov esi, string     ; esi = source
    mov edi, scr.cursor
    add edi, scr.bucket ; edi = destination
    mov ecx, strLen
    add scr.cursor, ecx
    cld
    rep movsb
    JMP end_proc

    _overflow:
        print "Given string exceed the boundary of screen"
        call Crlf
    end_proc:
    RET
WriteScreen ENDP

; -----------------------------------------------------------------------
ClearScreen PROC USES ecx esi edi, screen: PTR SCREEN
; clears the screen by filling buffer with ' ' && by moving cursor to top-left
; RECEIVES: screen = address of SCREEN
; RETURNS: nothing
; -----------------------------------------------------------------------
    ; type alias:
    mov esi, screen
    scr EQU (SCREEN PTR [esi])
    
    mov scr.cursor, 0      ; restart cursor
    ; fill buffer like a regular 2D array:
    mov edi, scr.bucket
    mov ecx, scr.rows
    outer:
    push ecx
        mov ecx, scr.cols
        inner:
            mov BYTE PTR [edi], NOCHAR
            inc edi
        LOOP inner
    pop ecx
    LOOP outer
    RET
ClearScreen ENDP

; -----------------------------------------------------------------------
; -----------------------------------------------------------------------

; -----------------------------------------------------------------------
CopyPlatform PROC USES eax esi edi, destination:PTR PLATFORM, source:PTR PLATFORM
; Copies contents of 'source' to 'destination'
; RECEIVES: destination = address of PLATFORM to copy into
;           source = address of PLATFORM to copy from
; RETURNS: nothing
; -----------------------------------------------------------------------
    ; type alias:
    mov edi, destination
    dest EQU (PLATFORM PTR [edi])
    mov esi, source
    src EQU (PLATFORM PTR [esi])

    mov edx, src.Len
    mov dest.Len, edx

    mov edx, src.offsetFromLeft
    mov dest.offsetFromLeft, edx

    mov edx, src.offsetFromRight
    mov dest.offsetFromRight, edx

    RET
CopyPlatform ENDP

; -----------------------------------------------------------------------
IntToString PROC USES eax edx esi, s: PTR BYTE, n: DWORD
; Converts string to integer
; RECEIVES: s = address of string
;           n = Integer
; RETURNS: length of string in ecx
; ----------------------------------------------
    LOCAL divisor: DWORD
    mov divisor, 10
    mov eax, n
    mov esi, s
    mov ecx, 0

    _while:
        mov edx, 0
        DIV divisor
        add dl, 48
        mov BYTE PTR [esi + ecx], dl
        inc ecx
        CMP eax, 0
        JNE _while
    
    _end_while:
        INVOKE str_reverse, s, ecx
        RET
IntToString ENDP

; -----------------------------------------------------------------------
str_reverse PROC USES eax ecx edx esi edi, s: PTR BYTE, len: DWORD
; Reverses the string
; RECEIVES: s = address of string
;           len = length of string
; RETURNS: nothing
; ----------------------------------------------
    LOCAL divisor: DWORD
    mov divisor, 2
    mov eax, len
    mov edx, 0
    DIV divisor
    mov ecx, eax
    mov esi, s
    mov edi, esi
    add edi, len
    dec edi

    reverse:
        mov al, BYTE PTR [esi]
        xchg BYTE PTR [edi], al
        mov BYTE PTR [esi], al
        inc esi
        dec edi
    LOOP reverse
    RET
str_reverse ENDP
END

||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
|||||||||||||||||||||||||||||||| END |||||||||||||||||||||||||||||||||||||||||||||||
||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||