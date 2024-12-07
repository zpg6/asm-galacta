### This file contains the model for entity player

.data
	
	player_struct: .word 30,49
		# spawns at bottom middle by default
.text

# This function needs to be visible outside of this file
.globl player_get_element
# player_get_element()
# returns:
# v0 = address of player
player_get_element:
	la	v0, player_struct
	jr	ra
