## This file implements the functions that display the player based on the model

# Include the convenience file so that we save some typing! :)
.include "convenience.asm"
# Include the game settings file with the board settings! :)
.include "game.asm"
# We will need to access the player model, include the structure offset definitions
.include "player_struct.asm"

# This function needs to be called by other files, so it needs to be global
.globl player_draw

.text
# void player_draw()
#	1. This function gets the address of the player element
#		1.1. Gets its (x, y) coordinates and selected status
#		1.2. Prints it in the display using function display_blit_5x5_trans (display.asm)

player_draw:
	enter
	jal	player_get_element
	lw	a0, player_x(v0)
	lw	a1, player_y(v0)
	la	a2, player_image
	jal	display_blit_5x5_trans
_player_draw_exit:
	leave
