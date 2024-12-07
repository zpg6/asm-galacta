#vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv#
#vvvvvvvvvvvvvvvvvvvvvvvvv      GAME SETUP	vvvvvvvvvvvvvvvvvvvvvvvvv#
#vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv#


.include "convenience.asm"
.include "game.asm"

#	Defines the number of frames per second: 16ms -> 60fps
.eqv	GAME_TICK_MS		16

.globl frame_counter
.globl _main_exit
.globl _main_game_over
.globl game_over_status # to let things finish before the screen change
.globl player_ammo	# contrlr_projectile needs to dec this when fired
.globl player_score	# contrlr_projectile needs to inc when projectile hits enemy 
.globl player_image	# for drawing
.globl enemy_image	# for drawing
.globl health_image	# for drawing
.globl player_lives	# contrlr_player needs to dec this when enemy hits player or
			# enemy reaches the bottom of the screen
.globl MAX_lives	# contrlr_health needs to know if a life is missing for spawning
.globl n_enemies   	# NOTE: to change # enemies, easily modified in .data below and 
			# modify array_of_enemy_structs in model_enemy.asm 
.globl n_health_orbs   	# NOTE: set to 2 in a hardcoded fashion as well (don't change)


.data
# don't get rid of these, they're used by wait_for_next_frame.
last_frame_time:  .word 0
frame_counter:    .word 0

player_image: .byte
	0 0 3 0 0
	0 3 5 3 0
	0 3 5 3 0
	3 3 3 3 3
	3 0 1 0 3
	
enemy_image: .byte
	6 0 1 0 6
	6 6 6 6 6
	0 6 2 6 0
	0 6 2 6 0
	0 0 6 0 0
	
			
health_image: .byte
	0 7 7 7 0
	7 7 1 7 7
	7 1 1 1 7
	7 7 1 7 7
	0 7 7 7 0
	
projectile_image_HUD: .byte
	0 0 5 0 0
	0 0 4 0 0
	0 0 3 0 0
	0 0 2 0 0
	0 0 1 0 0


	
player_ammo: 	.word 25  # <- Change
MAX_ammo:	.word 25  # <- both
player_score: 	.word 0
n_enemies: 	.word 11
n_health_orbs: 	.word 2
game_over_status: .word 0
welcome_printed_to_term:  .word	0
gameover_printed_to_term: .word	0

# NOTE: changing player lives to be >4 breaks the HUD design
player_lives: 	.word 4 # <- Change
MAX_lives: 	.word 4	# <- both


# for printing messages:
galacta_msg:	.asciiz "Galacta"
by_msg:		.asciiz "by ZPG6"
press_msg:	.asciiz "Press "
any_key_msg:	.asciiz	"any key"
to_play_msg:	.asciiz "to play"
game_msg:	.asciiz "GAME"
over_msg:	.asciiz "OVER"
score_msg:	.asciiz "Score:"
perf_score_msg:	.asciiz "Score!"
perfect_msg:	.asciiz "Perfect"
enemies_msg:	.asciiz "enemies"

# for printing rainbows:
last_color_rainbow:		.word	1
last_first_color_rainbow:	.word	1



#vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv#
#vvvvvvvvvvvvvvvvvvvvvvvvv      MAIN GAME	vvvvvvvvvvvvvvvvvvvvvvvvv#
#vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv#
.text
.globl main
main:		
welcome_loop:					# display the welcome page until the user
						# presses a key
	
	jal	display_welcome			# This will display the welcome text (below)
	jal	display_update_and_clear
	jal     handle_input			# Gather user input, branch to main if:
	lw	t0, down_pressed		
	bnez	t0, _main_loop			# user pressed down
	lw	t0, up_pressed
	bnez	t0, _main_loop			# user pressed up
	lw	t0, left_pressed
	bnez	t0, _main_loop			# user pressed left
	lw	t0, right_pressed
	bnez	t0, _main_loop			# user pressed right
	lw	t0, action_pressed
	bnez	t0, add_extra_projectile	# user pressed B
	jal	wait_for_next_frame
	j	welcome_loop	
