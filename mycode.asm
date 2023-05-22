org     100h

; data b�l�m�n� atla
jmp     start

; ------ data b�l�m� ------

y_boyut  equ     7	; y�lan�n ilerlerkenki uzunlu�u

snake dw y_boyut dup(0)	; y�lan�n ba�lang�� boyutu kadar bellekte yer ayr�l�yor

kuyruk    dw      ?	; y�lan�n kuyru�una ilk ba�ta de�er atanm�yor	

; y�n sabitleri
sol    equ     4bh	; y�n tu�lar�n�n ascii kodlar� sembolik sabitler olarak tan�mlan�yor
sag    equ     4dh
yukari equ     48h
asagi  equ     50h

; ba�lang��taki y�lan�n konumu:
yon db      sag	; yon y�lan�n �u anki hareket y�n�n� tutar, ilk ba�ta y�lan sa�a do�ru hareket etmektedir

bekleme_suresi dw    0	; y�lan�n hareketi aras�ndaki bekleme s�resini tutar

; mesaj, bir dizi (db) ifadesi kullan�larak tan�mlan�r
; her sat�r bir dizi byte'a kar��l�k gelir ve mesajdaki metni depolar
; 0dh ve 0ah s�ras�yla ascii tablosundaki \r ve \n karakterlerini temsil eder
; 0dh ve 0ah birlikte kullan�ld�klar�nda bir sat�r�n sona erdi�ini ve bir sonraki sat�ra ge�ti�ini belirtir
msg 	db "__   _____ _        _    _   _ ", 0dh,0ah
	db "\ \ / /_ _| |      / \  | \ | |", 0dh,0ah
	db " \ V / | || |     / _ \ |  \| |", 0dh,0ah
	db "  | |  | || |___ / ___ \| |\  |", 0dh,0ah
	db "  |_| |___|_____/_/   \_\_| \_|", 0dh,0ah
	db "                               ", 0dh,0ah
	db "  _____   ___   _ _   _ _   _ ", 0dh,0ah	
	db " / _ \ \ / / | | | \ | | | | |", 0dh,0ah
	db "| | | \ V /| | | |  \| | | | |", 0dh,0ah
	db "| |_| || | | |_| | |\  | |_| |", 0dh,0ah
	db " \___/ |_|  \___/|_| \_|\___/ $"

; ------ kod b�l�m� ------

start:

; kar��lama mesaj�n� yazd�rma:
mov dx, offset msg
mov ah, 9	; MSDOS i�letim sisteminin yazd�rma dizesi i�levini belirtmektedir
int 21h		; bu kesme �a�r�s� kullan�larak mesaj kutusu g�r�nt�lenmektedir    

mov bp,3  	; hak say�s�n� tan�mlanmakta ve ekrana yazd�rmak �zere hak_yazdir fonksiyonu �a�r�lmaktad�r
call hak_yazdir


; klavyeden bir tu� bas�m�n� bekleme:
mov ah, 00h	; MSDOS'un klavye okuma i�levini belirtmektedir
int 16h		; bu kesme �a�r�s� kullan�larak klavyeden bir tu� bas�m� beklenmektedir


; metin imlecini saklama:
mov     ah, 1	; MSDOS'un ekran karakterleri ve renkleri ayarlama i�levini belirtmektedir
mov     ch, 2bh	; ch kaydedici, arka plan rengini belirlemektedir
mov     cl, 0bh	; cl kaydedici, �n plan rengini belirlemektedir
int     10h 	; bu kesme �a�r�s� ile arka ve �n plan rengi ayarlanmaktad�r          


game_loop:

; === select first video page
mov     al, 0  ; page number.
mov     ah, 05h
int     10h	; oyunun �al��t��� terminale video sayfas�n�n atanmas�n� sa�lamaktad�r

; y�lan�n yeni ba��n� g�ster:
mov     dx, snake[0]	; dx kaydedici y�lan�n ba��n�n bellekteki konumunu temsil etmektedir

; metin imlecini yatay,dikey olacak �ekilde dl,dh a ayarlama
mov     ah, 02h		; imle� pozisyonunu ayarla i�levini belirtmektedir
			; dl kaydedici, imlecin yatay konumunu; dh kaydedici imlecin dikey konumunu belirler
int     10h		; bu kesme �a�r�s� kullan�larak, belirtilen koordinatlara imlecin ta��nmas� sa�lanmaktad�r

; y�lan�n g�vdesini * karakteri ile olu�turma:
mov     al, '*'	; al kaydedici yazd�r�lacak karakter olan * ile y�klenmektedir
mov     ah, 09h ; tek karakter yazd�rma i�levini belirtmektedir
mov     bl, 0dh ; attribute.
mov     cx, 1   ; cx kaydedici, yazd�r�lacak karakter say�s�n�(yani 1 adet olaca��n�) belirlemektedir
int     10h	; y�lan�n ba��n�n ekranda g�sterilmesini sa�lamaktad�r

