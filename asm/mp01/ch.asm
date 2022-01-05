; Микропроект №1
; Автор: Борисов Костя
; Группа: БПИ199
; Дата: 10.10.2020
; Вариант: 3

; Разработать программу, вычисляющую с
; помощью степенного ряда с точностью не
; хуже 0.1% значение функции
; гиперболического косинуса ch(x)=(ex+e-x)/2
; для конкретного параметра x
; (использовать FPU)

format PE console
entry start
include 'win32a.inc'

section '.code' code readable executable
  ; эта функция проверяет запущенны ли мы из cmd.exe и можно ли нам закрытся сразу
  isGetchNeeded:
    call [GetConsoleWindow]

    push consoleWindowProcessId
    push eax
    call [GetWindowThreadProcessId]

    call [GetCurrentProcessId]
    cmp eax, [consoleWindowProcessId]
    mov eax, 0
    jne isGetchNeeded_ret
    mov eax, 1
    isGetchNeeded_ret:
    test eax, eax
    ret

  ; это функция красиво выходит
  gracefulExit:
    call isGetchNeeded
    jz gracefulExit_exit

    ; если мы выедим сейчас то пользователь ничего неуспеет увидить
    push exitStr
    call [printf]
    add esp, 4
    call [getch]

    gracefulExit_exit:
    push 0
    call [exit]
    add esp, 4
    ret

  ; эта функция меняет кодировку консоли на UTF8 и читает argv
  dramaticEntrance:
    push 65001
    call [SetConsoleOutputCP]

    push env
    push 0
    push env
    push argv
    push argc
    call [getmainargs]
    add esp, 20

    ret

  ; эта функция выводит два последних значений частичной суммы ряда (только когда надо)
  debugLog:
    cmp dword[argc], 3
    jne debugLog_ret
    push ecx
    push dword[chres+4]
    push dword[chres]
    push dword[prevchres+4]
    push dword[prevchres]
    push ecx
    push debugFormat_printf
    call [printf]
    add esp, 24
    pop ecx
    debugLog_ret:
    ret

  ; эта функция проверяет можно ли от этого числа взять адекватный
  checkHyperbolicCosineBounds:
    finit
    fld qword[x]
    fabs
    fild dword[hundred]
    fcompp
    fstsw ax
    sahf
    jb checkHyperbolicCosineBounds_fail
    ret

    checkHyperbolicCosineBounds_fail:
    push dword[x+4]
    push dword[x]
    push floatWrongFormat_printf
    call [printf]
    add esp, 20
    call gracefulExit
    ret

  ; эта функция считает chres = ch(x)
  hyperbolicCosine:
    ; ряд у нас x**(2n)/(2n)!
    finit
    fld qword[x]
    fmul st0,st0
    fst qword[tmpPow]
    fstp qword[tmpSquare]

    fld1
    fstp qword[chres]
    fild dword[two]
    fstp qword[tmpFactorial]

    ; начало цикла
    mov ecx, 3
    hyperbolicCosine_loop:
    fld qword[tmpPow]
    fdiv qword[tmpFactorial]
    fadd qword[chres]
    fst qword[chres]

    ; мы тут сравниваем флоты как инты
    mov eax, [chres+4]
    cmp eax, 0x7ff00000
    je hyperbolicCosine_fixInf
    cmp eax, [prevchres+4]
    jne hyperbolicCosine_cmpend
    mov eax, [prevchres]
    cmp eax, [chres]
    je hyperbolicCosine_end
    hyperbolicCosine_cmpend:
    call debugLog
    fstp qword[prevchres]

    ; обновляем tmpPow
    fld qword[tmpPow]
    fmul qword[tmpSquare]
    fstp qword[tmpPow]

    ; обновляем tmpFactorial
    fld qword[tmpFactorial]
    mov [i], ecx
    fimul dword[i]
    inc ecx
    mov [i], ecx
    fimul dword[i]
    inc ecx
    fstp qword[tmpFactorial]

    cmp ecx, 10000
    jl hyperbolicCosine_loop
    hyperbolicCosine_end:

    ret

    hyperbolicCosine_fixInf:
    call debugLog
    fld qword[prevchres]
    fstp qword[chres]
    ret

  start:
    call dramaticEntrance

    cmp dword[argc], 1
    jne start_sscanf

    ; тут мы для scanf-а написали что он создаёт float64
    push askForX
    call [printf]
    add esp, 4
    push x
    push floatFormat_scanf
    call [scanf]
    add esp, 8
    cmp eax, 1
    jne start_wrongInput

    jmp start_scanfEnd
    start_sscanf:
    push x
    push floatFormat_scanf
    mov eax, [argv]
    mov eax, [eax+4]
    push eax
    call [sscanf]
    add esp, 12
    cmp eax, 1
    jne start_wrongInput

    start_scanfEnd:
    call checkHyperbolicCosineBounds
    call hyperbolicCosine

    ; printf уммеет работать только с float64
    ; а push неумеет
    push dword[chres+4]
    push dword[chres]
    push dword[x+4]
    push dword[x]
    push floatFormat_printf
    call [printf]
    add esp, 20

    start_exit:
    call gracefulExit
    ret

    start_wrongInput:
    push wrongFromat
    call [printf]
    add esp, 4
    jmp start_exit

section '.data' data readable writable
  ; тут всякие служебные переменные и строки
  consoleWindowProcessId: dd 0
  argv: dd 0
  argc: dd 0
  env: dd 0
  exitStr: db 'ты открыли эту программу не из терминала((',10, \
    'поэтому для выхода из неё тебе надо нажать Enter',10,0

  ; тут полезные переменные
  floatFormat_scanf: db '%lf',0
  floatFormat_printf: db 'ch(%g) = %.16g',10,0
  debugFormat_printf: db '│ %3i: %23.20g -> %23.20g',10,0
  askForX: db 'От какого числа нам надо искать чосинус? ',0
  wrongFromat: db 'Надо ввести какоето действительное число (через точку)',10,0
  floatWrongFormat_printf: db 'Число %g слишком большое и посчитать чосинус от него очень сложно',10,0

  align 4
  i: dd 0
  two: dd 2 ; это буквально 2 потомучто FPU неможет читать литералы
  hundred: dd 100 ; это буквально 100 потомучто FPU неможет читать литералы

  ; это всё float64
  align 8
  x: dq 0
  tmpFactorial: dq 0
  tmpPow: dq 0
  tmpSquare: dq 0
  chres: dq 0
  prevchres: dq 0


section '.idata' import code readable
  library msvcrt, 'msvcrt.dll', kernel32, 'kernel32.dll', user32, 'user32.dll'

  import msvcrt, \
    printf, 'printf', scanf, 'scanf', sscanf, 'sscanf', \
    exit, '_exit', getch, '_getch', getmainargs, '__getmainargs'

  import kernel32, \
    SetConsoleOutputCP, 'SetConsoleOutputCP', \
    GetConsoleWindow, 'GetConsoleWindow', \
    GetCurrentProcessId, 'GetCurrentProcessId'

  import user32, GetWindowThreadProcessId, 'GetWindowThreadProcessId'