add_extra_projectile:
	lw	t0, player_ammo			# if user used B as their any key,
	inc	t0				# give them an extra projectile
	sw	t0, player_ammo			# (they didn't know!)
_main_loop:
						# if all of these rules (branches) are
						# passed, the game goes on!
						
	lw	t0, player_lives		# if the player is out of lives
	blez	t0, _main_game_over		# definitely end the game
	lw	t0, player_ammo
	blez	t0, _main_game_over		# then end the game
	
	# we're still playing, so spawn if it's time
	
	lw	a0, frame_counter		# spawn enemies every 75 frames (1.25s)
	jal	spawn_enemy_sprite
	lw	a0, frame_counter		# every 2 seconds, check for a missing life
	jal	spawn_health_sprite		# if player needs health, spawn the health orb
	
	jal     handle_input			# gather user input
	
game_over_keep_drawing:		
	
	lw	a0, frame_counter		# projectile moves up one pixel every frame
	jal	projectile_update
	lw	a0, frame_counter		# player moves w/ user input every 2 frames
	jal	player_update
	lw	a0, frame_counter		# enemy moves down one pixel every 15 frames
	jal	enemy_update			
	lw	a0, frame_counter		# health orb moves up one pixel every 8 frames
	jal	health_update	

	jal 	display_draw_HUD		# this method (below) draws the entire HUD display
	
	jal	player_draw			# then draw everything...
	jal	projectile_draw
	jal	health_draw
	jal	enemy_draw
	
	
_main_loop_wait:
	jal	display_update_and_clear
	jal	wait_for_next_frame		## This function will block waiting for the next frame!

	lw	t0, game_over_status
	beqz	t0, _main_loop

_main_game_over:
	li	t0, 1
	sw	t0, game_over_status
	jal	are_any_enemies_exploding	# let explosions finish
	bnez	a0, game_over_keep_drawing
	
	jal	projectile_get_element
	lw	t0, 8(v0)			# let projectiles finish
	bnez	t0, game_over_keep_drawing		
_main_exit:	
	jal	display_gameover		# displays the game over screen (below)
	jal	display_update_and_clear
	exit
#vvvvvvvvvvvvvvvvvvvvvvvvv   END MAIN GAME	vvvvvvvvvvvvvvvvvvvvvvvvv#




#vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv#
#vvvvvvvvvvvvvvvvvvvvvvvvv     Wait Method	vvvvvvvvvvvvvvvvvvvvvvvvv#
#vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv#

# --------------------------------------------------------------------------------------------------
# call once per main loop to keep the game running at 60FPS.
# if your code is too slow (longer than 16ms per frame), the framerate will drop.
# otherwise, this will account for different lengths of processing per frame.

wait_for_next_frame:
	enter	s0
	lw	s0, last_frame_time
_wait_next_frame_loop:
	# while (sys_time() - last_frame_time) < GAME_TICK_MS {}
	li	v0, 30
	syscall # why does this return a value in a0 instead of v0????????????
	sub	t1, a0, s0
	bltu	t1, GAME_TICK_MS, _wait_next_frame_loop

	# save the time
	sw	a0, last_frame_time

	# frame_counter++
	lw	t0, frame_counter
	inc	t0
	sw	t0, frame_counter
	leave	s0











#vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv#
#vvvvvvvvvvvvvvvvvvvvvvvvv     DRAW METHODS	vvvvvvvvvvvvvvvvvvvvvvvvv#
#vvvvvvvvvvvvvvvvv   					vvvvvvvvvvvvvvvvv#
#vvvvvvvvvvvvvvvvv  (HUD, Welcome, Game Over, Divider)	vvvvvvvvvvvvvvvvv#
#vvvvvvvvvvvvvvvvv   					vvvvvvvvvvvvvvvvv#
#vvvvvvvvvvvvvvvvv  Basically, the rest of this file	vvvvvvvvvvvvvvvvv#
#vvvvvvvvvvvvvvvvv  is (VERY) hardcoded style nonsense  vvvvvvvvvvvvvvvvv#
#vvvvvvvvvvvvvvvvv  you'll wish you didn't read (lol)	vvvvvvvvvvvvvvvvv#
#vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv#



