#------- Data Segment ----------
.data
# Define the string messages and the array
msg1:		.asciiz "\nThe ascending sorted numbers are  "
msg2:           .asciiz "The original list of random numbers are "
space:		.asciiz " "
newline:	.asciiz "\n" 
A:		.word 0:10

#------- Text Segment ----------
.text
.globl main
main:

#$s1 holds the array size
addi $s1,$zero,10

# set random seed
	li $v0, 30
	syscall            
	move $a1, $a0
	li $a0, 0
	li $v0, 40
	syscall

# load the starting address of the array to $s0
	la $s0, A
	add $t0, $zero,$zero


# TODO 1: fill the array with $s1=10 random elements in the range [1, 100]
# You can add labels below as you wish	
# $s0 holds the base address of A, $s1 holds the array size
# DO NOT change the $s0,$s1 values (or perserv them using stack), otherwise printresult will not function correctly
# you can use the random_number_generate procedure provided to generate
# randome numbers, random_number_generate returns the random number in $v1
	add $t1, $zero, $s0	# get the starting address of array

array_filling:	
	
	li $v0, 42
	li $a0, 1
	addi $a1, $zero, 100
	syscall

	sw $a0, 0($t1)

	addi $t1, $t1, 4	#next word address
	addi $t0, $t0, 1	#iterating adding

	bne $t0, $s1, array_filling
# TODO 1 above

	


#print the original unsorted list
         jal printoriginal
         
# TODO 2 : sort the array A[] by referring to the C/C++ sort() function
# You can add labels below as you wish	
# $s0 holds the base address of A, $s1 holds the array size
# DO NOT change the $s0,$s1 values (or perserv them using stack), otherwise printresult will not function correctly
# use $s2 for the index i, and $s3 for the index j 
# remember to initalize i and j to 0
# write the sort algorithm in MIPS according to the sort() function in the homework description
# you can add labels as you wish

	add $s2, $zero, $zero	#initialize i
	add $s3, $zero, $zero	#initialize j
	add $t4, $zero, $s0		#starting address of array

Iteration1:
	add $s3, $zero, $zero  #reset j after inner loop iteration
	add $t4, $zero, $s0		#reset starting address of array
	addi $s2, $s2, 1	#iteration adding i++
	bne $s2, $s1, Iteration2
	j workdone

Iteration2:

	lw $t1, 0($t4)	#a[j]
	lw $t2, 4($t4)	#a[j+1]

	slt $t3, $t2, $t1	#compare
	bne $t3, $zero, swap

	addi $t4, $t4, 4	#array address adding

	sub $t0, $s1, $s2	#n-1-i
	addi $s3, $s3, 1	#iteration adding j++
	bne $s3, $t0, Iteration2

	j Iteration1

swap:
	add $t5, $zero, $t1 #temp = a[j]
	sw $t2, 0($t4)		#a[j] = a[j+1]
	sw $t5, 4($t4)		#a[j+1] = temp

	addi $t4, $t4, 4	#array address adding
	
	sub $t0, $s1, $s2	#n-1-i
	addi $s3, $s3, 1	#iteration adding
	bne $s3, $t0, Iteration2

	j Iteration1


# TODO 2 above 

# sorting of A[] completed, print the result and end
workdone: 
 	jal printresult
 	j end

# print the unsorted list A[]
printoriginal:
	addi $sp,$sp,-4
	sw $ra,0($sp)
	
	la $a0,msg2
	li $v0,4
	syscall
        jal printmain
        
        lw $ra,0($sp)
        addi $sp,$sp,4
        jr $ra
        
        
#print the sorted A[] 
printresult:
	addi $sp,$sp,-4
	sw $ra,0($sp)

	#Print msg1
	la $a0, msg1
	li $v0, 4
	syscall
	
        jal printmain
        
        lw $ra,0($sp)
        addi $sp,$sp,4
        jr $ra


# print all the numbers of A[]
printmain:
	addi $sp,$sp,-4
	sw $ra,0($sp)

#Print a new line
	la $a0, newline
	li $v0, 4
	syscall

        
#Print A[]
        add $t1,$zero,$zero  #$t1 is the index for printing A[i]
printloop:
        slt  $t0,$t1,$s1     #check to see if $t1 (i) is still within the correct range 
        beq  $t0,$zero, endprintloop #if i>=10 end print numbers
	sll  $t2,$t1,2       #$t1*4 to get the byte offset
	add  $t3,$s0,$t2     #base+byte offset to get address of A[i]
	lw   $a0,($t3)
	li   $v0, 1
	syscall

#Print a space to separate the numbers
	la $a0, space
	li $v0, 4
	syscall
	
#i=i+1 and start another iteration of the loop	
	addi $t1,$t1,1      #i=i+1
	j printloop

endprintloop:	
#Print a new line
	la $a0, newline
	li $v0, 4
	syscall
	lw $ra,0($sp)
        addi $sp,$sp,4
        jr $ra

#random_number_generate
#there is no input paramter
#output result stored in $v1
random_number_generate:
	addi $sp,$sp,-8
	sw   $ra,0($sp)
	sw   $a0,4($sp)
	
	addi $a1,$zero, 100 #set upper bound to be 100	
	li $a0, 0
	li $v0, 42
	syscall
	
	addi $v1, $a0, 1	
	
	lw $a0,4($sp)
	lw $ra,0($sp)
	addi $sp,$sp,8
	
	jr $ra		

#This is the end of the program
end:
	li $v0, 10 
	syscall
