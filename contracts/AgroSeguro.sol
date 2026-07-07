// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/// @title AgroSeguro - Seguro parametrico agricola basado en blockchain
/// @notice Paga automaticamente al agricultor si el oraculo climatico reporta
///         una temperatura igual o menor al umbral pactado (evento de helada)
///         dentro del periodo de vigencia de la poliza.
contract AgroSeguro {

    // ---------------------------------------------------------------
    // PARTICIPANTES
    // ---------------------------------------------------------------
    address public aseguradora; // administra el pool de reaseguro
    address public oraculo;     // unica direccion autorizada para reportar clima

    // ---------------------------------------------------------------
    // ESTADO (datos actuales del sistema)
    // ---------------------------------------------------------------
    uint256 public poolFondos;       // fondo disponible para pagos
    uint256 public contadorPolizas;  // numero total de polizas emitidas

    enum EstadoPoliza { Activa, Pagada, Vencida }

    // TERMINOS Y CONDICIONES de cada poliza (logica del acuerdo)
    struct Poliza {
        address agricultor;
        uint256 prima;              // lo que pago el agricultor
        uint256 montoPago;          // indemnizacion si se activa el seguro
        int256  umbralTemperatura;  // en decimas de grado Celsius (ej: -20 = -2.0 C)
        uint256 fechaInicio;
        uint256 fechaFin;
        EstadoPoliza estado;
    }

    mapping(uint256 => Poliza) public polizas;

    // ---------------------------------------------------------------
    // EVENTOS (trazabilidad publica de las operaciones)
    // ---------------------------------------------------------------
    event PolizaCreada(uint256 indexed idPoliza, address indexed agricultor, uint256 prima, uint256 montoPago);
    event FondoDepositado(address indexed origen, uint256 monto);
    event DatoClimaReportado(uint256 indexed idPoliza, int256 temperatura);
    event PagoEjecutado(uint256 indexed idPoliza, address indexed agricultor, uint256 monto);
    event PolizaVencida(uint256 indexed idPoliza);

    // ---------------------------------------------------------------
    // MODIFICADORES DE ACCESO
    // ---------------------------------------------------------------
    modifier soloAseguradora() {
        require(msg.sender == aseguradora, "Solo la aseguradora puede ejecutar esta accion");
        _;
    }

    modifier soloOraculo() {
        require(msg.sender == oraculo, "Solo el oraculo autorizado puede reportar datos");
        _;
    }

    constructor(address _oraculo) {
        aseguradora = msg.sender;
        oraculo = _oraculo;
    }

    // ---------------------------------------------------------------
    // FUNCIONES (operaciones)
    // ---------------------------------------------------------------

    /// @notice La aseguradora deposita fondos al pool de reaseguro
    function depositarFondo() external payable soloAseguradora {
        poolFondos += msg.value;
        emit FondoDepositado(msg.sender, msg.value);
    }

    /// @notice El agricultor contrata una poliza pagando la prima.
    /// La transaccion queda firmada digitalmente por su wallet (msg.sender),
    /// lo que reemplaza la firma manual de un contrato tradicional.
    function contratarPoliza(
        uint256 _montoPago,
        int256 _umbralTemperatura,
        uint256 _duracionDias
    ) external payable returns (uint256) {
        require(msg.value > 0, "Debe pagar una prima mayor a 0");
        require(_montoPago <= poolFondos, "El pool no tiene fondos suficientes para cubrir este monto");

        contadorPolizas++;
        polizas[contadorPolizas] = Poliza({
            agricultor: msg.sender,
            prima: msg.value,
            montoPago: _montoPago,
            umbralTemperatura: _umbralTemperatura,
            fechaInicio: block.timestamp,
            fechaFin: block.timestamp + (_duracionDias * 1 days),
            estado: EstadoPoliza.Activa
        });

        poolFondos += msg.value;
        emit PolizaCreada(contadorPolizas, msg.sender, msg.value, _montoPago);
        return contadorPolizas;
    }

    /// @notice El oraculo reporta la temperatura registrada para una poliza.
    /// Si la temperatura cae al umbral pactado o por debajo, el pago se
    /// ejecuta automaticamente, sin intervencion humana ni peritaje.
    function reportarClima(uint256 _idPoliza, int256 _temperatura) external soloOraculo {
        Poliza storage p = polizas[_idPoliza];
        require(p.estado == EstadoPoliza.Activa, "La poliza no esta activa");
        require(block.timestamp <= p.fechaFin, "La poliza ya vencio");

        emit DatoClimaReportado(_idPoliza, _temperatura);

        if (_temperatura <= p.umbralTemperatura) {
            _ejecutarPago(_idPoliza);
        }
    }

    function _ejecutarPago(uint256 _idPoliza) internal {
        Poliza storage p = polizas[_idPoliza];
        require(poolFondos >= p.montoPago, "Fondos insuficientes en el pool");

        p.estado = EstadoPoliza.Pagada;
        poolFondos -= p.montoPago;

        (bool exito, ) = p.agricultor.call{value: p.montoPago}("");
        require(exito, "Fallo la transferencia del pago");

        emit PagoEjecutado(_idPoliza, p.agricultor, p.montoPago);
    }

    /// @notice Cualquiera puede marcar como vencida una poliza cuyo periodo
    /// termino sin que ocurriera el evento climatico asegurado.
    function marcarVencida(uint256 _idPoliza) external {
        Poliza storage p = polizas[_idPoliza];
        require(block.timestamp > p.fechaFin, "La poliza aun no vence");
        require(p.estado == EstadoPoliza.Activa, "La poliza no esta activa");
        p.estado = EstadoPoliza.Vencida;
        emit PolizaVencida(_idPoliza);
    }

    function consultarPoliza(uint256 _idPoliza) external view returns (Poliza memory) {
        return polizas[_idPoliza];
    }
}
