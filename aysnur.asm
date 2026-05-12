.data
# Beethoven - Ode to Joy / 9. Senfoni
# 1=DO, 2=RE, 3=MI, 4=FA, 5=SOL, 6=LA
#
# Melodi:
# MI MI FA SOL | SOL FA MI RE | DO DO RE MI | MI RE RE
# MI MI FA SOL | SOL FA MI RE | DO DO RE MI | RE DO DO

# Interrupt haberleşme değişkenleri
pressed_key: .word 0    # Basılan tuşun ASCII değeri
has_new_key: .word 0    # 1 ise yeni tuş var, 0 ise yok

.eqv MAX_SCORE 48
# Level 1: 8 nota
level1_keys: .word 51, 51, 52, 53, 53, 52, 51, 50

# Level 2: 15 nota
level2_keys: .word 51, 51, 52, 53, 53, 52, 51, 50, 49, 49, 50, 51, 51, 50, 50

# Level 3: 25 nota
level3_keys: .word 51, 51, 52, 53, 53, 52, 51, 50, 49, 49, 50, 51, 51, 50, 50, 51, 51, 52, 53, 53, 52, 51, 50, 49, 49

.text
.globl main

main:
    li $t0, 0xFFFF0000
    li $t1, 2              # Interrupt Enable biti
    sw $t1, 0($t0)

    # CPU interruptları kabul etsin
    mfc0 $t0, $12          # Status register oku
    ori $t0, $t0, 0x01     # Interrupt Enable bitini 1 yap
    mtc0 $t0, $12          # Status registera geri yaz
    
    li $s0, 0          # skor
    li $s1, 1          # level
    li $s6, 0          # onceki basilan tus
    li $s7, 0          # onceki hedef tus

    jal draw_start_screen

wait_start:
    lw $t1, has_new_key
    beq $t1, $zero, wait_start  # Yeni tuş yoksa beklemeye devam et

    lw $t2, pressed_key         # Basılan tuşu al
    sw $zero, has_new_key       # Bayrağı clearle
    bne $t2, 32, wait_start     # SPACE start

level_start:
    beq $s1, 1, level1
    beq $s1, 2, level2
    beq $s1, 3, level3
    j game_over

level1:
    la $s3, level1_keys
    li $s4, 0
    li $s5, 8
    li $s6, 0
    li $s7, 0
    jal draw_piano
    jal draw_level_circles
    jal draw_score_bar
    j game_loop

level2:
    la $s3, level2_keys
    li $s4, 0
    li $s5, 15
    li $s6, 0
    li $s7, 0
    jal draw_piano
    jal draw_level_circles
    jal draw_score_bar
    j game_loop

level3:
    la $s3, level3_keys
    li $s4, 0
    li $s5, 25
    li $s6, 0
    li $s7, 0
    jal draw_piano
    jal draw_level_circles
    jal draw_score_bar
    j game_loop

game_loop:
    beq $s4, $s5, next_level

    move $a0, $s7
    jal restore_key

    move $a0, $s6
    jal restore_key

    lw $s2, 0($s3)
    move $s7, $s2

    move $a0, $s2
    li $a1, 1
    jal color_key

wait_key:
    jal get_time_limit
    move $t7, $v0          # kalan sure

wait_key_loop:
    beq $t7, $zero, missed_note

    lw $t1, has_new_key
    beq $t1, $zero, no_key_pressed  # Yeni tuş yoksa süreyi azalt

    # Yeni tuş geldiyse:
    lw $t2, pressed_key         # Tuşu al
    sw $zero, has_new_key       # Bayrağı sıfırla

    beq $t2, 49, valid_key
    beq $t2, 50, valid_key
    beq $t2, 51, valid_key
    beq $t2, 52, valid_key
    beq $t2, 53, valid_key
    beq $t2, 54, valid_key

no_key_pressed:
    addi $t7, $t7, -1
    j wait_key_loop

valid_key:
    move $s6, $t2

    beq $s6, $s2, correct
    j wrong

correct:
    addi $s0, $s0, 1
    jal draw_score_bar
    
    move $a0, $s6
    li $a1, 2              # yesil
    jal color_key

    move $a0, $s6
    jal play_note

    jal delay
    j next_note

missed_note:
    addi $s0, $s0, -1
    jal draw_score_bar

    move $a0, $s2
    li $a1, 3              # hedef tus kirmizi olsun
    jal color_key

    jal draw_score_bar
    jal delay
    j next_note

