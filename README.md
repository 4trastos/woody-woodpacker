# woody_woodpacker (42 School Project)

## Descripción

`woody_woodpacker` es un proyecto de 42 School que consiste en implementar un **packer** sencillo para binarios ELF de 64 bits. El programa toma un ejecutable ELF como parámetro, lo cifra y genera un nuevo binario llamado `woody`. Cuando `woody` se ejecuta, debe descifrarse a sí mismo en memoria y ejecutar el programa original de forma totalmente idéntica.

## Objetivos

- Cifrar un binario ELF de 64 bits.
- Generar un nuevo ejecutable (`woody`) que contenga el binario cifrado.
- Al ejecutar `woody`, este debe:
  1. Descifrar el payload en memoria.
  2. Mostrar el string `"...WOODY..."` seguido de un salto de línea.
  3. Ejecutar el programa original sin alterar su comportamiento.
- El algoritmo de cifrado debe ser lo suficientemente complejo (no se acepta un simple ROT).
- La clave debe generarse de forma lo más aleatoria posible y mostrarse por stdout al ejecutar `woody_woodpacker`.

## Requisitos

- Solo se admiten binarios **ELF de 64 bits** (x86_64).
- El proyecto debe estar escrito en **C** y acompañado de un `Makefile` con las reglas habituales.
- Funciones permitidas en la parte obligatoria:
  - `open`, `close`, `exit`
  - `fputs`, `fflush`, `lseek`
  - `mmap`, `munmap`, `mprotect`
  - `perror`, `strerror`
  - `syscall`
  - Funciones de la familia `printf`
  - Funciones de tu `libft` (ej. `read`, `write`, `malloc`, `free`)
- En la parte bonus se permiten otras funciones siempre que se justifiquen.

## Uso

```bash
./woody_woodpacker <archivo_elf_64bits>
```

Ejemplo:

```bash
$ clang -m64 -o sample sample.c
$ ./woody_woodpacker sample
key_value: 07A51FF040D45D5CD
$ ls
sample  sample.c  woody  woody_woodpacker
$ ./sample
Hello, World!
$ ./woody
...WOODY...
Hello, World!
```

## Estructura del proyecto

```
.
├── Makefile
├── includes/
│   └── woody.h
├── src/
│   ├── main.c
│   ├── elf_parser.c
│   ├── cipher.c
│   ├── injector.c
│   ├── stubs/          # Código assembly para el loader
│   └── utils.c
└── README.md
```

## Consideraciones técnicas

- **Parser ELF**: leer cabecera ELF, secciones y segmentos (`PT_LOAD`).
- **Cifrado**: algoritmo elegido y justificado (ej. AES-like, ChaCha20, XOR con clave larga, etc.).
- **Inyección**: añadir un nuevo segmento `PT_LOAD` ejecutable que contenga el stub de descifrado y el payload cifrado.
- **Stub de descifrado**: código (idealmente en assembly) que:
  1. Descifra el payload en memoria.
  2. Escribe `"...WOODY..."` en stdout.
  3. Salta al punto de entrada original.
- **Key generation**: usar fuentes de entropía (`/dev/urandom`, `getrandom`, etc.) y mostrar la clave por stdout.

## Bonus (opcionales)

- Soporte para binarios de 32 bits.
- Clave parametrizable por el usuario.
- Optimización del algoritmo en assembly.
- Soporte para otros formatos (PE, Mach-O).
- Compresión del binario.

## Recursos

- Subject oficial: `en.subject.pdf`
- Documentación ELF: [ELF-64 Object File Format](https://uclibc.org/docs/elf-64-gen.pdf)
- Referencia: [Linux x86_64 syscall table](https://filippo.io/linux-syscall-table/)

## Autor

- **davgalle** — estudiante de 42

## Licencia

Este proyecto es parte del currículo de 42 School. Uso educativo.

---