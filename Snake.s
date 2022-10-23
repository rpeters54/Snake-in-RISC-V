.data
	.space 3200	#snake memory allocation
.text
	.eqv DATA, 0x6000
	.eqv IO_ADDR, 0x11000000
	.eqv BOARD_SIZE, 33
	.eqv DELAY_TIME, 0x002FAF08 #1/4 second 
			#0x005F5E10, 1/2 second
	
	.eqv APPLE, 0xE0
	.eqv SNAKE, 0x1C
	.eqv BG_COLOR, 0
	.eqv WALL, 0xFF
	.eqv VG_ADDR, 0x11000120
	.eqv VG_COLOR, 0x11000140

# pre-run state of code	
# used as an intermediate state between games
hold:
	li s10, IO_ADDR		#IO address
	li sp, 0x10000
	call draw_title		#draws the title screen
	la t0, main		
	csrw t0, mtvec		#enables interrupt to main method
	addi t0, zero, 1
	csrw t0, mie
STANDBY: beqz zero, STANDBY

# main method:
# defines global variables
# calls setup methods
# enters the game loop
main:	
	li s0, DATA 		#snake tail data address
	add s1, s0, zero 	#snake head data address
	add s2, zero, zero	#snake head x location
	add s3, zero, zero	#snake head y location
	add s4, zero, zero	#score count
	add s5, zero, zero	#snake direction
	li s11, DELAY_TIME	#load delay
	sw s4, 0x40(s10)	#update ssd with the initial score
	call loadBoard		#generates board
	call loadSnake		#loads inital snake position
	call loadApple		#places the first apple on the board
RUN:	call action		#run loop
	j RUN

# resets the board between games
# fill the center square of the board with black
# fill the outer border of the board with white
loadBoard:
	addi sp, sp, -4		#push ra to stack
	sw ra, 0(sp)
	call draw_background
	add a0, zero, zero
	add a1, zero, zero
	addi a2, zero, BOARD_SIZE 
	li a3, WALL
	call draw_horizontal_line
	add a0, zero, zero
	add a1, zero, zero
	addi a2, zero, BOARD_SIZE
	call draw_vertical_line
	add a0, zero, zero
	addi a1, zero, BOARD_SIZE
	addi a2, zero, BOARD_SIZE
	call draw_horizontal_line
	addi a0, zero, BOARD_SIZE
	add a1, zero, zero
	addi a2, zero, BOARD_SIZE
	call draw_vertical_line
	lw ra, 0(sp)		#pop ra and return
	addi sp, sp, 4
	ret

# loads snake data in memory
# places the snake head on the board	
loadSnake:
	addi sp, sp, -4		#push ra to stack
	sw ra, 0(sp)
	addi a0, zero, 5
	addi a1, zero, 5
	add s2, zero, a0	#update current snake x and y position
	add s3, zero, a1
	slli t0, a1, 7		#save position address in data
	add t0, t0, a0
	sh t0, 0(s0)		#load vga position into data
	li a3, SNAKE
	call draw_dot
	lw ra, 0(sp)		#pop ra and return
	addi sp, sp, 4
	ret

# generate a pseudorandom coordinate and place an apple object in that location
# if the location contains the snake, repeat until an empty space is found	
loadApple:
	addi sp, sp, -4		#push ra to stack
	sw ra, 0(sp)
RELOAD:	lw t0, 0x60(s10)	#load pseudorandom number
	andi a0, t0, 0x1F	#X: 0 to 31
	addi a0, a0, 1		#shift 1 position to avoid wall
	srli t0, t0, 16
	andi a1, t0, 0x1F	#Y: 0 to 31
	addi a1, a1, 1		#shift 1 position to avoid wall
	call read_dot
	bnez a2, RELOAD		#if not empty: retry
	addi a3, zero, APPLE	#load red color
	call draw_dot
	lw ra, 0(sp)		#pop ra and return
	addi sp, sp, 4
	ret			#return
	
# delays for a short period
# any button presses during the delay period are registered	
delay:
	addi sp, sp, -4		#push ra to stack
	sw ra, 0(sp)
	add t0, zero, zero
