org     100h

; data bölümünü atla
jmp     start

; ------ data bölümü ------

y_boyut  equ     7	; yýlanýn ilerlerkenki uzunluðu

snake dw y_boyut dup(0)	; yýlanýn baþlangýç boyutu kadar bellekte yer ayrýlýyor

kuyruk    dw      ?	; yýlanýn kuyruðuna ilk baþta deðer atanmýyor	

; yön sabitleri
sol    equ     4bh	; yön tuþlarýnýn ascii kodlarý sembolik sabitler olarak tanýmlanýyor
sag    equ     4dh
yukari equ     48h
asagi  equ     50h

; baþlangýçtaki yýlanýn konumu:
yon db      sag	; yon yýlanýn þu anki hareket yönünü tutar, ilk baþta yýlan saða doðru hareket etmektedir

bekleme_suresi dw    0	; yýlanýn hareketi arasýndaki bekleme süresini tutar

; mesaj, bir dizi (db) ifadesi kullanýlarak tanýmlanýr
; her satýr bir dizi byte'a karþýlýk gelir ve mesajdaki metni depolar
; 0dh ve 0ah sýrasýyla ascii tablosundaki \r ve \n karakterlerini temsil eder
; 0dh ve 0ah birlikte kullanýldýklarýnda bir satýrýn sona erdiðini ve bir sonraki satýra geçtiðini belirtir
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

; ------ kod bölümü ------

start:

; karþýlama mesajýný yazdýrma:
mov dx, offset msg
mov ah, 9	; MSDOS iþletim sisteminin yazdýrma dizesi iþlevini belirtmektedir
int 21h		; bu kesme çaðrýsý kullanýlarak mesaj kutusu görüntülenmektedir    

mov bp,3  	; hak sayýsýný tanýmlanmakta ve ekrana yazdýrmak üzere hak_yazdir fonksiyonu çaðrýlmaktadýr
call hak_yazdir


; klavyeden bir tuþ basýmýný bekleme:
mov ah, 00h	; MSDOS'un klavye okuma iþlevini belirtmektedir
int 16h		; bu kesme çaðrýsý kullanýlarak klavyeden bir tuþ basýmý beklenmektedir


; metin imlecini saklama:
mov     ah, 1	; MSDOS'un ekran karakterleri ve renkleri ayarlama iþlevini belirtmektedir
mov     ch, 2bh	; ch kaydedici, arka plan rengini belirlemektedir
mov     cl, 0bh	; cl kaydedici, ön plan rengini belirlemektedir
int     10h 	; bu kesme çaðrýsý ile arka ve ön plan rengi ayarlanmaktadýr          


game_loop:

; === select first video page
mov     al, 0  ; page number.
mov     ah, 05h
int     10h	; oyunun çalýþtýðý terminale video sayfasýnýn atanmasýný saðlamaktadýr

; yýlanýn yeni baþýný göster:
mov     dx, snake[0]	; dx kaydedici yýlanýn baþýnýn bellekteki konumunu temsil etmektedir

; metin imlecini yatay,dikey olacak þekilde dl,dh a ayarlama
mov     ah, 02h		; imleç pozisyonunu ayarla iþlevini belirtmektedir
			; dl kaydedici, imlecin yatay konumunu; dh kaydedici imlecin dikey konumunu belirler
int     10h		; bu kesme çaðrýsý kullanýlarak, belirtilen koordinatlara imlecin taþýnmasý saðlanmaktadýr

; yýlanýn gövdesini * karakteri ile oluþturma:
mov     al, '*'	; al kaydedici yazdýrýlacak karakter olan * ile yüklenmektedir
mov     ah, 09h ; tek karakter yazdýrma iþlevini belirtmektedir
mov     bl, 0dh ; attribute.
mov     cx, 1   ; cx kaydedici, yazdýrýlacak karakter sayýsýný(yani 1 adet olacaðýný) belirlemektedir
int     10h	; yýlanýn baþýnýn ekranda gösterilmesini saðlamaktadýr

; bu kod bloðu, yýlanýn kuyruðunu hareket ettirmektedir
mov     ax, snake[y_boyut * 2 - 2]  ; ax kaydedici, yýlanýn son elemanýnýn bellekteki adresine karþýlýk gelen deðer ile yüklenmektedir
; yýlanýn her elemaný 2 byte yer kapladýðýndan, bellekteki toplam byte sayýsý: s_size * 2 
mov     kuyruk, ax	
; kuyruk deðiþkenine, ax atanýr. Bu iþlem, yýlanýn kuyruðunu hareket ettirirken son elemaný listeden çýkarýp yerine yeni eleman eklemeyi mümkün kýlmaktadýr

