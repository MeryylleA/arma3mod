/*
 * Author: Meryylle
 * Sistema de tratamento de erros e recuperação
 *
 * Arguments:
 * 0: Função <STRING> - Nome da função que gerou o erro
 * 1: Erro <STRING> - Descrição do erro
 * 2: Dados <ANY> - Dados relacionados ao erro
 * 3: Crítico <BOOL> - Se o erro é crítico e requer ação imediata
 *
 * Return Value:
 * ARRAY - [Sucesso do tratamento (Bool), Mensagem de status (String)]
 *
 * Example:
 * ["fn_coordinateUnits", "Invalid group", _group, false] call AIAI_fnc_errorHandler
 */

params [
    ["_function", "", [""]],
    ["_error", "", [""]],
    ["_data", nil, []],
    ["_critical", false, [false]]
];

// Log do erro
[
    ["ERROR", "WARNING"] select (!_critical),
    _function,
    _error,
    _data
] call AIAI_fnc_logSystem;

private _handled = false;
private _status = "";

switch (_function) do {
    case "fn_coordinateUnits": {
        switch (true) do {
            // Grupo inválido
            case (_error == "Invalid group"): {
                private _group = _data;
                if (!isNull _group) then {
                    // Tentar recriar o grupo
                    private _units = units _group;
                    private _side = side _group;
                    private _newGroup = createGroup [_side, true];
                    
                    {
                        [_x] joinSilent _newGroup;
                    } forEach _units;
                    
                    if (count units _newGroup > 0) then {
                        _handled = true;
                        _status = "Group recreated successfully";
                    };
                };
            };
            
            // Posição inválida
            case (_error == "Invalid position"): {
                private _pos = _data;
                if (_pos isEqualType [] && {count _pos >= 2}) then {
                    private _safePos = [_pos, 0, 100, 5, 0, 0.5, 0] call BIS_fnc_findSafePos;
                    if (_safePos isEqualType [] && {count _safePos >= 2}) then {
                        _handled = true;
                        _status = format ["Safe position found at %1", _safePos];
                        _data = _safePos;
                    };
                };
            };
        };
    };
    
    case "fn_analyzeTerrain": {
        switch (true) do {
            // Erro de análise de terreno
            case (_error == "Terrain analysis failed"): {
                private _pos = _data;
                if (_pos isEqualType []) then {
                    // Tentar análise simplificada
                    private _simpleAnalysis = [
                        [], // high points
                        nearestTerrainObjects [_pos, ["HOUSE", "WALL", "ROCK"], 100], // cover
                        [], // flank routes
                        [] // observation points
                    ];
                    _data = _simpleAnalysis;
                    _handled = true;
                    _status = "Fallback to simple terrain analysis";
                };
            };
        };
    };
    
    case "fn_handleAIBehavior": {
        switch (true) do {
            // Erro de comportamento da IA
            case (_error == "AI behavior error"): {
                private _unit = _data;
                if (!isNull _unit && {alive _unit}) then {
                    // Resetar comportamento para padrão
                    private _group = group _unit;
                    _group setBehaviour "AWARE";
                    _group setCombatMode "YELLOW";
                    _group setSpeedMode "NORMAL";
                    
                    // Limpar waypoints
                    while {(count (waypoints _group)) > 0} do {
                        deleteWaypoint ((waypoints _group) select 0);
                    };
                    
                    _handled = true;
                    _status = "AI behavior reset to default";
                };
            };
            
            // Erro de pathfinding
            case (_error == "Pathfinding error"): {
                private _unit = _data select 0;
                private _targetPos = _data select 1;
                
                if (!isNull _unit && {alive _unit}) then {
                    // Tentar encontrar caminho alternativo
                    private _altPos = [_targetPos, 10, 50, 5] call BIS_fnc_findSafePos;
                    _unit doMove _altPos;
                    
                    _handled = true;
                    _status = "Alternative path calculated";
                };
            };
        };
    };
};

// Se o erro não foi tratado e é crítico, tomar ação de fallback
if (!_handled && _critical) then {
    private _errorCount = missionNamespace getVariable ["AIAI_CRITICAL_ERRORS", 0];
    missionNamespace setVariable ["AIAI_CRITICAL_ERRORS", _errorCount + 1];
    
    if (_errorCount > 5) then {
        // Resetar todo o sistema em caso de muitos erros críticos
        [] spawn {
            ["WARNING", "ERROR_HANDLER", "Multiple critical errors, resetting AI system"] call AIAI_fnc_logSystem;
            
            {
                private _group = group _x;
                if (!isNull _group) then {
                    while {(count (waypoints _group)) > 0} do {
                        deleteWaypoint ((waypoints _group) select 0);
                    };
                    _group setBehaviour "AWARE";
                    _group setCombatMode "YELLOW";
                };
            } forEach allUnits;
            
            missionNamespace setVariable ["AIAI_CRITICAL_ERRORS", 0];
        };
        
        _handled = true;
        _status = "System reset initiated due to multiple critical errors";
    };
};

[_handled, _status]