WAIT:	addi t0, t0, 1
	bne t0, s11, WAIT
	lw ra, 0(sp)		#return
	addi sp, sp, 4
	ret

# method loop that begins when the game is played
# consists of an input check and two separate case segments:
# 1. verify that the next move is legal (not opposite to current motion)
# 2. generate next position based on the most recent button press
# 3. given next position, determine if the snake moves, eats, or dies
action:	
	addi sp, sp, -4		#push ra to stack
	sw ra, 0(sp)
	lw t0, 0x100(s10)	#load next move from button
	andi t2, t0, 1		#checks in case previous move contradicts new move
	beq t2, zero, ADD	#i.e. you cant move left and then right 
SUB:	addi t2, t0, -1		
	beq t2, s5, INVAL
	j VALID
ADD:	addi t2, t0, 1
	beq t2, s5, INVAL
	j VALID
INVAL:	add t0, s5, zero	#if the next move is invalid, continue in previous direction
VALID:	add s5, t0, zero	#set the previous direction to the current direction
	addi t1, zero, 3	#comparator (3 = UP, 2 = DOWN, 1 = LEFT, 0 = RIGHT)
UP:	bne t0, t1, DOWN	#if next move is UP:
	addi s3, s3, -1		#decrement y position
	j OBST
DOWN:	addi t1, zero, 2	
	bne t0, t1, LEFT	#if next move is DOWN:
	addi s3, s3, 1		#increment y position
	j OBST
LEFT:	addi t1, zero, 1
	bne t0, t1, RIGHT	#if next move is LEFT:
	addi s2, s2, -1		#decrement x position
	j OBST
RIGHT:	addi s2, s2, 1		#else, increment x position
OBST:	add a0, zero, s2	#use a0 and a1 temporaries for helper methods
	add a1, zero, s3
	call read_dot		#explore next space
EMPTY:	bnez a2, HUNGRY		#if the next space is empty:
	call move		#move to the next space
	j NEXT
HUNGRY:	li t3, APPLE		
	bne a2, t3, DEATH	#if the next space contains an apple:
	call eat		#eat the apple
	j NEXT
DEATH:	j hold			#otherwise, gameover
NEXT:	call delay		#delay between moves
	lw ra, 0(sp)		#return
	addi sp, sp, 4
	ret			
			
# moves the snake a single space in the direction it is traveling:
# draws the head at the next position, clears the tail location,
# and refreshes the VGA addresses stored in memory
move:
	addi sp, sp, -4		#push ra to stack
	sw ra, 0(sp)
	li a3, SNAKE		#load snake color
	add a0, zero, s2	#load snake position into arguments
	add a1, zero s3
	call draw_dot		#draw snake head position
	lhu t1, 0(s0)		#load the address at the snake's tail
	li a3, BG_COLOR		
	srli a1, t1, 7		#convert the address to xy coord
	andi a0, t1, 0x3F
	call draw_dot		#clear the tail of the snake from the board
	slli t2, s3, 7
	add t2, t2, s2		#turn x, y coord into address
	add t3, s1, zero	#head address temporary
UPDATE:	blt t3, s0, MOVED	#While there are more segments to visit
	lhu t4, 0(t3)		#load the address stored in that location
	sh t2, 0(t3)		#replace the address with the one stored in the next segment
	add t2, t4, zero	#set loaded address to be stored in the next segment
	addi t3, t3, -2		#move to the next spot in memory
	j UPDATE
MOVED:  lw ra, 0(sp)		#return
	addi sp, sp, 4
	ret

# generates a new snake piece and increments the score when an apple is encountered
# makes an internal call to loadApple so that a new apple is available
eat:	
	addi sp, sp, -4		#push ra to stack
	sw ra, 0(sp)
	li a3, SNAKE		#load snake color
	addi s1, s1, 2		#add an extra snake piece
	slli t0, s3, 7
	add t0, t0, s2		#generate location address
	sh t0, 0(s1)
	add a0, zero, s2
	add a1, zero, s3
	call draw_dot		#draw new snake head
	addi s4, s4, 1		#add 1 to the score
	sw s4, 0x40(s10)	#update ssd with the new score
	call loadApple		#generate a new apple
	lw ra, 0(sp)		#return
	addi sp, sp, 4
	ret

