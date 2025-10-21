import numpy as np


# --- Conversión binario ↔ float ---
def bits_to_float(f, bits):

    i = int(f, 2)
    ftype = np.float16 if bits == 16 else np.float32
    dftype = np.uint16 if bits == 16 else np.uint32
    return np.frombuffer(dftype(i).tobytes(), dtype=ftype)[0]


def float_to_bits(f, bits):
    """
    Convierte un float16 a su representación binaria IEEE-754 (cadena de 16 bits).
    """
    ftype = np.float16 if bits == 16 else np.float32
    dftype = np.uint16 if bits == 16 else np.uint32
    [d] = np.frombuffer(ftype(f).tobytes(), dtype=dftype)
    return format(int(d), f'0{bits}b')


# --- Cálculo de flags y resultado ---
def calc_flags_ieee(a_bits, b_bits, op, bits=16):
    """
    Calcula el resultado y flags IEEE simplificadas para half o single precision
    Flags: invalid, div0, ovf, unf, inx
    Retorna:
        bits_result: cadena de bits IEEE-754 del resultado
        flags: cadena de 5 bits 'invalid div0 ovf unf inx'
    """
    # Convertir cadenas a float IEEE
    a = bits_to_float(a_bits, bits)
    b = bits_to_float(b_bits, bits)
    ftype = np.float16 if bits == 16 else np.float32

    invalid = div0 = ovf = unf = inx = 0
    r = ftype(0.0)

    # ---------- Casos especiales ----------
    # NaN
    if np.isnan(a) or np.isnan(b):
        r = ftype(np.inf)
        invalid = 1
    # Infinito ± infinito en suma/resta
    elif np.isinf(a) and np.isinf(b) and op in ['00', '01']:
        r = ftype(np.inf)
        invalid = 1
    # División por cero
    elif op == '11' and b == ftype(0.0):
        div0 = 1
        inx = 1
        r = ftype(np.inf) if a >= 0 else ftype(-np.inf)
    else:
        # ---------- Operación normal ----------
        try:
            if op == '00':  # suma
                r = ftype(a) + ftype(b)
            elif op == '01':  # resta
                r = ftype(a) - ftype(b)
            elif op == '10':  # multiplicación
                r = ftype(a) * ftype(b)
            elif op == '11':  # división
                r = ftype(a) / ftype(b)
        except Exception:
            r = ftype(np.inf)
            invalid = 1

    # ---------- Flags por magnitud ----------
    if np.isnan(r):
        invalid = 1
    elif np.isinf(r) or abs(r) > np.finfo(ftype).max:
        ovf = 1
        inx = 1
        r = ftype(np.inf)
    elif 0 < abs(r) < np.finfo(ftype).tiny:
        unf = 1
        inx = 1
        r = ftype(0.0)

    # Convertir resultado a bits IEEE
    bits_result = float_to_bits(r, bits)
    flags = f"{invalid}{div0}{ovf}{unf}{inx}"

    return bits_result, flags


# --- Generador de archivo de salida ---
def generar_output(input_file='tb_vectors_input.mem', output_file='tb_expected.mem', bits=16):
    with open(input_file, 'r') as fin, open(output_file, 'w') as fout:
        for line in fin:
            parts = line.strip().split()
            if len(parts) != 3:
                continue

            a_bin, b_bin, op = parts
            r, flags = calc_flags_ieee(a_bin, b_bin, op, bits=len(a_bin))

            fout.write(f"{r} {flags}\n")

    print(f"✅ Archivo {output_file} generado con resultado y flags ({bits} bits)")



if __name__ == "__main__":
    generar_output(bits=16, input_file="./data/tb_vectors_16.mem", output_file="./output/tb_expected_output16.mem")
    generar_output(bits=32, input_file="./data/tb_vectors_32.mem", output_file="./output/tb_expected_output32.mem")
