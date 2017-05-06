#Name: Chan Nok Hin
#ID: 20349103
#Email: nhchana@conncct.ust.hk
#Lab Section: LA3
#Bonus Yes


#=====================#
# THE SPACESHIP GAME #
#=====================#

#---------- DATA SEGMENT ----------
	.data

speed:	.word	8

spaceship:	.word 384 384 1 10 0	# 5 words for 5 properties of the ship: (in this order) top-left corner's x-coordinate, top-left corner's y-coordinate, image index, speed_h, speed_v
spaceshipSize: .word 32	32		# spaceship image's width and height

aerolites:	.word -1:500		# 5 words for each aerolite: (in this order) top-left corner's x-coordinate, top-left corner's y-coordinate, image index, speed, Hit point  
aeroliteSize: .word 60 60			# aerolite image's width and height

fuels:	.word -1:500			# 5 words for each fuel: (in this order) top-left corner's x-coordinate, top-left corner's y-coordinate, image index, speed, status
fuelSize: .word 32 32			# fuel image's width and height

bombs:	.word 0 0 0 0 0 0 		# 6 words for the bomb: (in this order) top-left corner's x-coordinate, top-left corner's y-coordinate, image index, speed_x, speed_y, status  
bombSize: .word 15 15			# bomb image's width and height


msg0:	.asciiz "Enter the number of fuels (max. limit of 10) you want? "
msg1:	.asciiz "Invalid size!\n"
msg2:	.asciiz "Enter the seed for random number generator? "
msg3:	.asciiz "You won!"
msg4:	.asciiz "You lost!"
newline: .asciiz "\n"

title: .asciiz "The Spaceship Game"
# game image array constructed from a string of semicolon-delimited image files
# array index		0		1		  2	             3	                                    4	               5		6                 7		8	     9	         10		  11
images: .asciiz "background.jpg;spaceship_right.png;spaceship_left.png;aerolite_right.png;aerolite_left.png;aerolite_d_right.png;aerolite_d_left.png;fuel_right.png;fuel_left.png;bomb.png;spaceship_up.png;spaceship_down.png"

# The following registers are used throughout the program for the specified purposes,
# so using any of them for another purpose must preserve the value of that register first: 
# s0 -- total number of fuels in a game level
# s1 -- total number of aerolites in a game level
# s2 -- current game score
# s3 -- current game level
# s4 -- status flag of bomb in a game level
# s6 -- starting time of a game iteration

#---------- TEXT SEGMENT ----------
	.text
	


main:
#-------(Start main)------------------------------------------------
	jal setting				# the game setting

	ori $s3, $zero, 1			# level = 1
	ori $s2, $zero, 0			# score = 0

	
	jal createGame				# create the game 

	#----- initialize game objects and information, and create game screen ---
	jal playSound
	jal createGameObjects
	jal setGameStateOutput

	jal initgame				# initalize the first game level

	jal updateGameObjects
	jal createGameScreen
	#-------------------------------------------------------------------------
	
main_obj:
	jal getCurrentTime			# Step 1 of the game loop 
	ori $s6, $v0, 0    			# v1 keeps the iteration starting time

	jal removeObjects			# Step 2 of the game loop
	jal processInput			# Step 3 of the game loop
	jal collisionDetectionSpaceship		# Step 4 of the game loop
	jal collisionDetectionBomb		# Step 5 of the game loop
	jal updateDamagedImages			# Step 6 of the game loop

	jal isLevelOver				# Step 7 of the game loop
	bgtz $v0, main_next_level		# the player wins the current level
	bltz $v0, main_game_lose		# the player loses the game
	
	jal moveSpaceship 			# Step 8 of the game loop
	jal moveAeroliteFuel			# Step 9 of the game loop
	jal moveBomb				# Step 10 of the game loop

updateScreen:
	jal updateGameObjects			# Step 11 of the game loop
	jal redrawScreen

	ori $a0, $s6, 0				# Step 12 of the game loop
	li $a1, 30
	jal pauseExecution
	j main_obj
	
main_next_level:	
	li $t0, 3				# the last level is 3
	beq $s3, $t0, main_game_win 		# the last level and hence the whole game is won 
	addi $s3, $s3, 1			# increment level
	addi $s0, $s0, 3			# fuel_num = fuel_num + 3
	addi $s1, $s0, 3			# aerolite_num = fuel_num + 3
	j main_continue

main_continue:
	#----- re-initialize game objects and information for next level --------
	jal createGameObjects
	jal setGameStateOutput
	jal initgame				# initialize the next game level
	#-------------------------------------------------------------------------
	j updateScreen

main_game_win: 
	li $v0, 100	
	li $a0, 18
	li $a1, 4
	syscall
	jal setGameWinningOutput		# Game over, and output a game winning message
	jal redrawScreen   
	j end_main