wrong:
    addi $s0, $s0, -1
    jal draw_score_bar

    move $a0, $s6
    li $a1, 3               # kirmizi
    jal color_key

    move $a0, $s6
    jal play_note

    jal delay
    j next_note

next_note:
    addi $s3, $s3, 4
    addi $s4, $s4, 1
    j game_loop

next_level:
    addi $s1, $s1, 1
    j level_start

game_over:
    jal draw_end_screen

end:
    j end


# -------------------------
# SOUND
# -------------------------

# a0 = tus ASCII
play_note:
    beq $a0, 49, sound_do
    beq $a0, 50, sound_re
    beq $a0, 51, sound_mi
    beq $a0, 52, sound_fa
    beq $a0, 53, sound_sol
    beq $a0, 54, sound_la
    jr $ra

sound_do:
    li $a0, 60
    j sound_play

sound_re:
    li $a0, 62
    j sound_play

sound_mi:
    li $a0, 64
    j sound_play

sound_fa:
    li $a0, 65
    j sound_play

sound_sol:
    li $a0, 67
    j sound_play

sound_la:
    li $a0, 69
    j sound_play

sound_play:
    li $v0, 31
    li $a1, 1500
    li $a2, 0
    li $a3, 100
    syscall
    jr $ra


# -------------------------
# START / END
# -------------------------

draw_start_screen:
    addi $sp, $sp, -4
    sw $ra, 0($sp)

    # siyah arka plan
    li $a0, 0
    li $a1, 0
    li $a2, 64
    li $a3, 64
    li $t9, 0x00000000
    jal draw_rect

    # buyuk koyu yesil kart
    li $a0, 10
    li $a1, 18
    li $a2, 44
    li $a3, 28
    li $t9, 0x00008000
    jal draw_rect

    # parlak yesil ic alan
    li $a0, 14
    li $a1, 22
    li $a2, 36
    li $a3, 20
    li $t9, 0x0000FF00
    jal draw_rect

    # beyaz dekor cizgisi
    li $a0, 22
    li $a1, 31
    li $a2, 20
    li $a3, 2
    li $t9, 0x00FFFFFF
    jal draw_rect

    # alt golge
    li $a0, 10
    li $a1, 46
    li $a2, 44
    li $a3, 3
    li $t9, 0x00404040
    jal draw_rect

    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra

draw_end_screen:
    addi $sp, $sp, -4
    sw $ra, 0($sp)

    # siyah arka plan
    li $a0, 0
    li $a1, 0
    li $a2, 64
    li $a3, 64
    li $t9, 0x00000000
    jal draw_rect

    # skora göre renk seç
    bltz $s0, end_red
    beq $s0, $zero, end_orange
    j end_green

end_red:
    li $t9, 0x00FF0000
    j draw_end_box

end_orange:
    li $t9, 0x00FFA500
    j draw_end_box

end_green:
    li $t9, 0x0000FF00
    j draw_end_box

draw_end_box:
    # büyük renkli dikdörtgen
    li $a0, 10
    li $a1, 18
    li $a2, 44
    li $a3, 28
    jal draw_rect

    # iç beyaz çizgi
    li $a0, 22
    li $a1, 31
    li $a2, 20
    li $a3, 2
    li $t9, 0x00FFFFFF
    jal draw_rect

    # alt gölge
    li $a0, 10
    li $a1, 46
    li $a2, 44
    li $a3, 3
    li $t9, 0x00404040
    jal draw_rect

    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra


# -------------------------
# PIANO
# -------------------------

draw_piano:
    addi $sp, $sp, -4
    sw $ra, 0($sp)

    # Arka plan
    li $a0, 0
    li $a1, 0
    li $a2, 64
    li $a3, 64
    li $t9, 0x00C0C0C0
    jal draw_rect

    # Ust siyah alan
    li $a0, 0
    li $a1, 0
    li $a2, 64
    li $a3, 16
    li $t9, 0x00000000
    jal draw_rect

    # Beyaz tuslar
    li $a0, 0
    li $a1, 18
    li $a2, 64
    li $a3, 46
    li $t9, 0x00FFFFFF
    jal draw_rect

    jal draw_separators

    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra

