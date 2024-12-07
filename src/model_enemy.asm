### This file contains the model for entity enemy

.data
	# We don't need this array to be visible outside! So no .globl	
	array_of_enemys_structs:	.word  #x      #y     #on	# explosion	
						0,	0,	0,	0,
					        6,	0,	0,	0,
					       12,	0,	0,	0,
					       18,	0,	0,	0,
					       24,	0,	0,	0,
					       30,	0,	0,	0,
					       36,	0,	0,	0,
					       42,	0,	0,	0,
					       48,	0,	0,	0,
					       54,	0,	0,	0,
					       59,	0,	0,	0
	# Total size = 30 = 10enemys * 3words
	# all enemies initialized to OFF at (x,0) where
	# x is a predetermined value to prevent enemy overlap 
	# (after testing this keeps the game lloking cleaner)

.text

# This function needs to be visible outside of this file
.globl enemy_get_element
# address enemy_get_element(index)
enemy_get_element:
	la	t0, array_of_enemys_structs
				# First we load the address of the beginning of the array
	mul	t1, a0, 16	# Then we multiply the index by 12
				#	(the size of a enemy struct) to calculate the offset
	add	v0, t0, t1	# Finally add the offset to the address of the beginning of the array
	# Now v0 contains the address of the element i of the array
	jr	ra
