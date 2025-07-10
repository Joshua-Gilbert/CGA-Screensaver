;
; CGASCRMIN - Minimal CGA Screensaver TSR for 80286
; Ultra-lightweight memory resident screensaver with color animation
; Optimized for minimal memory usage and maximum compatibility
;
; Features:
; - Tiny memory footprint (~2KB resident)
; - 10-second activation timeout
; - CGA 320x200 4-color animation
; - Color cycling (cyan -> magenta -> white)
; - Instant keyboard deactivation
; - Proper COM file structure with ORG 100h
; - Minimal interrupt handlers for stability
;

.MODEL SMALL
.286

.CODE
ORG 100h              ; COM files start at offset 100h

start:
    ; Initialize variables first (critical for COM files)
    mov     WORD PTR tick_count, 0
    mov     BYTE PTR saver_active, 0
    mov     WORD PTR anim_counter, 0
    mov     BYTE PTR color_index, 1
    mov     BYTE PTR graphics_mode, 0
    
    ; Display installation message
    mov     ah, 02h
    mov     dl, 'C'
    int     21h
    mov     dl, 'G'
    int     21h
    mov     dl, 'A'
    int     21h
    mov     dl, ' '
    int     21h
    mov     dl, 'S'
    int     21h
    mov     dl, 'c'
    int     21h
    mov     dl, 'r'
    int     21h
    mov     dl, 'e'
    int     21h
    mov     dl, 'e'
    int     21h
    mov     dl, 'n'
    int     21h
    mov     dl, 's'
    int     21h
    mov     dl, 'a'
    int     21h
    mov     dl, 'v'
    int     21h
    mov     dl, 'e'
    int     21h
    mov     dl, 'r'
    int     21h
    mov     dl, 13
    int     21h
    mov     dl, 10
    int     21h
    
    ; Get old timer interrupt vector (INT 1Ch, not INT 08h)
    mov     ax, 351Ch
    int     21h
    mov     cs:old_timer_off, bx
    mov     cs:old_timer_seg, es
    
    ; Get old keyboard interrupt vector 
    mov     ax, 3509h
    int     21h
    mov     cs:old_keyboard_off, bx
    mov     cs:old_keyboard_seg, es
    
    ; Install timer handler (INT 1Ch - user timer)
    mov     ax, 251Ch
    push    ds
    mov     dx, cs
    mov     ds, dx
    lea     dx, timer_handler
    int     21h
    pop     ds
    
    ; Install keyboard handler
    mov     ax, 2509h
    push    ds
    mov     dx, cs
    mov     ds, dx
    lea     dx, keyboard_handler
    int     21h
    pop     ds
    
    ; Display success message
    mov     ah, 02h
    mov     dl, 'I'
    int     21h
    mov     dl, 'n'
    int     21h
    mov     dl, 's'
    int     21h
    mov     dl, 't'
    int     21h
    mov     dl, 'a'
    int     21h
    mov     dl, 'l'
    int     21h
    mov     dl, 'l'
    int     21h
    mov     dl, 'e'
    int     21h
    mov     dl, 'd'
    int     21h
    mov     dl, ' '
    int     21h
    mov     dl, '('
    int     21h
    mov     dl, '3'
    int     21h
    mov     dl, '0'
    int     21h
    mov     dl, ' '
    int     21h
    mov     dl, 's'
    int     21h
    mov     dl, 'e'
    int     21h
    mov     dl, 'c'
    int     21h
    mov     dl, ')'
    int     21h
    mov     dl, 13
    int     21h
    mov     dl, 10
    int     21h
    
    ; Calculate TSR size
    mov     dx, OFFSET end_resident
    add     dx, 15
    shr     dx, 4
    
    ; Stay resident
    mov     ax, 3100h
    int     21h

;-----------------------------------------------------------------------------
; Timer handler - INT 1Ch fires 18.2 times per second
; This is the user timer interrupt, less prone to timing issues
;-----------------------------------------------------------------------------
timer_handler PROC FAR
    ; Minimal timer handler - avoid COM file segment issues
    push    ax
    
    ; Simple counter increment (avoid DS manipulation)
    inc     WORD PTR cs:tick_count
    
    ; Check for activation after 30 seconds (546 ticks)
    cmp     WORD PTR cs:tick_count, 546
    jb      timer_animate
    
    ; Only activate if not already active
    cmp     BYTE PTR cs:saver_active, 1
    je      timer_animate
    
    ; Set activation flag (minimal operation)
    mov     BYTE PTR cs:saver_active, 1
    
    ; Also save current video mode here (fast BIOS call)
    push    ax
    mov     ah, 0Fh
    int     10h
    mov     BYTE PTR cs:saved_mode, al
    pop     ax
    
    ; Check if we need to switch to graphics mode
    cmp     BYTE PTR cs:graphics_mode, 1
    je      timer_chain
    
    ; Switch to CGA graphics mode (keep it minimal)
    push    ax
    mov     al, 4
    mov     ah, 0
    int     10h
    
    ; Set CGA palette
    mov     dx, 3D9h
    mov     al, 30h
    out     dx, al
    
    ; Mark graphics mode as active
    mov     BYTE PTR cs:graphics_mode, 1
    
    ; Initialize animation
    mov     BYTE PTR cs:color_index, 1
    mov     WORD PTR cs:anim_counter, 0
    pop     ax
    
    ; Do initial screen fill (keep it simple)
    push    ax
    push    cx
    push    dx
    push    es
    push    di
    
    ; Set up video memory
    mov     ax, 0B800h
    mov     es, ax
    xor     di, di
    
    ; Fill with cyan (color 1)
    mov     al, 55h  ; Cyan pattern
    mov     ah, al
    mov     cx, 4000h
    cld
    rep     stosw
    
    pop     di
    pop     es
    pop     dx
    pop     cx
    pop     ax
    jmp     timer_chain
    