# --------------------------------------------------------------------------------------------------
# void display_draw_HUD()

display_draw_HUD:
	enter	v1, s0			# v1 = gross, thank the args for "display_fill_rect"
	li 	a0, 1			# a0 = top-left x,
	li 	a1, 58			# a1 = top-left y
	lw 	a2, player_ammo		# a2 = integer to display (can be negative)
	jal	display_draw_int
	lw 	a2, player_score	# a2 = integer to display (can be negative)
	blt	a2, 10, _HUD_one_digit_score
	li 	a0, 23			# a0 = top-left x,
	li 	a1, 58			# a1 = top-left y
	j	_HUD_draw_score
_HUD_one_digit_score:
	li 	a0, 30			# a0 = top-left x,
	li 	a1, 58			# a1 = top-left y
_HUD_draw_score:
	jal	display_draw_int
	li	a0, 13
	li	a1, 58
	la	a2, projectile_image_HUD
	jal	display_blit_5x5_trans
	li 	a0, 18			# a0 = top-left corner x
	li 	a1, 56			# a1 = top-left corner y
	li 	a2, 1			# a2 = width
	li 	a3, 8			# a3 = height
	li 	v1, 7			# v1 = color (use one of the constants above)
	jal 	display_fill_rect
	li 	a0, 38			# a0 = top-left corner x
	li 	a1, 56			# a1 = top-left corner y
	li 	a2, 1			# a2 = width
	li 	a3, 8			# a3 = height
	li 	v1, 7			# v1 = color (use one of the constants above)
	jal 	display_fill_rect
	li 	a0, 0			# a0 = top-left corner x
	li 	a1, 56			# a1 = top-left corner y
	li 	a2, 64			# a2 = width
	li 	a3, 1			# a3 = height
	li 	v1, 7			# v1 = color (use one of the constants above)
	jal 	display_fill_rect
	lw	s0, player_lives	# we have to use a global as a loop counter SORRY!
display_lives_loop:				# i = lives
	blez	s0, exit_display_lives_loop 	# exit if i<=0
	li	t0, 64			# set t0 as width				
	mul	t1, s0, 6  		# t1 = t0*6
	sub	a0, t0, t1 		# a0 = t0 - t2 = x position		
	li 	a1, 58			# a1 = top-left y
	la	a2, player_image	# a2 = pointer to image
	jal 	display_blit_5x5_trans
	dec 	s0			# i--
	j 	display_lives_loop
exit_display_lives_loop:
	leave 	v1, s0			# v1 = gross, thank the args for "display_fill_rect"

	
# --------------------------------------------------------------------------------------------------
# void display_welcome()	

display_welcome:
	enter
	lw	t0, welcome_printed_to_term	# just in case we have errors displaying text
	bnez	t0, already_printed_welcome	# or displaying ints
	print_string	galacta_msg		# extra code to make sure it's only printing once
	print_char	'\n'
	print_string	by_msg
	print_char	'\n'
	print_string	press_msg
	print_char	'\n'
	print_string	any_key_msg
	print_char	'\n'
	print_string	to_play_msg
	print_char	'\n'
	print_char	'\n'
	li	t0, 1
	sw	t0, welcome_printed_to_term
already_printed_welcome:

	# 	Simulator printing begins here
			
	jal	display_draw_border	# how often can you say "experiment gone right" ?
	
	li 	a0, 12			#	a0 = top-left x
	li	a1, 11			#	a1 = top-left y
	la	a2, galacta_msg		#	a2 = pointer to string to print
	jal	display_draw_text	# draw "Galacta"
	li 	a0, 12			#	a0 = top-left x
	li	a1, 19			#	a1 = top-left y
	la	a2, by_msg		#	a2 = pointer to string to print	
	jal	display_draw_text	# draw "By zpg6"
	li 	a0, 18			#	a0 = top-left x
	li	a1, 32			#	a1 = top-left y
	la	a2, press_msg		#	a2 = pointer to string to print	
	jal	display_draw_text	# draw "Press"
	li 	a0, 12			#	a0 = top-left x
	li	a1, 40			#	a1 = top-left y
	la	a2, any_key_msg		#	a2 = pointer to string to print	
	jal	display_draw_text	# draw "Any Key"
	li 	a0, 12			#	a0 = top-left x
	li	a1, 48			#	a1 = top-left y
	la	a2, to_play_msg		#	a2 = pointer to string to print	
	jal	display_draw_text	# draw "To play"
	leave
	
