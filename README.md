# AgroSeguro

AgroSeguro es un contrato inteligente en Solidity para un **seguro paramétrico agrícola**. El sistema permite que una aseguradora emita pólizas y que un oráculo climático active pagos automáticos cuando ocurre un evento de helada (temperatura igual o menor al umbral acordado).

## Objetivo

Reducir tiempos y fricción en la indemnización agrícola:
- La aseguradora fondea un pool de cobertura.
- El agricultor contrata una póliza pagando una prima.
- El oráculo reporta el dato climático.
- Si se cumple la condición del contrato, el pago se ejecuta automáticamente en blockchain.

## Estructura del repositorio

- `/contracts/AgroSeguro.sol`: contrato principal.
- `/index.html`: archivo estático de apoyo.

## Funcionalidades principales

- **Depósito de fondo de cobertura** por la aseguradora (`depositarFondo`).
- **Contratación de pólizas** por agricultores (`contratarPoliza`).
- **Reporte de clima** restringido al oráculo autorizado (`reportarClima`).
- **Ejecución automática de pago** cuando la temperatura cumple el disparador (`_ejecutarPago`).
- **Marcado de pólizas vencidas** cuando termina su vigencia sin evento (`marcarVencida`).
- **Consulta de pólizas** (`consultarPoliza`).

## Roles

- **Aseguradora**: despliega el contrato y administra el pool.
- **Oráculo**: única cuenta autorizada para reportar la temperatura.
- **Agricultor**: contrata la póliza y recibe el pago si se activa el seguro.

## Flujo de uso

1. Desplegar `AgroSeguro` indicando la dirección del oráculo en el constructor.
2. La aseguradora deposita fondos al pool con `depositarFondo`.
3. El agricultor contrata una póliza con `contratarPoliza` enviando prima.
4. El oráculo reporta temperatura con `reportarClima` durante la vigencia.
5. Si la temperatura es menor o igual al umbral, se ejecuta el pago automáticamente.
6. Si no ocurre el evento y vence el plazo, se puede llamar `marcarVencida`.

## Modelo de datos (póliza)

Cada póliza almacena:
- `agricultor`
- `prima`
- `montoPago`
- `umbralTemperatura` (en décimas de °C, p. ej. `-20` = `-2.0 °C`)
- `fechaInicio`
- `fechaFin`
- `estado` (`Activa`, `Pagada`, `Vencida`)

## Eventos emitidos

- `PolizaCreada`
- `FondoDepositado`
- `DatoClimaReportado`
- `PagoEjecutado`
- `PolizaVencida`

## Consideraciones

- El contrato usa Solidity `^0.8.19`.
- Solo la aseguradora puede fondear el pool.
- Solo el oráculo configurado puede reportar clima.
- El contrato valida fondos disponibles antes de pagar indemnizaciones.

## Próximos pasos sugeridos

- Integrar framework de desarrollo (Hardhat o Foundry).
- Agregar pruebas unitarias para cada caso de negocio.
- Incorporar manejo de múltiples oráculos o validación de consenso de datos.
