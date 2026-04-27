import os

file_path = r'c:\Users\luism\Desktop\lwader_soft\prueba_contable\frontend\lib\modules\projects\project_details_screen.dart'

with open(file_path, 'r', encoding='utf-8') as f:
    lines = f.readlines()

# Queremos mantener líneas 1-803 (índices 0-802)
# Queremos mantener desde línea 951 en adelante (índices 950 en adelante)
new_lines = lines[0:803] + lines[950:]

with open(file_path, 'w', encoding='utf-8') as f:
    f.writelines(new_lines)

print(f"Limpieza completada. De {len(lines)} líneas a {len(new_lines)} líneas.")
