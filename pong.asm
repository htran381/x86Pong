STACK SEGMENT PARA STACK
	DB 64 DUP (' ')
STACK ENDS

DATA SEGMENT PARA 'DATA'
	
	prev_time DB 0   ;used to check if time has passed
	ball_X DW 0Ah  ;x pos ball (column)
	ball_Y DW 0Ah  ;y pos ball (row)
	ball_Size DW 05h ;size of ball, set to 25 pixels
	ball_XSpeed DW 05h ; X speed of ball movement
	ball_YSpeed DW 07h ; Y speed of ball movement
	window_Width DW 140h	; x length of window
	window_Height DW 0C8h ; y height of window
	window_diff DW 05h		; you can specify how far from the window borders you want the ball to collide from 
	

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
	
	MOVE_BALL PROC NEAR
		
		MOV AX, ball_XSpeed
		ADD ball_X,AX			;move ball in xSpeed direction
		
		MOV AX, window_diff
		CMP ball_X,AX			; if current ballX position <= 0+specified window difference, then it collides
		JLE reverse_XSpeed		; reverse the speed
		
		MOV AX, window_Width	
		SUB AX,ball_Size		;account for ball size
		SUB AX,window_diff
		CMP ball_X,AX			;if current ballX position >= window, then it collides
		JGE reverse_XSpeed		;reverse speed 
		
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
		
		reverse_XSpeed:
			NEG ball_XSpeed
			RET
			
		reverse_YSpeed:
			NEG ball_YSpeed
			RET
			
	MOVE_BALL ENDP
	
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