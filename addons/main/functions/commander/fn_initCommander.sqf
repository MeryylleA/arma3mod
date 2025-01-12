/*
 * Author: Meryylle
 * Inicializa o módulo do AI Commander com sistemas avançados
 *
 * Arguments:
 * 0: Logic <OBJECT>
 * 1: Units <ARRAY>
 * 2: Activated <BOOL>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_logic, [_unit], true] call AIAI_fnc_initCommander
 */

params ["_logic", "_units", "_activated"];

if (!_activated) exitWith {
    ["WARNING", "COMMANDER", "Module not activated", _logic] call AIAI_fnc_logSystem;
};

// Inicializar sistema de logging
private _debugMode = _logic getVariable ["DebugMode", false];
missionNamespace setVariable ["AIAI_DEBUG_MODE", _debugMode, true];

["INFO", "COMMANDER", format ["Initializing AI Commander (Debug: %1)", _debugMode]] call AIAI_fnc_logSystem;

try {
    // Configurar lado do comandante
    private _side = _logic getVariable ["Side", "WEST"];
    private _sideEnum = switch (_side) do {
        case "WEST": { west };
        case "EAST": { east };
        case "GUER": { resistance };
        default { 
            throw ["Invalid side configuration", _side];
        };
    };
    
    // Configurar nível de habilidade da IA
    private _aiSkill = _logic getVariable ["AISkill", 0.6];
    private _tacticStyle = _logic getVariable ["TacticStyle", "BALANCED"];
    
    // Inicializar variáveis do comandante
    _logic setVariable ["commanderSide", _sideEnum];
    _logic setVariable ["availableUnits", []];
    _logic setVariable ["activeUnits", []];
    _logic setVariable ["aiSkill", _aiSkill];
    _logic setVariable ["tacticStyle", _tacticStyle];
    
    // Inicializar monitor de performance
    if (isServer) then {
        [] spawn AIAI_fnc_performanceMonitor;
    };
    
    // Configurar event handlers para tratamento de erros
    _logic addEventHandler ["Deleted", {
        params ["_entity"];
        ["INFO", "COMMANDER", "Commander module deleted, cleaning up"] call AIAI_fnc_logSystem;
        
        // Limpar recursos
        {
            if (alive _x) then {
                private _group = group _x;
                if (!isNull _group) then {
                    while {(count (waypoints _group)) > 0} do {
                        deleteWaypoint ((waypoints _group) select 0);
                    };
                };
            };
        } forEach (_entity getVariable ["activeUnits", []]);
    }];
    
    // Inicializar sistema de IA
    private _aiInit = [_logic] call AIAI_fnc_initAI;
    if (!_aiInit) then {
        throw ["Failed to initialize AI system", _logic];
    };
    
    // Criar interface do usuário se necessário
    if (_debugMode) then {
        [] call AIAI_fnc_createUIElements;
    };
    
    // Iniciar loop principal do comandante
    [_logic] spawn {
        params ["_logic"];
        private _updateInterval = 1;
        
        while {!isNull _logic} do {
            try {
                // Atualizar comportamento da IA
                ["AIAI_fnc_handleAIBehavior", [_logic]] call AIAI_fnc_measureExecution;
                
                // Verificar performance e ajustar intervalo
                private _perfData = missionNamespace getVariable ["AIAI_PERFORMANCE_DATA", createHashMap];
                private _fps = _perfData getOrDefault ["fps", 60];
                
                if (_fps < 20) then {
                    _updateInterval = _updateInterval + 0.5;
                    _updateInterval = _updateInterval min 5;
                } else {
                    _updateInterval = _updateInterval - 0.1;
                    _updateInterval = _updateInterval max 1;
                };
                
                sleep _updateInterval;
            } catch {
                private _error = _exception;
                ["ERROR", "COMMANDER", "Error in commander loop", _error] call AIAI_fnc_logSystem;
                
                // Tentar recuperar de erro
                [
                    "fn_initCommander",
                    "Commander loop error",
                    _error,
                    true
                ] call AIAI_fnc_errorHandler;
                
                sleep 5; // Dar tempo para recuperação
            };
        };
    };
    
    ["INFO", "COMMANDER", "AI Commander initialized successfully"] call AIAI_fnc_logSystem;
    
} catch {
    private _error = _exception;
    
    // Log do erro
    ["ERROR", "COMMANDER", "Failed to initialize commander", _error] call AIAI_fnc_logSystem;
    
    // Tentar recuperar do erro
    private _handled = [
        "fn_initCommander",
        "Initialization error",
        _error,
        true
    ] call AIAI_fnc_errorHandler;
    
    if (!(_handled select 0)) then {
        // Se não foi possível recuperar, deletar o módulo
        deleteVehicle _logic;
    };
};
