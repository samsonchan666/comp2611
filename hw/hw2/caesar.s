#------- Data Segment ----------
.data
# Define the string messages
msg1:	.asciiz "Please enter the message all in capital letters: "
msg2:	.asciiz "Please enter the shift amount: "
msg3:   .asciiz "The encrypted text is: "
newline:.asciiz "\n"
input: .byte 0:100 #assume max input is 99-character

#------- Text Segment ----------
.text
.globl main
main:

# Print msg1
Label:	la $a0, msg1
	li $v0, 4
	syscall


# This is the syscall 8 to get the input string
# After the syscall, the string is loaded to the .byte array "input"
# the syscall will put a special LineFeed character to the end of the string
# just in front of the end of string character.
# i.e. if you enter "ABC", it will be stored as [A][B][C][LF][0] in the byte array "input"
# the LineFeed is due to the "Enter" key you pressed when you enter the string
	li $v0,8
	la $a0,input
	li $a1,100
	syscall


	la $a0, msg2
	li $v0, 4
	syscall

# Get the input shift amount from user (and store in $v0)
# assume the shift amount is always less than 26	 
	li $v0, 5
	syscall

# Copy the shift amount value to $s0, because we need to change $v0 for syscalls
# after this line $s0 contains the shift amount
        add $s0, $zero, $v0	

                

# TODO: Fill in your code below 
# You can add labels below as you wish
# load the letters (lbu) one by one from the address indicated by $s1
# then call the encrypt function to encrypt the letter 
# assume the letter is in $a2 and the encrypted letter is returned in $v1
# Assume the input can consists of *capital letters* and *spaces*
# Whenever you encounter a *space* (ASCII value 0x20) *DO NOT ENCRYPT it*
# Whenever you encounter a *LineFeed* (ASCII value 0xA) you have reached the end of the string, 
# you should stop encryption and process the string by putting '\0' (ASCII 0x0) in place of the LineFeed
# the LineFeed is due to the "Enter" key you pressed when you enter the string
	la $s1, input
	add $a2, $zero, $s1
	jal encrypt

	add $s1, $zero, $v1
	j print
#TODO 1 above
        
#Encryption done, print the result 
print:
	la $a0, msg3      # Output msg3
	li $v0, 4
	syscall
	
        add $a0,$s1,$zero   #$s1 contains the starting address of the input
	li $v0, 4           # output encrypted msg
	syscall
	
        j end	

# TODO 2: Fill in your code below 
# You can add labels below as you wish
# each time encrypts a single character
# assume the character is in $a2, and the return value in $v1
# assume all characters in the input string are capital characters
# ASCII code for 'A' is 0x41 ,and for 'Z' is 0x5A
encrypt:
	add $t0, $zero, $zero
	addi $t7, $zero, 32	#space
	addi $t6, $zero, 91 #larger than Z
	addi $t8, $zero, 10 #linefeed

L1:
	add $t1, $t0, $a2 	#store the address in $t1
	lb $t2, 0($t1)
	beq $t2, $t8, exit	
	beq $t2, $t7, space
	j shift

space:
	sb $t2, 0($t1)
	addi $t0, $t0, 1
	j L1
shift:
	add $t2, $t2, $s0	#shift the byte
	slt $t5, $t2, $t6
	beq $t5, $zero, large 	#lager than Z
	sb $t2, 0($t1)
	addi $t0, $t0, 1
	j L1
large:
	subi $t2, $t2, 26
	sb $t2, 0($t1)
	addi $t0, $t0, 1
	j L1	
exit:
	sb $zero, 0($t1)	#end of line character
	add $v1, $zero, $a2
	jr $ra
	
#TODO 2 above

#This is the end of the program
end:
        li $v0, 10
        syscall


