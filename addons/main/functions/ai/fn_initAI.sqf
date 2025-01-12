/*
 * Author: Your Name
 * Initializes the AI behavior system
 *
 * Arguments:
 * 0: Commander Logic <OBJECT>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_logic] call AIAI_fnc_initAI
 */

params ["_logic"];

if (isNull _logic) exitWith {};

// Initialize AI behavior parameters
_logic setVariable ["combatMode", "RED"];
_logic setVariable ["formation", "WEDGE"];
_logic setVariable ["speedMode", "NORMAL"];
_logic setVariable ["behavior", "COMBAT"];

// Start the AI behavior handler
[_logic] spawn {
    params ["_logic"];
    while {!isNull _logic} do {
        [_logic] call AIAI_fnc_handleAIBehavior;
        sleep 5;
    };
};
