### This file contains the model for entity health

.data
	# We don't need this array to be visible outside! So no .globl	
	health_struct:			.word  #x      #y     #on	
						0,	0,	0
	# Total size = 3 = 1health orb * 3words
	# health orbs initialized to OFF at (0,0)
	# inside its spawn method, a random x is assigned

.text

# This function needs to be visible outside of this file
.globl health_get_element
# address health_get_element()
health_get_element:
	la	v0, health_struct
	jr	ra