draw_separators:
    addi $sp, $sp, -4
    sw $ra, 0($sp)

    li $a0, 10
    li $a1, 18
    li $a2, 1
    li $a3, 46
    li $t9, 0x00000000
    jal draw_rect

    li $a0, 21
    li $a1, 18
    li $a2, 1
    li $a3, 46
    li $t9, 0x00000000
    jal draw_rect

    li $a0, 32
    li $a1, 18
    li $a2, 1
    li $a3, 46
    li $t9, 0x00000000
    jal draw_rect

    li $a0, 43
    li $a1, 18
    li $a2, 1
    li $a3, 46
    li $t9, 0x00000000
    jal draw_rect

    li $a0, 54
    li $a1, 18
    li $a2, 1
    li $a3, 46
    li $t9, 0x00000000
    jal draw_rect

    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra


# a0 = tus ASCII
restore_key:
    beq $a0, $zero, restore_end

    addi $sp, $sp, -4
    sw $ra, 0($sp)

    li $a1, 0
    jal color_key

    lw $ra, 0($sp)
    addi $sp, $sp, 4

restore_end:
    jr $ra


# a0 = tus ASCII
# a1 = renk tipi
# 0 beyaz, 1 sari, 2 yesil, 3 kirmizi
color_key:
    addi $sp, $sp, -8
    sw $ra, 0($sp)
    sw $a1, 4($sp)

    beq $a0, 49, key1
    beq $a0, 50, key2
    beq $a0, 51, key3
    beq $a0, 52, key4
    beq $a0, 53, key5
    beq $a0, 54, key6
    j color_key_end

key1:
    li $a0, 0
    li $t8, 10
    j choose_color

key2:
    li $a0, 11
    li $t8, 10
    j choose_color

key3:
    li $a0, 22
    li $t8, 10
    j choose_color

key4:
    li $a0, 33
    li $t8, 10
    j choose_color

key5:
    li $a0, 44
    li $t8, 10
    j choose_color

key6:
    li $a0, 55
    li $t8, 9
    j choose_color

choose_color:
    lw $t0, 4($sp)

    beq $t0, 0, color_white
    beq $t0, 1, color_yellow
    beq $t0, 2, color_green
    beq $t0, 3, color_red

color_white:
    li $t9, 0x00FFFFFF
    j paint_key

color_yellow:
    li $t9, 0x00FFFF00
    j paint_key

color_green:
    li $t9, 0x0000FF00
    j paint_key

color_red:
    li $t9, 0x00FF0000
    j paint_key

paint_key:
    li $a1, 18
    move $a2, $t8
    li $a3, 46
    jal draw_rect
    jal draw_separators

color_key_end:
    lw $ra, 0($sp)
    addi $sp, $sp, 8
    jr $ra


# -------------------------
# LEVEL CIRCLES
# -------------------------

draw_level_circles:
    addi $sp, $sp, -4
    sw $ra, 0($sp)

    # Once ust alani temizle
    li $a0, 0
    li $a1, 0
    li $a2, 64
    li $a3, 8
    li $t9, 0x00000000
    jal draw_rect

    # 3 bos daire
    li $a0, 8
    li $a1, 1
    li $a2, 0
    jal draw_small_circle

    li $a0, 30
    li $a1, 1
    li $a2, 0
    jal draw_small_circle

    li $a0, 52
    li $a1, 1
    li $a2, 0
    jal draw_small_circle

    # Level kadar dolu daire
    blt $s1, 1, circles_end
    li $a0, 8
    li $a1, 1
    li $a2, 1
    jal draw_small_circle

    blt $s1, 2, circles_end
    li $a0, 30
    li $a1, 1
    li $a2, 1
    jal draw_small_circle

    blt $s1, 3, circles_end
    li $a0, 52
    li $a1, 1
    li $a2, 1
    jal draw_small_circle

circles_end:
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra


# a0=x, a1=y, a2=0 bos / 1 dolu
draw_small_circle:
    addi $sp, $sp, -16
    sw $ra, 0($sp)
    sw $a0, 4($sp)
    sw $a1, 8($sp)
    sw $a2, 12($sp)

    beq $a2, 1, filled_small_circle

empty_small_circle:
    li $t9, 0x00FFFFFF

    lw $a0, 4($sp)
    addi $a0, $a0, 1
    lw $a1, 8($sp)
    li $a2, 2
    li $a3, 1
    jal draw_rect

    lw $a0, 4($sp)
    addi $a0, $a0, 1
    lw $a1, 8($sp)
    addi $a1, $a1, 3
    li $a2, 2
    li $a3, 1
    jal draw_rect

    lw $a0, 4($sp)
    lw $a1, 8($sp)
    addi $a1, $a1, 1
    li $a2, 1
    li $a3, 2
    jal draw_rect

    lw $a0, 4($sp)
    addi $a0, $a0, 3
    lw $a1, 8($sp)
    addi $a1, $a1, 1
    li $a2, 1
    li $a3, 2
    jal draw_rect

    j small_circle_done

