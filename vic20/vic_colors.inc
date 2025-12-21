; ---------------------------------------------------------------------------
; colors.inc - Color Definitions for the VIC (VIC-20's Video Interface Chip)
; Digital Rain on the Commodore VIC-20
;

.ifndef ::COLORS_INC_
::COLORS_INC = 1

VIC_COLOR_NORMAL    = $08       ; Bitmask for setting standard colors
VIC_BLACK           = $0
VIC_WHITE           = $1
VIC_RED             = $2
VIC_CYAN            = $3
VIC_PURPLE          = $4
VIC_GREEN           = $5
VIC_BLUE            = $6
VIC_YELLOW          = $7
; extended colors for auxiliary and screen
VIC_ORANGE          = $8
VIC_LIGHT_ORANGE    = $9
VIC_PINK            = $A
VIC_LIGHT_CYAN      = $B
VIC_LIGHT_PURPLE    = $C
VIC_LIGHT_GREEN     = $D
VIC_LIGHT_BLUE      = $E
VIC_LIGHT_YELLOW    = $F

.endif