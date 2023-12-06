STACK SEGMENT PARA STACK
	DB 64 DUP (' ')
STACK ENDS

DATA SEGMENT PARA 'DATA'
	
	prev_time DB 0   ;used to check if time has passed
	GAME_ACTIVE DB 1 	;1 = Game Active, Start as 1
	WINNER_INDEX DB 0 	;index of the winner (1->P1, 2->P2)
	CURRENT_SCENE DB 0 	;0 -> Main Menu, 1-> Game
	EXITING_GAME DB 0   ;0 -> Stay in Game, 1-> Leave

	TEXT_PLAYER_ONE_POINTS DB '0', '$'  ;string for keeping track of player 1 score
	TEXT_PLAYER_TWO_POINTS DB '0', '$'  ;string for keeping track of player 2 score

	TEXT_GAME_OVER_TITLE DB 'GAME OVER', '$' ;game over menu title
	TEXT_GAME_OVER_WINNER DB 'Player 0 Won', '$' ;Winner string
	TEXT_GAME_OVER_PLAY_AGAIN DB 'Press R to Restart', '$' ;Play Again String
	TEXT_GAME_OVER_MAIN_MENU DB 'Press E to Exit to main menu', '$' ;Game over menu message string

	TEXT_MAIN_MENU_TITLE DB 'MAIN MENU', '$' ;String for Main Menu Title
	TEXT_MAIN_MENU_SINGLEPLAYER DB 'SINGLEPLAYER - S Key', '$' ;String for Singleplayer option
	TEXT_MAIN_MENU_MULTIPLAYER DB 'MULTIPLAYER - M Key', '$' ;String for Multiplayer option
	TEXT_MAIN_MENU_EXIT DB 'EXIT - E Key', '$' ;String for Exit option
	

	ball_origin_x DW 0A0h ;center of screen for ball to return to
	ball_origin_y DW 64h ;center of screen for ball to return to
	ball_X DW 0A0h  ;x pos ball (column) current
	ball_Y DW 64h  ;y pos ball (row) current
	ball_Size DW 05h ;size of ball, set to 25 pixels
	ball_XSpeed DW 07h ; X speed of ball movement
	ball_YSpeed DW 09h ; Y speed of ball movement

	window_Width DW 140h	; x length of window
	window_Height DW 0C8h ; y height of window
	window_diff DW 05h		; you can specify how far from the window borders you want the ball to collide from 

	paddle_left_x DW 0Ah ;paddle x position current
	paddle_left_y DW 0Ah ;paddle y position current
	player_one_points DB 0 ;current point of the left player (player 1)

	paddle_right_x DW 130h ;paddle x position current
	paddle_right_y DW 0Ah ;paddle y position current
	player_two_points DB 0; current point of the right player (player 2)

	AI_CONTROLLED DB 0 	;Should Right Paddle be controlled by ai?

	paddle_width DW 05h ;paddle's width
	paddle_height DW 1Fh ;paddle's height
	paddle_velocity DW 10h ;paddle's velocity
	
	

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

			CMP EXITING_GAME, 01h
			JE START_EXIT_PROCESS
			
			CMP CURRENT_SCENE, 00h		;0 -> Scene is main menu
			JE SHOW_MAIN_MENU			;Disp main menu

			CMP GAME_ACTIVE, 00h ;Check if Game is active (1 -> Active, 0 -> Game Over)
			JE SHOW_GAME_OVER	;If equal, game is over
		
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

			;Previously just called UI for some reason?
			CALL DRAW_UI			  ;Draw entire game user interface
			
			JMP check_time		;keep checking time in an infinite 

			SHOW_GAME_OVER:
				CALL DRAW_GAME_OVER_MENU 	;Draw Game Over Menu
				JMP check_time
				RET
			
			SHOW_MAIN_MENU:
				CALL DRAW_MAIN_MENU
				JMP check_time

			START_EXIT_PROCESS:
				CALL CONCLUDE_EXIT_GAME
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
	
	DRAW_UI PROC NEAR 
;		DRAW THE POINTS OF LEFT PLAYER (PLAER ONE)
		MOV AH,02h					;set cursor pos
		MOV BH,00h					;set page num
		MOV DH,04h					;set row
		MOV DL,06h					;set column
		INT 10h						;Dosbox interrupt

		MOV AH,09h					;Write string to stdout
		LEA DX,TEXT_PLAYER_ONE_POINTS ;DX -> Player One Points (string)
		INT 21h						;print the string

