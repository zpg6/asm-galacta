## This file implements the functions that display the projectile based on the model

# Include the convenience file so that we save some typing! :)
.include "convenience.asm"
# Include the game settings file with the board settings! :)
.include "game.asm"
# We will need to access the projectile model, include the structure offset definitions
.include "projectile_struct.asm"

# This function needs to be called by other files, so it needs to be global
.globl projectile_draw

.text
# void projectile_draw()
#	1. This function goes through the array of projectiles and for each
#		1.1. Gets its (x, y) coordinates and selected status
#		1.2. Gets a random color to print with
#		1.2. Prints it in the display using function display_fill_rect (display.asm)
#			
projectile_draw:
	enter	v1		# thanks to display_fill_rect (display.asm)
	# Your code goes in here
_projectile_draw_loop:
	jal	projectile_get_element
	lw	t0, projectile_on(v0)
	beqz	t0, _projectile_off
	lw	a0, projectile_x(v0)
	lw	a1, projectile_y(v0)
	li	a2, 1
	li	a3, 2
	# Random color (:
	lw	t0, frame_counter
	li	t1, 7
	div	t0, t0, t1
	mfhi	v1
	jal	display_fill_rect
	
_projectile_off:
	leave	v1		# thanks to display_fill_rect (display.asm)
