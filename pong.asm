STACK SEGMENT PARA STACK
	DB 64 DUP (' ')
STACK ENDS

DATA SEGMENT PARA 'DATA'
	
	prev_time DB 0   ;used to check if time has passed
	ball_origin_x DW 0A0h ;center of screen for ball to return to
	ball_origin_y DW 64h ;center of screen for ball to return to
	ball_X DW 0A0h  ;x pos ball (column) current
	ball_Y DW 64h  ;y pos ball (row) current
	ball_Size DW 05h ;size of ball, set to 25 pixels
	ball_XSpeed DW 05h ; X speed of ball movement
	ball_YSpeed DW 07h ; Y speed of ball movement
	window_Width DW 140h	; x length of window
	window_Height DW 0C8h ; y height of window
	window_diff DW 05h		; you can specify how far from the window borders you want the ball to collide from 
	paddle_left_x DW 0Ah ;paddle x position current
	paddle_left_y DW 0Ah ;paddle y position current
	paddle_right_x DW 130h ;paddle x position current
	paddle_right_y DW 0Ah ;paddle y position current
	paddle_width DW 05h ;paddle's width
	paddle_height DW 1Fh ;paddle's height
	paddle_velocity DW 05h ;paddle's velocity
	
	

DATA ENDS

CODE SEGMENT PARA 'CODE'

	MAIN PROC FAR
	ASSUME CS:CODE,DS:DATA,SS:STACK			;setting segments 
	; Assuring that each segment is clear and initalized properly
	PUSH DS			;push data into stack
	SUB AX,AX		;clean/reset ax register
	PUSH AX			
	MOV AX,DATA		
	MOV DS,AX
	POP AX
	POP AX
	
		CALL RESET_SCREEN ; Resets background and initalizes INT 10h video configurations
		
		check_time:
		
			MOV AH,2Ch  ; get system time
			INT 21h		;execute config, CH = hour, CL = min, DH = second, DL = 1/100 second
		
			CMP DL, prev_time	;compare current time and previous time.
			JE check_time		;if they are equal, check again. if not, time has passed and update the graphics
			MOV prev_time, DL 	; update time
			CALL RESET_SCREEN	;reset screen to remove previous DRAW_BALL graphics
			CALL MOVE_BALL		;Moves Ball position based on specified speeds
			CALL DRAW_BALL		;Draws the Ball based on specified Size
			
			CALL MOVE_PADDLES ;This procedure will move the paddles
			CALL DRAW_PADDLES ;This procedure will draw our left and right paddles
			
			JMP check_time		;keep checking time in an infinite loop
		
		
		RET
	MAIN ENDP
	
	DRAW_BALL PROC NEAR
		
		MOV CX, ball_X ; initial col pos: X
		MOV DX, ball_Y ; initial row pos: Y
		
		draw_size:
			
			MOV AH,0Ch 			;set config to write pixel
			MOV AL,0Ch 			; choose color: red
			MOV BH,00h 			; set page num
			INT 10h				; exe config
			
			INC CX 				;increment ballX size CX+1
			
			; if (CX-ball_Size) > ball_Size, keep looping to draw the ball in the X direction
			MOV AX,CX
			SUB AX,ball_X		;;CX-ball_Size
			CMP AX, ball_Size	
			JNG draw_size		;(CX-ball_Size)<ball_Size, jump
			
			MOV CX,ball_X		;reset CX to initial ball x pos
			INC DX 				;increment ballY size DX+1
			
			; if (DX-ball_Size) > ball_Size, keep looping to draw the ball in the Y direction
			MOV AX,DX
			SUB AX,ball_Y		;Dx-ball_Size	
			CMP AX,ball_Size	
			JNG draw_size		;(DX-ball_Size)<ball_Size, jump
			
		
		RET
	DRAW_BALL ENDP
	
	DRAW_PADDLES PROC NEAR
	
		MOV CX, paddle_left_x ; initial col pos: X
		MOV DX, paddle_left_y ; initial row pos: Y
		
		DRAW_PADDLES_LEFT_HORIZONTAL: 
			MOV AH,0Ch 			;set config to write pixel
			MOV AL,0Ch 			; choose color: red
			MOV BH,00h 			; set page num
			INT 10h				; exe config
			
			INC CX 				;increment paddle_left_x size CX+1
			
			; if (CX-paddle_left_x) > paddle_left_x, keep looping to draw the paddle_left_x in the X direction
			MOV AX,CX
			SUB AX,paddle_left_x		;;CX-paddle_left_x
			CMP AX, paddle_width
			JNG DRAW_PADDLES_LEFT_HORIZONTAL		;(CX-paddle_left_x)<paddle_left_x, jump
			
			MOV CX,paddle_left_x		;reset CX to initial ball x pos
			INC DX 				;increment ballY size DX+1
			
			; if (DX-paddle_left_y) > paddle_left_y, keep looping to draw the ball in the Y direction
			MOV AX,DX
			SUB AX,paddle_left_y	;Dx-paddle_left_y
			CMP AX,paddle_height
			JNG DRAW_PADDLES_LEFT_HORIZONTAL		;(DX-paddle_left_y)<ball_Size, jump
			
			
		MOV CX, paddle_right_x ; initial col pos: X
		MOV DX, paddle_right_y ; initial row pos: Y
		
		DRAW_PADDLES_RIGHT_HORIZONTAL: 
			MOV AH,0Ch 			;set config to write pixel
			MOV AL,0Ch 			; choose color: red
			MOV BH,00h 			; set page num
			INT 10h				; exe config
			
			INC CX 				;increment paddle_right_x size CX+1
			
			; if (CX-paddle_right_x) > paddle_right_x, keep looping to draw the paddle_right_x in the X direction
			MOV AX,CX
			SUB AX,paddle_right_x		;;CX-paddle_right_x
			CMP AX, paddle_width
			JNG DRAW_PADDLES_RIGHT_HORIZONTAL		;(CX-paddle_right_x)<paddle_right_x, jump
			
			MOV CX,paddle_right_x		;reset CX to initial ball x pos
			INC DX 				;increment paddle size DX+1
			
			; if (DX-paddle_right_y) > paddle_right_y, keep looping to draw the ball in the Y direction
			MOV AX,DX
			SUB AX,paddle_right_y	;Dx-paddle_right_y
			CMP AX,paddle_height
			JNG DRAW_PADDLES_RIGHT_HORIZONTAL		;(DX-paddle_right_y)<paddle_size, jump
		RET
	DRAW_PADDLES ENDP
	
	MOVE_BALL PROC NEAR
		
		MOV AX, ball_XSpeed
		ADD ball_X,AX			;move ball in xSpeed direction
		
		MOV AX, window_diff
		CMP ball_X,AX			; if current ballX position <= 0+specified window difference, then it collides
		JLE reset_position	; go to reset position instead of jumping from the side
		
		MOV AX, window_Width	
		SUB AX,ball_Size		;account for ball size
		SUB AX,window_diff
		CMP ball_X,AX			;if current ballX position >= window, then it collides
		JGE reset_position		; go to reset position instead of jumping from the side
		
		MOV AX,ball_YSpeed		;move ball in ySpeed direction
		ADD ball_Y,AX
		
		MOV AX, window_diff
		CMP ball_Y,AX			;if current ballY position <=0 + specified window difference, then it collides
		JLE reverse_YSpeed		;reverse the speed
		
		MOV AX,window_Height	;if current ballY position >=window, then it collides
		SUB AX, ball_Size		; account for ball size
		SUB AX, window_diff
		CMP ball_Y,AX			
		JGE reverse_YSpeed		;;reverse the speed
		
		RET
		
		reset_position:
			CALL RESET_BALL_POSITION
			RET
			
		reverse_YSpeed:
			NEG ball_YSpeed
			RET
			
	MOVE_BALL ENDP
	
	MOVE_PADDLES PROC NEAR
		
		;left paddle movement 
		
		;check if a key is being pressed (if not check the other paddle)
		MOV AH, 01h
		INT 16h
		JZ CHECK_RIGHT_PADDLE_MOVEMENT ;ZF = 1, JZ -> Jump If Zero
		
		;check which key is being pressed (AL = ASCII character)
		MOV AH, 00h
		INT 16h
		
		;if it is 'w' or 'W' move up
		CMP AL, 77h ;'w'
		JE MOVE_LEFT_PADDLE_UP
		CMP AL, 57h ;'W'
		JE MOVE_LEFT_PADDLE_UP
		
		;if it is 's' or 'S' move down
		CMP AL, 73h ;'s'
		JE MOVE_LEFT_PADDLE_DOWN
		CMP AL, 53h ;'S'
		JE MOVE_LEFT_PADDLE_DOWN
		JMP CHECK_RIGHT_PADDLE_MOVEMENT
		
		MOVE_LEFT_PADDLE_UP:
			MOV AX, paddle_velocity
			SUB PADDLE_LEFT_Y, AX
			
			;This code is written to keep the paddle in mounds for the windows
			MOV AX, window_diff
			CMP Paddle_left_y, AX
			JL FIX_PADDLE_LEFT_TOP_POSITION
			JMP CHECK_RIGHT_PADDLE_MOVEMENT
			
			FIX_PADDLE_LEFT_TOP_POSITION:
				MOV AX, window_diff
				MOV paddle_left_y, AX
				JMP CHECK_RIGHT_PADDLE_MOVEMENT
			
		MOVE_LEFT_PADDLE_DOWN:
			MOV AX, paddle_velocity
			ADD Paddle_left_y, AX
			
			;This code is written to keep the paddle in mounds for the windows
			MOV AX, window_Height
			SUB AX, window_diff
			SUB AX, paddle_height
			CMP paddle_left_y, AX
			JG FIX_PADDLE_LEFT_BOTTOM_POSITION
			JMP CHECK_RIGHT_PADDLE_MOVEMENT	
			
			FIX_PADDLE_LEFT_BOTTOM_POSITION:
				MOV paddle_left_y, AX
				JMP CHECK_RIGHT_PADDLE_MOVEMENT
		
		;right paddle movement 
		CHECK_RIGHT_PADDLE_MOVEMENT:
		
			;if it is 'l' or 'L' move down
			CMP AL, 6Fh ;'o'
			JE MOVE_RIGHT_PADDLE_UP
			CMP AL, 4Fh ;'O'
			JE MOVE_RIGHT_PADDLE_UP
		
			;if it is 'o' or 'O' move up
			CMP AL, 6Ch ;'l'
			JE MOVE_RIGHT_PADDLE_DOWN
			CMP AL, 4Ch ;'L'
			JE MOVE_RIGHT_PADDLE_DOWN
			JMP EXIT_PADDLE_MOVEMENT
		
			MOVE_RIGHT_PADDLE_UP:
				MOV AX, paddle_velocity
				SUB paddle_right_y, AX
			
				;This code is written to keep the paddle in bounds for the windows
				MOV AX, window_diff
				CMP paddle_right_y, AX
				JL FIX_PADDLE_RIGHT_TOP_POSITION
				JMP EXIT_PADDLE_MOVEMENT
			
				FIX_PADDLE_RIGHT_TOP_POSITION:
					MOV paddle_right_y, AX
					JMP EXIT_PADDLE_MOVEMENT
				
			MOVE_RIGHT_PADDLE_DOWN:
				MOV AX, paddle_velocity
				ADD paddle_right_y, AX
			
				;This code is written to keep the paddle in bounds for the windows
				MOV AX, window_Height
				SUB AX, window_diff
				SUB AX, paddle_height
				CMP paddle_right_y, AX
				JG FIX_PADDLE_RIGHT_BOTTOM_POSITION
				JMP EXIT_PADDLE_MOVEMENT	
			
				FIX_PADDLE_RIGHT_BOTTOM_POSITION:
					MOV paddle_right_y, AX
					JMP EXIT_PADDLE_MOVEMENT
		
		EXIT_PADDLE_MOVEMENT:
	
			RET
		
	MOVE_PADDLES ENDP
	
	RESET_BALL_POSITION PROC NEAR
		MOV AX, ball_origin_x ;change ball position at start
		MOV ball_X, AX
		
		MOV AX, ball_origin_y ;change ball position at start
		MOV ball_Y, AX 
		RET
	RESET_BALL_POSITION ENDP
	
	RESET_SCREEN PROC NEAR
		MOV AH,00h ;set video mode config
		MOV AL,13h ;choose video mode
		INT 10h	;exe config
		
		MOV AH,08h ;set config
		MOV BH,00h ;to background color
		MOV BL,00h ; color: black
		INT 10h ;exe config
		
		RET
	RESET_SCREEN ENDP
	

CODE ENDS
END