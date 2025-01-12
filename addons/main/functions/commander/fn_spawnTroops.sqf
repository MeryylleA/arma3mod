/*
 * Author: Your Name
 * Spawns troops for the AI Commander
 *
 * Arguments:
 * 0: Commander Logic <OBJECT>
 * 1: Unit Type <STRING>
 * 2: Amount <NUMBER>
 * 3: Spawn Position <ARRAY>
 *
 * Return Value:
 * Array of spawned units
 *
 * Example:
 * [_logic, "B_Soldier_F", 5, [0,0,0]] call AIAI_fnc_spawnTroops
 */

params [
    ["_logic", objNull, [objNull]],
    ["_unitType", "", [""]],
    ["_amount", 1, [0]],
    ["_spawnPos", [0,0,0], [[]], [3]]
];

if (isNull _logic || _unitType == "") exitWith {[]};

private _side = _logic getVariable ["commanderSide", west];
private _group = createGroup [_side, true];
private _spawnedUnits = [];

for "_i" from 1 to _amount do {
    private _unit = _group createUnit [_unitType, _spawnPos, [], 0, "NONE"];
    _spawnedUnits pushBack _unit;
};

// Add units to commander's active units
private _activeUnits = _logic getVariable ["activeUnits", []];
_activeUnits append _spawnedUnits;
_logic setVariable ["activeUnits", _activeUnits];

_spawnedUnits