main_game_lose: 
	li $v0, 100	
	li $a0, 18
	li $a1, 3
	syscall
	jal setGameLosingOutput			# Game over, and output a game losing message
	jal redrawScreen   
	j end_main


#-------(End main)--------------------------------------------------
end_main:
# Terminate the program
#----------------------------------------------------------------------
li $v0, 100	
li $a0, 10
syscall
ori $v0, $zero, 10
syscall

# Function: Setting up fuel number and random seed from the player
setting:
#===================================================================
	addi $sp, $sp, -4
	sw $ra, 0($sp)

setting_fuels:
	li $t0, 10				# Max number of fuels.
	
	la $a0, msg0				# Enter the number of fuels
	li $v0, 4
	syscall
	
	li $v0, 5				# cin >> fuel_num
	syscall
	or $s0, $v0, $zero

	slt $t4, $t0, $s0
	bne $t4, $zero, setting_overlimit	# input fuel_num should be larger than 1 but less or equal to max nuber of fuels
	slti $t4, $s0, 1
	bne $t4, $zero, setting_overlimit
	addi $s1, $s0, 3			# aerolite_num = fuel_num + 3
	j setting_randomseed

setting_overlimit:				# over limiation of max number of fuels
	la $a0, msg1
	ori $v0, $zero, 4
	syscall
	j setting_fuels

setting_randomseed:
	la $a0, newline
	ori $v0, $zero, 4
	syscall

	la $a0, msg2				# Enter the seed for random number generator?
	ori $v0, $zero, 4
	syscall
	
	ori $v0, $zero, 5			# cin >> seed
	syscall

	ori $a0, $v0, 0				# set the seed of the random number generator
	jal setRandomSeed    

	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra

#---------------------------------------------------------------------------------------------------------------------
# Function: initalize to a new level
# Generate random location and speed for aerolites and fuels
# Set the image index of aerolites and fuels according to their own moving direction
# Set the Hit point of the aerolites and fuels
# Set the available number of the bombs
# Initialize the image index and speed of the bombs

initgame: 			
#===================================================================
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	li $t0, 0
	li $t4, 0
	la $t2, aerolites
	la $t3, fuels
	la $t5, bombs
	
	li $t6, -20
	sw $t6, 0($t5)
	sw $t6, 4($t5)
	li $t6, 9
	sw $t6, 8($t5)
	li $t6, 1
	sw $t6, 20($t5)
	li $t6, 16
	sw $t6, 12($t5)

initLoop:		
	beq $t0, $s1, nextloop

	li $t1, 0
	sw $t1, 0($t2)	
	
	addi $a0, $zero, 740	#generate random between 0 to 800
	jal randnum	
	
	add $t1, $zero, $v0	#get the random number from v0 and store in t1
	sw $t1, 4($t2)
	
	li $t1, 3
	sw $t1, 8($t2)
	
	addi $a0, $zero, 10
	jal randnum
	add $t1, $zero, $v0
	addi $t1, $t1, 1
	sw $t1, 12($t2)
	
	li $t1, 10
	sw $t1, 16($t2)
	
	addi $t0, $t0, 1
	addi $t2, $t2, 20
	
	j initLoop
nextloop:
	beq $t4, $s0, endloop	
	
	li $t1, 0
	sw $t1, 0($t3)	
	
	addi $a0, $zero, 768	#generate random between 0 to 800
	jal randnum	
	
	add $t1, $zero, $v0	#get the random number from v0 and store in t1
	sw $t1, 4($t3)
	
	li $t1, 7
	sw $t1, 8($t3)
	
	addi $a0, $zero, 10
	jal randnum
	add $t1, $zero, $v0
	addi $t1, $t1, 1
	sw $t1, 12($t3)
	
	li $t1, 1
	sw $t1, 16($t3)
	
	addi $t4, $t4, 1
	addi $t3, $t3, 20
	
	j nextloop
endloop:
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	
	jr $ra
############################
# Please add your code here#
############################

#---------------------------------------------------------------------------------------------------------------------
# Function: remove the destroyed aerolites and collected fuels from the screen

removeObjects:				
#===================================================================

	# remove aerolites 
	la $t6, aerolites 
	li $t7, 0
remove_aerolite_loop:
	lw $t5, 8($t6)
	slti $t5, $t5, 0
	bne $t5, $zero, remove_aerolite_loop_continue	# skip removed aerolites 
	lw $t5, 16($t6)
	bne $t5, $zero, remove_aerolite_loop_continue	# skip non-destroyed aerolites 
	li $t5, -1
	sw $t5, 8($t6)					# remove aerolite 