# --------------------------------------------------------------------------------------------------
# void display_gameover()	
# Here lies a very hardcoded design of the game over screen, sorry readers!
# If the user landed a shot with every bullet, print a special screen (:

display_gameover:
	enter
	
	lw	t0, gameover_printed_to_term	# just in case we have errors displaying text
	bnez	t0, already_printed_gameover	# or displaying ints
	print_string	game_msg		# extra code to make sure it's only printing once
	print_char	'\n'
	print_string	over_msg
	print_char	'\n'
	print_string	score_msg
	print_char	'\n'
	lw	t0, player_score
	print_int	t0
	print_char	'\n'
	print_string	enemies_msg
	print_char	'\n'
	print_char	'\n'
	li	t0, 1
	sw	t0, gameover_printed_to_term
already_printed_gameover:
	
	# 	Simulator printing begins here
	
	lw	t0, player_score	#	check for a perfect score
	lw	t1, MAX_ammo 
	beq	t0, t1, perfect_game_screen

# if the player didn't get a perfect score, print the screen
# without the perfect score message (and vertically centered)
	li 	a0, 20			#	a0 = top-left x
	li	a1, 8			#	a1 = top-left y
	la	a2, game_msg		#	a2 = pointer to string to print
	jal	display_draw_text	#	draw "GAME"
	li 	a0, 20			#	a0 = top-left x
	li	a1, 16			#	a1 = top-left y
	la	a2, over_msg		#	a2 = pointer to string to print	
	jal	display_draw_text	#	draw "OVER"
	li	a0, 28			# 	a0 = y for divider
	li	a1, 1			# 	Version 1: player sprite, divider, enemy sprite
	jal	display_draw_divider	#	draw a rainbow divider (:
	li 	a0, 17			#	a0 = top-left x
	li	a1, 37			#	a1 = top-left y
	la	a2, score_msg		#	a2 = pointer to string to print	
	jal	display_draw_text	#	draw "Score:"
	li 	a0, 11			#	a0 = top-left x
	li	a1, 53			#	a1 = top-left y
	la	a2, enemies_msg		#	a2 = pointer to string to print	
	jal	display_draw_text	#	draw "Enemies"
	
	# I horizontally centered the case of a one digit score
	lw 	a2, player_score	#	a2 = integer to display (can be negative)
	blt	a2, 10, _one_digit_imperfect_score
	li 	a0, 26			#	a0 = top-left x,
	li 	a1, 45			#	a1 = top-left y
	jal	display_draw_int
	leave
_one_digit_imperfect_score:
	li 	a0, 29			#	a0 = top-left x,
	li 	a1, 45			#	a1 = top-left y
	jal	display_draw_int
	leave
	
# print things vertically centered if the user had a perfect game
perfect_game_screen:	
	li 	a0, 7			#	a0 = top-left x
	li	a1, 12			#	a1 = top-left y
	la	a2, game_msg		#	a2 = pointer to string to print
	jal	display_draw_text	#	draw "GAME"
	li 	a0, 33			#	a0 = top-left x
	li	a1, 12			#	a1 = top-left y
	la	a2, over_msg		#	a2 = pointer to string to print	
	jal	display_draw_text	#	draw "OVER"
	jal	display_draw_border	#	draw a rainbow border (:
	li 	a0, 11			#	a0 = top-left x
	li	a1, 23			#	a1 = top-left y
	la	a2, perfect_msg		#	a2 = pointer to string to print	
	jal	display_draw_text
	li 	a0, 14			#	a0 = top-left x
	li	a1, 31			#	a1 = top-left y
	la	a2, perf_score_msg	#	a2 = pointer to string to print	
	jal	display_draw_text
	li 	a0, 11			#	a0 = top-left x
	li	a1, 50			#	a1 = top-left y
	la	a2, enemies_msg		#	a2 = pointer to string to print	
	jal	display_draw_text
	
	# I horizontally centered the case of a one digit score
	lw 	a2, player_score	#	a2 = integer to display (can be negative)
	blt	a2, 10, _one_digit_perfect_score
	li 	a0, 26			#	a0 = top-left x,
	li 	a1, 42			#	a1 = top-left y
	jal	display_draw_int
	leave
