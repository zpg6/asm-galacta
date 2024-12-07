## This file implements the functions that display the healths based on the model

# Include the convenience file so that we save some typing! :)
.include "convenience.asm"
# Include the game settings file with the board settings! :)
.include "game.asm"
# We will need to access the health model, include the structure offset definitions
.include "health_struct.asm"

# This function needs to be called by other files, so it needs to be global
.globl health_draw

.text
# void health_draw()
#	1. This function gets the address of the health orb
#		1.1. Gets its (x, y) coordinates and selected status
#		1.2. Prints it in the display using function display_blit_5x5_trans (display.asm)

health_draw:
	enter	s0, s1
	jal	health_get_element
	move	s0, v0
	lw	t0, health_on(s0)
	beqz	t0, _health_draw_exit
	lw	a0, health_x(s0)
	lw	a1, health_y(s0)
	la	a2, health_image
	jal	display_blit_5x5_trans
_health_draw_exit:
	leave	s0, s1