remove_aerolite_loop_continue:	
	addi $t7, $t7, 1 
	addi $t6, $t6, 20
	bne $t7, $s1, remove_aerolite_loop
	
	# remove fuels	
	la $t6, fuels
	li $t7, 0
remove_fuel_loop:
	lw $t5, 8($t6)
	slti $t5, $t5, 0
	bne $t5, $zero, remove_fuel_loop_continue	# skip removed fuels
	lw $t5, 16($t6)
	bne $t5, $zero, remove_fuel_loop_continue	# skip non-destroyed fuels
	li $t5, -1
	sw $t5, 8($t6)					# remove fuel

remove_fuel_loop_continue:	
	addi $t7, $t7, 1 
	addi $t6, $t6, 20
	bne $t7, $s0, remove_fuel_loop
	
	jr $ra
#---------------------------------------------------------------------------------------------------------------------
# Function: collision detection between the spaceship and a aerolite or fuel,
# and then post-processing by:
# changing the hit aerolite or fuel's Hit point and change the score accordingly
# setting the bomb to be avaliable

collisionDetectionSpaceship:
#===================================================================

############################
# Please add your code here#
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	la $t8, spaceship
	la $t9, fuels
	
	lw $a0, 0($t8)
	lw $a1, 4($t8)
	li $a2, 32
	li $a3, 32
	
	li $t6, 0
	
checkLoop:
	beq $t6, $s0, endCheck
		
	lw $t0, 0($t9)
	lw $t1, 4($t9)
	li $t2, 32
	li $t3, 32
	lw $t7, 16($t9)
	
	addi $t6, $t6, 1
	addi $t9, $t9, 20 
			
	beq $t7, $zero, checkLoop		
			
	jal isIntersected
	bne $v0, $zero, collidedSpaceFuel
	
	j checkLoop	
endCheck:
	la $t8, spaceship
	la $t9, aerolites
	
	lw $a0, 0($t8)
	lw $a1, 4($t8)
	li $a2, 32
	li $a3, 32
	
	li $t6, 0
	
checkLoop3:
	beq $t6, $s1, endCheck3
	lw $t0, 0($t9)
	lw $t1, 4($t9)
	li $t2, 60
	li $t3, 60
	lw $t7, 16($t9)
	
	addi $t6, $t6, 1
	addi $t9, $t9, 20 	

	beq $t7, $zero, checkLoop3
	jal isIntersected
	bne $v0, $zero, main_game_lose
	
	j checkLoop3	
	
endCheck3:
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra	
############################	
collidedSpaceFuel:
	# collide with fuels, play the sound effect		
	li $v0, 100	
	li $a0, 18
	li $a1, 2
	syscall

	subi $t9, $t9, 20
	 
	li $t8, -1
	sw $t8, 8($t9) 

	li $t8, 0
	sw $t8, 16($t9)
	
	addi $t9, $t9, 20 

	j checkLoop	


#---------------------------------------------------------------------------------------------------------------------
# Function: collision detection between the bomb and a aerolite or fuel,
# and then post-processing by:
# changing the hit aerolite or fuel's Hit point and change the score accordingly
# setting the bomb to be avaliable

collisionDetectionBomb:				
#===================================================================
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	la $t8, aerolites
	la $t9, bombs
		
	li $t6, 0
checkLoop2:
	beq $t6, $s1, endCheck2

	lw $a0, 0($t9)
	lw $a1, 4($t9)
	li $a2, 16
	li $a3, 16
			
	lw $t0, 0($t8)
	lw $t1, 4($t8)
	li $t2, 60
	li $t3, 60
	lw $t7, 16($t8)

	addi $t6, $t6, 1
	addi $t8, $t8, 20 
	
	beq $t7, $zero, checkLoop2	
	jal isIntersected
	bne $v0, $zero, collidedBombAero
	
	j checkLoop2
endCheck2:
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra

############################
# Please add your code here#
############################
	# collide with aerolites, play the sound effect
collidedBombAero:
	lw $t4, 0($t9)
	lw $t5, 4($t9)

	li $v0, 100	
	li $a0, 18
	li $a1, 5
	syscall

	add $a0, $zero, $t4	#new codes bombs
	add $a1, $zero, $t5
		
	subi $t8, $t8, 20
	 	
	li $t7, 1
	sw $t7, 20($t9)
	li $t7, -20
	sw $t7, 0($t9)
	sw $t7, 4($t9)
	
	lw $t5, 16($t8)
	li $t7, 5
	beq $t5, $t7, fullcollide
	
	add $a2, $a0, $a2	#new codes bombs
	add $a3, $a1, $a3
	
	add $t2, $t0, $t2	#aerolites
	add $t3, $t1, $t3
	
	addi $a0, $a0, 1
	slt $t5, $a0, $t0	#check x
	beq $t5 $zero, count1

	addi $a1, $a1, 1
	slt $t5, $a1, $t1	#check y
	beq $t5, $zero, count2	

	jal updateDamagedImages

	addi $t5, $zero, 5
	sw $t5, 16($t8)	
																																	
	addi $t8, $t8, 20 
	j checkLoop2
		
