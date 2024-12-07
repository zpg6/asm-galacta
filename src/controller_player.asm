## This file implements the functions that control the players based on the keyboard input

# Include the convenience file so that we save some typing! :)
.include "convenience.asm"
# Include the game settings file with the board settings! :)
.include "game.asm"
# We will need to access the player model, include the structure offset definitions
.include "player_struct.asm"
# We will need to access the enemy model, include the structure offset definitions
.include "enemy_struct.asm"
# We will need to access the health model, include the structure offset definitions
.include "health_struct.asm"

# This function needs to be called by other files, so it needs to be global
.globl player_update


.data
	# Keeps track of the last frame where we updated the selected player
	last_update:	.word	0
.text
# void player_update(current_frame)
#	1. Reads the state of the keyboard buttons and move the selected player accordingly
#		1.1. The player moves up to one player up/down and up to one player left/right according to the keyboard input.
#		1.2. The player must not leave the bounds of the display (check the .eqv in game.asm)
#	2. Every 60 frames (use the input): If the user pressed the action button (B) the player FIRES A PROJECTILE.
#	3. Refers to methods below that check for and handle collisions:
#		3.1  void check_for_player_collisions_w_enemies()
#		3.1  void check_for_player_collision_w_health()

player_update:
	enter
	
	lw	t0, last_update
	sub	t0, a0, t0		# s1 = frame_counter - last_update
	blt	t0, 2, _player_update_exit
	# only update player every 2 frames
	# if we make it here, time to update
	sw	a0, last_update		# store frame_count for last update
	
	
	jal	player_get_element
	move	t0, v0
	# Now lets check user input
	# Start with up/down to update the y coordinate
	lw	t1, up_pressed
	lw	t2, player_y(t0)
	sub	t2, t2, t1
	lw	t1, down_pressed
	add	t2, t2, t1
	# Check y bounds
	bltz	t2, _player_update_skip_y
	bge	t2, 49, _player_update_skip_y
	sw	t2, player_y(t0)
_player_update_skip_y:

	# Now with left/right to update the x coordinate
	lw	t1, left_pressed
	lw	t2, player_x(t0)
	sub	t2, t2, t1
	lw	t1, right_pressed
	add	t2, t2, t1
	# Check x bounds
	bltz	t2, _player_update_skip_x
	bge	t2, 60, _player_update_skip_x
	sw	t2, player_x(t0)
_player_update_skip_x:

	# Now with action to update the selected player
	# Check if it is time for the next update
	lw	t1, last_update
	addi	t1, t1, 60
	bge	t1, s0, _player_update_no_action
	# It is time! do it, do it now! If the action was pressed...
	lw	t1, action_pressed
	beqz	t1, _player_update_no_action
_player_update_no_overflow:
	
	lw 	t0, player_ammo
	blez	t0, _player_update_no_action	# if player is out of ammo, skip
	
_player_update_no_action:
	jal	check_for_player_collisions_w_enemies	# enemy collision takes
	jal	check_for_player_collision_w_health	# precedence over health orb
_player_update_exit:	
	leave

#-----------------------------------------------------------------
# void check_for_player_collisions_w_enemies()
#
# checks player position against all turned on enemies for overlapping sprites
# handles all outcomes of such a collision and returns nothing


check_for_player_collisions_w_enemies:
	enter	s0
	
	move	s0, zero	# i = 0
player_collisions_loop:
	lw	t0, n_enemies	# loop to check each enemy
	bge	s0, t0, end_check_for_player_collisions_w_enemies
	move	a0, s0
	jal	enemy_get_element
	move	t3, v0
	jal	player_get_element
	move	t2, v0
	lw	a0, player_x(t2)	# get player and enemy coords
	lw	a1, player_y(t2)	# for an overlap check
	lw	a2, enemy_x(t3)
	lw	a3, enemy_y(t3)
	lw	t0, enemy_on(t3)	# only check if the enemy is on
	bnez	t0, commence_collision_check
	inc	s0			# otherwise, i++ and loop again
	j	player_collisions_loop
commence_collision_check:
	jal	do_boxes_overlap	# method below abstractly checks for collision
	bnez	v0, handle_player_defeated	# if collided, handle below
	inc	s0			# otherwise, i++ and loop again
	j	player_collisions_loop
handle_player_defeated:			# if collision occurs:
	li	t0, 1
	sw	t0, enemy_expl(t3)	# explode the enemy
	move	t0, zero
	sw	t0, enemy_on(t3)	# turn enemy off
	li	t0, 30
	sw	t0, player_x(t2)	# move player to center (x)
	li	t0, 49
	sw	t0, player_y(t2)	# move player to bottom (y)
	lw	t0, player_lives
	dec	t0			# dec player_lives
	beqz	t0, _main_exit
	sw	t0, player_lives
end_check_for_player_collisions_w_enemies:
	leave 	s0
	
#-----------------------------------------------------------------
# void check_for_player_collision_w_health()
#
# checks player position against the health orb (if on) for overlapping
# handles all outcomes of such a collision and returns nothing

check_for_player_collision_w_health:
	enter
	jal	health_get_element	# exit if health orb is turned off
	move	t2, v0
	lw	t0, health_on(t2)
	beqz	t0, end_check_for_player_collision_w_health
					# if orb is on:
	jal	player_get_element
	move	t3, v0
	
	lw	a0, health_x(t2)	# get health orb and player coords
	lw	a1, health_y(t2)	# for an overlap check
	lw	a2, player_x(t3)
	lw	a3, player_y(t3)
	jal	do_boxes_overlap	# check if sprites overlap
	beqz	v0, end_check_for_player_collision_w_health
handle_player_gets_life:		# if player did collide with health orb
	move	t0, zero
	sw	t0, health_on(t2)	# turn the orb off
	move	t0, zero
	sw	t0, health_y(t2)	# move the orb to the top
	lw	t0, player_lives
	inc	t0			# inc player_lives
	sw	t0, player_lives
end_check_for_player_collision_w_health:
	leave


#-----------------------------------------------------------------
# int check_for_player_collision_w_health(a0, a1, a2 , a3)
#
# ARGS:		a0 = sprite1_x, a1 = sprite1_y, a2 = sprite2_x, a3 = sprite2_y
# 
# RETURNS:	v0 = 1 if overlapping, 0 otherwise
#
# sprites checked with this method are assumed to be 5x5
# and any intersection of the 5x5 boxes will return v0=1
# ignores transparency!!!


do_boxes_overlap:
	enter	s0, s1
	li	s0, -4	# i = -4	# chose to use s0 = i and s1 = j versus
	li	s1, -4	# j = -4	# resetting the counter for clarity
					# in a weird geometry algoritmn
check_box_x_loop:				# (x-coord loop) 
	bge	s0, 5, not_overlapping		# if a2 in range [a0-4, a0+4]:
	add	t1, a0, s0			# exits method if no x overlap
	beq	t1, a2, check_box_y_loop	# if overlap found, check y
	inc	s0
	j 	check_box_x_loop
check_box_y_loop:				# (y-coord loop)
	bge	s1, 5, not_overlapping		# AND if a3 in range [a1-4, a1+4]:
	add	t1, a1, s1			# exits if no y overlap 
	beq	t1, a3, boxes_overlap		# determines success if y also overlaps
	inc	s1	
	j 	check_box_y_loop
boxes_overlap:
	li	v0, 1		# return v0 = 1 for overlapping sprites
	leave	s0, s1
not_overlapping:
	move	v0, zero	# return v0 = 0 otherwise
	leave	s0, s1
end_do_boxes_overlap:

