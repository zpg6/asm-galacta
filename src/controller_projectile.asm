## This file implements the functions that control the projectiles based on the keyboard input

# Include the convenience file so that we save some typing! :)
.include "convenience.asm"
# Include the game settings file with the board settings! :)
.include "game.asm"
# We will need to access the projectile model, include the structure offset definitions
.include "projectile_struct.asm"
# We will need to access the player model, include the structure offset definitions
.include "player_struct.asm"
# We will need to access the enemy model, include the structure offset definitions
.include "enemy_struct.asm"

# This function needs to be called by other files, so it needs to be global
.globl projectile_update
.globl spawn_projectile_sprite


.data
	# Keeps track of the last frame where we updated the selected projectile
	last_update:	.word	0
	last_spawn:	.word	0
	
.text
# void projectile_update(current_frame)
#	1. Reads whether projectile is turned on (if so:)
#		1.1 moves the projectile up 1 pixel
#		1.2 if the projectile has reached the top
#			1.2.2 Turn off projectile
# 	2. If the projectile is off
#	  ****	2.1 check if B was pressed
#		2.2 if projectile can be fired:
# 			2.2.1  decrement ammo
#			2.2.2  FIRE! 
#	3. If the projectile is colliding with an enemy
#		3.1  turn off enemy and move to y=0
#		3.2  add point to player score
#		3.3  turn off projectile
#	  
# 	****	NOTE:
#		I put in a small bug fix for "double firing" a projectile
# 		now, players must wait 0.5 seconds before firing again
#
#
projectile_update:
	enter
	# normally we check frame count here but
	# projectiles update every frame so no need
	sw	a0, last_update
		
	jal	projectile_get_element
	lw	t0, projectile_on(v0)
	beqz	t0, check_if_projectile_was_fired	# if off, see if action pressed
	lw	t2, projectile_y(v0)
	sub	t2, t2, 1				# if on, move the projectile up a pixel
	ble	t2, 0, _projectile_update_overflow	# Check y bounds
	sw	t2, projectile_y(v0)
	jal	check_for_collisions_w_enemies
	j	_projectile_update_exit
_projectile_update_overflow:				# if projectile reached the top:
	li	t0, 0
	sw	t0, projectile_on(v0)			# turn it off and return
	lw	t0, game_over_status
	beqz	t0, _projectile_update_exit
	lw	t0, player_ammo
	bnez	t0, _projectile_update_exit
	j	_main_exit		
check_if_projectile_was_fired:			# if projectile was fired:
	lw	t0, projectile_on(v0)			# exit if it is already on
	bnez	t0, _projectile_update_exit		
	lw	t0, action_pressed			# exit if user didn't press B
	beqz	t0, _projectile_update_exit
							# READY,
	lw	t1, player_ammo				# AIM, (decrement ammo)
	beqz	t1, _projectile_update_exit
	jal	spawn_projectile_sprite			# and FIRE!
_projectile_update_exit:
	leave


#----------------------------------------------------------------------------------------------------
# void spawn_projectile_sprite()
#
		
			
spawn_projectile_sprite:
	enter
	# this is a small bug fix for "double firing" a projectile
	# now, players must wait 0.5 second before firing again
	lw	t0, last_update	# current frame
	lw	t1, last_spawn 	# frame of last spawn
	sub	t1, t0, t1
	blt	t1, 30, exit_spawn_projectile_sprite
	sw	t0, last_spawn
	
	# Decrement ammo
	lw	t0, player_ammo
	sub	t0, t0, 1
	sw	t0, player_ammo
	
	# Get projectile address and store in t1
	jal	projectile_get_element
	move	t1, v0
	
	# turn it on
	li	t0, 1
	sw	t0, projectile_on(t1)
	
	# Get player address and store in t2
	jal	player_get_element
	move	t2, v0
	
	# set its y right above player
	lw	t0, player_y(t2)
	sub	t0, t0, 1
	sw	t0, projectile_y(t1)
	
	# set x as player_x+2
	lw	t0, player_x(t2)
	add	t0, t0, 2
	sw	t0, projectile_x(t1)
exit_spawn_projectile_sprite:	
	leave
	
	
	


#----------------------------------------------------------------------------------------------------
# void check_for_collisions_w_enemies(a0)
#	a0 = proj x

check_for_collisions_w_enemies:
	enter	s0, s1, s2, s3
	
	move	s3, a0		# s3 = proj_x
	move	s0, zero	# i = 0
	lw	s1, n_enemies
collisions_loop:
	bge	s0, s1, end_check_for_collisions_w_enemies
	
	move	a0, s0
	jal	enemy_get_element
	move	s2, v0
	
	jal	projectile_get_element
	move	s3, v0
	
	lw	a0, enemy_x(s2)
	lw	a1, enemy_y(s2)
	lw	a2, projectile_x(s3)
	lw	a3, projectile_y(s3)
	lw	t0, enemy_on(s2)
	bnez	t0, commence_proj_collisions_check
	inc	s0
	j	collisions_loop
commence_proj_collisions_check:	
	jal	is_in_box
	bnez	v0, handle_enemy_defeated
	inc	s0
	j	collisions_loop
handle_enemy_defeated:
	move	t0, zero
	sw	t0, enemy_on(s2)
	li	t0, 1
	sw	t0, enemy_expl(s2)
	move	t0, zero
	sw	t0, projectile_on(s3)
	lw	t0, player_score
	add	t0, t0, 1
	sw	t0, player_score
end_check_for_collisions_w_enemies:
	leave 	s0, s1, s2, s3



#----------------------------------------------------------------------------------------------------
# int is_in_box( a0, a1, a2, a3 )
#	a0 = enemy x (left)
#	a1 = enemy y (top)
#	a2 = proj x
#	a3 = proj y

is_in_box:
	move	t0, zero	# i = 0
	move	t1, zero	# j = 0
	# if a2 is a0 thru a0 +4
box_x_loop:
	bge	t0, 5, not_found_in_box
	add	t2, a0, t0
	beq	t2, a2, box_y_loop
	inc	t0
	j 	box_x_loop
	# AND if a3 is a1 thru a1 +4
box_y_loop:	
	bge	t1, 5, not_found_in_box
	add	t3, a1, t1
	beq	t3, a3, found_in_box
	inc	t1	
	j 	box_y_loop
found_in_box:
	li	v0, 1	
	jr	ra
not_found_in_box:
	move	v0, zero	
	jr	ra