count1:
	addi $a2, $a2, -1
	slt $t5, $t2, $a2
	beq $t5, $zero, fullcollide

	addi $a1, $a1, 1
	slt $t5, $a1, $t1	#check y
	beq $t5, $zero, count2	
	
	jal updateDamagedImages
	
	addi $t5, $zero, 5
	sw $t5, 16($t8)		

	addi $t8, $t8, 20 
	j checkLoop2	

count2:
	addi $a3, $a3, -1
	slt $t5, $t3, $a3
	beq $t5, $zero, fullcollide

	jal updateDamagedImages
	
	addi $t5, $zero, 5
	sw $t5, 16($t8)	
	
	addi $t8, $t8, 20 
	j checkLoop2	

fullcollide:
	addi $s2, $s2, 10

	li $t7, -1
	sw $t7, 8($t8) 

	li $t7, 0
	sw $t7, 16($t8)
		
	addi $t8, $t8, 20 
	j checkLoop2	
#----------------------------------------------------------------------------------------------------------------------
# Function: read and handle the player's input

processInput:
#===================================================================

############################
# Please add your code here#
	la $t1, spaceship
	la $t6, bombs
	li $t2, 0
	li $t3, 8
############################

	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	jal getInput
	
	li $t0, 113			# key q
	beq $v0, $t0, end_main
	
	li $t0, 49			# key 1
	beq $v0, $t0, eject_bomb
	
	li $t0, 97			# key a
	beq $v0, $t0, press_a
	
	li $t0, 100			# key d
	beq $v0, $t0, press_d
	
	li $t0, 119			# key w
	beq $v0, $t0, press_w
	
	li $t0, 115			# key s
	beq $v0, $t0, press_s
	
	j process_input_end

press_d:
	li $t4, 1
	sw $t4, 8($t1)
	sw $t3, 12($t1)
	sw $t2, 16($t1)
			
	j process_input_end
	
press_a:
	# NOT IMPLEMENTED
	li $t4, 2
	sw $t4, 8($t1)
	sub $t3, $zero, $t3 
	sw $t3, 12($t1)
	sw $t2, 16($t1)
	
	j process_input_end
	
press_w:
	# NOT IMPLEMENTED
	li $t4, 10
	sw $t4, 8($t1)
	sub $t3, $zero, $t3
	sw $t2, 12($t1)
	sw $t3, 16($t1)
	
	j process_input_end
	
press_s:
	# NOT IMPLEMENTED
	li $t4, 11
	sw $t4, 8($t1)
	sw $t2, 12($t1)
	sw $t3, 16($t1)
	
	j process_input_end
	
eject_bomb:
	# NOT IMPLEMENTED
	lw $t2, 20($t6)
	beq $t2, $zero, process_input_end

	li $t2, 9
	sw $t2, 8($t6)
					
	li $t2, 0
	sw $t2, 20($t6)
	
	lw $t2, 0($t1)
	lw $t3, 4($t1)
	
	addi $t2, $t2, 8
	addi $t3, $t3, 8
	
	sw $t2, 0($t6)
	sw $t3, 4($t6)
	
	#li $t1, 9
	#sw $t1, 8($t6)
	# eject the bomb, play the sound effect 
	li $v0, 100	
	li $a0, 18
	li $a1, 1
	syscall
	
	lw $t2, 8($t1)
	li $t3, 1
	beq $t2,$t3, setDir1
	
	li $t3, 2
	beq $t2,$t3, setDir2
	
	li $t3, 10
	beq $t2,$t3, setDir3	
	
	li $t4, 0
	sw $t4, 12($t6)
	li $t4, 16
	sw $t4, 16($t6)
			
	j process_input_end
	
	
setDir1:
	li $t4, 16
	sw $t4, 12($t6)
	li $t4, 0
	sw $t4, 16($t6)
	
	j process_input_end
setDir2:
	li $t4, -16
	sw $t4, 12($t6)
	li $t4, 0
	sw $t4, 16($t6)
	
	j process_input_end
	
setDir3:
	li $t4, 0
	sw $t4, 12($t6)
	li $t4, -16
	sw $t4, 16($t6)
	
	j process_input_end
	
process_input_end:
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	
	jr $ra

#----------------------------------------------------------------------------------------------------------------------
# Function: move the spaceship, aerolites and fuels

moveSpaceship:
#===================================================================