; bu kod blo�u, y�lan�n kuyru�unu hareket ettirmektedir
mov     ax, snake[y_boyut * 2 - 2]  ; ax kaydedici, y�lan�n son eleman�n�n bellekteki adresine kar��l�k gelen de�er ile y�klenmektedir
; y�lan�n her eleman� 2 byte yer kaplad���ndan, bellekteki toplam byte say�s�: s_size * 2 
mov     kuyruk, ax	
; kuyruk de�i�kenine, ax atan�r. Bu i�lem, y�lan�n kuyru�unu hareket ettirirken son eleman� listeden ��kar�p yerine yeni eleman eklemeyi m�mk�n k�lmaktad�r

call    move_snake	; y�lan�n t�m elemanlar�n� bir �ne do�ru hareket ettirilmesi i�in move_snake adl� alt program �a�r�lmaktad�r


; kuyruk de�i�kenindeki y�lan�n son eleman�n�n bellekteki adresi, dx kaydedicisinde saklan�lmaktad�r
mov     dx, kuyruk	

; metin imlecini dl,dh'da ayarlama
mov     ah, 02h		; imlecin pozisyonunu ayarlamak i�in kesme �a�r�s� kullan�lmaktad�r 
int     10h

; y�lan ilerledik�e arkas�n� bo� karaktere d�n��t�rme
mov     al, ' '	; y�lan ilerledik�e arkas�n�n bo� bir karaktere d�n��mesini sa�lamaktad�r
mov     ah, 09h
mov     bl, 0eh ; attribute.
mov     cx, 1   ; single char.
int     10h



klavye_kontrol:
mov     ah, 01h
int     16h	; 16 interrupt� klavyeden tu�a bas�l�p bas�lmad���n� kontrol etmektedir
jz      no_key	; jz bayra�� s�f�r ise yani bir tu�a bas�lmad�ysa no_key etiketine atlanmaktad�r

mov     ah, 00h	; e�er bir tu�a bas�ld�ysa ah 00 olarak ayarlan� 16h interrupt� �a�r�lmaktad�r
int     16h

cmp     al, 1bh    ; esc(1bh) 
je      stop_game  ; esc tu�u ise stop_game etiketine atlanmaktad�r

mov     yon, ah; esc tu�u de�ilse yon de�i�keni klavyeden al�nan ah ile g�ncellenip y�lan�n hareket y�n� bu y�ne g�re ayarlanmaktad�r


no_key:    ; yeni bir tu�a bas�lmad��� s�rece devam etme, bekleme etiketi
; get number of clock ticks (about 18 per second) since midnight into cx:dx
mov     ah, 00h
int     1ah	; g�n�n saatine g�re bilgisayar�n saatini okumaktad�r
cmp     dx, bekleme_suresi ; dx, saniyeyi tutar
; beklenen s�re, oyun d�ng�s�nde klavyeden girdi almadan �nce ge�irilen s�redir
; dx de�eri, bekleme_suresi de�erinden k���k oldu�u s�rece (beklenen s�re dolmad��� s�rece) klavyeden tu� giri�i beklenerek ge�irilmektedir
jb      klavye_kontrol
add     dx, 4	
mov     bekleme_suresi, dx  

jmp     game_loop ; y�lan�n g�r�nt�lenece�i etikete atlar

  
; hak say�s�n� yazd�rma	 
hak_yazdir:   
    ; hak say�s�n�n ekranda yazd�r�laca�� konum belirlenmektedir
    mov ah, 02h     ; konsol imleci konumunu ayarlamak i�in DOS hizmet �a�r�s�
    mov bh, 0       ; sayfan�n numaras�
    mov dh, 01     ; sat�r numaras�
    mov dl, 40      ; s�tun numaras�
    int 10h         ; hizmet �a�r�s�n� �a��r

    ; bp register� i�indeki hak say�s� ekrana yazd�r�lmaktad�r
    mov ax, bp      ; bp register�ndaki say�y� ax kayd�na kopyala
    mov bx, 10      ; say�y� onluk sistemde d�n��t�rmek i�in kullan�lacak sabit
    mov cx, 0       ; karakter sayac�
    mov dx, 1000    ; b�l�necek en b�y�k say�
    
    ; say�y� onluk sistemde karakter dizisine d�n��t�r
    convert_digit:
        xor dx, dx          ; dx kayd�n� s�f�rla
        div bx              ; ax kayd�ndaki say�y� bx ile b�l
        add dl, '0'         ; kalan� ASCII karakterine d�n��t�r
        push dx             ; karakteri y���n�n �st�ne ekle
        inc cx              ; karakter sayac�n� art�r
        cmp ax, 0           ; ax kayd�ndaki say� 0 m�?
        jne convert_digit   ; de�ilse tekrar d�n��t�r
    
    ; karakter dizisini konsola yazd�r
    print_string:
        pop dx              ; y���n�n �st�ndeki karakteri al
        mov ah, 02h         ; karakteri yazd�rmak i�in DOS hizmet �a�r�s�
        int 21h             ; konsola yazd�r
        loop print_string   ; t�m karakterleri yazd�r  
    ret