_one_digit_perfect_score:
	li 	a0, 29			#	a0 = top-left x,
	li 	a1, 42			#	a1 = top-left y
	jal	display_draw_int
	leave

# --------------------------------------------------------------------------------------------------
# void display_draw_divider(a0, a1)	
# a0 = y to center divider at (NOT TOP LEFT!)
# a1 = VERSION #
#
# Version 1: player sprite, divider, enemy sprite
# Version 2: enemy sprite, divider, player sprite
#
# this method just draws a fancy rainbow divider
# with the player and enemy sprites

display_draw_divider:
	enter	s0, s1, s2, s3
				# s0 will be our x counter
	move	s1, a0		# s1 is the divider y from a0
				# s2 will be the color counter
	sub	s3, s1, 2	# s3 will be y=s1-2 for sprite printing
	move	t0, a1		# deal with the version from a1
	beq	t0, 2, _draw_divider_version_2
_draw_divider_version_1:	
	li 	a0, 2			#	a0 = top-left x
	move 	a1, s3			#	a1 = top-left y
	la	a2, player_image	#	a2 = pointer to image
	jal 	display_blit_5x5_trans	#	draw enemy sprite (:
	li 	a0, 57			#	a0 = top-left x
	move 	a1, s3			#	a1 = top-left y
	la	a2, enemy_image		#	a2 = pointer to image
	jal 	display_blit_5x5_trans	#	draw player sprite (:
	b	_draw_divider_sprites_finished
_draw_divider_version_2:	
	li 	a0, 2			#	a0 = top-left x
	move 	a1, s3			#	a1 = top-left y
	la	a2, enemy_image		#	a2 = pointer to image
	jal 	display_blit_5x5_trans	#	draw enemy sprite (:
	li 	a0, 57			#	a0 = top-left x
	move 	a1, s3			#	a1 = top-left y
	la	a2, player_image	#	a2 = pointer to image
	jal 	display_blit_5x5_trans	#	draw player sprite (:
_draw_divider_sprites_finished:
	
	# now for the rainbow divider	
	li	s0, 9		# s0 = x count
				# s1 = y from arg
	li	s2, 5		# s2 = color count (I started w/ blue)
display_draw_divider_loop:	
	bge	s0, 55, end_display_draw_divider
	bgt	s2, 6, reset_s2_color_count
	move	a0, s0
	move	a1, s1
	move	a2, s2
	jal	display_set_pixel
	inc	s0	# this inc the x for printing
	inc	s2	# this just cycles through the rainbow
	j	display_draw_divider_loop
reset_s2_color_count:		
	li	s2, 1
	j	display_draw_divider_loop
end_display_draw_divider:
	leave	s0, s1, s2, s3



# --------------------------------------------------------------------------------------------------
# void display_draw_border()	
#
# draw border around the screen with sprites at corners
# but have the rainbow POP! (:
#

display_draw_border:
	enter	s0, s1, s2, s3
	
	lw	t0, frame_counter
	li	t1, 500			# only update the color changing every second
	div	t0, t0, t1
	mfhi	t0			# t0 = FC % 5
	bnez	t0, _draw_border_no_color_update
	lw	s2, last_color_rainbow
	inc	s2
	bge	s2, 7, _draw_border_color_update_overflow
	j	_draw_border_sprites
_draw_border_color_update_overflow:
	li	s2, 1
	j	_draw_border_sprites
_draw_border_no_color_update:	
	lw	s2, last_first_color_rainbow
