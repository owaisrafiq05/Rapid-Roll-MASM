.386
.model flat,stdcall
INCLUDE Includes.inc
print EQU <mWrite>

.data
.code
; -----------------------------------------------------------------------
CreateDisplay PROC USES eax esi, disp: PTR DISPLAY, fnCallback: DWORD
; Creates a DISPLAY by allocating required resources and setting up a thread
; RECEIVES: disp = address of DISPLAY
;           fnCallback = function to be called by thread
; RETURNS: nothing
; -----------------------------------------------------------------------
    ; type alias:
    mov esi, disp
    dispPtr EQU (DISPLAY PTR [esi])

    ; CREATING BUFFER:
    INVOKE GetProcessHeap   ; get program heap
    cmp eax, 0              ; check for error
    JE _creationError       ; exit if error
    mov dispPtr.heapHandle, eax ; store heap handle
    ; calculate screen area:
    mov eax, dispPtr.rows
    mul dispPtr.cols
    mov dispPtr.size, eax
    ; allocate memory:
    INVOKE HeapAlloc, dispPtr.heapHandle, HEAP_ZERO_MEMORY, dispPtr.size
    cmp eax, 0              ; no space available?
    JE _creationError       ; exit if error
    mov dispPtr.buffer, eax ; store buffer pointer

    ; CREATING THREAD:
    INVOKE CreateThread, 0, 0, fnCallback, 0, CREATE_SUSPENDED, 0
    mov dispPtr.threadHandle, eax ; store thread handle
    JMP proc_end            ; finish procedure

    _creationError:
        print "Error in buffer creation. Code: "
        INVOKE GetLastError
        call WriteDec
        call Crlf

    proc_end:
    RET
CreateDisplay ENDP

; -----------------------------------------------------------------------
DeleteDisplay PROC, disp: PTR DISPLAY
; Deletes a DISPLAY by freeing memory and closing the associated thread
; RECEIVES: disp = address of DISPLAY
; RETURNS: nothing
; -----------------------------------------------------------------------
    dispPtr EQU (DISPLAY PTR [disp])
    INVOKE HeapFree, dispPtr.heapHandle, 0, dispPtr.buffer
    INVOKE CloseHandle, dispPtr.threadHandle
    RET
DeleteDisplay ENDP

; -----------------------------------------------------------------------
RenderDisplay PROC USES eax ecx esi edi edx, disp: PTR DISPLAY
; Prints the contents of the DISPLAY buffer to the screen
; RECEIVES: disp = address of DISPLAY
; RETURNS: nothing
; -----------------------------------------------------------------------
    ; type alias:
    mov esi, disp
    dispPtr EQU (DISPLAY PTR [esi])

    ; Move cursor to the top-left of the screen
    mov dh, BYTE PTR [dispPtr.offsetY]
    mov dl, 0
    call Gotoxy

    ; Print the screen buffer row by row
    mov edi, dispPtr.buffer
    mov ecx, dispPtr.rows
    outerLoop:
        push ecx
        ; Move cursor to the x-offset:
        mov dl, BYTE PTR [dispPtr.offsetX]
        inc dh
        call Gotoxy

        mov ecx, dispPtr.cols
        innerLoop:
            mov al, BYTE PTR [edi]
            cmp al, NOCHAR
            JE _noChar
                call WriteChar
                JMP _nextChar
            _noChar:
                inc dl
                call Gotoxy
            _nextChar:
            inc edi
        LOOP innerLoop
        pop ecx
    LOOP outerLoop
    RET
RenderDisplay ENDP

