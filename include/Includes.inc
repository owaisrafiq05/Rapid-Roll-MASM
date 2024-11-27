INCLUDE MyIrvine32.inc
INCLUDE C:\masm32\include\windows.inc
INCLUDE C:\masm32\include\kernel32.inc
INCLUDE C:\masm32\include\user32.inc
INCLUDE D:\irvine\Macros.inc

.NOLIST

NOCHAR EQU 0h
GAP EQU ' '
NEWLINE EQU 1h
PlatformChar EQU '_'
BallChar EQU 'O'

;||||||||||||||||||||| SCREEN starts |||||||||||||||||||||

; ----------------------------------------------
SCREEN STRUCT
; structure to represent an independent process 
; ----------------------------------------------
    ALIGN DWORD
    
    rows DWORD 0           ; the vertical length
    cols DWORD 0           ; the horizontal length
    off COORD <0,0>        ; the offset from top-left 

    thread HANDLE 0        ; handle to the thread
    buffer HANDLE 0        ; the handle ID for heap 
    bucket DWORD 0         ; the pointer to allocated memory

    cursor DWORD 0            ; the cursor
    area DWORD 0           ; rows * cols

SCREEN ENDS
; ----------------------------------------------

; ----------------------------------------------
CreateScreen PROTO,
             screen: PTR SCREEN,
             callback: DWORD
; Initializes a SCREEN by allocating required resources
; - Allocates an empty buffer in heap
; - Creates a sleeping thread pointing to the given function
; RECEIVES: screen = address of the SCREEN
;           callback = the executing function of SCREEN
; RETURNS: nothing
; ----------------------------------------------

; ----------------------------------------------
DeleteScreen PROTO,
             screen: PTR SCREEN
; Deletes a SCREEN by cleaning up allocated resources
; - frees the allocated buffer from heap
; - closes the running thread
; RECEIVES: screen = address of the SCREEN
; RETURNS: nothing
; ----------------------------------------------

; ----------------------------------------------
PrintScreen PROTO, 
            screen: PTR SCREEN
; Prints the contents of given SCREEN on the active buffer
; RECEIVES: screen = address of SCREEN
; RETURNS: nothing
; ----------------------------------------------

; ----------------------------------------------
WriteScreen PROTO, 
            screen: PTR SCREEN, 
            string: DWORD, 
            strLen: DWORD
; prints the given string on the buffer
; ERROR: when there is no room for the given string
; RECEIVES: screen = address of SCREEN
;           string = address of the string
;           strLen = the length of string (without '\0' null char)
; RETURNS: nothing
; ----------------------------------------------

; ----------------------------------------------
ClearScreen PROTO, 
            screen: PTR SCREEN
; clears the screen by filling buffer with ' ' && by moving cursor to cursor-left
; RECEIVES: screen = address of SCREEN
; RETURNS: nothing
; ----------------------------------------------

;||||||||||||||||||||| SCREEN end |||||||||||||||||||||

;||||||||||||||||||||| OTHER STRUCTS |||||||||||||||||||||

; ----------------------------------------------

PLATFORM STRUCT
; structure to represent platforms
; ----------------------------------------------
	Len DWORD 0                  ; the length of platform 
    offsetFromLeft DWORD COLS    ; distance from left of buffer
    offsetFromRight DWORD 0      ; distance from right of buffer    
PLATFORM ENDS
; ----------------------------------------------

; ----------------------------------------------
BALL STRUCT
; structure to represent ball
; ----------------------------------------------
    row DWORD 0
    col DWORD 0
	Char BYTE BallChar
BALL ENDS

; ----------------------------------------------
; ----------------------------------------------

CopyPlatform PROTO,
             destination:PTR PLATFORM,
             source:PTR PLATFORM
; Copies contents of 'source' to 'destination'
; RECEIVES: destination = address of PLATFORM to copy into
;           source = address of PLATFORM to copy from
; RETURNS: nothing
; ----------------------------------------------

;||||||||||||||||||||| OTHER FUNCTIONS |||||||||||||||||||||

; ----------------------------------------------
IntToString PROTO,
            s: PTR BYTE,
            n: DWORD
; Converts string to integer
; RECEIVES: s = address of string
;           n = Integer
; RETURNS: length of string in ecx
; ----------------------------------------------

; ----------------------------------------------
str_reverse PROTO,
            s: PTR BYTE,
            len: DWORD
; Reverses the string
; RECEIVES: s = address of string
;           len = length of string
; RETURNS: nothing
; ----------------------------------------------

.LIST