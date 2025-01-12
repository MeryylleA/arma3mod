/*
 * Author: Meryylle
 * Gerencia o comportamento da IA do comandante
 *
 * Arguments:
 * 0: Logic <OBJECT> - Objeto do módulo do comandante
 *
 * Return Value:
 * None
 *
 * Example:
 * [_logic] call AIAI_fnc_handleAIBehavior
 */

params ["_logic"];

if (isNull _logic) exitWith {};

private _side = _logic getVariable ["commanderSide", west];
private _activeUnits = _logic getVariable ["activeUnits", []];

// Remove unidades mortas ou nulas
_activeUnits = _activeUnits select {!isNull _x && {alive _x}};
_logic setVariable ["activeUnits", _activeUnits];

// Analisa a situação atual
private _enemySides = [west, east, resistance] select {_x != _side};
private _allEnemies = [];
{
    _allEnemies append (allUnits select {alive _x && {side _x == _x}});
} forEach _enemySides;

// Organizar unidades em grupos funcionais
private _groups = [];
{
    private _group = group _x;
    if (!isNull _group && {!(_group in _groups)}) then {
        _groups pushBack _group;
    };
} forEach _activeUnits;

// Análise de força e capacidades
private _unitAnalysis = {
    params ["_units"];
    private _analysis = createHashMap;
    _analysis set ["infantry", 0];
    _analysis set ["armor", 0];
    _analysis set ["air", 0];
    _analysis set ["support", 0];
    
    {
        private _unit = _x;
        switch (true) do {
            case (vehicle _unit isKindOf "Tank"): {
                _analysis set ["armor", (_analysis get "armor") + 3];
            };
            case (vehicle _unit isKindOf "Air"): {
                _analysis set ["air", (_analysis get "air") + 4];
            };
            case (_unit getUnitTrait "Medic"): {
                _analysis set ["support", (_analysis get "support") + 1];
            };
            default {
                _analysis set ["infantry", (_analysis get "infantry") + 1];
            };
        };
    } forEach _units;
    _analysis
};

private _ownForces = [_activeUnits] call _unitAnalysis;
private _enemyForces = [_allEnemies] call _unitAnalysis;

// Determinar estratégia baseada na análise de forças
private _determineStrategy = {
    params ["_own", "_enemy"];
    
    private _strategy = "DEFENSIVE";
    
    // Calcular força total
    private _ownStrength = 
        (_own get "infantry") + 
        (_own get "armor" * 3) + 
        (_own get "air" * 4) + 
        (_own get "support");
        
    private _enemyStrength = 
        (_enemy get "infantry") + 
        (_enemy get "armor" * 3) + 
        (_enemy get "air" * 4) + 
        (_enemy get "support");
    
    switch (true) do {
        // Força superior - Ataque agressivo
        case (_ownStrength > _enemyStrength * 1.5): {
            _strategy = "AGGRESSIVE";
        };
        // Força similar - Tática balanceada
        case (_ownStrength > _enemyStrength * 0.7): {
            _strategy = "BALANCED";
        };
        // Força inferior - Tática defensiva
        default {
            _strategy = "DEFENSIVE";
        };
    };
    
    _strategy
};

private _strategy = [_ownForces, _enemyForces] call _determineStrategy;

// Implementar estratégia
switch (_strategy) do {
    case "AGGRESSIVE": {
        if (count _groups >= 2) then {
            // Dividir grupos para flanqueamento
            private _attackGroups = [_groups select 0, _groups select 1];
            if (count _allEnemies > 0) then {
                [_attackGroups, "FLANKING_ATTACK", _allEnemies select 0] call AIAI_fnc_coordinateUnits;
            };
        } else {
            // Ataque direto se não houver grupos suficientes para flanquear
            {
                if (count _allEnemies > 0) then {
                    [_x, "ATTACK", getPos (_allEnemies select 0)] call AIAI_fnc_setOrders;
                };
            } forEach _groups;
        };
    };
    
    case "BALANCED": {
        // Análise do terreno para posições táticas
        private _centerPos = if (count _allEnemies > 0) then {
            getPos (_allEnemies select 0)
        } else {
            getPos (leader (_groups select 0))
        };
        
        private _terrainAnalysis = [_centerPos, 300] call AIAI_fnc_analyzeTerrain;
        private _highPoints = _terrainAnalysis select 0;
        
        if (count _groups >= 2) then {
            // Um grupo para supressão, outro para movimento
            [_groups, "SUPPRESS_AND_BREACH", _centerPos] call AIAI_fnc_coordinateUnits;
        } else {
            // Movimento coordenado se houver apenas um grupo
            {
                if (count _highPoints > 0) then {
                    [_x, "MOVE", _highPoints select 0 select 0] call AIAI_fnc_setOrders;
                };
            } forEach _groups;
        };
    };
    
    case "DEFENSIVE": {
        // Encontrar melhores posições defensivas
        private _centerPos = if (count _allEnemies > 0) then {
            getPos (_allEnemies select 0)
        } else {
            getPos (leader (_groups select 0))
        };
        
        [_groups, "DEFENSIVE_LINE", _centerPos] call AIAI_fnc_coordinateUnits;
        
        // Manter unidades de suporte protegidas
        {
            if (_x getUnitTrait "Medic") then {
                private _group = group _x;
                private _nearestAlly = objNull;
                private _maxDist = 100;
                
                {
                    if (_x != _unit && {alive _x}) then {
                        private _dist = _x distance _unit;
                        if (_dist < _maxDist) then {
                            _maxDist = _dist;
                            _nearestAlly = _x;
                        };
                    };
                } forEach _activeUnits;
                
                if (!isNull _nearestAlly) then {
                    [_group, "SUPPORT", _nearestAlly] call AIAI_fnc_setOrders;
                };
            };
        } forEach _activeUnits;
    };
};

// Verificar condições especiais
{
    private _unit = _x;
    private _group = group _unit;
    
    // Verificar munição
    if ((_unit ammo primaryWeapon _unit) == 0) then {
        private _nearestAmmo = objNull;
        private _minDist = 200;
        
        {
            if (_x isKindOf "ReammoBox_F") then {
                private _dist = _unit distance _x;
                if (_dist < _minDist) then {
                    _minDist = _dist;
                    _nearestAmmo = _x;
                };
            };
        } forEach nearestObjects [getPos _unit, ["ReammoBox_F"], 200];
        
        if (!isNull _nearestAmmo) then {
            _unit doMove (getPos _nearestAmmo);
        };
    };
    
    // Verificar dano do veículo
    if (vehicle _unit != _unit) then {
        private _vehicle = vehicle _unit;
        if (damage _vehicle > 0.5) then {
            _unit action ["GetOut", _vehicle];
            private _coverPos = [];
            
            private _terrainAnalysis = [getPos _unit, 50] call AIAI_fnc_analyzeTerrain;
            private _covers = _terrainAnalysis select 1;
            
            if (count _covers > 0) then {
                _unit doMove ((_covers select 0) select 0);
            };
        };
    };
} forEach _activeUnits;