; -----------------------------------------------------------------------
WriteToDisplay PROC USES ecx esi edi edx, disp: PTR DISPLAY, str: DWORD, length: DWORD
; Writes a string to the display buffer
; RECEIVES: disp = address of DISPLAY
;           str = address of the string
;           length = string length
; RETURNS: nothing
; -----------------------------------------------------------------------
    ; type alias:
    mov edx, disp
    dispPtr EQU (DISPLAY PTR [edx])

    mov ecx, length
    add ecx, dispPtr.cursor
    cmp ecx, dispPtr.size   ; check if string fits within the buffer
    JA _overflowError       ; exit if string exceeds screen size

    mov esi, str     ; source address
    mov edi, dispPtr.cursor
    add edi, dispPtr.buffer ; destination address
    mov ecx, length
    add dispPtr.cursor, ecx
    cld
    rep movsb
    JMP endProc

    _overflowError:
        print "Error: String exceeds display bounds!"
        call Crlf

    endProc:
    RET
WriteToDisplay ENDP

; -----------------------------------------------------------------------
ClearDisplay PROC USES ecx esi edi, disp: PTR DISPLAY
; Clears the display buffer by resetting the characters and moving the cursor
; RECEIVES: disp = address of DISPLAY
; RETURNS: nothing
; -----------------------------------------------------------------------
    ; type alias:
    mov esi, disp
    dispPtr EQU (DISPLAY PTR [esi])
    
    mov dispPtr.cursor, 0      ; reset cursor
    ; Clear screen buffer
    mov edi, dispPtr.buffer
    mov ecx, dispPtr.rows
    outerClear:
        push ecx
        mov ecx, dispPtr.cols
        innerClear:
            mov BYTE PTR [edi], NOCHAR
            inc edi
        LOOP innerClear
    pop ecx
    LOOP outerClear
    RET
ClearDisplay ENDP

; -----------------------------------------------------------------------
; -----------------------------------------------------------------------

; -----------------------------------------------------------------------
ClonePlatform PROC USES eax esi edi, dest:PTR PLATFORM, src:PTR PLATFORM
; Copies content from source to destination platform
; RECEIVES: dest = address of destination PLATFORM
;           src = address of source PLATFORM
; RETURNS: nothing
; -----------------------------------------------------------------------
    ; type alias:
    mov edi, dest
    destPtr EQU (PLATFORM PTR [edi])
    mov esi, src
    srcPtr EQU (PLATFORM PTR [esi])

    mov edx, srcPtr.Len
    mov destPtr.Len, edx

    mov edx, srcPtr.offsetFromLeft
    mov destPtr.offsetFromLeft, edx

    mov edx, srcPtr.offsetFromRight
    mov destPtr.offsetFromRight, edx

    RET
ClonePlatform ENDP

; -----------------------------------------------------------------------
ConvertIntToString PROC USES eax edx esi, str: PTR BYTE, value: DWORD
; Converts an integer value to a string representation
; RECEIVES: str = address of output string
;           value = integer value to convert
; RETURNS: length of the resulting string
; -----------------------------------------------------------------------
    LOCAL divisor: DWORD
    mov divisor, 10
    mov eax, value
    mov esi, str
    mov ecx, 0

    _conversionLoop:
        mov edx, 0
        DIV divisor
        add dl, 48
        mov BYTE PTR [esi + ecx], dl
        inc ecx
        CMP eax, 0
        JNE _conversionLoop
    
    _endConversion:
        INVOKE ReverseString, str, ecx
        RET
ConvertIntToString ENDP

; -----------------------------------------------------------------------
ReverseString PROC USES eax ecx edx esi edi, str: PTR BYTE, len: DWORD
; Reverses the characters in a string
; RECEIVES: str = address of the string
;           len = length of the string
; RETURNS: nothing
; -----------------------------------------------------------------------
    LOCAL divisor: DWORD
    mov divisor, 2
    mov eax, len
    mov edx, 0
    DIV divisor
    mov ecx, eax
    mov esi, str
    mov edi, esi
    add edi, len
    dec edi

    reverseLoop:
        mov al, BYTE PTR [esi]
        xchg BYTE PTR [edi], al
        mov BYTE PTR [esi], al
        inc esi
        dec edi
    LOOP reverseLoop
    RET
ReverseString ENDP
END