;		DRAW THE POINTS OF THE RIGHT PLAYER (PLAYER TWO)
		MOV AH,02h					;CURSOR POS
		MOV BH,00h					;PAGE NUM
		MOV DH,04h					;ROW
		MOV DL,20h					;COLUMN
		INT 10h						;interrupt

		MOV AH,09h
		LEA DX,TEXT_PLAYER_TWO_POINTS ;DX -> Player Two Points (String)
		INT 21h						;print
		
		RET
	DRAW_UI ENDP


	UPDATE_TEXT_PLAYER_ONE_POINTS PROC NEAR

		XOR AX, AX 					;clean AX
		MOV AL, player_one_points	;Store Player one Points inside AL

		;Before Printing, Convert decimal value to the ascii code character
		;Do this by adding 30h (number to ASCII)
		;and by subtracting 30h (ASCII to number)
		ADD AL, 30h 				;Ascii value of player one points
		MOV [TEXT_PLAYER_ONE_POINTS], AL ;Store this value back into the string  

		RET
	UPDATE_TEXT_PLAYER_ONE_POINTS ENDP



	UPDATE_TEXT_PLAYER_TWO_POINTS PROC NEAR
		XOR AX, AX 			;Clean
		MOV AL, player_two_points ;Store int value

		;Need to Convert to ascii

		Add AL, 30h 		;Int -> Ascii
		MOV [TEXT_PLAYER_TWO_POINTS], AL ;Store this value back into string

		RET
	UPDATE_TEXT_PLAYER_TWO_POINTS ENDP


	DRAW_GAME_OVER_MENU PROC NEAR	;Draw Game over Menu
		CALL RESET_SCREEN  			;need a clear screen to begin drawing

;		Show Game Over Menu
		MOV AH,02h					;CURSOR POS
		MOV BH,00h					;PAGE NUM
		MOV DH,04h					;ROW
		MOV DL,04h					;COLUMN
		INT 10h						;interrupt

		MOV AH,09h					;Write String to stdout
		LEA DX, TEXT_GAME_OVER_TITLE ;DX -> Game Over Title (String)
		INT 21h						;print

;		Show Winner
		MOV AH,02h					;CURSOR POS
		MOV BH,00h					;PAGE NUM
		MOV DH,06h					;ROW
		MOV DL,04h					;COLUMN
		INT 10h						;interrupt

		CALL UPDATE_WINNER_TEXT

		MOV AH,09h					
		LEA DX, TEXT_GAME_OVER_WINNER ;DX -> Player x Winner (String)
		INT 21h						;print

;		Show Play Again Msg
		MOV AH,02h					;CURSOR POS
		MOV BH,00h					;PAGE NUM
		MOV DH,08h					;ROW
		MOV DL,04h					;COLUMN
		INT 10h						;interrupt

		MOV AH,09h					
		LEA DX, TEXT_GAME_OVER_PLAY_AGAIN ;DX -> Game Over Text(String)
		INT 21h						;print

;		Show Exit Msg
		MOV AH,02h					;CURSOR POS
		MOV BH,00h					;PAGE NUM
		MOV DH,0Ah					;ROW
		MOV DL,04h					;COLUMN
		INT 10h						;interrupt

		MOV AH,09h					
		LEA DX, TEXT_GAME_OVER_MAIN_MENU ;DX -> Game Over Menu Text(String)
		INT 21h						;print

;		Wait For R or E Key Press to cont.
		MOV AH,00h			;Wait for key press instruction
		INT 16h				;Interrupt to execute, key press stored in AL

;		R Check
		CMP AL, 'R' 		;If R (or r) key is pressed....
		JE RESTART_GAME		;restart game
		CMP AL, 'r'
		JE RESTART_GAME

;		E Check
		CMP AL, 'E' 		;If R (or r) key is pressed....
		JE EXIT_TO_MAIN_MENU		;restart game
		CMP AL, 'e'
		JE EXIT_TO_MAIN_MENU
		RET

		RESTART_GAME:
			MOV GAME_ACTIVE,01h		;Game state reset

			RET
	
		EXIT_TO_MAIN_MENU:
			MOV GAME_ACTIVE,00h 
			MOV CURRENT_SCENE,00h
			RET
	DRAW_GAME_OVER_MENU ENDP

	DRAW_MAIN_MENU PROC NEAR

	CALL RESET_SCREEN
;		Show Main Menu
		MOV AH,02h					;CURSOR POS
		MOV BH,00h					;PAGE NUM
		MOV DH,04h					;ROW
		MOV DL,04h					;COLUMN
		INT 10h						;interrupt

		MOV AH,09h					;Write String to stdout
		LEA DX, TEXT_MAIN_MENU_TITLE ;DX 
		INT 21h						;print

;		Show Single Player Option Line
		MOV AH,02h					;CURSOR POS
		MOV BH,00h					;PAGE NUM
		MOV DH,06h					;ROW
		MOV DL,04h					;COLUMN
		INT 10h						;interrupt

		MOV AH,09h					;Write String to stdout
		LEA DX, TEXT_MAIN_MENU_SINGLEPLAYER ;DX 
		INT 21h						;print