############################
# Please add your code here#
	la $t6, spaceship

	lw $t1, 0($t6)
	lw $t0, 12($t6)
	
	add $t1, $t1, $t0
	
	slti $t2, $t1, 769
	beq $t2, $zero, Bound

	slti $t2, $t1, 0
	bne $t2, $zero, Bound
	
	sw $t1, 0($t6)

	lw $t1, 4($t6)
	lw $t0, 16($t6)

	add $t1, $t1, $t0
	
	slti $t2, $t1, 769
	beq $t2, $zero, Bound

	slti $t2, $t1, 0
	bne $t2, $zero, Bound	
	
	sw $t1, 4($t6)	

	jr $ra
	
Bound:
	jr $ra
############################

#----------------------------------------------------------------------------------------------------------------------
# Function: move aerolites and fuels 

moveAeroliteFuel:
#===================================================================
	# move aerolites 
	la $t6, aerolites 
	li $t7, 0
move_aerolite_loop:
	lw $t5, 8($t6)
	slti $t5, $t5, 0
	bne $t5, $zero, move_aerolite_loop_continue	# skip removed aerolites 
	lw $t5, 16($t6)
	beq $t5, $zero, move_aerolite_loop_continue	# skip destroyed aerolites 

	lw $t0, 12($t6)		# move aerolite 
	lw $t1, ($t6)
	add $t1, $t1, $t0	# new left x
	sw $t1, ($t6)
	slti $t2, $t1, 0
	bne $t2, $zero, aerolite_move_right
	la $t2, aeroliteSize 
	lw $t2, ($t2)
	add $t1, $t1, $t2	# new right x	
	li $t3, 800
	slt $t2, $t3, $t1
	beq $t2, $zero, move_aerolite_loop_continue

	sub $t0, $zero, $t0	# change aerolite to move left
	sw $t0, 12($t6)
	lw $t5, 8($t6)		# add 1 to image index (from facing right to left)
	addi $t5, $t5, 1
	sw $t5, 8($t6)
	la $t2, aeroliteSize 
	lw $t2, ($t2)
	li $t0, 800
	sub $t0, $t0, $t2	# new valid left x
	sw $t0, ($t6)
	j move_aerolite_loop_continue

aerolite_move_right: 
	sub $t0, $zero, $t0	# change aerolite to move right
	sw $t0, 12($t6)
	lw $t5, 8($t6)		# subtract 1 from image index (from facing left to right)
	addi $t5, $t5, -1
	sw $t5, 8($t6)
	sw $zero, ($t6)		# new valid left x

move_aerolite_loop_continue:	
	addi $t7, $t7, 1 
	addi $t6, $t6, 20
	bne $t7, $s1, move_aerolite_loop

	# move fuels	
	la $t6, fuels
	li $t7, 0
move_fuel_loop:
	lw $t5, 8($t6)
	slti $t5, $t5, 0
	bne $t5, $zero, move_fuel_loop_continue	# skip removed fuels
	lw $t5, 16($t6)
	beq $t5, $zero, move_fuel_loop_continue	# skip destroyed fuels

	lw $t0, 12($t6)		# move fuel
	lw $t1, ($t6)
	add $t1, $t1, $t0	# new left x
	sw $t1, ($t6)
	slti $t2, $t1, 0
	bne $t2, $zero, fuel_move_right
	la $t2, fuelSize
	lw $t2, ($t2)
	add $t1, $t1, $t2	# new right x	
	li $t3, 800
	slt $t2, $t3, $t1
	beq $t2, $zero, move_fuel_loop_continue

	sub $t0, $zero, $t0	# change fuel to move left
	sw $t0, 12($t6)
	lw $t5, 8($t6)		# add 1 to image index (from facing right to left)
	addi $t5, $t5, 1
	sw $t5, 8($t6)
	la $t2, fuelSize
	lw $t2, ($t2)
	li $t0, 800
	sub $t0, $t0, $t2	# new valid left x
	sw $t0, ($t6)
	j move_fuel_loop_continue

fuel_move_right: 
	sub $t0, $zero, $t0	# change fuel to move right
	sw $t0, 12($t6)
	lw $t5, 8($t6)		# subtract 1 from image index (from facing left to right)
	addi $t5, $t5, -1
	sw $t5, 8($t6)
	sw $zero, ($t6)		# new valid left x

move_fuel_loop_continue:	
	addi $t7, $t7, 1 
	addi $t6, $t6, 20
	bne $t7, $s0, move_fuel_loop
	
	jr $ra

#----------------------------------------------------------------------------------------------------------------------
# Function: move the bomb, and then remove those under the
# game screen and add them back to the available ones. 