# Let's handle version 2 first, we need to change the
# rainbow as the frame_counter changes
_draw_border_sprites:
	li 	a0, 2			#	a0 = top-left x
	li 	a1, 2			#	a1 = top-left y
	la	a2, player_image	#	a2 = pointer to image
	jal 	display_blit_5x5_trans	#	draw enemy sprite (:
	li 	a0, 57			#	a0 = top-left x
	li 	a1, 2			#	a1 = top-left y
	la	a2, enemy_image		#	a2 = pointer to image
	jal 	display_blit_5x5_trans	#	draw player sprite (:
	li 	a0, 57			#	a0 = top-left x
	li 	a1, 57			#	a1 = top-left y
	la	a2, player_image	#	a2 = pointer to image
	jal 	display_blit_5x5_trans	#	draw enemy sprite (:
	li 	a0, 2			#	a0 = top-left x
	li 	a1, 57			#	a1 = top-left y
	la	a2, enemy_image		#	a2 = pointer to image
	jal 	display_blit_5x5_trans	#	draw player sprite (:
				
					# now, draw the TOP rainbow line
_draw_border_TOP:
	li	s0, 9
	li	s1, 4
_draw_border_TOP_loop:
	bge	s0, 55, _draw_border_BOTTOM
	bgt	s2, 6, _draw_border_TOP_loop_reset_color
	move	a0, s0
	move	a1, s1
	sw	s2, last_color_rainbow
	move	a2, s2
	jal	display_set_pixel
	inc	s0	# this inc the x for printing
	inc	s2	# this just cycles through the rainbow
	j	_draw_border_TOP_loop
_draw_border_TOP_loop_reset_color:	
	li	s2, 1
	j	_draw_border_TOP_loop
	
					# now, draw the BOTTOM rainbow line
_draw_border_BOTTOM:
	li	s0, 9
	li	s1, 59
_draw_border_BOTTOM_loop:
	bge	s0, 55, _draw_border_RIGHT
	bgt	s2, 6, _draw_border_BOTTOM_loop_reset_color
	move	a0, s0
	move	a1, s1
	sw	s2, last_color_rainbow
	move	a2, s2
	jal	display_set_pixel
	inc	s0	# this inc the x for printing
	inc	s2	# this just cycles through the rainbow
	j	_draw_border_BOTTOM_loop
_draw_border_BOTTOM_loop_reset_color:	
	li	s2, 1
	j	_draw_border_BOTTOM_loop
		
					# now, draw the RIGHT rainbow line
_draw_border_RIGHT:
	li	s0, 59
	li	s1, 9
_draw_border_RIGHT_loop:
	bge	s1, 55, _draw_border_LEFT
	bgt	s2, 6, _draw_border_RIGHT_loop_reset_color
	move	a0, s0
	move	a1, s1
	sw	s2, last_color_rainbow
	move	a2, s2
	jal	display_set_pixel
	inc	s1	# this inc the y for printing
	inc	s2	# this just cycles through the rainbow
	j	_draw_border_RIGHT_loop
_draw_border_RIGHT_loop_reset_color:	
	li	s2, 1
	j	_draw_border_RIGHT_loop

					# now, draw the LEFT rainbow line
_draw_border_LEFT:
	li	s0, 4
	li	s1, 9
_draw_border_LEFT_loop:
	bge	s1, 55, end_display_draw_border
	bgt	s2, 6, _draw_border_LEFT_loop_reset_color
	move	a0, s0
	move	a1, s1
	sw	s2, last_color_rainbow
	move	a2, s2
	jal	display_set_pixel
	inc	s1	# this inc the y for printing
	inc	s2	# this just cycles through the rainbow
	j	_draw_border_LEFT_loop
_draw_border_LEFT_loop_reset_color:	
	li	s2, 1
	j	_draw_border_LEFT_loop
	
end_display_draw_border:
	lw	t0, last_first_color_rainbow
	inc	t0
	bgt	t0, 6, end_display_draw_border_reset_color
	sw	t0, last_first_color_rainbow
	b	exit_display_draw_border
end_display_draw_border_reset_color:
	li	t0, 1
	sw	t0, last_first_color_rainbow
exit_display_draw_border:
	leave	s0, s1, s2, s3