call    move_snake	; yýlanýn tüm elemanlarýný bir öne doðru hareket ettirilmesi için move_snake adlý alt program çaðrýlmaktadýr


; kuyruk deðiþkenindeki yýlanýn son elemanýnýn bellekteki adresi, dx kaydedicisinde saklanýlmaktadýr
mov     dx, kuyruk	

; metin imlecini dl,dh'da ayarlama
mov     ah, 02h		; imlecin pozisyonunu ayarlamak için kesme çaðrýsý kullanýlmaktadýr 
int     10h

; yýlan ilerledikçe arkasýný boþ karaktere dönüþtürme
mov     al, ' '	; yýlan ilerledikçe arkasýnýn boþ bir karaktere dönüþmesini saðlamaktadýr
mov     ah, 09h
mov     bl, 0eh ; attribute.
mov     cx, 1   ; single char.
int     10h



klavye_kontrol:
mov     ah, 01h
int     16h	; 16 interruptý klavyeden tuþa basýlýp basýlmadýðýný kontrol etmektedir
jz      no_key	; jz bayraðý sýfýr ise yani bir tuþa basýlmadýysa no_key etiketine atlanmaktadýr

mov     ah, 00h	; eðer bir tuþa basýldýysa ah 00 olarak ayarlaný 16h interruptý çaðrýlmaktadýr
int     16h

cmp     al, 1bh    ; esc(1bh) 
je      stop_game  ; esc tuþu ise stop_game etiketine atlanmaktadýr

mov     yon, ah; esc tuþu deðilse yon deðiþkeni klavyeden alýnan ah ile güncellenip yýlanýn hareket yönü bu yöne göre ayarlanmaktadýr


no_key:    ; yeni bir tuþa basýlmadýðý sürece devam etme, bekleme etiketi
; get number of clock ticks (about 18 per second) since midnight into cx:dx
mov     ah, 00h
int     1ah	; günün saatine göre bilgisayarýn saatini okumaktadýr
cmp     dx, bekleme_suresi ; dx, saniyeyi tutar
; beklenen süre, oyun döngüsünde klavyeden girdi almadan önce geçirilen süredir
; dx deðeri, bekleme_suresi deðerinden küçük olduðu sürece (beklenen süre dolmadýðý sürece) klavyeden tuþ giriþi beklenerek geçirilmektedir
jb      klavye_kontrol
add     dx, 4	
mov     bekleme_suresi, dx  

jmp     game_loop ; yýlanýn görüntüleneceði etikete atlar

  
; hak sayýsýný yazdýrma	 
hak_yazdir:   
    ; hak sayýsýnýn ekranda yazdýrýlacaðý konum belirlenmektedir
    mov ah, 02h     ; konsol imleci konumunu ayarlamak için DOS hizmet çaðrýsý
    mov bh, 0       ; sayfanýn numarasý
    mov dh, 01     ; satýr numarasý
    mov dl, 40      ; sütun numarasý
    int 10h         ; hizmet çaðrýsýný çaðýr

    ; bp registerý içindeki hak sayýsý ekrana yazdýrýlmaktadýr
    mov ax, bp      ; bp registerýndaki sayýyý ax kaydýna kopyala
    mov bx, 10      ; sayýyý onluk sistemde dönüþtürmek için kullanýlacak sabit
    mov cx, 0       ; karakter sayacý
    mov dx, 1000    ; bölünecek en büyük sayý
    
    ; sayýyý onluk sistemde karakter dizisine dönüþtür
    convert_digit:
        xor dx, dx          ; dx kaydýný sýfýrla
        div bx              ; ax kaydýndaki sayýyý bx ile böl
        add dl, '0'         ; kalaný ASCII karakterine dönüþtür
        push dx             ; karakteri yýðýnýn üstüne ekle
        inc cx              ; karakter sayacýný artýr
        cmp ax, 0           ; ax kaydýndaki sayý 0 mý?
        jne convert_digit   ; deðilse tekrar dönüþtür
    
    ; karakter dizisini konsola yazdýr
    print_string:
        pop dx              ; yýðýnýn üstündeki karakteri al
        mov ah, 02h         ; karakteri yazdýrmak için DOS hizmet çaðrýsý
        int 21h             ; konsola yazdýr
        loop print_string   ; tüm karakterleri yazdýr  
    ret