filled_small_circle:
    li $t9, 0x0000FF00

    lw $a0, 4($sp)
    lw $a1, 8($sp)
    li $a2, 4
    li $a3, 4
    jal draw_rect

small_circle_done:
    lw $ra, 0($sp)
    addi $sp, $sp, 16
    jr $ra

# -------------------------
# BASIC DRAW
# -------------------------

draw_rect:
    move $t0, $a0
    move $t1, $a1
    move $t2, $a2
    move $t3, $a3
    move $t4, $t9

    li $t5, 0

rect_row:
    beq $t5, $t3, rect_done
    li $t6, 0

rect_col:
    beq $t6, $t2, rect_next_row

    add $t7, $t0, $t6
    add $t8, $t1, $t5

    sll $t8, $t8, 6
    add $t8, $t8, $t7
    sll $t8, $t8, 2

    li $t7, 0x10008000
    add $t8, $t8, $t7

    sw $t4, 0($t8)

    addi $t6, $t6, 1
    j rect_col

rect_next_row:
    addi $t5, $t5, 1
    j rect_row

rect_done:
    jr $ra
    
get_time_limit:
    beq $s1, 1, time_level1
    beq $s1, 2, time_level2
    beq $s1, 3, time_level3

time_level1:
    li $v0, 600000
    jr $ra

time_level2:
    li $v0, 500000
    jr $ra

time_level3:
    li $v0, 400000
    jr $ra

draw_score_bar:
    addi $sp, $sp, -4
    sw $ra, 0($sp)

    # skor alanini temizle
    li $a0, 4
    li $a1, 14
    li $a2, 56
    li $a3, 2
    li $t9, 0x00404040
    jal draw_rect
    
    
    # orta nokta daha ince/silik
    li $a0, 32
    li $a1, 14
    li $a2, 1
    li $a3, 2
    li $t9, 0x00808080
    jal draw_rect

    beq $s0, $zero, score_done
    bgtz $s0, positive_score

negative_score:
    sub $t0, $zero, $s0
    li $t1, MAX_SCORE
    bgt $t0, $t1, neg_limit
    j neg_scale

neg_limit:
    li $t0, MAX_SCORE

neg_scale:
    li $t2, 28
    mul $t0, $t0, $t2
    li $t1, MAX_SCORE
    div $t0, $t1
    mflo $t0

    beq $t0, $zero, neg_min
    j draw_neg

neg_min:
    li $t0, 1

draw_neg:
    li $a0, 32
    sub $a0, $a0, $t0
    li $a1, 14
    move $a2, $t0
    li $a3, 2
    li $t9, 0x00FF0000
    jal draw_rect
    j score_done

positive_score:
    move $t0, $s0
    li $t1, MAX_SCORE
    bgt $t0, $t1, pos_limit
    j pos_scale

pos_limit:
    li $t0, MAX_SCORE

pos_scale:
    li $t2, 28
    mul $t0, $t0, $t2
    li $t1, MAX_SCORE
    div $t0, $t1
    mflo $t0

    beq $t0, $zero, pos_min
    j draw_pos

pos_min:
    li $t0, 1

draw_pos:
    li $a0, 33
    li $a1, 14
    move $a2, $t0
    li $a3, 2
    li $t9, 0x0000FF00
    jal draw_rect

score_done:
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra

delay:
    beq $s1, 1, delay_level1
    beq $s1, 2, delay_level2
    beq $s1, 3, delay_level3

delay_level1:
    li $t0, 190000
    j delay_loop

delay_level2:
    li $t0, 160000
    j delay_loop

delay_level3:
    li $t0, 130000
    j delay_loop

delay_loop:
    addi $t0, $t0, -1
    bgtz $t0, delay_loop
    jr $ra
# =========================================================
# KERNEL TEXT - INTERRUPT HANDLER 
# =========================================================
.ktext 0x80000180
    # $at (assembler temporary) registerını yedeğe alıyoruz 
    move $k0, $at 

    # Klavyeden gelen tuşu oku
    li $k1, 0xFFFF0004
    lw $k1, 0($k1)

    # Okunan tuşu hafızaya kaydet
    sw $k1, pressed_key

    # Yeni tuş basıldı flagi 1 yap
    li $k1, 1
    sw $k1, has_new_key

    # İşlemi bitir ve koda kaldığı yerden devam et
    move $at, $k0
    eret