;		Show Multiplayer Option Line
		MOV AH,02h					;CURSOR POS
		MOV BH,00h					;PAGE NUM
		MOV DH,08h					;ROW
		MOV DL,04h					;COLUMN
		INT 10h						;interrupt

		MOV AH,09h					;Write String to stdout
		LEA DX, TEXT_MAIN_MENU_MULTIPLAYER ;
		INT 21h						;print

;		Show Exit Option Line
		MOV AH,02h					;CURSOR POS
		MOV BH,00h					;PAGE NUM
		MOV DH,0Ah					;ROW
		MOV DL,04h					;COLUMN
		INT 10h						;interrupt

		MOV AH,09h					;Write String to stdout
		LEA DX, TEXT_MAIN_MENU_EXIT ;
		INT 21h						;print

		MAIN_MENU_WAIT_FOR_KEY:
;			Wait For Player Selection.
			MOV AH,00h			;Wait for key press instruction
			INT 16h				;Interrupt to execute, key press stored in AL

;		Check Which Key (option) was pressed

;		s Check
			CMP AL, 'S' 		;If S key is pressed....
			JE START_SINGLEPLAYER		;Start Singleplayer
			CMP AL, 's'
			JE START_SINGLEPLAYER

;		M Check
			CMP AL, 'M' 		;If M key is pressed....
			JE START_MULTIPLAYER		;Start Multiplayer
			CMP AL, 'm'
			JE START_MULTIPLAYER