moveBomb:
#===================================================================
	la $t6, bombs
	
	lw $t1, 20($t6)
	bne $t1, 0, BombBound 	

	lw $t1, 0($t6)
	lw $t0, 12($t6)
	
	add $t1, $t1, $t0
	
	slti $t2, $t1, 785
	beq $t2, $zero, BombBound

	slti $t2, $t1, 0
	bne $t2, $zero, BombBound
	
	sw $t1, 0($t6)

	lw $t1, 4($t6)
	lw $t0, 16($t6)

	add $t1, $t1, $t0
	
	slti $t2, $t1, 785
	beq $t2, $zero, BombBound

	slti $t2, $t1, 0
	bne $t2, $zero, BombBound
	
	sw $t1, 4($t6)	
	
	jr $ra
	
BombBound:
	li $t1, 1
	sw $t1, 20($t6)
	li $t1, -1
	sw $t1, 8($t6)
	li $t1, -20
	sw $t1, 0($t6)
	sw $t1, 4($t6)
	jr $ra
############################
# Please add your code here#
############################

#----------------------------------------------------------------------------------------------------------------------
# Function: update the image index of any damaged or destroyed aerolites and fuels

updateDamagedImages:
#===================================================================
	lw $t5, 8($t8)
	addi $t5, $t5, 2
	sw $t5, 8($t8)
	
	jr $ra
############################
# Please add your code here#
############################

	# update aerolites 
	la $t6, aerolites 
	li $t7, 0
update_aerolite_loop:
	lw $t5, 8($t6)
	slti $t5, $t5, 0
	bne $t5, $zero, update_aerolite_loop_continue	# skip removed aerolites 
	lw $t5, 16($t6)
	li $t4, 10
	beq $t5, $t4, update_aerolite_loop_continue	# skip un-damaged aerolites 
	beq $t5, $zero, update_aerolite_loop_continue	# skip destroyed aerolites

	lw $t5, 12($t6)					# change to damaged aerolite image
	li $t0, 5					# damaged aerolite facing right's image index
	slti $t1, $t5, 0
	beq $t1, $zero, damaged_aerolite_face_right
	li $t0, 6					# damaged aerolite facing left's image index
damaged_aerolite_face_right: 
	sw $t0, 8($t6)
	j update_aerolite_loop_continue

update_aerolite_loop_continue:	
	addi $t7, $t7, 1 
	addi $t6, $t6, 20
	bne $t7, $s1, update_aerolite_loop
	
	jr $ra
	
#----------------------------------------------------------------------------------------------------------------------
# Function: check if the current level continues or reachs wining state.
# Winning state: All aerolites are destroyed, while all fuels are collected.	
# return $v0: 1 -- the level is won, 0 -- the level continues

isLevelOver:
#===================================================================
	li $v0, 0

	# check fuels
	la $t6, fuels
	li $t7, 0
level_fuel_loop:
	lw $t5, 8($t6)
	slti $t5, $t5, 0
	bne $t5, $zero, level_fuel_loop_continue	# skip collected fuels
	ori $v0, $zero, 0				# fuel has not been removed yet
	jr $ra

level_fuel_loop_continue:	
	addi $t7, $t7, 1 
	addi $t6, $t6, 20
	bne $t7, $s1, level_fuel_loop
	ori $v0, $zero, 1
	j level_aerolite_check				# all fuels are collected, go check aerolite 

level_aerolite_check:
	# check aerolites
	la $t6, aerolites 
	li $t7, 0
level_aerolite_loop:
	lw $t5, 8($t6)
	slti $t5, $t5, 0
	bne $t5, $zero, level_aerolite_loop_continue	# skip removed aerolites 
	ori $v0, $zero, 0				# aerolite has not been removed yet
	jr $ra

level_aerolite_loop_continue:	
	addi $t7, $t7, 1 
	addi $t6, $t6, 20
	bne $t7, $s1, level_aerolite_loop
	
	ori $v0, $zero, 1
	jr $ra						# all aerolites are removed, the level is won

#----------------------------------------------------------------------------------------------------------------------
# Function: check whether two rectangles (say A and B) intersect each other
# return $v0: 0 -- false, 1 -- true
# a0 = x-coordinate of the top-left corner of rectangle A
# a1 = y-coordinate of the top-left corner of rectangle A
# a2 = width of rectangle A
# a3 = height of rectangle A
# t0 = x-coordinate of the top-left corner of rectangle B
# t1 = y-coordinate of the top-left corner of rectangle B
# t2 = width of rectangle B
# t3 = height of rectangle B

isIntersected:
#===================================================================

############################
# Please add your code here#
	add $t4, $a0, $a2	#largest x-coordinate of A
	slt $t5, $t4, $t0
	beq $t5, $zero, True1
	
	li $v0, 0
	jr $ra