# draws a horizontal line from (a0,a1) to (a2,a1) using color in a3
# Modifies (directly or indirectly): t0, t1, a0, a2
draw_horizontal_line:
	addi sp,sp,-4
	sw ra, 0(sp)
	addi a2,a2,1		#go from a0 to a2 inclusive
draw_horiz1:
	call draw_dot  		# must not modify: a0, a1, a2, a3
	addi a0,a0,1
	bne a0,a2, draw_horiz1
	lw ra, 0(sp)
	addi sp,sp,4
	ret

# draws a vertical line from (a0,a1) to (a0,a2) using color in a3
# Modifies (directly or indirectly): t0, t1, a1, a2
draw_vertical_line:
	addi sp,sp,-4
	sw ra, 0(sp)
	addi a2,a2,1
draw_vert1:
	call draw_dot  		# must not modify: a0, a1, a2, a3
	addi a1,a1,1
	bne a1,a2,draw_vert1
	lw ra, 0(sp)
	addi sp,sp,4
	ret

# Fills the 60x80 grid with one color using successive calls to draw_horizontal_line
# Modifies (directly or indirectly): t0, t1, t4, a0, a1, a2, a3
draw_background:
	addi sp,sp,-4
	sw ra, 0(sp)
	li a3, BG_COLOR			#use default color
	li a1, 0			#a1= row_counter
	li t4, 60 			#max rows
start:	li a0, 0
	li a2, 79 			#total number of columns
	call draw_horizontal_line  	# must not modify: t4, a1, a3
	addi a1,a1, 1
	bne t4,a1, start		#branch to draw more rows
	lw ra, 0(sp)
	addi sp,sp,4
	ret

# draws a dot on the display at the given coordinates:
# 	(X,Y) = (a0,a1) with a color stored in a3
# 	(col, row) = (a0,a1)
# Modifies (directly or indirectly): t0, t1
draw_dot:
	andi t0,a0,0x7F		# select bottom 7 bits (col)
	andi t1,a1,0x3F		# select bottom 6 bits  (row)
	slli t1,t1,7		#  {a1[5:0],a0[6:0]} 
	or t0,t1,t0		# 13-bit address
	sw t0, 0x120(s10)	# write 13 address bits to register
	sw a3, 0x140(s10)	# write color data to frame buffer
	ret

# reads the color data at the given coordinates:
# 	(X,Y) = (a0,a1)
# 	(col, row) = (a0,a1)
#	a2 = color data
# Modifies (directly or indirectly): t0, t1	
read_dot:
	andi t0,a0,0x7F		# select bottom 7 bits (col)
	andi t1,a1,0x3F		# select bottom 6 bits  (row)
	slli t1,t1,7		#  {a1[5:0],a0[6:0]} 
	or t0,t1,t0		# 13-bit address
	sw t0, 0x120(s10)	# write 13 address bits to register
	lw a2, 0x160(s10)	# read color data from frame buffer
	ret

# draws the title screen visible before the program runs	
draw_title:
	addi sp,sp,-4
	sw ra, 0(sp)
	call draw_background
	li a3, WALL
	call draw_header
	lw ra, 0(sp)
	addi sp,sp,4
	ret

# long series of draw_line calls that spell out "Snake"
# used for the title screen
draw_header:
	addi sp,sp,-4
	sw ra, 0(sp)
S:	addi a0, zero, 22
	addi a1, zero, 19
	addi a2, zero, 25
	call draw_vertical_line
	addi a0, zero, 23
	addi a1, zero, 19
	addi a2, zero, 25
	call draw_vertical_line
	addi a0, zero, 24
	addi a1, zero, 19
	addi a2, zero, 27
	call draw_horizontal_line
	addi a0, zero, 24
	addi a1, zero, 20
	addi a2, zero, 27
	call draw_horizontal_line
	addi a0, zero, 24
	addi a1, zero, 24
	addi a2, zero, 27
	call draw_horizontal_line
	addi a0, zero, 24
	addi a1, zero, 25
	addi a2, zero, 27
	call draw_horizontal_line
	addi a0, zero, 26
	addi a1, zero, 26
	addi a2, zero, 30
	call draw_vertical_line
	addi a0, zero, 27
	addi a1, zero, 26
	addi a2, zero, 30
	call draw_vertical_line
	addi a0, zero, 22
	addi a1, zero, 29
	addi a2, zero, 25
	call draw_horizontal_line
	addi a0, zero, 22
	addi a1, zero, 30
	addi a2, zero, 25
	call draw_horizontal_line
