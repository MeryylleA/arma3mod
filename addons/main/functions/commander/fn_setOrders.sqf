/*
 * Author: Meryylle
 * Define ordens para um grupo de unidades
 *
 * Arguments:
 * 0: Grupo <GROUP>
 * 1: Tipo de Ordem <STRING> - "PATROL", "ATTACK", "DEFEND", "SUPPORT"
 * 2: Posição/Objetivo <ARRAY/OBJECT>
 * 3: Parâmetros Adicionais <ARRAY> (opcional)
 *
 * Return Value:
 * Boolean - Sucesso da operação
 *
 * Example:
 * [_group, "PATROL", [0,0,0], [100, 3]] call AIAI_fnc_setOrders
 */

params [
    ["_group", grpNull, [grpNull]],
    ["_orderType", "", [""]],
    ["_target", [0,0,0], [[], objNull]],
    ["_params", [], [[]]]
];

if (isNull _group) exitWith {false};

// Limpa ordens anteriores
{[_x] orderGetIn true;} forEach units _group;
{deleteWaypoint _x} forEach waypoints _group;

private _wp = _group addWaypoint [_target, 0];

switch (toUpper _orderType) do {
    case "PATROL": {
        _params params [["_radius", 100, [0]], ["_points", 3, [0]]];
        
        for "_i" from 1 to _points do {
            private _angle = (_i * (360/_points));
            private _pos = _target getPos [_radius, _angle];
            _wp = _group addWaypoint [_pos, 0];
        };
        
        _wp = _group addWaypoint [_target, 0];
        _wp setWaypointType "CYCLE";
        
        _group setCombatMode "YELLOW";
        _group setBehaviour "AWARE";
        _group setSpeedMode "LIMITED";
    };
    
    case "ATTACK": {
        _wp setWaypointType "SAD";
        _wp setWaypointBehaviour "COMBAT";
        _wp setWaypointCombatMode "RED";
        _wp setWaypointSpeed "NORMAL";
        
        _group setCombatMode "RED";
        _group setBehaviour "COMBAT";
        _group setSpeedMode "NORMAL";
    };
    
    case "DEFEND": {
        _wp setWaypointType "HOLD";
        _wp setWaypointBehaviour "COMBAT";
        _wp setWaypointCombatMode "RED";
        
        _group setCombatMode "RED";
        _group setBehaviour "COMBAT";
        _group setSpeedMode "LIMITED";
        
        // Criar posições defensivas ao redor do ponto
        {
            private _unit = _x;
            private _pos = _target getPos [10 + random 20, random 360];
            _unit doMove _pos;
            _unit setUnitPos "DOWN";
        } forEach units _group;
    };
    
    case "SUPPORT": {
        _wp setWaypointType "SUPPORT";
        _wp setWaypointBehaviour "AWARE";
        _wp setWaypointCombatMode "YELLOW";
        _wp setWaypointSpeed "NORMAL";
        
        _group setCombatMode "YELLOW";
        _group setBehaviour "AWARE";
        _group setSpeedMode "NORMAL";
        
        // Se for unidade médica, priorizar cura
        {
            if (_x getUnitTrait "Medic") then {
                _x setUnitTrait ["Medic", 1];
            };
        } forEach units _group;
    };
    
    default {
        _wp setWaypointType "MOVE";
        _group setBehaviour "AWARE";
    };
};

true