; ------ fonksiyonlar b�l�m� ------

; y�lan�n ilerleme mant���: 
; [kuyru�un son k�sm�]-> silinir
; [i. k�s�m] -> [i+1. k�s�m]

stop_game:
; esc tu�una bas�lmas� durumunda �al��maktad�r
; show cursor back:
mov     ah, 1
mov     ch, 0bh
mov     cl, 0bh
int     10h	; bu kod, alt programda imleci geri g�stermek i�in kullan�lmaktad�r

hlt	
         
         
move_snake proc near    
                              
mov     ax, 40h
mov     es, ax	; BIOS bilgi segmentinin yerini es register�nda saklan�lmas�n� sa�lamaktad�r

  mov   di, y_boyut * 2 - 2	; di register� kuyru�un son eleman�n�n adresini g�stermektedir
  ; move all body parts
  ; (last one simply goes away)
  mov   cx, y_boyut-1
move_array:
  mov   ax, snake[di-2]
  mov   snake[di], ax
  sub   di, 2
  loop  move_array


cmp     yon, sol	; klavyeden sol y�n tu�una bas�ld�ysa
  je    sola_git
cmp     yon, sag	; klavyeden sa� y�n tu�una bas�ld�ysa
  je    saga_git
cmp     yon, yukari	; klavyeden yukar� y�n tu�una bas�ld�ysa
  je    yukari_git
cmp     yon, asagi	; klavyeden a�a�� y�n tu�una bas�ld�ysa
  je    asagi_git

jmp     stop_move       ; y�n belirlenmediyse hareketsiz kalmaktad�r

stop_game1:
; esc tu�una bas�lmas� durumunda �al��maktad�r
; show cursor back:
mov     ah, 1
mov     ch, 0bh
mov     cl, 0bh
int     10h	; bu kod, alt programda imleci geri g�stermek i�in kullan�lmaktad�r 

hlt	; alt program ret komutu ile bitirilmektedir


sola_git:
  mov   al, b.snake[0]
  dec   al
  mov   b.snake[0], al
  cmp   al, -1
  jne   stop_move   	; al, -1 de�ilse stop_move etiketine atlanmaktad�r   
  dec bp     
  call hak_yazdir
  cmp bp,0	; bp yani hak say�s� 0 a e�itse
  je  stop_game1
  ; e�er b.snake[0] -1'e e�itse oyun alan�n�n sol s�n�r�n� a�t��� anlam�na gelmektedir
  ; bu durumda y�lan�n yeni konumu sa�a ta��narak oyun alan�na geri d�nd�r�lmektedir
  mov   al, es:[4ah]    ; s�tun numaras�
  dec   al		; es:[4ah] adresindeki de�er yani ekran�n geni�li�i 1 azalt�lmaktad�r
  mov   b.snake[0], al  
  jmp   stop_move   

saga_git:
  mov   al, b.snake[0]
  inc   al
  mov   b.snake[0], al
  cmp   al, es:[4ah]    ; s�tun numaras� 
  ; e�er s�tun numaras� daha b�y�kse oyun alan�n�n sa� s�n�r�na �arp�lm��t�r  
  jb    stop_move	
  mov   b.snake[0], 0   ; sola d�n
  ;
  dec bp    
  call hak_yazdir
  cmp bp,0	; bp yani hak say�s� 0 a e�itse
  je  stop_game1
  ;
  ; oyun alan�n�n sa� s�n�r�na �arp�lm��sa y�lan�n ba�� oyun alan�n�n sol s�n�r�na d�nd�r�l�r
  jmp   stop_move 
  
yukari_git:
  mov   al, b.snake[1]
  dec   al
  mov   b.snake[1], al
  cmp   al, -1
  jne   stop_move
  ;
  dec bp    
  call hak_yazdir
  cmp bp,0	; bp yani hak say�s� 0 a e�itse
  je  stop_game1		
  ;
  mov   al, es:[84h]    ; sat�r numaras� -1
  mov   b.snake[1], al  ; a�a��ya d�n    
  jmp   stop_move  

asagi_git:
  mov   al, b.snake[1]
  inc   al
  mov   b.snake[1], al
  cmp   al, es:[84h]    ; sat�r numaras� -1
  jbe   stop_move	; E�er birinci operand ikinci operanddan k���k veya e�itse 
  ;
  dec bp 
  call hak_yazdir  
  cmp bp,0	; bp yani hak say�s� 0 a e�itse
  je  stop_game1	
  ;
  mov   b.snake[1], 0   ; yukar�ya d�n 
  jmp   stop_move  

stop_move:  
  ret
move_snake endp