True1:
	add $t4, $t0, $t2	#largest x-coordinate of B
	slt $t5, $t4, $a0
	beq $t5, $zero, True2
	
	li $v0, 0
	jr $ra	
True2:
	add $t4, $a1, $a3	#largest y-coordinate of A
	slt $t5, $t4, $t1
	beq $t5, $zero, True3
	
	li $v0, 0
	jr $ra	
True3:
	add $t4, $t1, $t3	#largest y-coordinate of B
	slt $t5, $t4, $a1
	beq $t5, $zero, True4
	
	li $v0, 0
	jr $ra		
True4:
	li $v0, 1
	jr $ra   
############################

#---------------------------------------------------------------------------------------------------------------------
# Function: update the game screen objects according to the game data structures in MIPS code here

updateGameObjects:				
#===================================================================
	li $v0, 100


	# update game state numbers	
	li $a0, 14

	li $a1, 0	# Score number
	ori $a2, $s2, 0	
	syscall
	
	li $a1, 1	# level number
	ori $a2, $s3, 0	
	syscall

	la $t0, bombs
	lw $a2, 20($t0)
	li $a1, 2	# bomb availability flag
	syscall

	# update spaceship
	li $a1, 4

	la $t0, spaceship
	lw $a2, 0($t0)
	lw $a3, 4($t0)
		
	li $a0, 12	# spaceship location			
	syscall
	
	li $a0, 11	# spaceship image index
	lw $a2, 8($t0)	
	syscall

	# update aerolites 
	li $a1, 5

	la $t6, aerolites 
	li $t7, 0
draw_aerolite_loop:
	lw $a2, ($t6)
	lw $a3, 4($t6)
	li $a0, 12	# location	
	syscall
	
	li $a0, 11	# image index
	lw $a2, 8($t6)	
	syscall
	



draw_aerolite_loop_continue:
	addi $a1, $a1, 1	
	addi $t7, $t7, 1 
	addi $t6, $t6, 20
	bne $t7, $s1, draw_aerolite_loop
	
	# update fuels
	la $t6, fuels
	li $t7, 0
draw_fuel_loop:
	lw $a2, ($t6)
	lw $a3, 4($t6)
	li $a0, 12	# location	
	syscall
	
	li $a0, 11	# image index
	lw $a2, 8($t6)	
	syscall
	

draw_fuel_loop_continue:
	addi $a1, $a1, 1	
	addi $t7, $t7, 1 
	addi $t6, $t6, 20

	bne $t7, $s0, draw_fuel_loop

	# update bombs
	la $t6, bombs
	lw $a2, ($t6)
	lw $a3, 4($t6)
	li $a0, 12	# location	
	syscall

	li $a0, 11	# image index
	lw $a2, 8($t6)	
	syscall
	

	jr $ra
#----------------------------------------------------------------------------------------------------------------------
# Function: get input character from keyboard, which is stored using Memory-Mapped Input Output (MMIO)
# return $v0: ASCII value of input character if input is available; otherwise the value zero

getInput:
#===================================================================
	addi $v0, $zero, 0

	lui $a0, 0xffff
	lw $a1, 0($a0)
	andi $a1,$a1,1
	beq $a1, $zero, noInput
	lw $v0, 4($a0)

noInput:	
	jr $ra
#----------------------------------------------------------------------------------------------------------------------
# Function: set the seed of the random number generator to $a0
# $a0 = the seed number
setRandomSeed:
#===================================================================
	ori $a1, $a0, 0		
	li $v0, 40    
	li $a0, 1
	syscall

	jr $ra
#----------------------------------------------------------------------------------------------------------------------
# Function: generate a random number between 0 and ($a0 - 1) inclusively, and return it in $v0
# $a0 = range
randnum:
#===================================================================
	li $v0, 42
	ori $a1, $a0, 0
	li $a0, 1 
	syscall
	ori $v0, $a0, 0

	jr $ra
#----------------------------------------------------------------------------------------------------------------------
# Function: set the location, color and font of drawing the game state's output objects in the game screen
setGameStateOutput:				
#===================================================================
	li $v0, 100

	# score number's location
	li $a1, 0
	li $a0, 12
	li $a2, 120
	li $a3, 47			
	syscall

	# font (size 20, plain)
	li $a0, 16
	li $a2, 20
	li $a3, 0
	li $t0, 0				
	syscall

	# color
	li $a0, 15
	li $a2, 0x00ffffff   # white				
	syscall


	# level number's location
	li $a1, 1
	li $a0, 12
	li $a2, 120
	li $a3, 105		
	syscall

	# font (size 20, plain)
	li $a0, 16
	li $a2, 20
	li $a3, 0
	li $t0, 0				
	syscall

	# color
	li $a0, 15
	li $a2, 0x00ffffff   # white				
	syscall

	
	# bomb availability number's location
	li $a1, 2
	li $a0, 12
	li $a2, 120
	li $a3, 162			
	syscall

	# font (size 20, plain)
	li $a0, 16
	li $a2, 20
	li $a3, 0
	li $t0, 0				
	syscall

	# color
	li $a0, 15
	li $a2, 0x00ffffff   # white				
	syscall

	jr $ra
