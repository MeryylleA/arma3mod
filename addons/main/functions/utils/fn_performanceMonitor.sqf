/*
 * Author: Meryylle
 * Monitor de performance e otimização
 *
 * Arguments:
 * None
 *
 * Return Value:
 * None
 *
 * Example:
 * [] call AIAI_fnc_performanceMonitor
 */

if (!isServer) exitWith {};

// Variáveis de monitoramento
private _maxUnitsPerFrame = 10;
private _maxUpdateInterval = 5;
private _minFPS = 20;

// Inicializar contadores
missionNamespace setVariable ["AIAI_PERF_COUNTER", 0];
missionNamespace setVariable ["AIAI_LAST_UPDATE", time];
missionNamespace setVariable ["AIAI_PERFORMANCE_DATA", createHashMap];

// Função para coletar métricas
private _fnc_collectMetrics = {
    private _perfData = missionNamespace getVariable ["AIAI_PERFORMANCE_DATA", createHashMap];
    
    // FPS do servidor
    private _serverFPS = diag_fps;
    _perfData set ["fps", _serverFPS];
    
    // Contagem de unidades
    private _totalUnits = count allUnits;
    _perfData set ["units", _totalUnits];
    
    // Uso de memória (aproximado através de allVariables)
    private _memoryUse = count (allVariables missionNamespace);
    _perfData set ["memory", _memoryUse];
    
    // Tempo médio de execução de funções
    private _executionTimes = _perfData getOrDefault ["execution_times", createHashMap];
    _perfData set ["execution_times", _executionTimes];
    
    missionNamespace setVariable ["AIAI_PERFORMANCE_DATA", _perfData];
    
    // Log de performance
    ["INFO", "PERFORMANCE", format ["FPS: %1 | Units: %2 | Memory: %3", _serverFPS, _totalUnits, _memoryUse]] call AIAI_fnc_logSystem;
};

// Função para otimizar performance
private _fnc_optimize = {
    private _perfData = missionNamespace getVariable ["AIAI_PERFORMANCE_DATA", createHashMap];
    private _fps = _perfData getOrDefault ["fps", 60];
    
    if (_fps < _minFPS) then {
        // Reduzir frequência de atualizações
        _maxUpdateInterval = _maxUpdateInterval + 1;
        
        // Reduzir número de unidades processadas por frame
        _maxUnitsPerFrame = _maxUnitsPerFrame - 1;
        _maxUnitsPerFrame = _maxUnitsPerFrame max 5;
        
        // Notificar sobre otimização
        ["WARNING", "PERFORMANCE", format ["Performance optimization: Update interval increased to %1, units per frame reduced to %2", _maxUpdateInterval, _maxUnitsPerFrame]] call AIAI_fnc_logSystem;
    } else {
        // Restaurar valores se performance melhorar
        if (_fps > _minFPS + 10) then {
            _maxUpdateInterval = _maxUpdateInterval - 0.5;
            _maxUpdateInterval = _maxUpdateInterval max 2;
            
            _maxUnitsPerFrame = _maxUnitsPerFrame + 1;
            _maxUnitsPerFrame = _maxUnitsPerFrame min 15;
        };
    };
};

// Função para medir tempo de execução
AIAI_fnc_measureExecution = {
    params ["_function", "_args"];
    
    private _startTime = diag_tickTime;
    private _result = _args call (missionNamespace getVariable [_function, {}]);
    private _endTime = diag_tickTime;
    
    private _perfData = missionNamespace getVariable ["AIAI_PERFORMANCE_DATA", createHashMap];
    private _executionTimes = _perfData getOrDefault ["execution_times", createHashMap];
    
    private _functionTimes = _executionTimes getOrDefault [_function, []];
    _functionTimes pushBack (_endTime - _startTime);
    
    // Manter apenas as últimas 100 medições
    if (count _functionTimes > 100) then {
        _functionTimes deleteRange [0, count _functionTimes - 100];
    };
    
    _executionTimes set [_function, _functionTimes];
    _perfData set ["execution_times", _executionTimes];
    
    _result
};

// Loop principal de monitoramento
[] spawn {
    while {true} do {
        call _fnc_collectMetrics;
        call _fnc_optimize;
        
        // Análise de tempos de execução
        private _perfData = missionNamespace getVariable ["AIAI_PERFORMANCE_DATA", createHashMap];
        private _executionTimes = _perfData getOrDefault ["execution_times", createHashMap];
        
        {
            private _function = _x;
            private _times = _executionTimes getOrDefault [_function, []];
            
            if (count _times > 0) then {
                private _avgTime = 0;
                {
                    _avgTime = _avgTime + _x;
                } forEach _times;
                _avgTime = _avgTime / count _times;
                
                // Alertar sobre funções lentas
                if (_avgTime > 0.1) then {
                    ["WARNING", "PERFORMANCE", format ["Slow function detected: %1 (avg: %2ms)", _function, _avgTime * 1000]] call AIAI_fnc_logSystem;
                };
            };
        } forEach (keys _executionTimes);
        
        sleep _maxUpdateInterval;
    };
};