; ------ fonksiyonlar bölümü ------

; yýlanýn ilerleme mantýðý: 
; [kuyruðun son kýsmý]-> silinir
; [i. kýsým] -> [i+1. kýsým]

stop_game:
; esc tuþuna basýlmasý durumunda çalýþmaktadýr
; show cursor back:
mov     ah, 1
mov     ch, 0bh
mov     cl, 0bh
int     10h	; bu kod, alt programda imleci geri göstermek için kullanýlmaktadýr

hlt	
         
         
move_snake proc near    
                              
mov     ax, 40h
mov     es, ax	; BIOS bilgi segmentinin yerini es registerýnda saklanýlmasýný saðlamaktadýr

  mov   di, y_boyut * 2 - 2	; di registerý kuyruðun son elemanýnýn adresini göstermektedir
  ; move all body parts
  ; (last one simply goes away)
  mov   cx, y_boyut-1
move_array:
  mov   ax, snake[di-2]
  mov   snake[di], ax
  sub   di, 2
  loop  move_array


cmp     yon, sol	; klavyeden sol yön tuþuna basýldýysa
  je    sola_git
cmp     yon, sag	; klavyeden sað yön tuþuna basýldýysa
  je    saga_git
cmp     yon, yukari	; klavyeden yukarý yön tuþuna basýldýysa
  je    yukari_git
cmp     yon, asagi	; klavyeden aþaðý yön tuþuna basýldýysa
  je    asagi_git

jmp     stop_move       ; yön belirlenmediyse hareketsiz kalmaktadýr

stop_game1:
; esc tuþuna basýlmasý durumunda çalýþmaktadýr
; show cursor back:
mov     ah, 1
mov     ch, 0bh
mov     cl, 0bh
int     10h	; bu kod, alt programda imleci geri göstermek için kullanýlmaktadýr 

hlt	; alt program ret komutu ile bitirilmektedir


sola_git:
  mov   al, b.snake[0]
  dec   al
  mov   b.snake[0], al
  cmp   al, -1
  jne   stop_move   	; al, -1 deðilse stop_move etiketine atlanmaktadýr   
  dec bp     
  call hak_yazdir
  cmp bp,0	; bp yani hak sayýsý 0 a eþitse
  je  stop_game1
  ; eðer b.snake[0] -1'e eþitse oyun alanýnýn sol sýnýrýný aþtýðý anlamýna gelmektedir
  ; bu durumda yýlanýn yeni konumu saða taþýnarak oyun alanýna geri döndürülmektedir
  mov   al, es:[4ah]    ; sütun numarasý
  dec   al		; es:[4ah] adresindeki deðer yani ekranýn geniþliði 1 azaltýlmaktadýr
  mov   b.snake[0], al  
  jmp   stop_move   

saga_git:
  mov   al, b.snake[0]
  inc   al
  mov   b.snake[0], al
  cmp   al, es:[4ah]    ; sütun numarasý 
  ; eðer sütun numarasý daha büyükse oyun alanýnýn sað sýnýrýna çarpýlmýþtýr  
  jb    stop_move	
  mov   b.snake[0], 0   ; sola dön
  ;
  dec bp    
  call hak_yazdir
  cmp bp,0	; bp yani hak sayýsý 0 a eþitse
  je  stop_game1
  ;
  ; oyun alanýnýn sað sýnýrýna çarpýlmýþsa yýlanýn baþý oyun alanýnýn sol sýnýrýna döndürülür
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
  cmp bp,0	; bp yani hak sayýsý 0 a eþitse
  je  stop_game1		
  ;
  mov   al, es:[84h]    ; satýr numarasý -1
  mov   b.snake[1], al  ; aþaðýya dön    
  jmp   stop_move  

asagi_git:
  mov   al, b.snake[1]
  inc   al
  mov   b.snake[1], al
  cmp   al, es:[84h]    ; satýr numarasý -1
  jbe   stop_move	; Eðer birinci operand ikinci operanddan küçük veya eþitse 
  ;
  dec bp 
  call hak_yazdir  
  cmp bp,0	; bp yani hak sayýsý 0 a eþitse
  je  stop_game1	
  ;
  mov   b.snake[1], 0   ; yukarýya dön 
  jmp   stop_move  

stop_move:  
  ret
move_snake endp