#----------------------------------------------------------------------------------------------------------------------
# Function: set the location, font and color of drawing the game-over string object (drawn with a winning notification message once the game is won) in the game screen
setGameWinningOutput:				
#===================================================================
	li $v0, 100		# gameover string
	addi $a1, $s0, 5	# 5 for 3 game states, 1 bomb, 1 spaceship 
	add $a1, $a1, $s1 

	li $a0, 13		# set object to game-over string
	la $a2, msg3				
	syscall
	
	# location
	li $a0, 12
	li $a2, 200
	li $a3, 250				
	syscall

	# font (size 40, bold, italic)
	li $a0, 16
	li $a2, 80
	li $a3, 1
	li $t0, 1				
	syscall


	# color
	li $a0, 15
	li $a2, 0x00ffff00   # yellow				
	syscall

	jr $ra
#----------------------------------------------------------------------------------------------------------------------
# Function: set the location, font and color of drawing the game-over string object (drawn with a losing notification message once the game is lost) in the game screen
setGameLosingOutput:				
#===================================================================
	li $v0, 100	# gameover string
	addi $a1, $s0, 5	# 5 for 3 game states, 1 bomb, 1 spaceship 
	add $a1, $a1, $s1 

	li $a0, 13	# set object to game-over string
	la $a2, msg4				
	syscall
	
	# location
	li $a0, 12
	li $a2, 200
	li $a3, 250				
	syscall

	# font (size 40, bold, italic)
	li $a0, 16
	li $a2, 80
	li $a3, 1
	li $t0, 1				
	syscall


	# color
	li $a0, 15
	li $a2, 0x00ff0000   # red				
	syscall

	jr $ra
#----------------------------------------------------------------------------------------------------------------------
## Function: create a new game (the first step in the game creation)
createGame:
#===================================================================
	li $v0, 100	

	li $a0, 1
	li $a1, 800 
	li $a2, 800
	la $a3, title
	syscall

	#set game image array
	li $a0, 3
	la $a1, images
	syscall

	li $a0, 5
	li $a1, 0   #set background image index
	syscall
 
	jr $ra
#----------------------------------------------------------------------------------------------------------------------
## Function: create the game screen objects
createGameObjects:
#===================================================================
	li $v0, 100	
	li $a0, 2
	addi $a1, $zero, 3   	# 3 game state outputs
	addi $a1, $a1, 1	# 1 spaceship
	add $a1, $a1, $s1	# s1 aerolites 
	add $a1, $a1, $s0	# s0 fuels
	addi $a1, $a1, 1   	# 1 bomb
	addi $a1, $a1, 1	# gameover output 
	syscall
 
	jr $ra
#----------------------------------------------------------------------------------------------------------------------
## Function: create and show the game screen
createGameScreen:
#===================================================================
	li $v0, 100   
	li $a0, 4
	syscall
	 
	jr $ra
#----------------------------------------------------------------------------------------------------------------------
## Function: redraw the game screen with the updated game screen objects
redrawScreen:
#===================================================================
	li $v0, 100   
	li $a0, 6
	syscall

	jr $ra
#----------------------------------------------------------------------------------------------------------------------
## Function: get the current time (in milliseconds from a fixed point of some years ago, which may be different in different program execution).    
# return $v0 = current time 
getCurrentTime:
#===================================================================
	li $v0, 30
	syscall				# this syscall also changes the value of $a1
	andi $v0, $a0, 0x3fffffff  	# truncated to milliseconds from some years ago

	jr $ra
#----------------------------------------------------------------------------------------------------------------------
## Function: pause execution for X milliseconds from the specified time T (some moment ago). If the current time is not less than (T + X), pause for only 1ms.    
# $a0 = specified time T (returned from a previous calll of getCurrentTime)
# $a1 = X amount of time to pause in milliseconds 
pauseExecution:
#===================================================================
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	add $a3, $a0, $a1
	jal getCurrentTime
	
	sub $a0, $a3, $v0
	slt $a3, $zero, $a0
	bne $a3, $zero, positive_pause_time
	li $a0, 1     # pause for at least 1ms

positive_pause_time:
	li $v0, 32	 
	syscall

	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra
	
playSound:
	li $v0, 100	
	li $a0, 17
	li $a1, 0
	syscall
	jr $ra
