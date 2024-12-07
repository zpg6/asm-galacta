### This file contains the model for entity projectile

.data
	# We don't need this array to be visible outside! So no .globl	
	projectile_struct:	.word  #x      #y     #on	
					0,	0,	0
					    
	# Total size = 3 = 1projectiles * 3words
	# projectile initialized to OFF at (0,0)

.text

# This function needs to be visible outside of this file
.globl projectile_get_element
# address projectile_get_element()
projectile_get_element:
	la	v0, projectile_struct
	jr	ra
