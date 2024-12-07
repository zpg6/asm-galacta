## This file implements the functions that control the enemies based on the keyboard input

# Include the convenience file so that we save some typing! :)
.include "convenience.asm"
# Include the game settings file with the board settings! :)
.include "game.asm"
# We will need to access the enemy model, include the structure offset definitions
.include "enemy_struct.asm"

# This function needs to be called by other files, so it needs to be global
.globl enemy_update
.globl spawn_enemy_sprite
.globl are_any_enemies_exploding


.data
	# Keeps track of the last frame where we updated the selected enemy
	last_update:	.word	0
	last_spawn:	.word	0
	
.text
# void enemy_update(current_frame)
#   for each enemy	
#	1. Reads whether it is turned on (if so:)
#		1.1. moves the enemy down 1 enemy
#		1.2. if the enemy has reached the bottom
#			1.2.1 Decrement player lives
#			1.2.2 Turn off enemy, set y to 0
#			1.2.3 Decrement player lives
#
enemy_update:
	enter	s0
	
	lw	t0, last_update
	sub	t0, a0, t0		# s1 = frame_counter - last_update
	blt	t0, 15, _enemy_update_exit
	# only update enemies every 15 frames
	# if we make it here, time to update
	sw	a0, last_update		# store frame_count for last update
	
	# we have to move down all enemies that are turned on
	move	s0, zero	# s0=i=0    for enemy[i]
enemy_update_loop:	
	lw	t0, n_enemies
	bge	s0, t0, _enemy_update_exit
	move	a0, s0
	jal	enemy_get_element
	lw	t0, enemy_on(v0)
	beqz	t0, _enemy_update_check_explosions
_enemy_update_turned_on:
	# only update on enemies if we're still playing
	lw	t0, game_over_status
	bnez	t0, _enemy_update_inc_s0
	# move the powered on enemy down a pixel
	lw	t2, enemy_y(v0)
	add	t2, t2, 1
	# Check y bounds
	li	t3, 48
	bgt	t2, t3, _enemy_update_overflow
	sw	t2, enemy_y(v0)
	j	_enemy_update_inc_s0
_enemy_update_check_explosions:
	lw	t0, enemy_expl(v0)
	beqz	t0, _enemy_update_inc_s0
					# if we get here, we have an exploding enemy
	inc	t0			# inc the explosion
	bgt	t0, 6, _enemy_update_end_explosion
	sw	t0, enemy_expl(v0)	# otherwise:
	lw	t0, enemy_y(v0)		
	bgt	t0, 48, _enemy_update_inc_s0	# bgt 48, branch to avoid moving exploding enemy
	inc	t0				# move down 1 frame
	sw	t0, enemy_y(v0)
	j	_enemy_update_inc_s0			
_enemy_update_end_explosion:		# if inc makes enemy_expl >=7:
	move	t0, zero		# set enemy_expl = 0
	sw	t0, enemy_expl(v0)	# set enemy_y = 0
	move	t0, zero
	sw	t0, enemy_y(v0)
	lw	t0, game_over_status		# if the game is over
	beqz	t0, _enemy_update_inc_s0
	jal	are_any_enemies_exploding   
	bnez	v0, _enemy_update_inc_s0	# and no explosions are occuring
	jal	projectile_get_element
	lw	t0, 8(v0)
	bnez	t0, _main_game_over
	j	_main_exit			# well, end the game!
_enemy_update_inc_s0:
	inc	s0
	j	enemy_update_loop
_enemy_update_overflow:
	# Enemy must have reached the bottom
	li	t0, 1
	sw	t0, enemy_expl(v0)	# start its explosion
	move	t0, zero
	sw	t0, enemy_on(v0)	# turn it off
	lw	t0, player_lives	
	dec	t0			# lose a life
	beqz	t0, _main_exit		# it gets buggy if you don't quit and instead try to wait
					# for the explosion to finish, just ignored this detail
	sw	t0, player_lives
	inc	s0			# inc i for enemy[i]
	j	enemy_update_loop	# next enemy
_enemy_update_exit:
	leave	s0


#-----------------------------------------------------------------
# int are_any_enemies_exploding()
#
# RETURNS:	1 if at least one enemy is still exploding
#		0 otherwise
#
are_any_enemies_exploding:
	enter	s0
	move	s0, zero
check_any_explosions_loop:
	lw	t0, n_enemies
	bge	s0, t0, none_exploding
	move	a0, s0
	jal	enemy_get_element
	lw	t0, enemy_expl(v0)
	bnez	t0, yes_one_exploding
	inc	s0
	j	check_any_explosions_loop
yes_one_exploding:
	li	v0, 1
	leave	s0
none_exploding:
	move	v0, zero
	leave 	s0
	

#-----------------------------------------------------------------
# void spawn_enemy_sprite(int frame_counter)
#
# ARG: a0 = frame_counter
# spawns an emeny sprite at a random x pos and y=0
# if 75 frames have passed since the last spawn
		
			
spawn_enemy_sprite:
	enter
	lw	t0, last_spawn
	sub	t0, a0, t0			# exit if 75 frames haven't passed
	blt	t0, 75, exit_spawn_enemy_sprite
	sw	a0, last_spawn			# save the frame if we're spawning		
	jal	enemy_find_unselected
	bltz	v0, exit_spawn_enemy_sprite	# exit if all enemies are spawned
	
	get_random_off_enemy:		#loop to get a random enemy turned off and not exploding
	li	a0, 3			#seed I chose randomly
	li 	a1, 11 			#a1 = upper bound.
    	li 	v0, 42  		#generates the random number.
    	syscall				#a0 is resulting rand num
	jal	enemy_get_element
	lw	t2, enemy_on(v0)
	bnez	t2, get_random_off_enemy
	lw	t2, enemy_expl(v0)
	bnez	t2, get_random_off_enemy
	found_off_enemy_to_spawn:	# actual spawning occurs here			
	li	t1, 1
	sw	t1, enemy_on(v0)	# turn it on
exit_spawn_enemy_sprite:	
	leave
	
	
#-----------------------------------------------------------------
# enemy_index enemy_find_unselected()
#
# RETURNDS: v0=	index of a turned off enemy
#		-1 if all enemies are turned on
# 
	
enemy_find_unselected:
	enter	s0
	# Loop all enemys
	move	s0, zero	# s0 = i = 0
_enemy_find_unselected_loop:
	# If the for exits here, then no enemy is selected
	lw	t0, n_enemies
	bge	s0, t0, _enemy_find_unselected_exit_none
	# Get information about the enemy
	move	a0, s0
	jal	enemy_get_element
	lw	t0, enemy_on(v0)
	# If loop exits here, enemy with index in s0 is selected
	beqz	t0, _enemy_find_unselected_exit_s0
	inc	s0
	j	_enemy_find_unselected_loop
_enemy_find_unselected_exit_none:
	# No enemy is selected, return index -1
	li	v0, -1
	j	_enemy_find_unselected_exit
_enemy_find_unselected_exit_s0:
	# If enemy found, put index in v0
	move	v0, s0
_enemy_find_unselected_exit:
	leave	s0
