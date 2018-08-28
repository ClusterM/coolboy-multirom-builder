BUTTONS .rs 1 ; текущие нажатия кнопок
BUTTONS_TMP .rs 1 ; временная переменная для кнопок
BUTTONS_HOLD_TIME .rs 1 ; время удержания вверх или вниз
KONAMI_CODE_STATE .rs 1 ; состояние KONAMI кода

	; чтение контроллера, два раза
read_controller:
	pha
	tya
	pha
	txa
	pha
	jsr .real ; первый раз
	ldx <BUTTONS_TMP
	jsr .real ; второй раз
	cpx <BUTTONS_TMP ; сравниваем два значения
	bne .end ; если они не совпадают, больше ничего не делаем
	stx <BUTTONS ; записываем значения
	txa
	and #%11110000 ; вверх и вниз
	beq .no_up_down ; если они не нажаты...
	inc	<BUTTONS_HOLD_TIME ; увеличиваем время удержания кнопок
	lda <BUTTONS_HOLD_TIME
	cmp #60 ; держим их долго?
	bcc .end ; нет
	lda #0 ; да, якобы отпускаем все кнопки
	sta <BUTTONS
	lda #50 ; и уменьшаем время до повтора
	sta <BUTTONS_HOLD_TIME
	jmp .end

.no_up_down:
	lda #0 ; время удержания кнопок равно нулю
	sta <BUTTONS_HOLD_TIME
.end:
	pla
	tax
	pla
	tay
	pla
	rts
	
	; чтение контроллера, настоящее
.real:
	;php
	lda #1
	sta $4016
	lda #0
	sta $4016
	ldy #8
.read_button:
	lda $4016
	and #$03
	cmp #$01
	ror <BUTTONS_TMP
	dey
	bne .read_button
	rts

buttons_check:
	; в большинстве случаев кнопки не нажаты, зачем тратить время на проверку?
	lda <BUTTONS
	cmp #$00
	bne .start_check
	rts
.start_check:
	jsr konami_code_check
.button_a:
	lda <BUTTONS
	and #%00000001	
	beq .button_b
	jsr start_sound
	jmp start_game
	
.button_b:
	lda <BUTTONS
	and #%00000010	
	beq .button_start	
	; nothing to do
	jmp .button_end
	
.button_start:
	lda <BUTTONS
	and #%00001000
	beq .button_up
	jsr start_sound
	jmp start_game

.button_up:
	lda <BUTTONS
	and #%00010000
	beq .button_down
	jsr bleep
	lda <SELECTED_GAME
	sec
	sbc #1
	sta <SELECTED_GAME
	lda <SELECTED_GAME+1
	sbc #0
	sta <SELECTED_GAME+1
	bmi .button_up_ovf
	jsr .check_separator_up
	jmp .button_end
.button_up_ovf:
	lda games_count
	sec
	sbc #1
	sta <SELECTED_GAME
	lda games_count+1
	sbc #0
	sta <SELECTED_GAME+1
	jmp .button_end

.button_down:
	lda <BUTTONS
	and #%00100000
	beq .button_left
	jsr bleep
	lda <SELECTED_GAME
	clc
	adc #1
	sta <SELECTED_GAME
	lda <SELECTED_GAME+1
	adc #0
	sta <SELECTED_GAME+1
	cmp games_count+1
	bne .button_down_not_ovf
	lda <SELECTED_GAME
	cmp games_count
	beq .button_down_ovf	
.button_down_not_ovf:
	jsr .check_separator_down
	jmp .button_end
.button_down_ovf:
	lda #0
	sta <SELECTED_GAME
	sta <SELECTED_GAME+1
	jmp .button_end
	
.button_left:
	lda <BUTTONS
	and #%01000000
	beq .button_right
	lda <SELECTED_GAME
	bne .button_left_bleep
	lda <SELECTED_GAME+1
	bne .button_left_bleep
	jmp .button_right
.button_left_bleep:
	jsr bleep
	lda <SCROLL_LINES_TARGET
	sec
	sbc #10
	sta <SCROLL_LINES_TARGET
	lda <SCROLL_LINES_TARGET+1
	sbc #0
	sta <SCROLL_LINES_TARGET+1
	bmi .button_left_ovf
	jmp .button_left2
.button_left_ovf:
	lda #0
	sta <SCROLL_LINES_TARGET
	sta <SCROLL_LINES_TARGET+1
