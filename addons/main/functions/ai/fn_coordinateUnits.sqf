/*
 * Author: Meryylle
 * Coordena ações entre múltiplas unidades para táticas avançadas
 *
 * Arguments:
 * 0: Grupos <ARRAY>
 * 1: Tipo de Coordenação <STRING>
 * 2: Alvo/Posição <OBJECT/ARRAY>
 * 3: Parâmetros Adicionais <ARRAY>
 *
 * Return Value:
 * Boolean - Sucesso da operação
 *
 * Example:
 * [[_group1, _group2], "FLANKING_ATTACK", _target] call AIAI_fnc_coordinateUnits
 */

params [
    ["_groups", [], [[]]],
    ["_coordinationType", "", [""]],
    ["_target", objNull, [objNull, []]],
    ["_params", [], [[]]]
];

if (count _groups == 0) exitWith {false};

// Função local para distribuir unidades em formação
private _fnc_distributeInFormation = {
    params ["_units", "_centerPos", "_spacing", "_direction"];
    private _positions = [];
    private _numUnits = count _units;
    private _rowSize = floor sqrt _numUnits;
    
    for "_i" from 0 to (_numUnits - 1) do {
        private _row = floor (_i / _rowSize);
        private _col = _i % _rowSize;
        private _relPos = [
            (_col - _rowSize/2) * _spacing,
            _row * _spacing,
            0
        ];
        private _rotatedPos = [
            (_relPos select 0) * cos _direction - (_relPos select 1) * sin _direction,
            (_relPos select 0) * sin _direction + (_relPos select 1) * cos _direction,
            0
        ];
        _positions pushBack (_centerPos vectorAdd _rotatedPos);
    };
    _positions
};

switch (toUpper _coordinationType) do {
    case "FLANKING_ATTACK": {
        if (count _groups < 2) exitWith {false};
        
        private _targetPos = if (_target isEqualType objNull) then {getPos _target} else {_target};
        private _terrainAnalysis = [_targetPos, 300] call AIAI_fnc_analyzeTerrain;
        private _flankRoutes = _terrainAnalysis select 2;
        
        if (count _flankRoutes == 0) exitWith {false};
        
        // Ordenar rotas por qualidade (cobertura)
        _flankRoutes sort false;
        
        // Dividir grupos entre ataque frontal e flanqueamento
        private _mainGroup = _groups select 0;
        private _flankGroup = _groups select 1;
        
        // Configurar grupo de flanqueamento
        private _flankRoute = _flankRoutes select 0;
        private _flankPos = _flankRoute select 0;
        [_flankGroup, "MOVE", _flankPos] call AIAI_fnc_setOrders;
        
        // Configurar grupo principal para supressão
        [_mainGroup, "SUPPRESS", _targetPos] call AIAI_fnc_setOrders;
        
        true
    };
    
    case "COORDINATED_ADVANCE": {
        private _targetPos = if (_target isEqualType objNull) then {getPos _target} else {_target};
        private _direction = (_groups select 0) getDir _targetPos;
        
        {
            private _group = _x;
            private _units = units _group;
            private _positions = [_units, getPos leader _group, 5, _direction] call _fnc_distributeInFormation;
            
            {
                private _unit = _x;
                private _pos = _positions select _forEachIndex;
                _unit doMove _pos;
            } forEach _units;
            
            _group setBehaviour "AWARE";
            _group setFormation "WEDGE";
        } forEach _groups;
        
        true
    };
    
    case "SUPPRESS_AND_BREACH": {
        if (count _groups < 2) exitWith {false};
        
        private _targetPos = if (_target isEqualType objNull) then {getPos _target} else {_target};
        private _suppressionGroup = _groups select 0;
        private _breachGroup = _groups select 1;
        
        // Grupo de supressão
        {
            _x setUnitPos "DOWN";
            _x doTarget _target;
            _x doSuppressiveFire _target;
        } forEach units _suppressionGroup;
        
        // Grupo de breach
        private _breachPos = _targetPos getPos [20, (_targetPos getDir (getPos leader _breachGroup)) + 180];
        [_breachGroup, "MOVE", _breachPos] call AIAI_fnc_setOrders;
        
        {
            _x setUnitPos "UP";
            _x disableAI "AUTOTARGET";
        } forEach units _breachGroup;
        
        true
    };
    
    case "DEFENSIVE_LINE": {
        private _centerPos = if (_target isEqualType objNull) then {getPos _target} else {_target};
        private _terrainAnalysis = [_centerPos, 200] call AIAI_fnc_analyzeTerrain;
        private _coverPositions = _terrainAnalysis select 1;
        
        if (count _coverPositions == 0) exitWith {false};
        
        // Distribuir grupos em posições de cobertura
        {
            private _group = _x;
            private _units = units _group;
            private _availableCover = _coverPositions select [0, count _units];
            _coverPositions = _coverPositions select [count _units, count _coverPositions];
            
            {
                private _unit = _x;
                private _coverInfo = _availableCover select _forEachIndex;
                if (!isNil "_coverInfo") then {
                    private _pos = _coverInfo select 0;
                    _unit doMove _pos;
                    _unit setUnitPos "MIDDLE";
                };
            } forEach _units;
            
            _group setBehaviour "COMBAT";
            _group setCombatMode "RED";
        } forEach _groups;
        
        true
    };
    
    default {false};
};
