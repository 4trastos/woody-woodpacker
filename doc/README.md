# Guía en pseudocódigo para `woody_woodpacker`

## Fase 0 — Preparación

```
1. Leer el subject completo y entender los requisitos.
2. Estudiar formato ELF 64 bits (cabecera, program headers, section headers).
3. Estudiar cómo el kernel carga un ELF (PT_LOAD, entry point, permisos).
4. Elegir algoritmo de cifrado (justificable): ChaCha20, AES-128/256, RC4 (simple pero justificable), XOR con clave larga derivada de urandom.
5. Decidir estrategia de inyección:
   - Añadir nuevo segmento PT_LOAD ejecutable al final del binario.
   - O reutilizar un segmento existente (más complejo).
   - O usar técnica de "entry point hijacking" + append del payload.
```

## Fase 1 — Parseo del ELF

```
FUNCION main(argc, argv):
    SI argc != 2: error("Usage: ./woody_woodpacker <elf64>")
    SI NOT is_valid_elf64(argv[1]): error("File architecture not supported. x86_64 only")

    abrir archivo (open)
    mmap archivo en memoria (PROT_READ)
    verificar cabecera ELF:
        - e_ident[EI_MAG] == 0x7F 'E' 'L' 'F'
        - e_ident[EI_CLASS] == ELFCLASS64
        - e_ident[EI_DATA] == ELFDATA2LSB
        - e_machine == EM_X86_64
    leer program headers (e_phoff, e_phnum, e_phentsize)
    identificar:
        - entry_point = e_entry
        - segmentos PT_LOAD (para saber dónde inyectar)
        - tamaño total del binario
    cerrar archivo (close)
```

## Fase 2 — Generación de clave

```
FUNCION generate_key():
    abrir /dev/urandom
    leer N bytes (N = tamaño de clave del algoritmo elegido, ej. 32 bytes)
    cerrar
    DEVOLVER key
```

## Fase 3 — Cifrado del payload

```
FUNCION encrypt_payload(binary_data, size, key):
    // Cifrar TODO el binario original o solo las secciones ejecutables
    // Recomendación: cifrar el binario completo para simplicidad,
    // pero conservar la cabecera ELF y program headers legibles por el loader.
    
    payload_cifrado = cipher(binary_data, size, key)
    DEVOLVER payload_cifrado
```

**Nota importante:** El binario `woody` debe seguir siendo un ELF válido, por lo que la cabecera ELF y los program headers NO se cifran (o se descifran antes de que el kernel los lea — imposible). Estrategia habitual:

- Conservar cabecera ELF + program headers originales.
- Añadir un nuevo segmento `PT_LOAD` que contenga:
  - El stub de descifrado (assembly).
  - El payload cifrado (el binario original completo, o sus segmentos).
- Modificar `e_entry` para que apunte al stub.
- El stub descifra el payload en memoria y salta al entry original.

## Fase 4 — Construcción del stub (loader)

```
; Pseudocódigo assembly x86_64

stub:
    ; 1. Escribir "...WOODY...\n" en stdout
    mov rax, 1          ; sys_write
    mov rdi, 1          ; stdout
    lea rsi, [msg]      ; "...WOODY...\n"
    mov rdx, msg_len
    syscall

    ; 2. Descifrar el payload en memoria
    lea rsi, [payload_start]   ; dirección del payload cifrado
    mov rcx, payload_size
    lea rdi, [key]             ; clave
    call decrypt_loop          ; descifra in-place

    ; 3. Saltar al entry point original
    mov rax, [original_entry]
    jmp rax

decrypt_loop:
    ; Implementar el mismo algoritmo usado en el cifrado
    ; (XOR, ChaCha20, etc.) en assembly
    ret

msg: db "...WOODY...", 10
msg_len equ $ - msg
```

## Fase 5 — Inyección en el binario

```
FUNCION build_woody(elf_original, payload_cifrado, key, stub):
    nuevo_elf = copia de elf_original

    // 1. Calcular nueva dirección virtual para el segmento inyectado
    //    (alineada a página, ej. 0x1000)
    nueva_vaddr = align_up(max_vaddr_of_PT_LOAD, PAGE_SIZE)

    // 2. Crear nuevo program header PT_LOAD:
    //    p_type   = PT_LOAD
    //    p_flags  = PF_R | PF_X
    //    p_offset = tamaño del archivo original (alineado)
    //    p_vaddr  = nueva_vaddr
    //    p_paddr  = nueva_vaddr
    //    p_filesz = sizeof(stub) + sizeof(payload_cifrado)
    //    p_memsz  = igual que filesz
    //    p_align  = PAGE_SIZE

    // 3. Añadir el nuevo program header a la tabla
    //    (requiere espacio; a veces hay que reubicar la tabla o usar padding)

    // 4. Modificar e_entry -> nueva_vaddr (inicio del stub)

    // 5. Escribir el nuevo archivo:
    //    - cabecera ELF modificada
    //    - program headers (incluido el nuevo)
    //    - contenido original
    //    - padding hasta alineación
    //    - stub + payload_cifrado
    
    escribir "woody"
```

## Fase 6 — Salida y limpieza

```
    imprimir "key_value: " + hex(key) + "\n"
    munmap, close, free
    exit(0)
```

## Fase 7 — Verificación

```
1. Compilar con Makefile.
2. Probar con binarios de ejemplo (sample.c).
3. Verificar:
   - ./woody_woodpacker sample genera woody.
   - ./woody imprime "...WOODY..." y luego ejecuta sample correctamente.
   - objdump -D woody muestra el stub.
   - El binario original no se modifica.
4. Probar casos de error:
   - Sin argumentos.
   - Archivo inexistente.
   - Binario de 32 bits.
   - Archivo no ELF.
   - Archivo corrupto.
```

## Fase 8 — Bonus (opcional)

```
- Soporte 32 bits: detectar ELFCLASS32 y usar stub de 32 bits.
- Clave parametrizable: flag -k <key>.
- Optimizar decrypt en assembly puro.
- Compresión: zlib/LZ4 antes del cifrado, descompresión en el stub.
```

## Consejos clave

1. **Empieza simple**: XOR con clave larga derivada de urandom es válido si justificas que no es un ROT trivial (clave de 32+ bytes, generada aleatoriamente, aplicada byte a byte con rotación de clave).
2. **Depura con `strace` y `gdb`**: verifica que el stub se ejecuta y descifra correctamente.
3. **Cuida la alineación**: los segmentos PT_LOAD deben estar alineados a página (0x1000).
4. **No toques la cabecera ELF original**: solo añade/modifica lo necesario.
5. **El stub debe ser position-independent**: usa direcciones relativas o calcula la base en runtime.
6. **Prueba con binarios estáticos y dinámicos**: el comportamiento debe ser idéntico.
7. **Gestión de errores impecable**: es requisito para que evalúen los bonus.