.button_left2:
	lda <SELECTED_GAME
	sec
	sbc #10
	sta <SELECTED_GAME
	lda <SELECTED_GAME+1
	sbc #0
	sta <SELECTED_GAME+1
	bmi .button_left_ovf2
	jsr .check_separator_up
	jmp .button_end
.button_left_ovf2:
	lda #0
	sta <SELECTED_GAME
	sta <SELECTED_GAME+1
	jmp .button_end

.button_right:
	lda <BUTTONS
	and #%10000000
	bne .button_right_check
	jmp .button_end
.button_right_check:
	; если это не последняя игра, надо блипнуть
	lda <SELECTED_GAME
	clc
	adc #1
	cmp games_count
	bne .button_right_bleep	
	lda <SELECTED_GAME
	clc
	adc #1
	lda <SELECTED_GAME+1
	adc #0
	cmp games_count+1
	bne .button_right_bleep
	jmp .button_end	
.button_right_bleep:
	jsr bleep
	lda <SCROLL_LINES_TARGET
	clc
	adc #10
	sta <SCROLL_LINES_TARGET
	lda <SCROLL_LINES_TARGET+1
	adc #0
	sta <SCROLL_LINES_TARGET+1
	; проверка на переполнение скроллинга
	lda <SCROLL_LINES_TARGET
	sec
	sbc maximum_scroll
	lda <SCROLL_LINES_TARGET+1
	sbc maximum_scroll+1
	bcs .button_right_ovf
.button_right_not_ovf:
	jmp .button_right2
.button_right_ovf:
	lda maximum_scroll
	sta <SCROLL_LINES_TARGET
	lda maximum_scroll+1
	sta <SCROLL_LINES_TARGET+1
.button_right2:
	lda <SELECTED_GAME
	clc
	adc #10
	sta <SELECTED_GAME
	lda <SELECTED_GAME+1
	adc #0
	sta <SELECTED_GAME+1
	; проверка на переполнение выбранной игры
	lda <SELECTED_GAME
	sec
	sbc games_count
	lda <SELECTED_GAME+1
	sbc games_count+1
	bcs .button_right_ovf2
.button_right_not_ovf2:
	jsr .check_separator_down
	jmp .button_end
.button_right_ovf2:
	lda games_count
	sec
	sbc #1
	sta <SELECTED_GAME
	lda games_count+1
	sbc #0
	sta <SELECTED_GAME+1
	jmp .button_end

.button_none:
	; это никогда не должно выполняться, ведь других кнопок нет, а что-то нажато
	rts
	
.button_end:
	jsr set_cursor_targets ; самое время обновить цели
	jsr wait_buttons_not_pressed
	rts

; пропускаем разделители при прокрутке вверх
.check_separator_down:
	lda <SELECTED_GAME+1
	jsr select_bank
	ldx <SELECTED_GAME
	lda loader_data_game_type, x
	and #$80
	beq .check_separator_down_end
	lda <SELECTED_GAME
	clc
	adc #1
	sta <SELECTED_GAME
	lda <SELECTED_GAME+1
	adc #0
	sta <SELECTED_GAME+1
	jmp .check_separator_down	
.check_separator_down_end:
	rts

; пропускаем разделители при прокрутке вниз
.check_separator_up:
	lda <SELECTED_GAME+1
	jsr select_bank
	ldx <SELECTED_GAME
	lda loader_data_game_type, x
	and #$80
	beq .check_separator_up_end
	lda <SELECTED_GAME
	sec
	sbc #1
	sta <SELECTED_GAME
	lda <SELECTED_GAME+1
	sbc #0
	sta <SELECTED_GAME+1
	jmp .check_separator_up	
.check_separator_up_end:
	rts
	
	; ждём, пока игрок не отпустит кнопку
wait_buttons_not_pressed:
	jsr waitblank ; ждём, пока дорисуется экран
	lda <BUTTONS
	;and #$FF ; wtf?
	bne wait_buttons_not_pressed
	rts
	
konami_code_check:
	ldy <KONAMI_CODE_STATE
	lda konami_code, y
	cmp <BUTTONS
	bne konami_code_check_fail
	iny
	jmp konami_code_check_end
konami_code_check_fail:
	ldy #0
	lda konami_code ; на случай если неверная кнопка - начало верной последовательности
	cmp <BUTTONS
	bne konami_code_check_end
	iny
konami_code_check_end:
	sty <KONAMI_CODE_STATE
	rts

konami_code:
	.db $10, $10, $20, $20, $40, $80, $40, $80, $02, $01
konami_code_length:
	.db 10
