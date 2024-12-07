## This file implements the functions that control the healths based on the keyboard input

# Include the convenience file so that we save some typing! :)
.include "convenience.asm"
# Include the game settings file with the board settings! :)
.include "game.asm"
# We will need to access the health model, include the structure offset definitions
.include "health_struct.asm"

# This function needs to be called by other files, so it needs to be global
.globl health_update
.globl spawn_health_sprite


.data
	# Keeps track of the last frame where we updated the selected health
	last_update:	.word	0
	last_spawn:	.word	0
	
.text
# void health_update(current_frame)
#   for each health	
#	1. Reads whether it is turned on (if so:)
#		1.1. moves the health down 1 health
#		1.2. if the health has reached the bottom
#			1.2.1 Decrement player lives
#			1.2.2 Turn off health, put away at (-10,10)
#			1.2.3 Decrement player lives
#	2. Every 60 frames (use the input): If the user pressed the action button (B) the player FIRES A PROJECTILE.
#		You may need some variables!
health_update:	
	enter
	lw	t0, last_update
	sub	t0, a0, t0		# s1 = frame_counter - last_update
	blt	t0, 8, _health_update_exit
	# only update health every 8 frames (twice as fast as enemies)
	# if we make it here, time to update
	sw	a0, last_update		# store frame_count for last update
	
	
	jal	health_get_element
	lw	t0, health_on(v0)
	beqz	t0, _health_update_exit		# return if health orb is off
	lw	t0, health_y(v0)
	inc	t0				# move it down a pixel
	bgt	t0, 49, _health_overflow	# check if it hit the bottom
	sw	t0, health_y(v0)
	b	_health_update_exit	
_health_overflow:
	move	t0, zero
	sw	t0, health_on(v0)		# if it hit bottom, turn off
	move	t0, zero
	sw	t0, health_y(v0)		# and set y to 0
_health_update_exit:
	leave


#----------------------------------------------------------------------------------------------------		
		
			
spawn_health_sprite:
	enter
	# return if player has all lives
	lw	t0, player_lives
	lw	t1, MAX_lives
	bge	t0, t1, exit_spawn_health_sprite
	
	# return if orb is on
	jal	health_get_element
	lw	t0, health_on(v0)
	bnez	t0, exit_spawn_health_sprite
	# orb must be off
	# turn it on
	li	t1, 1
	sw	t1, health_on(v0)
	
	# give it a random x (0 to 58)
	lw	t0, frame_counter
	li	t1, 58
	div	t0, t0, t1
	mfhi	t1
	sw	t1, health_x(v0)
	
	# set its y to 0 (failsafe)
	move	t1, zero
	sw	t1, health_y(v0)
	
exit_spawn_health_sprite:	
	leave
	