timer_animate:
    ; Handle animation for active screensaver
    cmp     BYTE PTR cs:saver_active, 1
    jne     timer_chain
    
    ; Animate every 18 ticks (~1 second)
    inc     WORD PTR cs:anim_counter
    cmp     WORD PTR cs:anim_counter, 18
    jb      timer_chain
    
    ; Reset animation counter
    mov     WORD PTR cs:anim_counter, 0
    
    ; Quick animation (minimal)
    push    ax
    push    cx
    push    dx
    push    es
    push    di
    
    ; Cycle color
    inc     BYTE PTR cs:color_index
    cmp     BYTE PTR cs:color_index, 4
    jb      @animate_fill
    mov     BYTE PTR cs:color_index, 1
    
@animate_fill:
    ; Set up video memory
    mov     ax, 0B800h
    mov     es, ax
    xor     di, di
    
    ; Create color pattern
    mov     al, BYTE PTR cs:color_index
    mov     ah, al
    shl     ah, 2
    or      al, ah
    mov     ah, al
    shl     ah, 4
    or      al, ah
    mov     ah, al
    
    ; Fill screen
    mov     cx, 4000h
    cld
    rep     stosw
    
    pop     di
    pop     es
    pop     dx
    pop     cx
    pop     ax
    
timer_chain:
    pop     ax
    
    ; Chain to original timer handler
    pushf
    call    DWORD PTR cs:old_timer_off
    iret
timer_handler ENDP

;-----------------------------------------------------------------------------
; Keyboard handler - deactivates screensaver on keypress
;-----------------------------------------------------------------------------
keyboard_handler PROC FAR
    ; Minimal keyboard handler - avoid COM file segment issues
    push    ax
    
    ; Reset activity counter (avoid DS manipulation)
    mov     WORD PTR cs:tick_count, 0
    
    ; If screensaver active, deactivate it
    cmp     BYTE PTR cs:saver_active, 1
    jne     keyboard_chain
    
    ; Restore text mode
    push    ax
    mov     al, BYTE PTR cs:saved_mode
    mov     ah, 0
    int     10h
    pop     ax
    
    ; Reset screensaver flags
    mov     BYTE PTR cs:saver_active, 0
    mov     BYTE PTR cs:graphics_mode, 0
    
keyboard_chain:
    pop     ax
    
    ; Chain to original keyboard handler
    pushf
    call    DWORD PTR cs:old_keyboard_off
    iret
keyboard_handler ENDP

;-----------------------------------------------------------------------------
; Animation procedure - cycles through CGA colors
;-----------------------------------------------------------------------------
animate_screen PROC NEAR
    push    ax
    push    cx
    push    dx
    push    es
    push    di
    
    ; Set up video memory
    mov     ax, 0B800h
    mov     es, ax
    xor     di, di
    
    ; Create color pattern from color_index
    mov     al, BYTE PTR cs:color_index
    mov     ah, al
    shl     ah, 2
    or      al, ah
    mov     ah, al
    shl     ah, 4
    or      al, ah          ; AL = color pattern
    mov     ah, al          ; AX = pattern word
    
    ; Fill screen (8K words for 16KB CGA memory)
    mov     cx, 4000h
    cld
    rep     stosw
    
    ; Cycle through colors (1=cyan, 2=magenta, 3=white)
    inc     BYTE PTR cs:color_index
    cmp     BYTE PTR cs:color_index, 4
    jb      @keep_color
    mov     BYTE PTR cs:color_index, 1  ; Skip black (0)
    
@keep_color:
    pop     di
    pop     es
    pop     dx
    pop     cx
    pop     ax
    ret
animate_screen ENDP

; Variables stored consecutively for DWORD PTR access
old_timer_off       DW      ?
old_timer_seg       DW      ?
old_keyboard_off    DW      ?
old_keyboard_seg    DW      ?
tick_count          DW      0
saver_active        DB      0
saved_mode          DB      ?
anim_counter        DW      0
color_index         DB      1
graphics_mode       DB      0

end_resident:

END start