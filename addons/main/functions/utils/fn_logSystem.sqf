/*
 * Author: Meryylle
 * Sistema de logging e diagnóstico para o mod
 *
 * Arguments:
 * 0: Tipo de Log <STRING> - "DEBUG", "INFO", "WARNING", "ERROR"
 * 1: Componente <STRING> - Nome do componente que gerou o log
 * 2: Mensagem <STRING> - Mensagem do log
 * 3: Dados Adicionais <ANY> (opcional) - Dados extras para debug
 *
 * Return Value:
 * None
 *
 * Example:
 * ["ERROR", "AI_BEHAVIOR", "Falha ao coordenar unidades", _errorData] call AIAI_fnc_logSystem
 */

params [
    ["_type", "INFO", [""]],
    ["_component", "", [""]],
    ["_message", "", [""]],
    ["_data", nil, []]
];

// Configurações de logging
private _enableDebug = missionNamespace getVariable ["AIAI_DEBUG_MODE", false];
private _logToRPT = true;
private _maxLogEntries = 1000;

// Formatar timestamp
private _timestamp = format ["%1:%2:%3", 
    str date select 3,
    str date select 4,
    str round time
];

// Formatar mensagem
private _logEntry = format ["[AIAI][%1][%2][%3] %4", _timestamp, _type, _component, _message];

// Adicionar dados extras se em modo debug
if (_enableDebug && {!isNil "_data"}) then {
    private _debugInfo = if (_data isEqualType []) then {
        str _data
    } else {
        format ["%1", _data]
    };
    _logEntry = _logEntry + format [" | Data: %1", _debugInfo];
};

// Armazenar log em array global
private _logHistory = missionNamespace getVariable ["AIAI_LOG_HISTORY", []];
_logHistory pushBack _logEntry;

// Limitar tamanho do histórico
if (count _logHistory > _maxLogEntries) then {
    _logHistory deleteRange [0, count _logHistory - _maxLogEntries];
};
missionNamespace setVariable ["AIAI_LOG_HISTORY", _logHistory];

// Logging para RPT se habilitado
if (_logToRPT) then {
    diag_log _logEntry;
};

// Mostrar hints para erros críticos
if (_type == "ERROR") then {
    if (isServer) then {
        private _errorCount = missionNamespace getVariable ["AIAI_ERROR_COUNT", 0];
        _errorCount = _errorCount + 1;
        missionNamespace setVariable ["AIAI_ERROR_COUNT", _errorCount, true];
        
        // Se muitos erros ocorrerem em sequência, notificar admin
        if (_errorCount > 10) then {
            private _adminMsg = format ["[AIAI] Multiple errors detected (%1 in total). Check RPT logs.", _errorCount];
            [_adminMsg] remoteExec ["hint", 0];
            missionNamespace setVariable ["AIAI_ERROR_COUNT", 0, true];
        };
    };
};
