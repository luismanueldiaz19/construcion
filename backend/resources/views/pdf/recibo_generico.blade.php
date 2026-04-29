<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <title>Recibo de Desembolso</title>
    <style>
        body {
            font-family: 'Courier', monospace;
            font-size: 10px;
            width: 100%;
            margin: 0;
            padding: 5px;
        }
        .header {
            text-align: center;
            margin-bottom: 15px;
        }
        .header h2 {
            margin: 5px 0;
        }
        .divider {
            border-bottom: 1px dashed #000;
            margin: 10px 0;
        }
        .bold {
            font-weight: bold;
        }
        table {
            width: 100%;
            border-collapse: collapse;
        }
        td {
            padding: 2px 0;
        }
        .text-right {
            text-align: right;
        }
        .footer {
            text-align: center;
            margin-top: 20px;
            font-size: 10px;
        }
    </style>
</head>
<body>
    <div class="header">
        <h2>NEO PROJECT S.R.L</h2>
        <p class="bold">{{ $data['subtitulo'] }}</p>
        <p>Recibo No: #{{ $data['id'] }}</p>
        <p>Fecha: {{ \Carbon\Carbon::parse($data['fecha'])->format('d/m/Y') }}</p>
    </div>

    <div class="divider"></div>

    <table>
        <tr>
            <td class="bold" style="width: 40%">Entidad/Proyecto:</td>
            <td>{{ $data['entidad'] }}</td>
        </tr>
        <tr>
            <td class="bold" style="width: 40%">Método:</td>
            <td>{{ $data['metodo'] }}</td>
        </tr>
        @if($data['referencia'])
        <tr>
            <td class="bold" style="width: 40%">Referencia:</td>
            <td>{{ $data['referencia'] }}</td>
        </tr>
        @endif
    </table>

    <div class="divider"></div>

    <table>
        <tr>
            <td class="bold" style="width: 40%">MONTO PAGADO:</td>
            <td class="text-right bold">${{ number_format($data['monto'], 2) }}</td>
        </tr>
        @foreach($data['detalles'] as $label => $value)
        <tr>
            <td style="width: 40%">{{ $label }}:</td>
            <td class="text-right">
                @if(is_numeric($value))
                    ${{ number_format($value, 2) }}
                @else
                    {{ $value }}
                @endif
            </td>
        </tr>
        @endforeach
    </table>

    <div class="divider"></div>

    <div class="footer">
        <p>*** Comprobante de Operación ***</p>
        <p>Generado el {{ date('d/m/Y H:i:s') }}</p>
    </div>
</body>
</html>
