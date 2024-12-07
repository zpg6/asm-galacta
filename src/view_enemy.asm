## This file implements the functions that display the enemys based on the model

# Include the convenience file so that we save some typing! :)
.include "convenience.asm"
# Include the game settings file with the board settings! :)
.include "game.asm"
# We will need to access the enemy model, include the structure offset definitions
.include "enemy_struct.asm"

# This function needs to be called by other files, so it needs to be global
.globl enemy_draw

.data

expl_1:	.byte
	6 0 1 0 6
	6 6 6 6 6
	0 6 1 3 0
	0 2 1 6 0
	0 0 6 0 0

expl_2:	.byte
	0 0 1 3 6
	6 2 1 6 6
	0 1 1 1 0
	0 6 1 2 0
	0 3 6 0 0
	
expl_3:	.byte
	0 6 3 0 3
	0 2 1 2 0
	3 1 3 1 3
	6 2 1 2 6
	3 0 6 3 0
	
expl_4:	.byte
	0 0 3 0 0
	0 2 2 0 0
	0 2 1 0 3
	6 0 2 0 0
	3 0 6 3 0
	
expl_5:	.byte
	0 0 0 0 0
	0 0 2 0 0
	0 2 1 0 0
	0 0 2 0 0
	6 0 6 3 0
	
expl_6:	.byte
	0 0 0 0 0
	0 0 0 0 0
	0 0 0 0 0
	0 0 2 3 0
	0 2 6 0 0

.text
# void enemy_draw()
#	1. This function goes through the array of enemys and for each
#		1.1. Gets its (x, y) coordinates and selected status
#		1.2. If turned on, prints it in the display using function display_blit_5x5_trans (display.asm)
#			
enemy_draw:
	enter	s0
	# Your code goes in here
	move	s0, zero
_enemy_draw_loop:
	lw	t0, n_enemies
	bge	s0, t0, _enemy_draw_exit	# for all enemies:
	move	a0, s0
	jal	enemy_get_element
	lw	t0, enemy_on(v0)		# if it's off,
	beqz	t0, _enemy_draw_check_explosion	# is it exploding?
	lw	a0, enemy_x(v0)
	lw	a1, enemy_y(v0)
	la	a2, enemy_image
	jal	display_blit_5x5_trans		# otherwise draw it
_enemy_draw_check_explosion:
	lw	t0, enemy_expl(v0)		# if its off and not expld,
	beqz	t0, _enemy_off_inc		# inc to next enemy in loop
	move	a0, t0				
	jal	get_explosion_image
	move	a2, v0
	move	a0, s0
	jal	enemy_get_element
	lw	a0, enemy_x(v0)			# draw the explosion
	lw	a1, enemy_y(v0)
	jal	display_blit_5x5_trans
_enemy_off_inc:
	inc	s0
	j	_enemy_draw_loop
_enemy_draw_exit:
	leave	s0


#---------------------------------------------------
# address get_explosion_image(a0)
# a0 = explosion frame to print

get_explosion_image:
	beq	a0, 1, get_explosion_1
	beq	a0, 2, get_explosion_2
	beq	a0, 3, get_explosion_3
	beq	a0, 4, get_explosion_4
	beq	a0, 5, get_explosion_5
	beq	a0, 6, get_explosion_6
get_explosion_1:
	la	v0, expl_1
	jr	ra
get_explosion_2:
	la	v0, expl_2
	jr	ra
get_explosion_3:
	la	v0, expl_3
	jr	ra
get_explosion_4:
	la	v0, expl_4
	jr	ra
get_explosion_5:
	la	v0, expl_5
	jr	ra
get_explosion_6:
	la	v0, expl_6
	jr	ra