;		E Check
			CMP AL, 'E' 		;If E key is pressed....
			JE EXIT_GAME		;Exit
			CMP AL, 'e'
			JE EXIT_GAME
			JMP MAIN_MENU_WAIT_FOR_KEY ;Loop infinitely until a key is pressed

		START_SINGLEPLAYER:
			MOV CURRENT_SCENE, 01h
			MOV GAME_ACTIVE, 01h
			RET

		START_MULTIPLAYER:
			MOV CURRENT_SCENE, 01h
			MOV GAME_ACTIVE, 01h
			MOV AI_CONTROLLED, 01h
			RET

		EXIT_GAME:
			MOV EXITING_GAME, 01h
			RET

	DRAW_MAIN_MENU ENDP

	UPDATE_WINNER_TEXT PROC NEAR
		MOV AL, WINNER_INDEX 		;Store the winner (1 or 2) into AL
		ADD AL, 30h					;Convert int to ascii string
		MOV [TEXT_GAME_OVER_WINNER + 7], AL	;Player X becomes winner (x is index 7)
		RET
	UPDATE_WINNER_TEXT ENDP


	CONCLUDE_EXIT_GAME PROC NEAR	;Exit pong game, go back to text mode
		MOV AH, 00h 			;Set config to text mode
		MOV AL, 02h				;Choose text mode
		INT 10h					;Execute config

		MOV AH, 4Ch				;Terminate Program
		INT 21h					;^


		RET
	CONCLUDE_EXIT_GAME ENDP

	MOVE_BALL PROC NEAR
		
		MOV AX, ball_XSpeed
		ADD ball_X,AX			;move ball in xSpeed direction
		
		MOV AX, window_diff
		CMP ball_X,AX			; if current ballX position <= 0+specified window difference, then it collides
		JLE GIVE_POINTS_TO_PLAYER_TWO	;give one point to player two and reset ball position
		
		MOV AX, window_Width	
		SUB AX,ball_Size		;account for ball size
		SUB AX,window_diff
		CMP ball_X,AX			;if current ballX position >= window, then it collides
		JGE GIVE_POINTS_TO_PLAYER_ONE		;give one point to player one and reset ball position
		JMP MOVE_BALL_VERTICALLY
		
		GIVE_POINTS_TO_PLAYER_ONE:
			INC player_one_points ;increment player one points
			CALL RESET_BALL_POSITION ;reset ball to the center of the screen

			CALL UPDATE_TEXT_PLAYER_ONE_POINTS ;UPDATE THE TEXT OF THE PLAYER ONE POINTS

			CMP player_one_points, 05h;check if this player has reached 5 points
			JGE GAME_OVER ;if this player reached 5 or more, the game is over
			RET
			
		GIVE_POINTS_TO_PLAYER_TWO:
			INC player_two_points ;increment player two points
			CALL RESET_BALL_POSITION ;reset ball to the center of the screen

			CALL UPDATE_TEXT_PLAYER_TWO_POINTS ;UPDATE THE TEXT OF THE PLAYER TWO POINTS
			
			CMP player_two_points, 05h;check if this player has reached 5 points
			JGE GAME_OVER ;if this player reached 5 or more, the game is over
			RET
			
		GAME_OVER: ;someone has reached 5 points

			CMP player_one_points,05h ;Check who reached 5 points, change winner index based off that
			JNL WINNER_IS_PLAYER_ONE
			JMP WINNER_IS_PLAYER_TWO

			WINNER_IS_PLAYER_ONE:			;P1 Wins
					MOV WINNER_INDEX, 01h
					JMP CONTINUE_GAME_OVER

			WINNER_IS_PLAYER_TWO:			;P2 Wins
					MOV WINNER_INDEX, 02h
					JMP CONTINUE_GAME_OVER
			
			CONTINUE_GAME_OVER:
				MOV player_one_points, 00h ;restart player one points
				MOV player_two_points, 00h ;restart player two points
				CALL UPDATE_TEXT_PLAYER_ONE_POINTS
				CALL UPDATE_TEXT_PLAYER_TWO_POINTS
				MOV GAME_ACTIVE,00h 		;Stops Game
				MOV AI_CONTROLLED, 00h


				RET
		
		MOVE_BALL_VERTICALLY: 		
			MOV AX,ball_YSpeed		;move ball in ySpeed direction
			ADD ball_Y,AX
		
		MOV AX, window_diff
		CMP ball_Y,AX			;if current ballY position <=0 + specified window difference, then it collides
		JLE NEG_VELOCITY_Y		;reverse the speed
		
		MOV AX,window_Height	;if current ballY position >=window, then it collides
		SUB AX, ball_Size		; account for ball size
		SUB AX, window_diff
		CMP ball_Y,AX			
		JGE NEG_VELOCITY_Y		;reverse the speed
		
		;Check if the ball is colliding with the right paddle 
		;maxx1 > minx2 && minx1 < maxx2 && maxy1 > miny1 && miny1 < maxy2
		;ball_x + ball_Size > paddle_right_x && ball_x < paddle_right_x + paddle_width && ball_y + ball_Size > paddle_right_y && ball_y < paddle_right_y + paddle_height
		
		MOV AX, ball_x 
		ADD AX, ball_Size
		CMP AX, paddle_right_x
		JNG CHECK_COLLISION_WITH_LEFT_PADDLE ;if there's no collision check for the left paddle collisions
		
		MOV AX, paddle_right_x
		ADD AX, paddle_width
		CMP ball_X, AX
		JNL CHECK_COLLISION_WITH_LEFT_PADDLE ;if there's no collision check for the left paddle collisions
		
		MOV AX, ball_Y
		ADD AX, ball_Size
		CMP AX, paddle_right_y
		JNG CHECK_COLLISION_WITH_LEFT_PADDLE ;if there's no collision check for the left paddle collisions
		
		MOV AX, paddle_right_y
		ADD AX, paddle_height
		CMP ball_Y, AX
		JNL CHECK_COLLISION_WITH_LEFT_PADDLE ;if there's no collision check for the left paddle collisions
		
		JMP NEG_VELOCITY_X
		
		;Check if the ball is colliding with the left paddle 
		CHECK_COLLISION_WITH_LEFT_PADDLE: 
			MOV AX, ball_x 
			ADD AX, ball_Size
			CMP AX, paddle_left_x
			JNG EXIT_COLLISION_CHECK ;if there's no collision exit procedure
		
			MOV AX, paddle_left_x
			ADD AX, paddle_width
			CMP ball_X, AX
			JNL EXIT_COLLISION_CHECK ;if there's no collision exit procedure
		
			MOV AX, ball_Y
			ADD AX, ball_Size
			CMP AX, paddle_left_y
			JNG EXIT_COLLISION_CHECK ;if there's no collision exit procedure
		
			MOV AX, paddle_left_y
			ADD AX, paddle_height
			CMP ball_Y, AX
			JNL EXIT_COLLISION_CHECK ;if there's no collision check for the right paddle collisions
			
		JMP NEG_VELOCITY_X
		
		NEG_VELOCITY_Y:
			NEG ball_YSpeed ;Reverse the horizontal velocity of the ball
			RET
			
		NEG_VELOCITY_X:
			NEG ball_XSpeed
			RET
		
	
		EXIT_COLLISION_CHECK:
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
			CMP AI_CONTROLLED, 01h
			JE CONTROL_BY_AI

;			User controlled paddle (Through Key Press)
			CHECK_FOR_KEYS:
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
			
;			Pattle Controlled by AI
			CONTROL_BY_AI:
				;Check if ball is above paddle (ball_y + ball_size < paddle_right_y)
				;->Move paddle up
				MOV AX, Ball_y
				ADD AX, ball_Size
				CMP AX, paddle_right_y
				JL MOVE_RIGHT_PADDLE_UP
				
				;Check if ball is below paddle (Ball_y > paddle_right_y + paddle_height)
				;->Move paddle down
				MOV AX, paddle_right_y
				ADD AX, paddle_height
				CMP AX, ball_y
				JL MOVE_RIGHT_PADDLE_DOWN
				
				;If neither, don't move paddle
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