n:	
	addi a0, zero, 29
	addi a1, zero, 24
	addi a2, zero, 30
	call draw_vertical_line
	addi a0, zero, 30
	addi a1, zero, 24
	addi a2, zero, 30
	call draw_vertical_line
	addi a0, zero, 31
	addi a1, zero, 25
	addi a2, zero, 34
	call draw_horizontal_line
	addi a0, zero, 31
	addi a1, zero, 26
	addi a2, zero, 34
	call draw_horizontal_line
	addi a0, zero, 33
	addi a1, zero, 27
	addi a2, zero, 30
	call draw_vertical_line
	addi a0, zero, 34
	addi a1, zero, 27
	addi a2, zero, 30
	call draw_vertical_line
a:
	addi a0, zero, 36
	addi a1, zero, 25
	addi a2, zero, 41
	call draw_horizontal_line
	addi a0, zero, 36
	addi a1, zero, 26
	addi a2, zero, 41
	call draw_horizontal_line
	addi a0, zero, 36
	addi a1, zero, 27
	addi a2, zero, 28
	call draw_vertical_line
	addi a0, zero, 37
	addi a1, zero, 27
	addi a2, zero, 28
	call draw_vertical_line
	addi a0, zero, 40
	addi a1, zero, 27
	addi a2, zero, 28
	call draw_vertical_line
	addi a0, zero, 41
	addi a1, zero, 27
	addi a2, zero, 28
	call draw_vertical_line
	addi a0, zero, 36
	addi a1, zero, 29
	addi a2, zero, 42
	call draw_horizontal_line
	addi a0, zero, 36
	addi a1, zero, 30
	addi a2, zero, 42
	call draw_horizontal_line
k:
	addi a0, zero, 44
	addi a1, zero, 20
	addi a2, zero, 30
	call draw_vertical_line
	addi a0, zero, 45
	addi a1, zero, 20
	addi a2, zero, 30
	call draw_vertical_line	
	addi a0, zero, 46
	addi a1, zero, 27
	addi a2, zero, 28
	call draw_vertical_line
	addi a0, zero, 47
	addi a1, zero, 27
	addi a2, zero, 28
	call draw_vertical_line
	addi a0, zero, 48
	addi a1, zero, 25
	addi a2, zero, 26
	call draw_vertical_line
	addi a0, zero, 49
	addi a1, zero, 25
	addi a2, zero, 26
	call draw_vertical_line
	addi a0, zero, 48
	addi a1, zero, 29
	addi a2, zero, 30
	call draw_vertical_line
	addi a0, zero, 49
	addi a1, zero, 29
	addi a2, zero, 30
	call draw_vertical_line
e:	
	addi a0, zero, 51
	addi a1, zero, 25
	addi a2, zero, 30
	call draw_vertical_line
	addi a0, zero, 52
	addi a1, zero, 25
	addi a2, zero, 30
	call draw_vertical_line
	addi a0, zero, 55
	addi a1, zero, 25
	addi a2, zero, 28
	call draw_vertical_line
	addi a0, zero, 56
	addi a1, zero, 25
	addi a2, zero, 28
	call draw_vertical_line
	addi a0, zero, 53
	addi a1, zero, 25
	addi a2, zero, 54
	call draw_horizontal_line
	addi a0, zero, 53
	addi a1, zero, 28
	addi a2, zero, 54
	call draw_horizontal_line
	addi a0, zero, 53
	addi a1, zero, 30
	addi a2, zero, 56
	call draw_horizontal_line
underline:
	addi a0, zero, 22
	addi a1, zero, 32
	addi a2, zero, 56
	call draw_horizontal_line
	addi a0, zero, 22
	addi a1, zero, 33
	addi a2, zero, 56
	call draw_horizontal_line
	
	lw ra, 0(sp)
	addi sp,sp,4
	ret
